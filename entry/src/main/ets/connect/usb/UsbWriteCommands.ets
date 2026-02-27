import {PlayInfo} from "../../model/PlayInfo"
import { ObjectUtils } from '../../utils/ObjectUtils'
import  EntryAbility  from '../../entryability/EntryAbility';

export  class UsbWriteCommands{
  public static HEAD_LENGTH:number = 11; // 数据头长度
  public static HEARTBEAT_DATA:Uint8Array  = new Uint8Array([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09]); // 心跳数据
  public static heart28:Uint8Array = new Uint8Array([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x28, 0x28]);
  public static heart30:Uint8Array = new Uint8Array([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x30, 0x30]);
  public static  mHeartbeatData:Uint8Array = this.heart28;
  public static heartId28:number = 0x03;
  public static  heartId30 = 0x0a;
  public static mHeartbeatId:number = this.heartId28;
  public static writeIndex = 0;


// // 供外部自定义数据写入
// public  writeCustomCmd(data:Uint8Array, id:number) {
//   // 封装数据 头+序号+长度+功能+校验+data
//  let  intactData:Uint8Array = new Uint8Array(this.HEAD_LENGTH + data.length);
//   intactData[0] = 0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, data);
//   byte [] dataId=ObjectUtils.intTo2Bytes(id);
//   // 功能ID
//   intactData[7] = dataId[0];
//   intactData[8] = dataId[1];
//   addCheck(intactData, data);
//   System.arraycopy(data, 0, intactData, HEAD_LENGTH, data.length);
//
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
public static  writeUDPCmd( data:Uint8Array) {
  // 封装数据 头+序号+长度+功能+校验+data
  const  intactData = new Uint8Array(UsbWriteCommands.HEAD_LENGTH + data.length);
  intactData[0] =  0xFF;
  intactData[1] =  0x56;
  intactData[2] =  0x53;
  UsbWriteCommands.addIndex(intactData);
  UsbWriteCommands.addDataLength(intactData, data);
  // 功能ID
  intactData[7] =  0x06;
  intactData[8] =  0x00;
  UsbWriteCommands.addCheck(intactData, data);
  intactData.set(data,UsbWriteCommands.HEAD_LENGTH);
 // console.info( ObjectUtils.arrayBufferToHex(intactData),'-----------====')
  EntryAbility.getInstance().writeUsbCmd(intactData);
}
//
public static writeTCPCmd(data: Uint8Array) {
  // 封装数据 头+序号+长度+功能+校验+data
  const intactData = new Uint8Array(UsbWriteCommands.HEAD_LENGTH + data.length);
  intactData[0] = 0xFF;
  intactData[1] = 0x56;
  intactData[2] = 0x53;
  UsbWriteCommands.addIndex(intactData);
  UsbWriteCommands.addDataLength(intactData, data);
  // 功能ID
  intactData[7] = 0x05;
  intactData[8] = 0x00;
  UsbWriteCommands.addCheck(intactData, data);
  intactData.set(data, UsbWriteCommands.HEAD_LENGTH);

  EntryAbility.getInstance().writeUsbCmd(intactData);
}
//
/**
 * USB通讯心跳
 */
public static writeHeartbeat() {
  //LogUtils.d("USB通讯心跳");
  // 封装数据 头+序号+长度+功能+校验+data
 const  intactData = new Uint8Array(UsbWriteCommands.HEAD_LENGTH + UsbWriteCommands.HEARTBEAT_DATA.length);
  intactData[0] =  0xFF;
  intactData[1] =  0x56;
  intactData[2] =  0x53;
  UsbWriteCommands.addIndex(intactData);
  UsbWriteCommands.addDataLength(intactData, UsbWriteCommands.HEARTBEAT_DATA);
  // 功能ID
  intactData[7] =  0x01;
  intactData[8] =  0x00;
  UsbWriteCommands.addCheck(intactData, UsbWriteCommands.HEARTBEAT_DATA);
  //System.arraycopy( UsbWriteCommands.HEARTBEAT_DATA, 0, intactData, UsbWriteCommands.HEAD_LENGTH,  UsbWriteCommands.HEARTBEAT_DATA.length);

  //console.info( ObjectUtils.arrayBufferToHex(intactData),'-----------====')
  intactData.set(UsbWriteCommands.HEARTBEAT_DATA,UsbWriteCommands.HEAD_LENGTH);
  //console.info( ObjectUtils.arrayBufferToHex(intactData),'-----------====')
  EntryAbility.getInstance().writeUsbCmd(intactData);
  //UsbTransportManager.getInstance().writeData(intactData);
}

/**
 * 视频请求数据心跳
 */
  public static  writeVideoHeartbeat() {
  // 封装数据 头+序号+长度+功能+校验+data
  // LogUtils.d("视频请求数据心跳");
 const  heartbeatData = UsbWriteCommands.mHeartbeatData;
  let  intactData = new Uint8Array( UsbWriteCommands.HEAD_LENGTH + heartbeatData.length);
  intactData[0] =  0xFF;
  intactData[1] =  0x56;
  intactData[2] =  0x53;
    UsbWriteCommands.addIndex(intactData);
    UsbWriteCommands.addDataLength(intactData, heartbeatData);
  // 功能ID
  intactData[7] =  UsbWriteCommands.mHeartbeatId;
  intactData[8] =  0x00;
    UsbWriteCommands.addCheck(intactData, heartbeatData);
 // System.arraycopy(heartbeatData, 0, intactData, HEAD_LENGTH, heartbeatData.length);
  intactData.set(heartbeatData, UsbWriteCommands.HEAD_LENGTH);

  //BaseApplication.getInstance().sendUsbMessage(intactData);
  // console.info( ObjectUtils.arrayBufferToHex(intactData),'-----------视频')
  EntryAbility.getInstance().writeUsbCmd(intactData);
  //        UsbTransportManager.getInstance().writeData(intactData);
}

/**
 * tcp 通讯心跳
 */
public static  writeTcpHeartbeat() {
  // LogUtils.d("TCP通讯心跳");
  // 封装数据 头+序号+长度+功能+校验+data
  const  heartbeatData:Uint8Array = new Uint8Array([0x0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x25, 0x25]);
  const intactData:Uint8Array= new Uint8Array(UsbWriteCommands.HEAD_LENGTH + heartbeatData.length);
  intactData[0] =  0xFF;
  intactData[1] =  0x56;
  intactData[2] =  0x53;
  UsbWriteCommands.addIndex(intactData);
  UsbWriteCommands.addDataLength(intactData, heartbeatData);
  // 功能ID
  intactData[7] =  0x05;
  intactData[8] =  0x00;
  UsbWriteCommands.addCheck(intactData, heartbeatData);
 // System.arraycopy(heartbeatData, 0, intactData, this.HEAD_LENGTH, heartbeatData.length);
  // 使用 set() 方法实现复制
  intactData.set(heartbeatData, UsbWriteCommands.HEAD_LENGTH);

  EntryAbility.getInstance().writeUsbCmd(intactData);

}
//
// /**
//  * 获取中继连接状态
//  */
// public  requestRelayConnectStatus() {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{0x00};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x07;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
// /**
//  * 拍照
//  */
// public  photograph(boolean readRemoteImage) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = RemoteImageHelper.remote(readRemoteImage);
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x04;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
// /**
//  * USB定频开关
//  */
// public  writeFixedFrequency(int onOff) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ onOff};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x09;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
//
// /**
//  * 读取远程相册所有照片名称
//  */
// public  readRemotePictures() {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x0b;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
// /**
//  * 读取远程相册所有视频名称
//  */
// public  readRemoteVideo() {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x0e;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
//
// /**
//  * 下载远程相册所有视频名称
//  */
// public  downloadRemoteVideo(byte[] videoName) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[10 + sendData.length];
//   byte[] result;
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, videoName);
//   // 功能ID
//   intactData[7] =  0x0f;
//   intactData[8] =  0x00;
//   result = Arrays.copyOf(intactData, intactData.length + videoName.length);
//   System.arraycopy(videoName, 0, result, 11, videoName.length);
//
//   addCheck(result, videoName);
//   //        UsbTransportManager.getInstance().writeData(result);
//   BaseApplication.getInstance().sendUsbMessage(result);
// }
//
//
// /**
//  * 下载远程相册所有照片名称
//  */
// public  downloadRemotePictures(byte[] photoName) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[10 + sendData.length];
//   byte[] result;
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, photoName);
//   // 功能ID
//   intactData[7] = 0x0c;
//   intactData[8] =  0x00;
//   result = Arrays.copyOf(intactData, intactData.length + photoName.length);
//   System.arraycopy(photoName, 0, result, 11, photoName.length);
//
//   addCheck(result, photoName);
//   //        UsbTransportManager.getInstance().writeData(result);
//   BaseApplication.getInstance().sendUsbMessage(result);
// }
//
// /**
//  * 删除媒体数据
//  */
// public  deleteRemoteMedia(byte[] photoName) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[10 + sendData.length];
//   byte[] result;
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, photoName);
//   // 功能ID
//   intactData[7] =  0x10;
//   intactData[8] =  0x00;
//   result = Arrays.copyOf(intactData, intactData.length + photoName.length);
//   System.arraycopy(photoName, 0, result, 11, photoName.length);
//
//   addCheck(result, photoName);
//   //        UsbTransportManager.getInstance().writeData(result);
//   BaseApplication.getInstance().sendUsbMessage(result);
// }
//
// /**
//  * 中断远程相册下载
//  */
// public  interruptDownload() {
//   // 封装数据 头+序号+长度+功能+校验+data
//   LogUtils.d("USB发送中断下载");
//   LogManager.getInstance().addLog("USB发送中断下载");
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x0d;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
// /**
//  * 读取遥控器状态
//  */
// public  readRemoteControlStatus() {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x11;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
// /**
//  * 切换功率 1 低功率 2 高功率
//  */
// public  switchPower(int type) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ type};
//   byte[] intactData = new byte[HEAD_LENGTH + sendData.length];
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, sendData);
//   // 功能ID
//   intactData[7] =  0x12;
//   intactData[8] =  0x00;
//   addCheck(intactData, sendData);
//   System.arraycopy(sendData, 0, intactData, HEAD_LENGTH, sendData.length);
//   //        UsbTransportManager.getInstance().writeData(intactData);
//   BaseApplication.getInstance().sendUsbMessage(intactData);
// }
//
// public  relayUpgrade(byte[] data) {
//   // 封装数据 头+序号+长度+功能+校验+data
//   byte[] sendData = new byte[]{ 0};
//   byte[] intactData = new byte[10 + sendData.length];
//   byte[] result;
//   intactData[0] =  0xFF;
//   intactData[1] =  0x56;
//   intactData[2] =  0x53;
//   addIndex(intactData);
//   addDataLength(intactData, data);
//   // 功能ID
//   intactData[7] =  0x14;
//   intactData[8] =  0x00;
//   result = Arrays.copyOf(intactData, intactData.length + data.length);
//   System.arraycopy(data, 0, result, 11, data.length);
//
//   addCheck(result, data);
//   //        UsbTransportManager.getInstance().writeData(result);
//   BaseApplication.getInstance().sendUsbMessage(result);
// }
//
// 添加序号
  public static  addIndex( intactData:Uint8Array) {
    UsbWriteCommands.writeIndex++;
  let  MAX = 65535;
  if (UsbWriteCommands.writeIndex > MAX) {
    UsbWriteCommands.writeIndex = 0;
  }

  let  indexData = ObjectUtils.intTo2Bytes(UsbWriteCommands.writeIndex);
  // 固定 3~4 是序号
  intactData[3] = indexData[0];
  intactData[4] = indexData[1];
}

  public static  addDataLength(intactData:Uint8Array, data:Uint8Array) {
let  dataLength = ObjectUtils.intTo2Bytes(data.length);
  // 固定 5~6 是序号
  intactData[5] = dataLength[0];
  intactData[6] = dataLength[1];
}

  public static  addCheck(intactData:Uint8Array,data:Uint8Array) {
  let  check = 0;
  for ( let datum of data) {
    check ^= datum;
  }
  // 固定 9~10 是序号
  intactData[9] = check;
  //        intactData[10] = checkData[1];
}

/**
 * 刷新心跳包
 */
  public static changeHeart() {
  if (PlayInfo.cameraIndex == 0) {
    UsbWriteCommands.mHeartbeatData = UsbWriteCommands.heart28;
    UsbWriteCommands.mHeartbeatId = UsbWriteCommands.heartId28;
  } else {
    UsbWriteCommands.mHeartbeatData = UsbWriteCommands.heart30;
    UsbWriteCommands.mHeartbeatId = UsbWriteCommands.heartId30;
  }
}

}