import 'package:flutter/material.dart';

enum ReportCategory {
  brokenStreetlight,
  roadPothole,
  waterProblem,
  illegalDumping,
  electricity,
  drainage,
  damagedPublicProperty,
  other,
}

extension ReportCategoryX on ReportCategory {
  String get key {
    switch (this) {
      case ReportCategory.brokenStreetlight:
        return 'broken_streetlight';
      case ReportCategory.roadPothole:
        return 'road_pothole';
      case ReportCategory.waterProblem:
        return 'water_problem';
      case ReportCategory.illegalDumping:
        return 'illegal_dumping';
      case ReportCategory.electricity:
        return 'electricity';
      case ReportCategory.drainage:
        return 'drainage';
      case ReportCategory.damagedPublicProperty:
        return 'damaged_public_property';
      case ReportCategory.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ReportCategory.brokenStreetlight:
        return 'Broken Streetlight';
      case ReportCategory.roadPothole:
        return 'Road / Pothole';
      case ReportCategory.waterProblem:
        return 'Water Problem';
      case ReportCategory.illegalDumping:
        return 'Illegal Dumping';
      case ReportCategory.electricity:
        return 'Electricity';
      case ReportCategory.drainage:
        return 'Drainage';
      case ReportCategory.damagedPublicProperty:
        return 'Damaged Public Property';
      case ReportCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.brokenStreetlight:
        return Icons.lightbulb_outline;
      case ReportCategory.roadPothole:
        return Icons.add_road;
      case ReportCategory.waterProblem:
        return Icons.water_drop_outlined;
      case ReportCategory.illegalDumping:
        return Icons.delete_outline;
      case ReportCategory.electricity:
        return Icons.bolt;
      case ReportCategory.drainage:
        return Icons.water;
      case ReportCategory.damagedPublicProperty:
        return Icons.apartment;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }

  static ReportCategory fromKey(String? key) {
    if (key == null || key.isEmpty) return ReportCategory.other;
    return ReportCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => ReportCategory.other,
    );
  }
}