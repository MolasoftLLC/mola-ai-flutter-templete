import '../timeline/timeline_page_notifier.dart';

/// ホームに表示する公開タイムラインを、既存のタイムライン機能と同じ経路で取得する。
class NewHomePageNotifier extends TimelinePageNotifier {
  NewHomePageNotifier() : super(feedType: TimelineFeedType.public);
}
