import EntryAbility from '../entryability/EntryAbility';
import { AnalysisListener } from '../listeners/AnalysisListener';
import  util  from '@ohos.util';
import {WifiCommandHelper} from '../helper/WifiCommandHelper';


@Entry
@Component
struct ceshi  {

  /*  private listener: AnalysisListener = {
      data:(type: number, data: Uint8Array)=> {
        // 实现逻辑
      }

    } ;*/



  build() {
    Column() {
      Button('获取WiFi IP')
        .onClick(() => {

          /* if (this.uiAbilityContext) {
             this.reqPermissionsFromUser(this.permissions,this.uiAbilityContext)
             console.error("执行");
           }else {
             console.error("uiAbilityContext为null，无法调用方法");
           }*/
          /*    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
              this.reqPermissionsFromUser(this.permissions, context);*/


        })
        .margin(20)

    }
    .width('100%')
    .height('100%')
  }



}