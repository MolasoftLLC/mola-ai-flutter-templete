import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import '../../common/localization/localization_extensions.dart';
import 'menu_photo_crop_page.dart';
import '../../domain/repository/menu_extraction_stream.dart';
import 'menu_search_page_notifier.dart';
import 'widgets/menu_photo_style.dart';
import '../my_page/widgets/place_picker_sheet.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

class MenuPhotoFlowPage extends StatefulWidget {
  const MenuPhotoFlowPage({super.key, required this.notifier, this.pickPlace});
  final Future<DrinkingPlace?> Function(BuildContext, String?)? pickPlace;
  final MenuSearchPageNotifier notifier;
  @override
  State<MenuPhotoFlowPage> createState() => _MenuPhotoFlowPageState();
}

class _MenuPhotoFlowPageState extends State<MenuPhotoFlowPage> {
  bool _submitting = false;
  bool _editing = false;
  bool _closing = false;
  bool _placeInteracted = false;
  bool _pickingPlace = false;

  Future<void> _choosePlace() async {
    if (_pickingPlace) return;
    setState(() {
      _placeInteracted = true;
      _pickingPlace = true;
    });
    try {
      final initial = widget.notifier.analysisPlace?.displayName;
      final place = widget.pickPlace == null
          ? await PlacePickerSheet.show(context, initialPlace: initial)
          : await widget.pickPlace!(context, initial);
      if (mounted && place != null) {
        await widget.notifier.setAnalysisPlace(place);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errorSaveToServer)));
      }
    } finally {
      if (mounted) setState(() => _pickingPlace = false);
    }
  }

  int _submission = 0;

  Future<void> _analyze(File photo) async {
    if (_submitting) return;
    final submission = ++_submission;
    setState(() => _submitting = true);
    try {
      await widget.notifier.extractAndFetchSakeInfo(photo);
    } finally {
      if (mounted && submission == _submission) {
        setState(() => _submitting = false);
      }
    }
  }

  void _cancel() {
    _submission++;
    widget.notifier.cancelAnalysis();
    setState(() => _submitting = false);
  }

  Future<void> _crop(File photo) async {
    setState(() => _editing = true);
    try {
      final cropped = await Navigator.of(context).push<File>(
        MaterialPageRoute(builder: (_) => MenuPhotoCropPage(image: photo)),
      );
      if (mounted && cropped != null) {
        widget.notifier.applyCroppedPhoto(cropped);
      }
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      StateNotifierBuilder<MenuSearchPageState>(
        stateNotifier: widget.notifier,
        builder: (context, state, _) {
          final active =
              state.isLoading ||
              state.isExtractingInfo ||
              (state.isGettingDetails && !state.isMasterLookupComplete);
          final complete =
              state.extractedSakes.isNotEmpty && state.isMasterLookupComplete;
          if (complete && !_placeInteracted && !_pickingPlace && !_closing) {
            _closing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_placeInteracted && !_pickingPlace) {
                Navigator.of(context).pop();
              }
            });
          }
          final photo = state.sakeImage;
          if (photo == null) return const SizedBox.shrink();
          return PopScope(
            canPop: !active && !_submitting && !_editing,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && active) _cancel();
            },
            child: active || (complete && _placeInteracted)
                ? ValueListenableBuilder<MenuReadingProgress>(
                    valueListenable: widget.notifier.menuReadingProgress,
                    builder: (context, progress, _) => MenuAnalysisProgress(
                      photo: photo,
                      onCancel: complete
                          ? () => Navigator.of(context).pop()
                          : _cancel,
                      progress: progress,
                      placeName: widget.notifier.analysisPlace?.displayName,
                      onChoosePlace: _pickingPlace ? null : _choosePlace,
                      complete: complete,
                      onContinue: complete && !_pickingPlace
                          ? () => Navigator.of(context).pop()
                          : null,
                    ),
                  )
                : MenuPhotoConfirmation(
                    photo: photo,
                    cropped: widget.notifier.isPhotoCropped,
                    busy: _submitting || _editing,
                    error: state.errorMessage == null
                        ? null
                        : localizeLegacyMessage(
                            context.l10n,
                            state.errorMessage!,
                          ),
                    onBack: () => Navigator.of(context).pop(),
                    onAnalyze: () => _analyze(photo),
                    onCrop: () => _crop(photo),
                    onRetake: () async {
                      setState(() => _editing = true);
                      try {
                        await widget.notifier.pickImageFromCamera();
                      } finally {
                        if (mounted) setState(() => _editing = false);
                      }
                    },
                    onRestore: widget.notifier.restoreOriginalPhoto,
                  ),
          );
        },
      );
}

class MenuPhotoConfirmation extends StatelessWidget {
  const MenuPhotoConfirmation({
    super.key,
    required this.photo,
    required this.cropped,
    required this.onBack,
    required this.onAnalyze,
    required this.onRetake,
    required this.onCrop,
    required this.onRestore,
    this.error,
    this.busy = false,
  });
  final File photo;
  final bool cropped;
  final bool busy;
  final String? error;
  final VoidCallback onBack, onAnalyze, onRetake, onCrop, onRestore;

