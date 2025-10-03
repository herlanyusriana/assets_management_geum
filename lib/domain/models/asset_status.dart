import 'package:flutter/material.dart';

enum AssetStatus {
  all,
  available,
  assigned,
  maintenance,
  retired,
  active,
  needsCheck,
  damaged,
}

extension AssetStatusLabel on AssetStatus {
  String get label {
    switch (this) {
      case AssetStatus.available:
        return 'Available';
      case AssetStatus.assigned:
        return 'Assigned';
      case AssetStatus.maintenance:
        return 'Maintenance';
      case AssetStatus.retired:
        return 'Retired';
      case AssetStatus.active:
        return 'Active';
      case AssetStatus.needsCheck:
        return 'Needs Check';
      case AssetStatus.damaged:
        return 'Damaged';
      case AssetStatus.all:
        return 'All';
    }
  }

  Color get chipColor {
    switch (this) {
      case AssetStatus.available:
        return const Color(0xFFE9F5EE);
      case AssetStatus.assigned:
        return const Color(0xFFE9F1FF);
      case AssetStatus.maintenance:
        return const Color(0xFFFFF4E5);
      case AssetStatus.retired:
        return const Color(0xFFF3F4F6);
      case AssetStatus.active:
        return const Color(0xFFE7F3FF);
      case AssetStatus.needsCheck:
        return const Color(0xFFFFF6EB);
      case AssetStatus.damaged:
        return const Color(0xFFFFE9E9);
      case AssetStatus.all:
        return const Color(0xFFE9ECEF);
    }
  }

  Color get chipTextColor {
    switch (this) {
      case AssetStatus.available:
        return const Color(0xFF1B7A3F);
      case AssetStatus.assigned:
        return const Color(0xFF2F54B0);
      case AssetStatus.maintenance:
        return const Color(0xFFB55E00);
      case AssetStatus.retired:
        return const Color(0xFF6B7280);
      case AssetStatus.active:
        return const Color(0xFF1B7A3F);
      case AssetStatus.needsCheck:
        return const Color(0xFFB55E00);
      case AssetStatus.damaged:
        return const Color(0xFFB42318);
      case AssetStatus.all:
        return const Color(0xFF495057);
    }
  }
}

extension AssetStatusApi on AssetStatus {
  String get apiValue {
    switch (this) {
      case AssetStatus.available:
        return 'available';
      case AssetStatus.assigned:
        return 'assigned';
      case AssetStatus.maintenance:
        return 'maintenance';
      case AssetStatus.retired:
        return 'retired';
      case AssetStatus.active:
        return 'active';
      case AssetStatus.needsCheck:
        return 'needs_check';
      case AssetStatus.damaged:
        return 'damaged';
      case AssetStatus.all:
        return 'all';
    }
  }

  static AssetStatus fromApi(String? status) {
    switch (status) {
      case 'available':
        return AssetStatus.available;
      case 'assigned':
        return AssetStatus.assigned;
      case 'maintenance':
        return AssetStatus.maintenance;
      case 'retired':
        return AssetStatus.retired;
      case 'active':
        return AssetStatus.active;
      case 'needs_check':
      case 'needs-check':
        return AssetStatus.needsCheck;
      case 'damaged':
        return AssetStatus.damaged;
      default:
        return AssetStatus.available;
    }
  }
}
