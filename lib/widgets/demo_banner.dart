import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Плашка-предупреждение о демонстрационных данных.
class DemoBanner extends StatelessWidget {
  final String text;
  const DemoBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
