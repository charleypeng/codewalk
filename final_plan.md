# Implement per-quick-reply agent and thinking-level selection

## Status

Ready.

## Problem

CodeWalk currently supports composer quick replies/canned answers that insert text, optionally send immediately, and can be scoped globally or to the current project context. Users now need each quick reply to optionally select an OpenCode agent and a thinking level before the reply is used. When the user selects a quick reply that has an agent or thinking-level override, CodeWalk must automatically update the active composer selection before sending. The current quick-reply add/edit dialog is already dense and will become too crowded with the new controls, so it must be redesigned into a larger responsive editor that remains usable on mobile and desktop.

## Objective

After implementation:

- A quick reply can optionally store an agent override.
- A quick reply can optionally store a thinking-level override using the existing OpenCode model variant/effort mechanism.
- Selecting a quick reply applies its agent/thinking overrides before any automatic send occurs.
- If an override cannot be honored because the active server/model/context no longer supports it, CodeWalk preserves user text and blocks automatic send rather than silently sending with the wrong agent or thinking level.
- The quick-reply add/edit surface is responsive: fullscreen on compact/mobile layouts and a large constrained dialog on wider layouts.
- Existing persisted quick replies continue to load without data loss.
- The implementation remains ADR-023 compatible: it must not add server fields, alter `prompt_async` semantics, forward `messageId`, hardcode model/agent allowlists, or mutate OpenCode config defaults.

## Context and Constraints

### Product and architecture context

- Project: CodeWalk, a Flutter mobile/desktop client for OpenCode-compatible servers.
- Mobile and desktop must both work; prioritize mobile UX, Material You, and responsive layouts.
- `BEHAVIOR.md` documents current implemented behavior only and must be updated after behavior changes.
- ADR-023 in `ADR.md` requires official OpenCode contract-first compatibility.
- Official local contract anchors:
  - `ai-docs/opencode_server.md`
  - `ai-docs/opencode_web.md`
  - `ai-docs/opencode_models.md`
- OpenChamber was checked as a secondary community reference. Its landing page shows multi-agent/model-management concepts and model cycling, but no explicit quick-reply/snippet or per-quick-reply selector pattern. Do not rely on OpenChamber for protocol semantics.

### Current quick-reply behavior

- `BEHAVIOR.md` lines 675-690 describe the current quick-reply behavior:
  - The composer extras menu opens an inline popover from the `+` button.
  - Selecting a canned answer inserts text according to `Append at cursor` or `Replace`.
  - If `Send automatically` is enabled, CodeWalk sends immediately after insertion.
  - Long-pressing a canned item opens edit/delete actions.
  - Add/edit supports optional label, required text, insertion mode, optional `Send automatically`, and scope mode (`Global` or `Project-only`).
  - Global items are available across all contexts; project-only items are restricted to active `serverId::scopeId`.
  - Rows stay compact and show one primary text source: optional label when present, otherwise canned text truncated with ellipsis.

### Key existing files

- `lib/domain/entities/canned_answer.dart`
  - Current `CannedAnswer` fields: `id`, `text`, optional `label`, `insertMode`, `sendAutomatically`, `scopeMode`, `updatedAtEpochMs`.
  - Current JSON keys include `id`, `text`, optional `label`, `insertMode`, `sendAutomatically` only when true, `scopeMode`, and `updatedAtEpochMs`.
  - `fromJson` is tolerant of legacy JSON and defaults `sendAutomatically` to `false`.
- `lib/presentation/widgets/chat_input_widget.dart`
  - `ChatInputWidget` owns composer UI state.
  - `ChatInputSubmission` currently contains `text`, `attachments`, and `mode` only.
  - `ChatComposerMode` means normal vs shell composer mode; do not reuse it for OpenCode agent selection.
  - The widget currently receives `cannedAnswersDataSource`, `cannedAnswersServerId`, and `cannedAnswersScopeId`.
- `lib/presentation/widgets/chat_input/chat_input_canned_controller.dart`
  - `_loadCannedAnswers()` loads global and project-scoped quick replies.
  - `_persistCannedAnswers()` saves JSON.
  - `_applyCannedAnswer()` inserts/replaces text and schedules `_handleSendMessage()` after the frame when `sendAutomatically` is true.
  - `_showCannedAnswerDialog()` currently uses `showDialog<CannedAnswer>` and `AlertDialog` with two text fields and three switches.
  - `_buildExtrasPopover()` renders compact one-line quick-reply rows.
- `lib/presentation/widgets/chat_input/chat_input_state_machine.dart`
  - `_handleSendMessage()` builds payload text and calls `widget.onSendMessage(ChatInputSubmission(...))`.
