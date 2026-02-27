import { AnalysisListener } from '../../listeners/AnalysisListener';
import TextDecoder from '@ohos.util';
import { PlayInfo, StreamType, TransportMode, SubCameraType, DeviceType } from '../../model/PlayInfo'
import { ObjectUtils } from '../../utils/ObjectUtils'
import { WifiCommandHelper } from '../../helper/WifiCommandHelper'
import {HisiCommandHelper} from '../../hisi/HisiCommandHelper'
import hilog from '@ohos.hilog';
import {DroneEnum} from '../../model/DroneEnum'


export class DeviceInfoManager {
  private static instance: DeviceInfoManager;
  // 定时任务对象id，用于获取设备信息
  private  mDeviceInfoId:number=0;
  // 定时任务对象id，用于设置设备时间
  private  mDeviceTimeId:number=0;
  // 定时获取设备信息的计数器
  private  mDevInfoCounter:number=0;
  // 定时设置设备时间的计数器
  private  mDevTimeCounter:number = 0;

  // 单例模式，确保唯一实例
  private constructor() {
  }

  static getInstance(): DeviceInfoManager {
    if (!DeviceInfoManager.instance) {
      DeviceInfoManager.instance = new DeviceInfoManager();
    }
    return DeviceInfoManager.instance;
  }


