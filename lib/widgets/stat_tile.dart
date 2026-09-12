import 'package:flutter/material.dart';

import '../theme/app_glass.dart';
import '../theme/app_metrics.dart';

/// Одна ячейка сводки: крупное число и подпись под ним.
class StatTile {
  final String value;
  final String caption;
  final Color? accent;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatTile({
    required this.value,
    required this.caption,
    this.accent,
    this.icon,
    this.onTap,
  });
}

/// Ряд равных ячеек сводки («Отлично 4 / Хорошо 2 / Зачтено 3»).
class StatTileRow extends StatelessWidget {
  final List<StatTile> tiles;
  final double spacing;

  const StatTileRow(this.tiles, {super.key, this.spacing = 10});

  @override
  Widget build(BuildContext context) {
    // Без IntrinsicHeight `stretch` превращается в тугое ограничение по
    // высоте, и внутри ListView (неограниченная высота) плитки получают
    // бесконечный размер — весь сливер перестаёт рисоваться.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: _Tile(tiles[i])),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final StatTile tile;

  const _Tile(this.tile);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = context.glass;
    final accent = tile.accent ?? theme.colorScheme.primary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tile.icon != null) ...[
            Icon(tile.icon, size: 18, color: accent),
            const SizedBox(height: 6),
          ],
          Text(
            tile.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: accent),
          ),
          const SizedBox(height: 4),
          Text(
            tile.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: glass.textMuted),
          ),
        ],
      ),
    );

    return Material(
      color: glass.elevatedFill,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: tile.onTap == null
          ? content
          : InkWell(
              onTap: tile.onTap,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              child: content,
            ),
    );
  }
}
