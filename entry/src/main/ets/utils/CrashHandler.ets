import { AbilityConstant, UIAbility, errorManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import process from '@ohos.process';
import { LogManager } from '../Log/LogManager';

let registerId: number = -1;

export  const crashObserver: errorManager.ErrorObserver = {
  // 关键方法：捕获所有未处理的全局异常
  onUnhandledException(errMsg: string) {
    console.error(`捕获到崩溃: ${errMsg}`);
   /* // 在这里调用你的上传或记录函数
    uploadToMyServer(errMsg);*/
    // 然后在任何地方写入日志
    LogManager.getInstance().error("崩溃错误", errMsg);

    // 重要：必须同步退出进程，否则应用会反复崩溃
    process.exit(0);
  }
};