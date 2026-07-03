#include "windows_microphone_plugin.h"

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>
#include <string>
#include <utility>

#include <audioclient.h>
#include <avrt.h>
#include <ksmedia.h>
#include <mmdeviceapi.h>
#include <wrl/client.h>

namespace {

using Microsoft::WRL::ComPtr;

constexpr int kTargetSampleRate = 16000;
constexpr int kMaxQueuedAudioChunks = 64;
constexpr REFERENCE_TIME kWasapiBufferDuration = 1000000;  // 100 ms.
constexpr HRESULT kAccessDenied = static_cast<HRESULT>(0x80070005L);

struct CoInitializer {
  CoInitializer() {
    hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    initialized = SUCCEEDED(hr);
  }

  ~CoInitializer() {
    if (initialized) {
      CoUninitialize();
    }
  }

  HRESULT hr = E_FAIL;
  bool initialized = false;
};

struct MixFormatInfo {
  bool supported = false;
  bool is_float = false;
  int sample_rate = 0;
  int channels = 0;
  int bits_per_sample = 0;
  int block_align = 0;
};

std::string StatusForHresult(HRESULT hr) {
  if (hr == kAccessDenied || hr == E_ACCESSDENIED) {
    return "denied";
  }
  if (hr == E_NOTFOUND || hr == AUDCLNT_E_DEVICE_INVALIDATED) {
    return "noInputDevice";
  }
  if (hr == AUDCLNT_E_DEVICE_IN_USE) {
    return "deviceBusy";
  }
  return "unknown";
}

std::string MessageForStatus(const std::string& status) {
  if (status == "denied") {
    return "Microphone access is blocked by Windows privacy settings.";
  }
  if (status == "noInputDevice") {
    return "No microphone input device is available.";
  }
  if (status == "deviceBusy") {
    return "The default microphone is currently in use by another app.";
  }
  if (status == "unsupportedFormat") {
    return "The default microphone format is not supported.";
  }
  return "The Windows microphone backend failed to initialize.";
}

bool IsPcmSubformat(const GUID& subformat) {
  return IsEqualGUID(subformat, KSDATAFORMAT_SUBTYPE_PCM);
}

bool IsFloatSubformat(const GUID& subformat) {
  return IsEqualGUID(subformat, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT);
}

MixFormatInfo ParseMixFormat(const WAVEFORMATEX* format) {
  MixFormatInfo info;
  if (format == nullptr || format->nSamplesPerSec == 0 ||
      format->nChannels == 0 || format->nBlockAlign == 0) {
    return info;
  }

  info.sample_rate = static_cast<int>(format->nSamplesPerSec);
  info.channels = static_cast<int>(format->nChannels);
  info.bits_per_sample = static_cast<int>(format->wBitsPerSample);
  info.block_align = static_cast<int>(format->nBlockAlign);

  WORD tag = format->wFormatTag;
  if (tag == WAVE_FORMAT_EXTENSIBLE &&
      format->cbSize >= sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)) {
    const auto* extensible = reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(
        format);
    if (IsFloatSubformat(extensible->SubFormat)) {
      tag = WAVE_FORMAT_IEEE_FLOAT;
    } else if (IsPcmSubformat(extensible->SubFormat)) {
      tag = WAVE_FORMAT_PCM;
    } else {
      return info;
    }
  }

  if (tag == WAVE_FORMAT_IEEE_FLOAT && format->wBitsPerSample == 32) {
    info.is_float = true;
    info.supported = true;
    return info;
  }

  if (tag == WAVE_FORMAT_PCM &&
      (format->wBitsPerSample == 16 || format->wBitsPerSample == 24 ||
       format->wBitsPerSample == 32)) {
    info.is_float = false;
    info.supported = true;
  }
  return info;
}

double ClampSample(double value) {
  return std::clamp(value, -1.0, 1.0);
}

