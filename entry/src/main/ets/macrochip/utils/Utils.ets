import { emitter } from "@kit.BasicServicesKit";
import { ModeType, PageSendData } from "../Drone/core/protocol/PageSendData";
import { ProtocolManager } from "../Drone/core/protocol/ProtocolManager";

export class Utils {
  //页面之间的数据通信
  public static  sendEvent(id:number,type: number,data?: Uint8Array) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: id,  // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };
    let  pageSendData:PageSendData=new PageSendData(ModeType.Page,type,data);
    // 2. 创建要发送的数据
    const eventData:emitter.EventData  = {
      data:pageSendData
    };

    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }
}