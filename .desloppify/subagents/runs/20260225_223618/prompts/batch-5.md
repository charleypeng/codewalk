You are a focused subagent reviewer for a single holistic investigation batch.

Repository root: /home/helio/MEGA/WORK/codewalk
Immutable packet: /home/helio/MEGA/WORK/codewalk/.desloppify/review_packets/holistic_packet_20260225_223618.json
Batch index: 5
Batch name: Full Codebase Sweep
Batch dimensions: cross_module_architecture, error_consistency, abstraction_fitness, test_strategy, design_coherence
Batch rationale: thorough default: evaluate cross-cutting quality across all production files

Files assigned:
- lib/core/config/feature_flags.dart
- lib/core/constants/api_constants.dart
- lib/core/constants/app_constants.dart
- lib/core/di/injection_container.dart
- lib/core/errors/exceptions.dart
- lib/core/errors/failures.dart
- lib/core/logging/app_logger.dart
- lib/core/network/dio_client.dart
- lib/core/network/dio_sse_adapter.dart
- lib/core/network/dio_sse_adapter_io.dart
- lib/core/network/dio_sse_adapter_stub.dart
- lib/core/utils/path_utils.dart
- lib/data/cache/chat_cache_payload_store.dart
- lib/data/cache/chat_cache_payload_store_base.dart
- lib/data/cache/chat_cache_payload_store_io.dart
- lib/data/cache/chat_cache_payload_store_stub.dart
- lib/data/datasources/app_local_datasource.dart
- lib/data/datasources/app_remote_datasource.dart
- lib/data/datasources/chat_remote_datasource.dart
- lib/data/datasources/project_remote_datasource.dart
- lib/data/models/agent_model.dart
- lib/data/models/app_info_model.dart
- lib/data/models/chat_message_model.dart
- lib/data/models/chat_realtime_model.dart
- lib/data/models/chat_session_model.dart
- lib/data/models/file_content_model.dart
- lib/data/models/file_node_model.dart
- lib/data/models/project_model.dart
- lib/data/models/provider_model.dart
- lib/data/models/session_lifecycle_model.dart
- lib/data/models/worktree_model.dart
- lib/data/repositories/app_repository_impl.dart
- lib/data/repositories/chat_repository_impl.dart
- lib/data/repositories/dio_exception_handler.dart
- lib/data/repositories/project_repository_impl.dart
- lib/domain/entities/agent.dart
- lib/domain/entities/app_info.dart
- lib/domain/entities/chat_composer_draft.dart
- lib/domain/entities/chat_message.dart
- lib/domain/entities/chat_realtime.dart
- lib/domain/entities/chat_session.dart
- lib/domain/entities/experience_settings.dart
- lib/domain/entities/file_node.dart
- lib/domain/entities/message.dart
- lib/domain/entities/project.dart
- lib/domain/entities/provider.dart
- lib/domain/entities/server_profile.dart
- lib/domain/entities/session.dart
- lib/domain/entities/worktree.dart
- lib/domain/repositories/app_repository.dart
- lib/domain/repositories/chat_repository.dart
- lib/domain/repositories/project_repository.dart
- lib/domain/usecases/abort_chat_session.dart
- lib/domain/usecases/check_connection.dart
- lib/domain/usecases/create_chat_session.dart
- lib/domain/usecases/delete_chat_session.dart
- lib/domain/usecases/fork_chat_session.dart
- lib/domain/usecases/get_agents.dart
- lib/domain/usecases/get_app_info.dart
- lib/domain/usecases/get_chat_message.dart
- lib/domain/usecases/get_chat_messages.dart
- lib/domain/usecases/get_chat_sessions.dart
- lib/domain/usecases/get_providers.dart
- lib/domain/usecases/get_session_children.dart
- lib/domain/usecases/get_session_diff.dart
- lib/domain/usecases/get_session_status.dart
- lib/domain/usecases/get_session_todo.dart
- lib/domain/usecases/list_pending_permissions.dart
- lib/domain/usecases/list_pending_questions.dart
- lib/domain/usecases/reject_question.dart
- lib/domain/usecases/reply_permission.dart
- lib/domain/usecases/reply_question.dart
- lib/domain/usecases/send_chat_message.dart
- lib/domain/usecases/share_chat_session.dart
- lib/domain/usecases/summarize_chat_session.dart
- lib/domain/usecases/unshare_chat_session.dart
- lib/domain/usecases/update_chat_session.dart
- lib/domain/usecases/update_server_config.dart
- lib/domain/usecases/watch_chat_events.dart
- lib/domain/usecases/watch_global_chat_events.dart
- lib/main.dart
- lib/presentation/pages/app_shell_page.dart
- lib/presentation/pages/chat_page.dart
- lib/presentation/pages/chat_page/chat_page_chrome.dart
- lib/presentation/pages/chat_page/chat_page_command_query.dart
- lib/presentation/pages/chat_page/chat_page_composer_status.dart
- lib/presentation/pages/chat_page/chat_page_composer_widgets.dart
- lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart
- lib/presentation/pages/chat_page/chat_page_file_runtime.dart
- lib/presentation/pages/chat_page/chat_page_file_viewer.dart
- lib/presentation/pages/chat_page/chat_page_lifecycle.dart
- lib/presentation/pages/chat_page/chat_page_model_selector_runtime.dart
- lib/presentation/pages/chat_page/chat_page_runtime_support.dart
- lib/presentation/pages/chat_page/chat_page_scaffold.dart
- lib/presentation/pages/chat_page/chat_page_scroll_coordinator.dart
- lib/presentation/pages/chat_page/chat_page_selector_flow.dart
- lib/presentation/pages/chat_page/chat_page_shortcuts.dart
- lib/presentation/pages/chat_page/chat_page_status_presenter.dart
- lib/presentation/pages/chat_page/chat_page_timeline_builder.dart
- lib/presentation/pages/chat_page/chat_page_timeline_runtime.dart
- lib/presentation/pages/chat_page/chat_page_workspace_controller.dart
- lib/presentation/pages/chat_page_types_part.dart
- lib/presentation/pages/logs_page.dart
- lib/presentation/pages/onboarding_wizard_page.dart
- lib/presentation/pages/server_settings_page.dart
- lib/presentation/pages/settings/sections/about_settings_section.dart
- lib/presentation/pages/settings/sections/appearance_settings_section.dart
- lib/presentation/pages/settings/sections/behavior_settings_section.dart
- lib/presentation/pages/settings/sections/notifications_settings_section.dart
- lib/presentation/pages/settings/sections/servers_settings_section.dart
- lib/presentation/pages/settings/sections/shortcuts_settings_section.dart
- lib/presentation/pages/settings/sections/speech_settings_section.dart
- lib/presentation/pages/settings_page.dart
- lib/presentation/providers/app_provider.dart
- lib/presentation/providers/chat_provider.dart
- lib/presentation/providers/chat_provider/chat_provider_abort_policy_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_auto_title_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_cache_persistence_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_context_state_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_core.dart
- lib/presentation/providers/chat_provider/chat_provider_error_policy.dart
- lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_message_merge_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_message_state_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_preference_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_realtime_aux_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_realtime_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_selection_helpers.dart
- lib/presentation/providers/chat_provider/chat_provider_selection_sync_ops.dart
- lib/presentation/providers/chat_provider/chat_provider_session_ops.dart
- lib/presentation/providers/chat_provider_draft_part.dart
- lib/presentation/providers/chat_provider_types_part.dart
- lib/presentation/providers/project_provider.dart
- lib/presentation/providers/settings_provider.dart
- lib/presentation/services/android_background_alert_logic.dart
- lib/presentation/services/android_background_alert_worker.dart
- lib/presentation/services/android_battery_optimization_service.dart
- lib/presentation/services/android_foreground_monitor_service.dart
- lib/presentation/services/chat_title_generator.dart
- lib/presentation/services/desktop_tray_service.dart
- lib/presentation/services/desktop_tray_service_io.dart
- lib/presentation/services/desktop_tray_service_stub.dart
- lib/presentation/services/desktop_tray_service_types.dart
- lib/presentation/services/event_feedback_dispatcher.dart
- lib/presentation/services/file_part_action_service.dart
- lib/presentation/services/file_part_action_service_io.dart
- lib/presentation/services/file_part_action_service_shared.dart
- lib/presentation/services/file_part_action_service_stub.dart
- lib/presentation/services/file_part_action_service_web.dart
- lib/presentation/services/file_part_action_types.dart
- lib/presentation/services/local_opencode_server_runtime.dart
- lib/presentation/services/local_opencode_server_runtime_io.dart
- lib/presentation/services/local_opencode_server_runtime_stub.dart
- lib/presentation/services/local_opencode_server_runtime_types.dart
- lib/presentation/services/notification_service.dart
- lib/presentation/services/notification_sound_source_service.dart
- lib/presentation/services/notification_sound_source_service_io.dart
- lib/presentation/services/notification_sound_source_service_stub.dart
- lib/presentation/services/notification_sound_source_service_types.dart
- lib/presentation/services/sherpa_model_manager.dart
- lib/presentation/services/sherpa_model_manager_io.dart
- lib/presentation/services/sherpa_model_manager_stub.dart
- lib/presentation/services/sound_service.dart
- lib/presentation/services/speech_input_service.dart
- lib/presentation/services/speech_input_service_sherpa.dart
- lib/presentation/services/speech_input_service_sherpa_io.dart
- lib/presentation/services/speech_input_service_sherpa_stub.dart
- lib/presentation/services/speech_input_service_stt.dart
- lib/presentation/services/update_check_service.dart
- lib/presentation/services/web_notification_bridge.dart
- lib/presentation/services/web_notification_bridge_stub.dart
- lib/presentation/services/web_notification_bridge_web.dart
- lib/presentation/theme/app_shapes.dart
- lib/presentation/theme/app_theme.dart
- lib/presentation/theme/brand_colors.dart
- lib/presentation/utils/chat_event_property_extractors.dart
- lib/presentation/utils/diff_parser.dart
- lib/presentation/utils/file_explorer_logic.dart
- lib/presentation/utils/reasoning_status_parser.dart
- lib/presentation/utils/session_title_formatter.dart
- lib/presentation/utils/shortcut_binding_codec.dart
- lib/presentation/utils/window_size_class.dart
- lib/presentation/widgets/chat_input/chat_input_attachment_controller.dart
- lib/presentation/widgets/chat_input/chat_input_commands_controller.dart
- lib/presentation/widgets/chat_input/chat_input_history_controller.dart
- lib/presentation/widgets/chat_input/chat_input_mentions_controller.dart
- lib/presentation/widgets/chat_input/chat_input_send_controller.dart
- lib/presentation/widgets/chat_input/chat_input_speech_controller.dart
- lib/presentation/widgets/chat_input/chat_input_state_machine.dart
- lib/presentation/widgets/chat_input/chat_input_suggestion_popover.dart
- lib/presentation/widgets/chat_input_widget.dart
- lib/presentation/widgets/chat_input_widget_types_part.dart
- lib/presentation/widgets/chat_message/chat_message_content.dart
- lib/presentation/widgets/chat_message/chat_message_file_part.dart
- lib/presentation/widgets/chat_message/chat_message_info_parts.dart
- lib/presentation/widgets/chat_message/chat_message_part_dispatch.dart
- lib/presentation/widgets/chat_message/chat_message_text_part.dart
- lib/presentation/widgets/chat_message/chat_message_tool_helpers.dart
- lib/presentation/widgets/chat_message/chat_message_tool_part.dart
- lib/presentation/widgets/chat_message_widget.dart
- lib/presentation/widgets/chat_session_list.dart
- lib/presentation/widgets/permission_request_card.dart
- lib/presentation/widgets/question_request_card.dart
- lib/presentation/widgets/session_title_inline_editor.dart
- lib/presentation/widgets/session_todo_list_widget.dart
- lib/presentation/widgets/sherpa_model_download_dialog.dart

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
  "batch": "Full Codebase Sweep",
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
