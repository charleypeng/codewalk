You are a focused subagent reviewer for a single holistic investigation batch.

Repository root: /home/helio/MEGA/WORK/codewalk
Immutable packet: /home/helio/MEGA/WORK/codewalk/.desloppify/review_packets/holistic_packet_20260225_221950.json
Batch index: 1
Batch name: Architecture & Coupling
Batch dimensions: cross_module_architecture
Batch rationale: god modules, import-time side effects

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
  "batch": "Architecture & Coupling",
  "batch_index": 1,
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