  public processDeviceInfo(data: Uint8Array) {

    const deviceVal = ObjectUtils.arrayBufferToHex(data)
    console.error(`收到来UDP数据：${ObjectUtils.arrayBufferToHex(data)}==========${data.length}${data.length >= 11 && data[0] == 0xAA && data[1] == 0xFF}`);
    if (deviceVal==null) {
      console.error(`==========`);
      return
    }

    if (data.length >= 3 && data[0] == 0x56 && data[2] == 0x2e) {
      //版本号
      //const str:string = TextDecoder.TextDecoder.
      const str = new TextDecoder.TextDecoder().decode(data)
      console.log(`版本号${str}`); // 输出："Hello"
      PlayInfo.firVersion = str;
      PlayInfo.setFirmwareVer();
      if (PlayInfo.firVersion) {
        return;
      }
      // udp720p 版本号小于2.1.9 通讯模式为udp
      if ("V2.1.9".localeCompare(PlayInfo.firVersion) > 0
        && DeviceType.UDP_720 == PlayInfo.deviceType) {
        PlayInfo.transportMode = TransportMode.UDP;
      }
      // VGA的板，如果版本是3.0.0（含）视频传输改成TCP
      if ("V3.0.0".localeCompare(PlayInfo.firVersion) <= 0
        && PlayInfo.deviceType == DeviceType.VGA) {
        PlayInfo.transportMode = TransportMode.TCP;
      }

    } else if (data.length >= 11 && data[0] == 0xAA && data[1] == 0xFF) {
      console.error(`收到来UDP数据：${ObjectUtils.arrayBufferToHex(data)}==========`);
      PlayInfo.setPlayInfo(data);
      this.initNewDeviceType(data);
      this.initResolution();

      console.log(`版id${PlayInfo.deviceId}`); // 输出："Hello"
    } else if (data.length >= 7 && data[0] == 0x6d && data[1] == 0x69 && data[2] == 0x72) {

      // 6d6972726f723d30=mirror=0 /6d6972726f723d31=mirror=1
      PlayInfo.mirror = data[7] == 0x31;

    } else if (data.length >= 3 && data[0] == 0x6f && data[1] == 0x6b) {

      if (data[2] == 0x01 || data[2] == 0x31 || (data[2] == 30 && data[3] == 0x0a)) {
        // 6f6b01 6f6b31 6f6b300a
        PlayInfo.mirror = false;
      } else if (data[2] == 0x02 || data[2] == 0x32 || (data[2] == 31 && data[3] == 0x0a)) {
        // 6f6b02 6f6b32 6f6b310a
        PlayInfo.mirror = true;
      }

    } else if (deviceVal.startsWith("797576")) { // YUV
      PlayInfo.transportMode = TransportMode.TCP;
      PlayInfo.streamType = StreamType.YUV;
      PlayInfo.deviceType = DeviceType.YUV;
      PlayInfo.frameRate = 25;
    } else if (deviceVal.startsWith("4d4a564741") || deviceVal.startsWith("5653564741")) { // MJVGA
      if (deviceVal.startsWith("4d4a564741")) {
        PlayInfo.deviceType = DeviceType.MJ_VGA;
      } else {
        PlayInfo.deviceType = DeviceType.VS_VGA;
      }
      //            PlayInfo.RTSPUrl = "rtsp://192.168.1.1:7070/webcam";
      PlayInfo.transportMode = TransportMode.RTSP;
      PlayInfo.streamType = StreamType.JPEG;
      PlayInfo.firmwareVer = "not support";
    } else if (deviceVal.startsWith("56474132")) { //VGA2

      PlayInfo.deviceType = DeviceType.VGA2;
      PlayInfo.transportMode = TransportMode.UDP;
      PlayInfo.streamType = StreamType.JPEG;
    } else if (deviceVal.startsWith("38373245545f3332305f333230")) { //872ET_320_320
      PlayInfo.deviceType = DeviceType.VGA2_872ET_320_320;
      PlayInfo.transportMode = TransportMode.UDP;
      PlayInfo.streamType = StreamType.JPEG;
    } else if (deviceVal.startsWith("38373241545f3634305f363430")) { //872AT_640_640
      PlayInfo.deviceType = DeviceType.VGA2_872AT_640_640;
      PlayInfo.transportMode = TransportMode.UDP;
      PlayInfo.streamType = StreamType.JPEG;
    } else if (deviceVal.startsWith("564741")) { //VGA
      // vga 版本号3.0.0（含）以上视频传输改成TCP
      PlayInfo.transportMode = TransportMode.UDP;
      PlayInfo.streamType = StreamType.H264_VGA;
      PlayInfo.deviceType = DeviceType.VGA;
    } else if (this.checkOldDeviceType(deviceVal)) {
      this.initOldDeviceType(deviceVal);
      PlayInfo.transportMode = TransportMode.TCP;
      PlayInfo.streamType = StreamType.H264;
    } else if (deviceVal.startsWith("5254535037323050") || deviceVal == ("3732305000")) { //RTSP720P / 720P
      //            PlayInfo.RTSPUrl = "rtsp://192.168.0.1/0 ";
      PlayInfo.transportMode = TransportMode.RTSP;
      PlayInfo.streamType = StreamType.H264;
      PlayInfo.frameRate = 25;
      if (deviceVal == ("3732305000")) {
        PlayInfo.deviceType = DeviceType._720P;
      } else {
        PlayInfo.deviceType = DeviceType.RTSP_720;
      }
    } else if (deviceVal.startsWith("525453503130383050")) { //RTSP1080P
      //            PlayInfo.RTSPUrl = "rtsp://192.168.0.1/0 ";
      PlayInfo.transportMode = TransportMode.RTSP;
      PlayInfo.streamType = StreamType.H264;
      PlayInfo.deviceType = DeviceType.RTSP_1080;
      PlayInfo.frameRate = 25;
    }


    if (PlayInfo.deviceType != DeviceType.NONE || PlayInfo.deviceId != 0) {
      console.log("已获取到设备信息", PlayInfo.deviceId, PlayInfo.deviceType);

    //  onDeviceTypeListener.onNewDevice(mExternalDevType);

      if (PlayInfo.streamType == StreamType.JPEG) {
        // 872 udp 心跳（目前只有872需要）
       // onDeviceTypeListener.onStartHeartbeat();
      }



      if (this.mDeviceInfoId==0) {
        this.mDevInfoCounter = 0;
        this.mDeviceInfoId = setInterval(() => {
          this.mDeviceInfo();
        }, 500,10);
      }


      // 调度任务
      if (this.mDeviceTimeId==0) {
        this.mDevTimeCounter = 0;
        this.mDeviceTimeId = setInterval(() => {
          this.mDeviceTime();
        }, 300,10);
      }


    }

  }
  // 设备时间定时任务，用于发送系统时间给设备
  private mDeviceTime(){
    try {
      // 根据设备类型发送系统时间
      if (PlayInfo.isHisi()) {
        HisiCommandHelper.sendSystemTime();
      }  else {
        WifiCommandHelper.udpSendTime();
      }
      console.info("设置系统时间 : " +  this.mDevTimeCounter);
      // 增加设备时间定时任务的计数
      this.mDevTimeCounter++;
      // 如果定时任务执行了一定次数，取消后续任务并关闭定时任务服务
      if ( this.mDevTimeCounter < 20) {
        //closeDeviceTimeTask();
        clearInterval(this.mDeviceTimeId);
      }
    } catch ( e) {
      // 记录异常信息
      console.error("deviceTimeTask : " + e.getMessage());
    }
  }

