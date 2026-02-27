import { common, Want } from '@kit.AbilityKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index{
  @State message: string = 'subscribe ukey event';
  @State oooo: string = '状态';

  build() {
    Row(){
      Column(){

        Button(this.message)
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.subscribeUkey();
          })
        Text(this.oooo)

      }
      .width('100%')
    }
  }

  subscribeUkey(){
    // 定义订阅者，用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
    let subscriber: commonEventManager.CommonEventSubscriber;

    //订阅者信息
    let subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_ATTACHED, //监听USB配件连接事件
        commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_DETACHED //监听USB配件断开事件
      ],
      priority: 1
    };

    // 创建订阅者
    let methodMark: string = 'testTag  ';
    try {
      commonEventManager.createSubscriber(subscribeInfo, (err:BusinessError, commonEventSubscriber:commonEventManager.CommonEventSubscriber) => {
        if (!err) {
          hilog.info(0, 'testTag', "创建订阅者");
          subscriber = commonEventSubscriber;
          //订阅公共事件
          try {
            commonEventManager.subscribe(subscriber, (err: BusinessError, data:commonEventManager.CommonEventData) => {
              if (err) {
                hilog.error(0, 'testTag', 'subscribe failed, code is ${err.code}, message is ${err.message}');
                this.oooo="失败3"
              } else {
                //监听到usb配件连接状态变化

                this.message =  "订阅事件 = " + data.event + ', code = ' + data.code;
                hilog.info(0, 'testTag', "subscribe event = " + data.event + ', code = ' + data.code);
                  if (data.event==commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_ATTACHED) {
                 //usb配件连接成功
                 this.oooo="usb配件连接成功"
               }else if (data.event==commonEventManager.Support.COMMON_EVENT_USB_ACCESSORY_DETACHED) {
                 //usb配件连接断开
                 this.oooo="usb配件连接断开"
               }
              }
            })
          } catch (error) {
            this.oooo="失败2"
            hilog.error(0, 'testTag', 'subscribe failed, code is ${error.code}, message is ${error.message}');
          }
        } else {
          this.oooo="失败1"
          hilog.error(0, 'testTag', 'createSubscriber failed, code is ${err.code}, message is ${err.message}');
        }
      });
    } catch (e) {
      let err:BusinessError = e as BusinessError;
      hilog.error(0, 'testTag', 'createSubscriber failed, code is ${err.code}, message is ${err.message}');
    }
  }
}