- `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
  - Builds `ChatInputWidget` around lines 728-837.
  - `onSendMessage` parses slash commands, calls `_prepareForOutgoingUserMessage()`, then calls `chatProvider.submitMessage(...)` with attachments/shell mode and clears file context.
- `lib/presentation/providers/chat_provider.dart`
  - Selection state includes `_selectedAgentName`, `_selectedProviderId`, `_selectedModelId`, and `_selectedVariantId`.
  - Public getters include `selectableAgents`, `selectedAgentName`, `selectedProviderId`, `selectedModelId`, `selectedVariantId`, `selectedModel`, `availableVariants`, and `selectedVariantLabel`.
  - Existing methods include `setSelectedAgent(String)`, `setSelectedVariant(String?)`, and `setSelectedModelByProvider({required String providerId, required String modelId})`.
  - Around lines 3906-3914, sends build `ChatInput(providerId, modelId, variant: _selectedVariantId, mode: selectedAgentForSend, parts: ...)`.
  - The send path intentionally does not forward `messageId`; preserve this ADR-023 invariant.
- `lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart`
  - Current composer controls include agent, model, and variant/effort chips.
  - Agent selection uses `chatProvider.selectableAgents` and `chatProvider.setSelectedAgent(...)`.
  - Variant/effort selection uses `chatProvider.availableVariants` and `chatProvider.setSelectedVariant(...)`.
  - Existing widget keys include `agent_selector_button`, `agent_selector_item_*`, `variant_selector_button`, `variant_selector_option_auto`, and `variant_selector_option_*`.
  - Sub-conversations lock or hide selector controls; quick replies must not bypass this lock.
- `lib/presentation/widgets/searchable_dropdown_form_field.dart`
  - Reusable searchable dropdown backed by a modal bottom sheet.
  - Useful for agent selection with many items.
  - It does not naturally represent a `null` selected value as an explicit selectable item, so use non-null UI sentinel values and convert them to nullable model fields.
- `lib/data/models/chat_session_model.dart`
  - `ChatInputModel.toJson()` includes `variant` when non-empty.
- `lib/data/repositories/chat_repository_impl.dart`
  - Logs provider/model/variant during send.

### Tests to extend

- `test/unit/domain/canned_answer_test.dart`
  - Currently verifies `sendAutomatically` serialization/default behavior.
- `test/widget_test.dart`
  - Current composer quick-reply widget tests cover append, replace, auto-send, focus preservation, dialog showing auto-send switch, extras actions, and global row display.
- `test/widget/chat_page_test.dart`
  - Current broader chat page tests cover agent selector, model selector, variant selector, sub-conversation locked selector behavior, and sending.

### OpenCode/ADR constraints

- `ai-docs/opencode_server.md` lines 589-611 state that `/session/:id/message` accepts `model?`, `agent?`, `parts`, and `/session/:id/prompt_async` uses the same body.
- `ai-docs/opencode_config.md` lines 525-535 state that `default_agent` must be a primary agent; invalid/subagent fallback is server-side.
- `ai-docs/opencode_models.md` requires live provider/model endpoints, untranslated provider/model identifiers, defensive model capability/variant parsing, and notes that recent OpenCode versions added reasoning variants.
- Do not add any new OpenCode payload fields for this feature.
- Do not mutate `/config`, `default_agent`, default model, or OpenCode config files for this feature.
- Do not forward a `messageId` in `prompt_async`.
- Do not hardcode agent names, model IDs, provider IDs, or thinking-level names.

## Decisions (Resolved)

1. Implement “thinking level” as the existing OpenCode model variant/effort selection, not as a new protocol field or hardcoded enum.
2. Store quick-reply thinking override as a local client-side preference that resolves into `ChatProvider.setSelectedVariant(...)` before send.
3. Store optional quick-reply agent override as a local client-side preference that resolves into `ChatProvider.setSelectedAgent(...)` before send.
4. Do not store provider/model overrides in quick replies in this implementation. Agent and thinking override only target the current composer selection model. If the selected agent changes the remembered model through existing `ChatProvider` behavior, validate the requested thinking variant after the agent switch.
5. Preserve global quick replies. A global quick reply may contain agent/thinking overrides, but those overrides are soft and must be validated against the active server/model before use.
6. If an explicit quick-reply override cannot be applied, insert the text but do not auto-send. Show an actionable snackbar so the user can review and send manually.
7. Quick replies must not bypass sub-conversation selection locks. In sub-conversations, insert text but ignore agent/thinking overrides; if `sendAutomatically` is true and the quick reply requested any override, block auto-send and show a snackbar.
8. Do not extend `ChatComposerMode` or overload `ChatInputSubmission.mode` for agent selection. Keep `ChatComposerMode` as normal/shell only.
9. Add explicit callback plumbing from `ChatInputWidget` to the chat page/provider for applying quick-reply selection overrides, rather than importing or reading `ChatProvider` directly from the quick-reply controller.
10. Redesign the add/edit editor as a responsive editor: fullscreen on compact layouts and a large constrained dialog on wider layouts. Use the same `showDialog<CannedAnswer>` result contract.
11. Use explicit non-null UI sentinel values for dropdown rows such as “Use current agent”, “Use current thinking”, and “Auto”; convert sentinels to nullable persisted fields.
12. Keep quick-reply popover rows one-line. Add only compact trailing indicators/icons/tooltips for overrides, not multi-line subtitles.

## Why This Plan

This plan keeps the feature local to CodeWalk’s existing composer selection state and official OpenCode send fields. It avoids protocol drift, preserves legacy quick-reply data, prevents wrong-agent auto-sends, and resolves the user’s UX concern by replacing the crowded alert with a responsive editor. It also explicitly handles stale agents, stale variants, global quick replies, and sub-conversation locks instead of letting those edge cases fail silently.

## Overview

Add nullable agent and thinking override fields to `CannedAnswer`. Thread selectable agent/variant data and an override callback into `ChatInputWidget`. Replace the compact quick-reply alert with a responsive editor containing content, behavior, scope, and routing sections. When a quick reply is applied, insert text first, apply overrides with validation and awaited ordering, then auto-send only if all explicit overrides were honored.

## Steps

### 1. Extend the quick-reply domain model

- **Files**:
  - `lib/domain/entities/canned_answer.dart`
  - `test/unit/domain/canned_answer_test.dart`
- **Details**:
  - Add enum:

    ```dart
    enum CannedAnswerThinkingMode { inherit, auto, variant }
    ```

  - Extend `CannedAnswer` with:

    ```dart
    final String? agentName;
    final CannedAnswerThinkingMode thinkingMode;
    final String? thinkingVariantId;
    ```

  - Constructor defaults:

    ```dart
    this.agentName,
    this.thinkingMode = CannedAnswerThinkingMode.inherit,
    this.thinkingVariantId,
    ```

  - Add these fields to `props` only if the entity later uses equality. The current file has no `Equatable`; do not introduce it just for this change.
  - Extend `copyWith` with nullable override semantics that allow clearing fields:

    ```dart
    String? Function()? agentName,
    CannedAnswerThinkingMode? thinkingMode,
    String? Function()? thinkingVariantId,
    ```

    Use the same thunk pattern already used by `label` for nullable clearable fields.
  - Extend `toJson()`:

    ```dart
    if ((agentName?.trim() ?? '').isNotEmpty) 'agentName': agentName!.trim(),
    if (thinkingMode != CannedAnswerThinkingMode.inherit)
      'thinkingMode': _thinkingModeKey(thinkingMode),
    if (thinkingMode == CannedAnswerThinkingMode.variant &&
        (thinkingVariantId?.trim() ?? '').isNotEmpty)
      'thinkingVariantId': thinkingVariantId!.trim(),
    ```

  - Do not write `thinkingVariantId` unless `thinkingMode == CannedAnswerThinkingMode.variant`.
  - Extend `fromJson()`:
    - `agentName` defaults to `null` when missing/blank.
    - `thinkingMode` defaults to `inherit` when missing/unknown.
    - `thinkingVariantId` defaults to `null` when missing/blank.
    - If `thinkingMode == variant` but `thinkingVariantId` is missing/blank, coerce `thinkingMode` to `inherit`.
  - Add helper functions:

    ```dart
    String _thinkingModeKey(CannedAnswerThinkingMode mode) { ... }
    CannedAnswerThinkingMode _thinkingModeFromKey(String value) { ... }
    ```

    Use keys: `inherit`, `auto`, `variant`.
  - Add tests in `test/unit/domain/canned_answer_test.dart`:
    - serializes/deserializes `agentName`.
    - serializes/deserializes `thinkingMode: auto` without `thinkingVariantId`.
    - serializes/deserializes `thinkingMode: variant` with `thinkingVariantId`.
    - legacy JSON without new keys yields `agentName == null`, `thinkingMode == inherit`, `thinkingVariantId == null`.
    - variant mode with missing `thinkingVariantId` falls back to `inherit`.
- **Risk**: Low. The change is backward-compatible if missing fields default correctly.
- **Validation**:
  - Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/domain/canned_answer_test.dart --plain-name CannedAnswer`

