# Plano Autoritário — TTS Cloud no CodeWalk

## Status

Ready.

Este plano é autocontido e deve ser executado sem depender do histórico da conversa, de outputs de planners, ou de qualquer contexto externo não citado aqui. A implementação deve seguir exatamente a direção definida neste documento: manter o TTS nativo como padrão, adicionar Microsoft Edge Speech como provedor experimental sem chave, e adicionar suporte inicial a provedores com chave por meio de um provedor OpenAI-compatible.

## Problema

O CodeWalk atualmente lê mensagens em voz alta usando apenas o TTS nativo/plataforma via `flutter_tts`, encapsulado em `ReadAloudService`. O usuário quer ampliar o recurso para incluir serviços cloud, começando por opções gratuitas, especialmente Microsoft Edge Speech experimental sem chave, e também preparar suporte a serviços com API key como OpenAI e outros compatíveis.

O sistema atual é limitado porque:

- `ReadAloudService` está acoplado diretamente a `FlutterTts`.
- O caminho atual assume que o motor TTS fala diretamente; provedores cloud retornam áudio binário que precisa ser tocado por um player.
- A configuração de voz é apenas `String? readAloudVoice` e ainda usa `locale: 'en-US'` hardcoded no TTS nativo.
- Chaves API não existem hoje e não podem ser armazenadas em JSON/settings comuns.
- O botão de read-aloud não diferencia falhas de engine nativo, falhas de rede, chave ausente, quota, ou provider experimental quebrado.
- A extração de texto para fala usa stripping Markdown básico, suficiente para o TTS nativo atual mas fraco para vozes cloud de maior qualidade/custo.

## Objetivo

Ao fim da implementação:

1. O TTS nativo atual continua funcionando como padrão e sem regressões.
2. A arquitetura de TTS passa a aceitar provedores plugáveis.
3. O usuário pode selecionar `Sistema/Nativo`, `Microsoft Edge Speech (experimental)` ou `OpenAI-compatible` em `Settings > Speech`.
4. O provedor Edge experimental funciona sem chave API, é opt-in, mostra aviso claro de privacidade/instabilidade, e possui fallback manual para nativo quando falhar.
5. O provedor OpenAI-compatible aceita `baseUrl`, `apiKey`, `model`, `voice`, `responseFormat=mp3` e `speed`, usando `POST /v1/audio/speech` e tocando o áudio retornado.
6. API keys são armazenadas somente em secure storage, nunca em `ExperienceSettings.toJson()` ou logs.
7. Síntese assíncrona e playback remoto respeitam cancelamento: stop, troca de sessão, background e novo envio impedem áudio antigo de começar depois.
8. O texto enviado ao TTS é melhor sanitizado para Markdown complexo.
9. `BEHAVIOR.md`, testes e, se necessário, `ADR.md` documentam o novo comportamento e os riscos do Edge experimental/cloud TTS.

## Contexto do Projeto

Projeto: CodeWalk, cliente Flutter mobile/desktop para servidores OpenCode-compatible.

Regras relevantes:

- Mobile e desktop devem continuar suportados; priorizar UX mobile.
- `BEHAVIOR.md` descreve comportamento implementado e deve ser atualizado após a mudança.
- Mudanças de comportamento precisam preservar ADR-023: o cliente não deve alterar semântica oficial de servidor/API/eventos OpenCode.
- Esta feature é client-side e não altera endpoints OpenCode; portanto é compatível com ADR-023 se não enviar dados ao servidor OpenCode nem modificar lifecycle de chat.
- Cloud TTS envia texto do assistente a terceiros; isso exige aviso de privacidade e preferencialmente uma ADR/nota explícita por causa de Edge experimental não oficial.
- Não usar `tool/i18n/generate_arb.dart` globalmente. Ao adicionar strings, seguir workflow seguro de tradução já usado no projeto.

Arquivos atuais relevantes:

- `lib/presentation/services/read_aloud_service.dart`
  - Define `ReadAloudService extends ChangeNotifier`.
  - Usa `FlutterTts` diretamente.
  - API atual: `state`, `activeMessageId`, `isSpeaking`, `progress`, `isAvailable`, `speak({messageId, text, rate, pitch, voice})`, `pause()`, `stop()`, `stopIfReading(messageId)`, `dispose()`, `getVoices()`, `getLanguages()`.
  - Aplica voz com `setVoice({'name': voice, 'locale': 'en-US'})`; isso deve ser corrigido.

- `lib/presentation/widgets/chat_message/chat_message_content.dart`
  - Renderiza o botão de read-aloud para mensagens do assistente.
  - Extrai texto de `TextPart` e remove Markdown básico.
  - Chama `readAloudService.speak(...)` com `readAloudRate`, `readAloudPitch` e `readAloudVoice`.

- `lib/domain/entities/experience_settings.dart`
  - Campos atuais: `readAloudEnabled`, `readAloudRate`, `readAloudPitch`, `readAloudVoice`.
  - Serializa settings em JSON. Não adicionar secrets/API keys aqui.

