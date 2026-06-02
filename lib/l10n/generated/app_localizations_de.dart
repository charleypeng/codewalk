// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get appProviderCannotActivateUnhealthy =>
      'Ein fehlerhafter Server kann nicht aktiviert werden';

  @override
  String get appProviderDesktopOnly =>
      'Der verwaltete lokale Server ist nur auf dem Desktop verfügbar.';

  @override
  String get appProviderDetectingCommand => 'OpenCode-Befehl wird erkannt...';

  @override
  String get appProviderErrorCannotActivateUnhealthy =>
      'Ein fehlerhafter Server kann nicht aktiviert werden';

  @override
  String get appProviderErrorCloudflareOAuthNotSupported =>
      'Cloudflare Access OAuth wird auf dieser Plattform nicht unterstützt';

  @override
  String get appProviderErrorInstallationFailed =>
      'OpenCode-Installation fehlgeschlagen.';

  @override
  String get appProviderErrorInvalidServerUrl => 'Ungültige Server-URL';

  @override
  String get appProviderErrorLocalServerHealthCheckFailed =>
      'Der lokale Server wurde gestartet, aber der Integritätstest ist fehlgeschlagen.';

  @override
  String get appProviderErrorManagedDesktopOnly =>
      'Der verwaltete lokale Server ist nur auf dem Desktop verfügbar.';

  @override
  String get appProviderErrorServerAlreadyExists =>
      'Ein Server mit dieser URL existiert bereits';

  @override
  String get appProviderErrorServerProfileNotFound =>
      'Serverprofil nicht gefunden';

  @override
  String get appProviderErrorServerUrlRequired => 'Server-URL ist erforderlich';

  @override
  String get appProviderErrorTailscaleNotSupported =>
      'Tailscale wird auf dieser Plattform nicht unterstützt';

  @override
  String appProviderExitedWithCode(int code) {
    return 'Der lokale Server wurde mit dem Code $code beendet.';
  }

  @override
  String get appProviderFailedToStart =>
      'Fehler beim Starten des lokalen OpenCode-Servers.';

  @override
  String get appProviderInstallBinary => 'Binärdatei installieren';

  @override
  String get appProviderInstallBunOpenCode => 'Bun + OpenCode installieren';

  @override
  String get appProviderInstallSucceeded => 'Installation erfolgreich.';

  @override
  String appProviderInstallSucceededWithPath(String path) {
    return 'Installation erfolgreich. OpenCode-Befehl verfügbar unter $path.';
  }

  @override
  String get appProviderInstallViaBun => 'Über Bun installieren';

  @override
  String get appProviderInstallViaNpm => 'Über npm installieren';

  @override
  String get appProviderInstallationFailed =>
      'OpenCode-Installation fehlgeschlagen.';

  @override
  String get appProviderInstalledSuccessfully =>
      'OpenCode-Anforderungen erfolgreich installiert.';

  @override
  String get appProviderInstallingRequirements =>
      'OpenCode-Anforderungen werden installiert...';

  @override
  String get appProviderInvalidServerUrl => 'Ungültige Server-URL';

  @override
  String get appProviderLabelLocalOpenCodeManaged =>
      'Lokales OpenCode (verwaltet)';

  @override
  String get appProviderLabelPrimaryServer => 'Primärer Server';

  @override
  String get appProviderLocalManaged => 'Lokales OpenCode (verwaltet)';

  @override
  String get appProviderLocalServerStopped => 'Der lokale Server ist gestoppt.';

  @override
  String get appProviderNotDetectedInstall =>
      'OpenCode-Befehl wurde nicht erkannt. Führen Sie die Installation über den Assistenten aus.';

  @override
  String appProviderNotDetectedRefresh(String appName) {
    return 'OpenCode-Befehl wurde nicht erkannt. Falls Sie ihn gerade erst installiert haben, aktualisieren Sie die Prüfungen oder starten Sie $appName neu, um den PATH neu zu laden.';
  }

  @override
  String get appProviderOAuthNotSupported =>
      'Cloudflare Access OAuth wird auf dieser Plattform nicht unterstützt';

  @override
  String get appProviderOpenCodeDetected => 'OpenCode erkannt';

  @override
  String get appProviderOpenCodeNotDetected => 'OpenCode nicht erkannt';

  @override
  String get appProviderPrimaryServer => 'Primärer Server';

  @override
  String get appProviderProfileNotFound => 'Serverprofil nicht gefunden';

  @override
  String get appProviderRunDiagnostics =>
      'Führen Sie eine Diagnose aus, um die lokalen OpenCode-Anforderungen zu überprüfen.';

  @override
  String appProviderRunningAt(String url) {
    return 'Läuft unter $url';
  }

  @override
  String get appProviderSetupDetectingOpenCode =>
      'OpenCode-Befehl wird erkannt...';

  @override
  String get appProviderSetupInstallationSucceeded =>
      'Installation erfolgreich.';

  @override
  String appProviderSetupInstallationSucceededWithPath(String path) {
    return 'Installation erfolgreich. OpenCode-Befehl verfügbar unter $path.';
  }

  @override
  String get appProviderSetupInstallingRequirements =>
      'OpenCode-Anforderungen werden installiert...';

  @override
  String get appProviderSetupOpenCodeDetected => 'OpenCode erkannt';

  @override
  String get appProviderSetupOpenCodeNotDetected => 'OpenCode nicht erkannt';

  @override
  String get appProviderSetupOpenCodeNotDetectedInstall =>
      'OpenCode-Befehl wurde nicht erkannt. Führen Sie die Installation über den Assistenten aus.';

  @override
  String get appProviderSetupOpenCodeNotDetectedRefresh =>
      'OpenCode-Befehl wurde nicht erkannt. Falls Sie ihn gerade erst installiert haben, aktualisieren Sie die Prüfungen oder starten Sie CodeWalk neu, um den PATH neu zu laden.';

  @override
  String get appProviderSetupRequirementsInstalled =>
      'OpenCode-Anforderungen erfolgreich installiert.';

  @override
  String appProviderSetupUsingOpenCodeAt(String path) {
    return 'OpenCode-Befehl unter $path wird verwendet';
  }

  @override
  String get appProviderStartingLocalServer =>
      'Lokaler Server wird gestartet...';

  @override
  String appProviderStatusLocalServerExitedWithCode(int code) {
    return 'Der lokale Server wurde mit dem Code $code beendet.';
  }

  @override
  String get appProviderStatusLocalServerStopped =>
      'Der lokale Server ist gestoppt.';

  @override
  String appProviderStatusRunningAt(String url) {
    return 'Läuft unter $url';
  }

  @override
  String get appProviderStatusStartingLocalServer =>
      'Lokaler Server wird gestartet...';

  @override
  String get appProviderStatusStoppingLocalServer =>
      'Lokaler Server wird gestoppt...';

  @override
  String get appProviderStoppingLocalServer =>
      'Lokaler Server wird gestoppt...';

  @override
  String get appProviderTailscaleNotSupported =>
      'Tailscale wird auf dieser Plattform nicht unterstützt';

  @override
  String appProviderUsingCommandAt(String path) {
    return 'OpenCode-Befehl unter $path wird verwendet';
  }

  @override
  String get appShellDownloadingUpdate => 'Update wird heruntergeladen';

  @override
  String get appShellInstall => 'Installieren';

  @override
  String get appShellInstallFailed => 'Installation fehlgeschlagen';

  @override
  String get appShellInstallingUpdate => 'Update wird installiert...';

  @override
  String get appShellRestart => 'Neu starten';

  @override
  String appShellUpdateAvailableResult(String latestVersion) {
    return 'Update verfügbar: v$latestVersion';
  }

  @override
  String get appShellUpdateInstalledRestartApp =>
      'Update installiert. Starten Sie die App neu, um es anzuwenden.';

  @override
  String get appShellUpdateInstalledRestartRequired =>
      'Update installiert. Ein Neustart ist erforderlich, um die neue Version anzuwenden.';

  @override
  String get attachmentCouldNotDecode =>
      'Anhangsdaten konnten nicht dekodiert werden.';

  @override
  String get attachmentCouldNotDownload =>
      'Anhang konnte nicht heruntergeladen werden.';

  @override
  String get attachmentCouldNotSave =>
      'Anhang konnte auf diesem Gerät nicht gespeichert werden.';

  @override
  String get attachmentDownloadStarted => 'Download des Anhangs gestartet.';

  @override
  String get attachmentLocalNotFound =>
      'Lokaler Anhang wurde auf diesem Gerät nicht gefunden.';

  @override
  String get attachmentNoValidLocation =>
      'Anhang bietet keinen gültigen Speicherort.';

  @override
  String get attachmentNotAvailableOnPlatform =>
      'Anhangsaktionen sind auf dieser Plattform nicht verfügbar.';

  @override
  String get attachmentPathEmpty => 'Anhangspfad ist leer.';

  @override
  String get attachmentPayloadEmpty => 'Anhangs-Payload ist leer.';

  @override
  String get attachmentSaveCanceled => 'Speichern abgebrochen.';

  @override
  String attachmentSavedAndOpened(String path) {
    return 'Anhang unter $path gespeichert und geöffnet.';
  }

  @override
  String attachmentSavedPath(String path) {
    return 'Anhang unter $path gespeichert.';
  }

  @override
  String attachmentSavedTo(String path) {
    return 'Anhang unter $path gespeichert.';
  }

  @override
  String get attachmentUnableToOpenLink =>
      'Link zum Anhang konnte nicht geöffnet werden.';

  @override
  String get attachmentUnableToOpenLocal =>
      'Lokaler Anhang konnte nicht geöffnet werden.';

  @override
  String get behaviorAdvancedPermissionRule => 'Erweiterte Berechtigungsregel';

  @override
  String get behaviorAutomatic => 'Automatisch';

  @override
  String get behaviorAutomaticFallback => 'Automatischer Fallback';

  @override
  String get behaviorCellularDataSaver => 'Mobiler Datensparmodus';

  @override
  String get behaviorCellularDataSaverActive => 'Datensparmodus ist aktiv.';

  @override
  String get behaviorChatLevelShare => 'Chat-Level-Freigabe';

  @override
  String get behaviorCodeWalkReleaseChecks => 'CodeWalk-Versionsprüfungen';

  @override
  String get behaviorControlsOfficialGlobal =>
      'Steuert offizielle globale OpenCode-Einstellungen';

  @override
  String get behaviorControlsUpstreamOpenCode =>
      'Steuert Upstream-OpenCode-Einstellungen';

  @override
  String get behaviorCustomDisplayName => 'Benutzerdefinierter Anzeigename';

  @override
  String behaviorCutsAutomaticMobile(int inSeconds) {
    return 'Reduziert automatische mobile Datennutzung durch Stoppen von Hintergrund-Downloads und Drosselung automatischer Vordergrund-Aktualisierungen auf einen Burst alle $inSeconds Sekunden.';
  }

  @override
  String get behaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get behaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get behaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get behaviorDisabled => 'Deaktiviert';

  @override
  String get behaviorLightweightTasksLike => 'Leichte Aufgaben wie';

  @override
  String get behaviorManual => 'Manuell';

  @override
  String get behaviorNotify => 'Benachrichtigen';

  @override
  String get behaviorOfficialOpenCodePermission =>
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.';

  @override
  String get behaviorOpenCodeBackedDefaults => 'OpenCode-backed defaults';

  @override
  String get behaviorPermissionHandlingProvenance =>
      'Permission handling provenance';

  @override
  String get behaviorPermissionsVariantReasoning =>
      'Permissions and variant/reasoning parity stay separate until their UI can preserve advanced config safely.';

  @override
  String get behaviorPrimaryAgentAgent =>
      'Primary agent used when no agent is explicitly chosen.';

  @override
  String get behaviorRefreshDefaults => 'Refresh defaults';

  @override
  String get behaviorSharedAcrossOpenCode =>
      'Shared across OpenCode clients through config.';

  @override
  String get behaviorTheseValuesWrite =>
      'These values write to `/config` on the active server and match official OpenCode shared config.';

  @override
  String get cannedAddTitle => 'Schnellantwort hinzufügen';

  @override
  String get cannedAppendAtCursor => 'An Cursor anhängen';

  @override
  String get cannedAppendAtCursorSubtitle => 'Aus = aktuellen Text ersetzen';

  @override
  String get cannedAttachFiles => 'Attach files';

  @override
  String get cannedEditTitle => 'Schnellantwort bearbeiten';

  @override
  String get cannedNewQuickReply => 'Neue Schnellantwort';

  @override
  String get cannedNoSuggestions => 'No suggestions';

  @override
  String get cannedOffMeansReplace => 'Off means replace current composer text';

  @override
  String get cannedQuickReply => 'New quick reply';

  @override
  String get cannedReplace => 'Ersetzen';

  @override
  String get cannedScopeGlobalSubtitle =>
      'Deaktivieren für projektweites Element';

  @override
  String get cannedScopeGlobalUnavailableSubtitle =>
      'Nur-Projekt im aktuellen Kontext nicht verfügbar';

  @override
  String get cannedSendAutomaticallySubtitle => 'Sofort nach Einfügen senden';

  @override
  String get cannedSendImmediatelyInserting =>
      'Send immediately after inserting this quick reply';

  @override
  String get cannedTextLabel => 'Text';

  @override
  String get chatActionNext => 'Weiter';

  @override
  String get chatActiveServerUnhealthy =>
      'Active server is unhealthy. Sends will try once and fail fast until recovery.';

  @override
  String get chatActiveServerUnhealthyLabel =>
      'Aktiver Server ist nicht verfügbar';

  @override
  String get chatAddServerToStart => 'Add a server to start chatting.';

  @override
  String get chatAppBarMoreActions => 'More actions';

  @override
  String get chatAppBarPinAction => 'Pin to app bar';

  @override
  String get chatAppBarPinDescription =>
      'This action will stay visible outside the menu.';

  @override
  String get chatAppBarUnpinAction => 'Unpin from app bar';

  @override
  String get chatAppBarUnpinDescription =>
      'This action will move back into the menu.';

  @override
  String chatBadgeConversationError(String title) {
    return '\"$title\" hat einen Fehler.';
  }

  @override
  String chatBadgeConversationNeedsInput(String title) {
    return '\"$title\" benötigt Ihre Eingabe.';
  }

  @override
  String chatBadgeConversationNewReply(String title) {
    return '\"$title\" hat eine neue Antwort.';
  }

  @override
  String get chatBadgeDataSaverActive => 'Mobiler Datensparmodus ist aktiv.';

  @override
  String get chatBadgeServerNeedsAttention =>
      'Serververbindung benötigt Aufmerksamkeit.';

  @override
  String get chatBadgeSyncing => 'Konversationen werden synchronisiert...';

  @override
  String get chatCachedConversationsYet => 'No cached conversations yet';

  @override
  String get chatChangedFilesAvailable =>
      'No changed files are available for this session.';

  @override
  String chatChildrenChatProviderCurrentSessionChildren(int length) {
    return 'Kinder: $length';
  }

  @override
  String get chatChooseAgent => 'Agent auswählen';

  @override
  String get chatChooseDirectory => 'Choose Directory';

  @override
  String get chatChooseEffort => 'Aufwand wählen';

  @override
  String get chatChooseFolderOpen =>
      'Choose a folder to open as project context.';

  @override
  String get chatChooseModel => 'Modell auswählen';

  @override
  String get chatClose => 'Close';

  @override
  String chatCloseProject(String project) {
    return '$project schließen';
  }

  @override
  String get chatCollapseGroup => 'Gruppe einklappen';

  @override
  String get chatCommandDescriptionProject => 'Projektbefehl';

  @override
  String get chatCommandSourceGeneric => 'Befehl';

  @override
  String get chatCommandSourceProject => 'Projekt';

  @override
  String get chatCompactContext => 'Compact Context';

  @override
  String get chatComposerHintShell => 'Shell-Befehl (Esc zum Beenden)';

  @override
  String get chatComposerPlaceholder => 'Gib deine Wünsche ein...';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatConversations => 'Conversations';

  @override
  String get chatConversationsPane => 'Conversations';

  @override
  String chatCostLabel(double cost) {
    return 'Kosten: \$$cost';
  }

  @override
  String get chatCouldNotRefreshSession =>
      'Konversation konnte nicht aktualisiert werden';

  @override
  String get chatCurrent => 'Use current';

  @override
  String chatDescriptionChildren(int count) {
    return 'Unterelemente: $count';
  }

  @override
  String get chatDescriptionCloseApp =>
      'App mit dem Standard-Schließverhalten der Plattform schließen';

  @override
  String get chatDescriptionCycleModels =>
      'Kürzlich verwendete Modelle durchlaufen';

  @override
  String get chatDescriptionCycleVariant => 'Modellvariante durchlaufen';

  @override
  String get chatDescriptionDiffFilesZero => 'Diff-Dateien: 0';

  @override
  String get chatDescriptionFocusInput => 'Nachrichteneingabe fokussieren';

  @override
  String get chatDescriptionFocusOrCloseDrawer =>
      'Eingabe fokussieren (oder Seitenleiste schließen, falls offen)';

  @override
  String get chatDescriptionForceExit => 'Beenden der App erzwingen';

  @override
  String get chatDescriptionNewConversation => 'Neue Konversation';

  @override
  String get chatDescriptionNextAgent => 'Nächster Agent';

  @override
  String get chatDescriptionOpenProjects =>
      'Verwenden Sie diese Schaltfläche, um Ihre Projekte und Konversationen zu öffnen.';

  @override
  String get chatDescriptionOpenSettings => 'Einstellungen öffnen';

  @override
  String get chatDescriptionPreviousAgent => 'Vorheriger Agent';

  @override
  String get chatDescriptionProjectCommand => 'Projektbefehl';

  @override
  String get chatDescriptionQuickOpen => 'Dateien schnell öffnen';

  @override
  String get chatDescriptionRefreshData => 'Chat-Daten aktualisieren';

  @override
  String get chatDescriptionStopResponse =>
      'Aktive Antwort stoppen (während der Antwort)';

  @override
  String get chatDescriptionSwitchProject =>
      'Verwenden Sie diese Schaltfläche, um Projektordner und Kontext zu wechseln.';

  @override
  String get chatDescriptionVoiceInput => 'Spracheingabe starten oder stoppen';

  @override
  String get chatDiffFiles => 'Diff files: 0';

  @override
  String get chatDisplay => 'Display';

  @override
  String get chatDisplayToggles => 'Display toggles';

  @override
  String get chatDoubleESCStop => 'Doppelt ESC zum Stoppen';

  @override
  String get chatEffortLockedSubConversation =>
      'Aufwand in Unterkonversation gesperrt';

  @override
  String get chatExpandGroup => 'Gruppe ausklappen';

  @override
  String get chatExportCanceled => 'Sitzungsexport abgebrochen';

  @override
  String get chatFailedToLoadDirectories =>
      'Verzeichnisse konnten nicht geladen werden';

  @override
  String get chatFailedToLoadFile => 'Datei konnte nicht geladen werden';

  @override
  String get chatFailedToRefreshProviders =>
      'Anbieter und Modelle konnten nicht aktualisiert werden';

  @override
  String get chatFailedToRefreshSubConversations =>
      'Unterkonversationen konnten nicht aktualisiert werden.';

  @override
  String get chatFailedToStopResponse => 'Failed to stop current response';

  @override
  String get chatFileExplorerContents => 'Inhalte';

  @override
  String get chatFileExplorerNames => 'Namen';

  @override
  String get chatFilterActive => 'Active';

  @override
  String get chatFilterAll => 'All';

  @override
  String get chatFilterArchived => 'Archived';

  @override
  String get chatFilterDirectories => 'Filter directories';

  @override
  String get chatFilterSessions => 'Filter sessions';

  @override
  String get chatForkFailed => 'Abzweigen der Konversation fehlgeschlagen';

  @override
  String get chatForked => 'Konversation abgezweigt';

  @override
  String get chatGoToFirst => 'Go to first message';

  @override
  String get chatGoToLatest => 'Go to latest message';

  @override
  String chatGroupMessageCountMessages(
    String compactionLabel,
    String messageCount,
  ) {
    return '$messageCount Nachrichten ausgeblendet vor $compactionLabel Komprimierung';
  }

  @override
  String get chatHelloAssistant => 'Hello! I am your AI assistant';

  @override
  String get chatHelp => 'How can I help you?';

  @override
  String get chatHelpMessage =>
      'Verwenden Sie @ für Erwähnungen, ! für Shell, / für Befehle';

  @override
  String get chatHideConversationsSidebar => 'Hide Conversations sidebar';

  @override
  String get chatHideUtilitySidebar => 'Hide Utility sidebar';

  @override
  String get chatHistoryCollapsed => 'Previous history is collapsed';

  @override
  String get chatHistoryHideEarlier => 'Hide earlier messages';

  @override
  String chatHistoryMessagesHidden(int count, String label) {
    return '$count messages hidden before $label compaction';
  }

  @override
  String get chatHistoryShowEarlier => 'Show earlier messages';

  @override
  String get chatKeepWorking => 'Keep working';

  @override
  String get chatLargeContentSkipped =>
      'Große oder fehlerhafte Inhalte wurden aus Stabilitätsgründen übersprungen.';

  @override
  String get chatLatestToolActivity =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatLoadMore => 'Load more';

  @override
  String get chatLoadingProjectContext => 'Loading project context...';

  @override
  String get chatMainConversationUnavailable =>
      'Hauptkonversation noch nicht verfügbar.';

  @override
  String get chatMentionAgentSubtitle => 'Agent';

  @override
  String get chatMentionFileSubtitle => 'Datei';

  @override
  String get chatMentionSymbolSubtitle => 'Symbol';

  @override
  String get chatMessageAttachedFile => 'Angehängte Datei';

  @override
  String get chatMessageDetails => 'Details';

  @override
  String get chatMessageHide => 'Ausblenden';

  @override
  String get chatMessageLess => 'Weniger';

  @override
  String get chatMessageMessagePartUnavailable => 'Message part unavailable';

  @override
  String get chatMessageMetadataAvailable => 'No metadata available';

  @override
  String chatMessageModelMessageModelId(String modelId) {
    return 'Modell: $modelId';
  }

  @override
  String get chatMessageMore => 'Mehr';

  @override
  String get chatMessageOpenFile => 'Open file';

  @override
  String chatMessageProviderMessageProviderId(String providerId) {
    return 'Anbieter: $providerId';
  }

  @override
  String get chatMessageRewindEdit => 'Rewind and edit from here';

  @override
  String get chatMessageRunningTask => 'Running task';

  @override
  String get chatMessageSaveFile => 'Save file';

  @override
  String get chatMessageShow => 'Anzeigen';

  @override
  String get chatMessageShowLess => 'Weniger anzeigen';

  @override
  String get chatMessageShowLessCompact => 'Weniger';

  @override
  String get chatMessageShowMore => 'Mehr anzeigen';

  @override
  String get chatMessageShowMoreCompact => 'Mehr';

  @override
  String get chatMessageThinking => 'Denkt nach';

  @override
  String get chatMessageThinkingProcess => 'Thinking Process';

  @override
  String get chatMessageToolCall => '1 tool call';

  @override
  String chatMessageToolCalls(int count) {
    return '$count tool calls';
  }

  @override
  String get chatMessageToolCommand => 'Befehl';

  @override
  String get chatMessageToolCommandTruncated =>
      'Befehlsvorschau aus Stabilitätsgründen gekürzt.';

  @override
  String get chatMessageToolDiffOmitted =>
      'Diff ausgelassen – Bearbeitung zu groß für mobile Darstellung.';

  @override
  String get chatMessageToolInput => 'Eingabe';

  @override
  String get chatMessageToolInputTruncated =>
      'Eingabevorschau aus Stabilitätsgründen gekürzt.';

  @override
  String get chatMessageToolOutputTruncated =>
      'Große Ausgabe aus Stabilitätsgründen gekürzt.';

  @override
  String chatMessageToolQueuedCount(int count) {
    return '$count warten';
  }

  @override
  String chatMessageToolRunningCount(int count) {
    return '$count laufen';
  }

  @override
  String get chatMessageToolStatusInProgress => 'In progress';

  @override
  String get chatMessageToolStatusNeedsAttention => 'Needs attention';

  @override
  String get chatMessageToolStatusQueued => 'Queued';

  @override
  String get chatMessageYou => 'You';

  @override
  String get chatModelLockedSubConversation =>
      'Modell in Unterhaltung gesperrt';

  @override
  String get chatNewChat => 'New Chat';

  @override
  String get chatNewChatTourDescription => 'Start a new conversation here.';

  @override
  String get chatNewChatTourTitle => 'New chat';

  @override
  String get chatNoConversationsInProject =>
      'Keine Konversationen in diesem Projekt.';

  @override
  String get chatNoServerYet => 'No server configured yet';

  @override
  String get chatNoSessionSelected => 'Wähle oder erstelle eine Konversation';

  @override
  String get chatNoSubConversationFound => 'Keine Unterkonversation gefunden.';

  @override
  String get chatOpenFiles => 'Open Files';

  @override
  String get chatOpenProject => 'Projekt öffnen';

  @override
  String get chatOpenProjectFolder => 'Open project folder...';

  @override
  String get chatOpenProjectToLoad =>
      'Projekt öffnen, um Konversationen zu laden.';

  @override
  String get chatOpenSidebar => 'Seitenleiste öffnen';

  @override
  String get chatPageStatusAutomaticCompactionExplanation =>
      'Automatic compaction happens as context usage grows.';

  @override
  String get chatPageStatusCompactNow => 'Compact now';

  @override
  String get chatPageStatusCompacting => 'Compacting...';

  @override
  String get chatPageStatusCompactingContextNow => 'Compacting context now...';

  @override
  String get chatPageStatusContextCompacted => 'Context compacted';

  @override
  String get chatPageStatusContextUsage => 'Kontextnutzung';

  @override
  String get chatPageStatusCost => 'Kosten';

  @override
  String get chatPageStatusFailedToCompactContext =>
      'Failed to compact context';

  @override
  String get chatPageStatusLimit => 'Limit';

  @override
  String get chatPageStatusManageServers => 'Server verwalten';

  @override
  String get chatPageStatusSaver => 'Sparmodus';

  @override
  String get chatPageStatusServer => 'Server';

  @override
  String get chatPageStatusSwitchServer => 'Server wechseln';

  @override
  String get chatPageStatusTokens => 'Tokens';

  @override
  String get chatPageStatusUsage => 'Nutzung';

  @override
  String chatPageStatusUsagePercent(int usagePercent) {
    return '$usagePercent';
  }

  @override
  String get chatPermissionAutoApproveOff =>
      'Automatische Genehmigung ist deaktiviert';

  @override
  String get chatPermissionAutoApproveOn =>
      'Automatische Genehmigung ist aktiviert';

  @override
  String get chatProjectContext => 'Project Context';

  @override
  String get chatProjectContext2 => 'Projektkontext';

  @override
  String get chatRealtimeGlobalEvent => 'globales Ereignis';

  @override
  String chatRealtimeGlobalEventReason(String reason) {
    return 'globales Ereignis ($reason)';
  }

  @override
  String get chatRealtimeGlobalEventStale =>
      'globales Ereignis (veraltete Generation)';

  @override
  String chatRealtimeMessageStreamReason(String reason) {
    return 'Nachrichtenstrom ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEvent => 'Echtzeit-Ereignis';

  @override
  String chatRealtimeRealtimeEventReason(String reason) {
    return 'Echtzeit-Ereignis ($reason)';
  }

  @override
  String get chatRealtimeRealtimeEventStale =>
      'Echtzeit-Ereignis (veraltete Generation)';

  @override
  String get chatRealtimeReconnectingServerTry =>
      'Wiederverbindung mit dem Server. Versuchen Sie es in einem Moment erneut.';

  @override
  String get chatReasoning => 'Denkt nach...';

  @override
  String get chatRecentSessions => 'Recent sessions';

  @override
  String get chatRecentSessionsToggle => 'Recent sessions';

  @override
  String get chatRedoLastTurn => 'Redo last undone turn';

  @override
  String get chatRedoNothing => 'Nichts zu wiederholen in dieser Sitzung';

  @override
  String get chatRefresh => 'Refresh';

  @override
  String get chatRefreshConversation => 'Could not refresh this conversation';

  @override
  String get chatRefreshProjects => 'Refresh projects';

  @override
  String get chatRefreshSessionDetails => 'Refresh session details';

  @override
  String chatRemoveDisplayNameHistory(String displayName) {
    return '$displayName aus Verlauf entfernen';
  }

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatRetry2 => 'Retry';

  @override
  String get chatRetryRefresh => 'Retry refresh';

  @override
  String get chatRetryingModelRequest => 'Retrying model request...';

  @override
  String get chatReturnToMainConversation => 'Return to main conversation';

  @override
  String get chatReviewChanges => 'Review changes';

  @override
  String get chatSearchConversations => 'Search conversations';

  @override
  String get chatSearchNextResult => 'Next result';

  @override
  String get chatSearchNoResults => 'No results';

  @override
  String get chatSearchPreviousResult => 'Previous result';

  @override
  String chatSearchResultCount(int current, int total) {
    return 'Message $current of $total';
  }

  @override
  String get chatSearchTimeline => 'Search timeline';

  @override
  String get chatSelectDirectory => 'Select directory';

  @override
  String get chatSelectOrCreate =>
      'Select or create a conversation to start chatting';

  @override
  String get chatSelectProjectBelow => 'Select a project below.';

  @override
  String get chatServerSelectedModel => 'Vom Server ausgewähltes Modell';

  @override
  String get chatSessionActions => 'Session actions';

  @override
  String chatSessionChatSessionSession(String title) {
    return 'Chat-Sitzung: $title';
  }

  @override
  String chatSessionConversationNextAction(String nextAction) {
    return 'Konversation $nextAction';
  }

  @override
  String get chatSessionConversations => 'No conversations';

  @override
  String get chatSessionCreateConversationStart =>
      'Create a new conversation to start chatting';

  @override
  String chatSessionsLength(int length) {
    return '$length';
  }

  @override
  String get chatSetUpServer => 'Set up server';

  @override
  String get chatSettings => 'Settings';

  @override
  String get chatShortcutsCloseApp =>
      'App mit Plattform-Schließverhalten schließen';

  @override
  String get chatShortcutsCycleModels =>
      'Zuletzt verwendete Modelle durchlaufen';

  @override
  String get chatShortcutsCycleVariant => 'Modellvariante durchlaufen';

  @override
  String get chatShortcutsFocusInput => 'Nachrichteneingabe fokussieren';

  @override
  String get chatShortcutsFocusInputCloseDrawer =>
      'Eingabe fokussieren (oder Drawer schließen, wenn offen)';

  @override
  String get chatShortcutsForceExit => 'App-Beenden erzwingen';

  @override
  String get chatShortcutsNewConversation => 'Neue Konversation';

  @override
  String get chatShortcutsNextAgent => 'Nächster Agent';

  @override
  String get chatShortcutsOpenSettings => 'Einstellungen öffnen';

  @override
  String get chatShortcutsPreviousAgent => 'Vorheriger Agent';

  @override
  String get chatShortcutsQuickOpen => 'Dateien schnell öffnen';

  @override
  String get chatShortcutsRefreshChat => 'Chat-Daten aktualisieren';

  @override
  String get chatShortcutsStartStopVoice =>
      'Spracheingabe starten oder stoppen';

  @override
  String get chatShortcutsStopResponse =>
      'Aktive Antwort stoppen (während der Antwort)';

  @override
  String get chatSidebarAccess => 'Seitenleiste öffnen';

  @override
  String get chatSortMostRecent => 'Most Recent';

  @override
  String get chatSortOldest => 'Oldest';

  @override
  String get chatSortRecent => 'Recent';

  @override
  String get chatSortSessions => 'Sort sessions';

  @override
  String get chatSortTitle => 'Title';

  @override
  String get chatStartVoiceInput => 'Spracheingabe starten';

  @override
  String get chatStartingVoiceInput => 'Spracheingabe wird gestartet';

  @override
  String get chatStatusBusy => 'Status: Beschäftigt';

  @override
  String get chatStatusPatching => 'Patching';

  @override
  String chatStatusPatchingMultipleFiles(int count) {
    return '$count Dateien werden gepatcht';
  }

  @override
  String get chatStatusPatchingOneFile => '1 Datei wird gepatcht';

  @override
  String get chatStatusRetry => 'Status: Wiederholen';

  @override
  String chatStatusRetryCount(int count) {
    return 'Status: Wiederholen #$count';
  }

  @override
  String get chatStatusSubsession => 'Unter-Sitzung';

  @override
  String get chatStatusThinking => 'Nachdenken...';

  @override
  String get chatStopVoiceInput => 'Spracheingabe stoppen';

  @override
  String chatSyncLabel(String label) {
    return 'Synchronisierung: $label';
  }

  @override
  String get chatTasks => 'Tasks';

  @override
  String get chatTasksAvailableSession =>
      'No tasks are available for this session.';

  @override
  String get chatTipBeSpecific =>
      'Tipp: Seien Sie spezifisch — kürzere Prompts erhalten schnellere Antworten';

  @override
  String get chatTipBreakTasks =>
      'Tipp: Teilen Sie große Aufgaben in kleinere Prompts auf';

  @override
  String get chatTipContextKnob =>
      'Tipp: Tippen Sie auf den Kontext-Knopf, um Nutzungsdetails zu sehen';

  @override
  String get chatTipLongPressSend =>
      'Tipp: Drücken Sie lange auf Senden, um eine neue Zeile einzufügen';

  @override
  String get chatTipMentionFiles =>
      'Tipp: Verwenden Sie @, um Dateien in Ihrem Prompt zu erwähnen';

  @override
  String get chatTipProvideContext =>
      'Tipp: Geben Sie Kontext an — fügen Sie Fehlermeldungen und Logs ein';

  @override
  String get chatTipRenameConversation =>
      'Tipp: Tippen Sie auf den Titel, um eine Konversation umzubenennen';

  @override
  String get chatTipShellCommands =>
      'Tipp: Verwenden Sie ! am Anfang, um Shell-Befehle auszuführen';

  @override
  String get chatTipSlashCommands =>
      'Tipp: Verwenden Sie /, um auf Slash-Befehle zuzugreifen';

  @override
  String get chatTipStepByStep =>
      'Tipp: Fragen Sie nach Schritt-für-Schritt beim Debuggen komplexer Probleme';

  @override
  String get chatToggleSidebars => 'Toggle sidebars';

  @override
  String chatTokensLabel(int total) {
    return 'Token: $total';
  }

  @override
  String get chatTourProjectsConversations =>
      'Verwenden Sie diese Schaltfläche, um Ihre Projekte und Konversationen zu öffnen.';

  @override
  String get chatTourSidebarProjectTools =>
      'Verwenden Sie dieses Menü, um die Konversations-Seitenleiste und Projekt-Tools anzuzeigen.';

  @override
  String get chatTourSwitchFolders =>
      'Verwenden Sie diese Schaltfläche, um Projektordner und Kontext zu wechseln.';

  @override
  String get chatUndoLastTurn => 'Undo last turn';

  @override
  String get chatUndoNothing => 'Nichts rückgängig zu machen in dieser Sitzung';

  @override
  String get chatUseCurrent => 'Use current';

  @override
  String get chatWaitingForNetworkConnection =>
      'Warten auf Netzwerkverbindung...';

  @override
  String get chatWelcomeMessage => 'Hallo! Ich bin dein KI-Assistent.';

  @override
  String get chatWelcomeSubmessage => 'Wie kann ich dir heute helfen?';

  @override
  String get chatWorkBoundedPanelExplanation =>
      'Latest tool activity stays inside this bounded panel to keep the chat viewport stable.';

  @override
  String get chatWorkExpand => 'Expand';

  @override
  String get chatWorkHide => 'Hide';

  @override
  String get chatWorkMessageOne => '1 work message';

  @override
  String chatWorkMessagesMultiple(int count) {
    return '$count work messages';
  }

  @override
  String get chatWorkShow => 'Show';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCopiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonFile => 'Datei';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSave => 'Save';

  @override
  String get compactionAutomatic => 'automatisch';

  @override
  String get compactionManual => 'manuel';

  @override
  String get composerAddAttachment => 'Add attachment';

  @override
  String get composerAttachFiles => 'Attach files';

  @override
  String get composerCannedAppendAtCursor => 'Append at cursor';

  @override
  String get composerCannedLabel => 'Label (optional)';

  @override
  String get composerCannedNoReplies => 'No quick replies yet.';

  @override
  String get composerCannedReplace => 'Replace';

  @override
  String get composerCannedSave => 'Save';

  @override
  String get composerCannedScopeGlobal => 'Global';

  @override
  String get composerCannedScopeProject => 'Project-only';

  @override
  String get composerCannedSendAutomatically => 'Send automatically';

  @override
  String get composerCannedText => 'Text';

  @override
  String get composerChatInput => 'Chat input';

  @override
  String get composerDeleteAction => 'Delete';

  @override
  String get composerEdit => 'Edit';

  @override
  String get composerExtras => 'Extras';

  @override
  String get composerNewQuickReply => 'New quick reply';

  @override
  String get composerSelectImages => 'Select Images';

  @override
  String get composerSelectPdf => 'Select PDF';

  @override
  String get composerSend => 'Send';

  @override
  String get composerShellMode => 'Shell mode';

  @override
  String get dialogDownload => 'Download';

  @override
  String get dialogLanguage => 'Language';

  @override
  String get dialogMoonshineModelSize => 'Model size';

  @override
  String get dialogMoonshineVoiceSetup => 'Moonshine Voice Setup';

  @override
  String get dialogParakeetModel => 'Parakeet model';

  @override
  String get dialogParakeetVoiceSetup => 'Parakeet Voice Setup';

  @override
  String get dialogSenseVoiceModel => 'SenseVoice model';

  @override
  String get dialogSenseVoiceSetup => 'SenseVoice Setup';

  @override
  String get dialogVoiceInputSetup => 'Voice Input Setup';

  @override
  String get errorAnErrorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get errorAuthRequired => 'Authentifizierung erforderlich';

  @override
  String get errorAuthRequiredDesc =>
      'Authentifizierung fehlgeschlagen. Verbinden Sie den Anbieter erneut und versuchen Sie es noch einmal.';

  @override
  String get errorConnectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get errorConnectionFailedDesc =>
      'Der Server konnte nicht erreicht werden. Überprüfen Sie die Verbindung und den Serverstatus.';

  @override
  String get errorFormatAuthenticationFailedReconnect =>
      'Authentication failed. Reconnect the provider and try again.';

  @override
  String get errorFormatProviderTemporarilyUnavailable =>
      'Provider temporarily unavailable. Try again shortly.';

  @override
  String get errorFormatQuotaExceededCheck =>
      'Quota exceeded. Check your provider plan or billing.';

  @override
  String get errorFormatRateLimitExceeded =>
      'Rate limit exceeded. Wait a moment and try again.';

  @override
  String get errorFormatServerErrorPlease => 'Server error. Please try again.';

  @override
  String get errorFormatServiceTemporarilyUnavailable =>
      'Service temporarily unavailable. The server may be starting up — please try again shortly.';

  @override
  String get errorFormatUnableReachServer =>
      'Unable to reach the server. Check connection and server status.';

  @override
  String get errorProviderUnavailable => 'Anbieter nicht verfügbar';

  @override
  String get errorProviderUnavailableDesc =>
      'Anbieter vorübergehend nicht verfügbar. Versuchen Sie es in Kürze erneut.';

  @override
  String get errorQuotaExceeded => 'Kontingent überschritten';

  @override
  String get errorQuotaExceededDesc =>
      'Kontingent überschritten. Überprüfen Sie Ihren Anbieterplan oder Ihre Abrechnung.';

  @override
  String get errorRateLimitExceeded => 'Ratenbegrenzung überschritten';

  @override
  String get errorRateLimitExceededDesc =>
      'Ratenbegrenzung überschritten. Warten Sie einen Moment und versuchen Sie es erneut.';

  @override
  String get errorServerError => 'Serverfehler';

  @override
  String get errorServerErrorDesc =>
      'Serverfehler. Bitte versuchen Sie es erneut.';

  @override
  String get errorServiceUnavailable => 'Dienst nicht verfügbar';

  @override
  String get errorServiceUnavailableDesc =>
      'Dienst vorübergehend nicht verfügbar. Der Server fährt möglicherweise gerade hoch – bitte versuchen Sie es in Kürze erneut.';

  @override
  String get fileActionAttachmentDataDecoded =>
      'Attachment data could not be decoded.';

  @override
  String get fileActionAttachmentPathEmpty => 'Attachment path is empty.';

  @override
  String get fileActionAttachmentPayloadEmpty => 'Attachment payload is empty.';

  @override
  String get fileActionAttachmentProvideValid =>
      'Attachment does not provide a valid location.';

  @override
  String get fileActionAttachmentSavedDevice =>
      'Attachment could not be saved on this device.';

  @override
  String fileActionAttachmentSavedOutputFile(String path) {
    return 'Anhang in $path gespeichert und geöffnet.';
  }

  @override
  String fileActionAttachmentSavedOutputFile2(String path) {
    return 'Anhang in $path gespeichert.';
  }

  @override
  String fileActionAttachmentSavedSavedPath(String savedPath) {
    return 'Anhang in $savedPath gespeichert.';
  }

  @override
  String get fileActionLocalAttachmentFound =>
      'Local attachment was not found on this device.';

  @override
  String get fileActionSaveCanceled => 'Save canceled.';

  @override
  String get fileActionUnableOpenLocal =>
      'Unable to open the local attachment.';

  @override
  String get filesAddChat => 'Add to chat';

  @override
  String get filesBinaryFilePreview => 'Binary file preview is not available.';

  @override
  String get filesClear => 'Clear';

  @override
  String get filesContents => 'Contents';

  @override
  String get filesFileEmpty => 'File is empty.';

  @override
  String get filesFilesFound => 'No files found';

  @override
  String get filesHideSidebar => 'Hide Files sidebar';

  @override
  String get filesNames => 'Names';

  @override
  String filesOpenFilesFileState(int length) {
    return 'Offene Dateien ($length)';
  }

  @override
  String get filesQuickOpen => 'Quick Open';

  @override
  String get filesQuickOpenFile => 'Quick Open File';

  @override
  String get filesRefresh => 'Refresh files';

  @override
  String get filesSearchHint => 'Search files by name or path';

  @override
  String get filesTitle => 'Files';

  @override
  String get logsAppLogs => 'App Logs';

  @override
  String get logsClear => 'Clear logs';

  @override
  String get logsCloseSearch => 'Close search';

  @override
  String get logsCopyFiltered => 'Copy filtered logs';

  @override
  String get logsFilterAll => 'Alle';

  @override
  String get logsLevel => 'Level';

  @override
  String get logsNoLogsYet => 'Noch keine Logs erfasst.';

  @override
  String get logsNoMatchingLogs =>
      'Keine Logs entsprechen den aktuellen Filtern.';

  @override
  String get logsSearch => 'Search logs';

  @override
  String logsShowingOrderedLength(int length, int length2) {
    return 'Zeige $length von $length2 Einträgen';
  }

  @override
  String get logsTimeRange => 'Time range';

  @override
  String get mathExpressionLabel => 'Mathematik';

  @override
  String get mermaidCopySourceTooltip => 'Copy source';

  @override
  String get mermaidDiagramLabel => 'Mermaid Diagram';

  @override
  String get modelAuto => 'Auto';

  @override
  String get modelChooseAgent => 'Choose agent';

  @override
  String get modelFavorites => 'Favorites';

  @override
  String get modelLabelBaseEnglish => 'Basis (Englisch)';

  @override
  String get modelLabelParakeet => 'Parakeet V3 (25 europäische Sprachen)';

  @override
  String get modelLabelSenseVoice => 'SenseVoice (zh/en/ja/ko/yue)';

  @override
  String get modelLabelTinyEnglish => 'Tiny (Englisch)';

  @override
  String get modelLoadingModels => 'Loading models';

  @override
  String get modelModelsFound => 'No models found';

  @override
  String get modelRetryModels => 'Retry models';

  @override
  String get modelSearchHint => 'Search model or provider';

  @override
  String get msgBatterySettingsFailed =>
      'Could not open Android battery optimization settings.';

  @override
  String get msgBatterySettingsOpened =>
      'Android battery settings opened. Allow unrestricted battery for CodeWalk.';

  @override
  String get msgClearUsernameNeedsConfigEdit =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get msgCommandCopied => 'Command copied';

  @override
  String get msgCopiedToClipboard => 'Copied to clipboard';

  @override
  String get msgEnterUsernameToSave =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get msgFailedToSendMessage =>
      'Failed to send message. Draft kept for retry.';

  @override
  String get msgFailedToStartVoiceInput => 'Failed to start voice input';

  @override
  String msgFilePathNotFound(String path) {
    return 'File not found: $path';
  }

  @override
  String get msgFilteredLogsCopied => 'Filtered logs copied to clipboard';

  @override
  String get msgInfoAgent => 'Agent';

  @override
  String get msgInfoCompaction => 'Compaction';

  @override
  String msgInfoCost(double cost) {
    return 'Cost: \$$cost';
  }

  @override
  String get msgInfoMessageInfo => 'Message Info';

  @override
  String msgInfoModel(String modelId) {
    return 'Model: $modelId';
  }

  @override
  String get msgInfoNoMetadata => 'No metadata available';

  @override
  String msgInfoPartDescriptionModel(String description, String model) {
    return '$description$model';
  }

  @override
  String get msgInfoPatch => 'Patch';

  @override
  String msgInfoProvider(String providerId) {
    return 'Provider: $providerId';
  }

  @override
  String get msgInfoRetry => 'Retry';

  @override
  String get msgInfoSnapshot => 'Snapshot';

  @override
  String msgInfoSubtaskPartAgent(String agent) {
    return 'Teilaufgabe ($agent)';
  }

  @override
  String msgInfoTokens(int total) {
    return 'Tokens: $total';
  }

  @override
  String get msgInfoUndoThisTurn => 'Undo this turn';

  @override
  String get msgInfoView => 'View';

  @override
  String get msgNoSystemSoundsFound =>
      'No system sound was found on this device.';

  @override
  String get msgNoValidFilesSelected => 'No valid files were selected';

  @override
  String get msgReadAloud => 'Read aloud';

  @override
  String get msgReadAloudNotAvailable =>
      'Text-to-speech is not available on this device.';

  @override
  String get msgSetupDebugCopied => 'OpenCode setup debug copied to clipboard';

  @override
  String get msgShareAsImage => 'Share as image';

  @override
  String get msgShareAsImageFailed => 'Could not share message as image.';

  @override
  String get msgShareAsImageSubject => 'CodeWalk message';

  @override
  String get msgShareAsImageTooTall =>
      'Message is too long to share as an image.';

  @override
  String get msgStopReadAloud => 'Stop reading';

  @override
  String get msgSystemSoundPickerUnavailable =>
      'System sound picker is not available on this platform.';

  @override
  String get msgUpdatedButRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';

  @override
  String get msgVoiceInputUnavailable =>
      'Voice input is unavailable on this device';

  @override
  String get notifAndroidBatteryOptimization => 'Android battery optimization';

  @override
  String get notifConversationUpdates => 'Conversation updates';

  @override
  String get notifNotificationsArriveReopening =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get notifResponseRunningKeep =>
      'When a response is running, keep realtime active briefly after you leave the app.';

  @override
  String notifSelectedSoundLabel(String soundLabel) {
    return 'Ausgewählt: $soundLabel';
  }

  @override
  String get notificationAgentFinished =>
      'Der Agent hat die aktuelle Antwort beendet.';

  @override
  String get notificationConversationUpdates => 'Konversations-Updates';

  @override
  String get notificationOpenToClear =>
      'Öffnen Sie diese Konversation, um zugehörige Benachrichtigungen zu löschen.';

  @override
  String get notificationSession => 'Sitzung';

  @override
  String get notificationSoundLoadFailed =>
      'Android-Systemtöne konnten nicht geladen werden';

  @override
  String get onboardingAIGeneratedTitles => 'AI generated titles';

  @override
  String get onboardingAddServerLater =>
      'You can add a server later in Settings > Servers.';

  @override
  String get onboardingAddedButHealthCheckFailed =>
      'Server hinzugefügt, aber der Integritätstest ist fehlgeschlagen. Er fährt möglicherweise noch hoch.';

  @override
  String get onboardingAlmostInstallOpenCode =>
      'You are almost there. Install OpenCode first, then connect CodeWalk to the server URL.';

  @override
  String onboardingAppProviderLocalSetupLogsLength(int length, int length2) {
    return '$length Setup-Protokollzeilen und $length2 Setup-Ereignisse sind im separaten Setup-Debug-Bildschirm verfügbar.';
  }

  @override
  String get onboardingAuthenticate => 'Authenticate';

  @override
  String get onboardingAvailable => 'verfügbar';

  @override
  String get onboardingAvailableOnlyDesktop =>
      'Nur auf dem Desktop verfügbar (Linux/macOS/Windows).';

  @override
  String get onboardingBasicAuthTip =>
      'Aktivieren Sie die Basis-Authentifizierung nur, wenn Ihr OpenCode-Server passwortgeschützt ist.';

  @override
  String get onboardingChooseAnotherPath => 'Choose another path';

  @override
  String get onboardingChooseHowToSetup =>
      'Wählen Sie, wie Sie Ihren Server einrichten möchten';

  @override
  String get onboardingClear => 'Clear';

  @override
  String get onboardingCloudflareAuthFailed =>
      'Authentifizierung bei Cloudflare Access fehlgeschlagen.';

  @override
  String get onboardingCodeWalkAppOpenCode =>
      'CodeWalk is the app. OpenCode is the engine it connects to.';

  @override
  String get onboardingConnectRunningServer => 'Connect to a running server';

  @override
  String get onboardingConnectionIssue => 'Connection issue';

  @override
  String get onboardingConnectionSaved =>
      'Serververbindung erfolgreich gespeichert.';

  @override
  String get onboardingConnectionTips => 'Connection tips';

  @override
  String get onboardingConnectionUpdated =>
      'Serververbindung erfolgreich aktualisiert.';

  @override
  String get onboardingContinue => 'Weiter';

  @override
  String get onboardingContinueServerURL => 'Continue to server URL';

  @override
  String get onboardingCopyLoginURL => 'Copy login URL';

  @override
  String get onboardingCouldNotVerify =>
      'Serververbindung konnte nicht verifiziert werden.';

  @override
  String get onboardingDefaultURLEmulator =>
      'Default URL, emulator loopback, auth, and debug help.';

  @override
  String onboardingDesktopOnlyDiagnose(String appName) {
    return 'Nur Desktop: $appName kann OpenCode für Sie diagnostizieren, installieren und ausführen.';
  }

  @override
  String get onboardingDetailedSetupEvents =>
      'Detailed setup events were captured for troubleshooting.';

  @override
  String get onboardingDonShowAgain => 'Don\'t show again';

  @override
  String get onboardingDone => 'Fertig';

  @override
  String get onboardingEditServer => 'Server bearbeiten';

  @override
  String get onboardingEditServerConnection => 'Serververbindung bearbeiten';

  @override
  String get onboardingEmulatorRemap =>
      'Im Android-Emulator werden localhost und 127.0.0.1 automatisch auf 10.0.2.2 umgeleitet.';

  @override
  String get onboardingEnterServerUrl => 'Server-URL eingeben';

  @override
  String get onboardingExisting => 'Use Existing';

  @override
  String get onboardingExplainInstallOpenCode =>
      'Explain how to install OpenCode, start the server, and then connect from CodeWalk.';

  @override
  String get onboardingFailed => 'Fehlgeschlagen';

  @override
  String get onboardingGoodOptionDesktop => 'Good first option on desktop';

  @override
  String get onboardingHealthCheckFailedMayBeStarting =>
      'Integritätstest des Servers fehlgeschlagen. Er fährt möglicherweise noch hoch.';

  @override
  String get onboardingInstallBinary => 'Install Binary';

  @override
  String get onboardingInstallBun => 'Install via Bun';

  @override
  String get onboardingInstallBunOpenCode => 'Install Bun + OpenCode';

  @override
  String get onboardingInstallNpm => 'Install via npm';

  @override
  String get onboardingInstallRunOpenCode =>
      'Install and run OpenCode directly from CodeWalk on desktop.';

  @override
  String get onboardingInvalidUrl => 'Ungültige URL';

  @override
  String get onboardingLabel => 'Label (optional)';

  @override
  String get onboardingLabelHint => 'My server';

  @override
  String onboardingLatestOutputAppProvider(String localServerLastOutput) {
    return 'Neueste Ausgabe: $localServerLastOutput';
  }

  @override
  String get onboardingLetCodeWalkSet => 'Let CodeWalk set it up locally';

  @override
  String get onboardingLocalServerSetup => 'Lokale Server-Einrichtung';

  @override
  String get onboardingManagedLocalServer => 'Managed local server';

  @override
  String get onboardingManagedLocalServer2 =>
      'Managed local server mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String onboardingNeedsOpenCodeServer(String appName) {
    return '$appName benötigt einen OpenCode-Server, bevor es Ihnen mit Ihrem Code helfen kann.';
  }

  @override
  String get onboardingNotAvailable => 'nicht verfügbar';

  @override
  String get onboardingNotWritable => 'nicht beschreibbar';

  @override
  String get onboardingOpenCode => 'What is OpenCode?';

  @override
  String get onboardingOpenCodeRunningDevice =>
      'I already have OpenCode running on this device or somewhere on my network.';

  @override
  String get onboardingOpenCodeRunsLocally =>
      'OpenCode runs locally or on a server and powers the AI coding features inside CodeWalk. If OpenCode is already running, connect to it. If not, pick one of the guided setup paths below.';

  @override
  String get onboardingOpenTailscaleLogin =>
      'Could not open Tailscale login URL.';

  @override
  String get onboardingPassword => 'Password';

  @override
  String get onboardingPasswordRequired => 'Enter password';

  @override
  String get onboardingPickSetupPath =>
      'Wählen Sie den Einrichtungspfad, der Ihrem aktuellen OpenCode-Setup entspricht.';

  @override
  String get onboardingReachable => 'erreichbar';

  @override
  String get onboardingReady => 'Bereit';

  @override
  String get onboardingRecommendedOrderTry =>
      'Recommended order: try Install Bun + OpenCode if you want CodeWalk to bootstrap everything for you. Use Existing if OpenCode is already installed.';

  @override
  String get onboardingRefreshChecks => 'Refresh Checks';

  @override
  String get onboardingRunDiagnosticsToVerify =>
      'Führen Sie eine Diagnose aus, um die lokalen OpenCode-Anforderungen zu überprüfen.';

  @override
  String get onboardingSaveAndTest => 'Speichern und testen';

  @override
  String get onboardingServerConnectedReady =>
      'Ihr Server ist verbunden und einsatzbereit.';

  @override
  String get onboardingServerConnection => 'Serververbindung';

  @override
  String get onboardingServerSettingsSaved =>
      'Ihre Servereinstellungen wurden gespeichert und die Integritätstests wurden aktualisiert.';

  @override
  String get onboardingServerSetup => 'Server-Einrichtung';

  @override
  String get onboardingServerUpdated => 'Server aktualisiert';

  @override
  String get onboardingServerUrl => 'Server URL';

  @override
  String get onboardingSetup => 'Einrichtung';

  @override
  String get onboardingSetupWizard => 'Einrichtungsassistent';

  @override
  String get onboardingShowSetupSteps => 'Show me the setup steps';

  @override
  String get onboardingShowSetupSteps2 => 'Show setup steps';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String get onboardingSkipSetup => 'Skip setup?';

  @override
  String get onboardingStart => 'Start';

  @override
  String onboardingStartUsing(String appName) {
    return 'Beginnen Sie mit der Nutzung von $appName';
  }

  @override
  String get onboardingStarting => 'Startet';

  @override
  String get onboardingStop => 'Stop';

  @override
  String get onboardingStopped => 'Gestoppt';

  @override
  String get onboardingStopping => 'Stoppt';

  @override
  String onboardingSuggestedUrl(String url) {
    return 'Vorgeschlagene lokale OpenCode-Server-URL: $url';
  }

  @override
  String get onboardingTailscaleAdminApproval =>
      'Administrator-Genehmigung für Tailscale erforderlich';

  @override
  String get onboardingTailscaleAuthAfterSave =>
      'Tailscale wird nach dem Speichern authentifiziert';

  @override
  String onboardingTailscaleAuthAfterSaveTest(String appName) {
    return 'Nachdem Sie diesen Server gespeichert und getestet haben, öffnet $appName den Tailscale-Login, falls dieses Gerät noch nicht authentifiziert ist.';
  }

  @override
  String get onboardingTailscaleConnected => 'Tailscale verbunden';

  @override
  String get onboardingTailscaleConnecting => 'Tailscale verbindet';

  @override
  String get onboardingTailscaleConnectionFailed =>
      'Tailscale-Verbindung fehlgeschlagen';

  @override
  String get onboardingTailscaleLoginRequired => 'Tailscale-Login erforderlich';

  @override
  String get onboardingTailscaleOpenLoginUrl =>
      'Öffnen Sie die Login-URL, um dieses Gerät zu Ihrem Tailnet hinzuzufügen. Wenn sich der Browser nicht geöffnet hat, kopieren Sie die unten stehende URL.';

  @override
  String get onboardingTailscaleUnsupported => 'Tailscale nicht unterstützt';

  @override
  String get onboardingTestConnection => 'Verbindung testen';

  @override
  String get onboardingTesting => 'Teste...';

  @override
  String get onboardingUnreachable => 'nicht erreichbar';

  @override
  String get onboardingUseBasicAuth => 'Use Basic Auth';

  @override
  String get onboardingUsername => 'Username';

  @override
  String get onboardingUsernameRequired => 'Enter username';

  @override
  String get onboardingUsesServerTitle =>
      'Uses your server\'s title agent to name conversations';

  @override
  String get onboardingUsingDetectedCommand =>
      'Verwendung des erkannten OpenCode-Befehls.';

  @override
  String get onboardingViewSetupDebug => 'View setup debug';

  @override
  String onboardingWelcomeTo(String appName) {
    return 'Willkommen bei $appName';
  }

  @override
  String get onboardingWindowsTipInstalling =>
      'Windows tip: after installing, click Refresh Checks. If detection still fails, reopen CodeWalk to reload PATH changes.';

  @override
  String get onboardingWritable => 'beschreibbar';

  @override
  String get onboardingYoureAllSet => 'Alles bereit!';

  @override
  String get permissionAllowOnce => 'Allow Once';

  @override
  String get permissionAlways => 'Always';

  @override
  String get permissionBack => 'Back';

  @override
  String get permissionConfirmReject => 'Confirm Reject';

  @override
  String get permissionReject => 'Reject';

  @override
  String get permissionReopen => 'Reopen';

  @override
  String get questionAnswerSelected => 'No answer selected.';

  @override
  String get questionCommaSeparatedValues => 'Comma-separated values';

  @override
  String get questionQuestionGroupMarked =>
      'Question group marked as rejected. You can keep chatting and reopen this group anytime before confirming.';

  @override
  String get questionQuestionRequest => 'Question request';

  @override
  String get questionQuestionsProvidedSubmit =>
      'No questions provided. You can submit an empty response.';

  @override
  String get questionReviewAnswersSubmitting =>
      'Review your answers before submitting.';

  @override
  String get quotaAuthCookie => 'Auth cookie';

  @override
  String get quotaForget => 'Forget';

  @override
  String get quotaOpenCodeGoUsage => 'OpenCode Go usage';

  @override
  String get quotaOpenDashboard => 'Open OpenCode dashboard';

  @override
  String get quotaSaving => 'Saving...';

  @override
  String get quotaWorkspaceId => 'Workspace ID';

  @override
  String get serverClearOAuth => 'Clear OAuth';

  @override
  String get serverConnectionAttention =>
      'Serververbindung erfordert Aufmerksamkeit.';

  @override
  String get serverHealthHealthy => 'Verfügbar';

  @override
  String get serverHealthUnhealthy => 'Nicht verfügbar';

  @override
  String get serverHealthUnknown => 'Unbekannt';

  @override
  String get serverOAuthAuthFailed => 'OAuth authentication failed';

  @override
  String get serverOAuthChip => 'OAuth';

  @override
  String get serverOAuthNotSupported =>
      'Cloudflare Access OAuth is not supported on this platform';

  @override
  String get serverReauthenticate => 'Re-authenticate';

  @override
  String get serverTailscaleChip => 'Tailscale';

  @override
  String get serversActive => 'Active';

  @override
  String get serversActiveServer => 'Active Server';

  @override
  String get serversAddLeastOpenCode =>
      'Add at least one OpenCode server to start using the app.';

  @override
  String get serversAddServer => 'Add Server';

  @override
  String get serversCancel => 'Cancel';

  @override
  String get serversCannotActivateUnhealthy =>
      'Ein fehlerhafter Server kann nicht aktiviert werden';

  @override
  String get serversCheckHealth => 'Check Health';

  @override
  String get serversClearDefault => 'Clear Default';

  @override
  String serversCommandAppProviderLocalServerCommandPath(
    String localServerCommandPath,
  ) {
    return 'Befehl: $localServerCommandPath';
  }

  @override
  String get serversCopy => 'Copy';

  @override
  String get serversDefault => 'Default';

  @override
  String get serversDelete => 'Delete';

  @override
  String get serversDeleteServer => 'Delete server';

  @override
  String get serversDesktopModeExplanation =>
      'Der Desktop-Modus kann `opencode serve` direkt von CodeWalk aus starten und verwalten.';

  @override
  String get serversEdit => 'Edit';

  @override
  String get serversLocalOpenCodeServer => 'Local OpenCode Server';

  @override
  String get serversManagedModeAvailable =>
      'This managed mode is available only on desktop builds (Linux/macOS/Windows).';

  @override
  String get serversNoServersFound => 'Keine Server gefunden';

  @override
  String get serversRefreshHealth => 'Refresh Health';

  @override
  String serversRemoveProfileDisplayName(String displayName) {
    return '\"$displayName\" entfernen?';
  }

  @override
  String get serversSearchActiveHint => 'Aktiven Server durchsuchen';

  @override
  String get serversServersConfigured => 'No servers configured';

  @override
  String get serversSetActive => 'Set Active';

  @override
  String get serversSetDefault => 'Set Default';

  @override
  String get serversSetupDebug => 'Setup Debug';

  @override
  String get serversSetupWizard => 'Setup Wizard';

  @override
  String get serversTailscaleAdminApprovalRequired =>
      'Tailscale-Admin-Genehmigung erforderlich';

  @override
  String get serversTailscaleAuthRequired =>
      'Tailscale-Authentifizierung erforderlich';

  @override
  String get serversTailscaleConnectExplanation =>
      'Tailscale wird verbunden, wenn dieses aktive Profil verwendet wird.';

  @override
  String get serversTailscaleConnected => 'Tailscale verbunden';

  @override
  String get serversTailscaleConnecting => 'Tailscale verbindet';

  @override
  String get serversTailscaleConnectionFailed =>
      'Tailscale-Verbindung fehlgeschlagen';

  @override
  String get serversTailscaleDisconnected => 'Tailscale getrennt';

  @override
  String get serversTailscaleLoginExplanation =>
      'Öffnen Sie die Tailscale-Anmelde-URL, um dieses Gerät zu Ihrem Tailnet hinzuzufügen.';

  @override
  String get serversTailscaleTrafficExplanation =>
      'Der OpenCode-Datenverkehr für dieses aktive Profil wird über Tailscale geleitet.';

  @override
  String get serversTailscaleUnsupported => 'Tailscale nicht unterstützt';

  @override
  String get serversUnhealthyActivateError =>
      'Dieser Server ist fehlerhaft. Überprüfen Sie den Zustand oder bearbeiten Sie die Einstellungen vor der Aktivierung.';

  @override
  String get sessionActionArchived => 'archived';

  @override
  String get sessionActionDeleted => 'deleted';

  @override
  String get sessionActionForked => 'forked';

  @override
  String get sessionActionUnarchived => 'unarchived';

  @override
  String get sessionCancelRename => 'Cancel rename';

  @override
  String sessionChildrenCount(int count) {
    return 'Unterkonversationen: $count';
  }

  @override
  String get sessionCompactContext => 'Kontext komprimieren';

  @override
  String get sessionCopyLink => 'Link kopieren';

  @override
  String get sessionDelete => 'Delete';

  @override
  String get sessionDeleteTitle => 'Delete Conversation';

  @override
  String get sessionDiffChangedFile => 'Changed file';

  @override
  String get sessionDiffContentNotCaptured =>
      'File content not captured by the server';

  @override
  String sessionDiffFilesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String sessionDiffFilesCount(int count) {
    return 'Diff-Dateien: $count';
  }

  @override
  String sessionDiffLinesAddedRemoved(int added, int removed) {
    return '+$added lines added -$removed lines removed';
  }

  @override
  String sessionDiffLinesCollapsed(int count) {
    return '$count lines collapsed — tap to expand';
  }

  @override
  String get sessionDiffReview => 'Review changes';

  @override
  String get sessionDiffSplit => 'Split';

  @override
  String get sessionDiffSummary => 'Summary';

  @override
  String get sessionDiffUnified => 'Unified';

  @override
  String get sessionExportAssistant => 'Assistent';

  @override
  String get sessionExportCanceled => 'Export abgebrochen';

  @override
  String get sessionExportDebugJson => 'Als Debug-JSON exportieren';

  @override
  String get sessionExportDebugJsonErrorClipboard =>
      'Datei konnte nicht gespeichert werden; Debug-JSON in Zwischenablage';

  @override
  String get sessionExportDebugJsonSaved => 'Debug-JSON-Export gespeichert';

  @override
  String get sessionExportDebugJsonTitle =>
      'Sitzung als Debug-JSON exportieren';

  @override
  String get sessionExportError => 'Fehler:';

  @override
  String get sessionExportInput => 'Eingabe:';

  @override
  String get sessionExportMarkdown => 'Als Markdown exportieren';

  @override
  String get sessionExportMarkdownErrorClipboard =>
      'Datei konnte nicht gespeichert werden; Markdown in Zwischenablage';

  @override
  String get sessionExportMarkdownSaved => 'Markdown-Export gespeichert';

  @override
  String get sessionExportMarkdownTitle => 'Sitzung als Markdown exportieren';

  @override
  String get sessionExportOutput => 'Ausgabe:';

  @override
  String get sessionExportUntitled => 'Unbenannte Sitzung';

  @override
  String get sessionExportUser => 'Benutzer';

  @override
  String get sessionFailedRename => 'Failed to rename conversation';

  @override
  String get sessionFailedUpdateArchive => 'Failed to update archive state';

  @override
  String get sessionFailedUpdateSharing => 'Failed to update sharing state';

  @override
  String get sessionFork => 'Fork';

  @override
  String get sessionForkFailed => 'Konversation konnte nicht verzweigt werden';

  @override
  String get sessionForked => 'Konversation verzweigt';

  @override
  String sessionHasError(String title) {
    return '\"$title\" hat einen Fehler.';
  }

  @override
  String sessionHasNewReply(String title) {
    return '\"$title\" hat eine neue Antwort.';
  }

  @override
  String get sessionKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String sessionNeedsInput(String title) {
    return '\"$title\" benötigt deine Eingabe.';
  }

  @override
  String get sessionNoCachedConversations =>
      'Keine zwischengespeicherten Konversationen';

  @override
  String get sessionNoConversationsInProject =>
      'Keine Konversationen in diesem Projekt.';

  @override
  String get sessionNotAvailable =>
      'Conversation is not available for this project yet';

  @override
  String get sessionOpenProjectToLoad =>
      'Projekt öffnen, um Konversationen zu laden.';

  @override
  String get sessionRename => 'Rename';

  @override
  String get sessionRenameHint => 'Enter new conversation name';

  @override
  String get sessionRenameTitle => 'Rename Conversation';

  @override
  String get sessionSaveTitle => 'Save title';

  @override
  String get sessionShare => 'Sitzung teilen';

  @override
  String get sessionShareLinkCopied => 'Share link copied';

  @override
  String get sessionShareLinkUnavailable =>
      'Teilen-Link für diese Sitzung nicht verfügbar';

  @override
  String get sessionShared => 'Konversation geteilt';

  @override
  String get sessionSyncing => 'Konversationen werden synchronisiert...';

  @override
  String get sessionTitleHint => 'Conversation title';

  @override
  String get sessionUnshare => 'Freigabe aufheben';

  @override
  String get sessionUnshared => 'Konversation nicht mehr geteilt';

  @override
  String get sessionViewTasks => 'Aufgaben anzeigen';

  @override
  String get settingsAboutCheckForUpdates => 'Check for updates';

  @override
  String get settingsAboutCheckOnOpen => 'Check for updates on open';

  @override
  String get settingsAboutCheckOnOpenDescription =>
      'Automatically check when the app starts';

  @override
  String get settingsAboutChecking => 'Checking...';

  @override
  String get settingsAboutDescription => 'Version, updates and links';

  @override
  String get settingsAboutDismiss => 'Dismiss';

  @override
  String settingsAboutDownloading(String percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get settingsAboutEraseAllData => 'Erase all data and restart';

  @override
  String get settingsAboutInstallUpdate => 'Install update';

  @override
  String get settingsAboutInstalling => 'Installing...';

  @override
  String settingsAboutLatestVersion(String version) {
    return 'v$version is the latest version';
  }

  @override
  String get settingsAboutLoading => 'Loading...';

  @override
  String get settingsAboutReplayChatTour => 'Replay chat tour';

  @override
  String get settingsAboutReplayChatTourDescription =>
      'Close settings and show the guided chat walkthrough';

  @override
  String get settingsAboutResetApp => 'Reset app';

  @override
  String get settingsAboutResetAppQuestion => 'Reset app?';

  @override
  String get settingsAboutResetAppWarning =>
      'This will erase all servers, settings, and cached data. This action cannot be undone.';

  @override
  String get settingsAboutRetryInstall => 'Retry install';

  @override
  String get settingsAboutTapToCheck => 'Tap to check for new versions';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutUpToDate => 'You\'re up to date';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get settingsAboutUpdateInstalled =>
      'Update installed. Restart the app to apply.';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String settingsAboutVersionBuild(String buildNumber, String version) {
    return '$version (build $buildNumber)';
  }

  @override
  String get settingsAppearanceAmoledDark => 'AMOLED dark mode';

  @override
  String get settingsAppearanceAmoledDarkActive =>
      'Use pure black surfaces while dark mode is active.';

  @override
  String get settingsAppearanceAmoledDarkInactive =>
      'Switch to dark mode to enable AMOLED surfaces.';

  @override
  String get settingsAppearanceBrandColor => 'Brand color';

  @override
  String get settingsAppearanceBrandColorDynamicBlocked =>
      'Disable wallpaper colors to pick a brand color.';

  @override
  String get settingsAppearanceBrandColorNormal =>
      'Pick a seed color for the app palette.';

  @override
  String get settingsAppearanceBrandColorPresetBlocked =>
      'Switch to CodeWalk Classic to pick a brand color.';

  @override
  String get settingsAppearanceCodeWalkClassic => 'CodeWalk Classic';

  @override
  String get settingsAppearanceComposerTips => 'Composer tips';

  @override
  String get settingsAppearanceComposerTipsDescription =>
      'Show or hide rotating tips while the assistant is reasoning.';

  @override
  String get settingsAppearanceContrast => 'Contrast';

  @override
  String get settingsAppearanceContrastDynamicBlocked =>
      'Disable wallpaper colors to adjust contrast.';

  @override
  String get settingsAppearanceContrastHigh => 'High';

  @override
  String get settingsAppearanceContrastNormal =>
      'Adjust the contrast level of the color scheme.';

  @override
  String get settingsAppearanceContrastPresetBlocked =>
      'Switch to CodeWalk Classic to adjust contrast.';

  @override
  String get settingsAppearanceContrastReduced => 'Reduced';

  @override
  String get settingsAppearanceDark => 'Dark';

  @override
  String get settingsAppearanceDensity => 'Density';

  @override
  String get settingsAppearanceDensityDense => 'Dense';

  @override
  String get settingsAppearanceDensityDescription =>
      'Apply spacing and component density across the app.';

  @override
  String get settingsAppearanceDensityExtraDense => 'Extra Dense';

  @override
  String get settingsAppearanceDensityExtraSpacious => 'Extra Spacious';

  @override
  String get settingsAppearanceDensityNormal => 'Normal';

  @override
  String get settingsAppearanceDensitySpacious => 'Spacious';

  @override
  String get settingsAppearanceDescription =>
      'Density and timeline bubble visibility';

  @override
  String get settingsAppearanceLight => 'Light';

  @override
  String get settingsAppearanceMathRendering => 'Mathematik-Rendering';

  @override
  String get settingsAppearanceMathRenderingDescription =>
      'LaTeX-Mathematik-Ausdrücke als gesetzte Gleichungen in Chat-Nachrichten darstellen.';

  @override
  String get settingsAppearanceNoPresets => 'No preset palettes found';

  @override
  String get settingsAppearanceOpenCodePresets => 'OpenCode Presets';

  @override
  String get settingsAppearancePresetHelper =>
      'Mirrors the official OpenCode Web built-in theme list.';

  @override
  String get settingsAppearancePresetNote =>
      'Theme colors now follow the official OpenCode Web registry and drive markdown/code surfaces too.';

  @override
  String get settingsAppearancePresetPalette => 'Preset palette';

  @override
  String get settingsAppearanceSearchPreset => 'Search preset palette';

  @override
  String get settingsAppearanceSectionDescription =>
      'Tune visual density and message surfaces for your workflow.';

  @override
  String get settingsAppearanceSectionTitle => 'Appearance';

  @override
  String get settingsAppearanceSystem => 'System';

  @override
  String get settingsAppearanceTaskList => 'Task list';

  @override
  String get settingsAppearanceTaskListDescription =>
      'Show or hide the session task list widget.';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAppearanceThemeDescription =>
      'Choose light, dark, or system mode, then keep the CodeWalk classic palette or switch to an OpenCode preset.';

  @override
  String get settingsAppearanceThinkingBubbles => 'Thinking bubbles';

  @override
  String get settingsAppearanceThinkingBubblesDescription =>
      'Show or hide reasoning blocks in assistant messages.';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceToolCallBubbles => 'Tool call bubbles';

  @override
  String get settingsAppearanceToolCallBubblesDescription =>
      'Show or hide tool execution cards in assistant messages.';

  @override
  String get settingsAppearanceWallpaperColors => 'Use wallpaper colors';

  @override
  String get settingsAppearanceWallpaperNormal =>
      'Extract color scheme from your device wallpaper.';

  @override
  String get settingsAppearanceWallpaperPresetBlocked =>
      'Switch to CodeWalk Classic to use wallpaper colors.';

  @override
  String get settingsBack => 'Back';

  @override
  String get settingsBehaviorAutoupdateCaveat =>
      'Use About for CodeWalk release checks. This setting only mirrors the official OpenCode `autoupdate` config.';

  @override
  String get settingsBehaviorAutoupdateHelp =>
      'Controls upstream OpenCode runtime updates, not CodeWalk app update checks.';

  @override
  String get settingsBehaviorCellularDataSaver => 'Cellular data saver';

  @override
  String get settingsBehaviorConfigDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String settingsBehaviorConfigUpdateFailed(String field) {
    return 'Could not update the OpenCode $field.';
  }

  @override
  String get settingsBehaviorConversationUsername => 'Conversation username';

  @override
  String get settingsBehaviorConversationUsernameHelp =>
      'Custom display name shown in conversations instead of the system username.';

  @override
  String get settingsBehaviorDataSaverActive => 'Active now on mobile data.';

  @override
  String get settingsBehaviorDataSaverCellularOnly =>
      'Only applies when the connection is cellular/mobile.';

  @override
  String get settingsBehaviorDataSaverDescription =>
      'Cuts automatic mobile-data usage by stopping background downloads and throttling automatic foreground refreshes.';

  @override
  String get settingsBehaviorDataSaverWaiting =>
      'Waiting for the next mobile-data sync window.';

  @override
  String get settingsBehaviorDefaultAgent => 'Default agent';

  @override
  String get settingsBehaviorDefaultAgentHelp =>
      'Primary agent used when no agent is explicitly chosen.';

  @override
  String get settingsBehaviorDefaultModel => 'Default model';

  @override
  String get settingsBehaviorDefaultModelHelp =>
      'Shared across OpenCode clients through config.';

  @override
  String get settingsBehaviorDescription =>
      'OpenCode defaults, provenance, and composer sync safety';

  @override
  String get settingsBehaviorEnableDataSaver => 'Enable cellular data saver';

  @override
  String get settingsBehaviorMultiDeviceSync =>
      'Enable experimental multi-device sync';

  @override
  String get settingsBehaviorMultiDeviceSyncDescription =>
      'Sync composer selection (agent/model/variant) with the active server config.';

  @override
  String get settingsBehaviorMultiDeviceSyncWarning =>
      'Can abort ongoing sessions when working in more than one session at the same time.';

  @override
  String get settingsBehaviorNoAgents => 'No agents found';

  @override
  String get settingsBehaviorNoModels => 'No models found';

  @override
  String get settingsBehaviorOpenCodeAutoupdate => 'OpenCode auto-update';

  @override
  String get settingsBehaviorOpenCodeDefaults => 'OpenCode-backed defaults';

  @override
  String get settingsBehaviorOpenCodeDefaultsDescription =>
      'These values write to `/config` on the active server and match official OpenCode shared config.';

  @override
  String get settingsBehaviorOpenCodeSnapshots => 'OpenCode snapshots';

  @override
  String get settingsBehaviorOpenCodeSnapshotsDescription =>
      'Keep upstream git-backed snapshots enabled for undo/redo and recovery history.';

  @override
  String get settingsBehaviorPermissionDeferred =>
      'Advanced permission rule editing stays out of Settings for now and is deferred to later parity work.';

  @override
  String get settingsBehaviorPermissionProvenance =>
      'Permission handling provenance';

  @override
  String get settingsBehaviorPermissionProvenanceDescription =>
      'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.';

  @override
  String get settingsBehaviorRefreshDefaults => 'Refresh defaults';

  @override
  String get settingsBehaviorSaveUsername => 'Save username';

  @override
  String get settingsBehaviorSearchAutoupdate => 'Search auto-update mode';

  @override
  String get settingsBehaviorSearchDefaultAgent => 'Search default agent';

  @override
  String get settingsBehaviorSearchDefaultModel => 'Search default model';

  @override
  String get settingsBehaviorSearchShareMode => 'Search sharing mode';

  @override
  String get settingsBehaviorSearchSmallModel => 'Search small model';

  @override
  String get settingsBehaviorShareMode => 'OpenCode sharing default';

  @override
  String get settingsBehaviorShareModeCaveat =>
      'Use the chat-level share action to publish one session now. This setting only changes OpenCode\'s default sharing policy.';

  @override
  String get settingsBehaviorShareModeHelp =>
      'Controls the official global `share` config, not the share button for an individual chat.';

  @override
  String get settingsBehaviorSmallModel => 'Small model';

  @override
  String get settingsBehaviorSmallModelAutoFallback => 'Automatic fallback';

  @override
  String get settingsBehaviorSmallModelFallbackActive =>
      'OpenCode automatic fallback is active because `small_model` is unset.';

  @override
  String get settingsBehaviorSmallModelHelp =>
      'Used for lightweight tasks like title generation.';

  @override
  String get settingsBehaviorSmallModelResetCaveat =>
      'Resetting `small_model` back to automatic fallback still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsBehaviorSnapshotCaveat =>
      'This controls OpenCode snapshot storage and undo/redo support, not CodeWalk local cache snapshots.';

  @override
  String get settingsBehaviorTitle => 'Behavior';

  @override
  String get settingsBehaviorUsernameFallback =>
      'OpenCode uses the system username because `username` is unset.';

  @override
  String get settingsBehaviorUsernamePatchCaveat =>
      'Resetting `username` back to the system default still requires editing config outside the app because `/config` patch updates cannot remove keys.';

  @override
  String get settingsConfigRefreshFailed =>
      'Updated the server setting, but could not refresh chat providers.';

  @override
  String get settingsConfigUpdateDeferred =>
      'CodeWalk will apply this OpenCode setting after the current response finishes.';

  @override
  String get settingsConversationUsername => 'Konversations-Benutzername';

  @override
  String get settingsDefaultAgent => 'Standardagent';

  @override
  String get settingsDefaultModel => 'Standardmodell';

  @override
  String get settingsLanguageDescription =>
      'Choose the language used by CodeWalk. System default follows your device language.';

  @override
  String get settingsLanguageEmptyText => 'No languages found';

  @override
  String get settingsLanguageFieldHelper =>
      'Applies immediately and persists across restarts.';

  @override
  String get settingsLanguageFieldLabel => 'App language';

  @override
  String get settingsLanguageSearchHint => 'Search languages';

  @override
  String get settingsLanguageSystemDefault => 'System default';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLogsDescription =>
      'Runtime diagnostics and troubleshooting data';

  @override
  String get settingsLogsTitle => 'Registros';

  @override
  String get settingsNoAgentsFound => 'Keine Agenten gefunden';

  @override
  String get settingsNotificationsAgentSubtitle => 'When a response finishes';

  @override
  String get settingsNotificationsAgentUpdates => 'Agent updates';

  @override
  String get settingsNotificationsAnotherConversation => 'Another conversation';

  @override
  String get settingsNotificationsAppInBackground => 'App in background';

  @override
  String get settingsNotificationsBackgroundAlerts =>
      'Android background alerts';

  @override
  String get settingsNotificationsBackgroundBehavior => 'Background behavior';

  @override
  String get settingsNotificationsBackgroundBehaviorDescription =>
      'Choose how CodeWalk behaves after the app leaves the foreground.';

  @override
  String get settingsNotificationsBackgroundDescription =>
      'Use low-data background monitoring for response completions, permission requests, questions, and errors while the app is not on screen.';

  @override
  String get settingsNotificationsBackgroundToggle =>
      'Background alerts on Android';

  @override
  String get settingsNotificationsBackgroundToggleDescription =>
      'Turn off all Android background checks and hide the persistent monitor notification.';

  @override
  String get settingsNotificationsBatteryDescription =>
      'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.';

  @override
  String get settingsNotificationsBatteryDisabled =>
      'Battery optimization is disabled for CodeWalk.';

  @override
  String get settingsNotificationsBatteryEnabled =>
      'Battery optimization is enabled. Some devices may delay background alerts.';

  @override
  String get settingsNotificationsBatteryOptimization =>
      'Android battery optimization';

  @override
  String get settingsNotificationsBatteryUnknown =>
      'Could not read battery optimization status yet.';

  @override
  String get settingsNotificationsChooseAudioFile => 'Choose audio file';

  @override
  String get settingsNotificationsChooseSystemSound => 'Choose system sound';

  @override
  String get settingsNotificationsCloseToTray => 'Close to tray';

  @override
  String get settingsNotificationsCloseToTrayDescription =>
      'Hide window and keep running in system tray.';

  @override
  String get settingsNotificationsDescription =>
      'Per-category notify and sound controls';

  @override
  String get settingsNotificationsDisableOptimization => 'Disable optimization';

  @override
  String get settingsNotificationsErrors => 'Errors';

  @override
  String get settingsNotificationsErrorsSubtitle =>
      'When a session reports a failure';

  @override
  String get settingsNotificationsJustClose => 'Just close';

  @override
  String get settingsNotificationsJustCloseDescription =>
      'Exit the application completely.';

  @override
  String get settingsNotificationsKeepLive => 'Keep alerts live for 3 min';

  @override
  String get settingsNotificationsKeepLiveDescription =>
      'When a response is already running, keep realtime active briefly after leaving the app.';

  @override
  String get settingsNotificationsLocal => 'Local';

  @override
  String get settingsNotificationsMinimizeWhenClose => 'Minimize when close';

  @override
  String get settingsNotificationsMinimizeWhenCloseDescription =>
      'Minimize to taskbar/dock and keep running.';

  @override
  String get settingsNotificationsNoCondition =>
      'If no condition is selected, alerts are allowed in any context.';

  @override
  String get settingsNotificationsNotify => 'Notify';

  @override
  String get settingsNotificationsNotifyOnlyWhen => 'Notify only when';

  @override
  String get settingsNotificationsOpenBatterySettings =>
      'Open battery settings';

  @override
  String get settingsNotificationsPermissions => 'Permissions and questions';

  @override
  String get settingsNotificationsPermissionsSubtitle =>
      'When tools request your input';

  @override
  String get settingsNotificationsPreview => 'Preview';

  @override
  String get settingsNotificationsRefreshStatus => 'Refresh status';

  @override
  String get settingsNotificationsSearchSoundType => 'Search sound type';

  @override
  String get settingsNotificationsSectionDescription =>
      'Control when alerts appear and when they can play sound.';

  @override
  String get settingsNotificationsSectionTitle => 'Notifications';

  @override
  String settingsNotificationsSelectedSound(String label) {
    return 'Selected: $label';
  }

  @override
  String get settingsNotificationsServer => 'Server';

  @override
  String get settingsNotificationsSound => 'Sound';

  @override
  String get settingsNotificationsSoundOnlyWhen => 'Sound only when';

  @override
  String get settingsNotificationsSoundType => 'Sound type';

  @override
  String get settingsNotificationsSyncInfo =>
      'Some category on/off toggles are synced from /config on the active server.';

  @override
  String get settingsNotificationsSyncInfoLocal =>
      'Current server does not expose notification toggles in /config; local values are active.';

  @override
  String get settingsNotificationsSystemSoundPickerTitle =>
      'Choose system sound';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsWhenClosing => 'When closing the window';

  @override
  String get settingsOpenCodeAutoUpdate => 'OpenCode Auto-Update';

  @override
  String get settingsOpenCodeSharingDefault => 'OpenCode Freigabe-Standard';

  @override
  String get settingsReadAloudEnabled => 'Read aloud';

  @override
  String get settingsReadAloudEnabledDescription =>
      'Show a read-aloud button on assistant messages.';

  @override
  String get settingsReadAloudPitch => 'Pitch';

  @override
  String get settingsReadAloudPitchDescription => 'Adjust the voice pitch.';

  @override
  String get settingsReadAloudSectionDescription =>
      'Read assistant responses aloud. Configure speed, pitch, and voice.';

  @override
  String get settingsReadAloudSectionTitle => 'Text to speech';

  @override
  String get settingsReadAloudSpeed => 'Speed';

  @override
  String get settingsReadAloudSpeedDescription => 'Adjust the speaking rate.';

  @override
  String get settingsReadAloudVoice => 'Voice';

  @override
  String get settingsReadAloudVoiceHint => 'Select a voice for read-aloud.';

  @override
  String get settingsSearchAutoUpdateMode => 'Auto-Update-Modus suchen';

  @override
  String get settingsSearchDefaultAgent => 'Standardagent suchen';

  @override
  String get settingsSearchDefaultModel => 'Standardmodell suchen';

  @override
  String get settingsSearchSharingMode => 'Freigabe-Modus suchen';

  @override
  String get settingsSearchSmallModel => 'Kleines Modell suchen';

  @override
  String get settingsServersActive => 'Active';

  @override
  String get settingsServersChooseActive => 'Choose active server';

  @override
  String get settingsServersDefault => 'Default';

  @override
  String get settingsServersDescription =>
      'OpenCode servers and health routing';

  @override
  String get settingsServersTitle => 'Servers';

  @override
  String get settingsSetupWizard => 'Setup Wizard';

  @override
  String get settingsShortcutsDescription => 'Portable app key bindings';

  @override
  String get settingsShortcutsEdit => 'Edit shortcut';

  @override
  String get settingsShortcutsKeyboard => 'Keyboard shortcuts';

  @override
  String get settingsShortcutsReset => 'Reset shortcut';

  @override
  String get settingsShortcutsSearch => 'Search shortcuts';

  @override
  String get settingsShortcutsTitle => 'Shortcuts';

  @override
  String get settingsSmallModel => 'Kleines Modell';

  @override
  String get settingsSmallModelResetExplanation =>
      'Das Zurücksetzen von `small_model` auf den automatischen Fallback erfordert weiterhin das Bearbeiten der Konfiguration außerhalb der App, da `/config`-Patch-Updates keine Schlüssel entfernen können.';

  @override
  String get settingsSmallModelUnsetExplanation =>
      'OpenCode-Automatischer Fallback ist aktiv, da `small_model` nicht gesetzt ist.';

  @override
  String get settingsSoundPickerNotAvailable =>
      'System-Tonauswahl ist auf dieser Plattform nicht verfügbar.';

  @override
  String get settingsSpeechDescription =>
      'Engine, silence timeout, and model options';

  @override
  String get settingsSpeechRefreshStatus => 'Refresh status';

  @override
  String settingsSpeechSilenceTimeout(String value) {
    return 'Silence timeout: ${value}s';
  }

  @override
  String get settingsSpeechTitle => 'Speech to text';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUsernameClearHint =>
      'Clearing the OpenCode conversation username still requires editing config outside the app.';

  @override
  String get settingsUsernameEnterHint =>
      'Enter a username to save a custom OpenCode conversation name.';

  @override
  String get settingsUsernameResetExplanation =>
      'Das Zurücksetzen von `username` auf den Systemstandard erfordert weiterhin das Bearbeiten der Konfiguration außerhalb der App, da `/config`-Patch-Updates keine Schlüssel entfernen können.';

  @override
  String get settingsUsernameUnsetExplanation =>
      'OpenCode verwendet den Systembenutzernamen, da `username` nicht gesetzt ist.';

  @override
  String get setupDebugBun => 'Bun';

  @override
  String get setupDebugBun2 => 'Bun';

  @override
  String get setupDebugCapturedSetupDetails => 'No captured setup details yet';

  @override
  String get setupDebugCapturedSetupLogs => 'Captured setup logs';

  @override
  String get setupDebugClear => 'Clear setup debug';

  @override
  String get setupDebugClearSetupDebug => 'Clear setup debug';

  @override
  String get setupDebugCodeWalkCaptureEnough =>
      'If CodeWalk did not capture enough context, check the official OpenCode logs and health endpoints directly:';

  @override
  String get setupDebugCommandPath => 'Command path';

  @override
  String get setupDebugCommandPath2 => 'Command path';

  @override
  String get setupDebugCopy => 'Copy setup debug';

  @override
  String get setupDebugCopySetupDebug => 'Copy setup debug';

  @override
  String get setupDebugCurrentStatus => 'Current status';

  @override
  String get setupDebugDiagnosticsLoading => 'Diagnostics are still loading.';

  @override
  String get setupDebugEnvironment => 'Environment diagnostics';

  @override
  String get setupDebugEnvironmentDiagnostics => 'Environment diagnostics';

  @override
  String get setupDebugFocusedOpenCodeSetup => 'Focused on OpenCode setup';

  @override
  String get setupDebugInstallDir => 'Install directory';

  @override
  String get setupDebugInstallDirectory => 'Install directory';

  @override
  String get setupDebugLatestLocalServer => 'Latest local server output';

  @override
  String get setupDebugLogs => 'Captured setup logs';

  @override
  String get setupDebugManual => 'Manual troubleshooting';

  @override
  String get setupDebugManualTroubleshooting => 'Manual troubleshooting';

  @override
  String get setupDebugNetwork => 'Network';

  @override
  String get setupDebugNetwork2 => 'Network';

  @override
  String get setupDebugNoDetails => 'No captured setup details yet';

  @override
  String get setupDebugNode => 'Node.js';

  @override
  String get setupDebugNodeJs => 'Node.js';

  @override
  String get setupDebugNpm => 'npm';

  @override
  String get setupDebugNpm2 => 'npm';

  @override
  String get setupDebugOpenCode => 'OpenCode';

  @override
  String get setupDebugOpenCode2 => 'OpenCode';

  @override
  String get setupDebugOpenCodeSetupDebug => 'OpenCode Setup Debug';

  @override
  String get setupDebugPlatform => 'Platform';

  @override
  String get setupDebugPlatform2 => 'Platform';

  @override
  String get setupDebugRunDiagnosticsTry =>
      'Run diagnostics, try an installation method, or attempt a setup flow to capture OpenCode-specific troubleshooting details here.';

  @override
  String get setupDebugScreenCoversOpenCode =>
      'This screen only covers OpenCode installation, diagnostics, and local setup troubleshooting. Use App Logs for general CodeWalk runtime issues.';

  @override
  String get setupDebugServerOutput => 'Latest local server output';

  @override
  String get setupDebugStatus => 'Current status';

  @override
  String setupDebugTimeEntrySource(String source, String time) {
    return '$time - $source';
  }

  @override
  String get setupDebugTimeline => 'Timeline';

  @override
  String get setupDebugTimeline2 => 'Timeline';

  @override
  String get setupDebugTitle => 'Focused on OpenCode setup';

  @override
  String get setupDebugWSL => 'WSL';

  @override
  String get setupDebugWsl => 'WSL';

  @override
  String get shortcutCloseApp => 'Anwendung schließen';

  @override
  String get shortcutCloseAppDesc =>
      'App mit dem Standard-Schließverhalten der Plattform schließen';

  @override
  String get shortcutFocusCloseDrawer => 'Seitenleiste fokussieren/schließen';

  @override
  String get shortcutFocusCloseDrawerDesc =>
      'Eingabe standardmäßig fokussieren oder Seitenleiste schließen, falls offen';

  @override
  String get shortcutFocusInput => 'Eingabe fokussieren';

  @override
  String get shortcutFocusInputDesc => 'Fokus auf die Texteingabe verschieben';

  @override
  String get shortcutGroupApplication => 'Anwendung';

  @override
  String get shortcutGroupGeneral => 'Allgemein';

  @override
  String get shortcutGroupModelAndAgent => 'Modell und Agent';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutGroupPrompt => 'Prompt';

  @override
  String get shortcutGroupSession => 'Sitzung';

  @override
  String get shortcutNewConversation => 'Neue Konversation';

  @override
  String get shortcutNewConversationDesc => 'Eine neue Chat-Sitzung erstellen';

  @override
  String get shortcutNextAgent => 'Nächster Agent';

  @override
  String get shortcutNextAgentDesc =>
      'Zum nächsten verfügbaren Agenten wechseln';

  @override
  String get shortcutNextRecentModel => 'Nächstes kürzliches Modell';

  @override
  String get shortcutNextRecentModelDesc =>
      'Durch kürzlich verwendete Modelle wechseln';

  @override
  String get shortcutNextVariant => 'Nächste Variante';

  @override
  String get shortcutNextVariantDesc =>
      'Durch verfügbare Modellvarianten wechseln';

  @override
  String get shortcutOpenSettings => 'Einstellungen öffnen';

  @override
  String get shortcutOpenSettingsDesc => 'Einstellungsseite öffnen';

  @override
  String get shortcutPreviousAgent => 'Vorheriger Agent';

  @override
  String get shortcutPreviousAgentDesc =>
      'Zum vorherigen verfügbaren Agenten wechseln';

  @override
  String get shortcutQuickOpenFiles => 'Dateien schnell öffnen';

  @override
  String get shortcutQuickOpenFilesDesc => 'Dateischnellsuche öffnen';

  @override
  String get shortcutQuitApp => 'Anwendung beenden';

  @override
  String get shortcutQuitAppDesc => 'Beenden der App erzwingen';

  @override
  String get shortcutRefreshData => 'Daten aktualisieren';

  @override
  String get shortcutRefreshDataDesc =>
      'Daten des aktuellen Chats aktualisieren';

  @override
  String get shortcutStopResponse => 'Antwort stoppen';

  @override
  String get shortcutStopResponseDesc =>
      'Aktive Antwort stoppen (während der Antwort)';

  @override
  String get shortcutToggleVoiceInput => 'Spracheingabe umschalten';

  @override
  String get shortcutToggleVoiceInputDesc =>
      'Spracheingabe im Editor starten oder stoppen';

  @override
  String get shortcutsApply => 'Apply';

  @override
  String shortcutsConflictConflict(String conflict) {
    return 'Konflikt mit $conflict';
  }

  @override
  String get shortcutsKeyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutsReset => 'Reset all';

  @override
  String get shortcutsSearchEditBindings =>
      'Search, edit bindings, and resolve conflicts before saving.';

  @override
  String shortcutsSetShortcutWidget(String label) {
    return 'Tastenkombination festlegen: $label';
  }

  @override
  String get shortcutsTheseBindingsStored =>
      'These bindings are stored in CodeWalk for the current app runtime and do not edit OpenCode `tui.json` keybinds.';

  @override
  String get speechAutoStopSilence => 'Auto-stop silence timeout';

  @override
  String get speechChooseRecognitionEngine =>
      'Choose the recognition engine, silence timeout, and model options.';

  @override
  String speechDesktopOnly(String service) {
    return '$service ist nur auf dem Desktop verfügbar.';
  }

  @override
  String get speechDownload => 'Download';

  @override
  String get speechEngine => 'Engine';

  @override
  String get speechInstalledLanguages => 'Installed languages';

  @override
  String get speechListeningStopsAutomatically =>
      'Listening stops automatically after this many seconds of silence.';

  @override
  String get speechMicPermissionDisabled =>
      'Mikrofonberechtigung ist deaktiviert.';

  @override
  String speechModelFilesIncomplete(String service) {
    return 'Modelldateien für $service sind unvollständig.';
  }

  @override
  String get speechMoonshine => 'Moonshine';

  @override
  String get speechMoonshineModelsDesktop => 'Moonshine models (desktop)';

  @override
  String get speechMoonshineStaysDownloadable =>
      'Moonshine stays downloadable and out of the app bundle. Pick one model for this desktop device and remove it later if you want the space back.';

  @override
  String get speechNative => 'Native';

  @override
  String get speechNativeSTTDisabled =>
      'Native STT is disabled on Linux in this app. Parakeet is the default engine for new installs.';

  @override
  String get speechNativeSTTWorks =>
      'Native STT works on Windows when OS speech services are enabled. If native initialization fails, CodeWalk automatically falls back to Sherpa. Check Windows microphone privacy, Online speech recognition, and installed speech language packs.';

  @override
  String get speechNativeStartsFaster =>
      'Native starts faster. Sherpa runs fully on-device with heavier setup and deeper model control.';

  @override
  String get speechParakeet => 'Parakeet';

  @override
  String get speechParakeetModelsDesktop => 'Parakeet models (desktop)';

  @override
  String get speechParakeetStaysDownloadable =>
      'Parakeet stays downloadable and out of the app bundle. It currently exposes one multilingual model optimized for 25 European languages.';

  @override
  String get speechPickLanguagePacks =>
      'Pick language packs and download/remove models for on-device recognition.';

  @override
  String get speechRemove => 'Remove';

  @override
  String speechRuntimeFailed(String service) {
    return 'Laufzeit für $service konnte nicht initialisiert werden.';
  }

  @override
  String get speechSelectSherpaAbove =>
      'Select Sherpa above to manage language packs and download models.';

  @override
  String get speechSenseVoice => 'SenseVoice';

  @override
  String get speechSenseVoiceModelsDesktop => 'SenseVoice models (desktop)';

  @override
  String get speechSenseVoiceStaysDownloadable =>
      'SenseVoice stays downloadable and out of the app bundle. It is the strongest desktop option here for Chinese, Cantonese, Japanese, Korean, and English.';

  @override
  String get speechSherpa => 'Sherpa';

  @override
  String get speechSherpaExperimentalFail =>
      'Sherpa is experimental and can fail on some devices. Prefer Native if you want the most stable behavior.';

  @override
  String get speechSherpaModelsLinux => 'Sherpa models (Linux)';

  @override
  String get speechSpeechText => 'Speech to text';

  @override
  String speechUnavailableOnPlatform(String service) {
    return '$service-Sprachausgabe ist auf dieser Plattform nicht verfügbar.';
  }

  @override
  String get statusConnected => 'Verbunden';

  @override
  String get statusDelayed => 'Verzögert';

  @override
  String get statusFailed => 'Fehlgeschlagen';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusReconnecting => 'Wiederverbinden';

  @override
  String get statusStarting => 'Starten';

  @override
  String get statusStopped => 'Gestoppt';

  @override
  String get statusStopping => 'Stoppen';

  @override
  String get statusSyncDelayed => 'Sync verzögert';

  @override
  String get tailscaleNoPeers => 'No peers found';

  @override
  String get tailscaleNotSupportedOnPlatform =>
      'Tailscale wird auf dieser Plattform nicht unterstützt.';

  @override
  String get tailscaleNotSupportedOnWindows =>
      'Tailscale wird unter Windows nicht unterstützt.';

  @override
  String get tailscalePeerOffline => 'offline';

  @override
  String get tailscaleSelectPeer => 'Select a Tailscale peer';

  @override
  String get tailscaleWaitingAdminApproval =>
      'Dieser Tailscale-Knoten wartet auf die Genehmigung durch den Administrator.';

  @override
  String get terminalClose => 'Close terminal';

  @override
  String terminalConnectingTo(String serverName) {
    return 'Verbindung zum Terminal von $serverName wird hergestellt...';
  }

  @override
  String terminalConnectionFailed(String error) {
    return 'Terminalverbindung fehlgeschlagen: $error';
  }

  @override
  String get terminalDisconnected => 'Terminal getrennt.';

  @override
  String terminalEmbeddedUnavailable(String serverName) {
    return 'Das eingebettete Terminal ist in dieser Laufzeit noch nicht verfügbar. Verwenden Sie weiterhin den Composer-Shell-Modus für Einmalbefehle oder öffnen Sie das Terminal von einer unterstützten CodeWalk-App-Laufzeit für $serverName.';
  }

  @override
  String get terminalHide => 'Terminal ausblenden';

  @override
  String get terminalMaximize => 'Maximize';

  @override
  String get terminalMinimize => 'Minimize terminal';

  @override
  String get terminalNotAvailableYet =>
      'Das eingebettete Terminal ist in dieser Laufzeit noch nicht verfügbar.';

  @override
  String get terminalOpen => 'Terminal öffnen';

  @override
  String get terminalOpenInfo => 'Terminal-Info öffnen';

  @override
  String get terminalOpenProjectFirst =>
      'Öffnen Sie einen Projektordner, bevor Sie das Server-Terminal starten.';

  @override
  String get terminalOpenToConnect =>
      'Öffnen Sie das Terminal, um sich mit dem Server-Projekt-Terminal zu verbinden.';

  @override
  String get terminalReconnect => 'Reconnect terminal';

  @override
  String get terminalRestoreSize => 'Restore size';

  @override
  String get terminalSelectServer =>
      'Wählen Sie einen aktiven Server aus, bevor Sie das Terminal öffnen.';

  @override
  String get terminalSessionClosed => 'Terminal-Sitzung geschlossen.';

  @override
  String get terminalTerminal => 'Terminal';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalTryAgain => 'Try again';

  @override
  String get toolAwaitingInput => 'Awaiting input';

  @override
  String get toolEditing => 'Editing';

  @override
  String get toolEditingFiles => 'Editing files';

  @override
  String get toolFinding => 'Finding';

  @override
  String get toolFindingFiles => 'Finding files';

  @override
  String get toolPresentationAwaitingInput => 'Awaiting input';

  @override
  String get toolPresentationEditing => 'Editing';

  @override
  String get toolPresentationEditingFiles => 'Editing files';

  @override
  String get toolPresentationFinding => 'Finding';

  @override
  String get toolPresentationFindingFiles => 'Finding files';

  @override
  String get toolPresentationReading => 'Reading';

  @override
  String get toolPresentationReadingFile => 'Reading file';

  @override
  String get toolPresentationRunning => 'Running';

  @override
  String get toolPresentationRunningCommand => 'Running command';

  @override
  String toolPresentationRunningTool(String toolName) {
    return 'Führt $toolName aus';
  }

  @override
  String get toolPresentationSearching => 'Searching';

  @override
  String get toolPresentationSearchingCode => 'Searching code';

  @override
  String get toolPresentationSearchingWeb => 'Searching the web';

  @override
  String get toolPresentationTool => 'Werkzeug';

  @override
  String get toolPresentationUpdatingTaskList => 'Updating task list';

  @override
  String get toolPresentationUpdatingTasks => 'Updating tasks';

  @override
  String get toolPresentationWaitingInput => 'Waiting for your input';

  @override
  String get toolPresentationWriting => 'Writing';

  @override
  String get toolPresentationWritingFile => 'Writing file';

  @override
  String get toolReading => 'Reading';

  @override
  String get toolReadingFile => 'Reading file';

  @override
  String get toolRunning => 'Running';

  @override
  String get toolRunningCommand => 'Running command';

  @override
  String get toolRunningTask => 'Running task';

  @override
  String get toolSearching => 'Searching';

  @override
  String get toolSearchingCode => 'Searching code';

  @override
  String get toolSearchingWeb => 'Searching the web';

  @override
  String get toolUpdatingTaskList => 'Updating task list';

  @override
  String get toolUpdatingTasks => 'Updating tasks';

  @override
  String get toolWaitingForInput => 'Waiting for your input';

  @override
  String get toolWriting => 'Writing';

  @override
  String get toolWritingFile => 'Writing file';

  @override
  String get tourBack => 'Back';

  @override
  String get tourSkip => 'Skip';

  @override
  String get trayQuit => 'Quit';

  @override
  String get trayShow => 'Show';

  @override
  String get useOAuthCloudflareAccess => 'Use OAuth (Cloudflare Access)';

  @override
  String get useOAuthCloudflareAccessSubtitle =>
      'Opens a browser for Cloudflare Access Managed OAuth.';

  @override
  String get useOAuthCloudflareAccessUnsupported =>
      'Cloudflare Access OAuth is not available on this platform. Use Basic Auth instead.';

  @override
  String get useTailscale => 'Use Tailscale';

  @override
  String get useTailscaleSubtitle =>
      'Routes traffic through the Tailscale network without a system VPN.';

  @override
  String get useTailscaleUnsupported =>
      'Tailscale is not supported on this platform.';

  @override
  String get utilityTitle => 'Dienstprogramm';

  @override
  String get workspaceBrowseDirs => 'Browse directories';

  @override
  String get workspaceChooseFolderOpen =>
      'Choose any folder to open as project context.';

  @override
  String workspaceCloseProject(String project) {
    return 'Close $project';
  }

  @override
  String get workspaceFilterDirs => 'Filter directories';

  @override
  String get workspaceOpenFolder => 'Open folder';

  @override
  String get workspaceOpenProjectFolder => 'Open project folder';

  @override
  String get workspaceProjectDirectory => 'Project directory';

  @override
  String get workspaceProjectHint => '/repo/my-project';

  @override
  String workspaceRemoveFromHistory(String name) {
    return 'Remove $name from history';
  }

  @override
  String get workspaceSuggestions => 'Suggestions';
}
