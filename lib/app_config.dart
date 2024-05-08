import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'common/logger.dart';

Future configure() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 縦固定
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  /// Logger
  loggerConfigure();
}
