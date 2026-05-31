import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// CodeWalk UI string — cannedNoSuggestions
  ///
  /// In en, this message translates to:
  /// **'No suggestions'**
  String get cannedNoSuggestions;

  /// CodeWalk UI string — chatAddServerToStart
  ///
  /// In en, this message translates to:
  /// **'Add a server to start chatting.'**
  String get chatAddServerToStart;

  /// CodeWalk UI string — chatClose
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get chatClose;

  /// CodeWalk UI string — chatCompactContext
  ///
  /// In en, this message translates to:
  /// **'Compact Context'**
  String get chatCompactContext;

  /// CodeWalk UI string — chatConversations
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatConversations;

  /// CodeWalk UI string — chatConversationsPane
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get chatConversationsPane;

  /// CodeWalk UI string — chatDisplayToggles
  ///
  /// In en, this message translates to:
  /// **'Display toggles'**
  String get chatDisplayToggles;

  /// CodeWalk UI string — chatFilterActive
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatFilterActive;

  /// CodeWalk UI string — chatFilterAll
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chatFilterAll;

  /// CodeWalk UI string — chatFilterArchived
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get chatFilterArchived;

  /// CodeWalk UI string — chatFilterSessions
  ///
  /// In en, this message translates to:
  /// **'Filter sessions'**
  String get chatFilterSessions;

  /// CodeWalk UI string — chatGoToFirst
  ///
  /// In en, this message translates to:
  /// **'Go to first message'**
  String get chatGoToFirst;

  /// CodeWalk UI string — chatGoToLatest
  ///
  /// In en, this message translates to:
  /// **'Go to latest message'**
  String get chatGoToLatest;

  /// CodeWalk UI string — chatHelloAssistant
  ///
  /// In en, this message translates to:
  /// **'Hello! I am your AI assistant'**
  String get chatHelloAssistant;

  /// CodeWalk UI string — chatHideConversationsSidebar
  ///
  /// In en, this message translates to:
  /// **'Hide Conversations sidebar'**
  String get chatHideConversationsSidebar;

  /// CodeWalk UI string — chatHideUtilitySidebar
  ///
  /// In en, this message translates to:
  /// **'Hide Utility sidebar'**
  String get chatHideUtilitySidebar;

  /// CodeWalk UI string — chatKeepWorking
  ///
  /// In en, this message translates to:
  /// **'Keep working'**
  String get chatKeepWorking;

  /// CodeWalk UI string — chatLoadMore
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get chatLoadMore;

  /// CodeWalk UI string — chatNewChat
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatNewChat;

  /// CodeWalk UI string — chatNewChatTourDescription
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation here.'**
  String get chatNewChatTourDescription;

  /// CodeWalk UI string — chatNewChatTourTitle
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get chatNewChatTourTitle;

  /// CodeWalk UI string — chatNoServerYet
  ///
  /// In en, this message translates to:
  /// **'No server configured yet'**
  String get chatNoServerYet;

  /// CodeWalk UI string — chatOpenFiles
  ///
  /// In en, this message translates to:
  /// **'Open Files'**
  String get chatOpenFiles;

  /// CodeWalk UI string — chatProjectContext
  ///
  /// In en, this message translates to:
  /// **'Project Context'**
  String get chatProjectContext;

  /// CodeWalk UI string — chatRecentSessions
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get chatRecentSessions;

  /// CodeWalk UI string — chatRecentSessionsToggle
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get chatRecentSessionsToggle;

  /// CodeWalk UI string — chatRedoLastTurn
  ///
  /// In en, this message translates to:
  /// **'Redo last undone turn'**
  String get chatRedoLastTurn;

  /// CodeWalk UI string — chatRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get chatRefresh;

  /// CodeWalk UI string — chatRefreshSessionDetails
  ///
  /// In en, this message translates to:
  /// **'Refresh session details'**
  String get chatRefreshSessionDetails;

  /// CodeWalk UI string — chatRetry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetry;

  /// CodeWalk UI string — chatRetryRefresh
  ///
  /// In en, this message translates to:
  /// **'Retry refresh'**
  String get chatRetryRefresh;

  /// CodeWalk UI string — chatReturnToMainConversation
  ///
  /// In en, this message translates to:
  /// **'Return to main conversation'**
  String get chatReturnToMainConversation;

  /// CodeWalk UI string — chatSearchConversations
  ///
  /// In en, this message translates to:
  /// **'Search conversations'**
  String get chatSearchConversations;

  /// CodeWalk UI string — chatSearchTimeline
  ///
  /// In en, this message translates to:
  /// **'Search timeline'**
  String get chatSearchTimeline;

  /// CodeWalk UI string — chatSearchNoResults
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get chatSearchNoResults;

  /// CodeWalk UI string — chatSearchResultCount
  ///
  /// In en, this message translates to:
  /// **'Message {current} of {total}'**
  String chatSearchResultCount(int current, int total);

  /// CodeWalk UI string — chatSearchPreviousResult
  ///
  /// In en, this message translates to:
  /// **'Previous result'**
  String get chatSearchPreviousResult;

  /// CodeWalk UI string — chatSearchNextResult
  ///
  /// In en, this message translates to:
  /// **'Next result'**
  String get chatSearchNextResult;

  /// CodeWalk UI string — chatAppBarMoreActions
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get chatAppBarMoreActions;

  /// CodeWalk UI string — chatAppBarPinAction
  ///
  /// In en, this message translates to:
  /// **'Pin to app bar'**
  String get chatAppBarPinAction;

  /// CodeWalk UI string — chatAppBarUnpinAction
  ///
  /// In en, this message translates to:
  /// **'Unpin from app bar'**
  String get chatAppBarUnpinAction;

  /// CodeWalk UI string — chatAppBarPinDescription
  ///
  /// In en, this message translates to:
  /// **'This action will stay visible outside the menu.'**
  String get chatAppBarPinDescription;

  /// CodeWalk UI string — chatAppBarUnpinDescription
  ///
  /// In en, this message translates to:
  /// **'This action will move back into the menu.'**
  String get chatAppBarUnpinDescription;

  /// CodeWalk UI string — chatSelectOrCreate
  ///
  /// In en, this message translates to:
  /// **'Select or create a conversation to start chatting'**
  String get chatSelectOrCreate;

  /// CodeWalk UI string — chatSessionActions
  ///
  /// In en, this message translates to:
  /// **'Session actions'**
  String get chatSessionActions;

  /// CodeWalk UI string — chatSetUpServer
  ///
  /// In en, this message translates to:
  /// **'Set up server'**
  String get chatSetUpServer;

  /// CodeWalk UI string — chatSortMostRecent
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get chatSortMostRecent;

  /// CodeWalk UI string — chatSortOldest
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get chatSortOldest;

  /// CodeWalk UI string — chatSortRecent
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get chatSortRecent;

  /// CodeWalk UI string — chatSortSessions
  ///
  /// In en, this message translates to:
  /// **'Sort sessions'**
  String get chatSortSessions;

  /// CodeWalk UI string — chatSortTitle
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get chatSortTitle;

  /// CodeWalk UI string — chatToggleSidebars
  ///
  /// In en, this message translates to:
  /// **'Toggle sidebars'**
  String get chatToggleSidebars;

  /// CodeWalk UI string — chatUndoLastTurn
  ///
  /// In en, this message translates to:
  /// **'Undo last turn'**
  String get chatUndoLastTurn;

  /// CodeWalk UI string — chatUseCurrent
  ///
  /// In en, this message translates to:
  /// **'Use current'**
  String get chatUseCurrent;

  /// CodeWalk UI string — commonCancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// CodeWalk UI string — commonDelete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// CodeWalk UI string — commonReset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// CodeWalk UI string — commonSave
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// CodeWalk UI string — composerAddAttachment
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get composerAddAttachment;

  /// CodeWalk UI string — composerAttachFiles
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get composerAttachFiles;

  /// CodeWalk UI string — composerCannedAppendAtCursor
  ///
  /// In en, this message translates to:
  /// **'Append at cursor'**
  String get composerCannedAppendAtCursor;

  /// CodeWalk UI string — composerCannedLabel
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get composerCannedLabel;

  /// CodeWalk UI string — composerCannedNoReplies
  ///
  /// In en, this message translates to:
  /// **'No quick replies yet.'**
  String get composerCannedNoReplies;

  /// CodeWalk UI string — composerCannedReplace
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get composerCannedReplace;

  /// CodeWalk UI string — composerCannedSave
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get composerCannedSave;

  /// CodeWalk UI string — composerCannedScopeGlobal
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get composerCannedScopeGlobal;

  /// CodeWalk UI string — composerCannedScopeProject
  ///
  /// In en, this message translates to:
  /// **'Project-only'**
  String get composerCannedScopeProject;

  /// CodeWalk UI string — composerCannedSendAutomatically
  ///
  /// In en, this message translates to:
  /// **'Send automatically'**
  String get composerCannedSendAutomatically;

  /// CodeWalk UI string — composerCannedText
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get composerCannedText;

  /// CodeWalk UI string — composerChatInput
  ///
  /// In en, this message translates to:
  /// **'Chat input'**
  String get composerChatInput;

  /// CodeWalk UI string — composerDeleteAction
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get composerDeleteAction;

  /// CodeWalk UI string — composerEdit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get composerEdit;

  /// CodeWalk UI string — composerExtras
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get composerExtras;

  /// CodeWalk UI string — composerNewQuickReply
  ///
  /// In en, this message translates to:
  /// **'New quick reply'**
  String get composerNewQuickReply;

  /// CodeWalk UI string — composerSelectImages
  ///
  /// In en, this message translates to:
  /// **'Select Images'**
  String get composerSelectImages;

  /// CodeWalk UI string — composerSelectPdf
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get composerSelectPdf;

  /// CodeWalk UI string — composerSend
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get composerSend;

  /// CodeWalk UI string — composerShellMode
  ///
  /// In en, this message translates to:
  /// **'Shell mode'**
  String get composerShellMode;

  /// CodeWalk UI string — dialogDownload
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get dialogDownload;

  /// CodeWalk UI string — dialogLanguage
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get dialogLanguage;

  /// CodeWalk UI string — dialogMoonshineModelSize
  ///
  /// In en, this message translates to:
  /// **'Model size'**
  String get dialogMoonshineModelSize;

  /// CodeWalk UI string — dialogMoonshineVoiceSetup
  ///
  /// In en, this message translates to:
  /// **'Moonshine Voice Setup'**
  String get dialogMoonshineVoiceSetup;

  /// CodeWalk UI string — dialogParakeetModel
  ///
  /// In en, this message translates to:
  /// **'Parakeet model'**
  String get dialogParakeetModel;

  /// CodeWalk UI string — dialogParakeetVoiceSetup
  ///
  /// In en, this message translates to:
  /// **'Parakeet Voice Setup'**
  String get dialogParakeetVoiceSetup;

  /// CodeWalk UI string — dialogSenseVoiceModel
  ///
  /// In en, this message translates to:
  /// **'SenseVoice model'**
  String get dialogSenseVoiceModel;

  /// CodeWalk UI string — dialogSenseVoiceSetup
  ///
  /// In en, this message translates to:
  /// **'SenseVoice Setup'**
  String get dialogSenseVoiceSetup;

  /// CodeWalk UI string — dialogVoiceInputSetup
  ///
  /// In en, this message translates to:
  /// **'Voice Input Setup'**
  String get dialogVoiceInputSetup;

  /// CodeWalk UI string — filesHideSidebar
  ///
  /// In en, this message translates to:
  /// **'Hide Files sidebar'**
  String get filesHideSidebar;

  /// CodeWalk UI string — filesQuickOpen
  ///
  /// In en, this message translates to:
  /// **'Quick Open'**
  String get filesQuickOpen;

  /// CodeWalk UI string — filesRefresh
  ///
  /// In en, this message translates to:
  /// **'Refresh files'**
  String get filesRefresh;

  /// CodeWalk UI string — filesSearchHint
  ///
  /// In en, this message translates to:
  /// **'Search files by name or path'**
  String get filesSearchHint;

  /// CodeWalk UI string — filesTitle
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// CodeWalk UI string — logsClear
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get logsClear;

  /// CodeWalk UI string — logsCloseSearch
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get logsCloseSearch;

  /// CodeWalk UI string — logsCopyFiltered
  ///
  /// In en, this message translates to:
  /// **'Copy filtered logs'**
  String get logsCopyFiltered;

  /// CodeWalk UI string — logsSearch
  ///
  /// In en, this message translates to:
  /// **'Search logs'**
  String get logsSearch;

  /// CodeWalk UI string — modelAuto
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get modelAuto;

  /// CodeWalk UI string — modelLoadingModels
  ///
  /// In en, this message translates to:
  /// **'Loading models'**
  String get modelLoadingModels;

  /// CodeWalk UI string — modelRetryModels
  ///
  /// In en, this message translates to:
  /// **'Retry models'**
  String get modelRetryModels;

  /// CodeWalk UI string — modelSearchHint
  ///
  /// In en, this message translates to:
  /// **'Search model or provider'**
  String get modelSearchHint;

  /// CodeWalk UI string — msgBatterySettingsFailed
  ///
  /// In en, this message translates to:
  /// **'Could not open Android battery optimization settings.'**
  String get msgBatterySettingsFailed;

  /// CodeWalk UI string — msgBatterySettingsOpened
  ///
  /// In en, this message translates to:
  /// **'Android battery settings opened. Allow unrestricted battery for CodeWalk.'**
  String get msgBatterySettingsOpened;

  /// CodeWalk UI string — msgClearUsernameNeedsConfigEdit
  ///
  /// In en, this message translates to:
  /// **'Clearing the OpenCode conversation username still requires editing config outside the app.'**
  String get msgClearUsernameNeedsConfigEdit;

  /// CodeWalk UI string — msgCommandCopied
  ///
  /// In en, this message translates to:
  /// **'Command copied'**
  String get msgCommandCopied;

  /// CodeWalk UI string — msgCopiedToClipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get msgCopiedToClipboard;

  /// CodeWalk UI string — msgEnterUsernameToSave
  ///
  /// In en, this message translates to:
  /// **'Enter a username to save a custom OpenCode conversation name.'**
  String get msgEnterUsernameToSave;

  /// CodeWalk UI string — msgFailedToSendMessage
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Draft kept for retry.'**
  String get msgFailedToSendMessage;

  /// CodeWalk UI string — msgFailedToStartVoiceInput
  ///
  /// In en, this message translates to:
  /// **'Failed to start voice input'**
  String get msgFailedToStartVoiceInput;

  /// CodeWalk UI string — msgFilteredLogsCopied
  ///
  /// In en, this message translates to:
  /// **'Filtered logs copied to clipboard'**
  String get msgFilteredLogsCopied;

  /// CodeWalk UI string — msgInfoAgent
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get msgInfoAgent;

  /// CodeWalk UI string — msgInfoCompaction
  ///
  /// In en, this message translates to:
  /// **'Compaction'**
  String get msgInfoCompaction;

  /// CodeWalk UI string — msgInfoCost
  ///
  /// In en, this message translates to:
  /// **'Cost: \${cost}'**
  String msgInfoCost(String cost);

  /// CodeWalk UI string — msgInfoMessageInfo
  ///
  /// In en, this message translates to:
  /// **'Message Info'**
  String get msgInfoMessageInfo;

  /// CodeWalk UI string — msgInfoModel
  ///
  /// In en, this message translates to:
  /// **'Model: {modelId}'**
  String msgInfoModel(String modelId);

  /// CodeWalk UI string — msgInfoNoMetadata
  ///
  /// In en, this message translates to:
  /// **'No metadata available'**
  String get msgInfoNoMetadata;

  /// CodeWalk UI string — msgInfoPatch
  ///
  /// In en, this message translates to:
  /// **'Patch'**
  String get msgInfoPatch;

  /// CodeWalk UI string — msgInfoProvider
  ///
  /// In en, this message translates to:
  /// **'Provider: {providerId}'**
  String msgInfoProvider(String providerId);

  /// CodeWalk UI string — msgInfoRetry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get msgInfoRetry;

  /// CodeWalk UI string — msgInfoSnapshot
  ///
  /// In en, this message translates to:
  /// **'Snapshot'**
  String get msgInfoSnapshot;

  /// CodeWalk UI string — msgInfoTokens
  ///
  /// In en, this message translates to:
  /// **'Tokens: {total}'**
  String msgInfoTokens(String total);

  /// CodeWalk UI string — msgInfoUndoThisTurn
  ///
  /// In en, this message translates to:
  /// **'Undo this turn'**
  String get msgInfoUndoThisTurn;

  /// CodeWalk UI string — msgInfoView
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get msgInfoView;

  /// CodeWalk UI string — msgNoSystemSoundsFound
  ///
  /// In en, this message translates to:
  /// **'No system sound was found on this device.'**
  String get msgNoSystemSoundsFound;

  /// CodeWalk UI string — msgNoValidFilesSelected
  ///
  /// In en, this message translates to:
  /// **'No valid files were selected'**
  String get msgNoValidFilesSelected;

  /// CodeWalk UI string — msgSetupDebugCopied
  ///
  /// In en, this message translates to:
  /// **'OpenCode setup debug copied to clipboard'**
  String get msgSetupDebugCopied;

  /// CodeWalk UI string — msgSystemSoundPickerUnavailable
  ///
  /// In en, this message translates to:
  /// **'System sound picker is not available on this platform.'**
  String get msgSystemSoundPickerUnavailable;

  /// CodeWalk UI string — msgUpdatedButRefreshFailed
  ///
  /// In en, this message translates to:
  /// **'Updated the server setting, but could not refresh chat providers.'**
  String get msgUpdatedButRefreshFailed;

  /// CodeWalk UI string — msgVoiceInputUnavailable
  ///
  /// In en, this message translates to:
  /// **'Voice input is unavailable on this device'**
  String get msgVoiceInputUnavailable;

  /// CodeWalk UI string — notifConversationUpdates
  ///
  /// In en, this message translates to:
  /// **'Conversation updates'**
  String get notifConversationUpdates;

  /// CodeWalk UI string — onboardingClear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get onboardingClear;

  /// CodeWalk UI string — onboardingLabel
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get onboardingLabel;

  /// CodeWalk UI string — onboardingLabelHint
  ///
  /// In en, this message translates to:
  /// **'My server'**
  String get onboardingLabelHint;

  /// CodeWalk UI string — onboardingPassword
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get onboardingPassword;

  /// CodeWalk UI string — onboardingServerUrl
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get onboardingServerUrl;

  /// CodeWalk UI string — onboardingUsername
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get onboardingUsername;

  /// CodeWalk UI string — permissionAllowOnce
  ///
  /// In en, this message translates to:
  /// **'Allow Once'**
  String get permissionAllowOnce;

  /// CodeWalk UI string — permissionAlways
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get permissionAlways;

  /// CodeWalk UI string — permissionBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get permissionBack;

  /// CodeWalk UI string — permissionConfirmReject
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get permissionConfirmReject;

  /// CodeWalk UI string — permissionReject
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get permissionReject;

  /// CodeWalk UI string — permissionReopen
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get permissionReopen;

  /// CodeWalk UI string — quotaAuthCookie
  ///
  /// In en, this message translates to:
  /// **'Auth cookie'**
  String get quotaAuthCookie;

  /// CodeWalk UI string — quotaForget
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get quotaForget;

  /// CodeWalk UI string — quotaOpenCodeGoUsage
  ///
  /// In en, this message translates to:
  /// **'OpenCode Go usage'**
  String get quotaOpenCodeGoUsage;

  /// CodeWalk UI string — quotaOpenDashboard
  ///
  /// In en, this message translates to:
  /// **'Open OpenCode dashboard'**
  String get quotaOpenDashboard;

  /// CodeWalk UI string — quotaSaving
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get quotaSaving;

  /// CodeWalk UI string — quotaWorkspaceId
  ///
  /// In en, this message translates to:
  /// **'Workspace ID'**
  String get quotaWorkspaceId;

  /// CodeWalk UI string — sessionActionArchived
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get sessionActionArchived;

  /// CodeWalk UI string — sessionActionDeleted
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get sessionActionDeleted;

  /// CodeWalk UI string — sessionActionForked
  ///
  /// In en, this message translates to:
  /// **'forked'**
  String get sessionActionForked;

  /// CodeWalk UI string — sessionActionUnarchived
  ///
  /// In en, this message translates to:
  /// **'unarchived'**
  String get sessionActionUnarchived;

  /// CodeWalk UI string — sessionCancelRename
  ///
  /// In en, this message translates to:
  /// **'Cancel rename'**
  String get sessionCancelRename;

  /// CodeWalk UI string — sessionCopyLink
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get sessionCopyLink;

  /// CodeWalk UI string — sessionDelete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sessionDelete;

  /// CodeWalk UI string — sessionDeleteTitle
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get sessionDeleteTitle;

  /// CodeWalk UI string — sessionDiffChangedFile
  ///
  /// In en, this message translates to:
  /// **'Changed file'**
  String get sessionDiffChangedFile;

  /// CodeWalk UI string — sessionDiffReview
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get sessionDiffReview;

  /// CodeWalk UI string — sessionDiffSummary
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get sessionDiffSummary;

  /// CodeWalk UI string — sessionDiffUnified
  ///
  /// In en, this message translates to:
  /// **'Unified'**
  String get sessionDiffUnified;

  /// CodeWalk UI string — sessionDiffSplit
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get sessionDiffSplit;

  /// CodeWalk UI string — sessionDiffFilesChanged
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file changed} other{{count} files changed}}'**
  String sessionDiffFilesChanged(int count);

  /// CodeWalk UI string — sessionDiffLinesCollapsed
  ///
  /// In en, this message translates to:
  /// **'{count} lines collapsed — tap to expand'**
  String sessionDiffLinesCollapsed(int count);

  /// CodeWalk UI string — sessionDiffLinesAddedRemoved
  ///
  /// In en, this message translates to:
  /// **'+{added} lines added -{removed} lines removed'**
  String sessionDiffLinesAddedRemoved(int added, int removed);

  /// CodeWalk UI string — sessionDiffContentNotCaptured
  ///
  /// In en, this message translates to:
  /// **'File content not captured by the server'**
  String get sessionDiffContentNotCaptured;

  /// CodeWalk UI string — sessionFailedRename
  ///
  /// In en, this message translates to:
  /// **'Failed to rename conversation'**
  String get sessionFailedRename;

  /// CodeWalk UI string — sessionFailedUpdateArchive
  ///
  /// In en, this message translates to:
  /// **'Failed to update archive state'**
  String get sessionFailedUpdateArchive;

  /// CodeWalk UI string — sessionFailedUpdateSharing
  ///
  /// In en, this message translates to:
  /// **'Failed to update sharing state'**
  String get sessionFailedUpdateSharing;

  /// CodeWalk UI string — sessionFork
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get sessionFork;

  /// CodeWalk UI string — sessionKeyboardShortcuts
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get sessionKeyboardShortcuts;

  /// CodeWalk UI string — sessionNotAvailable
  ///
  /// In en, this message translates to:
  /// **'Conversation is not available for this project yet'**
  String get sessionNotAvailable;

  /// CodeWalk UI string — sessionRename
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get sessionRename;

  /// CodeWalk UI string — sessionRenameHint
  ///
  /// In en, this message translates to:
  /// **'Enter new conversation name'**
  String get sessionRenameHint;

  /// CodeWalk UI string — sessionRenameTitle
  ///
  /// In en, this message translates to:
  /// **'Rename Conversation'**
  String get sessionRenameTitle;

  /// CodeWalk UI string — sessionSaveTitle
  ///
  /// In en, this message translates to:
  /// **'Save title'**
  String get sessionSaveTitle;

  /// CodeWalk UI string — sessionShareLinkCopied
  ///
  /// In en, this message translates to:
  /// **'Share link copied'**
  String get sessionShareLinkCopied;

  /// CodeWalk UI string — sessionTitleHint
  ///
  /// In en, this message translates to:
  /// **'Conversation title'**
  String get sessionTitleHint;

  /// CodeWalk UI string — settingsAboutCheckForUpdates
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsAboutCheckForUpdates;

  /// CodeWalk UI string — settingsAboutCheckOnOpen
  ///
  /// In en, this message translates to:
  /// **'Check for updates on open'**
  String get settingsAboutCheckOnOpen;

  /// CodeWalk UI string — settingsAboutCheckOnOpenDescription
  ///
  /// In en, this message translates to:
  /// **'Automatically check when the app starts'**
  String get settingsAboutCheckOnOpenDescription;

  /// CodeWalk UI string — settingsAboutChecking
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get settingsAboutChecking;

  /// CodeWalk UI string — settingsAboutDescription
  ///
  /// In en, this message translates to:
  /// **'Version, updates and links'**
  String get settingsAboutDescription;

  /// CodeWalk UI string — settingsAboutDismiss
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get settingsAboutDismiss;

  /// CodeWalk UI string — settingsAboutDownloading
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percent}%'**
  String settingsAboutDownloading(String percent);

  /// CodeWalk UI string — settingsAboutEraseAllData
  ///
  /// In en, this message translates to:
  /// **'Erase all data and restart'**
  String get settingsAboutEraseAllData;

  /// CodeWalk UI string — settingsAboutInstallUpdate
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get settingsAboutInstallUpdate;

  /// CodeWalk UI string — settingsAboutInstalling
  ///
  /// In en, this message translates to:
  /// **'Installing...'**
  String get settingsAboutInstalling;

  /// CodeWalk UI string — settingsAboutLatestVersion
  ///
  /// In en, this message translates to:
  /// **'v{version} is the latest version'**
  String settingsAboutLatestVersion(String version);

  /// CodeWalk UI string — settingsAboutLoading
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get settingsAboutLoading;

  /// CodeWalk UI string — settingsAboutReplayChatTour
  ///
  /// In en, this message translates to:
  /// **'Replay chat tour'**
  String get settingsAboutReplayChatTour;

  /// CodeWalk UI string — settingsAboutReplayChatTourDescription
  ///
  /// In en, this message translates to:
  /// **'Close settings and show the guided chat walkthrough'**
  String get settingsAboutReplayChatTourDescription;

  /// CodeWalk UI string — settingsAboutResetApp
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get settingsAboutResetApp;

  /// CodeWalk UI string — settingsAboutResetAppQuestion
  ///
  /// In en, this message translates to:
  /// **'Reset app?'**
  String get settingsAboutResetAppQuestion;

  /// CodeWalk UI string — settingsAboutResetAppWarning
  ///
  /// In en, this message translates to:
  /// **'This will erase all servers, settings, and cached data. This action cannot be undone.'**
  String get settingsAboutResetAppWarning;

  /// CodeWalk UI string — settingsAboutRetryInstall
  ///
  /// In en, this message translates to:
  /// **'Retry install'**
  String get settingsAboutRetryInstall;

  /// CodeWalk UI string — settingsAboutTapToCheck
  ///
  /// In en, this message translates to:
  /// **'Tap to check for new versions'**
  String get settingsAboutTapToCheck;

  /// CodeWalk UI string — settingsAboutTitle
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// CodeWalk UI string — settingsAboutUpToDate
  ///
  /// In en, this message translates to:
  /// **'You\'\'re up to date'**
  String get settingsAboutUpToDate;

  /// CodeWalk UI string — settingsAboutUpdateAvailable
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String settingsAboutUpdateAvailable(String version);

  /// CodeWalk UI string — settingsAboutUpdateInstalled
  ///
  /// In en, this message translates to:
  /// **'Update installed. Restart the app to apply.'**
  String get settingsAboutUpdateInstalled;

  /// CodeWalk UI string — settingsAboutVersion
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersion;

  /// CodeWalk UI string — settingsAboutVersionBuild
  ///
  /// In en, this message translates to:
  /// **'{version} (build {buildNumber})'**
  String settingsAboutVersionBuild(String buildNumber, String version);

  /// CodeWalk UI string — settingsAppearanceAmoledDark
  ///
  /// In en, this message translates to:
  /// **'AMOLED dark mode'**
  String get settingsAppearanceAmoledDark;

  /// CodeWalk UI string — settingsAppearanceAmoledDarkActive
  ///
  /// In en, this message translates to:
  /// **'Use pure black surfaces while dark mode is active.'**
  String get settingsAppearanceAmoledDarkActive;

  /// CodeWalk UI string — settingsAppearanceAmoledDarkInactive
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode to enable AMOLED surfaces.'**
  String get settingsAppearanceAmoledDarkInactive;

  /// CodeWalk UI string — settingsAppearanceBrandColor
  ///
  /// In en, this message translates to:
  /// **'Brand color'**
  String get settingsAppearanceBrandColor;

  /// CodeWalk UI string — settingsAppearanceBrandColorDynamicBlocked
  ///
  /// In en, this message translates to:
  /// **'Disable wallpaper colors to pick a brand color.'**
  String get settingsAppearanceBrandColorDynamicBlocked;

  /// CodeWalk UI string — settingsAppearanceBrandColorNormal
  ///
  /// In en, this message translates to:
  /// **'Pick a seed color for the app palette.'**
  String get settingsAppearanceBrandColorNormal;

  /// CodeWalk UI string — settingsAppearanceBrandColorPresetBlocked
  ///
  /// In en, this message translates to:
  /// **'Switch to CodeWalk Classic to pick a brand color.'**
  String get settingsAppearanceBrandColorPresetBlocked;

  /// CodeWalk UI string — settingsAppearanceCodeWalkClassic
  ///
  /// In en, this message translates to:
  /// **'CodeWalk Classic'**
  String get settingsAppearanceCodeWalkClassic;

  /// CodeWalk UI string — settingsAppearanceComposerTips
  ///
  /// In en, this message translates to:
  /// **'Composer tips'**
  String get settingsAppearanceComposerTips;

  /// CodeWalk UI string — settingsAppearanceComposerTipsDescription
  ///
  /// In en, this message translates to:
  /// **'Show or hide rotating tips while the assistant is reasoning.'**
  String get settingsAppearanceComposerTipsDescription;

  /// CodeWalk UI string — settingsAppearanceContrast
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get settingsAppearanceContrast;

  /// CodeWalk UI string — settingsAppearanceContrastDynamicBlocked
  ///
  /// In en, this message translates to:
  /// **'Disable wallpaper colors to adjust contrast.'**
  String get settingsAppearanceContrastDynamicBlocked;

  /// CodeWalk UI string — settingsAppearanceContrastHigh
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsAppearanceContrastHigh;

  /// CodeWalk UI string — settingsAppearanceContrastNormal
  ///
  /// In en, this message translates to:
  /// **'Adjust the contrast level of the color scheme.'**
  String get settingsAppearanceContrastNormal;

  /// CodeWalk UI string — settingsAppearanceContrastPresetBlocked
  ///
  /// In en, this message translates to:
  /// **'Switch to CodeWalk Classic to adjust contrast.'**
  String get settingsAppearanceContrastPresetBlocked;

  /// CodeWalk UI string — settingsAppearanceContrastReduced
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get settingsAppearanceContrastReduced;

  /// CodeWalk UI string — settingsAppearanceDark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsAppearanceDark;

  /// CodeWalk UI string — settingsAppearanceDensity
  ///
  /// In en, this message translates to:
  /// **'Density'**
  String get settingsAppearanceDensity;

  /// CodeWalk UI string — settingsAppearanceDensityDense
  ///
  /// In en, this message translates to:
  /// **'Dense'**
  String get settingsAppearanceDensityDense;

  /// CodeWalk UI string — settingsAppearanceDensityDescription
  ///
  /// In en, this message translates to:
  /// **'Apply spacing and component density across the app.'**
  String get settingsAppearanceDensityDescription;

  /// CodeWalk UI string — settingsAppearanceDensityExtraDense
  ///
  /// In en, this message translates to:
  /// **'Extra Dense'**
  String get settingsAppearanceDensityExtraDense;

  /// CodeWalk UI string — settingsAppearanceDensityExtraSpacious
  ///
  /// In en, this message translates to:
  /// **'Extra Spacious'**
  String get settingsAppearanceDensityExtraSpacious;

  /// CodeWalk UI string — settingsAppearanceDensityNormal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsAppearanceDensityNormal;

  /// CodeWalk UI string — settingsAppearanceDensitySpacious
  ///
  /// In en, this message translates to:
  /// **'Spacious'**
  String get settingsAppearanceDensitySpacious;

  /// CodeWalk UI string — settingsAppearanceDescription
  ///
  /// In en, this message translates to:
  /// **'Density and timeline bubble visibility'**
  String get settingsAppearanceDescription;

  /// CodeWalk UI string — settingsAppearanceLight
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsAppearanceLight;

  /// CodeWalk UI string — settingsAppearanceNoPresets
  ///
  /// In en, this message translates to:
  /// **'No preset palettes found'**
  String get settingsAppearanceNoPresets;

  /// CodeWalk UI string — settingsAppearanceOpenCodePresets
  ///
  /// In en, this message translates to:
  /// **'OpenCode Presets'**
  String get settingsAppearanceOpenCodePresets;

  /// CodeWalk UI string — settingsAppearancePresetHelper
  ///
  /// In en, this message translates to:
  /// **'Mirrors the official OpenCode Web built-in theme list.'**
  String get settingsAppearancePresetHelper;

  /// CodeWalk UI string — settingsAppearancePresetNote
  ///
  /// In en, this message translates to:
  /// **'Theme colors now follow the official OpenCode Web registry and drive markdown/code surfaces too.'**
  String get settingsAppearancePresetNote;

  /// CodeWalk UI string — settingsAppearancePresetPalette
  ///
  /// In en, this message translates to:
  /// **'Preset palette'**
  String get settingsAppearancePresetPalette;

  /// CodeWalk UI string — settingsAppearanceSearchPreset
  ///
  /// In en, this message translates to:
  /// **'Search preset palette'**
  String get settingsAppearanceSearchPreset;

  /// CodeWalk UI string — settingsAppearanceSectionDescription
  ///
  /// In en, this message translates to:
  /// **'Tune visual density and message surfaces for your workflow.'**
  String get settingsAppearanceSectionDescription;

  /// CodeWalk UI string — settingsAppearanceSectionTitle
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSectionTitle;

  /// CodeWalk UI string — settingsAppearanceSystem
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsAppearanceSystem;

  /// CodeWalk UI string — settingsAppearanceTaskList
  ///
  /// In en, this message translates to:
  /// **'Task list'**
  String get settingsAppearanceTaskList;

  /// CodeWalk UI string — settingsAppearanceTaskListDescription
  ///
  /// In en, this message translates to:
  /// **'Show or hide the session task list widget.'**
  String get settingsAppearanceTaskListDescription;

  /// CodeWalk UI string — settingsAppearanceTheme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsAppearanceTheme;

  /// CodeWalk UI string — settingsAppearanceThemeDescription
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or system mode, then keep the CodeWalk classic palette or switch to an OpenCode preset.'**
  String get settingsAppearanceThemeDescription;

  /// CodeWalk UI string — settingsAppearanceThinkingBubbles
  ///
  /// In en, this message translates to:
  /// **'Thinking bubbles'**
  String get settingsAppearanceThinkingBubbles;

  /// CodeWalk UI string — settingsAppearanceThinkingBubblesDescription
  ///
  /// In en, this message translates to:
  /// **'Show or hide reasoning blocks in assistant messages.'**
  String get settingsAppearanceThinkingBubblesDescription;

  /// CodeWalk UI string — settingsAppearanceTitle
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// CodeWalk UI string — settingsAppearanceToolCallBubbles
  ///
  /// In en, this message translates to:
  /// **'Tool call bubbles'**
  String get settingsAppearanceToolCallBubbles;

  /// CodeWalk UI string — settingsAppearanceToolCallBubblesDescription
  ///
  /// In en, this message translates to:
  /// **'Show or hide tool execution cards in assistant messages.'**
  String get settingsAppearanceToolCallBubblesDescription;

  /// CodeWalk UI string — settingsAppearanceWallpaperColors
  ///
  /// In en, this message translates to:
  /// **'Use wallpaper colors'**
  String get settingsAppearanceWallpaperColors;

  /// CodeWalk UI string — settingsAppearanceWallpaperNormal
  ///
  /// In en, this message translates to:
  /// **'Extract color scheme from your device wallpaper.'**
  String get settingsAppearanceWallpaperNormal;

  /// CodeWalk UI string — settingsAppearanceWallpaperPresetBlocked
  ///
  /// In en, this message translates to:
  /// **'Switch to CodeWalk Classic to use wallpaper colors.'**
  String get settingsAppearanceWallpaperPresetBlocked;

  /// CodeWalk UI string — settingsBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsBack;

  /// CodeWalk UI string — settingsBehaviorAutoupdateCaveat
  ///
  /// In en, this message translates to:
  /// **'Use About for CodeWalk release checks. This setting only mirrors the official OpenCode `autoupdate` config.'**
  String get settingsBehaviorAutoupdateCaveat;

  /// CodeWalk UI string — settingsBehaviorAutoupdateHelp
  ///
  /// In en, this message translates to:
  /// **'Controls upstream OpenCode runtime updates, not CodeWalk app update checks.'**
  String get settingsBehaviorAutoupdateHelp;

  /// CodeWalk UI string — settingsBehaviorCellularDataSaver
  ///
  /// In en, this message translates to:
  /// **'Cellular data saver'**
  String get settingsBehaviorCellularDataSaver;

  /// CodeWalk UI string — settingsBehaviorConfigDeferred
  ///
  /// In en, this message translates to:
  /// **'CodeWalk will apply this OpenCode setting after the current response finishes.'**
  String get settingsBehaviorConfigDeferred;

  /// CodeWalk UI string — settingsBehaviorConfigUpdateFailed
  ///
  /// In en, this message translates to:
  /// **'Could not update the OpenCode {field}.'**
  String settingsBehaviorConfigUpdateFailed(String field);

  /// CodeWalk UI string — settingsBehaviorConversationUsername
  ///
  /// In en, this message translates to:
  /// **'Conversation username'**
  String get settingsBehaviorConversationUsername;

  /// CodeWalk UI string — settingsBehaviorConversationUsernameHelp
  ///
  /// In en, this message translates to:
  /// **'Custom display name shown in conversations instead of the system username.'**
  String get settingsBehaviorConversationUsernameHelp;

  /// CodeWalk UI string — settingsBehaviorDataSaverActive
  ///
  /// In en, this message translates to:
  /// **'Active now on mobile data.'**
  String get settingsBehaviorDataSaverActive;

  /// CodeWalk UI string — settingsBehaviorDataSaverCellularOnly
  ///
  /// In en, this message translates to:
  /// **'Only applies when the connection is cellular/mobile.'**
  String get settingsBehaviorDataSaverCellularOnly;

  /// CodeWalk UI string — settingsBehaviorDataSaverDescription
  ///
  /// In en, this message translates to:
  /// **'Cuts automatic mobile-data usage by stopping background downloads and throttling automatic foreground refreshes.'**
  String get settingsBehaviorDataSaverDescription;

  /// CodeWalk UI string — settingsBehaviorDataSaverWaiting
  ///
  /// In en, this message translates to:
  /// **'Waiting for the next mobile-data sync window.'**
  String get settingsBehaviorDataSaverWaiting;

  /// CodeWalk UI string — settingsBehaviorDefaultAgent
  ///
  /// In en, this message translates to:
  /// **'Default agent'**
  String get settingsBehaviorDefaultAgent;

  /// CodeWalk UI string — settingsBehaviorDefaultAgentHelp
  ///
  /// In en, this message translates to:
  /// **'Primary agent used when no agent is explicitly chosen.'**
  String get settingsBehaviorDefaultAgentHelp;

  /// CodeWalk UI string — settingsBehaviorDefaultModel
  ///
  /// In en, this message translates to:
  /// **'Default model'**
  String get settingsBehaviorDefaultModel;

  /// CodeWalk UI string — settingsBehaviorDefaultModelHelp
  ///
  /// In en, this message translates to:
  /// **'Shared across OpenCode clients through config.'**
  String get settingsBehaviorDefaultModelHelp;

  /// CodeWalk UI string — settingsBehaviorDescription
  ///
  /// In en, this message translates to:
  /// **'OpenCode defaults, provenance, and composer sync safety'**
  String get settingsBehaviorDescription;

  /// CodeWalk UI string — settingsBehaviorEnableDataSaver
  ///
  /// In en, this message translates to:
  /// **'Enable cellular data saver'**
  String get settingsBehaviorEnableDataSaver;

  /// CodeWalk UI string — settingsBehaviorMultiDeviceSync
  ///
  /// In en, this message translates to:
  /// **'Enable experimental multi-device sync'**
  String get settingsBehaviorMultiDeviceSync;

  /// CodeWalk UI string — settingsBehaviorMultiDeviceSyncDescription
  ///
  /// In en, this message translates to:
  /// **'Sync composer selection (agent/model/variant) with the active server config.'**
  String get settingsBehaviorMultiDeviceSyncDescription;

  /// CodeWalk UI string — settingsBehaviorMultiDeviceSyncWarning
  ///
  /// In en, this message translates to:
  /// **'Can abort ongoing sessions when working in more than one session at the same time.'**
  String get settingsBehaviorMultiDeviceSyncWarning;

  /// CodeWalk UI string — settingsBehaviorNoAgents
  ///
  /// In en, this message translates to:
  /// **'No agents found'**
  String get settingsBehaviorNoAgents;

  /// CodeWalk UI string — settingsBehaviorNoModels
  ///
  /// In en, this message translates to:
  /// **'No models found'**
  String get settingsBehaviorNoModels;

  /// CodeWalk UI string — settingsBehaviorOpenCodeAutoupdate
  ///
  /// In en, this message translates to:
  /// **'OpenCode auto-update'**
  String get settingsBehaviorOpenCodeAutoupdate;

  /// CodeWalk UI string — settingsBehaviorOpenCodeDefaults
  ///
  /// In en, this message translates to:
  /// **'OpenCode-backed defaults'**
  String get settingsBehaviorOpenCodeDefaults;

  /// CodeWalk UI string — settingsBehaviorOpenCodeDefaultsDescription
  ///
  /// In en, this message translates to:
  /// **'These values write to `/config` on the active server and match official OpenCode shared config.'**
  String get settingsBehaviorOpenCodeDefaultsDescription;

  /// CodeWalk UI string — settingsBehaviorOpenCodeSnapshots
  ///
  /// In en, this message translates to:
  /// **'OpenCode snapshots'**
  String get settingsBehaviorOpenCodeSnapshots;

  /// CodeWalk UI string — settingsBehaviorOpenCodeSnapshotsDescription
  ///
  /// In en, this message translates to:
  /// **'Keep upstream git-backed snapshots enabled for undo/redo and recovery history.'**
  String get settingsBehaviorOpenCodeSnapshotsDescription;

  /// CodeWalk UI string — settingsBehaviorPermissionDeferred
  ///
  /// In en, this message translates to:
  /// **'Advanced permission rule editing stays out of Settings for now and is deferred to later parity work.'**
  String get settingsBehaviorPermissionDeferred;

  /// CodeWalk UI string — settingsBehaviorPermissionProvenance
  ///
  /// In en, this message translates to:
  /// **'Permission handling provenance'**
  String get settingsBehaviorPermissionProvenance;

  /// CodeWalk UI string — settingsBehaviorPermissionProvenanceDescription
  ///
  /// In en, this message translates to:
  /// **'Official OpenCode permission policy is configured in `opencode.json` with allow/ask/deny rules per tool. CodeWalk keeps the official permission-request cards and adds one approved ADR-023 exception: the composer auto-approve toggle replies with `Always` and `remember: true` unconditionally to create durable session-scoped grants, and keeps the same thread-scoped continuity path active in the Android background worker.'**
  String get settingsBehaviorPermissionProvenanceDescription;

  /// CodeWalk UI string — settingsBehaviorRefreshDefaults
  ///
  /// In en, this message translates to:
  /// **'Refresh defaults'**
  String get settingsBehaviorRefreshDefaults;

  /// CodeWalk UI string — settingsBehaviorSaveUsername
  ///
  /// In en, this message translates to:
  /// **'Save username'**
  String get settingsBehaviorSaveUsername;

  /// CodeWalk UI string — settingsBehaviorSearchAutoupdate
  ///
  /// In en, this message translates to:
  /// **'Search auto-update mode'**
  String get settingsBehaviorSearchAutoupdate;

  /// CodeWalk UI string — settingsBehaviorSearchDefaultAgent
  ///
  /// In en, this message translates to:
  /// **'Search default agent'**
  String get settingsBehaviorSearchDefaultAgent;

  /// CodeWalk UI string — settingsBehaviorSearchDefaultModel
  ///
  /// In en, this message translates to:
  /// **'Search default model'**
  String get settingsBehaviorSearchDefaultModel;

  /// CodeWalk UI string — settingsBehaviorSearchShareMode
  ///
  /// In en, this message translates to:
  /// **'Search sharing mode'**
  String get settingsBehaviorSearchShareMode;

  /// CodeWalk UI string — settingsBehaviorSearchSmallModel
  ///
  /// In en, this message translates to:
  /// **'Search small model'**
  String get settingsBehaviorSearchSmallModel;

  /// CodeWalk UI string — settingsBehaviorShareMode
  ///
  /// In en, this message translates to:
  /// **'OpenCode sharing default'**
  String get settingsBehaviorShareMode;

  /// CodeWalk UI string — settingsBehaviorShareModeCaveat
  ///
  /// In en, this message translates to:
  /// **'Use the chat-level share action to publish one session now. This setting only changes OpenCode\'\'s default sharing policy.'**
  String get settingsBehaviorShareModeCaveat;

  /// CodeWalk UI string — settingsBehaviorShareModeHelp
  ///
  /// In en, this message translates to:
  /// **'Controls the official global `share` config, not the share button for an individual chat.'**
  String get settingsBehaviorShareModeHelp;

  /// CodeWalk UI string — settingsBehaviorSmallModel
  ///
  /// In en, this message translates to:
  /// **'Small model'**
  String get settingsBehaviorSmallModel;

  /// CodeWalk UI string — settingsBehaviorSmallModelAutoFallback
  ///
  /// In en, this message translates to:
  /// **'Automatic fallback'**
  String get settingsBehaviorSmallModelAutoFallback;

  /// CodeWalk UI string — settingsBehaviorSmallModelFallbackActive
  ///
  /// In en, this message translates to:
  /// **'OpenCode automatic fallback is active because `small_model` is unset.'**
  String get settingsBehaviorSmallModelFallbackActive;

  /// CodeWalk UI string — settingsBehaviorSmallModelHelp
  ///
  /// In en, this message translates to:
  /// **'Used for lightweight tasks like title generation.'**
  String get settingsBehaviorSmallModelHelp;

  /// CodeWalk UI string — settingsBehaviorSmallModelResetCaveat
  ///
  /// In en, this message translates to:
  /// **'Resetting `small_model` back to automatic fallback still requires editing config outside the app because `/config` patch updates cannot remove keys.'**
  String get settingsBehaviorSmallModelResetCaveat;

  /// CodeWalk UI string — settingsBehaviorSnapshotCaveat
  ///
  /// In en, this message translates to:
  /// **'This controls OpenCode snapshot storage and undo/redo support, not CodeWalk local cache snapshots.'**
  String get settingsBehaviorSnapshotCaveat;

  /// CodeWalk UI string — settingsBehaviorTitle
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get settingsBehaviorTitle;

  /// CodeWalk UI string — settingsBehaviorUsernameFallback
  ///
  /// In en, this message translates to:
  /// **'OpenCode uses the system username because `username` is unset.'**
  String get settingsBehaviorUsernameFallback;

  /// CodeWalk UI string — settingsBehaviorUsernamePatchCaveat
  ///
  /// In en, this message translates to:
  /// **'Resetting `username` back to the system default still requires editing config outside the app because `/config` patch updates cannot remove keys.'**
  String get settingsBehaviorUsernamePatchCaveat;

  /// CodeWalk UI string — settingsLanguageDescription
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by CodeWalk. System default follows your device language.'**
  String get settingsLanguageDescription;

  /// CodeWalk UI string — settingsLanguageEmptyText
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get settingsLanguageEmptyText;

  /// CodeWalk UI string — settingsLanguageFieldHelper
  ///
  /// In en, this message translates to:
  /// **'Applies immediately and persists across restarts.'**
  String get settingsLanguageFieldHelper;

  /// CodeWalk UI string — settingsLanguageFieldLabel
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageFieldLabel;

  /// CodeWalk UI string — settingsLanguageSearchHint
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get settingsLanguageSearchHint;

  /// CodeWalk UI string — settingsLanguageSystemDefault
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystemDefault;

  /// CodeWalk UI string — settingsLanguageTitle
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// CodeWalk UI string — settingsLogsDescription
  ///
  /// In en, this message translates to:
  /// **'Runtime diagnostics and troubleshooting data'**
  String get settingsLogsDescription;

  /// CodeWalk UI string — settingsLogsTitle
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get settingsLogsTitle;

  /// CodeWalk UI string — settingsNotificationsAgentSubtitle
  ///
  /// In en, this message translates to:
  /// **'When a response finishes'**
  String get settingsNotificationsAgentSubtitle;

  /// CodeWalk UI string — settingsNotificationsAgentUpdates
  ///
  /// In en, this message translates to:
  /// **'Agent updates'**
  String get settingsNotificationsAgentUpdates;

  /// CodeWalk UI string — settingsNotificationsAnotherConversation
  ///
  /// In en, this message translates to:
  /// **'Another conversation'**
  String get settingsNotificationsAnotherConversation;

  /// CodeWalk UI string — settingsNotificationsAppInBackground
  ///
  /// In en, this message translates to:
  /// **'App in background'**
  String get settingsNotificationsAppInBackground;

  /// CodeWalk UI string — settingsNotificationsBackgroundAlerts
  ///
  /// In en, this message translates to:
  /// **'Android background alerts'**
  String get settingsNotificationsBackgroundAlerts;

  /// CodeWalk UI string — settingsNotificationsBackgroundBehavior
  ///
  /// In en, this message translates to:
  /// **'Background behavior'**
  String get settingsNotificationsBackgroundBehavior;

  /// CodeWalk UI string — settingsNotificationsBackgroundBehaviorDescription
  ///
  /// In en, this message translates to:
  /// **'Choose how CodeWalk behaves after the app leaves the foreground.'**
  String get settingsNotificationsBackgroundBehaviorDescription;

  /// CodeWalk UI string — settingsNotificationsBackgroundDescription
  ///
  /// In en, this message translates to:
  /// **'Use low-data background monitoring for response completions, permission requests, questions, and errors while the app is not on screen.'**
  String get settingsNotificationsBackgroundDescription;

  /// CodeWalk UI string — settingsNotificationsBackgroundToggle
  ///
  /// In en, this message translates to:
  /// **'Background alerts on Android'**
  String get settingsNotificationsBackgroundToggle;

  /// CodeWalk UI string — settingsNotificationsBackgroundToggleDescription
  ///
  /// In en, this message translates to:
  /// **'Turn off all Android background checks and hide the persistent monitor notification.'**
  String get settingsNotificationsBackgroundToggleDescription;

  /// CodeWalk UI string — settingsNotificationsBatteryDescription
  ///
  /// In en, this message translates to:
  /// **'If notifications only arrive when reopening the app, allow CodeWalk to run without optimization on this device.'**
  String get settingsNotificationsBatteryDescription;

  /// CodeWalk UI string — settingsNotificationsBatteryDisabled
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is disabled for CodeWalk.'**
  String get settingsNotificationsBatteryDisabled;

  /// CodeWalk UI string — settingsNotificationsBatteryEnabled
  ///
  /// In en, this message translates to:
  /// **'Battery optimization is enabled. Some devices may delay background alerts.'**
  String get settingsNotificationsBatteryEnabled;

  /// CodeWalk UI string — settingsNotificationsBatteryOptimization
  ///
  /// In en, this message translates to:
  /// **'Android battery optimization'**
  String get settingsNotificationsBatteryOptimization;

  /// CodeWalk UI string — settingsNotificationsBatteryUnknown
  ///
  /// In en, this message translates to:
  /// **'Could not read battery optimization status yet.'**
  String get settingsNotificationsBatteryUnknown;

  /// CodeWalk UI string — settingsNotificationsChooseAudioFile
  ///
  /// In en, this message translates to:
  /// **'Choose audio file'**
  String get settingsNotificationsChooseAudioFile;

  /// CodeWalk UI string — settingsNotificationsChooseSystemSound
  ///
  /// In en, this message translates to:
  /// **'Choose system sound'**
  String get settingsNotificationsChooseSystemSound;

  /// CodeWalk UI string — settingsNotificationsCloseToTray
  ///
  /// In en, this message translates to:
  /// **'Close to tray'**
  String get settingsNotificationsCloseToTray;

  /// CodeWalk UI string — settingsNotificationsCloseToTrayDescription
  ///
  /// In en, this message translates to:
  /// **'Hide window and keep running in system tray.'**
  String get settingsNotificationsCloseToTrayDescription;

  /// CodeWalk UI string — settingsNotificationsDescription
  ///
  /// In en, this message translates to:
  /// **'Per-category notify and sound controls'**
  String get settingsNotificationsDescription;

  /// CodeWalk UI string — settingsNotificationsDisableOptimization
  ///
  /// In en, this message translates to:
  /// **'Disable optimization'**
  String get settingsNotificationsDisableOptimization;

  /// CodeWalk UI string — settingsNotificationsErrors
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get settingsNotificationsErrors;

  /// CodeWalk UI string — settingsNotificationsErrorsSubtitle
  ///
  /// In en, this message translates to:
  /// **'When a session reports a failure'**
  String get settingsNotificationsErrorsSubtitle;

  /// CodeWalk UI string — settingsNotificationsJustClose
  ///
  /// In en, this message translates to:
  /// **'Just close'**
  String get settingsNotificationsJustClose;

  /// CodeWalk UI string — settingsNotificationsJustCloseDescription
  ///
  /// In en, this message translates to:
  /// **'Exit the application completely.'**
  String get settingsNotificationsJustCloseDescription;

  /// CodeWalk UI string — settingsNotificationsKeepLive
  ///
  /// In en, this message translates to:
  /// **'Keep alerts live for 3 min'**
  String get settingsNotificationsKeepLive;

  /// CodeWalk UI string — settingsNotificationsKeepLiveDescription
  ///
  /// In en, this message translates to:
  /// **'When a response is already running, keep realtime active briefly after leaving the app.'**
  String get settingsNotificationsKeepLiveDescription;

  /// CodeWalk UI string — settingsNotificationsLocal
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get settingsNotificationsLocal;

  /// CodeWalk UI string — settingsNotificationsMinimizeWhenClose
  ///
  /// In en, this message translates to:
  /// **'Minimize when close'**
  String get settingsNotificationsMinimizeWhenClose;

  /// CodeWalk UI string — settingsNotificationsMinimizeWhenCloseDescription
  ///
  /// In en, this message translates to:
  /// **'Minimize to taskbar/dock and keep running.'**
  String get settingsNotificationsMinimizeWhenCloseDescription;

  /// CodeWalk UI string — settingsNotificationsNoCondition
  ///
  /// In en, this message translates to:
  /// **'If no condition is selected, alerts are allowed in any context.'**
  String get settingsNotificationsNoCondition;

  /// CodeWalk UI string — settingsNotificationsNotify
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get settingsNotificationsNotify;

  /// CodeWalk UI string — settingsNotificationsNotifyOnlyWhen
  ///
  /// In en, this message translates to:
  /// **'Notify only when'**
  String get settingsNotificationsNotifyOnlyWhen;

  /// CodeWalk UI string — settingsNotificationsOpenBatterySettings
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get settingsNotificationsOpenBatterySettings;

  /// CodeWalk UI string — settingsNotificationsPermissions
  ///
  /// In en, this message translates to:
  /// **'Permissions and questions'**
  String get settingsNotificationsPermissions;

  /// CodeWalk UI string — settingsNotificationsPermissionsSubtitle
  ///
  /// In en, this message translates to:
  /// **'When tools request your input'**
  String get settingsNotificationsPermissionsSubtitle;

  /// CodeWalk UI string — settingsNotificationsPreview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsNotificationsPreview;

  /// CodeWalk UI string — settingsNotificationsRefreshStatus
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get settingsNotificationsRefreshStatus;

  /// CodeWalk UI string — settingsNotificationsSearchSoundType
  ///
  /// In en, this message translates to:
  /// **'Search sound type'**
  String get settingsNotificationsSearchSoundType;

  /// CodeWalk UI string — settingsNotificationsSectionDescription
  ///
  /// In en, this message translates to:
  /// **'Control when alerts appear and when they can play sound.'**
  String get settingsNotificationsSectionDescription;

  /// CodeWalk UI string — settingsNotificationsSectionTitle
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsSectionTitle;

  /// CodeWalk UI string — settingsNotificationsSelectedSound
  ///
  /// In en, this message translates to:
  /// **'Selected: {label}'**
  String settingsNotificationsSelectedSound(String label);

  /// CodeWalk UI string — settingsNotificationsServer
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsNotificationsServer;

  /// CodeWalk UI string — settingsNotificationsSound
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsNotificationsSound;

  /// CodeWalk UI string — settingsNotificationsSoundOnlyWhen
  ///
  /// In en, this message translates to:
  /// **'Sound only when'**
  String get settingsNotificationsSoundOnlyWhen;

  /// CodeWalk UI string — settingsNotificationsSoundType
  ///
  /// In en, this message translates to:
  /// **'Sound type'**
  String get settingsNotificationsSoundType;

  /// CodeWalk UI string — settingsNotificationsSyncInfo
  ///
  /// In en, this message translates to:
  /// **'Some category on/off toggles are synced from /config on the active server.'**
  String get settingsNotificationsSyncInfo;

  /// CodeWalk UI string — settingsNotificationsSyncInfoLocal
  ///
  /// In en, this message translates to:
  /// **'Current server does not expose notification toggles in /config; local values are active.'**
  String get settingsNotificationsSyncInfoLocal;

  /// CodeWalk UI string — settingsNotificationsSystemSoundPickerTitle
  ///
  /// In en, this message translates to:
  /// **'Choose system sound'**
  String get settingsNotificationsSystemSoundPickerTitle;

  /// CodeWalk UI string — settingsNotificationsTitle
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// CodeWalk UI string — settingsNotificationsWhenClosing
  ///
  /// In en, this message translates to:
  /// **'When closing the window'**
  String get settingsNotificationsWhenClosing;

  /// CodeWalk UI string — settingsServersActive
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsServersActive;

  /// CodeWalk UI string — settingsServersChooseActive
  ///
  /// In en, this message translates to:
  /// **'Choose active server'**
  String get settingsServersChooseActive;

  /// CodeWalk UI string — settingsServersDefault
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsServersDefault;

  /// CodeWalk UI string — settingsServersDescription
  ///
  /// In en, this message translates to:
  /// **'OpenCode servers and health routing'**
  String get settingsServersDescription;

  /// CodeWalk UI string — settingsServersTitle
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get settingsServersTitle;

  /// CodeWalk UI string — settingsSetupWizard
  ///
  /// In en, this message translates to:
  /// **'Setup Wizard'**
  String get settingsSetupWizard;

  /// CodeWalk UI string — settingsShortcutsDescription
  ///
  /// In en, this message translates to:
  /// **'Portable app key bindings'**
  String get settingsShortcutsDescription;

  /// CodeWalk UI string — settingsShortcutsEdit
  ///
  /// In en, this message translates to:
  /// **'Edit shortcut'**
  String get settingsShortcutsEdit;

  /// CodeWalk UI string — settingsShortcutsKeyboard
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsShortcutsKeyboard;

  /// CodeWalk UI string — settingsShortcutsReset
  ///
  /// In en, this message translates to:
  /// **'Reset shortcut'**
  String get settingsShortcutsReset;

  /// CodeWalk UI string — settingsShortcutsSearch
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts'**
  String get settingsShortcutsSearch;

  /// CodeWalk UI string — settingsShortcutsTitle
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get settingsShortcutsTitle;

  /// CodeWalk UI string — settingsSpeechDescription
  ///
  /// In en, this message translates to:
  /// **'Engine, silence timeout, and model options'**
  String get settingsSpeechDescription;

  /// CodeWalk UI string — settingsSpeechRefreshStatus
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get settingsSpeechRefreshStatus;

  /// CodeWalk UI string — settingsSpeechSilenceTimeout
  ///
  /// In en, this message translates to:
  /// **'Silence timeout: {value}s'**
  String settingsSpeechSilenceTimeout(String value);

  /// CodeWalk UI string — settingsSpeechTitle
  ///
  /// In en, this message translates to:
  /// **'Speech to text'**
  String get settingsSpeechTitle;

  /// CodeWalk UI string — settingsTitle
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// CodeWalk UI string — setupDebugBun
  ///
  /// In en, this message translates to:
  /// **'Bun'**
  String get setupDebugBun;

  /// CodeWalk UI string — setupDebugClear
  ///
  /// In en, this message translates to:
  /// **'Clear setup debug'**
  String get setupDebugClear;

  /// CodeWalk UI string — setupDebugCommandPath
  ///
  /// In en, this message translates to:
  /// **'Command path'**
  String get setupDebugCommandPath;

  /// CodeWalk UI string — setupDebugCopy
  ///
  /// In en, this message translates to:
  /// **'Copy setup debug'**
  String get setupDebugCopy;

  /// CodeWalk UI string — setupDebugEnvironment
  ///
  /// In en, this message translates to:
  /// **'Environment diagnostics'**
  String get setupDebugEnvironment;

  /// CodeWalk UI string — setupDebugInstallDir
  ///
  /// In en, this message translates to:
  /// **'Install directory'**
  String get setupDebugInstallDir;

  /// CodeWalk UI string — setupDebugLogs
  ///
  /// In en, this message translates to:
  /// **'Captured setup logs'**
  String get setupDebugLogs;

  /// CodeWalk UI string — setupDebugManual
  ///
  /// In en, this message translates to:
  /// **'Manual troubleshooting'**
  String get setupDebugManual;

  /// CodeWalk UI string — setupDebugNetwork
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get setupDebugNetwork;

  /// CodeWalk UI string — setupDebugNoDetails
  ///
  /// In en, this message translates to:
  /// **'No captured setup details yet'**
  String get setupDebugNoDetails;

  /// CodeWalk UI string — setupDebugNodeJs
  ///
  /// In en, this message translates to:
  /// **'Node.js'**
  String get setupDebugNodeJs;

  /// CodeWalk UI string — setupDebugNpm
  ///
  /// In en, this message translates to:
  /// **'npm'**
  String get setupDebugNpm;

  /// CodeWalk UI string — setupDebugOpenCode
  ///
  /// In en, this message translates to:
  /// **'OpenCode'**
  String get setupDebugOpenCode;

  /// CodeWalk UI string — setupDebugPlatform
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get setupDebugPlatform;

  /// CodeWalk UI string — setupDebugServerOutput
  ///
  /// In en, this message translates to:
  /// **'Latest local server output'**
  String get setupDebugServerOutput;

  /// CodeWalk UI string — setupDebugStatus
  ///
  /// In en, this message translates to:
  /// **'Current status'**
  String get setupDebugStatus;

  /// CodeWalk UI string — setupDebugTimeline
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get setupDebugTimeline;

  /// CodeWalk UI string — setupDebugTitle
  ///
  /// In en, this message translates to:
  /// **'Focused on OpenCode setup'**
  String get setupDebugTitle;

  /// CodeWalk UI string — setupDebugWsl
  ///
  /// In en, this message translates to:
  /// **'WSL'**
  String get setupDebugWsl;

  /// CodeWalk UI string — terminalClose
  ///
  /// In en, this message translates to:
  /// **'Close terminal'**
  String get terminalClose;

  /// CodeWalk UI string — terminalMinimize
  ///
  /// In en, this message translates to:
  /// **'Minimize terminal'**
  String get terminalMinimize;

  /// CodeWalk UI string — terminalReconnect
  ///
  /// In en, this message translates to:
  /// **'Reconnect terminal'**
  String get terminalReconnect;

  /// CodeWalk UI string — terminalTryAgain
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get terminalTryAgain;

  /// CodeWalk UI string — toolAwaitingInput
  ///
  /// In en, this message translates to:
  /// **'Awaiting input'**
  String get toolAwaitingInput;

  /// CodeWalk UI string — toolEditing
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get toolEditing;

  /// CodeWalk UI string — toolEditingFiles
  ///
  /// In en, this message translates to:
  /// **'Editing files'**
  String get toolEditingFiles;

  /// CodeWalk UI string — toolFinding
  ///
  /// In en, this message translates to:
  /// **'Finding'**
  String get toolFinding;

  /// CodeWalk UI string — toolFindingFiles
  ///
  /// In en, this message translates to:
  /// **'Finding files'**
  String get toolFindingFiles;

  /// CodeWalk UI string — toolReading
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get toolReading;

  /// CodeWalk UI string — toolReadingFile
  ///
  /// In en, this message translates to:
  /// **'Reading file'**
  String get toolReadingFile;

  /// CodeWalk UI string — toolRunning
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get toolRunning;

  /// CodeWalk UI string — toolRunningCommand
  ///
  /// In en, this message translates to:
  /// **'Running command'**
  String get toolRunningCommand;

  /// CodeWalk UI string — toolRunningTask
  ///
  /// In en, this message translates to:
  /// **'Running task'**
  String get toolRunningTask;

  /// CodeWalk UI string — toolSearching
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get toolSearching;

  /// CodeWalk UI string — toolSearchingCode
  ///
  /// In en, this message translates to:
  /// **'Searching code'**
  String get toolSearchingCode;

  /// CodeWalk UI string — toolSearchingWeb
  ///
  /// In en, this message translates to:
  /// **'Searching the web'**
  String get toolSearchingWeb;

  /// CodeWalk UI string — toolUpdatingTaskList
  ///
  /// In en, this message translates to:
  /// **'Updating task list'**
  String get toolUpdatingTaskList;

  /// CodeWalk UI string — toolUpdatingTasks
  ///
  /// In en, this message translates to:
  /// **'Updating tasks'**
  String get toolUpdatingTasks;

  /// CodeWalk UI string — toolWaitingForInput
  ///
  /// In en, this message translates to:
  /// **'Waiting for your input'**
  String get toolWaitingForInput;

  /// CodeWalk UI string — toolWriting
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get toolWriting;

  /// CodeWalk UI string — toolWritingFile
  ///
  /// In en, this message translates to:
  /// **'Writing file'**
  String get toolWritingFile;

  /// CodeWalk UI string — tourBack
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// CodeWalk UI string — tourSkip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tourSkip;

  /// CodeWalk UI string — trayQuit
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// CodeWalk UI string — trayShow
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get trayShow;

  /// CodeWalk UI string — workspaceBrowseDirs
  ///
  /// In en, this message translates to:
  /// **'Browse directories'**
  String get workspaceBrowseDirs;

  /// CodeWalk UI string — workspaceCloseProject
  ///
  /// In en, this message translates to:
  /// **'Close {project}'**
  String workspaceCloseProject(String project);

  /// CodeWalk UI string — workspaceFilterDirs
  ///
  /// In en, this message translates to:
  /// **'Filter directories'**
  String get workspaceFilterDirs;

  /// CodeWalk UI string — workspaceProjectDirectory
  ///
  /// In en, this message translates to:
  /// **'Project directory'**
  String get workspaceProjectDirectory;

  /// CodeWalk UI string — workspaceProjectHint
  ///
  /// In en, this message translates to:
  /// **'/repo/my-project'**
  String get workspaceProjectHint;

  /// CodeWalk UI string — workspaceRemoveFromHistory
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from history'**
  String workspaceRemoveFromHistory(String name);

  /// CodeWalk UI string — shown when a tapped file path cannot be resolved in the project
  ///
  /// In en, this message translates to:
  /// **'File not found: {path}'**
  String msgFilePathNotFound(String path);

  /// CodeWalk UI string — settingsReadAloudSectionTitle
  ///
  /// In en, this message translates to:
  /// **'Text to speech'**
  String get settingsReadAloudSectionTitle;

  /// CodeWalk UI string — settingsReadAloudSectionDescription
  ///
  /// In en, this message translates to:
  /// **'Read assistant responses aloud. Configure speed, pitch, and voice.'**
  String get settingsReadAloudSectionDescription;

  /// CodeWalk UI string — settingsReadAloudEnabled
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get settingsReadAloudEnabled;

  /// CodeWalk UI string — settingsReadAloudEnabledDescription
  ///
  /// In en, this message translates to:
  /// **'Show a read-aloud button on assistant messages.'**
  String get settingsReadAloudEnabledDescription;

  /// CodeWalk UI string — settingsReadAloudSpeed
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get settingsReadAloudSpeed;

  /// CodeWalk UI string — settingsReadAloudSpeedDescription
  ///
  /// In en, this message translates to:
  /// **'Adjust the speaking rate.'**
  String get settingsReadAloudSpeedDescription;

  /// CodeWalk UI string — settingsReadAloudPitch
  ///
  /// In en, this message translates to:
  /// **'Pitch'**
  String get settingsReadAloudPitch;

  /// CodeWalk UI string — settingsReadAloudPitchDescription
  ///
  /// In en, this message translates to:
  /// **'Adjust the voice pitch.'**
  String get settingsReadAloudPitchDescription;

  /// CodeWalk UI string — settingsReadAloudVoice
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get settingsReadAloudVoice;

  /// CodeWalk UI string — settingsReadAloudVoiceHint
  ///
  /// In en, this message translates to:
  /// **'Select a voice for read-aloud.'**
  String get settingsReadAloudVoiceHint;

  /// CodeWalk UI string — msgReadAloud
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get msgReadAloud;

  /// CodeWalk UI string — msgStopReadAloud
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get msgStopReadAloud;

  /// CodeWalk UI string — msgReadAloudNotAvailable
  ///
  /// In en, this message translates to:
  /// **'Text-to-speech is not available on this device.'**
  String get msgReadAloudNotAvailable;

  /// CodeWalk UI string — mermaidDiagramLabel
  ///
  /// In en, this message translates to:
  /// **'Mermaid Diagram'**
  String get mermaidDiagramLabel;

  /// CodeWalk UI string — mermaidCopySourceTooltip
  ///
  /// In en, this message translates to:
  /// **'Copy source'**
  String get mermaidCopySourceTooltip;

  /// CodeWalk UI string — mathExpressionLabel
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get mathExpressionLabel;

  /// CodeWalk UI string — settingsAppearanceMathRendering
  ///
  /// In en, this message translates to:
  /// **'Math rendering'**
  String get settingsAppearanceMathRendering;

  /// CodeWalk UI string — settingsAppearanceMathRenderingDescription
  ///
  /// In en, this message translates to:
  /// **'Render LaTeX math expressions (\$…\$ and \$\$…\$\$) as typeset equations in chat messages.'**
  String get settingsAppearanceMathRenderingDescription;

  /// CodeWalk UI string — Tooltip for the share-as-image action on a chat message bubble
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get msgShareAsImage;

  /// CodeWalk UI string — Subject line when sharing a message image via the system share sheet
  ///
  /// In en, this message translates to:
  /// **'CodeWalk message'**
  String get msgShareAsImageSubject;

  /// CodeWalk UI string — Shown when the message bubble exceeds the maximum capture height
  ///
  /// In en, this message translates to:
  /// **'Message is too long to share as an image.'**
  String get msgShareAsImageTooTall;

  /// CodeWalk UI string — Shown when image capture or sharing fails unexpectedly
  ///
  /// In en, this message translates to:
  /// **'Could not share message as image.'**
  String get msgShareAsImageFailed;

  /// CodeWalk UI string — Label for the Cloudflare Access OAuth toggle in the onboarding/server setup wizard
  ///
  /// In en, this message translates to:
  /// **'Use OAuth (Cloudflare Access)'**
  String get useOAuthCloudflareAccess;

  /// CodeWalk UI string — Subtitle explaining the OAuth toggle when supported on this platform
  ///
  /// In en, this message translates to:
  /// **'Opens a browser for Cloudflare Access Managed OAuth.'**
  String get useOAuthCloudflareAccessSubtitle;

  /// CodeWalk UI string — Shown when OAuth is not supported on the current platform
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Access OAuth is not available on this platform. Use Basic Auth instead.'**
  String get useOAuthCloudflareAccessUnsupported;

  /// CodeWalk UI string — Chip label showing a server profile uses OAuth authentication
  ///
  /// In en, this message translates to:
  /// **'OAuth'**
  String get serverOAuthChip;

  /// CodeWalk UI string — Label for the Tailscale transport toggle in the onboarding/server setup wizard
  ///
  /// In en, this message translates to:
  /// **'Use Tailscale'**
  String get useTailscale;

  /// CodeWalk UI string — Subtitle explaining the Tailscale toggle when supported on this platform
  ///
  /// In en, this message translates to:
  /// **'Routes traffic through the Tailscale network without a system VPN.'**
  String get useTailscaleSubtitle;

  /// CodeWalk UI string — Shown when Tailscale transport is not supported on the current platform
  ///
  /// In en, this message translates to:
  /// **'Tailscale is not supported on this platform.'**
  String get useTailscaleUnsupported;

  /// CodeWalk UI string — Chip label showing a server profile routes traffic through Tailscale
  ///
  /// In en, this message translates to:
  /// **'Tailscale'**
  String get serverTailscaleChip;

  /// CodeWalk UI string — Menu action to re-authenticate an OAuth-enabled server profile
  ///
  /// In en, this message translates to:
  /// **'Re-authenticate'**
  String get serverReauthenticate;

  /// CodeWalk UI string — Menu action to clear stored OAuth credentials for a server profile
  ///
  /// In en, this message translates to:
  /// **'Clear OAuth'**
  String get serverClearOAuth;

  /// CodeWalk UI string — Error message shown when OAuth re-authentication fails
  ///
  /// In en, this message translates to:
  /// **'OAuth authentication failed'**
  String get serverOAuthAuthFailed;

  /// CodeWalk UI string — Error when user tries to enable OAuth on an unsupported platform
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Access OAuth is not supported on this platform'**
  String get serverOAuthNotSupported;

  /// CodeWalk UI string — Switch tile label in onboarding wizard to enable Basic Auth
  ///
  /// In en, this message translates to:
  /// **'Use Basic Auth'**
  String get onboardingUseBasicAuth;

  /// CodeWalk UI string — Validation error shown when Basic Auth username is empty
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get onboardingUsernameRequired;

  /// CodeWalk UI string — Validation error shown when Basic Auth password is empty
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get onboardingPasswordRequired;

  /// CodeWalk UI string — Dropdown hint label for selecting a tailnet peer as server URL source
  ///
  /// In en, this message translates to:
  /// **'Select a Tailscale peer'**
  String get tailscaleSelectPeer;

  /// CodeWalk UI string — Shown in peer dropdown when Tailscale is connected but no peers are visible
  ///
  /// In en, this message translates to:
  /// **'No peers found'**
  String get tailscaleNoPeers;

  /// CodeWalk UI string — Badge shown next to a Tailscale peer that is currently offline
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get tailscalePeerOffline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
