import { VideoPage } from './VideoPage';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
struct BasePage {
  @State message: string = 'Hello World';

  build() {
    Column() {
      VideoPage()
      Button('发送事件')
        .onClick(() => {
          this.sendEvent();
        })
    }
    .width('100%')
    .height('100%')
  }

  private sendEvent() {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: 1001,  // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };
    
    // 2. 创建要发送的数据
    const eventData:emitter.EventData  = {
      data:{ text: "测试文本" }
    };
    
    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }
}