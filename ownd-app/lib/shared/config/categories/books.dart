import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> booksCategories = [
  const CategoryItem(
    name: '纸质书',
    iconPath: 'MdiIcons.book',
    color: Colors.brown,
  ),
  const CategoryItem(
    name: '杂志',
    iconPath: 'MdiIcons.newspaper',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '黑胶唱片',
    iconPath: 'MdiIcons.album',
  ), // Adaptive (Black)
  const CategoryItem(
    name: 'CD/光盘',
    iconPath: 'MdiIcons.disc',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '游戏卡带',
    iconPath: 'MdiIcons.cartridge',
    color: Colors.red,
  ),
];
