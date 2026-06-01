import 'package:flutter/material.dart';

class CostConfig {
  static Color? getCostColor(double dailyCost) {
    if (dailyCost > 100) {
      return Colors.red;
    } else if (dailyCost >= 50) {
      return Colors.orange;
    } else if (dailyCost < 10) {
      return Colors.green;
    } else {
      // Normal: 10-50
      return null; // Theme dependent color, handled in widget
    }
  }

  static bool isNormalCost(double dailyCost) {
    return dailyCost >= 10 && dailyCost < 50;
  }
}
