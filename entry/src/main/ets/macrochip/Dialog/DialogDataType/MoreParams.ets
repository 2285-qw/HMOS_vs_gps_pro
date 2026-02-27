import { DroneCodeManager } from "../../Drone/code/DroneCodeManager";
import { FSDroneCode } from "../../Drone/code/FSDroneCode";
import { HyDroneCode } from "../../Drone/code/HyDroneCode";
import { VsDroneCode } from "../../Drone/code/VsDroneCode";
import { ProtocolManager } from "../../Drone/core/protocol/ProtocolManager";
import { MoreBean } from "../../More/MoreBean";
import MoreHelper from "../../More/MoreHelper";
import { MoreType } from "../../More/MoreType";
import resourceManager from '@ohos.resourceManager';

export  class MoreParams {

  dialogId?:  ComponentContent;
  uiContext?: UIContext;
  arrMoreBean: Array<MoreBean> = [];
  onItemClick?: (type: MoreType) => void

  constructor(uiContext?:UIContext, onItemClick?: (type: MoreType) => void) {
    this.uiContext=uiContext;
    this.onItemClick=onItemClick
  }

  addMoreBean(more:MoreType){
    const bean = new MoreBean();
    switch (more) {
      case MoreType.REV:
        bean.setIcon($r('app.media.ic_more_rev'));
        bean.setText('镜头翻转');
        break;
      case MoreType._3D:
        bean.setIcon($r('app.media.ic_more_3d'));
        bean.setText('3D模式');
        break;
      case MoreType.POINT:
        bean.setIcon($r('app.media.ic_more_point'));
        bean.setText('多点飞行');
        break;
      case MoreType.FOLLOW:
        bean.setIcon($r('app.media.ic_more_follow'));
        bean.setText('跟随');
        break;
      case MoreType.AROUND:
        bean.setIcon($r('app.media.ic_more_around'));
        bean.setText('环绕');
        break;
      case MoreType.GESTURE:
        bean.setIcon($r('app.media.ic_more_ges'));
        bean.setText('手势拍照');
        break;
      case MoreType.UNLOCK:
        bean.setIcon($r('app.media.ic_more_unlock'));
        bean.setText('解锁按钮');
        break;
      case MoreType.ROCKER:
        bean.setIcon($r('app.media.ic_more_rocker'));
        bean.setText('摇杆');
        break;
      case MoreType.FIND_DRONE:
        bean.setIcon($r('app.media.ic_more_find_drone'));
        bean.setText('找飞机');
        break;
      case MoreType.SWITCH_CAMERA:
        bean.setIcon($r('app.media.ic_more_switch_camera'));
        bean.setText('切换镜头');
        break;
      case MoreType.SPEED:
        bean.setIcon($r('app.media.ic_more_speed_1'));
        bean.setText('速度控制');
        break;
      case MoreType.MUSIC:
        bean.setIcon($r('app.media.ic_more_music'));
        bean.setText('音乐');
        break;
      case MoreType.CAMERA_ADJUST:
        bean.setIcon($r('app.media.ic_more_camera_adjust'));
        bean.setText('镜头调节');
        break;
      case MoreType.PTZ:
        bean.setIcon($r('app.media.ic_more_ptz'));
        bean.setText('云台调节');
        break;
      case MoreType.FAR:
        bean.setIcon($r('app.media.ic_more_far'));
        bean.setText('一键远飞');
        break;
      case MoreType.GPS_OFF:
        bean.setIcon($r('app.media.ic_more_gps'));
        bean.setText('GPS模式/室内模式切换');
        break;
      case MoreType.HEADLESS:
        bean.setIcon($r('app.media.ic_more_headless'));
        bean.setText('无头模式');
        break;
      case MoreType.OBSTACLE:
        bean.setIcon($r('app.media.ic_more_obstacle'));
        bean.setText('避障');
        break;
      case MoreType.VISION_OBSTACLE:
        bean.setIcon($r('app.media.ic_more_vision_obstacle'));
        bean.setText('视觉（单目）避障');
        break;
      case MoreType.FAR_FLY:
        bean.setIcon($r('app.media.ic_more_far'));
        bean.setText('一键远飞');
        break;
      case MoreType.SKY_FLY:
        bean.setIcon($r('app.media.ic_more_sky'));
        bean.setText('冲天功能变高');
        break;
      case MoreType.SPIRAL_FLY:
        bean.setIcon($r('app.media.ic_more_spiral'));
        bean.setText('螺旋功能变高');
        break;
      case MoreType.SPORT:
        bean.setIcon($r('app.media.ic_more_sport'));
        bean.setText('运动模式');
        break;
      case MoreType.FOLLOW_TRACK:
        bean.setIcon($r('app.media.ic_more_follow_track'));
        bean.setText('图像跟随');
        break;
      case MoreType.CRUISE:
        bean.setIcon($r('app.media.ic_more_cruise'));
        bean.setText('巡航');
        break;
      case MoreType.PREVIEW_DIRECTION:
        bean.setIcon($r('app.media.icon_more_preview_direction'));
        bean.setText('预览方向');
        break;
      case MoreType.PLACE:
        bean.setIcon($r('app.media.ic_place_off'));
        bean.setText('投放');
        break;
    }
    bean.setType(more);
    bean.setPopupView(this);
    this.arrMoreBean.push(bean)
  }

