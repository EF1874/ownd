import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error('DATABASE_URL 未定义，请检查 .env.development。');
}

const pool = new Pool({ connectionString: databaseUrl });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

type CategorySeed = {
  name: string;
  icon: string;
  children: { name: string; icon: string }[];
};

type PlatformSeed = {
  name: string;
  icon: string;
  color: string;
};

const categories: CategorySeed[] = [
  {
    name: '虚拟订阅',
    icon: 'MdiIcons.youtubeSubscription',
    children: [
      { name: 'Netflix', icon: 'MdiIcons.netflix' },
      { name: 'YouTube Premium', icon: 'MdiIcons.youtube' },
      { name: 'bilibili大会员', icon: 'MdiIcons.televisionClassic' },
      { name: '爱奇艺', icon: 'MdiIcons.playBox' },
      { name: '腾讯视频', icon: 'MdiIcons.video' },
      { name: '优酷', icon: 'MdiIcons.youtubeSubscription' },
      { name: 'Disney+', icon: 'MdiIcons.videoVintage' },
      { name: 'Spotify', icon: 'MdiIcons.spotify' },
      { name: 'Apple Music', icon: 'MdiIcons.musicCircle' },
      { name: 'QQ音乐', icon: 'MdiIcons.musicNote' },
      { name: '网易云音乐', icon: 'MdiIcons.disc' },
      { name: '喜马拉雅/播客', icon: 'MdiIcons.microphone' },
      { name: '百度网盘/云存储', icon: 'MdiIcons.cloudUpload' },
      { name: 'Google Drive', icon: 'MdiIcons.googleDrive' },
      { name: 'iCloud', icon: 'MdiIcons.appleCloud' },
      { name: 'Office 365', icon: 'MdiIcons.microsoftOffice' },
      { name: 'Adobe Creative Cloud', icon: 'MdiIcons.adobe' },
      { name: 'ChatGPT/AI订阅', icon: 'MdiIcons.robot' },
      { name: '1Password/密码管理', icon: 'MdiIcons.shieldKey' },
      { name: 'VPN/加速器', icon: 'MdiIcons.vpn' },
      { name: '共享单车月卡', icon: 'MdiIcons.bicycle' },
      { name: '公交/地铁月票', icon: 'MdiIcons.cardBulleted' },
      { name: '停车月卡', icon: 'MdiIcons.car' },
      { name: '健身房会员', icon: 'MdiIcons.dumbbell' },
      { name: '运动场馆卡', icon: 'MdiIcons.basketball' },
      { name: '外卖会员', icon: 'MdiIcons.moped' },
      { name: '电商会员', icon: 'MdiIcons.shopping' },
      { name: '生鲜买菜会员', icon: 'MdiIcons.carrot' },
      { name: '山姆/Costco会员', icon: 'MdiIcons.cartVariant' },
      { name: '咖啡月卡', icon: 'MdiIcons.coffeeMaker' },
      { name: '手机套餐', icon: 'MdiIcons.cellphone' },
      { name: '宽带/网络套餐', icon: 'MdiIcons.routerWireless' },
      { name: '流量包/eSIM', icon: 'MdiIcons.cellphone' },
      { name: '域名/云服务器', icon: 'MdiIcons.cloudUpload' },
      { name: 'GitHub Copilot', icon: 'MdiIcons.robot' },
      { name: 'Notion/知识库', icon: 'MdiIcons.notebook' },
      { name: '网课/学习会员', icon: 'MdiIcons.bookOpenPageVariant' },
      { name: '阅读会员', icon: 'MdiIcons.book' },
      { name: '保险/保单', icon: 'MdiIcons.shieldKey' },
      { name: '效率工具订阅', icon: 'MdiIcons.briefcase' },
      { name: 'Steam', icon: 'MdiIcons.steam' },
      { name: 'PlayStation Plus', icon: 'MdiIcons.sonyPlaystation' },
      { name: 'Xbox Game Pass', icon: 'MdiIcons.microsoftXbox' },
      { name: 'Nintendo Online', icon: 'MdiIcons.nintendoSwitch' },
    ],
  },
  {
    name: '数码电子',
    icon: 'MdiIcons.cellphone',
    children: [
      { name: '手机', icon: 'MdiIcons.cellphone' },
      { name: '平板电脑', icon: 'MdiIcons.tablet' },
      { name: '笔记本电脑', icon: 'MdiIcons.laptop' },
      { name: '台式主机', icon: 'MdiIcons.desktopTower' },
      { name: '智能手表', icon: 'MdiIcons.watchVariant' },
      { name: '电子书/Kindle', icon: 'MdiIcons.bookOpenPageVariant' },
      { name: '主板', icon: 'MdiIcons.motherboard' },
      { name: '显卡 (GPU)', icon: 'MdiIcons.expansionCard' },
      { name: '处理器 (CPU)', icon: 'MdiIcons.cpu64Bit' },
      { name: '内存条 (RAM)', icon: 'MdiIcons.memory' },
      { name: '机械硬盘 (HDD)', icon: 'MdiIcons.harddisk' },
      { name: '固态硬盘 (SSD)', icon: 'MdiIcons.nas' },
      { name: '电源', icon: 'MdiIcons.powerSupply' },
      { name: '机箱风扇', icon: 'MdiIcons.fan' },
      { name: '显示器', icon: 'MdiIcons.monitor' },
      { name: '机械键盘', icon: 'MdiIcons.keyboardVariant' },
      { name: '鼠标', icon: 'MdiIcons.mouse' },
      { name: '头戴式耳机', icon: 'MdiIcons.headphones' },
      { name: '入耳式耳机/AirPods', icon: 'MdiIcons.earbuds' },
      { name: '充电头', icon: 'MdiIcons.powerPlug' },
      { name: '数据线', icon: 'MdiIcons.usbCable' },
      { name: '充电宝', icon: 'MdiIcons.batteryCharging100' },
      { name: 'U盘/SD卡', icon: 'MdiIcons.usbFlashDrive' },
      { name: '路由器', icon: 'MdiIcons.routerWireless' },
      { name: '相机', icon: 'MdiIcons.camera' },
      { name: '无人机', icon: 'MdiIcons.quadcopter' },
      { name: '运动相机 (GoPro)', icon: 'MdiIcons.cameraGopro' },
      { name: '全景相机 (360)', icon: 'MdiIcons.cameraIris' },
      { name: '云台相机 (Pocket)', icon: 'MdiIcons.camcorder' },
      { name: '微单/Vlog相机', icon: 'MdiIcons.camera' },
      { name: 'CCD相机', icon: 'MdiIcons.cameraPartyMode' },
      { name: '手机云台/稳定器', icon: 'MdiIcons.videoStabilization' },
      { name: '三脚架', icon: 'MdiIcons.tripod' },
      { name: '自拍杆', icon: 'MdiIcons.stick' },
      { name: '无线麦克风 (小蜜蜂)', icon: 'MdiIcons.microphoneMessage' },
      { name: '枪式麦克风', icon: 'MdiIcons.microphoneVariant' },
      { name: '录音笔', icon: 'MdiIcons.soundRecording' },
      { name: '补光灯', icon: 'MdiIcons.whiteBalanceSunny' },
      { name: '环形灯', icon: 'MdiIcons.circleOutline' },
      { name: '相机电池', icon: 'MdiIcons.batteryHigh' },
      { name: '存储卡/SD卡', icon: 'MdiIcons.sd' },
      { name: '读卡器', icon: 'MdiIcons.expansionCardVariant' },
      { name: '相机包', icon: 'MdiIcons.bagPersonal' },
    ],
  },
  {
    name: '家用电器',
    icon: 'MdiIcons.washingMachine',
    children: [
      { name: '冰箱', icon: 'MdiIcons.fridge' },
      { name: '洗衣机', icon: 'MdiIcons.washingMachine' },
      { name: '空调', icon: 'MdiIcons.airConditioner' },
      { name: '电视机', icon: 'MdiIcons.television' },
      { name: '投影仪', icon: 'MdiIcons.projector' },
      { name: '微波炉', icon: 'MdiIcons.microwave' },
      { name: '烤箱', icon: 'MdiIcons.toasterOven' },
      { name: '空气炸锅', icon: 'MdiIcons.potSteam' },
      { name: '电饭煲', icon: 'MdiIcons.rice' },
      { name: '咖啡机', icon: 'MdiIcons.coffeeMaker' },
      { name: '烧水壶', icon: 'MdiIcons.kettle' },
      { name: '洗碗机', icon: 'MdiIcons.dishwasher' },
      { name: '扫地机器人', icon: 'MdiIcons.robotVacuum' },
      { name: '吸尘器', icon: 'MdiIcons.vacuum' },
      { name: '吹风机', icon: 'MdiIcons.hairDryer' },
      { name: '风扇', icon: 'MdiIcons.fan' },
      { name: '加湿器', icon: 'MdiIcons.airHumidifier' },
      { name: '智能灯泡', icon: 'MdiIcons.lightbulbSmart' },
      { name: '热水器', icon: 'MdiIcons.waterBoiler' },
    ],
  },
  {
    name: '家具家装',
    icon: 'MdiIcons.sofa',
    children: [
      { name: '沙发', icon: 'MdiIcons.sofa' },
      { name: '床', icon: 'MdiIcons.bed' },
      { name: '床垫', icon: 'MdiIcons.bedEmpty' },
      { name: '椅子/电竞椅', icon: 'MdiIcons.chairRolling' },
      { name: '桌子', icon: 'MdiIcons.tableFurniture' },
      { name: '书桌/工作台', icon: 'MdiIcons.desk' },
      { name: '衣柜', icon: 'MdiIcons.wardrobe' },
      { name: '书架', icon: 'MdiIcons.bookshelf' },
      { name: '台灯/落地灯', icon: 'MdiIcons.lamp' },
      { name: '窗帘', icon: 'MdiIcons.curtains' },
      { name: '地毯', icon: 'MdiIcons.rug' },
    ],
  },
  {
    name: '服饰鞋包',
    icon: 'MdiIcons.tshirtCrew',
    children: [
      { name: 'T恤', icon: 'MdiIcons.tshirtCrew' },
      { name: '衬衫', icon: 'MdiIcons.tshirtV' },
      { name: '外套/夹克', icon: 'MdiIcons.jacket' },
      { name: '裤子/牛仔裤', icon: 'MdiIcons.contentCut' },
      { name: '裙子', icon: 'MdiIcons.skirt' },
      { name: '内衣/袜子', icon: 'MdiIcons.shoeHeel' },
      { name: '运动鞋', icon: 'MdiIcons.shoeSneaker' },
      { name: '皮鞋/靴子', icon: 'MdiIcons.shoeFormal' },
      { name: '高跟鞋', icon: 'MdiIcons.shoeHeel' },
      { name: '手表 (机械/石英)', icon: 'MdiIcons.watch' },
      { name: '眼镜/墨镜', icon: 'MdiIcons.glasses' },
      { name: '帽子', icon: 'MdiIcons.hatFedora' },
      { name: '戒指/首饰', icon: 'MdiIcons.ring' },
      { name: '项链', icon: 'MdiIcons.necklace' },
      { name: '双肩包', icon: 'MdiIcons.bagPersonal' },
      { name: '手提包', icon: 'MdiIcons.handbag' },
      { name: '行李箱', icon: 'MdiIcons.bagSuitcase' },
      { name: '钱包', icon: 'MdiIcons.wallet' },
    ],
  },
  {
    name: '个护美妆',
    icon: 'MdiIcons.lipstick',
    children: [
      { name: '口红', icon: 'MdiIcons.lipstick' },
      { name: '香水', icon: 'MdiIcons.bottleTonic' },
      { name: '护肤品/乳液', icon: 'MdiIcons.bottleTonicPlus' },
      { name: '化妆刷/工具', icon: 'MdiIcons.brush' },
      { name: '电动牙刷', icon: 'MdiIcons.toothbrushElectric' },
      { name: '剃须刀', icon: 'MdiIcons.razorSingleEdge' },
      { name: '防晒霜', icon: 'MdiIcons.weatherSunny' },
      { name: '梳子', icon: 'MdiIcons.hairbrush' },
    ],
  },
  {
    name: '户外运动',
    icon: 'MdiIcons.basketball',
    children: [
      { name: '自行车', icon: 'MdiIcons.bicycle' },
      { name: '滑板', icon: 'MdiIcons.skateboard' },
      { name: '哑铃/健身', icon: 'MdiIcons.dumbbell' },
      { name: '跑步机', icon: 'MdiIcons.run' },
      { name: '瑜伽垫', icon: 'MdiIcons.yoga' },
      { name: '帐篷 (露营)', icon: 'MdiIcons.tent' },
      { name: '钓鱼竿', icon: 'MdiIcons.fish' },
      { name: '篮球', icon: 'MdiIcons.basketball' },
      { name: '足球', icon: 'MdiIcons.soccer' },
      { name: '网球/羽毛球拍', icon: 'MdiIcons.tennis' },
      { name: '台球', icon: 'MdiIcons.billiards' },
    ],
  },
  {
    name: '出行交通',
    icon: 'MdiIcons.car',
    children: [
      { name: '轿车', icon: 'MdiIcons.car' },
      { name: '摩托车', icon: 'MdiIcons.motorbike' },
      { name: '电动车/小电驴', icon: 'MdiIcons.moped' },
      { name: '车钥匙', icon: 'MdiIcons.carKey' },
      { name: '交通卡/地铁卡', icon: 'MdiIcons.cardBulleted' },
      { name: '行车记录仪', icon: 'MdiIcons.webcam' },
      { name: 'ETC设备', icon: 'MdiIcons.creditCardWireless' },
      { name: '车载手机支架', icon: 'MdiIcons.cellphoneDock' },
      { name: '车载充电器', icon: 'MdiIcons.carBattery' },
      { name: '充气泵', icon: 'MdiIcons.airFilter' },
      { name: '安全座椅', icon: 'MdiIcons.seatPassenger' },
    ],
  },
  {
    name: '书籍影音',
    icon: 'MdiIcons.bookOpenPageVariant',
    children: [
      { name: '纸质书', icon: 'MdiIcons.book' },
      { name: '杂志', icon: 'MdiIcons.newspaper' },
      { name: '黑胶唱片', icon: 'MdiIcons.album' },
      { name: 'CD/光盘', icon: 'MdiIcons.disc' },
      { name: '游戏卡带', icon: 'MdiIcons.cartridge' },
    ],
  },
  {
    name: '娱乐游戏',
    icon: 'MdiIcons.controller',
    children: [
      { name: 'Switch游戏', icon: 'MdiIcons.nintendoSwitch' },
      { name: 'PS5/PS4游戏', icon: 'MdiIcons.sonyPlaystation' },
      { name: 'Xbox游戏', icon: 'MdiIcons.microsoftXbox' },
      { name: 'Steam/PC游戏', icon: 'MdiIcons.steam' },
      { name: '手游/氪金', icon: 'MdiIcons.cellphonegame' },
      { name: 'VR游戏', icon: 'MdiIcons.virtualReality' },
      { name: '掌机/复古', icon: 'MdiIcons.gameboy' },
      { name: '街机游戏', icon: 'MdiIcons.pacMan' },
      { name: '游戏手柄', icon: 'MdiIcons.gamepadVariant' },
      { name: '电竞外设', icon: 'MdiIcons.headsetDock' },
      { name: '桌游', icon: 'MdiIcons.diceMultiple' },
      { name: '剧本杀', icon: 'MdiIcons.fileFind' },
      { name: '密室逃脱', icon: 'MdiIcons.doorOpen' },
      { name: '麻将', icon: 'MdiIcons.domino' },
      { name: '扑克/德州', icon: 'MdiIcons.cards' },
      { name: '象棋/围棋', icon: 'MdiIcons.chessKnight' },
      { name: 'DND/跑团', icon: 'MdiIcons.bookOpenVariant' },
      { name: '电影/影院', icon: 'MdiIcons.popcorn' },
      { name: 'KTV/唱歌', icon: 'MdiIcons.microphoneVariant' },
      { name: '演唱会/Live', icon: 'MdiIcons.ticketConfirmation' },
      { name: '游乐园/主题乐园', icon: 'MdiIcons.ferrisWheel' },
      { name: '乐高/积木', icon: 'MdiIcons.toyBrick' },
      { name: '盲盒/扭蛋', icon: 'MdiIcons.giftOutline' },
      { name: '手办/模型', icon: 'MdiIcons.robot' },
      { name: '抓娃娃', icon: 'MdiIcons.hook' },
      { name: '网吧/电竞馆', icon: 'MdiIcons.desktopClassic' },
    ],
  },
  {
    name: '医疗健康',
    icon: 'MdiIcons.medicalBag',
    children: [
      { name: '常备药', icon: 'MdiIcons.pill' },
      { name: '体温计', icon: 'MdiIcons.thermometer' },
      { name: '创可贴/急救包', icon: 'MdiIcons.bandAid' },
      { name: '口罩', icon: 'MdiIcons.faceMask' },
      { name: '保健品', icon: 'MdiIcons.bottleTonicPlus' },
    ],
  },
];

