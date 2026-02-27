import { PlayInfo } from '../../model/PlayInfo';
import { DroneCodeManager } from '../Drone/code/DroneCodeManager';
import { HyDroneCode } from '../Drone/code/HyDroneCode';
import { LgDroneCode } from '../Drone/code/LgDroneCode';
import { VsDroneCode } from '../Drone/code/VsDroneCode';
import { ProtocolManager } from '../Drone/core/protocol/ProtocolManager';
import { DroneEnum } from '../../model/DroneEnum';

class MoreHelper {

    /**
     * 支持双镜头
     *
     * @return
     */
    static isTwinlens(): boolean {
        return PlayInfo.isMr100()
                || PlayInfo.chipMaker == 3
                //|| PlayInfo.deviceId == PlayInfo.DeviceId._872_DOUBLE_CAMERA.getId()
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.ZCZ210FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.ZC001R0P)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.ZC0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.SM1902FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQP1RQFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TXJLGCX0)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQZ10ZFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.DW0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.HC7151HM)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.MDDHM02X)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.KAI_ZHENG)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.LIAN_HUANG_0C)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.XIN_LI)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.YIN_HE)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.PPHMH108)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.HNWLGC20)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC775VFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC775BFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XY0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XY1001FX)
                || PlayInfo.droneEnum == DroneEnum.drone44
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.LI_HUANG)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.LI_HUANG_ONE)
                || (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.YH0001FX) && !PlayInfo.isMr100())
                || (DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.KE_YING) && DroneCodeManager.getInstance().isVisonChildEquals(VsDroneCode.KeYing.MODEL_06)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.OR0181FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.DW0132FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.DW0132FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.LH0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.LH0002FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HX518XFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XYZ091FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.CFEX5XFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TXDG9XFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0002FX)
                || DroneCodeManager.getInstance().containsLanGuangEquals(HyDroneCode.CBY0B2FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0002FX)
                || DroneCodeManager.getInstance().containsLanGuangEquals(HyDroneCode.CBYZB2FX)
        );
    }

    /**
     * 支持镜头调节
     *
     * @return
     */
    static isAdjustLens(): boolean {
        return DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQM1RQFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQM1RUFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.YH0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.XG0001FX)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.XING_HAI_HONG)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.LIAN_HUANG_0B)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.HNW)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.KE_YING)
                || ProtocolManager.getInstance().isBite()
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC775VFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC775BFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC782VFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC780VFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JY531VFX)
                || (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5XFX) && PlayInfo.chipMaker == 4)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.OR0181FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.KY7573FX);
    }


    /**
     * 不支持镜头翻转
     */
    static isNotReverse(): boolean {
        return DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.HUA_JIA)
                || VsDroneCode.AoSenMa.isASM_DE()
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RXFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RZFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RCFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5XFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5DFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.LIU001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.LIHSB9FX);
    }

    /**
     * 支持wifi云台
     */
    static isPTZ(): boolean {
        return DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.DFLLG401)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.JYLGDB00)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.FT851SFX)
                || (DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5XFX) && PlayInfo.chipMaker != 4)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.JYEX5DFX)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.HUA_JIA)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.QI_CHENG)
                || DroneCodeManager.getInstance().isVisonEquals(VsDroneCode.LI_HUANG)
                || VsDroneCode.AoSenMa.isASM_DE()
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RXFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RZFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RCFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.TQK3RBFX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0002FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.PP0001FX)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.JYLGMK01)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.JYLGMG01)
                || DroneCodeManager.getInstance().isLanGuangEquals(LgDroneCode.JYLGMJ01)
                || DroneCodeManager.getInstance().isLanGuangEquals(HyDroneCode.HC7581HM);
    }
}

export default MoreHelper;