double ReadPcmSample(const BYTE* sample, int bits_per_sample) {
  if (bits_per_sample <= 16) {
    const uint32_t raw = static_cast<uint32_t>(sample[0]) |
                         (static_cast<uint32_t>(sample[1]) << 8);
    const int16_t value = static_cast<int16_t>(raw);
    return static_cast<double>(value) / 32768.0;
  }
  if (bits_per_sample <= 24) {
    uint32_t raw = static_cast<uint32_t>(sample[0]) |
                   (static_cast<uint32_t>(sample[1]) << 8) |
                   (static_cast<uint32_t>(sample[2]) << 16);
    if ((raw & 0x00800000u) != 0) {
      raw |= 0xFF000000u;
    }
    const int32_t value = static_cast<int32_t>(raw);
    return static_cast<double>(value) / 8388608.0;
  }
  const uint32_t raw = static_cast<uint32_t>(sample[0]) |
                       (static_cast<uint32_t>(sample[1]) << 8) |
                       (static_cast<uint32_t>(sample[2]) << 16) |
                       (static_cast<uint32_t>(sample[3]) << 24);
  const int32_t value = static_cast<int32_t>(raw);
  return static_cast<double>(value) / 2147483648.0;
}

std::vector<double> ConvertPacketToMono(const BYTE* data,
                                        UINT32 frame_count,
                                        DWORD flags,
                                        const MixFormatInfo& format) {
  std::vector<double> mono;
  mono.reserve(frame_count);
  if ((flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0 || data == nullptr) {
    mono.assign(frame_count, 0.0);
    return mono;
  }

  const int bytes_per_sample =
      format.is_float ? 4 : std::max(1, format.bits_per_sample / 8);
  for (UINT32 frame = 0; frame < frame_count; frame++) {
    const BYTE* frame_data = data + frame * format.block_align;
    double sum = 0.0;
    for (int channel = 0; channel < format.channels; channel++) {
      const BYTE* sample = frame_data + channel * bytes_per_sample;
      double value = 0.0;
      if (format.is_float) {
        float float_value = 0.0f;
        memcpy(&float_value, sample, sizeof(float_value));
        value = static_cast<double>(float_value);
      } else {
        value = ReadPcmSample(sample, format.bits_per_sample);
      }
      sum += ClampSample(value);
    }
    mono.push_back(sum / static_cast<double>(format.channels));
  }
  return mono;
}

class PcmResampler {
 public:
  explicit PcmResampler(int source_rate)
      : ratio_(static_cast<double>(source_rate) / kTargetSampleRate) {}

  std::vector<uint8_t> AddSamples(std::vector<double>&& samples) {
    buffer_.insert(buffer_.end(), samples.begin(), samples.end());
    std::vector<uint8_t> out;
    if (buffer_.size() < 2) {
      return out;
    }

    while (position_ + 1.0 < static_cast<double>(buffer_.size())) {
      const auto index = static_cast<size_t>(position_);
      const double fraction = position_ - static_cast<double>(index);
      const double sample = buffer_[index] * (1.0 - fraction) +
                            buffer_[index + 1] * fraction;
      const int16_t pcm = static_cast<int16_t>(std::round(
          ClampSample(sample) *
          static_cast<double>(std::numeric_limits<int16_t>::max())));
      out.push_back(static_cast<uint8_t>(pcm & 0xFF));
      out.push_back(static_cast<uint8_t>((pcm >> 8) & 0xFF));
      position_ += ratio_;
    }

    const size_t max_consumed = buffer_.empty() ? 0 : buffer_.size() - 1;
    const size_t consumed =
        std::min(static_cast<size_t>(position_), max_consumed);
    if (consumed > 0) {
      buffer_.erase(buffer_.begin(), buffer_.begin() + consumed);
      position_ -= static_cast<double>(consumed);
    }
    return out;
  }

 private:
  double ratio_ = 1.0;
  double position_ = 0.0;
  std::vector<double> buffer_;
};

std::string ProbeMicrophoneAccess(MixFormatInfo* out_format = nullptr) {
  CoInitializer co;
  if (FAILED(co.hr) && co.hr != RPC_E_CHANGED_MODE) {
    return StatusForHresult(co.hr);
  }

  ComPtr<IMMDeviceEnumerator> enumerator;
  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                                CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
  if (FAILED(hr)) {
    return StatusForHresult(hr);
  }

  ComPtr<IMMDevice> device;
  hr = enumerator->GetDefaultAudioEndpoint(eCapture, eConsole, &device);
  if (FAILED(hr)) {
    return StatusForHresult(hr);
  }

  ComPtr<IAudioClient> audio_client;
  hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                        reinterpret_cast<void**>(audio_client.GetAddressOf()));
  if (FAILED(hr)) {
    return StatusForHresult(hr);
  }

  WAVEFORMATEX* mix_format = nullptr;
  hr = audio_client->GetMixFormat(&mix_format);
  if (FAILED(hr)) {
    return StatusForHresult(hr);
  }

  const MixFormatInfo format = ParseMixFormat(mix_format);
  if (out_format != nullptr) {
    *out_format = format;
  }
  if (!format.supported) {
    CoTaskMemFree(mix_format);
    return "unsupportedFormat";
  }

  hr = audio_client->Initialize(
      AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
      kWasapiBufferDuration, 0, mix_format, nullptr);
  CoTaskMemFree(mix_format);
  if (FAILED(hr)) {
    return StatusForHresult(hr);
  }
  return "allowed";
}

}  // namespace

