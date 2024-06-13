import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../common/logger.dart';
import '../domain/repository/mola_api_repository.dart';

part 'app_page_notifier.freezed.dart';

@freezed
abstract class AppPageState with _$AppPageState {
  const factory AppPageState({
    @Default(0) int selectedNavIndex,
    @Default(false) bool needUpDate,
  }) = _AppPageState;
}

class AppPageNotifier extends StateNotifier<AppPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  AppPageNotifier({
    required this.context,
  }) : super(const AppPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();

  GlobalKey first = GlobalKey();
  GlobalKey keyBottomNavigation1 = GlobalKey();
  GlobalKey keyBottomNavigation2 = GlobalKey();
  GlobalKey keyBottomNavigation3 = GlobalKey();
  GlobalKey keyBottomNavigation4 = GlobalKey();
  GlobalKey keyBottomNavigation5 = GlobalKey();
  GlobalKey keyBottomNavigation6 = GlobalKey();

  @override
  Future<void> initState() async {
    super.initState();
    final needUpDate = await isUpdateRequired();
    state = state.copyWith(needUpDate: needUpDate);
    //await initATT();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<Map<String, dynamic>?> getLatestVersion() async {
    final latestVersion = await molaApiRepository.getLatestVersion();
    return latestVersion;
  }

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<bool> isUpdateRequired() async {
    final latestVersion = await getLatestVersion();
    final currentVersion = await getCurrentVersion();
    logger.shout(currentVersion);
    logger.shout(latestVersion);
    return Version.parse(latestVersion!['version']!) >
        Version.parse(currentVersion);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {}
  }

  Future<void> onNavTapped(int index) async {
    state = state.copyWith(selectedNavIndex: index);
  }

  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  //ATT対応時
  //	<key>NSUserTrackingUsageDescription</key>
  //     <string>This app uses tracking data to show you personalized ads.</string>
  // Future<void> initATT() async {
  //   if (await AppTrackingTransparency.trackingAuthorizationStatus ==
  //       TrackingStatus.notDetermined) {
  //     await showCustomTrackingDialog(context);
  //     await Future.delayed(const Duration(milliseconds: 200));
  //     await AppTrackingTransparency.requestTrackingAuthorization();
  //   }
  // }
}
