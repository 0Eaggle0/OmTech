import 'package:flutter/foundation.dart';

/// Просьба переключить нижнюю вкладку, поданная из экрана, который не
/// является прямым потомком `HomeShell` в дереве виджетов (например, из
/// полноэкранного поиска, запушенного через корневой `Navigator`).
///
/// `HomeShell` слушает этот контроллер и сам решает, что делать со сменой
/// вкладки — здесь только просьба, а не факт переключения.
class AppNavController extends ChangeNotifier {
  int? _pendingTab;

  void openTab(int index) {
    _pendingTab = index;
    notifyListeners();
  }

  /// Забирает и сбрасывает отложенный запрос. Вызывать один раз на приём.
  int? consumeTab() {
    final tab = _pendingTab;
    _pendingTab = null;
    return tab;
  }
}
