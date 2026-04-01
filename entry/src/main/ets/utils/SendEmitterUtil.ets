import { emitter } from "@kit.BasicServicesKit";
import { ModeType, PageSendData } from "../macrochip/Drone/core/protocol/PageSendData";
import { ProtocolManager } from "../macrochip/Drone/core/protocol/ProtocolManager";
import { geoLocationManager } from '@kit.LocationKit';

export class SendEmitterUtil {

  public  static  sendEvent(type: number, data?: Uint8Array, location?:geoLocationManager.Location) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: ProtocolManager.getInstance().getProtocol(),  // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };
    let  pageSendData:PageSendData=new PageSendData(ModeType.Page,type,data,location);
    // 2. 创建要发送的数据
    const eventData:emitter.EventData  = {
      data:pageSendData
    };

    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }

  //发送位置数据
  public static  sendEventLocation(type: number, location?:geoLocationManager.Location ) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: ProtocolManager.getInstance().getProtocol(),  // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };
    let  pageSendData:PageSendData=new PageSendData(ModeType.Page,type,undefined,location);
    // 2. 创建要发送的数据
    const eventData:emitter.EventData  = {
      data:pageSendData
    };

    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }

  //发送number数据
  public static  sendEventNumber(type: number, numberData:number ) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: ProtocolManager.getInstance().getProtocol(),  // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };
    let  pageSendData:PageSendData=new PageSendData(ModeType.Page,type,undefined,undefined,numberData);
    // 2. 创建要发送的数据
    const eventData:emitter.EventData  = {
      data:pageSendData
    };
    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }
}