### 2. Add quick-reply override UI data types to `ChatInputWidget`

- **Files**:
  - `lib/presentation/widgets/chat_input_widget.dart`
  - `lib/presentation/widgets/chat_input_widget_types_part.dart` if the project keeps type definitions there.
- **Details**:
  - Add immutable data classes for UI-safe options:

    ```dart
    class ChatQuickReplyAgentOption {
      const ChatQuickReplyAgentOption({required this.name, required this.label});
      final String name;
      final String label;
    }

    class ChatQuickReplyThinkingOption {
      const ChatQuickReplyThinkingOption({required this.id, required this.label});
      final String id;
      final String label;
    }

    class ChatQuickReplySelectionOverride {
      const ChatQuickReplySelectionOverride({
        required this.agentName,
        required this.thinkingMode,
        required this.thinkingVariantId,
      });

      final String? agentName;
      final CannedAnswerThinkingMode thinkingMode;
      final String? thinkingVariantId;

      bool get hasExplicitOverride =>
          (agentName?.trim().isNotEmpty ?? false) ||
          thinkingMode != CannedAnswerThinkingMode.inherit;
    }

    class ChatQuickReplySelectionApplyResult {
      const ChatQuickReplySelectionApplyResult({
        required this.applied,
        this.message,
      });

      final bool applied;
      final String? message;
    }
    ```

  - Add `ChatInputWidget` constructor parameters:

    ```dart
    this.quickReplyAgentOptions = const <ChatQuickReplyAgentOption>[],
    this.quickReplyThinkingOptions = const <ChatQuickReplyThinkingOption>[],
    this.quickReplySelectedAgentName,
    this.quickReplySelectedThinkingMode = CannedAnswerThinkingMode.inherit,
    this.quickReplySelectedThinkingVariantId,
    this.onApplyQuickReplySelectionOverride,
    this.quickReplySelectionOverridesEnabled = true,
    ```

  - Add fields:

    ```dart
    final List<ChatQuickReplyAgentOption> quickReplyAgentOptions;
    final List<ChatQuickReplyThinkingOption> quickReplyThinkingOptions;
    final String? quickReplySelectedAgentName;
    final CannedAnswerThinkingMode quickReplySelectedThinkingMode;
    final String? quickReplySelectedThinkingVariantId;
    final Future<ChatQuickReplySelectionApplyResult> Function(
      ChatQuickReplySelectionOverride override,
    )? onApplyQuickReplySelectionOverride;
    final bool quickReplySelectionOverridesEnabled;
    ```

  - Do not add provider/model fields to `ChatInputSubmission` in this step. Keep the selected agent/variant mutation outside the text submission payload.
