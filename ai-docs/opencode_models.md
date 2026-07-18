# Models | OpenCode Compatibility Notes

Last reviewed: 2026-07-18

This local anchor summarizes the model/provider compatibility details CodeWalk
needs when following ADR-023. The official OpenCode server remains the source of
truth through `/provider`, `/provider/auth`, `/config/providers`, and the OpenAPI
spec exposed at `/doc`.

## Provider And Model Discovery

- Use the live OpenCode provider endpoints instead of hardcoded provider lists
  whenever possible.
- `/provider` returns the current provider catalog and connected provider IDs.
- `/config/providers` returns configured providers and default models.
- CodeWalk must keep provider/model identifiers untranslated and preserve their
  exact wire values.
- Composer model selection follows the official connected/free model contract:
  list non-hidden, non-deprecated models from `/provider.connected`, plus dynamic
  free Zen models from provider id `opencode` where `cost.input == 0`.
- Do not hardcode CodeWalk-side model allowlists for Zen/free models; rely on the
  `/provider` payload refreshed by OpenCode from models.dev.
- Do not treat similarly named providers such as `opencode-go` as Zen/free unless
  they are reported as connected.
- Treat `catalog.updated` as a provider/model catalog invalidation signal. Keep
  the current catalog visible while one coalesced `/provider` refresh is in
  flight, then publish the server response.
- Do not infer that `integration.updated` or `integration.connection.updated`
  changed the legacy `/provider` response. Those events belong to newer
  integration lifecycle behavior and require a separate official contract
  before they can invalidate the legacy provider catalog.

## Recent OpenCode Additions

- OpenCode v1.16.x added Snowflake Cortex provider support.
- OpenCode v1.17.x added Cohere North model support and additional reasoning
  variants for existing providers.
- OpenCode v1.17.x added connector-based authentication flows and stored
  provider credentials.

## Client Requirements

- Parse model capabilities defensively. Upstream may send booleans, structured
  objects, variant maps, model `status`, or new capability fields.
- Treat unknown providers and models as valid catalog entries when OpenCode
  returns them.
- Do not infer provider availability from static CodeWalk metadata alone.
- When provider auth fails, surface the server error and allow the user to
  reconnect through the official provider auth flow.

## Relevant CodeWalk Files

- `lib/data/models/provider_model.dart`
- `lib/data/datasources/app_remote_datasource.dart`
- `lib/data/datasources/chat_remote_datasource.dart`
- `lib/presentation/providers/chat_provider.dart`
