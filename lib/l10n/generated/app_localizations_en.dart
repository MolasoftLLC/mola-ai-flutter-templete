// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SAKEPEDIA';

  @override
  String get navigationSearch => 'Search';

  @override
  String get navigationMenuAnalysis => 'Menu Scan';

  @override
  String get navigationTimeline => 'Timeline';

  @override
  String get navigationMyPage => 'My Page';

  @override
  String get searchPageTitle => 'Sake Search';

  @override
  String get menuSearchPageTitle => 'Menu Scan';

  @override
  String get preferenceSearchPageTitle => 'Find by Taste';

  @override
  String get helpGuide => 'Help guide';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get mainSearchHelpTitle => 'How to search for sake';

  @override
  String get menuSearchHelpTitle => 'How to scan a menu';

  @override
  String get myPageHelpTitle => 'How to use My Page';

  @override
  String get helpBottleFlowTitle => 'Scan a sake bottle';

  @override
  String get helpBottleFlowDescription =>
      'On the Bottle Scan tab, take or select a photo. AI analyzes the label and retrieves sake information. Use the save button to add the result to My Page.';

  @override
  String get helpAfterAnalysisTitle => 'After analysis';

  @override
  String get helpAfterAnalysisDescription =>
      'Enter a brand name and tap Analyze only to see details such as the brewery and flavor. Use favorites and saved sake to build your own list.';

  @override
  String get helpMenuCaptureTitle => 'Photograph or upload a menu';

  @override
  String get helpMenuCaptureDescription =>
      'Upload a restaurant menu photo from the Menu Scan tab to list the sake shown in it. Keep the screen open until analysis finishes.';

  @override
  String get helpMenuResultTitle => 'Review the results';

  @override
  String get helpMenuResultDescription =>
      'Tap a detected sake to view its brewery, flavor, and recommendation score. Add favorites with the heart or save entries to My Page for tasting notes.';

  @override
  String get helpSavedListTitle => 'Review your saved sake';

  @override
  String get helpSavedListDescription =>
      'My Page brings together your saved sake and favorites. Tap an entry to edit its details, notes, and photos.';

  @override
  String get helpPreferenceAnalysisTitle => 'Analyze your favorites';

  @override
  String get helpPreferenceAnalysisDescription =>
      'AI analyzes your preferences from your favorite sake. You can also edit the resulting preference profile yourself.';

  @override
  String get termsTitle => 'SAKEPEDIA Terms of Use';

  @override
  String get termsAiUsage =>
      'SAKEPEDIA is a sake-focused app that uses AI provided by Google LLC and OpenAI. You may lose access to the service if you do any of the following:\n\n• Send an unnecessary number of requests\n• Use generated data commercially\n• Violate any other terms established by Google LLC or OpenAI';

  @override
  String get termsAiDisclaimer =>
      'Depending on the availability and behavior of the AI services, the app may fail to respond or may return inaccurate or unreliable information. The development team assumes no liability for any inconvenience or loss this may cause. Please use the app with this understanding.';

  @override
  String get termsAccount =>
      'This service uses email addresses and passwords for sign-in. If unauthorized use is suspected, features may be restricted or your access may be suspended.';

  @override
  String get termsContentPolicy =>
      'Users may not post inappropriate photos or information such as the following:\n\n• Photos containing people\n• Violent, threatening, discriminatory, or harassing content\n• Sexual content (excluding alcohol-related content)\n• Content that infringes copyright or other intellectual property rights\n• Any other content we deem inappropriate\n\nThe app uses AI to prevent photos other than sake bottles from being posted. However, inappropriate posts that are detected may be hidden or deleted.';

  @override
  String get termsServiceAvailability =>
      'The service may be suspended or discontinued without notice for operational reasons. Analysis images and other data stored on the server may be deleted as a result. Be sure to keep your own copy of important data.';

  @override
  String get termsClosing =>
      'By accepting the terms above, we hope you enjoy using SAKEPEDIA.';

  @override
  String get sakeTrivia => 'SAKE TRIVIA';

  @override
  String get triviaLoadFailed => 'Could not load sake trivia';

  @override
  String get triviaQuestionFallback => 'Did you know?';

  @override
  String get triviaTailOne =>
      'It is a useful detail to remember when ordering sake.';

  @override
  String get triviaTailTwo =>
      'Knowing this can open up more pairing possibilities.';

  @override
  String get triviaTailThree =>
      'It makes a great conversation starter with friends.';

  @override
  String get triviaTailFour =>
      'Keep it in mind for your next brewery visit or tasting.';

  @override
  String get triviaTailFive =>
      'A little knowledge makes choosing sake even more enjoyable.';

  @override
  String get everyoneSake => 'Everyone\'s Sake';

  @override
  String get publicTimelineEmpty =>
      'There are no saved sake posts on the timeline yet.\nPosts from other users will appear here.';

  @override
  String get myPosts => 'My Posts';

  @override
  String get myPostsEmpty =>
      'You have not shared any sake on the timeline yet.\nShare one of your favorites!';

  @override
  String get understood => 'Got it';

  @override
  String get envyTutorialTitle => 'Send some envy';

  @override
  String get envyTutorialDescription =>
      'Tap Good on a sake that catches your eye.\nIt is anonymous, so feel free to tap away!';

  @override
  String get timelineLoginTitle => 'Sign in to enjoy more';

  @override
  String get timelineLoginMessage =>
      'Sign in to save, favorite, envy, or report posts from the timeline.';

  @override
  String get rankingLoginMessage => 'Sign in to send envy from the ranking.';

  @override
  String get dataFetchFailed =>
      'Could not load the data. Check your connection.';

  @override
  String get reload => 'Reload';

  @override
  String get envySent => 'Envy sent!';

  @override
  String get envySendFailed => 'Could not send envy. Check your connection.';

  @override
  String get envyAlready => 'You already envied this post!';

  @override
  String get reportAccepted => 'Thank you. Your report has been received.';

  @override
  String get reportAlready => 'You have already reported this post.';

  @override
  String get reportFailed =>
      'Could not submit the report. Check your connection.';

  @override
  String get refresh => 'Refresh';

  @override
  String get envyRankingTitle => 'Most Envied Sake';

  @override
  String get envyRankingSubtitle => 'See the top 20 most-envied posts';

  @override
  String tasteLabel(String taste) {
    return 'Taste: $taste';
  }

  @override
  String get readMore => 'Read more';

  @override
  String get anonymousUser => 'Anonymous user';

  @override
  String get reportPostTitle => 'Report this post?';

  @override
  String get reportPostDescription =>
      'This post will be reported for review. Do you want to continue?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get rankingEmpty => 'There are no posts to rank yet.';

  @override
  String get rankingFetchFailed =>
      'Could not load the ranking. Please wait and try again.';

  @override
  String get ownPostsLoginRequired => 'Sign in to view your posts.';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get timelineLoginRequired => 'Sign in to view the timeline.';

  @override
  String get preferenceSweet => 'Sweet';

  @override
  String get preferenceDry => 'Dry';

  @override
  String get preferenceClean => 'Clean';

  @override
  String get preferenceFruity => 'Fruity';

  @override
  String get preferenceNigori => 'Nigori';

  @override
  String get preferenceSparkling => 'Lightly sparkling';

  @override
  String get preferenceAcidic => 'Acidic';

  @override
  String get favoriteSakeQuestion => 'What kind of sake do you like?';

  @override
  String get selectPreferenceFeatures =>
      'Select one or more characteristics you enjoy';

  @override
  String get selectAtLeastOne => 'Select at least one option';

  @override
  String get preferencesChangeAnytime =>
      'You can change this anytime from My Page!';

  @override
  String betaVersion(String version) {
    return 'Beta $version';
  }

  @override
  String get bottleListClosingNotice =>
      'This feature overlaps with Saved Sake and is scheduled to be retired.';

  @override
  String get noBottleImages => 'No bottle images have been saved';

  @override
  String get captureBottleHint => 'Try taking a photo with Bottle Scan';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get unknownSake => 'Unknown sake';

  @override
  String capturedDate(String date) {
    return 'Captured: $date';
  }

  @override
  String get deleteBottleImageTitle => 'Delete image';

  @override
  String get deleteBottleImageDescription => 'Delete this sake bottle image?';

  @override
  String get errorSelectImage => 'Could not select the image';

  @override
  String get unanalyzedBottle => 'Unanalyzed bottle';

  @override
  String get errorSaveBottleImage => 'Could not save the bottle image';

  @override
  String get errorLoadBottleImages => 'Could not load bottle images';

  @override
  String get errorDeleteBottleImage => 'Could not delete the bottle image';

  @override
  String get axisFruity => 'Fruity';

  @override
  String get axisCalm => 'Subtle';

  @override
  String get axisSweetness => 'Sweetness';

  @override
  String get axisDry => 'Dry';

  @override
  String get axisSweet => 'Sweet';

  @override
  String get axisAcidity => 'Acidity';

  @override
  String get axisLowAcid => 'Low';

  @override
  String get axisHighAcid => 'High';

  @override
  String get axisUmami => 'Umami';

  @override
  String get axisLight => 'Light';

  @override
  String get axisRich => 'Rich';

  @override
  String get axisFinish => 'Finish';

  @override
  String get axisMellow => 'Mellow';

  @override
  String get axisSharp => 'Sharp';

  @override
  String get axisSpiciness => 'Spiciness';

  @override
  String get axisGentle => 'Gentle';

  @override
  String get axisKick => 'Bold';

  @override
  String get tasteTrendSample => 'Your sake profile (sample)';

  @override
  String get tasteTrend => 'Your sake profile';

  @override
  String get tasteTrendSampleDescription =>
      'Your personalized chart will appear here once you have enough favorite sake data.';

  @override
  String get tasteTrendDescription =>
      'This average profile is calculated from your favorite sake. Please remember that it is an AI-generated estimate.';

  @override
  String get signedInUsersOnly => 'Signed-in users only';

  @override
  String get tasteChartLoginDescription =>
      'Generate a preference chart from your favorite sake. Sign in to view your personalized analysis.';

  @override
  String get loginToViewChart => 'Sign in to view chart';

  @override
  String get sakeDiagnosisTitle => 'Your sake preference analysis';

  @override
  String get tasteChartUpdated =>
      'Your taste chart has been updated!\nAdd more favorites to improve its accuracy.';

  @override
  String get sakeDiagnosisFailed =>
      'Could not create an analysis from your favorites. Try adding different sake.';

  @override
  String get savePreferenceAndClose => 'Save to preferences and close';

  @override
  String get badges => 'Badges';

  @override
  String get achievementWelcomeTitle => 'Welcome Toast';

  @override
  String get achievementWelcomeDescription =>
      'Keep using the app to collect badges';

  @override
  String get achievementBottleTitle => 'Bottle Master';

  @override
  String get achievementBottleDescription =>
      'Learn more about sake through bottle analysis';

  @override
  String get achievementEnvyTitle => 'Envy Collector';

  @override
  String get achievementEnvyDescription =>
      'Collect envy and become the center of attention';

  @override
  String get badgeComplete => 'Complete! You earned this badge';

  @override
  String badgeRemaining(int count) {
    return '$count more to the next badge';
  }

  @override
  String get badgeStart => 'Start your first challenge';

  @override
  String get goldBadge => 'Gold badge';

  @override
  String get silverBadge => 'Silver badge';

  @override
  String get bronzeBadge => 'Bronze badge';

  @override
  String get badgeNotEarned => 'Not earned';

  @override
  String get totalEnvyPoints => 'Total envy points';

  @override
  String get collectEnvy => 'Collect envy';

  @override
  String envyEarnedCount(int count) {
    return 'You have received $count envy points';
  }

  @override
  String get envyShareHint =>
      'Share on the timeline to receive envy from the community';

  @override
  String get everyonePraises => 'Community favorite!';

  @override
  String get tryCollecting => 'Start collecting';

  @override
  String get timelineIntroTitle => 'Welcome to the Timeline';

  @override
  String get timelineIntroDescription =>
      'Discover sake enjoyed by the community.\nSave anything that catches your eye to build your own list!';

  @override
  String get timelineIntroEnvyHint =>
      'Tap 👍 when you see a sake worth envying.';

  @override
  String get timelinePublishingTitle => 'About timeline publishing';

  @override
  String get timelinePublishingDescription =>
      'Only the sake information and first photo appear on the timeline. Your impressions and private notes are not shown. Help others discover more sake by sharing.';

  @override
  String get continueAnalysis => 'Continue analysis';

  @override
  String get removeCheck => 'Turn sharing off';

  @override
  String get loginToToggleAutoPost => 'Sign in to change automatic posting.';

  @override
  String get autoPostUpdateFailed =>
      'Could not update automatic posting. Please wait and try again.';

  @override
  String autoPostUpdated(String status) {
    return 'Automatic posting to X is now $status.';
  }

  @override
  String get statusOn => 'on';

  @override
  String get statusOff => 'off';

  @override
  String get autoPostDialogTitle => 'About automatic posting to X';

  @override
  String get autoPostDialogDescription =>
      'Only this image and the analysis result will be posted.\nThank you for helping more people discover sake.';

  @override
  String get continuePosting => 'Keep automatic posting on';

  @override
  String get disableAutoPost => 'Turn automatic posting off';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Use device language';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageEnglish => 'English';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get developer => 'Developer';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saveAction => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownName => 'Unknown name';

  @override
  String get updateRequiredMessage =>
      'Thank you for using SAKEPEDIA. This version is no longer supported. Please update the app from the store.';

  @override
  String get openAppStore => 'Open App Store';

  @override
  String get openPlayStore => 'Open Google Play';

  @override
  String get welcomeTitle => 'Welcome to Sakepedia!';

  @override
  String get welcomeDescription =>
      'Sign in with your email to sync saved sake and favorites across devices. Complete verification using the email sent after signing in.';

  @override
  String get welcomeFree => 'Free to use';

  @override
  String get welcomeBackup => 'Automatically back up saved sake and favorites';

  @override
  String get welcomeMoreStorage => 'Save more sake';

  @override
  String get loginOrRegisterWithEmail => 'Sign in or register with email';

  @override
  String get continueAsGuest => 'Continue without signing in';

  @override
  String get loginLaterHint => 'You can sign in later from My Page.';

  @override
  String get loginBenefitsTitle => 'Get more by signing in';

  @override
  String get loginBenefitsDescription =>
      'You can use the app without registering. Sign in for a higher save limit, backups, and syncing across devices.';

  @override
  String get userFallbackName => 'User';

  @override
  String get signedIn => 'Signed in';

  @override
  String helloUser(String name) {
    return 'Hello, $name!';
  }

  @override
  String get authPageTitle => 'Sign in or register with email';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signInAction => 'Sign in';

  @override
  String get signUpAction => 'Create account';

  @override
  String get signInDescription =>
      'Sign in with your registered email and password. If you forgot your password, you can request a reset email.';

  @override
  String get signUpDescription =>
      'Create an account with an email and password. You can use the same details to sign in afterward.';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get guestUseAvailable => 'You can use the app without registering.';

  @override
  String get passwordMismatch => 'The passwords do not match.';

  @override
  String get passwordResetSent =>
      'A password reset email was sent. Please also check your spam folder.';

  @override
  String get verificationEmailSent =>
      'A verification email was sent. Check your inbox and spam folder, open the link, then sign in again.';

  @override
  String get passwordResetEmailSent => 'A password reset email was sent.';

  @override
  String get loginCompleted => 'Signed in.';

  @override
  String get logoutCompleted => 'Signed out.';

  @override
  String get accountDeleted => 'Account deleted.';

  @override
  String get nicknameUpdated => 'Nickname updated.';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get notSet => 'Not set';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'Example: Sake fan';

  @override
  String get saveNickname => 'Save nickname';

  @override
  String get errorEnterNickname => 'Enter a nickname.';

  @override
  String get errorNicknameLength =>
      'Enter a nickname of no more than 10 characters.';

  @override
  String get errorNicknameUpdate =>
      'Could not update the nickname. Please wait and try again.';

  @override
  String get updating => 'Updating...';

  @override
  String get changeIcon => 'Change profile image';

  @override
  String get iconUpdated => 'Profile image updated.';

  @override
  String get errorIconUpdate =>
      'Could not update the profile image. Please wait and try again.';

  @override
  String get selectFromPhotoLibrary => 'Choose from photo library';

  @override
  String get emailChangeUnavailable =>
      'The email address cannot currently be changed in the app.';

  @override
  String get signingOut => 'Signing out...';

  @override
  String get signOut => 'Sign out';

  @override
  String get accountDeletion => 'Delete account';

  @override
  String get accountDeletionConfirmation => 'Confirm account deletion';

  @override
  String get accountDeletionWarning =>
      'Deleting your account permanently removes all saved sake, favorites, and preference data. This cannot be undone.';

  @override
  String get accountDeletionWarningShort =>
      'Deleting your account removes all saved sake, favorites, and preference data.';

  @override
  String get enterPasswordToConfirm => 'Enter your password to confirm.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteAccountAction => 'Delete account';

  @override
  String get nameSearch => 'Search by name';

  @override
  String get bottleSearch => 'Scan bottle';

  @override
  String get sakeName => 'Sake name';

  @override
  String get enterSakeName => 'Enter a sake name';

  @override
  String get sakeType => 'Type';

  @override
  String get enterOptionalSakeType => 'Enter a type (optional)';

  @override
  String get selectBottleImage => 'Select a photo of a sake label or bottle';

  @override
  String get tapToSelectImage => 'Tap to select an image';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get shareToTimeline => 'Share on timeline';

  @override
  String get onlyFirstImageShared => 'Only the first image will be shared.';

  @override
  String get autoPostToX => 'Automatically post to X';

  @override
  String get autoPostToXDescription =>
      'Automatically post the result to X when analysis finishes.';

  @override
  String get loginToChangeSetting => 'Sign in to change this setting.';

  @override
  String get loadingAutoPostSetting => 'Loading the auto-post setting...';

  @override
  String get updatingSetting => 'Updating setting...';

  @override
  String get analyzeAndSave => 'Analyze and save';

  @override
  String get analyzeOnly => 'Analyze only';

  @override
  String get analyzingWithAd =>
      'Analyzing... Thank you for supporting us by viewing ads.';

  @override
  String get loadingSakeInfo => 'Loading sake information...';

  @override
  String get aiAnalysisResult => 'AI analysis';

  @override
  String get tryBackLabelHint => 'The back label may work better.';

  @override
  String get saveSake => 'Save';

  @override
  String get removeSavedSake => 'Remove from saved';

  @override
  String get savedToMyPage => 'Saved to My Page!';

  @override
  String get favorite => 'Favorite';

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get unknownType => 'Unknown type';

  @override
  String get loadingDetails => 'Loading details...';

  @override
  String get detailsUnavailable => 'Details could not be loaded';

  @override
  String get expand => 'Expand';

  @override
  String get highlyRecommended => 'Highly recommended!';

  @override
  String get recommended => 'Recommended!';

  @override
  String get goodSake => 'Good choice';

  @override
  String get characteristics => 'Characteristics';

  @override
  String get brewery => 'Brewery';

  @override
  String get sakeMeterValue => 'Sake meter value';

  @override
  String get searchByType => 'Search by type';

  @override
  String get sweet => 'Sweet';

  @override
  String get dry => 'Dry';

  @override
  String get savedSake => 'Saved sake';

  @override
  String get savedSakeEmpty => 'No saved sake yet.';

  @override
  String get savedSakeEmptyHint =>
      'No saved sake yet.\nBookmark sake from Menu Scan to see it here!';

  @override
  String get sort => 'Sort';

  @override
  String get gridView => 'Grid view';

  @override
  String get listView => 'List view';

  @override
  String get filterByTag => 'Filter by tag';

  @override
  String get noAvailableTags => 'No tags are available yet.';

  @override
  String savedSakeLimit(int count) {
    return 'You can save up to $count sake entries. Please remove an entry before saving another.';
  }

  @override
  String removedFromSaved(String name) {
    return 'Removed $name from saved sake';
  }

  @override
  String get bottleList => 'Bottle list';

  @override
  String get sakeDetails => 'Sake details';

  @override
  String get price => 'Price';

  @override
  String get recommendationScore => 'Recommendation';

  @override
  String get tasteAndFeatures => 'Taste & characteristics';

  @override
  String get description => 'Description';

  @override
  String get basicInformation => 'Basic information';

  @override
  String get noDetailedInformation => 'No detailed information is available.';

  @override
  String get processing => 'Processing…';

  @override
  String savedDate(String date) {
    return 'Saved $date';
  }

  @override
  String get syncedToServer => 'Saved to server';

  @override
  String get localOnly => 'Not synced (stored on this device only)';

  @override
  String get notSynced => 'Not synced';

  @override
  String consumedAt(String place) {
    return 'Where you had it: $place';
  }

  @override
  String get noMatchingTags => 'No sake matches the selected tags.';

  @override
  String get syncToServer => 'Sync to server';

  @override
  String get manualNameSearchHint =>
      'You can search by entering the name manually';

  @override
  String get syncToChangeVisibility =>
      'Sync to the server to change timeline visibility.';

  @override
  String get loginToChangeVisibility => 'Sign in to change visibility.';

  @override
  String get visibilityChangeHint =>
      'You can show or hide this entry on the timeline at any time.';

  @override
  String get showOnTimeline => 'Show on timeline';

  @override
  String get reanalyze => 'Analyze again';

  @override
  String get change => 'Change';

  @override
  String get loginToReanalyze => 'Sign in to analyze again';

  @override
  String get loginToReanalyzeAfterRename =>
      'Sign in to analyze again after renaming';

  @override
  String get memo => 'Notes';

  @override
  String get memoFilterHint => 'Add tags to filter your saved sake list.';

  @override
  String get impressionLabel => 'Impressions (up to 200 characters)';

  @override
  String get impressionHint =>
      'Record your impressions of the flavor and aroma';

  @override
  String get placeConsumed => 'Where you had it';

  @override
  String get placeConsumedHint => 'Record the restaurant or event name';

  @override
  String get saveMemories => 'Save your memories';

  @override
  String get recordPrompt => 'Would you like to keep a record of this sake?';

  @override
  String get add => 'Add';

  @override
  String get maxThreeImages => 'You can add up to three images';

  @override
  String get syncToAddImages => 'Sync to the server to add images';

  @override
  String get memoSaved => 'Notes saved';

  @override
  String get savingToServer => 'Saving to server…';

  @override
  String get savedToServer => 'Saved to server';

  @override
  String get errorSaveToServer =>
      'Could not save to the server. Check your connection.';

  @override
  String get errorEnterSakeNameDetail => 'Enter the sake name';

  @override
  String get noChanges => 'There are no changes';

  @override
  String get nameSaved => 'Name saved';

  @override
  String get reanalyzing => 'Analyzing again…';

  @override
  String get reanalyzeCompleted => 'Analysis completed';

  @override
  String get errorReanalyze =>
      'Analysis failed. Check your connection and try again.';

  @override
  String get syncingWithServer => 'Syncing with server…';

  @override
  String get syncedWithServer => 'Synced with server!';

  @override
  String get errorSync => 'Sync failed. Check your connection and try again.';

  @override
  String get imageAdded => 'Image added';

  @override
  String get deleteImageConfirmation => 'Delete this image?';

  @override
  String get deleteImageDescription =>
      'This image will be removed from the list.';

  @override
  String get deleteImage => 'Delete image';

  @override
  String get imageDeleted => 'Image deleted';

  @override
  String get errorImageAdd => 'Could not add the image';

  @override
  String get errorImageDelete => 'Could not delete the image';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavoritesToast => 'Removed from favorites';

  @override
  String get missingSavedIdReanalyze =>
      'Analysis is unavailable because the saved ID is missing';

  @override
  String get syncBeforeVisibility =>
      'Sync to the server before changing timeline visibility';

  @override
  String get errorVisibilityUpdate =>
      'Could not update visibility. Check your connection.';

  @override
  String get publishedToTimeline => 'Published to the timeline';

  @override
  String get hiddenFromTimeline => 'Hidden from the timeline';

  @override
  String get missingSavedIdServerSave =>
      'The entry cannot be saved to the server because its saved ID is missing';

  @override
  String get loginForServerReanalyze => 'Sign in to use server analysis';

  @override
  String get savedIdNotFound => 'The saved ID could not be found';

  @override
  String get syncableSavedIdNotFound => 'No saved ID is available to sync.';

  @override
  String get savedInformationNotFound => 'Saved information could not be found';

  @override
  String get favoriteSake => 'Favorite sake';

  @override
  String get favoriteEmpty =>
      'No favorites yet.\nSearch for sake and tap the heart icon!';

  @override
  String removedFromFavorites(String name) {
    return 'Removed $name from favorites';
  }

  @override
  String get favoriteDiagnosis => 'Your sake taste analysis';

  @override
  String get diagnosisDailyLimit =>
      'You can run this analysis up to three times per day. Please try again later.';

  @override
  String get needMoreFavorites => 'Add a few more favorite sake first.';

  @override
  String get tastePreferences => 'Sake preferences';

  @override
  String get tastePreferencesDescription =>
      'Describe what you enjoy to make it easier to find sake recommendations.';

  @override
  String get tastePreferencesHint =>
      'Example: I like sweet, fruity sake and prefer it not too dry.';

  @override
  String get preferencesSaved => 'Preferences saved';

  @override
  String get menuPhotoDescription => 'Upload a menu photo to find sake';

  @override
  String get searchSakeFromMenu => 'Find sake';

  @override
  String get detectedSake => 'Detected sake';

  @override
  String get menuHistory => 'Scan history';

  @override
  String get noMenuHistory => 'No scan history';

  @override
  String get pastMenuAnalysis => 'Previous menu scans';

  @override
  String get deleteConfirmation => 'Confirm deletion';

  @override
  String get deleteMenuHistoryConfirmation =>
      'Delete this menu scan from history?';

  @override
  String get delete => 'Delete';

  @override
  String sakeCount(int count) {
    return '$count sake entries';
  }

  @override
  String get enterStoreName => 'Enter restaurant name';

  @override
  String get enterStoreNameHint => 'Enter the restaurant name';

  @override
  String get preferenceSearchDescription => 'Find sake by region and flavor!';

  @override
  String get searchByRegion => 'Search by region';

  @override
  String get continueInquiry => 'Ask another question';

  @override
  String get flavorGroupOne => 'Flavor profile 1';

  @override
  String get flavorGroupTwo => 'Flavor profile 2';

  @override
  String get specificDesignation => 'Sake classification';

  @override
  String get selectRegion => 'Select a region';

  @override
  String get region => 'Region';

  @override
  String get flavor => 'Aroma & profile';

  @override
  String get taste => 'Taste';

  @override
  String get type => 'Type';

  @override
  String get askAi => 'Ask AI';

  @override
  String get savedLimitTitle => 'Saved sake limit reached';

  @override
  String savedLimitMessage(int count) {
    return 'Create a free account to increase your saved sake limit.\nYour current limit is $count.\nRegister before analysis to save more sake for free!';
  }

  @override
  String get favoriteLimitTitle => 'Favorites limit reached';

  @override
  String favoriteLimitMessage(int count) {
    return 'Create a free account to increase your favorites limit.\nYour current limit is $count.\nRegister to add unlimited favorites!';
  }

  @override
  String get goToLoginOrRegister => 'Sign in or register';

  @override
  String get adConfirmation => 'Watch an ad?';

  @override
  String get adFeatureDescription => 'Watch an ad to use this feature.';

  @override
  String get searchAdDescription =>
      'Watch an ad to search for sake information. Thank you for your support.';

  @override
  String get bottleAdDescription =>
      'Watch an ad to analyze the sake bottle. Continue?';

  @override
  String get menuAdDescription =>
      'Watch an ad to analyze sake information from a menu.';

  @override
  String get searchCancelled =>
      'Search canceled. Please consider watching the ad next time.';

  @override
  String get analysisCancelled =>
      'Analysis canceled. Please consider watching the ad next time.';

  @override
  String get imageSaveFailed => 'Could not save the image';

  @override
  String get agree => 'Continue';

  @override
  String get errorEnterEmail => 'Enter your email address.';

  @override
  String get errorEnterPassword => 'Enter your password.';

  @override
  String get errorPasswordLength =>
      'Enter a password with at least 6 characters.';

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorInvalidCredential =>
      'The email address or password is incorrect.';

  @override
  String get errorUserNotFound =>
      'No matching user was found. Check whether you have registered.';

  @override
  String get errorEmailInUse => 'This email address is already in use.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorTooManyRequests =>
      'Too many requests. Please wait and try again.';

  @override
  String get errorSignInFailed =>
      'Sign-in failed. Check your connection and try again.';

  @override
  String get errorSignUpFailed =>
      'Registration failed. Please wait and try again.';

  @override
  String get errorVerificationEmailFailed =>
      'Could not send the verification email. Please wait and try again.';

  @override
  String get errorEmailSendFailed =>
      'Could not send the email. Check your connection and try again.';

  @override
  String get errorSignOutFailed =>
      'Sign-out failed. Please wait and try again.';

  @override
  String get errorUserDisabled =>
      'This email address cannot be used. Try another email address.';

  @override
  String get errorRecentLoginRequired =>
      'For security, please sign out and sign in again before retrying.';

  @override
  String get errorLoginStateUnavailable =>
      'Your sign-in state could not be confirmed. Sign in again and retry.';

  @override
  String get errorAuthenticationFailed =>
      'Authentication failed. Check your connection and try again.';

  @override
  String get errorAccountDeletion =>
      'Could not delete the account. Please wait and try again.';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get errorEnterSakeName => 'Enter a sake name.';

  @override
  String get errorSakeNotFound => 'No sake information was found.';

  @override
  String get errorSakeFetch => 'Could not load sake information.';

  @override
  String get errorImageNotFound => 'The image to analyze could not be found.';

  @override
  String get errorMenuExtraction => 'Could not extract sake information.';

  @override
  String get errorNoSakeExtracted => 'No sake information could be extracted.';

  @override
  String get errorSakeDetailFetch =>
      'Could not load detailed sake information.';

  @override
  String get noPreferenceConfigured =>
      'Set your preferences before trying this feature.';
}