- `lib/presentation/providers/settings_provider.dart`
  - Getters/setters e persistência dos campos de read-aloud.

- `lib/presentation/pages/settings/sections/speech_settings_section.dart`
  - `_buildReadAloudCard` hoje mostra enable, speed e pitch.
  - Não possui voice picker visível apesar de existirem strings/fields.

- `lib/core/di/injection_container.dart`
  - Registra `ReadAloudService.new` como lazy singleton.

- `lib/presentation/services/sound_service.dart`
  - Usa `audioplayers` com `UrlSource` e `BytesSource` para sons curtos.
  - Não reutilizar `SoundService` diretamente para TTS longo; criar player próprio gerenciado por `ReadAloudService` ou backend de áudio TTS.

- `pubspec.yaml`
  - Já possui `flutter_tts: ^4.2.5`.
  - Já possui `audioplayers: ^6.6.0`.
  - Já possui HTTP/Dio usados pelo app.

- `test/unit/services/read_aloud_service_test.dart`
  - Testa o wrapper atual com fake `FlutterTts`.

- `test/unit/providers/settings_provider_test.dart`
  - Testa persistência/clamping dos settings.

- `BEHAVIOR.md`
  - Tem seção `Text-to-Speech (TTS)` com botão read-aloud, toggle, auto-stop, settings de speed/pitch, disabled state e Markdown stripping.

Referências externas que moldam a decisão:

- OpenChamber usa Kokoro local para read-aloud recente, não Edge/Microsoft no changelog pesquisado.
- LobeHub/LobeChat possui `EdgeSpeechTTS`, `MicrosoftTTS`, `OpenAITTS`, `OpenAISTT`, cache local e configuração de TTS.
- Edge TTS usa endpoint não oficial/reverse-engineered do Microsoft Edge Read Aloud, sem SLA e com risco de quebra/rate-limit/ToS.
- OpenAI-compatible TTS usa `POST /v1/audio/speech` com `model`, `input`, `voice`, `response_format`, `speed` e `Authorization: Bearer <key>`, retornando áudio binário.

## Decisões Resolvidas

1. **Manter o TTS nativo como padrão.** Novas instalações e usuários existentes continuam em `native` até optarem por outro provedor.
2. **Adicionar Edge como experimental e opt-in.** O rótulo deve ser `Microsoft Edge Speech (experimental)` e deve explicar que é não oficial, pode parar de funcionar, e envia texto à Microsoft.
3. **Adicionar `OpenAI-compatible` como primeiro provedor com chave.** Ele cobre OpenAI oficial e proxies/serviços compatíveis com `/v1/audio/speech`.
4. **Não implementar ElevenLabs/Azure oficial nesta primeira entrega.** Apenas preparar a arquitetura para adicionar esses provedores depois. Não criar UI morta para eles neste primeiro PR.
5. **Não armazenar API keys em `ExperienceSettings`.** Secrets ficam em secure storage por provider.
6. **Separar síntese e playback.** O backend nativo fala internamente via `flutter_tts`; backends cloud sintetizam áudio e o `ReadAloudService` toca bytes com `AudioPlayer`.
7. **Não implementar streaming progressivo no primeiro passo.** A primeira versão baixa/sintetiza o áudio completo e depois toca. Isso reduz risco em Edge/OpenAI-compatible e simplifica cancelamento.
8. **Progressão de UI simples no v1.** Botão no chat continua play/stop. Pausa, seekbar e cache podem ser entregas posteriores.
9. **Corrigir o contrato de voz.** Substituir o uso simples de `readAloudVoice` por metadados suficientes: provider, voice id, locale e model/base URL quando necessário.
10. **Implementar cancelamento por geração.** Cada chamada `speak()` deve receber um generation id interno; se `stop()` ou outra chamada invalidar a geração, resultados tardios devem ser descartados.

## Plano de Execução

### Passo 1 — Criar modelo de provedor TTS em settings sem secrets

Arquivos:

- `lib/domain/entities/experience_settings.dart`
- `lib/presentation/providers/settings_provider.dart`
- `test/unit/domain/experience_settings_test.dart` se existir; caso não exista, criar ou adicionar no conjunto de testes apropriado.
- `test/unit/providers/settings_provider_test.dart`

Executar:

1. Em `experience_settings.dart`, adicionar enum:

```dart
enum ReadAloudProvider {
  native,
  edgeExperimental,
  openAiCompatible,
}
```

2. Adicionar helpers:

```dart
String readAloudProviderKey(ReadAloudProvider provider) {
  return switch (provider) {
    ReadAloudProvider.native => 'native',
    ReadAloudProvider.edgeExperimental => 'edge_experimental',
    ReadAloudProvider.openAiCompatible => 'openai_compatible',
  };
}

ReadAloudProvider readAloudProviderFromKey(String value) {
  return switch (value.trim().toLowerCase()) {
    'edge_experimental' || 'edge' || 'microsoft_edge' =>
      ReadAloudProvider.edgeExperimental,
    'openai_compatible' || 'openai' || 'openai-compatible' =>
      ReadAloudProvider.openAiCompatible,
    _ => ReadAloudProvider.native,
  };
}
```

