import {DroneEnum} from './DroneEnum'
/**
 * 视频流类型
 */
export enum StreamType {
  H264_VGA=1, // 低分辨率
  H264=2,
  JPEG=3,
  H265=4,
  YUV=5,
}


/**
 * 通讯模式
 */
export enum TransportMode {
  UDP,
  TCP,
  RTSP
}

export enum DeviceType {
  NONE,
  YUV,
  MJ_VGA,
  VS_VGA,
  VGA,
  VGA2,
  VGA2_872ET_320_320,
  VGA2_872AT_640_640,
  YU_YAN_720,  // 鱼眼
  UDP_720,
  HZ_5G_720_1, // 小写5g 720
  HZ_5G_720_2, // 大写5g 720
  UDP_1080,
  HZ_5G_1080_1, // 小写5g 1080
  HZ_5G_1080_2, // 大写5g 1080
  UDP_2K,
  UDP_4K,
  RTSP_720,
  _720P,      // 与RTSP720P一样
  RTSP_1080,
  I_1080,       // 1080P-I (拍照拉伸为1080， 无插卡)
  UDP_2K_30,    // 2k 回传720P 30fps
  UDP_2_7K,     // 2.7k 回传720P
  HI2K,
  HI25K,        // 回传1024x576 默认拍照录像插值720
  HI4K,
  FH8626_ssv6x5x_24g_1920_1280,
  FH8626_ssv6x5x_5g_1920_1280,
  FH8856_8812cu_4000_1280,

  Mr100_ssv6x5x_2048_2048,
  Mr100_ssv6x5x_1920_1920,
  Mr100_ssv6x5x_1920_1280,
  Mr100_ssv6x5x_4000_2048,
  Mr100_ssv6x5x_4000_1920,
  Mr100_ssv6x5x_4000_1280,

  Mr100_8801_2048_2048,
  Mr100_8801_1920_1920,
  Mr100_8801_1920_1280,
  Mr100_8801_4000_2048,
  Mr100_8801_4000_1920,
  Mr100_8801_4000_1280
}


export class PlayInfo {
  public static  transportMode:TransportMode = TransportMode.TCP;
  public static firVersion: string; //WIFI 版本
  public static deviceId: number=0; //版id
  public static subCameraType: SubCameraType; //副镜头（双镜头）类型
  public static chipMaker: number; // 芯片制造商

  public static chipType: number; // 芯片型号标识 主控
  public static showStream: number; //出图方式
  public static bandId: number = 0;
  public static frameRate: number = 25; //频段
  public static streamType:StreamType =StreamType.H264;
  public static  wifiRate:number; // 0=2.4G  1=5.8G
  public static  firmwareVer:string;   // firmware 版本+分辨率
  public static  cameraIndex:number; //镜头的index 0=主镜头、1=副镜头
  public static  resolutionId:number= 0;//分辨率ID
  public static  hisiResolutionId:number= -1;//海思3519分辨率ID
  public static  frameWidth:number;
  public static  frameHeight:number;
  public static  deviceType:DeviceType = DeviceType.NONE; // wifi版类型
  public static  mirror:boolean;        // 是否是镜子模式（翻转）
  public static  droneEnum:DroneEnum = DroneEnum.no_drone;
  public static  countryCode:string;   // 国家码
  public static  Sensor:string;


  // 公共静态方法：根据传入的数值设置subCameraType
  public static setSubCameraTypeByValue(value: number) {
    PlayInfo.subCameraType = value as SubCameraType;
  }


  /**
   * 基础的配置
   */
  public static  initConfigure() {
    PlayInfo.deviceType = DeviceType.NONE;
    PlayInfo.deviceId = 0;
    PlayInfo.resolutionId = 0;
    PlayInfo.hisiResolutionId = -1;
    PlayInfo.mirror = true;        // 是否是镜子模式（翻转）
    //        cameraIndex = 0;
    PlayInfo.subCameraType = SubCameraType.NO;
    PlayInfo.firmwareVer = "";
    PlayInfo.firVersion = "";

  }


  /**
   * 头（AAFF 2byte） + 芯片厂家 + 芯片型号+ 频段 （2.4/5.8）
   * + 回传分辨率 + 实际分辨率 + 出图方式（tcp/udp）+ 帧率
   * + 是否双镜头 + 副镜头回传分辨率 +  id
   */
  public static setPlayInfo(data: Uint8Array) {
    //芯片制造商
    PlayInfo.chipMaker = data[2];
    // 芯片型号
    PlayInfo.chipType = data[3];
    PlayInfo.showStream = data[7];

    // 频段
    PlayInfo.bandId = data[4];
    // 帧率
    if (PlayInfo.isGK()) {
      PlayInfo.frameRate = 25;
    } else {
      PlayInfo.frameRate = data[8];
    }

  }



  /**
   * 国科板
   *
   * @return
   */
  public static isGK(): boolean {
    return PlayInfo.chipMaker == 0x07;
  }

  /**
   * 海思新板，做双目，新录像功能
   *
   * @return
   */
  public static  isHisi():boolean {
    //        return PlayInfo.deviceId == 71 || PlayInfo.deviceId == 72 || PlayInfo.deviceId == 99 || PlayInfo.deviceId == 100 || PlayInfo.deviceId == 105 || PlayInfo.deviceId == 113;
    return PlayInfo.chipMaker == 0x02;
  }


