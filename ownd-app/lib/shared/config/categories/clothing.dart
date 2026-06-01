import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> clothingCategories = [
  const CategoryItem(
    name: 'T恤',
    iconPath: 'MdiIcons.tshirtCrew',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '衬衫',
    iconPath: 'MdiIcons.tshirtV',
    color: Colors.lightBlue,
  ),
  const CategoryItem(name: '外套/夹克', iconPath: 'MdiIcons.jacket'), // Adaptive
  const CategoryItem(
    name: '裤子/牛仔裤',
    iconPath: 'MdiIcons.contentCut',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: '裙子',
    iconPath: 'MdiIcons.skirt',
    color: Colors.pink,
  ),
  const CategoryItem(
    name: '内衣/袜子',
    iconPath: 'MdiIcons.shoeHeel',
    color: Colors.pinkAccent,
  ),
  const CategoryItem(
    name: '运动鞋',
    iconPath: 'MdiIcons.shoeSneaker',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '皮鞋/靴子',
    iconPath: 'MdiIcons.shoeFormal',
  ), // Adaptive
  const CategoryItem(
    name: '高跟鞋',
    iconPath: 'MdiIcons.shoeHeel',
    color: Colors.red,
  ),
  const CategoryItem(
    name: '手表 (机械/石英)',
    iconPath: 'MdiIcons.watch',
    color: Colors.blueGrey,
  ),
  const CategoryItem(name: '眼镜/墨镜', iconPath: 'MdiIcons.glasses'), // Adaptive
  const CategoryItem(
    name: '帽子',
    iconPath: 'MdiIcons.hatFedora',
    color: Colors.brown,
  ),
  const CategoryItem(
    name: '戒指/首饰',
    iconPath: 'MdiIcons.ring',
    color: Colors.amber,
  ),
  const CategoryItem(
    name: '项链',
    iconPath: 'MdiIcons.necklace',
    color: Colors.amber,
  ),
  const CategoryItem(
    name: '双肩包',
    iconPath: 'MdiIcons.bagPersonal',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '手提包',
    iconPath: 'MdiIcons.handbag',
    color: Colors.red,
  ),
  const CategoryItem(
    name: '行李箱',
    iconPath: 'MdiIcons.bagSuitcase',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '钱包',
    iconPath: 'MdiIcons.wallet',
    color: Colors.brown,
  ),
];
