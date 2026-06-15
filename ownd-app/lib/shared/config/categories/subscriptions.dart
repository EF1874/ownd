import 'package:flutter/material.dart';
import '../category_item.dart';

final Map<String, List<String>> subscriptionCategoryGroups = {
  '影视订阅': [
    'Netflix',
    'YouTube Premium',
    'bilibili大会员',
    '爱奇艺',
    '腾讯视频',
    '优酷',
    'Disney+',
  ],
  '音乐音频': ['Spotify', 'Apple Music', 'QQ音乐', '网易云音乐', '喜马拉雅/播客'],
  '云存储与办公': [
    '百度网盘/云存储',
    'Google Drive',
    'iCloud',
    'Office 365',
    'Adobe Creative Cloud',
  ],
  'AI 与效率': [
    'ChatGPT/AI订阅',
    'GitHub Copilot',
    'Notion/知识库',
    '1Password/密码管理',
    'VPN/加速器',
    '效率工具订阅',
  ],
  '交通出行': ['共享单车月卡', '公交/地铁月票', '停车月卡'],
  '生活会员': [
    '健身房会员',
    '运动场馆卡',
    '外卖会员',
    '电商会员',
    '生鲜买菜会员',
    '山姆/Costco会员',
    '咖啡月卡',
    '保险/保单',
  ],
  '通信与网络': ['手机套餐', '宽带/网络套餐', '流量包/eSIM', '域名/云服务器'],
  '学习阅读': ['网课/学习会员', '阅读会员'],
  '游戏会员': ['Steam', 'PlayStation Plus', 'Xbox Game Pass', 'Nintendo Online'],
};

final List<CategoryItem> subscriptionCategories = [
  const CategoryItem(
    name: 'Netflix',
    iconPath: 'MdiIcons.netflix',
    color: Colors.red,
  ),
  const CategoryItem(
    name: 'YouTube Premium',
    iconPath: 'MdiIcons.youtube',
    color: Colors.redAccent,
  ),
  const CategoryItem(
    name: 'bilibili大会员',
    iconPath: 'MdiIcons.televisionClassic',
    color: Colors.pinkAccent,
  ),
  const CategoryItem(
    name: '爱奇艺',
    iconPath: 'MdiIcons.playBox',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '腾讯视频',
    iconPath: 'MdiIcons.video',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '优酷',
    iconPath: 'MdiIcons.youtubeSubscription',
    color: Colors.blueAccent,
  ),
  const CategoryItem(
    name: 'Disney+',
    iconPath: 'MdiIcons.videoVintage',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: 'Spotify',
    iconPath: 'MdiIcons.spotify',
    color: Colors.green,
  ),
  const CategoryItem(
    name: 'Apple Music',
    iconPath: 'MdiIcons.musicCircle',
    color: Colors.red,
  ),
  const CategoryItem(
    name: 'QQ音乐',
    iconPath: 'MdiIcons.musicNote',
    color: Colors.greenAccent,
  ),
  const CategoryItem(
    name: '网易云音乐',
    iconPath: 'MdiIcons.disc',
    color: Colors.redAccent,
  ),
  const CategoryItem(
    name: '喜马拉雅/播客',
    iconPath: 'MdiIcons.microphone',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '百度网盘/云存储',
    iconPath: 'MdiIcons.cloudUpload',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: 'Google Drive',
    iconPath: 'MdiIcons.googleDrive',
    color: Colors.green,
  ),
  const CategoryItem(
    name: 'iCloud',
    iconPath: 'MdiIcons.appleCloud',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: 'Office 365',
    iconPath: 'MdiIcons.microsoftOffice',
    color: Colors.orangeAccent,
  ),
  const CategoryItem(
    name: 'Adobe Creative Cloud',
    iconPath: 'MdiIcons.adobe',
    color: Colors.red,
  ),
  const CategoryItem(
    name: 'ChatGPT/AI订阅',
    iconPath: 'MdiIcons.robot',
    color: Colors.teal,
  ),
  const CategoryItem(
    name: '1Password/密码管理',
    iconPath: 'MdiIcons.shieldKey',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: 'VPN/加速器',
    iconPath: 'MdiIcons.vpn',
    color: Colors.cyan,
  ),
  const CategoryItem(
    name: '共享单车月卡',
    iconPath: 'MdiIcons.bicycle',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '公交/地铁月票',
    iconPath: 'MdiIcons.cardBulleted',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: '停车月卡',
    iconPath: 'MdiIcons.car',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '健身房会员',
    iconPath: 'MdiIcons.dumbbell',
    color: Colors.deepOrange,
  ),
  const CategoryItem(
    name: '运动场馆卡',
    iconPath: 'MdiIcons.basketball',
    color: Colors.orange,
  ),
  const CategoryItem(
    name: '外卖会员',
    iconPath: 'MdiIcons.moped',
    color: Colors.amber,
  ),
  const CategoryItem(
    name: '电商会员',
    iconPath: 'MdiIcons.shopping',
    color: Colors.deepOrangeAccent,
  ),
  const CategoryItem(
    name: '生鲜买菜会员',
    iconPath: 'MdiIcons.carrot',
    color: Colors.lightGreen,
  ),
  const CategoryItem(
    name: '山姆/Costco会员',
    iconPath: 'MdiIcons.cartVariant',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '咖啡月卡',
    iconPath: 'MdiIcons.coffeeMaker',
    color: Colors.brown,
  ),
  const CategoryItem(
    name: '手机套餐',
    iconPath: 'MdiIcons.cellphone',
    color: Colors.teal,
  ),
  const CategoryItem(
    name: '宽带/网络套餐',
    iconPath: 'MdiIcons.routerWireless',
    color: Colors.blueAccent,
  ),
  const CategoryItem(
    name: '流量包/eSIM',
    iconPath: 'MdiIcons.cellphone',
    color: Colors.cyan,
  ),
  const CategoryItem(
    name: '域名/云服务器',
    iconPath: 'MdiIcons.cloudUpload',
    color: Colors.lightBlue,
  ),
  const CategoryItem(
    name: 'GitHub Copilot',
    iconPath: 'MdiIcons.robot',
    color: Colors.black87,
  ),
  const CategoryItem(
    name: 'Notion/知识库',
    iconPath: 'MdiIcons.notebook',
    color: Colors.black54,
  ),
  const CategoryItem(
    name: '网课/学习会员',
    iconPath: 'MdiIcons.bookOpenPageVariant',
    color: Colors.deepPurple,
  ),
  const CategoryItem(
    name: '阅读会员',
    iconPath: 'MdiIcons.book',
    color: Colors.brown,
  ),
  const CategoryItem(
    name: '保险/保单',
    iconPath: 'MdiIcons.shieldKey',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '效率工具订阅',
    iconPath: 'MdiIcons.briefcase',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: 'Steam',
    iconPath: 'MdiIcons.steam',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: 'PlayStation Plus',
    iconPath: 'MdiIcons.sonyPlaystation',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: 'Xbox Game Pass',
    iconPath: 'MdiIcons.microsoftXbox',
    color: Colors.green,
  ),
  const CategoryItem(
    name: 'Nintendo Online',
    iconPath: 'MdiIcons.nintendoSwitch',
    color: Colors.red,
  ),
];
