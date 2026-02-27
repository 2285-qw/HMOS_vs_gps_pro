import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Type, window } from '@kit.ArkUI';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import socket from '@ohos.net.socket';
import { ObjectUtils } from '../utils/ObjectUtils';
import { WifiUtils } from '../utils/WifiUtils';
import { DataNoticeManager } from '../connect/manager/DataNoticeManager';
import { DeviceInfoManager } from '../connect/manager/DeviceInfoManager';
import { AnalysisListener } from '../listeners/AnalysisListener';
import wifiManager from '@ohos.wifiManager';
import { NetworkManager } from '../connect/manager/NetworkManager'
import { OnDeviceConnectionListener, ExternalDevType } from '../listeners/OnDeviceConnectionListener';
import { PlayInfo, StreamType, TransportMode, SubCameraType, DeviceType } from '../model/PlayInfo'
import { WifiCommandHelper } from '../helper/WifiCommandHelper';
import { HeartbeatTcpConnection } from '../connect/HeartbeatTcpConnection'

import { StreamTcpConnection } from '../connect/StreamTcpConnection'
import { TcpConnection, TcpConfig } from "../connect/TcpConnection"
import { ConnectionCallback, ConnectionState } from '../connect/BaseConnection'
import { createBuffer, writeData, getOneFrame } from 'vison_main.so';
import NapiBuffer from 'libentry.so';
import { VideoStreamHandle } from '../connect/stream/VideoStreamHandle'
import { emitter, usbManager } from '@kit.BasicServicesKit';
import commonEventManager from '@ohos.commonEventManager';
import prompt from '@ohos.prompt';
import { USBAccessoryCommunicator } from '../connect/usb/USBAccessoryCommunicator'