  getType(){
    if (ProtocolManager.getInstance().isFeiSha()) {
      // 飞沙协议所需要的功能挑选
      this.addMoreBean(MoreType.REV);
       this.addMoreBean(MoreType._3D);
       this.addMoreBean(MoreType.POINT);
       this.addMoreBean(MoreType.FOLLOW);
       this.addMoreBean(MoreType.AROUND);
       this.addMoreBean(MoreType.GESTURE);
       this.addMoreBean(MoreType.FIND_DRONE);
      if (DroneCodeManager.getInstance().isFeishaEquals(FSDroneCode.SYSID_HNW)) {
         this.addMoreBean(MoreType.MUSIC);
         this.addMoreBean(MoreType.SWITCH_CAMERA);
      } else if (DroneCodeManager.getInstance().isFeishaEquals(FSDroneCode.SYSID_XX)) {
         this.addMoreBean(MoreType.MUSIC);
         this.addMoreBean(MoreType.UNLOCK);
      }
       this.addMoreBean(MoreType.CAMERA_ADJUST);
    } else {
      if (!MoreHelper.isNotReverse()) {
         this.addMoreBean(MoreType.REV);
      }
       this.addMoreBean(MoreType._3D);
       this.addMoreBean(MoreType.POINT);
      if (!DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.LIUB93FX) /*|| levelDistance < 30*/) {
         this.addMoreBean(MoreType.FOLLOW);
      }

       this.addMoreBean(MoreType.AROUND);


       this.addMoreBean(MoreType.GESTURE);

      if (!DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.FX30P3FX)) {
         this.addMoreBean(MoreType.UNLOCK);
        /*  if (!DroneCodeManager.getInstance().containsLanGuangEquals(HyDroneCode.OR0181FX)) {*/
         this.addMoreBean(MoreType.ROCKER);
        //  }
      }

       this.addMoreBean(MoreType.FIND_DRONE);
      if (MoreHelper.isTwinlens()) {
         this.addMoreBean(MoreType.SWITCH_CAMERA);
      }

      if (!DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.FX30P3FX)
        && !DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM010FX)
        && !DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM011FX)
        && !DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM012FX)) {
         this.addMoreBean(MoreType.SPEED);
      }
       this.addMoreBean(MoreType.MUSIC);
      if (MoreHelper.isAdjustLens()) {
         this.addMoreBean(MoreType.CAMERA_ADJUST);
      }
      if (MoreHelper.isPTZ()) {
         this.addMoreBean(MoreType.PTZ);
      }
      //一键远飞
      if (DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.KAI_ZHENG)) {
         this.addMoreBean(MoreType.FAR);
      }
      if (DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.KE_YING)) {
         this.addMoreBean(MoreType.GPS_OFF);
        //避障
        if (DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_02)
          || DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_03)
          || DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_04)
          || DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_06)
          || DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_07)) {
           this.addMoreBean(MoreType.OBSTACLE);
           this.addMoreBean(MoreType.VISION_OBSTACLE);
        }

        if (DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_06)
          || DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_07)) {
           this.addMoreBean(MoreType.FAR_FLY);
           this.addMoreBean(MoreType.SKY_FLY);
           this.addMoreBean(MoreType.SPIRAL_FLY);
        }
      }


      //趣贝
      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.QNTQ01FX)) {
         this.addMoreBean(MoreType.PLACE);
      }

      //奇城
      if (DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.QI_CHENG)) {
        if (DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.QiCheng.MODEL_01)) {
           this.addMoreBean(MoreType.GPS_OFF);
           this.addMoreBean(MoreType.VISION_OBSTACLE);
           this.addMoreBean(MoreType.FAR_FLY);
           this.addMoreBean(MoreType.SKY_FLY);
           this.addMoreBean(MoreType.SPIRAL_FLY);
        }
      }

      //无头
      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5XFX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5DFX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0001FX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0002FX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PPHH12FX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PPHH13FX)) {
         this.addMoreBean(MoreType.HEADLESS);
      }
      //视觉避障
      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RBFX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RCFX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0001FX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0002FX)) {
         this.addMoreBean(MoreType.VISION_OBSTACLE);
      }

      //图像跟随
      if (DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.XinLi.MODEL_02) || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PPHH12FX) || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PPHH13FX)) {
         this.addMoreBean(MoreType.FOLLOW_TRACK);
      }


      // 辉科
      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.FX30P3FX)) {
         this.addMoreBean(MoreType.FAR_FLY);
         this.addMoreBean(MoreType.SKY_FLY);
         this.addMoreBean(MoreType.SPIRAL_FLY);
         this.addMoreBean(MoreType.SPORT);
         this.addMoreBean(MoreType.FOLLOW_TRACK);
         this.addMoreBean(MoreType.CRUISE);
      }

      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM010FX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM011FX)
        || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM012FX)) {
         this.addMoreBean(MoreType.FAR_FLY);
         this.addMoreBean(MoreType.SKY_FLY);
         this.addMoreBean(MoreType.SPIRAL_FLY);
      }
      // 天驱
      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RBFX)) {
         this.addMoreBean(MoreType.FAR_FLY);
         this.addMoreBean(MoreType.SKY_FLY);
         this.addMoreBean(MoreType.SPIRAL_FLY);
      }

      // 博洋
      if (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.CBYZB2FX)) {
         this.addMoreBean(MoreType.FAR_FLY);
         this.addMoreBean(MoreType.SKY_FLY);
         this.addMoreBean(MoreType.SPIRAL_FLY);
      }

    }


    if (DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.XIN_LI)
      || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.KE_YING)
      || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM010FX)
      || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM011FX)
      || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XMM012FX)
      || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.OR0181FX)) {
       this.addMoreBean(MoreType.PREVIEW_DIRECTION);
    }

  }

}