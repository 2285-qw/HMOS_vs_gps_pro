import {AnalysisListener } from '../../listeners/AnalysisListener';
import TextDecoder from '@ohos.util';
import { ObjectUtils } from '../../utils/ObjectUtils';
import { SwitchType } from '../../model/SwitchType';

export class DataNoticeManager {
  private static instance: DataNoticeManager;
  private strShotName: string = '';
  private mRemoteRecord: boolean = false;

  // 单例模式，确保唯一实例
  private constructor() {}
  static getInstance(): DataNoticeManager {
    if (!DataNoticeManager.instance) {
      DataNoticeManager.instance = new DataNoticeManager();
    }
    return DataNoticeManager.instance;
  }

  // 将Uint8Array转换为字符串
  private bytesToString(data: Uint8Array): string {
    return new TextDecoder.TextDecoder().decode(data);
  }

  public processUdpNotification(data: Uint8Array, analysisListener: AnalysisListener) {
    if (data.length >= 5 && data[0] == 0xff && data[1] == 0x53 && data[2] == 0x54) {
      if (data[3] == 0x08) {
        //获取到板型号
        const uint8: Uint8Array = new Uint8Array([data[4], data[5]]);

        analysisListener.data(1, data);

        const str = new TextDecoder.TextDecoder().decode(uint8);
        console.log(str); // 输出："Hello"

      }
    }
  }

  public processTcpNotification(data: Uint8Array, analysisListener?: AnalysisListener) {
    try {
      if (data.length >= 5 && data[0] == 0x70 && data[1] == 0x68 && data[2] == 0x6f && data[3] == 0x74) {
        const photo = data[4];
        if (photo == 0x6f) {
          // photo
          if (analysisListener != null) {
            analysisListener?.data(SwitchType.NOTIFY_REMOTE_PHOTO);
          }
        } else if (photo == 0x31 || photo == 0x32) {
          // 70686f7431=phot1 70686f7432=phot2
          const phot = this.bytesToString(data);
          if (phot !== this.strShotName) {
            if (analysisListener != null) {
              analysisListener.data(SwitchType.NOTIFY_REMOTE_PHOTO);
            }
          }
          this.strShotName = phot;
        }
      } else if (data.length >= 3 && data[0] == 0x72 && data[1] == 0x65 && data[2] == 0x63) {
        // 7265636f7274=recort
        if (!this.mRemoteRecord) {
          if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_REMOTE_RECORD_START);
          }
          this.mRemoteRecord = true;
        }
      } else if (data.length >= 3 && data[0] == 0x73 && data[1] == 0x74 && data[2] == 0x6f) {
        // 73746f70=stop
        if (this.mRemoteRecord) {
          if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_REMOTE_RECORD_STOP);
          }
          this.mRemoteRecord = false;
        }
      }
    } catch (e) {
      console.error(`处理TCP数据: ${e instanceof Error ? e.message : String(e)}`);
    }
  }






}