  //设备信息定时任务，用于获取设备信息
  private mDeviceInfo(){
    try {
      // 执行一系列获取设备信息的命令
      if (PlayInfo.firVersion==null){
        WifiCommandHelper.getVersion();
      }
      if (PlayInfo.droneEnum == DroneEnum.no_drone){
        WifiCommandHelper.getWifiCode();
      }

      //  WifiCommandHelper.getWifiName();
      if (PlayInfo.countryCode==null){
        WifiCommandHelper.getCountryCode();
      }

      // bool变量无法判断
      WifiCommandHelper.getVideoOrientation();

      if (PlayInfo.isHisi()) {
        if (PlayInfo.Sensor==null){
          HisiCommandHelper.getSensor();
        }

        if ( PlayInfo.hisiResolutionId ==-1){
          HisiCommandHelper.getRecordResolution();
        }

      }
      console.log("请求设备信息 : " +  this.mDevInfoCounter);
      // 增加设备信息定时任务的计数
      this.mDevInfoCounter++;
      // 如果定时任务执行了一定次数，取消后续任务
      if ( this.mDevInfoCounter >= 10) {
       // closeDevInfoTask();
         clearInterval(this.mDeviceInfoId);
      }
    } catch (e) {
      // 记录异常信息
      console.log("deviceInfoTask : " + e.getMessage());
    }
  }


