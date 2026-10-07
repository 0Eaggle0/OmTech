import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_version.dart';
import '../l10n/app_localizations.dart';
import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Шторка «вышла новая версия». Скачивание идёт прямо в ней: кнопка
/// превращается в полосу прогресса, а не уступает место отдельному диалогу.
class UpdateSheet extends StatefulWidget {
  final AppRelease release;

  const UpdateSheet({super.key, required this.release});

  /// Показывает шторку; если пользователь ушёл без установки — откладываем
  /// следующее напоминание на сутки.
  static Future<void> show(BuildContext context, AppRelease release) async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateSheet(release: release),
    );
    if (started != true) await UpdateService.snooze();
  }

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

enum _Phase { idle, downloading, opening, failed }

class _UpdateSheetState extends State<UpdateSheet> {
  _Phase _phase = _Phase.idle;
  int _received = 0;
  int _total = 0;
  int _failures = 0;

  int get _size => _total > 0 ? _total : widget.release.size;
  double get _progress => _size > 0 ? (_received / _size).clamp(0, 1) : 0;

  Future<void> _start() async {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _phase = _Phase.downloading;
      _received = 0;
    });
    try {
      await UpdateService.downloadAndInstall(
        widget.release,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            if (total > 0) _total = total;
          });
        },
      );
      if (!mounted) return;
      unawaited(HapticFeedback.mediumImpact());
      setState(() => _phase = _Phase.opening);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('[Update] download failed: $e');
      if (!mounted) return;
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _phase = _Phase.failed;
        _failures++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final glass = context.glass;
    final busy = _phase == _Phase.downloading || _phase == _Phase.opening;

    return PopScope(
      canPop: !busy,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(from: kAppVersion, to: widget.release.version),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.updateBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: glass.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                          children: [
                            Expanded(
                              child: _Fact(
                                icon: Icons.south_rounded,
                                value: l.updateSize(_mb(_size)),
                                caption: l.updateSizeCaption,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Fact(
                                icon: Icons.verified_user_outlined,
                                value: l.updateKeeps,
                                caption: l.updateKeepsCaption,
                              ),
                            ),
                          ],
                        )
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 400.ms)
                        .moveY(begin: 10, curve: Curves.easeOutCubic),
                    const SizedBox(height: 20),
                    Animate(
                      key: ValueKey(_failures),
                      effects: _failures > 0
                          ? [
                              ShakeEffect(
                                hz: 5,
                                offset: const Offset(7, 0),
                                duration: 420.ms,
                              ),
                            ]
                          : const [],
                      child: _ProgressButton(
                        phase: _phase,
                        progress: _progress,
                        onTap: busy ? null : _start,
                        idleLabel: _phase == _Phase.failed
                            ? l.retry
                            : l.updateInstall,
                        downloadingLabel: l.updateDownloading,
                        openingLabel: l.updateOpening,
                      ),
                    ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: AnimatedSwitcher(
                        duration: 250.ms,
                        child: switch (_phase) {
                          _Phase.downloading => Center(
                            key: const ValueKey('mb'),
                            child: Text(
                              '${_mb(_received)} / ${l.updateSize(_mb(_size))}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: glass.textFaint,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          _Phase.failed => Center(
                            key: ValueKey('err$_failures'),
                            child: Text(
                              l.updateFailed,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.statusDanger,
                              ),
                            ),
                          ),
                          _Phase.opening => const SizedBox.shrink(),
                          _Phase.idle => TextButton(
                            key: const ValueKey('later'),
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: glass.textMuted,
                            ),
                            child: Text(l.updateLater),
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
}

/// Градиентная шапка: медленно плывущие пятна света и номер версии,
/// у которого изменившиеся цифры прокручиваются, как на счётчике.
class _Header extends StatefulWidget {
  final String from;
  final String to;

  const _Header({required this.from, required this.to});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // «Убрать анимации» в системе — пятна стоят на месте.
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ClipRect(
      child: SizedBox(
        height: 188,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.accentGradient),
            ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (_, _) =>
                    CustomPaint(painter: _AuroraPainter(_drift.value)),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.updateEyebrow.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 4),
                  _RollingVersion(from: widget.from, to: widget.to),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      l.updateCurrent(widget.from),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate(delay: 900.ms).fadeIn(duration: 350.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пятна света поверх градиента. `t` бежит 0→1 по кругу; у каждого пятна
/// своя частота, поэтому рисунок не повторяется заметно.
class _AuroraPainter extends CustomPainter {
  final double t;

  const _AuroraPainter(this.t);

  static const _pink = Color(0xFFEC4899);

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    void blob(double x, double y, double r, Color color) {
      final c = Offset(x * size.width, y * size.height);
      final radius = r * size.height;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }

    blob(
      0.85 + 0.06 * math.sin(a),
      0.15 + 0.10 * math.cos(a),
      1.0,
      Colors.white.withValues(alpha: 0.20),
    );
    blob(
      0.10 + 0.08 * math.cos(2 * a),
      1.0 + 0.08 * math.sin(a),
      0.9,
      _pink.withValues(alpha: 0.35),
    );
    blob(
      0.55 + 0.12 * math.sin(3 * a),
      0.55 + 0.06 * math.cos(2 * a),
      0.7,
      AppColors.statusInfo.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}

/// Номер версии: совпадающие символы стоят, изменившиеся уезжают вверх,
/// а новые въезжают снизу — каждый со своей небольшой задержкой.
class _RollingVersion extends StatelessWidget {
  final String from;
  final String to;

  const _RollingVersion({required this.from, required this.to});

  static const _size = 46.0;
  static const _style = TextStyle(
    color: Colors.white,
    fontSize: _size,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    const travel = _size;
    var changed = 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < to.length; i++)
          if (i < from.length && from[i] == to[i])
            Text(to[i], style: _style)
          else
            ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (i < from.length)
                    Text(from[i], style: _style)
                        .animate(delay: (450 + 110 * changed).ms)
                        .moveY(
                          end: -travel,
                          duration: 520.ms,
                          curve: Curves.easeInOutCubic,
                        )
                        .fadeOut(duration: 520.ms),
                  Text(to[i], style: _style)
                      .animate(delay: (450 + 110 * changed++).ms)
                      .moveY(
                        begin: travel,
                        end: 0,
                        duration: 620.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 300.ms),
                ],
              ),
            ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String value;
  final String caption;

  const _Fact({required this.icon, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: glass.elevatedFill,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: glass.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: glass.accent),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: glass.textFaint),
          ),
        ],
      ),
    );
  }
}