3. Adicionar campos persistidos não secretos a `ExperienceSettings`:

```dart
final ReadAloudProvider readAloudProvider;
final String? readAloudVoiceId;
final String? readAloudVoiceLocale;
final String? readAloudModel;
final String? readAloudBaseUrl;
final String readAloudResponseFormat;
```

4. Defaults obrigatórios:

```dart
readAloudProvider: ReadAloudProvider.native,
readAloudVoiceId: null,
readAloudVoiceLocale: null,
readAloudModel: 'gpt-4o-mini-tts',
readAloudBaseUrl: 'https://api.openai.com/v1',
readAloudResponseFormat: 'mp3',
```

5. Manter `readAloudVoice` temporariamente para migração/compatibilidade se remover de uma vez quebrar muitos testes. Se mantido, tratar como alias legado e migrar seu valor para `readAloudVoiceId` quando `readAloudVoiceId` estiver ausente.

6. Atualizar constructor, `copyWith`, `toJson` e `fromJson`.

7. Garantir que `toJson()` nunca inclua API key.

8. Em `SettingsProvider`, adicionar getters/setters:

```dart
ReadAloudProvider get readAloudProvider => _settings.readAloudProvider;
String? get readAloudVoiceId => _settings.readAloudVoiceId;
String? get readAloudVoiceLocale => _settings.readAloudVoiceLocale;
String? get readAloudModel => _settings.readAloudModel;
String? get readAloudBaseUrl => _settings.readAloudBaseUrl;
String get readAloudResponseFormat => _settings.readAloudResponseFormat;
```

9. Adicionar setters com trim, normalização e persistência:

- `setReadAloudProvider(ReadAloudProvider value)`
- `setReadAloudVoice({String? id, String? locale})`
- `setReadAloudModel(String? value)`
- `setReadAloudBaseUrl(String? value)`
- `setReadAloudResponseFormat(String value)`

10. Normalizar `baseUrl` removendo `/` final. Valor vazio volta para `https://api.openai.com/v1`.

Validação:

- Testar default provider `native`.
- Testar roundtrip JSON para provider/model/baseUrl/voice/locale/format.
- Testar que nenhuma API key aparece em `ExperienceSettings.toJson()`.
- Testar migração de `readAloudVoice` legado para `readAloudVoiceId` se o alias for mantido.

### Passo 2 — Criar secure storage específico para TTS API keys

Arquivos:

- Novo: `lib/core/auth/tts_api_key_storage.dart`
- `lib/core/di/injection_container.dart`
- Teste novo: `test/unit/core/auth/tts_api_key_storage_test.dart`

Executar:

1. Criar classe baseada no padrão de `OAuthTokenStorage`, mas com namespace próprio:

```dart
abstract class TtsApiKeyStorageBackend {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class TtsApiKeyStorage {
  TtsApiKeyStorage({required TtsApiKeyStorageBackend backend})
      : _backend = backend;

  final TtsApiKeyStorageBackend _backend;

  String _key(ReadAloudProvider provider) {
    return '${AppConstants.secureStorageNamespace}::tts_api_key::${readAloudProviderKey(provider)}';
  }

  Future<String?> read(ReadAloudProvider provider) async {
    return _backend.read(key: _key(provider));
  }

  Future<void> write(ReadAloudProvider provider, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await delete(provider);
      return;
    }
    await _backend.write(key: _key(provider), value: trimmed);
  }

  Future<void> delete(ReadAloudProvider provider) async {
    await _backend.delete(key: _key(provider));
  }
}
```

2. Implementar backend com `FlutterSecureStorage`, igual ao padrão existente.

3. Registrar em DI.

4. Garantir que exceções não loguem o valor da chave.

Validação:

- Testar write/read/delete.
- Testar trim.
- Testar valor vazio apaga a chave.
- Testar namespace por provider.

### Passo 3 — Criar abstração de backend TTS e manter nativo funcionando

Arquivos:

- Novo: `lib/presentation/services/tts/tts_backend.dart`
- Novo: `lib/presentation/services/tts/native_tts_backend.dart`
- Atualizar: `lib/presentation/services/read_aloud_service.dart`
- Atualizar: `lib/core/di/injection_container.dart`
- Atualizar: `test/unit/services/read_aloud_service_test.dart`

Executar:

1. Criar modelos:

