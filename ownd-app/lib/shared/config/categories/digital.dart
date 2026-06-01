import 'package:flutter/material.dart';
import '../category_item.dart';

final List<CategoryItem> digitalCategories = [
  const CategoryItem(
    name: '手机',
    iconPath: 'MdiIcons.cellphone',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '平板电脑',
    iconPath: 'MdiIcons.tablet',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '笔记本电脑',
    iconPath: 'MdiIcons.laptop',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '台式主机',
    iconPath: 'MdiIcons.desktopTower',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '智能手表',
    iconPath: 'MdiIcons.watchVariant',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '电子书/Kindle',
    iconPath: 'MdiIcons.bookOpenPageVariant',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '主板',
    iconPath: 'MdiIcons.motherboard',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '显卡 (GPU)',
    iconPath: 'MdiIcons.expansionCard',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '处理器 (CPU)',
    iconPath: 'MdiIcons.cpu64Bit',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '内存条 (RAM)',
    iconPath: 'MdiIcons.memory',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '机械硬盘 (HDD)',
    iconPath: 'MdiIcons.harddisk',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '固态硬盘 (SSD)',
    iconPath: 'MdiIcons.nas',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '电源',
    iconPath: 'MdiIcons.powerSupply',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '机箱风扇',
    iconPath: 'MdiIcons.fan',
    color: Colors.indigo,
  ),
  const CategoryItem(
    name: '显示器',
    iconPath: 'MdiIcons.monitor',
    color: Colors.blueAccent,
  ),
  const CategoryItem(
    name: '机械键盘',
    iconPath: 'MdiIcons.keyboardVariant',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: '鼠标',
    iconPath: 'MdiIcons.mouse',
    color: Colors.blueGrey,
  ),
  const CategoryItem(
    name: '头戴式耳机',
    iconPath: 'MdiIcons.headphones',
    color: Colors.teal,
  ),
  const CategoryItem(
    name: '入耳式耳机/AirPods',
    iconPath: 'MdiIcons.earbuds',
    color: Colors.teal,
  ),
  const CategoryItem(
    name: '充电头',
    iconPath: 'MdiIcons.powerPlug',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '数据线',
    iconPath: 'MdiIcons.usbCable',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '充电宝',
    iconPath: 'MdiIcons.batteryCharging100',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: 'U盘/SD卡',
    iconPath: 'MdiIcons.usbFlashDrive',
    color: Colors.grey,
  ),
  const CategoryItem(
    name: '路由器',
    iconPath: 'MdiIcons.routerWireless',
    color: Colors.cyan,
  ),
  const CategoryItem(
    name: '相机',
    iconPath: 'MdiIcons.camera',
    color: Colors.brown,
  ),
  const CategoryItem(
    name: '无人机',
    iconPath: 'MdiIcons.quadcopter',
    color: Colors.brown,
  ),
  // --- 核心拍摄主机 ---
  const CategoryItem(
    name: '运动相机 (GoPro)',
    iconPath: 'MdiIcons.cameraGopro',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '全景相机 (360)',
    iconPath: 'MdiIcons.cameraIris',
    color: Colors.purple,
  ),
  const CategoryItem(
    name: '云台相机 (Pocket)',
    iconPath: 'MdiIcons.camcorder',
    color: Colors.orange,
  ),
  // 无人机 skipped (exists)
  const CategoryItem(
    name: '微单/Vlog相机',
    iconPath: 'MdiIcons.camera',
    color: Colors.teal, // Changed from Black87
  ),
  const CategoryItem(
    name: 'CCD相机',
    iconPath: 'MdiIcons.cameraPartyMode',
    color: Colors.pink,
  ),

  // --- 稳定与支撑 ---
  const CategoryItem(
    name: '手机云台/稳定器',
    iconPath: 'MdiIcons.videoStabilization',
    color: Colors.blueGrey, // Improved visibility
  ),
  const CategoryItem(
    name: '三脚架',
    iconPath: 'MdiIcons.tripod',
    color: Colors.indigo, // Changed from Black54
  ),
  const CategoryItem(
    name: '自拍杆',
    iconPath: 'MdiIcons.stick', // or armFlex
    color: Colors.lightBlue, // Changed from Grey
  ),

  // --- 音频收录 ---
  const CategoryItem(
    name: '无线麦克风 (小蜜蜂)',
    iconPath: 'MdiIcons.microphoneMessage',
    color: Colors.deepOrange, // Changed from Black
  ),
  const CategoryItem(
    name: '枪式麦克风',
    iconPath: 'MdiIcons.microphoneVariant',
    color: Colors.blueGrey, // Improved visibility
  ),
  const CategoryItem(
    name: '录音笔',
    iconPath: 'MdiIcons.soundRecording',
    color: Colors.cyan, // Changed from BlueGrey
  ),

  // --- 灯光与配件 ---
  const CategoryItem(
    name: '补光灯',
    iconPath: 'MdiIcons.whiteBalanceSunny',
    color: Colors.amber,
  ),
  const CategoryItem(
    name: '环形灯',
    iconPath: 'MdiIcons.circleOutline',
    color: Colors.amberAccent,
  ),
  const CategoryItem(
    name: '相机电池',
    iconPath: 'MdiIcons.batteryHigh',
    color: Colors.green,
  ),
  const CategoryItem(
    name: '存储卡/SD卡',
    iconPath: 'MdiIcons.sd',
    color: Colors.blue,
  ),
  const CategoryItem(
    name: '读卡器',
    iconPath: 'MdiIcons.expansionCardVariant',
    color: Colors.deepPurple, // Changed from Grey
  ),
  const CategoryItem(
    name: '相机包',
    iconPath: 'MdiIcons.bagPersonal',
    color: Colors.brown,
  ),
];