- **Risk**: Medium. Constructor changes can affect tests and call sites.
- **Validation**:
  - Run focused analyze after call sites are updated in later steps.

### 3. Pass selection data and override callback from `ChatPage`

- **Files**:
  - `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
  - `lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart` only if helper formatting functions must be reused or extracted.
- **Details**:
  - In the `ChatInputWidget` construction around `chat_page_timeline_builder.dart` lines 728-837, pass:
    - `quickReplyAgentOptions`: map `chatProvider.selectableAgents` to names and display labels. Use the same label formatting as the current agent selector when feasible; if `_formatAgentLabel` is private to the chat page extension and available from `_ChatPageState`, call it. Otherwise use `agent.name` directly and defer prettification.
    - `quickReplyThinkingOptions`: map `chatProvider.availableVariants` to id/label pairs.
    - `quickReplySelectedAgentName`: `chatProvider.selectedAgentName`.
    - `quickReplySelectedThinkingMode`: `chatProvider.selectedVariantId == null ? CannedAnswerThinkingMode.auto : CannedAnswerThinkingMode.variant` only for display defaults if needed. Persisted quick-reply defaults remain `inherit`.
    - `quickReplySelectedThinkingVariantId`: `chatProvider.selectedVariantId`.
    - `quickReplySelectionOverridesEnabled`: `!_isSubConversationSession(chatProvider.currentSession)`.
    - `onApplyQuickReplySelectionOverride`: a new async closure described below.
  - Implement the callback in the same build scope where `chatProvider` is available:

    ```dart
    onApplyQuickReplySelectionOverride: (override) async {
      final isSubConversation = _isSubConversationSession(chatProvider.currentSession);
      if (isSubConversation && override.hasExplicitOverride) {
        return ChatQuickReplySelectionApplyResult(
          applied: false,
          message: context.l10n.cannedSelectionLockedSubConversation,
        );
      }

      final agentName = override.agentName?.trim();
      if (agentName != null && agentName.isNotEmpty) {
        final exists = chatProvider.selectableAgents.any(
          (agent) => agent.name == agentName,
        );
        if (!exists) {
          return ChatQuickReplySelectionApplyResult(
            applied: false,
            message: context.l10n.cannedAgentUnavailable,
          );
        }
        await chatProvider.setSelectedAgent(agentName);
      }

      switch (override.thinkingMode) {
        case CannedAnswerThinkingMode.inherit:
          break;
        case CannedAnswerThinkingMode.auto:
          await chatProvider.setSelectedVariant(null);
          break;
        case CannedAnswerThinkingMode.variant:
          final variantId = override.thinkingVariantId?.trim();
          if (variantId == null || variantId.isEmpty) {
            return ChatQuickReplySelectionApplyResult(
              applied: false,
              message: context.l10n.cannedThinkingUnavailable,
            );
          }
          final exists = chatProvider.availableVariants.any(
            (variant) => variant.id == variantId,
          );
          if (!exists) {
            return ChatQuickReplySelectionApplyResult(
              applied: false,
              message: context.l10n.cannedThinkingUnavailable,
            );
          }
          await chatProvider.setSelectedVariant(variantId);
          break;
      }

      return const ChatQuickReplySelectionApplyResult(applied: true);
    },
    ```

  - Validate variant availability after `setSelectedAgent(...)`, not before, because `setSelectedAgent` may restore agent-specific model/variant memory.
  - Do not restore the previous agent/variant after sending. The user explicitly asked that selecting the response should change the agent automatically; the new selection should remain visible in composer controls.
- **Risk**: High. This is the critical correctness seam for wrong-agent sends.
- **Validation**:
  - Add widget tests in later steps that prove callback ordering before auto-send.

### 4. Redesign the quick-reply add/edit editor

- **Files**:
  - `lib/presentation/widgets/chat_input/chat_input_canned_controller.dart`
  - `lib/presentation/widgets/searchable_dropdown_form_field.dart` only if a small missing feature is unavoidable; prefer no changes there.
- **Details**:
  - Replace the `AlertDialog` returned by `_showCannedAnswerDialog()` with a responsive dialog shell that still returns `CannedAnswer` via `Navigator.of(context).pop(cannedAnswer)`.
  - Preserve controller lifecycle: create controllers before `showDialog`, dispose after it returns.
  - Compute compact layout inside the builder:

    ```dart
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 600;
    ```

  - Use `Dialog.fullscreen` when compact:
    - `Scaffold`
    - `AppBar` title: add/edit title.
    - leading close button.
    - save action in the app bar or bottom action row.
    - body: `SafeArea` + `ListView` with padding.
  - Use `Dialog` when not compact:
    - `insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24)`.
    - `clipBehavior: Clip.antiAlias`.
    - `SizedBox(width: 720)`.
    - `ConstrainedBox(maxHeight: min(MediaQuery.height * 0.86, 820))`.
    - header row with title and close button.
    - `Expanded` scrollable body.
    - footer action row with Cancel/Save.
  - Divide content into visually labeled sections using Material 3 spacing:
    - `Content`: label field and multiline text field.
    - `Behavior`: append/replace and send automatically.
    - `Scope`: global/project-only.
    - `Routing`: agent and thinking level.
  - Keep the multiline text field at `minLines: 3`, `maxLines: isCompact ? 8 : 6`.
  - Replace the current append/replace `SwitchListTile` with a clearer two-option control if practical:
    - Use `SegmentedButton<CannedAnswerInsertMode>` with `Append at cursor` and `Replace`.
    - If this introduces too much change, keep the switch but group it under Behavior.
  - Agent dropdown:
    - Use `SearchableDropdownFormField<String>`.
    - Build non-null item values:
      - sentinel `__cw_inherit_agent__` = “Use current agent”.
      - each actual agent name as itself.
    - `value` is actual `agentName` if non-null and currently available; otherwise sentinel.
    - If the initial stored agent is non-null and not in current options, include a disabled-looking item or helper text warning. Since `DropdownMenuItem` does not support disabled directly in this custom component, use the sentinel as selected and show a warning text below: `Saved agent is unavailable on this server.`
  - Thinking dropdown:
    - Use simple `DropdownButtonFormField<String>` or `SearchableDropdownFormField<String>`; choose `SearchableDropdownFormField` if reuse is easier and consistent.
    - Build non-null item values:
      - sentinel `__cw_inherit_thinking__` = “Use current thinking”.
      - sentinel `__cw_auto_thinking__` = “Auto”.
      - actual variant ids for current `quickReplyThinkingOptions`.
    - Convert on save:
      - inherit sentinel -> `thinkingMode: inherit`, `thinkingVariantId: null`.
      - auto sentinel -> `thinkingMode: auto`, `thinkingVariantId: null`.
      - variant id -> `thinkingMode: variant`, `thinkingVariantId: id`.
    - If no variants are available, still show `Use current thinking` and `Auto`; do not show an empty broken selector.
    - If an initial saved variant is not in current options, select inherit sentinel and show warning text below: `Saved thinking level is unavailable for the current model.`
  - Save button behavior:
    - Trim required text.
    - If text is empty, keep current dialog open and do not pop. Optionally set an inline error on the text field.
    - Create `CannedAnswer` with all old fields plus `agentName`, `thinkingMode`, and `thinkingVariantId`.
  - Add stable keys for testing:
    - `canned_answer_editor_fullscreen`
    - `canned_answer_editor_dialog`
    - `canned_answer_agent_dropdown`
    - `canned_answer_thinking_dropdown`
    - `canned_answer_text_field`
    - `canned_answer_label_field`
    - `canned_answer_save_button`
- **Risk**: Medium. UI refactor can break existing widget tests that look for current dialog structure.
- **Validation**:
  - Existing tests that find `Send automatically` and cancel should still pass after updating finder expectations if needed.
  - Add mobile/desktop layout tests in later steps.

### 5. Apply quick-reply overrides safely before auto-send

- **Files**:
  - `lib/presentation/widgets/chat_input/chat_input_canned_controller.dart`
- **Details**:
  - Add helper:

    ```dart
    bool _cannedAnswerHasSelectionOverride(CannedAnswer answer) {
      return (answer.agentName?.trim().isNotEmpty ?? false) ||
          answer.thinkingMode != CannedAnswerThinkingMode.inherit;
    }
    ```

  - Add helper to show snackbar:

    ```dart
    void _showCannedAnswerOverrideWarning(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    ```

  - Update `_applyCannedAnswer(CannedAnswer answer)` sequence:
    1. Trim right text and return if empty.
    2. Insert or replace composer text exactly as today.
    3. Update `_isComposing`, close popover, reset active suggestion index exactly as today.
    4. Build `ChatQuickReplySelectionOverride` from `answer.agentName`, `answer.thinkingMode`, and `answer.thinkingVariantId`.
    5. If `override.hasExplicitOverride` and `widget.onApplyQuickReplySelectionOverride != null`, await callback result.
    6. If callback result is not applied:
       - show callback message if present, otherwise a generic localized message.
       - call `_ensureInputFocus()`.
       - return without auto-sending even if `answer.sendAutomatically == true`.
    7. If callback is absent but override exists:
       - show generic localized message.
       - return without auto-sending.
    8. If `answer.sendAutomatically` is true, schedule `_handleSendMessage()` in a post-frame callback only after the override callback has completed successfully.
    9. If not auto-sending, call `_ensureInputFocus()`.
  - Do not call `_handleSendMessage()` before awaiting `setSelectedAgent`/`setSelectedVariant` through the callback.
  - Do not clear the composer if override application fails. The inserted text must remain editable.
  - Do not auto-send slash commands or shell commands with failed overrides. If overrides succeed, preserve current slash/shell behavior.
- **Risk**: High. This is the primary race-condition fix.
- **Validation**:
  - Add widget tests proving auto-send observes updated selection.

### 6. Add compact override indicators in the extras popover

- **Files**:
  - `lib/presentation/widgets/chat_input/chat_input_canned_controller.dart`
  - `BEHAVIOR.md` after implementation.
- **Details**:
  - Keep the existing one-line title behavior.
  - Add trailing indicators only when a quick reply has an explicit override:
    - agent override icon: `Symbols.smart_toy` or `Symbols.support_agent_rounded` if available.
    - thinking override icon: `Symbols.psychology_alt_rounded` or `Symbols.tune_rounded` if available.
  - Use a compact `Row(mainAxisSize: MainAxisSize.min, children: [...])` as `ListTile.trailing`.
  - Wrap icons in `Tooltip` on desktop where tooltips are useful:
    - agent: `Uses saved agent`.
    - thinking: `Uses saved thinking level`.
  - Do not add multi-line subtitles or long labels to the popover rows.
  - If both overrides are present, show two small icons with spacing `4`.
- **Risk**: Low. Pure UI affordance.
- **Validation**:
  - Update existing one-line popover test to ensure label/text remains single-line and indicators do not replace the primary text.

### 7. Add localization strings safely

- **Files**:
  - `tool/i18n/arb_strings.dart`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_pt.arb`
  - `lib/l10n/generated/app_localizations.dart`
  - `lib/l10n/generated/app_localizations_en.dart`
  - `lib/l10n/generated/app_localizations_pt.dart`
  - Other generated localization files if the project’s normal generation updates all locales.
- **Details**:
  - Add these English keys to `tool/i18n/arb_strings.dart`:

    ```dart
    'cannedRoutingSection': 'Routing',
    'cannedContentSection': 'Content',
    'cannedBehaviorSection': 'Behavior',
    'cannedScopeSection': 'Scope',
    'cannedAgentOverride': 'Agent',
    'cannedAgentUseCurrent': 'Use current agent',
    'cannedAgentUnavailable': 'Saved agent is unavailable on this server. Review the quick reply before sending.',
    'cannedThinkingOverride': 'Thinking level',
    'cannedThinkingUseCurrent': 'Use current thinking',
    'cannedThinkingAuto': 'Auto',
    'cannedThinkingUnavailable': 'Saved thinking level is unavailable for the current model. Review the quick reply before sending.',
    'cannedSelectionLockedSubConversation': 'Agent and thinking overrides are locked in this sub-conversation. Review the quick reply before sending.',
    'cannedOverrideApplyFailed': 'Could not apply the saved quick-reply routing. Review before sending.',
    'cannedUsesAgentOverride': 'Uses saved agent',
    'cannedUsesThinkingOverride': 'Uses saved thinking level',
    'cannedSavedAgentUnavailable': 'The saved agent is not available in the current server context.',
    'cannedSavedThinkingUnavailable': 'The saved thinking level is not available for the current model.',
    ```

  - Add Portuguese translations in the `pt` translations map:

    ```dart
    'cannedRoutingSection': 'Roteamento',
    'cannedContentSection': 'Conteúdo',
    'cannedBehaviorSection': 'Comportamento',
    'cannedScopeSection': 'Escopo',
    'cannedAgentOverride': 'Agente',
    'cannedAgentUseCurrent': 'Usar agente atual',
    'cannedAgentUnavailable': 'O agente salvo não está disponível neste servidor. Revise a resposta rápida antes de enviar.',
    'cannedThinkingOverride': 'Nível de pensamento',
    'cannedThinkingUseCurrent': 'Usar pensamento atual',
    'cannedThinkingAuto': 'Auto',
    'cannedThinkingUnavailable': 'O nível de pensamento salvo não está disponível para o modelo atual. Revise a resposta rápida antes de enviar.',
    'cannedSelectionLockedSubConversation': 'Overrides de agente e pensamento estão bloqueados nesta subconversa. Revise a resposta rápida antes de enviar.',
    'cannedOverrideApplyFailed': 'Não foi possível aplicar o roteamento salvo da resposta rápida. Revise antes de enviar.',
    'cannedUsesAgentOverride': 'Usa agente salvo',
    'cannedUsesThinkingOverride': 'Usa nível de pensamento salvo',
    'cannedSavedAgentUnavailable': 'O agente salvo não está disponível no contexto atual do servidor.',
    'cannedSavedThinkingUnavailable': 'O nível de pensamento salvo não está disponível para o modelo atual.',
    ```

  - Use the project’s safe localization workflow. Do not run a destructive global ARB generation unless `tool/i18n/arb_strings.dart` is synchronized and the repository’s current workflow expects it.
  - If generation is required and safe in the current branch, run:

    ```bash
    export PATH="$HOME/flutter/bin:$PATH" && dart tool/i18n/generate_arb.dart && flutter gen-l10n
    ```

    Only run this after confirming `arb_strings.dart` contains all existing keys.
  - If generation is not safe, manually add keys to `app_en.arb`, `app_pt.arb`, and generated localization files for English/Portuguese only, then report remaining locale fallback behavior explicitly.
- **Risk**: Medium. The repo explicitly warns that global i18n generation can be destructive when the source map is stale.
- **Validation**:
  - Run targeted analyzer after localization updates.

### 8. Update behavior documentation

- **Files**:
  - `BEHAVIOR.md`
- **Details**:
  - Update the existing section `### Composer extras menu includes canned answers and attachments` after implementation.
  - Add behavior bullets:
    - Add/edit supports optional agent and thinking-level overrides.
    - Applying a quick reply with overrides updates composer selection before send.
    - If an override is unavailable, text is inserted and automatic send is blocked with a user-visible warning.
    - In sub-conversations, quick-reply selection overrides are locked; text insertion still works, but automatic send is blocked when the quick reply depends on a locked override.
    - The editor uses a fullscreen responsive layout on compact screens and a large scrollable dialog on wider screens.
    - Rows remain compact and may show small routing indicators without adding multiline metadata.
  - Keep `BEHAVIOR.md` as implemented behavior only. Do not describe future alternatives.
- **Risk**: Low.
- **Validation**:
  - Documentation review only unless code references generated docs.

### 9. Add widget and integration-facing tests

- **Files**:
  - `test/widget_test.dart`
  - `test/widget/chat_page_test.dart` if provider-backed assertions require the full chat page harness.
- **Details**:
  - In `test/widget_test.dart`, extend `_buildChatInputHarness` only if needed to provide quick-reply options/callbacks.
  - Add tests:
    1. `new quick reply dialog shows agent and thinking selectors`:
       - Open extras.
       - Tap `New quick reply`.
       - Expect `Agent` and `Thinking level` controls.
    2. `canned answer stores selected agent and thinking override`:
       - Open dialog.
       - Enter label/text.
       - Select agent and thinking option through provided options.
       - Save.
       - Inspect in-memory stored JSON to verify fields.
    3. `canned override applies before auto-send`:
       - Configure a quick reply with `sendAutomatically: true`, `agentName: 'plan'`, and `thinkingMode: auto` or variant.
       - Provide `onApplyQuickReplySelectionOverride` that records completion before `onSendMessage` runs.
       - Assert `onSendMessage` only fires after override callback completed.
    4. `failed override inserts text and blocks auto-send`:
       - Callback returns `applied: false`.
       - Tap quick reply.
       - Assert text remains in the composer.
       - Assert no submission happened.
       - Assert snackbar appears.
    5. `compact quick reply editor uses fullscreen shell`:
       - Set surface width below 600.
       - Open editor.
       - Expect key `canned_answer_editor_fullscreen`.
    6. `wide quick reply editor uses centered dialog shell`:
       - Set surface width 1000.
       - Open editor.
       - Expect key `canned_answer_editor_dialog`.
    7. `quick reply row remains single-line with override indicators`:
       - Store quick reply with label and overrides.
       - Open extras.
       - Expect label appears once.
       - Expect override indicator tooltip/icon exists.
       - Ensure no multiline subtitle text appears.
  - In `test/widget/chat_page_test.dart`, add full-provider tests if the lightweight widget test cannot verify real `ChatProvider` effects:
    1. Selecting a quick reply with agent override updates `provider.selectedAgentName`.
    2. Selecting a quick reply with `sendAutomatically=true` sends using updated provider selection.
    3. In a sub-conversation, a quick reply with override does not change the selected agent and does not auto-send.
- **Risk**: Medium. Tests may need helper refactoring.
- **Validation**:
  - Run targeted widget tests:

    ```bash
    export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget_test.dart --plain-name canned
    export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name agent
    export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name variant
    ```

### 10. Run focused analysis and final validation

- **Files**:
  - All touched Dart files.
- **Details**:
  - Run targeted analyzer on touched source and tests:

    ```bash
    export PATH="$HOME/flutter/bin:$PATH" && flutter analyze \
      lib/domain/entities/canned_answer.dart \
      lib/presentation/widgets/chat_input_widget.dart \
      lib/presentation/widgets/chat_input/chat_input_canned_controller.dart \
      lib/presentation/pages/chat_page/chat_page_timeline_builder.dart \
      test/unit/domain/canned_answer_test.dart \
      test/widget_test.dart
    ```

  - Run focused tests:

    ```bash
    export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/domain/canned_answer_test.dart
    export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget_test.dart --plain-name canned
    ```

  - If full chat page provider tests were added, run those targeted names too.
  - Once stable, run `make check` at the validation gate if this implementation is being committed or if targeted checks do not cover all changed integration behavior:

    ```bash
    export PATH="$HOME/flutter/bin:$PATH" && make check
    ```

  - Do not run `make precommit`; CodeWalk project rules prefer `make check` and `make android` separately.
- **Risk**: Low.
- **Validation**:
  - All targeted tests pass.
  - Analyzer has no new issues.

## Risks & Mitigations

- **Critical: auto-send may use the old agent or old thinking level.**
  - Mitigation: await `onApplyQuickReplySelectionOverride` before scheduling `_handleSendMessage()`; add a test proving override callback completes before submission.
- **High: stored agent/variant can become stale across servers, projects, or model changes.**
  - Mitigation: validate against `chatProvider.selectableAgents` and `chatProvider.availableVariants` at apply time; insert text but block auto-send with snackbar when invalid.
- **High: quick replies could bypass sub-conversation selection locks.**
  - Mitigation: pass `quickReplySelectionOverridesEnabled: false` in sub-conversations; callback rejects explicit overrides and blocks auto-send.
- **Medium: thinking variant is model-specific and can be invalid after agent switch.**
  - Mitigation: validate variant after applying agent override, not before.
- **Medium: global quick replies with overrides may not be portable.**
  - Mitigation: treat overrides as soft validated preferences; never crash; never auto-send when explicit override fails.
- **Medium: editor becomes too crowded.**
  - Mitigation: responsive fullscreen/large dialog layout with sections and scrollable content.
- **Medium: localization workflow can overwrite newer ARB keys.**
  - Mitigation: update `tool/i18n/arb_strings.dart` first and only run global generation when the source map is synchronized; otherwise manually patch required generated files.
- **Low: popover row indicators can break compact layout.**
  - Mitigation: use small trailing icons/tooltips only; no subtitles.

## Assumptions to Validate

- **Assumption: “thinking level” is equivalent to existing OpenCode model variants/effort.**
  - Validation: Re-read `ai-docs/opencode_models.md` and current variant selector code before implementation.
  - Fallback if false: Stop and ask for clarification before adding any new field; do not invent a new server payload.
- **Assumption: `setSelectedAgent` followed by `setSelectedVariant` is the correct way to update send state.**
  - Validation: Inspect `ChatProvider.setSelectedAgent`, `_restoreSelectionForAgent`, and `setSelectedVariant` before coding.
  - Fallback if false: Add a provider method that atomically applies an agent + variant selection using existing internal selection rules, then use that method from the callback.
- **Assumption: sub-conversation state is detectable at the `ChatInputWidget` call site.**
  - Validation: Use existing `_isSubConversationSession(chatProvider.currentSession)` in `chat_page_timeline_builder.dart` or a nearby helper.
  - Fallback if false: Add a boolean parameter from the chat page where sub-conversation status is already known.
- **Assumption: safe i18n generation is possible from `tool/i18n/arb_strings.dart`.**
  - Validation: Confirm the file contains all current keys before running generation.
  - Fallback if false: Manually add keys to `app_en.arb`, `app_pt.arb`, and generated localization classes needed for compilation, and document that other locales fall back or need follow-up.

## Decisions and Nuances

- Do not add provider/model quick-reply overrides in this implementation. The user requested agent and thinking level only.
- Do not make quick-reply overrides temporary. When a quick reply changes agent/thinking, the visible composer selection remains changed afterward.
- Do not silently auto-send with the wrong selection. Failed explicit overrides block auto-send.
- Text insertion is always preserved even if overrides fail.
- Agent IDs/names and variant IDs are server-originated identifiers and must remain untranslated in storage and payloads. Only UI labels like “Agent” and “Use current thinking” are localized.
- The saved `agentName` must be compared exactly against `chatProvider.selectableAgents` first. Do not perform fuzzy matching that could select the wrong agent.
- The saved `thinkingVariantId` must be compared exactly against current `availableVariants` after any agent switch.
- `ChatComposerMode.shell` and slash-command handling remain independent of OpenCode agent selection. Do not repurpose `ChatComposerMode`.
- Do not forward local optimistic message IDs as `messageId`; preserve ADR-023 pitfall P-001 invariants.

## Blockers and Open Questions

None.

## Testing Strategy

1. Unit-test `CannedAnswer` serialization and legacy defaults.
2. Widget-test the quick-reply editor in compact and wide layouts.
3. Widget-test agent/thinking dropdown visibility and save behavior.
4. Widget-test override-before-auto-send ordering.
5. Widget-test stale override failure path: text inserted, auto-send blocked, snackbar shown.
6. Widget-test sub-conversation lock path if provider-backed harness supports it.
7. Run targeted analyzer on touched Dart files.
8. Run `make check` before committing or handing off as complete if implementation changes are broad enough that targeted tests are insufficient.

## Execution Handoff

Start with these files in this order:

1. `lib/domain/entities/canned_answer.dart`
   - Add persisted fields and tests first so storage semantics are stable.
2. `lib/presentation/widgets/chat_input_widget.dart`
   - Add option/result/callback types and constructor fields.
3. `lib/presentation/pages/chat_page/chat_page_timeline_builder.dart`
   - Pass current selectable agents/variants and implement the apply callback using `ChatProvider`.
4. `lib/presentation/widgets/chat_input/chat_input_canned_controller.dart`
   - Redesign editor and apply overrides before auto-send.
5. Localization files.
6. Tests.
7. `BEHAVIOR.md`.

Strict sequencing constraints:

- Do not implement auto-send override behavior before the callback plumbing exists.
- Do not add UI controls before the domain model can round-trip saved values.
- Do not run broad i18n generation until `tool/i18n/arb_strings.dart` is confirmed synchronized.
- Do not mark the feature complete until stale override and sub-conversation behavior are tested or explicitly validated manually.

## Out of Scope

- Adding provider/model quick-reply overrides.
- Editing OpenCode `default_agent`, default model, or `/config` defaults.
- Adding new OpenCode server API fields.
- Changing `prompt_async`, SSE, optimistic message ID, or message reconciliation semantics.
- Redesigning the main composer model/agent/variant chips outside the quick-reply editor.
- Implementing a new snippets system separate from existing canned answers.
- Adding OpenChamber-specific UX that is not supported by CodeWalk’s current architecture and official OpenCode-compatible contract.
