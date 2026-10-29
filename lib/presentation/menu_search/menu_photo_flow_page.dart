import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import '../../common/localization/localization_extensions.dart';
import 'menu_photo_crop_page.dart';
import 'menu_search_page_notifier.dart';
import 'widgets/menu_photo_style.dart';

class MenuPhotoFlowPage extends StatefulWidget {
  const MenuPhotoFlowPage({super.key, required this.notifier});
  final MenuSearchPageNotifier notifier;
  @override
  State<MenuPhotoFlowPage> createState() => _MenuPhotoFlowPageState();
}

class _MenuPhotoFlowPageState extends State<MenuPhotoFlowPage> {
  bool _submitting = false;
  bool _editing = false;
  bool _closing = false;
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
          if (state.extractedSakes.isNotEmpty &&
              state.isMasterLookupComplete &&
              !_closing) {
            _closing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
          }
          final photo = state.sakeImage;
          if (photo == null) return const SizedBox.shrink();
          return PopScope(
            canPop: !active && !_submitting && !_editing,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && active) _cancel();
            },
            child: active
                ? MenuAnalysisProgress(photo: photo, onCancel: _cancel)
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
    backgroundColor: MenuPhotoStyle.blue,
    appBar: MenuPhotoStyle.appBar(
      context.l10n.menuConfirmPhoto,
      onBack: busy ? null : onBack,
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
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
                  const SizedBox(height: 8),
                  if (cropped)
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    )
                  else
                    TextButton(
                      onPressed: () => _zoom(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 24),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const MenuPhotoIcon('zoom', size: 18),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.menuZoomPhoto,
                            style: MenuPhotoStyle.text(12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            color: MenuPhotoStyle.deep,
            width: double.infinity,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(error!, style: MenuPhotoStyle.text(13)),
                      ),
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
                    const SizedBox(height: 12),
                    MenuPhotoButton(
                      label: context.l10n.menuAnalyzePhoto,
                      height: 56,
                      fontSize: 17,
                      color: MenuPhotoStyle.yellow,
                      onPressed: busy ? null : onAnalyze,
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
  });
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
                    context.l10n.menuAnalyzingHeading,
                    style: MenuPhotoStyle.text(20, bold: true),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.menuAnalyzingDescription,
                    style: MenuPhotoStyle.text(13),
                  ),
                  const SizedBox(height: 20),
                  const _MenuIndeterminateProgress(),
                  const SizedBox(height: 86),
                  MenuPhotoButton(
                    label: context.l10n.menuStopAnalysis,
                    onPressed: onCancel,
                    height: 52,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.menuPhotoPreserved,
                    style: MenuPhotoStyle.text(12),
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