  /**
   * 初始化或更新设备类型信息。
   * 根据传入的数据解析出设备类型，并进行相应的初始化工作。
   *
   * @param data 包含设备类型信息的数据。
   */
  private initNewDeviceType(data: Uint8Array) {
    try {
      PlayInfo.setPlayInfo(data);
      // 芯片厂家
      switch (PlayInfo.chipMaker) {
        case 0x01: //富瀚
          break;
        case 0x02: // 海思
          break;
        case 0x03: //全志
          if (PlayInfo.chipType == 1) { // 872
            // 872 udp 心跳（目前只有872需要）
            //UdpHeartbeat.getInstance().start();
            PlayInfo.streamType = StreamType.JPEG;
          }
          break;
        case 0x04: // 杰理
          if (PlayInfo.chipType == 1 || PlayInfo.chipType == 2) { // 872
            // 872 udp 心跳（目前只有872需要）
            //UdpHeartbeat.getInstance().start();
            PlayInfo.streamType = StreamType.JPEG;
          }
          break;
      }
      // wifi 频段
      if (PlayInfo.bandId >= 200) {
        PlayInfo.wifiRate = 1;
        WifiCommandHelper.getCountryCode();
      } else {
        PlayInfo.wifiRate = 0;
      }


      // 出图方式
      if (data[7] == 1) {
        PlayInfo.transportMode = TransportMode.UDP;
      } else if (data[7] == 2) {
        PlayInfo.transportMode = TransportMode.TCP;
      } else if (data[7] == 3) {
        PlayInfo.transportMode = TransportMode.RTSP;
      }

      if (data.length == 11) {
        // 老定义
        // id
        PlayInfo.deviceId = ObjectUtils.byte2ToShort(new Uint8Array([data[9], data[10]]));

        // 示例：打印DEBUG级别日志
        hilog.debug(0xD010, 'MyAppTag', '设置板id1: %{public}s', data[9]);

        console.log('设置板id1: ' + PlayInfo.firVersion+"-----"+ObjectUtils.byte2ToShort(new Uint8Array([data[9], data[10]])),new Uint8Array([data[9], data[10]]))

      } else {
        // 副镜头类型
        PlayInfo.setSubCameraTypeByValue(data[9]);
        // id
        PlayInfo.deviceId = ObjectUtils.byte2ToShort(new Uint8Array([data[11], data[12]]));
        console.log('设置板id2: ' + PlayInfo.deviceId, ObjectUtils.byte2ToShort(new Uint8Array([data[11], data[12]])));
      }


      //获取当前主、副镜头
      if (PlayInfo.subCameraType == SubCameraType.UDP_SINGLE
        || PlayInfo.subCameraType == SubCameraType.TCP_MULTIPLE) {
        WifiCommandHelper.getCameraIndex();
      }

      // 海思和国科使用h265
      if (PlayInfo.deviceId == 58
        || PlayInfo.isHisi()
        || PlayInfo.isGK()) {
        PlayInfo.streamType = StreamType.H265;
      }

      if (PlayInfo.deviceId == 59 || PlayInfo.deviceId == 61 || PlayInfo.deviceId == 97) {
        PlayInfo.streamType = StreamType.H264;
      }

      if (PlayInfo.deviceId == 97 && PlayInfo.firmwareVer.includes("4.7.3")) {
        PlayInfo.streamType = StreamType.H265;
      }
      if (PlayInfo.showStream == 240 || PlayInfo.deviceId == 102) {
        if (PlayInfo.cameraIndex == 0) {
          PlayInfo.streamType = StreamType.H264;
        } else {
          PlayInfo.streamType = StreamType.H265;
        }
      }

      PlayInfo.resolutionId = data[5];

      console.log(`=======${PlayInfo.resolutionId}`);


    } catch (e) {
      console.log(`initNewDeviceType Exception :${e}`);
    }
  }

  /**
   * 初始化设备的分辨率设置。
   * 该方法会根据默认设置或用户偏好来配置设备的分辨率。
   */
  private initResolution() {
    // 图传分辨率
    switch (PlayInfo.resolutionId) {
      case 1:
        PlayInfo.frameWidth = 320;
        PlayInfo.frameHeight = 240;
        break;
      case 10:
        PlayInfo.frameWidth = 640;
        PlayInfo.frameHeight = 360;
        break;
      case 11:
        PlayInfo.frameWidth = 640;
        PlayInfo.frameHeight = 480;
        break;
      case 20:
        PlayInfo.frameWidth = 1280;
        PlayInfo.frameHeight = 720;
        break;
      case 21:
        PlayInfo.frameWidth = 1024;
        PlayInfo.frameHeight = 576;
        break;
      case 30:
        PlayInfo.frameWidth = 1920;
        PlayInfo.frameHeight = 1080;
        break;
      case 31:
        PlayInfo.frameWidth = 1632;
        PlayInfo.frameHeight = 928;
        break;
      case 40:
        PlayInfo.frameWidth = 2048;
        PlayInfo.frameHeight = 1152;
        break;
      case 41:
        PlayInfo.frameWidth = 2592;
        PlayInfo.frameHeight = 1520;
        break;
      case 42:
        PlayInfo.frameWidth = 2560;
        PlayInfo.frameHeight = 1440;
        break;
      case 43:
        PlayInfo.frameWidth = 2592;
        PlayInfo.frameHeight = 1952;
        break;
      case 44:
        PlayInfo.frameWidth = 2976;
        PlayInfo.frameHeight = 1680;
        break;
      case 50:
        PlayInfo.frameWidth = 3840;
        PlayInfo.frameHeight = 2160;
        break;
      case 60:
        PlayInfo.frameWidth = 4000;
        PlayInfo.frameHeight = 3000;
        break;
    }
  }

