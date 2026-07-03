#ifndef RUNNER_WINDOWS_MICROPHONE_PLUGIN_H_
#define RUNNER_WINDOWS_MICROPHONE_PLUGIN_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/method_channel.h>

#include <atomic>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include <windows.h>

constexpr UINT kWindowsMicrophoneDrainMessage = WM_APP + 0x43C;

class WindowsMicrophonePlugin {
 public:
  WindowsMicrophonePlugin(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsMicrophonePlugin();

  WindowsMicrophonePlugin(const WindowsMicrophonePlugin&) = delete;
  WindowsMicrophonePlugin& operator=(const WindowsMicrophonePlugin&) = delete;

  bool HandleWindowMessage(UINT message);
  void Stop();

 private:
  struct CaptureError {
    std::string code;
    std::string message;
  };

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListen(const flutter::EncodableValue* arguments,
           std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink);
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancel(const flutter::EncodableValue* arguments);

  std::string Probe();
  std::optional<CaptureError> StartCapture();
  void StopCapture();
  void CaptureLoop();
  void QueueAudio(std::vector<uint8_t>&& bytes);
  void QueueError(std::string code, std::string message);
  void DrainQueuedEvents();

  HWND window_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  std::mutex event_mutex_;
  std::mutex queue_mutex_;
  std::deque<std::vector<uint8_t>> pending_audio_;
  std::deque<CaptureError> pending_errors_;

  std::thread capture_thread_;
  std::atomic<bool> capture_running_{false};
  HANDLE stop_event_ = nullptr;
};

#endif  // RUNNER_WINDOWS_MICROPHONE_PLUGIN_H_