```dart
enum TtsPlaybackMode {
  nativeEngine,
  generatedAudio,
}

class TtsVoiceOption {
  const TtsVoiceOption({
    required this.id,
    required this.label,
    this.locale,
    this.providerMetadata = const <String, String>{},
  });

  final String id;
  final String label;
  final String? locale;
  final Map<String, String> providerMetadata;
}

class TtsSynthesisRequest {
  const TtsSynthesisRequest({
    required this.text,
    required this.rate,
    required this.pitch,
    this.voiceId,
    this.voiceLocale,
    this.model,
    this.baseUrl,
    this.responseFormat = 'mp3',
    this.apiKey,
  });

  final String text;
  final double rate;
  final double pitch;
  final String? voiceId;
  final String? voiceLocale;
  final String? model;
  final String? baseUrl;
  final String responseFormat;
  final String? apiKey;
}

sealed class TtsSynthesisResult {
  const TtsSynthesisResult();
}

class NativeTtsStarted extends TtsSynthesisResult {
  const NativeTtsStarted();
}

class GeneratedTtsAudio extends TtsSynthesisResult {
  const GeneratedTtsAudio({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

abstract class TtsBackend {
  ReadAloudProvider get provider;
  TtsPlaybackMode get playbackMode;
  Future<bool> get isAvailable;
  Future<List<TtsVoiceOption>> getVoices();
  Future<TtsSynthesisResult> speakOrSynthesize(TtsSynthesisRequest request);
  Future<void> stop();
  Future<void> pause();
  void dispose();
}
```

2. Implement `NativeTtsBackend` using `FlutterTts`.

3. Move all direct `_tts.*` calls out of `ReadAloudService` into `NativeTtsBackend`.

4. Fix voice locale:

```dart
if (request.voiceId != null) {
  await _tts.setVoice({
    'name': request.voiceId!,
    if (request.voiceLocale != null) 'locale': request.voiceLocale!,
  });
}
```

If `voiceLocale` is null and backend voice list contains the selected id, derive locale from that list before calling `setVoice`.

5. Refactor `ReadAloudService` so it no longer imports `flutter_tts` directly.

6. Keep external `ReadAloudService.speak(...)` compatible initially, but extend parameters to include provider/config or make it receive provider/config from `SettingsProvider` call site in a later step.

7. Preserve state behavior for native provider.

Validação:

- Existing `ReadAloudService` tests still pass after updating fakes to fake `TtsBackend` instead of `FlutterTts`.
- Test selected voice passes locale when provided.
- Test native backend handles empty voice locale without hardcoded `en-US`.

### Passo 4 — Adicionar playback de áudio gerado no `ReadAloudService`

Arquivos:

- `lib/presentation/services/read_aloud_service.dart`
- Testes em `test/unit/services/read_aloud_service_test.dart`

Executar:

1. Adicionar `AudioPlayer` dedicado ao `ReadAloudService` para backends `generatedAudio`.

2. Não reutilizar `SoundService`, pois TTS longo precisa de estado, cancelamento, active message id e dispose próprio.

3. Em `ReadAloudService`, adicionar contador interno:

```dart
int _generation = 0;
```

4. Em cada `speak()`:

- Incrementar `_generation`.
- Guardar `final generation = _generation`.
- Parar playback anterior.
- Definir `_activeMessageId`.
- Definir estado de carregamento se for necessário adicionar enum `loading`; se não adicionar, manter `playing` apenas quando áudio começar e usar uma flag privada `_isPreparing` para evitar UI complexa.
- Chamar backend.
- Antes de tocar áudio retornado, checar `if (generation != _generation) return;`.
- Se for `GeneratedTtsAudio`, tocar com `AudioPlayer.play(BytesSource(result.bytes))`.
- Ao completar player, checar geração e resetar estado.

5. Em `stop()`:

- Incrementar `_generation`.
- Chamar `backend.stop()`.
- Chamar `_audioPlayer.stop()`.
- Resetar estado para idle e limpar active message id.

6. Em `pause()`:

- Para native, delegar `backend.pause()`.
- Para generated audio, chamar `_audioPlayer.pause()` e estado `paused` se existir UI para retomar; se a UI continua play/stop, `pause()` pode permanecer apenas para testes/compatibilidade.

7. Escutar eventos do `AudioPlayer`:

- completion → idle.
- error → idle + lastError.
- duration/position se disponíveis → progress por tempo, não por caracteres.

8. Redefinir `progress`:

- Native: manter null ou melhor esforço se `flutter_tts` fornecer progress real.
- Generated audio: `position / duration` quando duration > 0.
- Nunca usar character count para providers cloud.

Validação:

- Testar backend lento: `stop()` antes de retornar áudio impede playback.
- Testar duas chamadas `speak()` seguidas: apenas a segunda toca.
- Testar completion reseta active message.
- Testar erro de player reseta estado e não crasha.

### Passo 5 — Implementar OpenAI-compatible backend

Arquivos:

- Novo: `lib/presentation/services/tts/openai_compatible_tts_backend.dart`
- Atualizar DI.
- Testes novos em `test/unit/services/openai_compatible_tts_backend_test.dart`

Contrato obrigatório:

- Endpoint: `POST {baseUrl}/audio/speech`
- Se `baseUrl` default for `https://api.openai.com/v1`, endpoint final é `https://api.openai.com/v1/audio/speech`.
- Headers:
  - `Authorization: Bearer <apiKey>`
  - `Content-Type: application/json`
  - `Accept: audio/mpeg` quando responseFormat for `mp3`.
- Body:

```json
{
  "model": "gpt-4o-mini-tts",
  "input": "texto a sintetizar",
  "voice": "alloy",
  "response_format": "mp3",
  "speed": 1.0
}
```

Mapeamento:

- `model`: `request.model ?? 'gpt-4o-mini-tts'`
- `input`: `request.text`
- `voice`: `request.voiceId ?? 'alloy'`
- `response_format`: `request.responseFormat`, default `mp3`
- `speed`: mapear `readAloudRate` atual para range OpenAI-compatible.

Decisão de speed:

- O slider atual `readAloudRate` vai de 0.0 a 1.0.
- Para OpenAI-compatible, converter para `speed` de 0.5 a 2.0 inicialmente:

```dart
double openAiSpeedFromReadAloudRate(double rate) {
  return (0.5 + (rate.clamp(0.0, 1.0) * 1.5)).clamp(0.5, 2.0);
}
```

- Não usar `pitch` em OpenAI-compatible; o controle deve aparecer desabilitado/oculto para esse provider na UI.

Erros:

- 401/403 → `invalidApiKey`.
- 429 → `rateLimitedOrQuota`.
- 400 → `invalidRequest` com mensagem sanitizada.
- 5xx/network → `providerUnavailable`.
- Nunca incluir texto completo nem API key em logs/erros.

Validação:

- Testar body exato.
- Testar baseUrl com e sem slash final.
- Testar API key ausente retorna erro configurável antes da chamada HTTP.
- Testar status 401/429/500 mapeados.
- Testar bytes retornados viram `GeneratedTtsAudio` com mime `audio/mpeg` para mp3.

### Passo 6 — Implementar Edge experimental backend

Arquivos:

- Novo: `lib/presentation/services/tts/edge_experimental_tts_backend.dart`
- Testes: `test/unit/services/edge_experimental_tts_backend_test.dart`

Decisão:

- Implementar Edge como provider experimental, opt-in, sem chave do usuário.
- Usar endpoint público reverse-engineered do Edge Read Aloud conforme libs conhecidas.
- Encapsular todos os detalhes em backend isolado.
- Nunca tornar Edge default.

Contrato técnico mínimo:

- Voices list endpoint conhecido por bibliotecas Edge TTS:
  - `https://speech.platform.bing.com/consumer/speech/synthesize/readaloud/voices/list`
- WebSocket synthesis endpoint conhecido por bibliotecas Edge TTS:
  - `wss://speech.platform.bing.com/consumer/speech/synthesize/readaloud/edge/v1?...`
- O backend deve construir SSML com texto escapado.
- O backend deve receber frames binários de áudio e montar `Uint8List` final.
- O backend deve ignorar/metadados de word boundary na primeira versão.

Regras de segurança:

- Escapar XML/SSML: `&`, `<`, `>`, `"`, `'`.
- Limitar tamanho por request; se texto for muito longo, dividir em chunks seguros e concatenar áudio somente se isso for confiável. Na primeira versão, preferir limitar e retornar erro amigável para texto muito longo em Edge, em vez de implementar chunking frágil.
- Definir timeout de conexão e síntese.
- Tratar 403/close inesperado como `edgeUnavailable`.

UI/label obrigatório:

- Label: `Microsoft Edge Speech (experimental)`.
- Descrição: `Uses an unofficial Microsoft Edge Read Aloud endpoint. It may stop working, be rate-limited, or fail without notice. Text is sent to Microsoft.`

Validação:

- Testar SSML escaping.
- Testar parsing de frames em unidade com frames fake.
- Testar timeout.
- Testar erro quando endpoint fecha antes de áudio.
- Testar que nenhuma credencial é esperada.

Observação importante:

- Se a implementação direta do protocolo Edge em Dart se mostrar grande demais ou instável, a entrega deve parar após a arquitetura + OpenAI-compatible, e Edge deve ser marcado como bloqueado por protocolo/ToS até decisão explícita. Não criar implementação parcial que pareça funcionar mas falhe silenciosamente.

### Passo 7 — Selecionar backend no `ReadAloudService` e call site

Arquivos:

- `lib/presentation/services/read_aloud_service.dart`
- `lib/presentation/widgets/chat_message/chat_message_content.dart`
- `lib/core/di/injection_container.dart`

Executar:

1. Registrar backends no DI por provider.

2. `ReadAloudService` deve escolher backend com base em provider passado na chamada ou provider configurado via dependência de settings. A mudança mais explícita e testável é passar config na chamada a partir do widget.

3. Atualizar chamada em `chat_message_content.dart`:

```dart
readAloudService.speak(
  messageId: message.id,
  text: text,
  provider: settingsProvider.readAloudProvider,
  rate: settingsProvider.readAloudRate,
  pitch: settingsProvider.readAloudPitch,
  voiceId: settingsProvider.readAloudVoiceId,
  voiceLocale: settingsProvider.readAloudVoiceLocale,
  model: settingsProvider.readAloudModel,
  baseUrl: settingsProvider.readAloudBaseUrl,
  responseFormat: settingsProvider.readAloudResponseFormat,
);
```

4. `ReadAloudService` busca API key em `TtsApiKeyStorage` quando provider for `openAiCompatible`.

5. Se provider exigir key e key estiver ausente, não chamar HTTP; setar erro amigável e resetar estado.

6. Se provider cloud falhar, não cair automaticamente para nativo sem informar. A queda automática pode vazar comportamento inesperado; a UI deve mostrar erro e o usuário pode mudar provider para nativo.

Validação:

- Testar seleção de backend por provider.
- Testar provider com key ausente.
- Testar provider nativo continua igual.

### Passo 8 — Melhorar extração de texto para fala

Arquivos:

- Novo: `lib/presentation/services/tts/read_aloud_text_extractor.dart`
- Atualizar: `lib/presentation/widgets/chat_message/chat_message_content.dart`
- Testes: `test/unit/services/read_aloud_text_extractor_test.dart`

Executar:

1. Mover a lógica de `_extractReadableText` e regex para helper testável.

2. O helper deve:

- Remover fenced code blocks inteiros ou substituí-los por frase curta `Code block omitted.` dependendo de preferência UX. Decisão: omitir code blocks no v1 para reduzir ruído/custo.
- Remover inline code preservando texto interno curto somente se tiver menos de 80 chars; caso maior, omitir.
- Converter links `[label](url)` para `label`.
- Remover imagens `![alt](url)` ou usar `alt` quando existir.
- Remover headings markers.
- Remover blockquote markers.
- Remover listas `-`, `*`, `1.` mantendo conteúdo.
- Remover tabelas Markdown ou convertê-las para frases simples. Decisão v1: omitir linhas de tabela quando contiverem múltiplos `|`.
- Remover HTML tags simples.
- Decodificar/normalizar whitespace.
- Escapar SSML/XML no backend que usar SSML, não no extractor geral.

3. `chat_message_content.dart` passa a chamar o helper.

Validação:

- Testar bold/italic/link/image/headings/blockquote existentes.
- Testar fenced code block.
- Testar tabela.
- Testar lista numerada e bullet.
- Testar texto vazio após stripping não chama TTS.

### Passo 9 — Atualizar Settings > Speech com progressive disclosure

Arquivos:

- `lib/presentation/pages/settings/sections/speech_settings_section.dart`
- `lib/l10n/app_en.arb` e demais ARB conforme workflow seguro.
- `lib/presentation/providers/settings_provider.dart`

Executar:

1. Em `_buildReadAloudCard`, adicionar seletor de provider acima dos sliders:

- `System / Native`
- `Microsoft Edge Speech (experimental)`
- `OpenAI-compatible`

2. Para `native`:

- Mostrar speed.
- Mostrar pitch.
- Mostrar voice picker quando `ReadAloudService.getVoices()` retornar vozes.
- Voice picker deve salvar id e locale.

3. Para `edgeExperimental`:

- Mostrar card de aviso experimental/privacidade.
- Mostrar voice picker Edge quando a lista de vozes carregar.
- Mostrar speed.
- Ocultar ou desabilitar pitch se o backend não mapear pitch com segurança.
- Mostrar botão `Test voice`.

4. Para `openAiCompatible`:

- Mostrar base URL.
- Mostrar API key field com valor mascarado.
- Mostrar botão `Save key` ou salvar on submit.
- Mostrar model field default `gpt-4o-mini-tts`.
- Mostrar voice field/dropdown com defaults: `alloy`, `ash`, `ballad`, `coral`, `echo`, `fable`, `nova`, `onyx`, `sage`, `shimmer`, `verse`.
- Mostrar response format `mp3` inicialmente. Não expor outros formatos no v1.
- Mostrar speed.
- Ocultar/desabilitar pitch com explicação `Pitch is not supported by this provider.`
- Mostrar botão `Test voice`.

5. Mobile UX:

- Usar cards expansíveis ou seções condicionais; não mostrar todos os campos de todos os providers ao mesmo tempo.
- Evitar layout horizontal largo.

6. Erros:

- Mostrar SnackBar ou texto inline para key ausente, key inválida, quota/rate limit, network/provider unavailable.

Validação:

- Widget test ou golden simples em mobile width para provider selector e campos condicionais.
- Testar que trocar provider persiste.
- Testar API key não aparece em settings JSON.

### Passo 10 — Adicionar mensagens de erro e aviso de privacidade

Arquivos:

- `lib/presentation/services/read_aloud_service.dart`
- `lib/presentation/widgets/chat_message/chat_message_content.dart`
- `lib/presentation/pages/settings/sections/speech_settings_section.dart`
- ARB files.

Executar:

1. Adicionar ao `ReadAloudService`:

```dart
String? get lastErrorMessage;
ReadAloudErrorKind? get lastErrorKind;
```

2. Definir enum:

```dart
enum ReadAloudErrorKind {
  unavailable,
  missingApiKey,
  invalidApiKey,
  rateLimitedOrQuota,
  network,
  providerUnavailable,
  cancelled,
  unknown,
}
```

3. Não mostrar erro para `cancelled`.

4. No botão de mensagem, quando `speak()` falhar imediatamente ou `lastErrorKind` for setado, mostrar SnackBar curto.

5. Textos obrigatórios:

- Edge warning: `Microsoft Edge Speech is experimental and uses an unofficial Microsoft Edge Read Aloud endpoint. It may stop working or be rate-limited. Message text is sent to Microsoft.`
- Cloud warning: `Cloud TTS sends the selected assistant message text to the configured provider.`
- Missing key: `Add an API key in Settings > Speech to use this TTS provider.`
- Invalid key: `The TTS API key was rejected by the provider.`
- Quota/rate limit: `The TTS provider reported a quota or rate limit. Try again later or switch providers.`

Validação:

- Testar erro sem key.
- Testar 401.
- Testar 429.
- Testar cancelamento sem SnackBar.

### Passo 11 — Documentar comportamento e ADR

Arquivos:

- `BEHAVIOR.md`
- `ADR.md` via fluxo/adrkeeper se disponível.

Executar:

1. Atualizar `BEHAVIOR.md` seção TTS:

- Provider selection.
- Native default.
- Edge experimental opt-in e warning.
- OpenAI-compatible API key provider.
- Secrets stored securely.
- Cloud privacy warning.
- Auto-stop/cancelamento para síntese em andamento.
- Markdown cleanup ampliado.

2. Criar ADR ou adicionar nota em ADR existente:

- Título sugerido: `Cloud Text-to-Speech Providers with Experimental Edge Speech`.
- Decisão: client-only TTS providers; Edge experimental opt-in; OpenAI-compatible with secure storage.
- ADR-023 compatibility: no OpenCode server contract changes.
- Riscos: Edge unofficial, ToS/SLA/rate limits, third-party text egress, API key handling.
- Mitigações: opt-in, warnings, secure storage, no default Edge, native fallback available, no automatic silent fallback.

Validação:

- Docs refletem comportamento implementado, não promessa futura.

### Passo 12 — Validação final

Executar validação na ordem:

1. Formatação/análise focada:

```bash
export PATH="$HOME/flutter/bin:$PATH" && dart format lib test
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/services/read_aloud_service.dart lib/presentation/services/tts lib/domain/entities/experience_settings.dart lib/presentation/providers/settings_provider.dart lib/presentation/pages/settings/sections/speech_settings_section.dart
```

2. Testes unitários focados:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/read_aloud_service_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/read_aloud_text_extractor_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/settings_provider_test.dart
```

3. Testes adicionais criados:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/openai_compatible_tts_backend_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/edge_experimental_tts_backend_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/core/auth/tts_api_key_storage_test.dart
```

4. Gate completo quando código estiver estável:

```bash
make check
```

Não usar `make precommit` neste projeto para validação normal; o projeto orienta usar `make check` e `make android` separadamente.

## Riscos e Mitigações

### Risco crítico — API keys vazarem em settings/logs

Mitigação: API keys só em `TtsApiKeyStorage` com `flutter_secure_storage`; nunca adicionar keys a `ExperienceSettings.toJson()`; sanitizar erros/logs; criar teste que serializa settings e confirma ausência da key.

### Risco crítico — Edge experimental quebrar por endpoint não oficial

Mitigação: Edge opt-in, label experimental, warning explícito, timeout, erro claro, nunca default, ADR documentando risco. Não criar fallback automático silencioso; usuário escolhe nativo se quiser estabilidade.

### Risco alto — corrida entre cancelamento e síntese assíncrona

Mitigação: generation id obrigatório; toda resposta tardia é descartada se geração mudou; testes com backend lento e stop/session switch.

### Risco alto — UI de settings ficar confusa no mobile

Mitigação: progressive disclosure por provider; cards condicionais; campos de API key/model/baseUrl apenas para OpenAI-compatible.

### Risco médio — pitch/rate não mapearem entre providers

Mitigação: mostrar/desabilitar controles conforme provider. OpenAI-compatible usa speed derivado de rate; pitch oculto/desabilitado. Native mantém pitch.

### Risco médio — Markdown complexo soar ruim ou custar caro

Mitigação: helper testável; omitir code blocks/tabelas no v1; normalizar listas/links/headings.

### Risco médio — `audioplayers` não suportar perfeitamente long-form em todas as plataformas

