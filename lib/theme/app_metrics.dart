import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Радиусы скруглений. Один набор на всё приложение.
class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double tile = 16;
  static const double pill = 999;
  static const double sheet = 28;
}

/// Высота содержимого плавающей нижней панели, без отступов и системной зоны.
const double kFloatingNavHeight = 62;

/// Нижний отступ для скроллящегося содержимого вкладки, чтобы последний
/// элемент не оказался под плавающей панелью.
///
/// Работает только при `extendBody: true` на `Scaffold`: тогда Flutter кладёт
/// высоту нижней панели в `MediaQuery.padding.bottom` тела. Вызывать нужно
/// из `build` самого экрана — то есть **над** любым `SafeArea(bottom: true)`,
/// иначе тот уже съест этот отступ.
double navBottomPadding(BuildContext context, {double extra = 16}) =>
    MediaQuery.paddingOf(context).bottom + extra;

/// Включать ли настоящее размытие под стеклянными поверхностями.
///
/// `BackdropFilter` поверх скроллящегося списка — это `saveLayer` плюс
/// размытие на каждом кадре. На Impeller (iOS) это дёшево, на массовом
/// Android — нет, поэтому там рисуем почти непрозрачную заливку: на тёмном
/// фоне разница незаметна.
bool get glassBlurEnabled => defaultTargetPlatform == TargetPlatform.iOS;
