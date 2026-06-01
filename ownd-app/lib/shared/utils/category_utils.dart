import 'package:flutter/material.dart';
import '../config/category_config.dart';

class CategoryUtils {
  static Color? getCategoryColor(String? categoryName) {
    return CategoryConfig.getItem(categoryName).color;
  }
}
