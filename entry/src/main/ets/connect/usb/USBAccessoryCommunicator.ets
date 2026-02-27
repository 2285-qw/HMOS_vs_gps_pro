import usbManager from '@ohos.usbManager';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
// 导入模块
import { worker } from '@kit.ArkTS';
import promptAction from '@ohos.promptAction';
import { UsbWriteCommands } from '../usb/UsbWriteCommands'
import NapiBuffer from 'libentry.so';
import { VideoStreamHandle } from '../../connect/stream/VideoStreamHandle';
import { ExternalDevType, OnDeviceConnectionListener } from '../../listeners/OnDeviceConnectionListener';
import commonEventManager from '@ohos.commonEventManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DeviceInfoManager } from '../manager/DeviceInfoManager';
import { ObjectUtils } from '../../utils/ObjectUtils';
import { ConnectionType, OnHandleDataListener } from '../../listeners/OnHandleDataListener';

export class USBAccessoryCommunicator {
  protected onHandleDataListener?: OnHandleDataListener;
  private accessoryHandle: usbManager.USBAccessoryHandle | null = null;
  private currentAccessory: usbManager.USBAccessory | null = null;
  private isConnected: boolean = false;
  private heartbeatTimer: number | null = null;
  private heartbeatInterval: number = 1000; // 默认5秒间隔

  private static instance: USBAccessoryCommunicator;
  private onDeviceConnectionListener?: OnDeviceConnectionListener;

  private isVideoHeartbeat:boolean=false;

  // 单例模式，确保唯一实例
  private constructor() {
  }

  static getInstance(): USBAccessoryCommunicator {
    if (!USBAccessoryCommunicator.instance) {
      USBAccessoryCommunicator.instance = new USBAccessoryCommunicator();
    }
    return USBAccessoryCommunicator.instance;
  }

  public setonDeviceConnectionListener(onDeviceConnectionListener: OnDeviceConnectionListener) {
    this.onDeviceConnectionListener = onDeviceConnectionListener;

  }

  //设置回调
  public setonHandleDataListener(callback: OnHandleDataListener): void {
    this.onHandleDataListener = callback;
  }


  /**
   * 初始化配件通信
   */
  async initializeAccessoryCommunication(): Promise<boolean> {
    try {
      console.log('开始初始化USBAccessory通信...');

      // 1. 获取配件列表
      const accessories = this.getAccessoryList();
      if (accessories.length === 0) {
        console.warn('未检测到USB配件');
        return false;
      }

      // 2. 选择配件（这里选择第一个）
      this.currentAccessory = accessories[0];
      console.log(`发现配件: ${this.currentAccessory.manufacturer} - ${this.currentAccessory.product}`);

      // 3. 检查并请求权限
      if (!await this.requestAccessoryRight(this.currentAccessory)) {
        return false;
      }

      // 4. 打开配件连接
      this.accessoryHandle = await this.openAccessory(this.currentAccessory);
      if (!this.accessoryHandle) {
        return false;
      }

      this.isConnected = true;
      console.log('USBAccessory通信初始化成功');
      promptAction.showToast({
        message: 'USBAccessory通信初始化成功' + this.accessoryHandle + '===' + this.isConnected,
        duration: 2000, // 显示时长（毫秒）
        bottom: '500vp'   // 距屏幕底部距离
      });

      // 5. 开始数据监听
      this.startDataListening();

      //发送心跳数据
      this.startHeartbeat();

      //初始化usb环形buf
      NapiBuffer.createUsbStream();


      //this.onDeviceConnectionListener?.onDeviceConnection(ExternalDevType.USB)


      return true;

    } catch (error) {
      this.handleUSBError(error);
      return false;
    }
  }

  /**
   * 获取配件列表
   */
  private getAccessoryList(): Array<usbManager.USBAccessory> {
    try {
      return usbManager.getAccessoryList();
    } catch (error) {
      if (error.code === 14400004) {
        console.log('没有配件接入');
      }
      return [];
    }
  }

