You are a focused subagent reviewer for a single holistic investigation batch.

Repository root: /home/helio/MEGA/WORK/codewalk
Immutable packet: /home/helio/MEGA/WORK/codewalk/.desloppify/review_packets/holistic_packet_20260225_221950.json
Batch index: 2
Batch name: Abstractions & Dependencies
Batch dimensions: abstraction_fitness
Batch rationale: abstraction hotspots (wrappers/interfaces/param bags), dep cycles

Files assigned:
- lib/presentation/services/android_background_alert_worker.dart
- lib/presentation/pages/chat_page/chat_page_file_runtime.dart
- lib/presentation/providers/chat_provider.dart
- lib/presentation/providers/app_provider.dart
- lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart
- lib/presentation/pages/onboarding_wizard_page.dart
- lib/presentation/widgets/chat_input_widget.dart
- lib/presentation/widgets/question_request_card.dart
- lib/core/network/dio_client.dart
- lib/presentation/widgets/chat_message/chat_message_tool_part.dart
- lib/data/models/chat_message_model.dart
- lib/presentation/pages/chat_page/chat_page_file_viewer.dart
- lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart
- lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart
- lib/presentation/widgets/chat_message_widget.dart
- lib/presentation/providers/chat_provider/chat_provider_core.dart
- lib/presentation/pages/chat_page/chat_page_lifecycle.dart
- lib/presentation/pages/logs_page.dart
- lib/presentation/pages/settings/sections/servers_settings_section.dart
- lib/presentation/pages/chat_page/chat_page_shortcuts.dart
- lib/presentation/pages/home_page.dart
- lib/presentation/pages/chat_page/chat_page_chrome.dart
- lib/presentation/widgets/chat_session_list.dart
- lib/presentation/pages/settings/sections/notifications_settings_section.dart
- lib/presentation/pages/chat_page.dart
- lib/presentation/pages/settings/sections/about_settings_section.dart
- lib/presentation/pages/chat_page/chat_page_timeline_builder.dart
- lib/presentation/pages/chat_page/chat_page_status_presenter.dart
- lib/presentation/widgets/chat_message/chat_message_info_parts.dart
- lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart
- lib/presentation/pages/chat_page/chat_page_workspace_controller.dart
- lib/presentation/pages/settings/sections/speech_settings_section.dart
- lib/presentation/widgets/chat_message/chat_message_text_part.dart

Task requirements:
1. Read the immutable packet and follow `system_prompt` constraints exactly.
2. Evaluate ONLY listed files and ONLY listed dimensions for this batch.
3. Return 0-10 high-quality findings for this batch (empty array allowed).
4. Score/finding consistency is required: broader or more severe findings MUST lower dimension scores.
5. Every finding must include `related_files` with at least 2 files when possible.
6. Every finding must include `impact_scope` and `fix_scope`.
7. Every scored dimension MUST include dimension_notes with concrete evidence.
8. If a dimension score is >85, include `unreported_risk` in dimension_notes.
9. Use exactly one decimal place for every assessment and abstraction sub-axis score.
10. Do not edit repository files.
11. Return ONLY valid JSON, no markdown fences.

Scope enums:
- impact_scope: "local" | "module" | "subsystem" | "codebase"
- fix_scope: "single_edit" | "multi_file_refactor" | "architectural_change"

Output schema:
{
  "batch": "Abstractions & Dependencies",
  "batch_index": 2,
  "assessments": {"<dimension>": <0-100 with one decimal place>},
  "dimension_notes": {
    "<dimension>": {
      "evidence": ["specific code observations"],
      "impact_scope": "local|module|subsystem|codebase",
      "fix_scope": "single_edit|multi_file_refactor|architectural_change",
      "confidence": "high|medium|low",
      "unreported_risk": "required when score >85",
      "sub_axes": {"abstraction_leverage": 0-100 with one decimal place, "indirection_cost": 0-100 with one decimal place, "interface_honesty": 0-100 with one decimal place}  // required for abstraction_fitness when evidence supports it
    }
  },
  "findings": []
}
