export class LGControlHyBean {
    rocker1: number = 128;       // 摇杆1 (Roll)
    rocker2: number = 128;       // 摇杆2 (Pitch)
    rocker3: number = 128;       // 摇杆3 (Throttle)
    rocker4: number = 128;       // 摇杆4 (Yaw)
    leftRightTrim: number = 0x20;    // 左右微调 (TrimRoll)
    upDownTrim: number = 0x20;       // 上下微调 (TrimPitch)
    fastMode: number = 0;        // 快档模式 (FastMode)
    cfMode: number = 0;          // 无头模式 (CFMode)
    flipMode: number = 0;        // 翻滚模式 (FlipMode)
    gpsMode: number = 0;         // GPS模式 (GpsMode)
    levelCor: number = 0;        // 水平校准 (LevelCor)
    magCor: number = 0;          // 罗盘校准 (MagCor)
    lockUnlock: number = 0;      // 解锁/加锁 (LockUnlock)
    autoTakeoff: number = 0;     // 一键起飞 (AutoTakeoff)
    autoLand: number = 0;        // 一键降落 (AutoLand)
    goHome: number = 0;          // 一键返航 (GoHome)
    stop: number = 0;            // 急停 (Stop)
    followMe: number = 0;        // 跟随 (FollowMe)
    circleFly: number = 0;       // 环绕 (CircleFly)
    popublicFly: number = 0;     // 航点飞行 (PointFly)
    photo: number = 0;           // 拍照状态 (Photo)
    video: number = 0;           // 视频 (Video)
    ptzH: number = 0;            // 云台平移 (PTZ_H)
    ptzV: number = 0;            // 云台俯仰 (PTZ_V)
    ctrlPanel: number = 0;       // 控制面板 (CtrlPanel)
    display: number = 0;         // 显示 (display)
    opticalFlowOn: number = 0;   // 室内光流模式 (OpticalFlowOn)
    visionFollow: number = 0;    // 视觉跟随 (VisionFollow)
    disValid: number = 0;        // 跟随数据有效 (Dis_valid)
    distance: number = 0;        // 与跟随人的距离 (Distance)
    boxX: number = 0;            // 跟随框中心x坐标 (Box_x)
    boxY: number = 0;            // 跟随框中心y坐标 (Box_y)

    toString(): string {
        return "LGControlHyBean{" +
            "rocker1=" + this.rocker1 +
            ", rocker2=" + this.rocker2 +
            ", rocker3=" + this.rocker3 +
            ", rocker4=" + this.rocker4 +
            ", leftRightTrim=" + this.leftRightTrim +
            ", upDownTrim=" + this.upDownTrim +
            ", fastMode=" + this.fastMode +
            ", cfMode=" + this.cfMode +
            ", flipMode=" + this.flipMode +
            ", gpsMode=" + this.gpsMode +
            ", levelCor=" + this.levelCor +
            ", magCor=" + this.magCor +
            ", lockUnlock=" + this.lockUnlock +
            ", autoTakeoff=" + this.autoTakeoff +
            ", autoLand=" + this.autoLand +
            ", goHome=" + this.goHome +
            ", stop=" + this.stop +
            ", followMe=" + this.followMe +
            ", circleFly=" + this.circleFly +
            ", popublicFly=" + this.popublicFly +
            ", photo=" + this.photo +
            ", video=" + this.video +
            ", ptzH=" + this.ptzH +
            ", ptzV=" + this.ptzV +
            ", ctrlPanel=" + this.ctrlPanel +
            ", display=" + this.display +
            ", opticalFlowOn=" + this.opticalFlowOn +
            ", visionFollow=" + this.visionFollow +
            ", disValid=" + this.disValid +
            ", distance=" + this.distance +
            ", boxX=" + this.boxX +
            ", boxY=" + this.boxY +
            '}';
    }
}