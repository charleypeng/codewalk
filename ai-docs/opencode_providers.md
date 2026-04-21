Title: Providers

URL Source: https://opencode.ai/docs/providers/

Markdown Content:
# Providers | OpenCode

Using any LLM provider in OpenCode.

OpenCode uses the [AI SDK](https://ai-sdk.dev/) and [Models.dev](https://models.dev) to support **75+ LLM providers** and local models.

---

## [Core Setup](https://opencode.ai/docs/providers/#overview)

1. Add API keys using `/connect` command (stored in `auth.json`).
2. Configure via `provider` section in `opencode.json`.

### [Global Options](https://opencode.ai/docs/providers/#config)

- `baseURL`: Customize API endpoints (proxies, custom hosts).
- `timeout`: Request timeout in ms (default: 300000).
- `setCacheKey`: Ensure cache keys are set for prompt caching.

---

## [Major Providers](https://opencode.ai/docs/providers/#directory)

### [OpenCode Zen / Go](https://opencode.ai/docs/providers/#opencode-zen)
Verified models hosted by the OpenCode team. Quick setup via `/connect`.

### [Amazon Bedrock](https://opencode.ai/docs/providers/#amazon-bedrock)
Supports IAM keys, profiles, or bearer tokens. Configuration via `AWS_REGION`, `AWS_PROFILE` or `opencode.json`.

### [Anthropic](https://opencode.ai/docs/providers/#anthropic)
Native support for Claude models. Supports manual keys or OAuth.

### [Azure OpenAI](https://opencode.ai/docs/providers/#azure-openai)
Requires `AZURE_RESOURCE_NAME` and matching deployment/model names.

### [Google Vertex AI](https://opencode.ai/docs/providers/#google-vertex-ai)
Uses `GOOGLE_CLOUD_PROJECT` and `GOOGLE_APPLICATION_CREDENTIALS`.

### [DeepSeek](https://opencode.ai/docs/providers/#deepseek)
Native support for DeepSeek Reasoner and Chat.

### [GitHub Copilot](https://opencode.ai/docs/providers/#github-copilot)
Uses Copilot subscription via device login.

### [GitLab Duo](https://opencode.ai/docs/providers/#gitlab-duo)
Experimental integration with GitLab Duo Agent Platform (DAP). Supports self-hosted instances.

### [Local Models](https://opencode.ai/docs/providers/#llamacpp)
Supports **Ollama**, **LM Studio**, and **llama.cpp** via OpenAI-compatible endpoints.

---

## [Authentication Precedence](https://opencode.ai/docs/providers/#amazon-bedrock)

1. Bearer tokens (via `/connect` or env vars).
2. Provider-specific credentials (API keys, service accounts).
3. System-level credentials (AWS profiles, gcloud auth).

Last updated: Apr 21, 2026
