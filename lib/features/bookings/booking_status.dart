import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Real statuses available at the BE. `confirmed` is intentionally excluded —
/// the BE never emits it, so filtering on it would never match.
const bookingStatusFilters = <String>[
  'pending',
  'picked_up',
  'returned',
  'cancelled',
];

const bookingStatusLabel = <String, String>{
  'pending': 'In attesa',
  'confirmed': 'Confermata',
  'picked_up': 'Ritirata',
  'returned': 'Restituita',
  'damaged': 'Danneggiata',
  'cancelled': 'Annullata',
  'missing': 'Smarrita',
};

Color bookingStatusColor(String status) {
  switch (status) {
    case 'pending':
      return AppTheme.amber;
    case 'picked_up':
    case 'confirmed':
      return AppTheme.fg;
    case 'returned':
      return AppTheme.muted;
    case 'damaged':
    case 'cancelled':
    case 'missing':
      return AppTheme.destructive;
    default:
      return AppTheme.muted;
  }
}

String labelFor(String status) => bookingStatusLabel[status] ?? status;