import promptAction from '@ohos.promptAction';
import { UsbWriteCommands } from '../connect/usb/UsbWriteCommands'
import { ConnectionStatusListener } from '../listeners/ConnectionStatusListener';
import { OnHandleDataListener, ConnectionType } from '../listeners/OnHandleDataListener';
import { ProtocolManager } from '../macrochip/Drone/core/protocol/ProtocolManager';
import { DroneCodeManager } from '../macrochip/Drone/code/DroneCodeManager';
import { MessagePacket } from '../macrochip/Drone/core/message/MessagePacket';
import { ParseUtils } from '../macrochip/Drone/core/parse/ParseUtils';
import { ObserverManager } from '../macrochip/Drone/observer/ObserverManager';
import { PreferencesUtil } from '../macrochip/utils/PreferencesUtil';
import { ModeType, PageSendData } from '../macrochip/Drone/core/protocol/PageSendData';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  // 1. 创建 UdpSocket 实例
  udpSocket: socket.UDPSocket = socket.constructUDPSocketInstance();
  communicator ?: USBAccessoryCommunicator;
  private isConnected: boolean = false;
  // 连接状态
  public static DEV_UDP_PORT = 8080;
  public static DEV_UDP_PORT_8081 = 8081;
  public static DEV_UDP_PORT_8088 = 8088;
  public static DEV_TCP_PORT = 8888;
  public static STREAM_PORT = 8888;
  public static Ip: string = '';
  private static instance: EntryAbility;
  //private analysisListener?: AnalysisListener;
  private mDeviceTaskId: number | null = null;
  private streamTcpConnection?: StreamTcpConnection;
  //WIFI视频流心跳

  private connectionStatusListener?: ConnectionStatusListener;

  //连接状态监听放回进行视频流心跳

  // 单例模式，确保唯一实例
  static getInstance(): EntryAbility {
    if (!EntryAbility.instance) {
      EntryAbility.instance = new EntryAbility();
    }
    return EntryAbility.instance;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {

    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    //绑定UDp连接
    // this.initUdpSocket();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    hilog.setMinLogLevel(hilog.LogLevel.DEBUG);


  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    NetworkManager.getInstance().unregisterNetwork()
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 监听网络连接
    this.initConnection()
    //监听usb连接
    this.initUsb()

    UsbWriteCommands.writeHeartbeat();
    UsbWriteCommands.writeVideoHeartbeat();

    //NapiBuffer.createUsbStream();


    // 存储UIAbilityContext到AppStorage，键名为"uiAbilityContext"
    AppStorage.SetOrCreate('uiAbilityContext', this.context);

    windowStage.loadContent('pages/WelcomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    PreferencesUtil.initPreferences(this.context)

  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }


  // 初始化UDP套接字
  private initUdpSocket() {
    this.udpSocket = socket.constructUDPSocketInstance();
    // 绑定本地端口（可选，根据需求配置）
    // 3. 注册接收数据回调（用于接收服务器响应）
    this.udpSocket.on('message', (packet: socket.SocketMessageInfo) => {
      console.error(`收到来UDP数据：${ObjectUtils.arrayBufferToHex(packet.message)}==========+${new Uint8Array(packet.message)}`);
      // 处理接收到的数据（如解析、展示等）


      //处理收到UDP数据
      // 转换为Uint8Array
      const uint8Array: Uint8Array = new Uint8Array(packet.message);
      this.onHandleDataListener?.onHandleData(ConnectionType.UDP, ExternalDevType.WIFI, uint8Array)

    });

    this.udpSocket.bind({
      address: '0.0.0.0',
      port: 0,
    }, (err: BusinessError) => {
      if (err) {
        console.error('UDP绑定失败：', err.message);
        this.isConnected = false;
        return;
      }
      this.isConnected = true;
      console.log('UDP绑定成功，开始监听消息');
    });

  }

  // WIFI发送UDP消息的方法
  writeUDPCmd(data: Uint8Array) {
    if (!this.udpSocket || !this.isConnected) {
      console.error('UDP未连接，发送失败');
      this.initUdpSocket();
      return;
    }

    if (EntryAbility.Ip.length == 0) {
      EntryAbility.Ip = WifiUtils.getWIFIIP()
    }
    let targetIp: socket.NetAddress = {
      address: EntryAbility.Ip, // 服务器ip地址
      port: EntryAbility.DEV_UDP_PORT, // 本地端口
      family: 1, // 1:IPv4, 2:IPv6
    }
    const data1 = new Uint8Array([0x0f]);
    this.udpSocket.send({
      data: data.buffer,
      address: targetIp,
    }, (err: BusinessError) => {
      if (err) {
        console.error(`发送失败：${err.message}`);
        return;
      }
      // console.log(`已发送${data}`);
    });
  }

  public setAnalysisListener(analysisListener: AnalysisListener): void {

    this.analysisListener = analysisListener;
    console.log('设置回调', this.analysisListener)
  }


  private initConnection() {
    // 请求网络连接，onDeviceConnectionListener 用于处理网络连接的回调
    NetworkManager.getInstance().requestNetwork(this.onDeviceConnectionListener);
    //usb连接回调
    USBAccessoryCommunicator.getInstance().setonDeviceConnectionListener(this.onDeviceConnectionListener);
    USBAccessoryCommunicator.getInstance().subscribeUsb();

  }


  private onDeviceConnectionListener: OnDeviceConnectionListener = {
    onDeviceConnection: (type: ExternalDevType) => {
      if (this.hasDevice()) {
        console.info("device connection 已有设备正通信中：" + type)
        return;
      }
      console.log(`设备连接：${type}`);
      this.startDeviceTypeTask(500);
      if (type == ExternalDevType.WIFI) {


        console.log(`wifi 已连接`)
        // 基础用法（显示在应用内）
        //创建udp连接
        this.initUdpSocket();

        //创建tcp连接
        // 创建带心跳的TCP连接实例
        const heartbeatConnection = new HeartbeatTcpConnection();
        // 建立连接后自动开始心跳
        heartbeatConnection.connect(new TcpConfig(WifiUtils.getWIFIIP(), EntryAbility.DEV_TCP_PORT, 50000))
          .then(() => {
            console.log("Connected with heartbeat");
          });
        heartbeatConnection.setCallback(this.connectionCallback)
        //设置数据除视频数据外其他数据回调
        heartbeatConnection.setonHandleDataListener(this.onHandleDataListener)

        if (this.streamTcpConnection != null) {
          //创建视频流心跳
          this.streamTcpConnection = new StreamTcpConnection();
        }


      } else if (type == ExternalDevType.USB) {
        this.initUsb();
        console.log("usb连接成功=============")


      }

      this.connectionStatusListener?.onDeviceConnection();

      /*  promptAction.showToast({
          message: '连接判断',
          duration: 2000,  // 显示时长（毫秒）
          bottom: '500vp'   // 距屏幕底部距离
        });
        VideoStreamHandle.getInstance().create();*/

    },
    onDeviceDisconnection: (type: ExternalDevType) => {
      console.log(`设备断开：${type}`);
      this.stopDeviceTypeTask()
      //
      PlayInfo.initConfigure();
      this.connectionStatusListener?.onDeviceDisconnection();
    }
  };
  private connectionCallback: ConnectionCallback = {
    onStateChanged: (state: ConnectionState) => {
      console.log(`tcp连接状态：${state}`)
    },
    onDataReceived: (data: Uint8Array) => {
      //  console.log(`收到tcp数据：${ObjectUtils.arrayBufferToHex(data)}`)

    },
    onError: (errorMsg: string) => {
      console.log(`tcp连接出错：${errorMsg}`)
    }

  }
  private analysisListener: AnalysisListener = {
    data: (type: number, data?: Uint8Array) => {
      console.log(`收到蓝光功能字解析类型`, type);
      const context = this.context;
      this.sendEvent(type,data);
    }
  };


  private sendEvent(type: number, data?: Uint8Array) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: ProtocolManager.getInstance().getProtocol(),  // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };
   let  pageSendData:PageSendData=new PageSendData(ModeType.FlightControl,type,data);
    // 2. 创建要发送的数据
    const eventData:emitter.EventData  = {
      data:pageSendData
    };

    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }



  private onHandleDataListener: OnHandleDataListener = {
    onHandleData: (connectionType: ConnectionType, devTypes: ExternalDevType, data: Uint8Array) => {
      console.log(`处理数据 - 连接类型: ${connectionType}, 设备类型: ${devTypes}, 数据: ${ObjectUtils.arrayBufferToHex(data)}`);
      // 这里可以添加具体的数据处理逻辑
      // 示例：根据连接类型和设备类型进行不同处理
      switch (connectionType) {
        case ConnectionType.UDP:
          //处理udp数据
          DeviceInfoManager.getInstance().processDeviceInfo(data)
          break;
        case ConnectionType.TCP:
          console.log('判断回调', this.analysisListener)
          //处理TCP数据
          DataNoticeManager.getInstance().processTcpNotification(data, this.analysisListener)
          this.onTcpReceiveData(data)
          break;
      }
    }
  };

  /**
   * 开始设备类型检测任务的方法
   */
  private startDeviceTypeTask(period: number) {
    // 检查mDeviceTypeService是否为null，或者是否已经关闭或终止
    this.mDeviceTaskId = setInterval(() => {
      // 如果设备未连接，则尝试获取设备类型
      console.log(`类型检测任务正在执行:${PlayInfo.firmwareVer}:${!this.hasDevice()}:${PlayInfo.deviceId}:${PlayInfo.deviceType}`)
      if (!this.hasDevice()) {
        WifiCommandHelper.getDevType();
      }

    }, 500, period);


  }

  /**
   * 停止设备类型检测任务的方法
   */
  private stopDeviceTypeTask() {
    // 如果mDeviceTypeService存在，则关闭它，并将其设置为null
    // 取消任务（如组件销毁时）
    if (this.mDeviceTaskId !== null) {
      clearInterval(this.mDeviceTaskId);
      this.mDeviceTaskId = null;
    }
  }


  /**
   * 检查设备是否存在。
   * <p>
   * 此方法用于检查系统中是否存在所需的设备。如果设备信息对象{@code mDeviceInfo}为null，
   * 或者设备信息对象中没有检测到设备，则返回false，否则返回true。
   *
   * @return 如果设备存在返回true，否则返回false。
   */
  public hasDevice(): boolean {
    // 调用mDeviceInfo的hasDevice方法来检查设备是否存在
    return PlayInfo.deviceType != DeviceType.NONE || PlayInfo.deviceId != 0;
  }


  initUsb() {
    console.info('USB初始化开始');
    // 1. 初始化USB通信
    USBAccessoryCommunicator.getInstance().initializeAccessoryCommunication().then((isDefault: boolean) => {
      if (isDefault) {
        console.info('USB初始化成功');

        // 基础用法（显示在应用内）

        // 全局置顶模式（显示在应用之上）
      } else {

        console.info('USB初始化失败');
        return;
      }
    });

    // 2. 显示配件信息
    console.log(USBAccessoryCommunicator.getInstance().getAccessoryInfo());
    promptAction.showToast({
      message: '配件信息' + USBAccessoryCommunicator.getInstance().getAccessoryInfo(),
      duration: 2000, // 显示时长（毫秒）
      bottom: '50vp'   // 距屏幕底部距离
    });
    USBAccessoryCommunicator.getInstance().setonHandleDataListener(this.onHandleDataListener)

  }

  // 发送usb消息的方法
  writeUsbCmd(data: Uint8Array) {
   /* USBAccessoryCommunicator.getInstance().getConnected().then((isConnected: boolean) => {
      if (isConnected) {
        USBAccessoryCommunicator.getInstance().sendDataToAccessory(data)
      }
    })*/
    USBAccessoryCommunicator.getInstance().sendDataToAccessory(data)

  }

  /**
   * 发送UDP数据。
   *
   * @param data 要发送的数据的byte数组。
   */
  sendUDPCmd(data: Uint8Array) {
    //usb发送udp消息
    UsbWriteCommands.writeUDPCmd(data);
    //wifi发送udp消息
    this.writeUDPCmd(data);
  }


  sendTCPCmd(data: Uint8Array) {
    //usb发送udp消息
    UsbWriteCommands.writeTCPCmd(data);
    //wifi发送udp消息
  //  this.writeTCPCmd(data);
  }



  public setVideoHeartbeat(isHeartbeat: boolean) {
    //usb视频设置开始心跳
    USBAccessoryCommunicator.getInstance().setVideoHeartbeat(isHeartbeat);
    if (isHeartbeat) {
      //创建视频流tcp连接
      const streamTcpConnection = new StreamTcpConnection();
      // 建立连接后自动开始心跳
      streamTcpConnection.connect(new TcpConfig(WifiUtils.getWIFIIP(), EntryAbility.STREAM_PORT, 50000))
        .then(() => {
          console.log("Connected with heartbeat");
        });


      //初始化视频流循环buf
      VideoStreamHandle.getInstance().create();
    } else {
      VideoStreamHandle.getInstance().release();
    }

  }

  public setConnectionStatusListener(connectionStatusListener: ConnectionStatusListener) {
    this.connectionStatusListener = connectionStatusListener;
  }

  public onTcpReceiveData(data: Uint8Array): void {

    //处理杰理板数据处理问题
    try {
      if (ProtocolManager.getInstance().isNone()) {
        ProtocolManager.getInstance().checkProtocol(data);
      }
      if (ProtocolManager.getInstance().hasProtocol()) {
        DroneCodeManager.getInstance().setProtocol(ProtocolManager.getInstance().getProtocol());
        console.log("无人机协议", ProtocolManager.getInstance().getNewProtocolName());
        let parse = ParseUtils.newInstance(ProtocolManager.getInstance().getProtocol());
        if (parse != null) {
          let packet: MessagePacket | null;
          for (let bt of data) {
            packet = parse.parse_char(bt);
            if (packet != null) {
              DroneCodeManager.getInstance().processPacket(packet);
              console.log("1111111111", this.analysisListener)
              if (this.analysisListener) {
                ObserverManager.getInstance().subscribe(this.analysisListener, packet);
              }
            }
          }
        }
      }
    } catch (error) {
      console.error("TCP解析异常 " + JSON.stringify(error));
    }

    // initStreamThread();

  }

  public getOnHandleDataListener(): OnHandleDataListener {
    return this.onHandleDataListener;
  }
}