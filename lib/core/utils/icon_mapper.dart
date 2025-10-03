import 'package:flutter/material.dart';

IconData iconForCategory(String? name) {
  switch (name) {
    case 'laptop_mac':
      return Icons.laptop_mac;
    case 'desktop_windows':
      return Icons.desktop_windows;
    case 'videocam':
      return Icons.videocam_outlined;
    case 'memory':
      return Icons.memory_outlined;
    case 'developer_board':
      return Icons.developer_board;
    case 'storage':
      return Icons.storage_outlined;
    case 'keyboard':
      return Icons.keyboard_alt_outlined;
    default:
      return Icons.devices_other;
  }
}