  /**
   * 请求配件权限
   */
  private async requestAccessoryRight(accessory: usbManager.USBAccessory): Promise<boolean> {
    try {
      // 检查是否已有权限
      const hasRight = usbManager.hasAccessoryRight(accessory);
      if (hasRight) {
        console.log('已具有配件访问权限');
        return true;
      }

      // 请求权限
      console.log('请求配件访问权限...');
      const granted = await usbManager.requestAccessoryRight(accessory);

      if (granted) {
        console.log('配件权限获取成功');
        return true;
      } else {
        console.error('配件权限被拒绝');
        return false;
      }

    } catch (error) {
      this.handleUSBError(error);
      return false;
    }
  }

  /**
   * 打开配件连接
   */
  private async openAccessory(accessory: usbManager.USBAccessory): Promise<usbManager.USBAccessoryHandle | null> {
    try {
      const handle = usbManager.openAccessory(accessory);
      console.log(`配件打开成功，文件描述符: ${handle.accessoryFd}`);
      return handle;
    } catch (error) {
      this.handleUSBError(error);
      return null;
    }
  }

  /**
   * 通过文件描述符读写数据
   * 注意：需要配合@ohos.file.fs模块进行文件读写
   */
  async sendDataToAccessory(data: Uint8Array): Promise<number> {
    if (!this.isConnected || !this.accessoryHandle || this.accessoryHandle.accessoryFd <= 0) {
      throw new Error('配件未连接');
    }

    try {
      // 导入文件系统模块

      const fd = this.accessoryHandle.accessoryFd;
      const bytesWritten = fs.writeSync(fd, data.buffer, {
        offset: 0,
        length: data.length
      });

      console.log(`向配件发送 ${bytesWritten} 字节数据`);
      return bytesWritten;

    } catch (error) {
      console.error('发送数据失败:', error);
      throw new Error(`发送数据失败: ${error.message}`);
    }
  }

  /**
   * 从配件接收数据
   */
  async receiveDataFromAccessory(bufferSize: number): Promise<Uint8Array> {
    if (!this.isConnected || !this.accessoryHandle || this.accessoryHandle.accessoryFd <= 0) {
      throw new Error('配件未连接');
    }

    try {

      const fd = this.accessoryHandle.accessoryFd;
      const buffer = new ArrayBuffer(bufferSize);
      const bytesRead = fs.readSync(fd, buffer, {
        offset: 0,
        length: bufferSize
      });

      if (bytesRead > 0) {
        const data = new Uint8Array(buffer, 0, bytesRead);
        console.log(`从配件接收 ${bytesRead} 字节数据`);
        return data;
      }

      return new Uint8Array(0);

    } catch (error) {
      console.error('接收数据失败:', error);
      throw new Error(`接收数据失败: ${error.message}`);
    }
  }

  worker2: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/UsbBufWorker.ets');




  /**
   * 异步读取数据（非阻塞）
   */
  startAsyncReading(bufferSize: number = 1024): void {
    if (!this.isConnected || !this.accessoryHandle) {
      console.error('异步读取数据进入失败');
      return;
    }

    // 使用Worker线程进行异步读取
    const workerS: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/getUsbWorker.ets');

    workerS.onmessage = (event) => {

    };

    workerS.onerror = (error) => {
      console.error('Worker错误:', error);
    };

    workerS.postMessage({
      type: 'start_reading',
      fd: this.accessoryHandle!.accessoryFd,
      bufferSize: bufferSize
    });

    // 使用Worker线程进行异步读取
    this.worker2.onmessage = (event) => {
      if (event.data.type == "TOAST") {
        //无用弹窗
        promptAction.showToast({
          message: event.data.text,
          duration: 2000, // 显示时长（毫秒）
          bottom: '600vp'   // 距屏幕底部距离
        });
      } else if (event.data.type == "usbdata") {
        const header: Array<number> = event.data.header;
        let newData: Uint8Array = event.data.data;
        if (header[2] == 0x0a || header[2] == 0x03) {
          //视频流类型
          //传入数据解码
          const uint8Array = new Uint8Array(newData);
          VideoStreamHandle.getInstance().addVideoStream(uint8Array, header[1])

         // console.log("newData======video", "newData=" + newData);
        }else if (header[2] == 0x06) {
          //udp连接类型
          const uint8Array = new Uint8Array(newData);
          console.log("收到udp数据", "uint8Array=" + ObjectUtils.arrayBufferToHex(uint8Array), this.onHandleDataListener);
          this.onHandleDataListener?.onHandleData(ConnectionType.UDP,ExternalDevType.USB,uint8Array)
        } else if (header[2] == 0x05) {
          //TCP连接类型
         // DeviceInfoManager.getInstance().processDeviceInfo(newData)
          const uint8Array = new Uint8Array(newData);
          this.onHandleDataListener?.onHandleData(ConnectionType.TCP,ExternalDevType.USB,uint8Array)
          console.log("收到TCP数据", "uint8Array=" + ObjectUtils.arrayBufferToHex(uint8Array), this.onHandleDataListener);
        }
      }
    }
    //开启读取usb数据
    this.worker2.postMessage({
      type: 'startCUsb',
    });
  }


