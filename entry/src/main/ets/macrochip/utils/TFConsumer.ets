import EntryAbility from "../../entryability/EntryAbility";
import { HisiCommandHelper } from "../../hisi/HisiCommandHelper";
import { PlayInfo } from "../../model/PlayInfo";


/**
 * TF卡操作管理器（整合轮询请求 + 格式化）
 * - 每5秒自动请求一次TF卡状态（轮询）
 * - 支持手动格式化SD卡
 */
export class TFConsumer {
  public static timerId: number | undefined;
  public static  isPolling: boolean = false;

  // 指令类型常量
  private static readonly REQUEST_STATE = 1;  // 请求状态
  private static readonly REQUEST_FORMAT = 2; // 格式化

  /**
   * 开始轮询（每5秒请求一次TF卡状态）
   */
  public static  start(): void {
    console.debug("Tf卡执行")
    if (TFConsumer.isPolling) {
      console.warn('Tf卡执行 轮训启动');
      return;
    }
    // 立即请求一次，避免等待第一个5秒
    TFConsumer.requestStatus();
    // 启动定时器
    TFConsumer.timerId = setInterval(() => {
      TFConsumer.requestStatus();
    }, 5000);
    TFConsumer.isPolling = true;
    console.info('Tf卡执行, interval = 5000ms');
  }

  /**
   * 停止轮询
   */
  public static stop(): void {
    if (TFConsumer.timerId !== undefined) {
      clearInterval(TFConsumer.timerId);
      TFConsumer.timerId = undefined;
    }
    TFConsumer.isPolling = false;
    console.info('TFStatusPoller stopped');
  }

  /**
   * 手动请求一次TF卡状态（不依赖轮询周期）
   */
  public static  requestStatus(): void {
    try {
      TFConsumer.sendRequest(TFConsumer.REQUEST_STATE);
    } catch (err) {
      console.error(`Request TF status failed: ${err}`);
    }
  }

  /**
   * 格式化SD卡
   * 注：格式化操作不会自动停止轮询，如有需要可先调用 stop()，格式化完成后重新 start()
   */
  public static  formatSD(): void {
    try {
      TFConsumer.sendRequest(TFConsumer.REQUEST_FORMAT);
      console.info('Format SD command sent');
    } catch (err) {
      console.error(`Format SD failed: ${err}`);
    }
  }

  /**
   * 发送指令（内部通用）
   * @param functionCode 1=请求状态，2=格式化
   */
  public static sendRequest(functionCode: number): void {
    console.debug("Tf卡执行 发送命令",PlayInfo.isHisi(),functionCode)
    if (PlayInfo.isHisi()) {
      // 海思平台
      if (functionCode === TFConsumer.REQUEST_STATE) {
        HisiCommandHelper.getSDInfo();
      } else if (functionCode === TFConsumer.REQUEST_FORMAT) {
        HisiCommandHelper.formatSD();
      }
    } else {
      // 非海思平台：通过UDP发送指令
      const data = new Uint8Array(5);
      data[0] = 0xFF;
      data[1] = 0x53;
      data[2] = 0x54;
      data[3] = 0x00;
      data[4] = functionCode;
      EntryAbility.getInstance().sendUDPCmd(data);
    }
  }

  /**
   * 获取当前轮询状态
   */
  public static getIsPolling(): boolean {
    return TFConsumer.isPolling;
  }
}