Mitigação: v1 toca bytes completos; testar Android e desktop; se houver problemas graves, trocar para `just_audio` em mudança separada, não misturar sem necessidade.

## Assumptions to Validate

1. `audioplayers` consegue tocar `BytesSource` MP3 retornado por OpenAI-compatible em Android e desktop.
   - Validação: teste manual com áudio curto real ou fake integration.
   - Fallback: se falhar, adicionar `just_audio` em PR separado e adaptar apenas o playback gerado.

2. Edge protocol pode ser implementado em Dart com escopo aceitável.
   - Validação: spike isolado do backend com voz curta.
   - Fallback: entregar arquitetura + OpenAI-compatible e marcar Edge bloqueado por protocolo/ToS até decisão explícita.

3. Existing settings migration tolera novos campos nullable/default.
   - Validação: unit test com JSON antigo sem novos campos.
   - Fallback: adicionar parsing defensivo e defaults explícitos.

4. Cloud TTS deve enviar apenas texto visível do assistente, não tool metadata, hidden state, logs ou API keys.
   - Validação: testes do extractor com diferentes message parts.
   - Fallback: restringir a `TextPart` sanitizado e omitir qualquer parte não reconhecida.

## Blockers e Perguntas em Aberto

None.

O plano está pronto para implementação. A única condição de parada durante execução é se o protocolo Edge experimental se mostrar instável/grande demais para implementar com segurança; nesse caso, a execução deve entregar a arquitetura + OpenAI-compatible e registrar Edge como bloqueado, sem shippar implementação parcial.

## Testing Strategy

Testes obrigatórios:

1. `ExperienceSettings`:
   - defaults antigos continuam válidos;
   - provider default native;
   - JSON roundtrip provider/model/baseUrl/voice/locale/format;
   - API key ausente do JSON.

2. `TtsApiKeyStorage`:
   - write/read/delete;
   - trim;
   - empty deletes;
   - namespace por provider.

3. `ReadAloudService`:
   - native speak ainda funciona;
   - generated audio toca bytes;
   - stop cancela síntese lenta;
   - segunda chamada invalida primeira;
   - completion reseta estado;
   - erro reseta estado e define erro amigável;
   - cancelamento não mostra erro.

4. `OpenAiCompatibleTtsBackend`:
   - request body correto;
   - headers corretos;
   - baseUrl normalizado;
   - status 401/429/500 mapeados;
   - bytes retornados viram áudio.

5. `EdgeExperimentalTtsBackend`:
   - SSML escaping;
   - timeout;
   - close/error mapping;
   - voices parsing se implementado.

6. `ReadAloudTextExtractor`:
   - markdown básico existente;
   - fenced code blocks;
   - tables;
   - lists;
   - headings;
   - links/images;
   - whitespace.

7. UI/settings:
   - provider selector aparece;
   - campos condicionais por provider;
   - key field não mostra segredo;
   - warning Edge/cloud aparece;
   - pitch oculto/desabilitado para OpenAI-compatible.

## Handoff de Execução

Comece por estes arquivos, nesta ordem:

1. `lib/domain/entities/experience_settings.dart` — adicionar enum/config não secreto.
2. `lib/presentation/providers/settings_provider.dart` — getters/setters.
3. `lib/core/auth/tts_api_key_storage.dart` — secure storage.
4. `lib/presentation/services/tts/tts_backend.dart` — interface/modelos.
5. `lib/presentation/services/tts/native_tts_backend.dart` — wrapper de `flutter_tts` com locale corrigido.
6. `lib/presentation/services/read_aloud_service.dart` — controlador com generation cancel e generated-audio playback.
7. `lib/presentation/services/tts/openai_compatible_tts_backend.dart` — provider com API key.
8. `lib/presentation/services/tts/edge_experimental_tts_backend.dart` — provider experimental, se spike confirmar viabilidade.
9. `lib/presentation/services/tts/read_aloud_text_extractor.dart` — helper sanitizador.
10. `lib/presentation/widgets/chat_message/chat_message_content.dart` — call site e extractor.
11. `lib/presentation/pages/settings/sections/speech_settings_section.dart` — UI.
12. `lib/core/di/injection_container.dart` — DI.
13. Testes.
14. `BEHAVIOR.md` e ADR.

Strict sequencing:

- Não implemente Edge antes da abstração e do cancelamento por generation id.
- Não implemente OpenAI-compatible antes do secure storage.
- Não adicione API key a settings JSON em nenhum momento.
- Não exponha Edge como default.
- Não silencie erros cloud.

## Out of Scope

- Cache local de áudio por hash.
- Streaming progressivo real.
- Seekbar/progress UI avançado.
- ElevenLabs provider específico.
- Azure Speech provider específico.
- Google Cloud TTS.
- Amazon Polly.
- Per-agent TTS settings.
- Sumarização automática de respostas longas com modelo local/remoto.
- Envio de TTS através do servidor OpenCode.
- Mudanças no protocolo/API/event stream OpenCode.