const platforms: PlatformSeed[] = [
  { name: '淘宝', icon: 'MdiIcons.shopping', color: '#FF5000' },
  { name: '天猫', icon: 'MdiIcons.cat', color: '#FF0036' },
  { name: '京东', icon: 'MdiIcons.dog', color: '#E4393C' },
  { name: '拼多多', icon: 'MdiIcons.accountGroup', color: '#E02E24' },
  { name: '抖音', icon: 'MdiIcons.musicNote', color: '#1C1C1C' },
  { name: '快手电商', icon: 'MdiIcons.video', color: '#FF4800' },
  { name: '苏宁易购', icon: 'MdiIcons.store', color: '#FDBD00' },
  { name: '唯品会', icon: 'MdiIcons.tagHeart', color: '#F10180' },
  { name: '小红书', icon: 'MdiIcons.notebook', color: '#FF2442' },
  { name: '得物', icon: 'MdiIcons.shoeSneaker', color: '#000000' },
  { name: '闲鱼', icon: 'MdiIcons.fish', color: '#FFDA44' },
  { name: '转转', icon: 'MdiIcons.recycle', color: '#FF3535' },
  { name: '多抓鱼', icon: 'MdiIcons.bookOpenPageVariant', color: '#4C4C4C' },
  { name: '美团', icon: 'MdiIcons.kangaroo', color: '#FFC300' },
  { name: '饿了么', icon: 'MdiIcons.moped', color: '#0085FF' },
  { name: '盒马鲜生', icon: 'MdiIcons.cow', color: '#00C3F6' },
  { name: '叮咚买菜', icon: 'MdiIcons.carrot', color: '#32B16C' },
  { name: '山姆会员店', icon: 'MdiIcons.cartVariant', color: '#0064C8' },
  { name: 'Apple Store', icon: 'MdiIcons.apple', color: '#000000' },
  { name: '亚马逊 (Amazon)', icon: 'MdiIcons.shopping', color: '#FF9900' },
  { name: '宜家 (IKEA)', icon: 'MdiIcons.homeCity', color: '#0051BA' },
  { name: 'Steam', icon: 'MdiIcons.steam', color: '#171A21' },
  { name: '网易严选', icon: 'MdiIcons.briefcase', color: '#B4A078' },
  { name: '其它', icon: 'MdiIcons.dotsHorizontal', color: '#9E9E9E' },
];