  /**
   *
   */
  private handleIncomingData(data: Uint8Array): void {
    // 这里处理接收到的数据
    console.log('接收到配件数据:', data);
    // 2. 显示配件信息


    // 示例：解析数据
    if (data.length > 0) {
      const command = data[0];
      switch (command) {
        case 0x01:
          this.handleCommand1(data);
          break;
        case 0x02:
          this.handleCommand2(data);
          break;
        default:
          console.log('未知命令:', command);
      }
    }
  }

  /**
   * 开始数据监听
   */
  private startDataListening(): void {
    // 启动异步读取
    this.startAsyncReading(1024*10);

    // 或者使用轮询方式
    // this.startPolling();
  }

  /**
   * 轮询方式读取数据
   */
  private startPolling(interval: number = 100): void {
    setInterval(async () => {
      try {
        const data = await this.receiveDataFromAccessory(1024);
        if (data.length > 0) {
          this.handleIncomingData(data);
        }
      } catch (error) {
        // 忽略读取错误，可能是没有数据
      }
    }, interval);
  }

  /*  */
  /**
   * 发送文本数据到配件
   */
  /*
    async sendText(text: string, encoding: string = 'utf-8'): Promise<number> {
      const encoder = new TextEncoder();
      const data = encoder.encode(text);
      return await this.sendDataToAccessory(data);
    }

    *//**
   * 接收文本数据
   */
  /*
    async receiveText(bufferSize: number = 1024): Promise<string> {
      const data = await this.receiveDataFromAccessory(bufferSize);
      const decoder = new TextDecoder('utf-8');
      return decoder.decode(data);
    }*/

  /**
   * 发送带格式的数据包
   */
  async sendPacket(packetType: number, payload: Uint8Array): Promise<number> {
    // 创建数据包：类型(1字节) + 长度(2字节) + 数据
    const length = payload.length;
    const packet = new Uint8Array(3 + length);

    packet[0] = packetType; // 包类型
    packet[1] = (length >> 8) & 0xFF; // 长度高字节
    packet[2] = length & 0xFF; // 长度低字节

    packet.set(payload, 3); // 数据负载

    return await this.sendDataToAccessory(packet);
  }

  /*  */
  /**
   * 解析数据包
   */
  /*
    private parsePacket(data: Uint8Array): { type: number, payload: Uint8Array } | null {
      if (data.length < 3) {
        return null;
      }

      const type = data[0];
      const length = (data[1] << 8) | data[2];

      if (data.length < 3 + length) {
        return null;
      }

      const payload = data.slice(3, 3 + length);
      return { type, payload };
    }*/

  /**
   * 错误处理
   */
  private handleUSBError(error: BusinessError): void {
    console.error('USB错误:', error);

    // 根据错误码处理
    if (error.code) {
      switch (error.code) {
        case 14400001:
          console.error('访问权限被拒绝');
          break;
        case 14400004:
          console.error('服务异常，配件可能未连接');
          break;
        case 14401001:
          console.error('目标配件不匹配');
          break;
        case 14401002:
          console.error('无法打开配件节点');
          break;
        default:
          console.error(`USB错误码: ${error.code}`);
      }
    }
  }

  /**
   * 关闭配件连接
   */
  close(): void {
    promptAction.showToast({
      message: '配件断开',
      duration: 2000, // 显示时长（毫秒）
      bottom: '50vp'   // 距屏幕底部距离
    });
    // this.onDeviceConnectionListener?.onDeviceDisconnection(ExternalDevType.USB)

    if (this.accessoryHandle) {
      try {
        usbManager.closeAccessory(this.accessoryHandle);
        console.log('配件连接已关闭');
      } catch (error) {
        console.error('关闭配件连接失败:', error);
      } finally {
        this.accessoryHandle = null;
        this.currentAccessory = null;
        this.isConnected = false;
      }
    }
    this.worker2.postMessage({
      type: 'stopUsb',
    });
  }