  private checkOldDeviceType(tmpStr: string): boolean {
    return (tmpStr == ("55445037323050")  //UDP720P
      || tmpStr == ("373230502d3567")  //720P-5g
      || tmpStr == ("373230502d3547")  //720P-5G
      || tmpStr == ("3130383050")  //1080P = UDP1080P
      || tmpStr == ("31303830502d3567")  //1080P-5g
      || tmpStr == ("554450324b")  //UDP2K
      || tmpStr == ("554450344b")  //UDP4K
      || tmpStr == ("31303830502d49")  //1080P-I
      || tmpStr == ("554450324b2d3330")  //UDP2K-30
      || tmpStr == ("55445032374b")  //UDP27K
      || tmpStr == ("4849344b")//HI4K
      || tmpStr == ("4849324b")//HI2K
      || tmpStr == ("484932354b")//HI25K
      || tmpStr == ("4648383632365f737376367835785f3234675f313932305f31323830") //FH8626_ssv6x5x_24g_1920_1280
      || tmpStr == ("4648383632365f737376367835785f35675f313932305f31323830")//FH8626_ssv6x5x_5g_1920_1280
      || tmpStr == ("383835365f3838313263755f343030305f31323830")//FH8856_8812cu_4000_1280
      || tmpStr == ("4d723130305f737376367835785f313932305f31393230")//Mr100_ssv6x5x_1920_1920
      || tmpStr == ("4d723130305f737376367835785f313932305f31323830")//Mr100_ssv6x5x_1920_1280
      || tmpStr == ("4d723130305f737376367835785f343030305f31393230")//Mr100_ssv6x5x_4000_1920
      || tmpStr == ("4d723130305f737376367835785f343030305f31323830")//Mr100_ssv6x5x_4000_1280
      || tmpStr == ("4d723130305f737376367835785f323034385f32303438")//Mr100_ssv6x5x_2048_2048
      || tmpStr == ("4d723130305f737376367835785f343030305f32303438")//Mr100_ssv6x5x_4000_2048
      || tmpStr == ("4d723130305f383830315f323034385f32303438")//Mr100_8801_2048_2048
      || tmpStr == ("4d723130305f383830315f343030305f32303438")//Mr100_8801_4000_2048
      || tmpStr == ("4d723130305f383830315f313932305f31393230")//Mr100_8801_1920_1920
      || tmpStr == ("4d723130305f383830315f313932305f31323830")//Mr100_8801_1920_1280
      || tmpStr == ("4d723130305f383830315f343030305f31393230")//Mr100_8801_4000_1920
      || tmpStr == ("4d723130305f383830315f343030305f31323830")//Mr100_8801_4000_1280
      || tmpStr == ("31303830502d3547")// 1080P-5G 回传1080p
    );
  }


