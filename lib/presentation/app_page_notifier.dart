import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:state_notifier/state_notifier.dart';

part 'app_page_notifier.freezed.dart';

@freezed
abstract class AppPageState with _$AppPageState {
  const factory AppPageState({
    @Default(0) int selectedNavIndex,
  }) = _AppPageState;
}

class AppPageNotifier extends StateNotifier<AppPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  AppPageNotifier({
    required this.context,
  }) : super(const AppPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
    //await initATT();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {}
  }

  Future<void> onNavTapped(int index) async {
    state = state.copyWith(selectedNavIndex: index);
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