  /**
   * 获取配件信息
   */
  getAccessoryInfo(): string {
    if (!this.currentAccessory) {
      return '无配件信息';
    }

    return `
      USBAccessory信息:
      制造商: ${this.currentAccessory.manufacturer}
      产品: ${this.currentAccessory.product}
      描述: ${this.currentAccessory.description}
      版本: ${this.currentAccessory.version}
      序列号: ${this.currentAccessory.serialNumber}
    `;
  }

  // 示例命令处理函数
  private handleCommand1(data: Uint8Array): void {
    console.log('处理命令1:', data);
    // 具体处理逻辑
  }

  private handleCommand2(data: Uint8Array): void {
    console.log('处理命令2:', data);
    // 具体处理逻辑
  }

  async getConnected(): Promise<boolean> {
    return this.isConnected;
  }

  // 开启心跳定时器
  async startHeartbeat() {
    if (!this.isConnected || !this.accessoryHandle || this.accessoryHandle.accessoryFd <= 0) {
      promptAction.showToast({
        message: '开启心跳定时器失败' + this.accessoryHandle + '===' + this.isConnected,
        duration: 2000, // 显示时长（毫秒）
        bottom: '50vp'   // 距屏幕底部距离
      });
      return
    }
    promptAction.showToast({
      message: '开启心跳定时器',
      duration: 2000, // 显示时长（毫秒）
      bottom: '50vp'   // 距屏幕底部距离
    });


    this.heartbeatTimer = setInterval(() => {
      UsbWriteCommands.writeHeartbeat();
      if (this.isVideoHeartbeat) {
        //视频心跳
        UsbWriteCommands.writeVideoHeartbeat();
      }
      UsbWriteCommands.writeTcpHeartbeat();

    }, this.heartbeatInterval);
  }

  //监听usb连接状态
  public subscribeUsb() {
    // 定义订阅者，用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
    let subscriber: commonEventManager.CommonEventSubscriber;

    //订阅者信息
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_ATTACHED, //监听USB配件连接事件
        commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_DETACHED//监听USB配件断开事件
      ],
      priority: 1
    };
    // 创建订阅者
    try {
      commonEventManager.createSubscriber(subscribeInfo,
        (err: BusinessError, commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
          if (!err) {
            hilog.info(0, 'testTag', "创建订阅者");
            subscriber = commonEventSubscriber;
            //订阅公共事件
            try {
              commonEventManager.subscribe(subscriber,
                (err: BusinessError, data: commonEventManager.CommonEventData) => {
                  if (err) {
                    hilog.error(0, 'testTag', 'subscribe failed, code is ${err.code}, message is ${err.message}');
                  } else {
                    //监听到usb配件连接状态变化

                    if (data.event == commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_ATTACHED) {
                      //usb配件连接成功
                      //this.initUsb();
                      console.log("usb配件连接成功");
                      this.onDeviceConnectionListener?.onDeviceConnection(ExternalDevType.USB)

                    } else if (data.event == commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_DETACHED) {
                      //usb配件连接断开
                      this.onDeviceConnectionListener?.onDeviceDisconnection(ExternalDevType.USB)
                      console.log("usb配件断开");
                      VideoStreamHandle.getInstance().isCreate_f(false)
                      USBAccessoryCommunicator.getInstance().close();
                    }
                  }
                })
            } catch (error) {
              hilog.error(0, 'testTag', 'subscribe failed, code is ${error.code}, message is ${error.message}');
            }
          } else {
            hilog.error(0, 'testTag', 'createSubscriber failed, code is ${err.code}, message is ${err.message}');
          }
        });
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      hilog.error(0, 'testTag', 'createSubscriber failed, code is ${err.code}, message is ${err.message}');
    }
  }

  public  setVideoHeartbeat(isVideoHeartbeat:boolean){
    this.isVideoHeartbeat=isVideoHeartbeat;
  }
}