import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> healthCategories = [
  const CategoryItem(name: '常备药', iconPath: 'MdiIcons.pill', color: Colors.red),
  const CategoryItem(
    name: '体温计',
    iconPath: 'MdiIcons.thermometer',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '创可贴/急救包',
    iconPath: 'MdiIcons.bandAid',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '口罩',
    iconPath: 'MdiIcons.faceMask',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '保健品',
    iconPath: 'MdiIcons.bottleTonicPlus',
    color: Colors.green,
  ),
];
