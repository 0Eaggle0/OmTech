import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Снимок экрана приложения для отчёта об ошибке.
///
/// Корень приложения обёрнут в `RepaintBoundary` с [boundaryKey] (см.
/// `CampusApp`), поэтому в кадр попадают и открытые шторки с диалогами.
class ScreenCapture {
  ScreenCapture._();

  static final boundaryKey = GlobalKey(debugLabel: 'app-screen');

  /// PNG во временной папке или `null`, если снять не вышло.
  static Future<String?> capture() async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return null;
      // `debugNeedsPaint` есть только в debug-сборке.
      if (kDebugMode && boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }
      final image = await boundary.toImage(pixelRatio: 1.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(p.join(
        dir.path,
        'omtech_screen_${DateTime.now().millisecondsSinceEpoch}.png',
      ));
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (e) {
      debugPrint('[BugReport] снимок экрана не удался: $e');
      return null;
    }
  }
}
