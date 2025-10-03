import 'package:flutter/material.dart';

import '../../domain/models/asset_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final AssetStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: status.chipTextColor,
        ),
      ),
    );
  }
}
