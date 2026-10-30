import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/sake/personal_sake_record.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/eintities/sake_catalog_browse.dart';
import '../../../domain/eintities/sake_label_scan.dart';
import '../../../domain/notifier/sake_stamp_store.dart';
import '../../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../../domain/repository/place_map_repository.dart';
import 'japan_sake_map.dart';
import 'sake_stamp_acquisition_demo.dart';

/// Captures the account and existing records before a successful save.
/// Optional stamp failures never turn a successful record save into a failure.
class SakeStampAwardSession {
  SakeStampAwardSession._(this.store, this.repository);
  final SakeStampStore store;
  final PlaceMapRepository repository;
  final priorBrands = <int>{};
  bool _current(BuildContext context) =>
      context.mounted &&
      identical(Provider.of<SakeStampStore?>(context, listen: false), store) &&
      ModalRoute.of(context)?.isCurrent != false;

  static Future<SakeStampAwardSession?> prepare(BuildContext context) async {
    final store = Provider.of<SakeStampStore?>(context, listen: false);
    final repository = Provider.of<PlaceMapRepository?>(context, listen: false);
    if (store == null || repository == null) return null;
    final session = SakeStampAwardSession._(store, repository);
    final records =
        Provider.of<SavedSakeState?>(context, listen: false)?.savedSakeList ??
        const <Sake>[];
    final ids = records
        .where(hasPersonalSakeRecord)
        .map((s) => s.sakeId ?? 0)
        .where((id) => id > 0)
        .toSet()
        .toList();
    try {
      await store.ready;
      final origins = ids.isEmpty
          ? const <SakeProductOrigin>[]
          : await repository.fetchSakeOrigins(ids);
      if (!context.mounted || !session._current(context)) return null;
      session.priorBrands.addAll(origins.map((o) => o.brandId));
      await store.inheritRecords(
        origins,
        isCurrent: () => context.mounted && session._current(context),
      );
      return context.mounted && session._current(context) ? session : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> detail(
    BuildContext context,
    SakeOverview overview,
  ) async {
    if (!isStampEligibleOverview(overview)) return;
    final name = overview.brand.name?.trim() ?? '';
    final id = overview.brand.id ?? overview.sake.brandId ?? 0;
    final prefecture = int.tryParse(
      overview.brewery.prefectureCode ?? overview.sake.prefectureCode ?? '',
    );
    if (id <= 0 ||
        name.isEmpty ||
        prefecture == null ||
        (overview.sake.brandId != null && overview.sake.brandId != id)) {
      return;
    }
    final session = await prepare(context);
    if (session == null || !context.mounted || !session._current(context)) {
      return;
    }
    await session._award(
      context,
      brandId: id,
      prefecture: prefecture,
      sakeId: overview.sake.sakeId ?? 0,
      name: name,
      source: 'analyzed_detail',
    );
  }

  Future<void> record(BuildContext context, Sake sake) async {
    if (!_current(context) ||
        !hasPersonalSakeRecord(sake) ||
        (sake.sakeId ?? 0) <= 0) {
      return;
    }
    try {
      final origins = await repository.fetchSakeOrigins([sake.sakeId!]);
      if (!context.mounted || !_current(context)) return;
      final origin = origins.where((o) => o.sakeId == sake.sakeId).firstOrNull;
      if (origin == null || store.contains(origin.brandId)) return;
      int? cursor;
      final seen = <int>{};
      do {
        final page = await repository.fetchPrefectureBrands(
          origin.prefectureCode,
          afterId: cursor,
        );
        if (!context.mounted || !_current(context)) return;
        final brand = page.items
            .where((b) => b.brandId == origin.brandId)
            .firstOrNull;
        if (brand != null) {
          await _award(
            context,
            brandId: origin.brandId,
            prefecture: origin.prefectureCode,
            sakeId: origin.canonicalSakeId,
            name: brand.name,
            source: 'personal_record',
          );
          return;
        }
        cursor = page.nextCursor;
        if (cursor != null && !seen.add(cursor)) return;
      } while (cursor != null);
    } catch (_) {
      /* Keep the saved record; retry on a later successful action. */
    }
  }

  Future<void> _award(
    BuildContext context, {
    required int brandId,
    required int prefecture,
    required int sakeId,
    required String name,
    required String source,
  }) async {
    if (!_current(context) || name.trim().isEmpty) return;
    final stamp = CollectedSakeStamp(
      brandId: brandId,
      prefectureCode: prefecture,
      sakeId: sakeId,
      source: source,
      observedAt: DateTime.now(),
    );
    if (!stamp.valid) return;
    try {
      final prefectures = await JapanSakeMapData.load();
      if (!context.mounted || !_current(context)) return;
      final region = prefectures.firstWhere((p) => p.code == prefecture);
      final fresh = await store.acquire(
        stamp,
        isCurrent: () => context.mounted && _current(context),
      );
      if (!fresh ||
          !context.mounted ||
          !_current(context) ||
          priorBrands.contains(brandId) ||
          store.presenting) {
        return;
      }
      store.presenting = true;
      try {
        await showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: MaterialLocalizations.of(
            context,
          ).modalBarrierDismissLabel,
          barrierColor: const Color(0xFF071C35).withValues(alpha: .88),
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          transitionBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          pageBuilder: (dialogContext, __, ___) => _AwardAccountGuard(
            store: store,
            child: SakeStampAcquisitionDemo(
              brandName: name,
              prefectureName: region.label(dialogContext),
              brandId: brandId,
              demo: false,
            ),
          ),
        );
      } finally {
        store.presenting = false;
      }
    } catch (_) {
      /* A collection failure must not break the original action. */
    }
  }
}

/// Hide and close an award immediately if its account changes mid-animation.
class _AwardAccountGuard extends StatelessWidget {
  const _AwardAccountGuard({required this.store, required this.child});
  final SakeStampStore store;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!identical(Provider.of<SakeStampStore?>(context), store)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}