const ensureSystemCategory = async (
  name: string,
  icon: string,
  parentId: string | null,
) => {
  const existing = await prisma.category.findFirst({
    where: { name, parentId, userId: null },
  });

  if (existing) {
    return prisma.category.update({
      where: { id: existing.id },
      data: { icon },
    });
  }

  return prisma.category.create({
    data: { name, icon, parentId, userId: null },
  });
};

const seedCategories = async () => {
  for (const category of categories) {
    const parent = await ensureSystemCategory(
      category.name,
      category.icon,
      null,
    );

    for (const child of [
      ...category.children,
      { name: '其它', icon: 'MdiIcons.dotsHorizontal' },
    ]) {
      await ensureSystemCategory(child.name, child.icon, parent.id);
    }
  }
};

const seedPlatforms = async () => {
  for (const platform of platforms) {
    const existing = await prisma.platform.findFirst({
      where: { name: platform.name, userId: null },
    });

    if (existing) {
      await prisma.platform.update({
        where: { id: existing.id },
        data: { icon: platform.icon, color: platform.color },
      });
      continue;
    }

    await prisma.platform.create({
      data: { ...platform, userId: null },
    });
  }
};

const main = async () => {
  await seedCategories();
  await seedPlatforms();
};

main()
  .then(async () => {
    await prisma.$disconnect();
    await pool.end();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    await pool.end();
    process.exit(1);
  });
