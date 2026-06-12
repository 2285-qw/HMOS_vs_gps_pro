import { AnalysisListener } from '../../listeners/AnalysisListener';
import TextDecoder from '@ohos.util';
import { ObjectUtils } from '../../utils/ObjectUtils';
import { SwitchType } from '../../model/SwitchType';
import { WifiCommandHelper } from '../../helper/WifiCommandHelper';
import { ConnectConfig } from '../../utils/ConnectConfig';
import { PlayInfo } from '../../model/PlayInfo';
import { DeviceStatus } from '../../SDK/DeviceStatus';
import { SendEmitterUtil } from '../../utils/SendEmitterUtil';

export class DataNoticeManager {
  private static instance: DataNoticeManager;
  private strShotName: string = '';
  private mRemoteRecord: boolean = false;

  // 单例模式，确保唯一实例
  private constructor() {
  }

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

  public processUdpNotification(data: Uint8Array, analysisListener?: AnalysisListener) {
    console.debug("收到udp数据==="+ObjectUtils.arrayBufferToHex(data))
    if (data.length >= 5 && data[0] == 0x70 && data[1] == 0x68 && data[2] == 0x6f && data[3] == 0x74) {
      //70686f746f photo
      /* if (analysisListener != null) {
        // analysisListener.data(SwitchType.NOTIFY_REMOTE_PHOTO);
       }*/
      SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_PHOTO)
    } else if (data.length >= 5 && data[0] == 0x72 && data[1] == 0x65 && data[2] == 0x63 && data[3] == 0x6f) {
      //7265636f7264 record
      /* if (analysisListener != null) {
         analysisListener.data(SwitchType.NOTIFY_REMOTE_RECORD);
       }*/
      SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_RECORD)
    } else if (WifiCommandHelper.checkFF5354(data)) {
      // ff5354
      if (data[3] == 0x00 && data[4] == 0x01 && data[5] == 0x00) { //没有TF卡
        //LogUtils.d("SD卡", "没有TF卡");
        ConnectConfig.TF_CARD_REMAIN_SPACE = 0;
        ConnectConfig.TF_CARD_TOTAL_SPACE = 0;
        /*  if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_NO_CARD);
          }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_RECORD)
        //  EventBus.getDefault().post(NotifyEvent.SD_NO_CARD);

      } else if (data[3] == 0x00 && data[4] == 0x01 && (data[5] == 0x01 || data[5] == 0x02)) {
        //说明卡没有p1分区，需要格式化.说明卡的分区大小不是64K，需要格式化
        /*  if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_FORMAT);
          }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT)
        // EventBus.getDefault().post(NotifyEvent.SD_NEED_FORMAT);
      } else if (data[3] == 0x00 && data[4] == 0x01 && data[5] == 0x03) {
        //TF卡正常
        if (data.length >= 9) {
          //剩余容量
          ConnectConfig.TF_CARD_REMAIN_SPACE =
            ObjectUtils.byteArrayToInt(new Uint8Array([0x00, data[6], data[7], data[8]]));
        }

        if (data.length >= 12) {
          //总容量
          ConnectConfig.TF_CARD_TOTAL_SPACE =
            ObjectUtils.byteArrayToInt(new Uint8Array([0x00, data[9], data[10], data[11]]));
        }

        // 有数据时处理TF卡数据,处理示例
        if (ConnectConfig.TF_CARD_REMAIN_SPACE != 0 || ConnectConfig.TF_CARD_TOTAL_SPACE != 0) {
          let remainSpace = ConnectConfig.TF_CARD_REMAIN_SPACE / 1024;
          let totalSpace = ConnectConfig.TF_CARD_TOTAL_SPACE / 1024
          PlayInfo.sdRemainSpace = remainSpace;
          PlayInfo.sdTotalSpace = totalSpace;
          //                        String info = String.format(Locale.getDefault(), "%.2fG/%.2fG", remainSpace, totalSpace);
        }

        /* if (analysisListener != null) {
           analysisListener.data(SwitchType.NOTIFY_TF_EXIST_CARD);
         }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_EXIST_CARD)
        //  EventBus.getDefault().post(NotifyEvent.SD_HAS_CARD_INFO);

      } else if (data[3] == 0x00 && data[4] == 0x01 && data[5] == 0x04) {
        //需要重新插拔卡
        ConnectConfig.TF_CARD_REMAIN_SPACE = 0;
        ConnectConfig.TF_CARD_TOTAL_SPACE = 0;
        /* if (analysisListener != null) {
           analysisListener.data(SwitchType.NOTIFY_TF_NEED_PLUG);
         }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_NEED_PLUG)
        //EventBus.getDefault().post(NotifyEvent.SD_NEED_PLUG);
      } else if (data[3] == 0x00 && data[4] == 0x02 && data[5] == 0x00) {
        //开始格式化卡
        /*  if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_FORMAT_BEGIN);
          }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT_BEGIN)
        //  EventBus.getDefault().post(NotifyEvent.SD_FORMAT_BEGIN);
      } else if (data[3] == 0x00 && data[4] == 0x02 && data[5] == 0x01) {
        //格式化失败
        /* if (analysisListener != null) {
           analysisListener.data(SwitchType.NOTIFY_TF_FORMAT_FAIL);
         }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT_FAIL)
        // EventBus.getDefault().post(NotifyEvent.SD_FORMAT_FAIL);
      } else if (data[3] == 0x00 && data[4] == 0x02 && data[5] == 0x02) {
        //格式化成功
        /*  if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_FORMAT_FINISHED);
          }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT_FINISHED)

      } else if (data[3] == 0x08) {
        // wifi信号强度
        PlayInfo.wifiStrength = data[4];

        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_WIFI_STRENGTH)
      } else if (data[3] == 0x52) {
        // 遥控信号强度
        PlayInfo.rcStrength = data[4];
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_RC_STRENGTH)
      } else if (data[3] == 0x76) {
        //LogUtils.d(data.length,ObjectUtils.bytesToHexString(data));
        const bytes: Uint8Array = data.slice(4);

        PlayInfo.deviceStatusInfo = DeviceStatus.DeviceStatusParser(bytes);
        // EventBus.getDefault().post(NotifyEvent.NOTIFY_DEVICE_STATUS_INFO);
        //LogUtils.d("deviceStatusInfo",PlayInfo.deviceStatusInfo.sdState,PlayInfo.deviceStatusInfo.sdFreeSize,PlayInfo.deviceStatusInfo.sdTotalSize);
        //LogUtils.d("deviceStatusInfo",PlayInfo.deviceStatusInfo.toString());
        //LogUtils.d("deviceStatusInfo","Wi-Fi："+PlayInfo.deviceStatusInfo.wifiSignalStrength +" 4G："+PlayInfo.deviceStatusInfo.live4gSignalStrength);
        /*  if (statusInfoListener != null) {
            statusInfoListener.onDeviceStatus(PlayInfo.deviceStatusInfo);
          }*/

        if (PlayInfo.deviceStatusInfo.sdState == 0) {
          //ff35190a2e 00 0000000edd28 000000000df7790000

          // 有数据时处理TF卡数据,处理示例
          if (PlayInfo.deviceStatusInfo.sdTotalSize != 0 || ConnectConfig.TF_CARD_TOTAL_SPACE != 0) {
            let remainSpace = PlayInfo.deviceStatusInfo.sdFreeSize / 1024 / 1024 / 1024;
            let totalSpace = PlayInfo.deviceStatusInfo.sdTotalSize / 1024 / 1024 / 1024;
            PlayInfo.sdRemainSpace = remainSpace;
            PlayInfo.sdTotalSpace = totalSpace;

            /*   if (analysisListener != null) {
                 analysisListener.data(SwitchType.NOTIFY_TF_EXIST_CARD);
               }*/
            SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_EXIST_CARD)
            /* String info = String.format(Locale.getDefault(), "%.2fG/%.2fG", remainSpace, totalSpace);
             LogUtils.d("deviceStatusInfo:sd信息",info);*/
          }
          // EventBus.getDefault().post(NotifyEvent.SD_HAS_CARD_INFO);

        } else if (PlayInfo.deviceStatusInfo.sdState == 1) {
          PlayInfo.deviceStatusInfo.sdFreeSize = 0;
          PlayInfo.deviceStatusInfo.sdTotalSize = 0;
          /* if (analysisListener != null) {
             analysisListener.data(SwitchType.NOTIFY_TF_NO_CARD);
           }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_NO_CARD)
          // EventBus.getDefault().post(NotifyEvent.SD_NO_CARD);
        } else if (PlayInfo.deviceStatusInfo.sdState == 2) {
          PlayInfo.deviceStatusInfo.sdFreeSize = 0;
          PlayInfo.deviceStatusInfo.sdTotalSize = 0;

          /* if (analysisListener != null) {
             analysisListener.data(SwitchType.NOTIFY_TF_FORMAT);
           }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT)
        }
      }
    } else if (WifiCommandHelper.isTargetData(data)) {
      if (data[4] == 0xa0
      ) {
        //检测目标
        /*  if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TARGET_DETECTION, data);
          }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TARGET_DETECTION, data)
      } else
        if (data[4] == 0xa1) {
          //跟踪目标-最多只有目标数据或目标丢失
          /*  if (analysisListener != null) {
              analysisListener.data(SwitchType.NOTIFY_TARGET_TRACK, data);
            }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TARGET_TRACK, data)
        } else
        if (data[4] == 0xa2) {
          //深度信息前距离和后距离
          /* if (analysisListener != null) {
             analysisListener.data(SwitchType.NOTIFY_DEPTH_INFO, data);
           }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_DEPTH_INFO, data)
        }
    } else if (WifiCommandHelper.checkFF3519(data)) {
      console.debug("收到海思信息数据")
      //海思数据
      let type = ObjectUtils.toInt(data[4]);
      //远程获取到得图片信息
      // RemoteAlbumManager.getInstance().receiveData(type, data);
      if (type == 0x2e) {
        console.debug("收到tf卡信息数据")
        let sdInfo = ObjectUtils.toInt(data[5]);
        if (sdInfo == 0) {
          //ff35190a2e 00 0000000edd28 000000000df7790000

          if (data.length >= 14) {
            ConnectConfig.TF_CARD_TOTAL_SPACE = ObjectUtils.bytesToLongBigEndian(new Uint8Array
            ([data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13]])
            )
            ;
          }
          if (data.length >= 22) {
            ConnectConfig.TF_CARD_REMAIN_SPACE = ObjectUtils.bytesToLongBigEndian(new Uint8Array([
              data[14], data[15], data[16], data[17], data[18], data[19], data[20], data[21]
            ])
            )
            ;
          }

          // 有数据时处理TF卡数据,处理示例
          if (ConnectConfig.TF_CARD_REMAIN_SPACE != 0 || ConnectConfig.TF_CARD_TOTAL_SPACE != 0) {
            let
              remainSpace = ConnectConfig.TF_CARD_REMAIN_SPACE / 1024
                / 1024 / 1024;
            let
              totalSpace = ConnectConfig.TF_CARD_TOTAL_SPACE / 1024
                / 1024 / 1024;
            PlayInfo.sdRemainSpace = remainSpace;
            PlayInfo.sdTotalSpace = totalSpace;

            //String info = String.format(Locale.getDefault(), "%.2fG/%.2fG", remainSpace, totalSpace);
          }


          /*if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_EXIST_CARD);
          }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_EXIST_CARD)
          // EventBus.getDefault().post(NotifyEvent.SD_HAS_CARD_INFO);

        } else if (sdInfo == 1) {
          ConnectConfig.TF_CARD_REMAIN_SPACE = 0;
          ConnectConfig.TF_CARD_TOTAL_SPACE = 0;
          /*if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_NO_CARD);
          }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_NO_CARD)
          // EventBus.getDefault().post(NotifyEvent.SD_NO_CARD);
        } else if (sdInfo == 2) {
          ConnectConfig.TF_CARD_REMAIN_SPACE = 0;
          ConnectConfig.TF_CARD_TOTAL_SPACE = 0;
          /* if (analysisListener != null) {
             analysisListener.data(SwitchType.NOTIFY_TF_FORMAT);
           }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT)
          //EventBus.getDefault().post(NotifyEvent.SD_NEED_FORMAT);
        }
      } else if (type == 0x11) {
        /*  if (analysisListener != null) {
            analysisListener.data(SwitchType.NOTIFY_TF_FORMAT_FINISHED);
          }*/
        SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT_FINISHED)
        let format = ObjectUtils.toInt(data[5]); //0 格式化中  1格式化成功  0xff格式化失败
        if (format == 0) {
          // EventBus.getDefault().post(NotifyEvent.SD_FORMAT_ING);
          SendEmitterUtil.sendEventObject(SwitchType.SD_FORMAT_ING)
        } else if (format == 1) {
          // EventBus.getDefault().post(NotifyEvent.SD_FORMAT_SUCCESS);
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT_FINISHED)
        } else if (format == 0xff) {
          // EventBus.getDefault().post(NotifyEvent.SD_FORMAT_FAIL);
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_TF_FORMAT_FAIL)
        }


      }
    }
  }

  public processTcpNotification(data: Uint8Array, analysisListener?: AnalysisListener) {
    try {
      if (data.length >= 5 && data[0] == 0x70 && data[1] == 0x68 && data[2] == 0x6f && data[3] == 0x74) {
        const photo = data[4];
        if (photo == 0x6f) {
          // photo
          /*    if (analysisListener != null) {
                analysisListener?.data(SwitchType.NOTIFY_REMOTE_PHOTO);
              }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_PHOTO)
        } else if (photo == 0x31 || photo == 0x32) {
          // 70686f7431=phot1 70686f7432=phot2
          const phot = this.bytesToString(data);
          if (phot !== this.strShotName) {
            if (analysisListener != null) {
              // analysisListener.data(SwitchType.NOTIFY_REMOTE_PHOTO);
              SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_PHOTO)
            }
          }
          this.strShotName = phot;
        }
      } else if (data.length >= 3 && data[0] == 0x72 && data[1] == 0x65 && data[2] == 0x63) {
        // 7265636f7274=recort
        if (!this.mRemoteRecord) {
          /* if (analysisListener != null) {
             analysisListener.data(SwitchType.NOTIFY_REMOTE_RECORD_START);
           }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_RECORD_START)
          this.mRemoteRecord = true;
        }
      } else if (data.length >= 3 && data[0] == 0x73 && data[1] == 0x74 && data[2] == 0x6f) {
        // 73746f70=stop
        if (this.mRemoteRecord) {
          /* if (analysisListener != null) {
             analysisListener.data(SwitchType.NOTIFY_REMOTE_RECORD_STOP);
           }*/
          SendEmitterUtil.sendEventObject(SwitchType.NOTIFY_REMOTE_RECORD_STOP)
          this.mRemoteRecord = false;
        }
      }
    } catch (e) {
      console.error(`处理TCP数据: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
}