class _ProgressButton extends StatelessWidget {
  final _Phase phase;
  final double progress;
  final VoidCallback? onTap;
  final String idleLabel;
  final String downloadingLabel;
  final String openingLabel;

  const _ProgressButton({
    required this.phase,
    required this.progress,
    required this.onTap,
    required this.idleLabel,
    required this.downloadingLabel,
    required this.openingLabel,
  });

  static const _height = 54.0;
  static const _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final downloading = phase == _Phase.downloading;
    final fill = switch (phase) {
      _Phase.downloading => progress,
      _ => 1.0,
    };
    final shape = BorderRadius.circular(AppRadius.pill);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: glass.glow(AppColors.violet),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: SizedBox(
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Дорожка под полосой; при fill = 1 её не видно.
              ColoredBox(color: AppColors.indigo.withValues(alpha: 0.35)),
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  widthFactor: fill,
                  heightFactor: 1,
                  child: _gradientFill(downloading),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _label(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientFill(bool shimmering) {
    const fill = DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.accentGradient),
    );
    if (!shimmering) return fill;
    return fill
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.28),
        );
  }

  Widget _label() => switch (phase) {
    _Phase.downloading => Padding(
      key: const ValueKey('down'),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Text(downloadingLabel, style: _labelStyle),
          const Spacer(),
          Text('${(progress * 100).round()}%', style: _labelStyle),
        ],
      ),
    ),
    _Phase.opening => Row(
      key: const ValueKey('open'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 22,
        ).animate().scale(
          begin: const Offset(0.3, 0.3),
          curve: Curves.elasticOut,
          duration: 700.ms,
        ),
        const SizedBox(width: 8),
        Text(openingLabel, style: _labelStyle),
      ],
    ),
    _ => Row(
      key: ValueKey(idleLabel),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(idleLabel, style: _labelStyle),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 19),
      ],
    ),
  };
}
