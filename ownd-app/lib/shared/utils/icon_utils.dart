import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class IconUtils {
  static final Map<String, IconData> _mdiMap = {
    // 1. Digital & Electronics
    'MdiIcons.cellphone': MdiIcons.cellphone,
    'MdiIcons.tablet': MdiIcons.tablet,
    'MdiIcons.laptop': MdiIcons.laptop,
    'MdiIcons.desktopTower': MdiIcons.desktopTower,
    'MdiIcons.watchVariant': MdiIcons.watchVariant,
    'MdiIcons.bookOpenPageVariant': MdiIcons.bookOpenPageVariant,
    'MdiIcons.motherboard': MdiIcons.developerBoard, // Replacement
    'MdiIcons.expansionCard': MdiIcons.expansionCard,
    'MdiIcons.cpu64Bit': MdiIcons.cpu64Bit,
    'MdiIcons.memory': MdiIcons.memory,
    'MdiIcons.harddisk': MdiIcons.harddisk,
    'MdiIcons.nas': MdiIcons.nas,
    'MdiIcons.powerSupply': MdiIcons.powerPlug, // Replacement
    'MdiIcons.fan': MdiIcons.fan,
    'MdiIcons.monitor': MdiIcons.monitor,
    'MdiIcons.keyboardVariant': MdiIcons.keyboardVariant,
    'MdiIcons.mouse': MdiIcons.mouse,
    'MdiIcons.headphones': MdiIcons.headphones,
    'MdiIcons.earbuds': MdiIcons.earbuds,
    'MdiIcons.powerPlug': MdiIcons.powerPlug,
    'MdiIcons.usbCable': MdiIcons.usbPort, // Replacement
    'MdiIcons.batteryCharging100': MdiIcons.batteryCharging100,
    'MdiIcons.usbFlashDrive': MdiIcons.usbFlashDrive,
    'MdiIcons.routerWireless': MdiIcons.routerWireless,
    'MdiIcons.camera': MdiIcons.camera,
    'MdiIcons.quadcopter': MdiIcons.quadcopter,

    // 2. Subscriptions
    'MdiIcons.cardAccountDetails': MdiIcons.cardAccountDetails,
    'MdiIcons.netflix': MdiIcons.netflix,
    'MdiIcons.youtube': MdiIcons.youtube,
    'MdiIcons.televisionClassic': MdiIcons.televisionClassic,
    'MdiIcons.playBox': MdiIcons.playBox,
    'MdiIcons.video': MdiIcons.video,
    'MdiIcons.youtubeSubscription': MdiIcons.youtubeSubscription,
    'MdiIcons.videoVintage': MdiIcons.videoVintage,
    'MdiIcons.spotify': MdiIcons.spotify,
    'MdiIcons.musicCircle': MdiIcons.musicCircle,
    'MdiIcons.musicNote': MdiIcons.musicNote,
    'MdiIcons.disc': MdiIcons.disc,
    'MdiIcons.microphone': MdiIcons.microphone,
    'MdiIcons.cloudUpload': MdiIcons.cloudUpload,
    'MdiIcons.googleDrive': MdiIcons.googleDrive,
    'MdiIcons.appleCloud': MdiIcons.cloud, // Replacement
    'MdiIcons.microsoftOffice': MdiIcons.microsoftOffice,
    'MdiIcons.adobe': MdiIcons.image, // Replacement
    'MdiIcons.robot': MdiIcons.robot,
    'MdiIcons.shieldKey': MdiIcons.shieldKey,
    'MdiIcons.vpn': MdiIcons.vpn,
    'MdiIcons.steam': MdiIcons.steam,
    'MdiIcons.sonyPlaystation': MdiIcons.sonyPlaystation,
    'MdiIcons.microsoftXbox': MdiIcons.microsoftXbox,
    'MdiIcons.nintendoSwitch': MdiIcons.nintendoSwitch,

    // 3. Home Appliances
    'MdiIcons.washingMachine': MdiIcons.washingMachine,
    'MdiIcons.fridge': MdiIcons.fridge,
    'MdiIcons.airConditioner': MdiIcons.airConditioner,
    'MdiIcons.television': MdiIcons.television,
    'MdiIcons.projector': MdiIcons.projector,
    'MdiIcons.microwave': MdiIcons.microwave,
    'MdiIcons.toasterOven': MdiIcons.toasterOven,
    'MdiIcons.potSteam': MdiIcons.potSteam,
    'MdiIcons.rice': MdiIcons.rice,
    'MdiIcons.coffeeMaker': MdiIcons.coffeeMaker,
    'MdiIcons.kettle': MdiIcons.kettle,
    'MdiIcons.dishwasher': MdiIcons.dishwasher,
    'MdiIcons.robotVacuum': MdiIcons.robotVacuum,
    'MdiIcons.vacuum': MdiIcons.vacuum,
    'MdiIcons.hairDryer': MdiIcons.hairDryer,
    'MdiIcons.airHumidifier': MdiIcons.airHumidifier,
    'MdiIcons.lightbulbSmart': MdiIcons.lightbulb, // Replacement
    'MdiIcons.waterBoiler': MdiIcons.waterBoiler,
    // 4. Furniture
    'MdiIcons.sofa': MdiIcons.sofa,
    'MdiIcons.bed': MdiIcons.bed,
    'MdiIcons.bedEmpty': MdiIcons.bedEmpty,
    'MdiIcons.chairRolling': MdiIcons.chairRolling,
    'MdiIcons.tableFurniture': MdiIcons.tableFurniture,
    'MdiIcons.desk': MdiIcons.desk,
    'MdiIcons.wardrobe': MdiIcons.wardrobe,
    'MdiIcons.bookshelf': MdiIcons.bookshelf,
    'MdiIcons.lamp': MdiIcons.lamp,
    'MdiIcons.curtains': MdiIcons.curtains,
    'MdiIcons.rug': MdiIcons.rug,

    // 5. Clothing
    'MdiIcons.hanger': MdiIcons.hanger,
    'MdiIcons.tshirtCrew': MdiIcons.tshirtCrew,
    'MdiIcons.tshirtV': MdiIcons.tshirtV,
    'MdiIcons.jacket': MdiIcons.hanger, // Replacement
    'MdiIcons.contentCut': MdiIcons.contentCut,
    'MdiIcons.skirt': MdiIcons.humanFemale, // Replacement
    'MdiIcons.shoeHeel': MdiIcons.shoeHeel,
    'MdiIcons.shoeSneaker': MdiIcons.shoeSneaker,
    'MdiIcons.shoeFormal': MdiIcons.shoeFormal,
    'MdiIcons.watch': MdiIcons.watch,
    'MdiIcons.glasses': MdiIcons.glasses,
    'MdiIcons.hatFedora': MdiIcons.hatFedora,
    'MdiIcons.ring': MdiIcons.ring,
    'MdiIcons.necklace': MdiIcons.necklace,
    'MdiIcons.bagPersonal': MdiIcons.bagPersonal,
    'MdiIcons.handbag': MdiIcons.bagPersonal, // Replacement
    'MdiIcons.bagSuitcase': MdiIcons.bagSuitcase,
    'MdiIcons.wallet': MdiIcons.wallet,

    // 6. Personal Care
    'MdiIcons.lipstick': MdiIcons.lipstick,
    'MdiIcons.bottleTonic': MdiIcons.bottleTonic,
    'MdiIcons.bottleTonicPlus': MdiIcons.bottleTonicPlus,
    'MdiIcons.brush': MdiIcons.brush,
    'MdiIcons.toothbrushElectric': MdiIcons.toothbrushElectric,
    'MdiIcons.razorSingleEdge': MdiIcons.razorSingleEdge,
    'MdiIcons.weatherSunny': MdiIcons.weatherSunny,
    'MdiIcons.hairbrush': MdiIcons.brush, // Replacement
    // 7. Sports
    'MdiIcons.basketball': MdiIcons.basketball,
    'MdiIcons.bicycle': MdiIcons.bicycle,
    'MdiIcons.skateboard': MdiIcons.skateboard,
    'MdiIcons.dumbbell': MdiIcons.dumbbell,
    'MdiIcons.run': MdiIcons.run,
    'MdiIcons.yoga': MdiIcons.yoga,
    'MdiIcons.tent': MdiIcons.tent,
    'MdiIcons.fish': MdiIcons.fish,
    'MdiIcons.soccer': MdiIcons.soccer,
    'MdiIcons.tennis': MdiIcons.tennis,
    'MdiIcons.billiards': MdiIcons.billiards,

    // 8. Vehicles
    // 8. Vehicles
    'MdiIcons.car': MdiIcons.car,
    'MdiIcons.motorbike': MdiIcons.motorbike,
    'MdiIcons.moped': MdiIcons.moped,
    'MdiIcons.carKey': MdiIcons.carKey,
    'MdiIcons.cardBulleted': MdiIcons.cardBulleted,
    'MdiIcons.webcam': MdiIcons.webcam,
    'MdiIcons.creditCardWireless': MdiIcons.creditCardWireless,
    'MdiIcons.cellphoneDock': MdiIcons.cellphoneDock,
    'MdiIcons.carBattery': MdiIcons.carBattery,
    'MdiIcons.airFilter': MdiIcons.airFilter,
    'MdiIcons.seatPassenger': MdiIcons.seatPassenger,

    // 12. Photography & Videography (Added)
    'MdiIcons.cameraGopro': MdiIcons.cameraGopro,
    'MdiIcons.cameraIris': MdiIcons.cameraIris,
    'MdiIcons.camcorder': MdiIcons.camcorder,
    'MdiIcons.videoStabilization': MdiIcons.videoStabilization,
    'MdiIcons.tripod': MdiIcons.webcam, // Fallback for invalid tripod
    'MdiIcons.stick': MdiIcons.cameraFront, // User requested (Selfie stick)
    'MdiIcons.microphoneMessage': MdiIcons.microphone, // User requested
    'MdiIcons.soundRecording': MdiIcons.waveform, // User requested
    'MdiIcons.whiteBalanceSunny': MdiIcons.whiteBalanceSunny,
    'MdiIcons.circleOutline': MdiIcons.circleOutline,
    'MdiIcons.batteryHigh': MdiIcons.batteryHigh,
    'MdiIcons.sd': MdiIcons.sd,
    'MdiIcons.expansionCardVariant': MdiIcons.expansionCardVariant,

    // 9. Books
    'MdiIcons.bookOpen': MdiIcons.bookOpen,
    'MdiIcons.book': MdiIcons.book,
    'MdiIcons.newspaper': MdiIcons.newspaper,
    'MdiIcons.album': MdiIcons.album,
    'MdiIcons.cartridge': MdiIcons.album, // Replacement
    // 10. Health
    'MdiIcons.medicalBag': MdiIcons.medicalBag,
    'MdiIcons.pill': MdiIcons.pill,
    'MdiIcons.thermometer': MdiIcons.thermometer,
    'MdiIcons.bandAid': MdiIcons.medicalBag, // Replacement
    'MdiIcons.faceMask': MdiIcons.faceMask,

    // 11. Entertainment & Games
    'MdiIcons.controller': MdiIcons.controller,
    'MdiIcons.cellphonegame': MdiIcons.cellphone,
    'MdiIcons.virtualReality': MdiIcons.virtualReality,
    'MdiIcons.gameboy': MdiIcons.gamepadVariant, // Replacement
    'MdiIcons.gamepadVariant': MdiIcons.gamepadVariant, // Direct use
    'MdiIcons.pacMan': MdiIcons.pacMan,
    'MdiIcons.headsetDock': MdiIcons.headsetDock,
    'MdiIcons.diceMultiple': MdiIcons.diceMultiple,
    'MdiIcons.fileFind': MdiIcons.fileFind,
    'MdiIcons.doorOpen': MdiIcons.doorOpen,
    'MdiIcons.domino': MdiIcons.viewModule, // Replacement for Mahjong
    'MdiIcons.cards': MdiIcons.cards,
    'MdiIcons.chessKnight': MdiIcons.chessKnight,
    'MdiIcons.bookOpenVariant': MdiIcons.bookOpenVariant,
    'MdiIcons.popcorn': MdiIcons.popcorn,
    'MdiIcons.microphoneVariant': MdiIcons.microphoneVariant,
    'MdiIcons.ticketConfirmation': MdiIcons.ticketConfirmation,
    'MdiIcons.ferrisWheel': MdiIcons.ferrisWheel,
    'MdiIcons.toyBrick': MdiIcons.toyBrick,
    'MdiIcons.giftOutline': MdiIcons.giftOutline,
    'MdiIcons.hook': MdiIcons.hook,
    'MdiIcons.desktopClassic': MdiIcons.desktopClassic,

    // Generic / UI
    'MdiIcons.shape': MdiIcons.shape,
    'MdiIcons.tag': MdiIcons.tag,
    'MdiIcons.viewDashboard': MdiIcons.viewDashboard,
    'MdiIcons.dotsHorizontal': MdiIcons.dotsHorizontal,
    'MdiIcons.shopping': MdiIcons.shopping,
    'MdiIcons.cat': MdiIcons.cat,
    'MdiIcons.dog': MdiIcons.dog,
    'MdiIcons.accountGroup': MdiIcons.accountGroup,
    'MdiIcons.store': MdiIcons.store,
    'MdiIcons.tagHeart': MdiIcons.tagHeart,
    'MdiIcons.notebook': MdiIcons.notebook,
    'MdiIcons.recycle': MdiIcons.recycle,
    'MdiIcons.kangaroo': MdiIcons.kangaroo,
    'MdiIcons.cow': MdiIcons.cow,
    'MdiIcons.carrot': MdiIcons.carrot,
    'MdiIcons.cartVariant': MdiIcons.cartVariant,
    'MdiIcons.apple': MdiIcons.apple,
    'MdiIcons.homeCity': MdiIcons.homeCity,
    'MdiIcons.briefcase': MdiIcons.briefcase,
  };

  static IconData getIconData(String iconName) {
    // Check key in MDI map
    if (_mdiMap.containsKey(iconName)) {
      return _mdiMap[iconName]!;
    }

    // Default Material Icons fallback
    switch (iconName) {
      case 'phone_android':
        return Icons.phone_android;
      case 'computer':
        return Icons.computer;
      default:
        // Fallback for unknown icons (previously handled dynamic 0x...)
        return Icons.category;
    }
  }
}
