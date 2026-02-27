You are a focused subagent reviewer for a single holistic investigation batch.

Repository root: /home/helio/MEGA/WORK/codewalk
Immutable packet: /home/helio/MEGA/WORK/codewalk/.desloppify/review_packets/holistic_packet_20260225_221950.json
Batch index: 5
Batch name: Cross-cutting Sweep
Batch dimensions: error_consistency
Batch rationale: selected dimensions had no direct batch mapping; review representative cross-cutting files

Files assigned:
- lib/core/errors/failures.dart
- lib/core/logging/app_logger.dart
- lib/domain/repositories/chat_repository.dart
- lib/domain/entities/chat_session.dart
- lib/domain/entities/experience_settings.dart
- lib/core/constants/app_constants.dart
- lib/domain/entities/chat_realtime.dart
- lib/presentation/providers/settings_provider.dart
- lib/domain/entities/chat_message.dart
- lib/presentation/providers/app_provider.dart
- lib/presentation/services/file_part_action_service_io.dart
- lib/presentation/services/file_part_action_service_web.dart
- lib/presentation/widgets/permission_request_card.dart
- lib/presentation/widgets/question_request_card.dart
- lib/presentation/services/android_background_alert_worker.dart
- lib/presentation/pages/chat_page/chat_page_file_runtime.dart
- lib/presentation/providers/chat_provider.dart
- lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart
- lib/presentation/pages/onboarding_wizard_page.dart
- lib/presentation/widgets/chat_input_widget.dart
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
- lib/core/di/injection_container.dart
- lib/presentation/utils/shortcut_binding_codec.dart
- lib/data/models/chat_realtime_model.dart
- lib/presentation/theme/app_shapes.dart
- lib/domain/entities/server_profile.dart
- .claude/skills/desloppify/SKILL.md
- .dart_tool/flutter_build/dart_plugin_registrant.dart
- .dart_tool/hooks_runner/objective_c/87f123bf0143be1c3660f409017d82ce/input.json
- .desloppify/query.json
- .github/workflows/ci.yml
- .github/workflows/release.yml
- ai-docs/opencode_models.md
- ai-docs/opencode_server.md
- android/app/src/main/AndroidManifest.xml
- android/app/src/main/res/xml/network_security_config.xml
- assets/sherpa_models.json
- build/.cxx/release/l3g60191/arm64-v8a/.cmake/api/v1/reply/cmakeFiles-v1-b9d1da072bd75150a903.json
- build/.cxx/release/l3g60191/arm64-v8a/.cmake/api/v1/reply/codemodel-v2-590aa308e4269570a5d4.json
- build/.cxx/release/l3g60191/arm64-v8a/.cmake/api/v1/reply/index-2026-02-19T19-45-51-0454.json
- build/.cxx/release/l3g60191/arm64-v8a/CMakeCache.txt
- build/.cxx/release/l3g60191/arm64-v8a/CMakeFiles/3.22.1-g37088a8/CompilerIdC/CMakeCCompilerId.c
- build/.cxx/release/l3g60191/arm64-v8a/CMakeFiles/3.22.1-g37088a8/CompilerIdCXX/CMakeCXXCompilerId.cpp
- build/.cxx/release/l3g60191/armeabi-v7a/CMakeCache.txt
- build/.cxx/release/l3g60191/x86_64/.cmake/api/v1/reply/cmakeFiles-v1-356cfe3d3790e40ee320.json
- build/.cxx/release/l3g60191/x86_64/CMakeFiles/3.22.1-g37088a8/CompilerIdCXX/CMakeCXXCompilerId.cpp
- build/app/intermediates/aapt_proguard_file/release/processReleaseResources/aapt_rules.txt
- build/app/intermediates/assets/release/mergeReleaseAssets/flutter_assets/packages/record_web/assets/js/record.fixwebmduration.js
- build/app/intermediates/assets/release/mergeReleaseAssets/flutter_assets/packages/record_web/assets/js/record.worklet.js
- build/app/intermediates/combined_art_profile/release/compileReleaseArtProfile/baseline-prof.txt
- build/app/intermediates/cxx/release/l3g60191/logs/arm64-v8a/build_model.json
- build/app/intermediates/incremental/lintVitalAnalyzeRelease/module.xml
- build/app/intermediates/incremental/lintVitalAnalyzeRelease/release-artifact-dependencies.xml
- build/app/intermediates/incremental/lintVitalAnalyzeRelease/release.xml
- build/app/intermediates/incremental/release/mergeReleaseResources/merged.dir/values-af/values-af.xml
- build/app/intermediates/incremental/release/mergeReleaseResources/merged.dir/values-am/values-am.xml

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
  "batch": "Cross-cutting Sweep",
  "batch_index": 5,
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
