import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlatformModel {
  final String name;
  final IconData icon;
  final Color color;

  const PlatformModel({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class PlatformConfig {
  static List<PlatformModel> get shoppingPlatforms => [
    // --- 综合电商 ---
    PlatformModel(
      name: '淘宝',
      icon: MdiIcons.shopping, // 经典的购物袋
      color: const Color(0xFFFF5000), // 淘宝橙
    ),
    PlatformModel(
      name: '天猫',
      icon: MdiIcons.cat, // 吉祥物：猫
      color: const Color(0xFFFF0036), // 天猫红
    ),
    PlatformModel(
      name: '京东',
      icon: MdiIcons.dog, // 吉祥物：金属狗 Joy
      color: const Color(0xFFE4393C), // 京东红
    ),
    PlatformModel(
      name: '拼多多',
      icon: MdiIcons.accountGroup, // 寓意：拼团/多人
      color: const Color(0xFFE02E24), // 拼多多红
    ),
    PlatformModel(
      name: '抖音电商',
      icon: MdiIcons.musicNote, // 标志性音符
      color: const Color(0xFF1C1C1C), // 抖音黑
    ),
    PlatformModel(
      name: '快手电商',
      icon: MdiIcons.video, // 短视频
      color: const Color(0xFFFF4800), // 快手橙
    ),
    PlatformModel(
      name: '苏宁易购',
      icon: MdiIcons.store,
      color: const Color(0xFFFDBD00),
    ),
    PlatformModel(
      name: '唯品会',
      icon: MdiIcons.tagHeart,
      color: const Color(0xFFF10180),
    ),

    // --- 社区与种草 ---
    PlatformModel(
      name: '小红书',
      icon: MdiIcons.notebook,
      color: const Color(0xFFFF2442),
    ),
    PlatformModel(
      name: '得物',
      icon: MdiIcons.shoeSneaker,
      color: const Color(0xFF000000),
    ),

    // --- 二手交易 ---
    PlatformModel(
      name: '闲鱼',
      icon: MdiIcons.fish,
      color: const Color(0xFFFFDA44),
    ),
    PlatformModel(
      name: '转转',
      icon: MdiIcons.recycle,
      color: const Color(0xFFFF3535),
    ),
    PlatformModel(
      name: '多抓鱼',
      icon: MdiIcons.bookOpenPageVariant,
      color: const Color(0xFF4C4C4C),
    ),

    // --- 本地生活 (外卖/生鲜) ---
    PlatformModel(
      name: '美团',
      icon: MdiIcons.kangaroo,
      color: const Color(0xFFFFC300),
    ),
    PlatformModel(
      name: '饿了么',
      icon: MdiIcons.moped,
      color: const Color(0xFF0085FF),
    ),
    PlatformModel(
      name: '盒马鲜生',
      icon: MdiIcons.cow,
      color: const Color(0xFF00C3F6),
    ),
    PlatformModel(
      name: '叮咚买菜',
      icon: MdiIcons.carrot,
      color: const Color(0xFF32B16C),
    ),
    PlatformModel(
      name: '山姆会员店',
      icon: MdiIcons.cartVariant,
      color: const Color(0xFF0064C8),
    ),

    // --- 国际/数码/其他 ---
    PlatformModel(
      name: 'Apple Store',
      icon: MdiIcons.apple,
      color: const Color(0xFF000000),
    ),
    PlatformModel(
      name: '亚马逊 (Amazon)',
      icon: MdiIcons.shopping,
      color: const Color(0xFFFF9900),
    ),
    PlatformModel(
      name: '宜家 (IKEA)',
      icon: MdiIcons.homeCity,
      color: const Color(0xFF0051BA),
    ),
    PlatformModel(
      name: 'Steam',
      icon: MdiIcons.steam,
      color: const Color(0xFF171A21),
    ),
    PlatformModel(
      name: '网易严选',
      icon: MdiIcons.briefcase,
      color: const Color(0xFFB4A078),
    ),

    // --- 其它 ---
    PlatformModel(
      name: '其它',
      icon: MdiIcons.dotsHorizontal,
      color: Colors.grey,
    ),
  ];
}