  void _zoom(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: MenuPhotoStyle.deep,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 6,
                child: Image.file(
                  photo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      context.l10n.menuPhotoLoadFailed,
                      style: MenuPhotoStyle.text(14),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MenuPhotoStyle.deep,
    appBar: MenuPhotoStyle.appBar(
      context.l10n.menuConfirmPhoto,
      onBack: busy ? null : onBack,
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Flexible(
            child: ColoredBox(
              color: MenuPhotoStyle.blue,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SizedBox(
                        height: 490,
                        child: Semantics(
                          button: true,
                          label: context.l10n.menuZoomPhoto,
                          child: GestureDetector(
                            onTap: () => _zoom(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: MenuPhotoStyle.deep,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Image.file(
                                photo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Center(
                                  child: Text(
                                    context.l10n.menuPhotoLoadFailed,
                                    style: MenuPhotoStyle.text(13),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (cropped) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.menuPhotoCropped,
                              style: MenuPhotoStyle.text(12),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: busy ? null : onRestore,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  context.l10n.menuRestorePhoto,
                                  maxLines: 2,
                                  textAlign: TextAlign.right,
                                  style: MenuPhotoStyle.text(12, bold: true),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: MenuPhotoStyle.deep,
            width: double.infinity,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(error!, style: MenuPhotoStyle.text(13)),
                      ),
                    MenuPhotoButton(
                      label: context.l10n.menuAnalyzePhoto,
                      height: 56,
                      fontSize: 17,
                      color: MenuPhotoStyle.yellow,
                      onPressed: busy ? null : onAnalyze,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MenuPhotoButton(
                            label: context.l10n.menuRetakePhoto,
                            icon: 'retake',
                            onPressed: busy ? null : onRetake,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MenuPhotoButton(
                            label: context.l10n.menuCropPhoto,
                            icon: 'crop',
                            onPressed: busy ? null : onCrop,
                          ),
                        ),
                      ],
                    ),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MenuAnalysisProgress extends StatelessWidget {
  const MenuAnalysisProgress({
    super.key,
    required this.photo,
    required this.onCancel,
    this.progress = const MenuReadingProgress(),
    this.placeName,
    this.onChoosePlace,
    this.complete = false,
    this.onContinue,
  });
  final String? placeName;
  final VoidCallback? onChoosePlace;
  final bool complete;
  final VoidCallback? onContinue;
  final MenuReadingProgress progress;
  final File photo;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MenuPhotoStyle.blue,
    appBar: MenuPhotoStyle.appBar(
      context.l10n.menuAnalyzingTitle,
      onBack: onCancel,
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: constraints.maxHeight > 650 ? 54 : 12),
                  Container(
                    height: 280,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: MenuPhotoStyle.deep,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.file(
                      photo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    complete
                        ? (Localizations.localeOf(context).languageCode == 'ja'
                              ? '解析できました'
                              : 'Analysis complete')
                        : progress.names.isNotEmpty
                        ? (Localizations.localeOf(context).languageCode == 'ja'
                              ? '${progress.names.length}件読み取れました'
                              : '${progress.names.length} entries read')
                        : progress.started
                        ? context.l10n.menuAnalyzingHeading
                        : (Localizations.localeOf(context).languageCode == 'ja'
                              ? '写真を準備・送信しています'
                              : 'Preparing and sending your photo'),
                    style: MenuPhotoStyle.text(20, bold: true),
                  ),
                  const SizedBox(height: 20),
                  if (!complete)
                    Text(
                      Localizations.localeOf(context).languageCode == 'ja'
                          ? 'メニューの文字を読み取っています'
                          : 'Reading the text on your menu',
                      style: MenuPhotoStyle.text(13),
                    ),
                  const SizedBox(height: 20),
                  if (!complete) const _MenuIndeterminateProgress(),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    key: const ValueKey('menu-analysis-place'),
                    onPressed: onChoosePlace,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(placeName ?? context.l10n.addConsumedPlace),
                  ),
                  if (!complete && progress.names.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ja'
                            ? '読み取り中・候補は完了後に表示します'
                            : 'Still reading. Candidates will appear when complete.',
                        style: MenuPhotoStyle.text(13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final name
                        in progress.names.reversed.take(4).toList().reversed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          name,
                          style: MenuPhotoStyle.text(16, bold: true),
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  MenuPhotoButton(
                    label: complete
                        ? (Localizations.localeOf(context).languageCode == 'ja'
                              ? '候補を見る ▶'
                              : 'View candidates ▶')
                        : context.l10n.menuStopAnalysis,
                    onPressed: complete ? onContinue : onCancel,
                    height: 52,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MenuIndeterminateProgress extends StatefulWidget {
  const _MenuIndeterminateProgress();
  @override
  State<_MenuIndeterminateProgress> createState() =>
      _MenuIndeterminateProgressState();
}

class _MenuIndeterminateProgressState extends State<_MenuIndeterminateProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.menuAnalyzingTitle,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, constraints) => ColoredBox(
            color: Colors.white.withValues(alpha: .22),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    left: MediaQuery.disableAnimationsOf(context)
                        ? 0
                        : constraints.maxWidth * (1.6 * _animation.value - .6),
                    width: constraints.maxWidth * .62,
                    top: 0,
                    bottom: 0,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
