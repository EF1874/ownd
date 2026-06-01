import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> sportsCategories = [
  const CategoryItem(
    name: '自行车',
    iconPath: 'MdiIcons.bicycle',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '滑板',
    iconPath: 'MdiIcons.skateboard',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '哑铃/健身',
    iconPath: 'MdiIcons.dumbbell',
    color: Colors.grey,
  ),
  const CategoryItem(name: '跑步机', iconPath: 'MdiIcons.run'), // Adaptive (Black)
  const CategoryItem(
    name: '瑜伽垫',
    iconPath: 'MdiIcons.yoga',
    color: Colors.purple,
  ),
  const CategoryItem(
    name: '帐篷 (露营)',
    iconPath: 'MdiIcons.tent',
    color: Colors.greenAccent,
  ),
  const CategoryItem(
    name: '钓鱼竿',
    iconPath: 'MdiIcons.fish',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '篮球',
    iconPath: 'MdiIcons.basketball',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '足球',
    iconPath: 'MdiIcons.soccer',
  ), // Adaptive (White)
  const CategoryItem(
    name: '网球/羽毛球拍',
    iconPath: 'MdiIcons.tennis',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '台球',
    iconPath: 'MdiIcons.billiards',
    color: Colors.green,
  ),
];