WindowsMicrophonePlugin::WindowsMicrophonePlugin(
    flutter::BinaryMessenger* messenger, HWND window)
    : window_(window) {
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "codewalk/windows_microphone",
          &flutter::StandardMethodCodec::GetInstance());
  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "codewalk/windows_microphone_stream",
          &flutter::StandardMethodCodec::GetInstance());
  event_channel_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [this](const flutter::EncodableValue* arguments,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                     events) { return OnListen(arguments, std::move(events)); },
          [this](const flutter::EncodableValue* arguments) {
            return OnCancel(arguments);
          }));
}

WindowsMicrophonePlugin::~WindowsMicrophonePlugin() {
  Stop();
}

bool WindowsMicrophonePlugin::HandleWindowMessage(UINT message) {
  if (message != kWindowsMicrophoneDrainMessage) {
    return false;
  }
  DrainQueuedEvents();
  return true;
}

void WindowsMicrophonePlugin::Stop() {
  StopCapture();
  std::lock_guard<std::mutex> lock(event_mutex_);
  event_sink_.reset();
}

void WindowsMicrophonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "probe") {
    result->Success(flutter::EncodableValue(Probe()));
    return;
  }
  if (call.method_name() == "stop") {
    StopCapture();
    result->Success();
    return;
  }
  result->NotImplemented();
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
WindowsMicrophonePlugin::OnListen(
    const flutter::EncodableValue* /* arguments */,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink) {
  StopCapture();
  {
    std::lock_guard<std::mutex> lock(event_mutex_);
    event_sink_ = std::move(sink);
  }

  const auto error = StartCapture();
  if (!error.has_value()) {
    return nullptr;
  }

  {
    std::lock_guard<std::mutex> lock(event_mutex_);
    event_sink_.reset();
  }
  return std::make_unique<flutter::StreamHandlerError<flutter::EncodableValue>>(
      error->code, error->message, nullptr);
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
WindowsMicrophonePlugin::OnCancel(
    const flutter::EncodableValue* /* arguments */) {
  Stop();
  return nullptr;
}

std::string WindowsMicrophonePlugin::Probe() {
  return ProbeMicrophoneAccess();
}

std::optional<WindowsMicrophonePlugin::CaptureError>
WindowsMicrophonePlugin::StartCapture() {
  const std::string status = ProbeMicrophoneAccess();
  if (status != "allowed") {
    return CaptureError{status, MessageForStatus(status)};
  }

  stop_event_ = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  if (stop_event_ == nullptr) {
    return CaptureError{"unknown", "Failed to create microphone stop event."};
  }

  capture_running_ = true;
  capture_thread_ = std::thread([this]() { CaptureLoop(); });
  return std::nullopt;
}

void WindowsMicrophonePlugin::StopCapture() {
  capture_running_ = false;
  if (stop_event_ != nullptr) {
    SetEvent(stop_event_);
  }
  if (capture_thread_.joinable()) {
    capture_thread_.join();
  }
  if (stop_event_ != nullptr) {
    CloseHandle(stop_event_);
    stop_event_ = nullptr;
  }
  std::lock_guard<std::mutex> lock(queue_mutex_);
  pending_audio_.clear();
  pending_errors_.clear();
}

void WindowsMicrophonePlugin::CaptureLoop() {
  CoInitializer co;
  if (FAILED(co.hr) && co.hr != RPC_E_CHANGED_MODE) {
    QueueError(StatusForHresult(co.hr), MessageForStatus(StatusForHresult(co.hr)));
    return;
  }

  ComPtr<IMMDeviceEnumerator> enumerator;
  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                                CLSCTX_ALL, IID_PPV_ARGS(&enumerator));
  if (FAILED(hr)) {
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  ComPtr<IMMDevice> device;
  hr = enumerator->GetDefaultAudioEndpoint(eCapture, eConsole, &device);
  if (FAILED(hr)) {
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  ComPtr<IAudioClient> audio_client;
  hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                        reinterpret_cast<void**>(audio_client.GetAddressOf()));
  if (FAILED(hr)) {
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  WAVEFORMATEX* mix_format = nullptr;
  hr = audio_client->GetMixFormat(&mix_format);
  if (FAILED(hr)) {
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }
  const MixFormatInfo format = ParseMixFormat(mix_format);
  if (!format.supported) {
    CoTaskMemFree(mix_format);
    QueueError("unsupportedFormat", MessageForStatus("unsupportedFormat"));
    return;
  }

  hr = audio_client->Initialize(
      AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
      kWasapiBufferDuration, 0, mix_format, nullptr);
  CoTaskMemFree(mix_format);
  if (FAILED(hr)) {
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  HANDLE capture_event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
  if (capture_event == nullptr) {
    QueueError("unknown", "Failed to create microphone capture event.");
    return;
  }

  hr = audio_client->SetEventHandle(capture_event);
  if (FAILED(hr)) {
    CloseHandle(capture_event);
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  ComPtr<IAudioCaptureClient> capture_client;
  hr = audio_client->GetService(IID_PPV_ARGS(&capture_client));
  if (FAILED(hr)) {
    CloseHandle(capture_event);
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  DWORD task_index = 0;
  HANDLE mmcss_handle = AvSetMmThreadCharacteristics(L"Audio", &task_index);
  hr = audio_client->Start();
  if (FAILED(hr)) {
    if (mmcss_handle != nullptr) {
      AvRevertMmThreadCharacteristics(mmcss_handle);
    }
    CloseHandle(capture_event);
    QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
    return;
  }

  PcmResampler resampler(format.sample_rate);
  HANDLE wait_handles[] = {stop_event_, capture_event};
  while (capture_running_) {
    const DWORD wait_result = WaitForMultipleObjects(2, wait_handles, FALSE, 200);
    if (wait_result == WAIT_OBJECT_0) {
      break;
    }
    if (wait_result != WAIT_OBJECT_0 + 1 && wait_result != WAIT_TIMEOUT) {
      QueueError("unknown", "Windows microphone wait failed.");
      break;
    }

    UINT32 packet_length = 0;
    hr = capture_client->GetNextPacketSize(&packet_length);
    if (FAILED(hr)) {
      QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
      break;
    }

    while (packet_length != 0 && capture_running_) {
      BYTE* data = nullptr;
      UINT32 frames = 0;
      DWORD flags = 0;
      hr = capture_client->GetBuffer(&data, &frames, &flags, nullptr, nullptr);
      if (FAILED(hr)) {
        QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
        break;
      }

      auto mono = ConvertPacketToMono(data, frames, flags, format);
      auto pcm = resampler.AddSamples(std::move(mono));
      capture_client->ReleaseBuffer(frames);
      if (!pcm.empty()) {
        QueueAudio(std::move(pcm));
      }

      hr = capture_client->GetNextPacketSize(&packet_length);
      if (FAILED(hr)) {
        QueueError(StatusForHresult(hr), MessageForStatus(StatusForHresult(hr)));
        break;
      }
    }
  }

  audio_client->Stop();
  if (mmcss_handle != nullptr) {
    AvRevertMmThreadCharacteristics(mmcss_handle);
  }
  CloseHandle(capture_event);
}

void WindowsMicrophonePlugin::QueueAudio(std::vector<uint8_t>&& bytes) {
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    pending_audio_.push_back(std::move(bytes));
    while (pending_audio_.size() > kMaxQueuedAudioChunks) {
      pending_audio_.pop_front();
    }
  }
  PostMessage(window_, kWindowsMicrophoneDrainMessage, 0, 0);
}

void WindowsMicrophonePlugin::QueueError(std::string code, std::string message) {
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    pending_errors_.push_back(CaptureError{std::move(code), std::move(message)});
  }
  PostMessage(window_, kWindowsMicrophoneDrainMessage, 0, 0);
}

void WindowsMicrophonePlugin::DrainQueuedEvents() {
  std::deque<std::vector<uint8_t>> audio;
  std::deque<CaptureError> errors;
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    audio.swap(pending_audio_);
    errors.swap(pending_errors_);
  }

  std::lock_guard<std::mutex> lock(event_mutex_);
  if (!event_sink_) {
    return;
  }
  for (const auto& error : errors) {
    event_sink_->Error(error.code, error.message);
  }
  for (auto& chunk : audio) {
    event_sink_->Success(flutter::EncodableValue(std::move(chunk)));
  }
}