  private initOldDeviceType(tmpStr: string) {
    switch (tmpStr) {
      case "55445037323050":
        PlayInfo.deviceType = DeviceType.UDP_720;
        PlayInfo.frameRate = 25;
        break;
      case "373230502d3567":
        PlayInfo.deviceType = DeviceType.HZ_5G_720_1;
        PlayInfo.frameRate = 25;
        break;
      case "373230502d3547":
        PlayInfo.deviceType = DeviceType.HZ_5G_720_2;
        PlayInfo.frameRate = 25;
        break;
      case "3130383050":
        PlayInfo.deviceType = DeviceType.UDP_1080;
        PlayInfo.frameRate = 25;
        break;
      case "31303830502d3567":
        PlayInfo.deviceType = DeviceType.HZ_5G_1080_1;
        PlayInfo.frameRate = 25;
        break;
      case "554450324b":
        PlayInfo.deviceType = DeviceType.UDP_2K;
        PlayInfo.frameRate = 25;
        break;
      case "554450344b": //回传2048
        PlayInfo.deviceType = DeviceType.UDP_4K;
        PlayInfo.frameRate = 25;
        break;
      case "31303830502d49":
        PlayInfo.deviceType = DeviceType.I_1080;
        PlayInfo.frameRate = 25;
        break;
      case "554450324b2d3330":
        PlayInfo.deviceType = DeviceType.UDP_2K_30;
        PlayInfo.frameRate = 30;
        break;
      case "55445032374b":
        PlayInfo.deviceType = DeviceType.UDP_2_7K;
        break;
      case "4849324b":
        PlayInfo.deviceType = DeviceType.HI2K;
        PlayInfo.frameRate = 30;
        break;
      case "484932354b":
        PlayInfo.deviceType = DeviceType.HI25K;
        PlayInfo.frameRate = 30;
        break;
      case "4849344b":
        PlayInfo.deviceType = DeviceType.HI4K;
        PlayInfo.frameRate = 30;
        break;
      case "4648383632365f737376367835785f3234675f313932305f31323830":
        PlayInfo.deviceType = DeviceType.FH8626_ssv6x5x_24g_1920_1280;
        PlayInfo.frameRate = 25;
        break;
      case "4648383632365f737376367835785f35675f313932305f31323830":
        PlayInfo.deviceType = DeviceType.FH8626_ssv6x5x_5g_1920_1280;
        PlayInfo.frameRate = 25;
        break;
      case "383835365f3838313263755f343030305f31323830":
        PlayInfo.deviceType = DeviceType.FH8856_8812cu_4000_1280;
        PlayInfo.frameRate = 25;
        break;
      case "4d723130305f737376367835785f313932305f31393230":
        PlayInfo.deviceType = DeviceType.Mr100_ssv6x5x_1920_1920;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f737376367835785f313932305f31323830":
        PlayInfo.deviceType = DeviceType.Mr100_ssv6x5x_1920_1280;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f737376367835785f343030305f31393230":
        PlayInfo.deviceType = DeviceType.Mr100_ssv6x5x_4000_1920;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f737376367835785f343030305f31323830":
        PlayInfo.deviceType = DeviceType.Mr100_ssv6x5x_4000_1280;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f737376367835785f323034385f32303438":
        PlayInfo.deviceType = DeviceType.Mr100_ssv6x5x_2048_2048;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f737376367835785f343030305f32303438":
        PlayInfo.deviceType = DeviceType.Mr100_ssv6x5x_4000_2048;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f383830315f323034385f32303438":
        PlayInfo.deviceType = DeviceType.Mr100_8801_2048_2048;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f383830315f343030305f32303438":
        PlayInfo.deviceType = DeviceType.Mr100_8801_4000_2048;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f383830315f313932305f31393230":
        PlayInfo.deviceType = DeviceType.Mr100_8801_1920_1920;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f383830315f313932305f31323830":
        PlayInfo.deviceType = DeviceType.Mr100_8801_1920_1280;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f383830315f343030305f31393230":
        PlayInfo.deviceType = DeviceType.Mr100_8801_4000_1920;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "4d723130305f383830315f343030305f31323830":
        PlayInfo.deviceType = DeviceType.Mr100_8801_4000_1280;
        PlayInfo.frameRate = 25;
        PlayInfo.subCameraType = SubCameraType.TCP_MULTIPLE;
        break;
      case "31303830502d3547":
        PlayInfo.deviceType = DeviceType.HZ_5G_1080_2;
        PlayInfo.frameRate = 25;
        break;
    }
  }
}