  public static setFirmwareVer() {
    if (PlayInfo.deviceId != 0) {
      PlayInfo.firmwareVer = PlayInfo.firVersion + "_" + PlayInfo.deviceId + "X";
    } else {
      switch (PlayInfo.deviceType) {
        case DeviceType.YUV:
          PlayInfo.firmwareVer = PlayInfo.firVersion;
          break;
        case DeviceType.VGA:
        case DeviceType.MJ_VGA:
        case DeviceType.VS_VGA:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_10";
          break;
        case DeviceType.VGA2:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_11";
          break;
        case DeviceType.VGA2_872ET_320_320:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_1_01";
          break;
        case DeviceType.VGA2_872AT_640_640:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_1_02";
          break;
        case DeviceType.UDP_720:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_20";
          break;
        case DeviceType.RTSP_720:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_21";
          break;
        case DeviceType.HZ_5G_720_1:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_22";
          break;
        case DeviceType.HZ_5G_720_2:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_23";
          break;
        case DeviceType.YU_YAN_720:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_24";
          break;
        case DeviceType._720P:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_25";
          break;
        case DeviceType.UDP_1080:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_30";
          break;
        case DeviceType.I_1080:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_31";
          break;
        case DeviceType.HZ_5G_1080_1:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_32";
          break;
        case DeviceType.RTSP_1080:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_33";
          break;
        case DeviceType.HZ_5G_1080_2:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_34";
          break;
        case DeviceType.FH8626_ssv6x5x_24g_1920_1280:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_3_01";
          break;
        case DeviceType.FH8626_ssv6x5x_5g_1920_1280:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_3_02";
          break;
        case DeviceType.Mr100_ssv6x5x_1920_1920:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_3_03";
          break;
        case DeviceType.Mr100_ssv6x5x_1920_1280:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_3_04";
          break;
        case DeviceType.Mr100_8801_1920_1920:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_3_05";
          break;
        case DeviceType.UDP_2K:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_40";
          break;
        case DeviceType.UDP_2K_30:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_41";
          break;
        case DeviceType.UDP_2_7K:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_42";
          break;
        case DeviceType.HI2K:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_43";
          break;
        case DeviceType.HI25K:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_44";
          break;
        case DeviceType.Mr100_ssv6x5x_2048_2048:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_4_01";
          break;
        case DeviceType.Mr100_8801_2048_2048:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_4_02";
          break;
        case DeviceType.UDP_4K:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_50";
          break;
        case DeviceType.HI4K:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_51";
          break;
        case DeviceType.FH8856_8812cu_4000_1280:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_01";
          break;
        case DeviceType.Mr100_ssv6x5x_4000_2048:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_02";
          break;
        case DeviceType.Mr100_ssv6x5x_4000_1920:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_03";
          break;
        case DeviceType.Mr100_ssv6x5x_4000_1280:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_04";
          break;
        case DeviceType.Mr100_8801_4000_2048:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_05";
          break;
        case DeviceType.Mr100_8801_4000_1920:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_06";
          break;
        case DeviceType.Mr100_8801_4000_1280:
          PlayInfo.firmwareVer = PlayInfo.firVersion + "_5_07";
          break;
      }
    }
  }

  /**
   * 是否是872的版
   *
   * @return
   */
  public static  is872():boolean {
    return PlayInfo.deviceType ==DeviceType.VGA2
      || PlayInfo.deviceType == DeviceType.VGA2_872ET_320_320
      || PlayInfo.deviceType == DeviceType.VGA2_872AT_640_640
      || PlayInfo.deviceId == DeviceId._872_720
      || PlayInfo.deviceId ==DeviceId._872_DOUBLE_CAMERA
      || (PlayInfo.chipMaker == 0x03 && PlayInfo.chipType == 0x01) // chipMaker=全志+masterControl=872
      || (PlayInfo.chipMaker == 0x04 && (PlayInfo.chipType == 0x01 ||PlayInfo. chipType == 0x02)); // chipMaker=杰理+masterControl=872
  }

  public static  isMr100():boolean {
    return  PlayInfo.deviceType == DeviceType.Mr100_ssv6x5x_2048_2048 || PlayInfo.deviceType == DeviceType.Mr100_ssv6x5x_1920_1920 || PlayInfo.deviceType == DeviceType.Mr100_ssv6x5x_1920_1280 || PlayInfo.deviceType == DeviceType.Mr100_ssv6x5x_4000_2048 || PlayInfo.deviceType == DeviceType.Mr100_ssv6x5x_4000_1920 || PlayInfo.deviceType ==DeviceType.Mr100_ssv6x5x_4000_1280 || PlayInfo.deviceType == DeviceType.Mr100_8801_2048_2048 || PlayInfo.deviceType ==DeviceType.Mr100_8801_1920_1920 || PlayInfo.deviceType ==DeviceType.Mr100_8801_1920_1280 || PlayInfo.deviceType ==DeviceType.Mr100_8801_4000_2048 || PlayInfo.deviceType ==DeviceType.Mr100_8801_4000_1920 || PlayInfo.deviceType == DeviceType.Mr100_8801_4000_1280 || PlayInfo.deviceId == 41 || PlayInfo.chipType == 2 && PlayInfo.chipMaker == 3;
  }

}


/**
 * 副镜头（双镜头）类型
 */
export enum SubCameraType {
  NO = 0, // 没有/不支持
  UDP_SINGLE = 1, // UDP单码流
  TCP_MULTIPLE = 2, // TCP支持同时双码流
  UDP_MULTIPLE = 3, // UDP支持同时双码流
}

export enum DeviceId {
  _872_720=1,
  _872_DOUBLE_CAMERA=2,
  MR100_5G_8822CS_4K=10,
  _8626_5G_8801_8603_1080P=13,
}



