export class LGInfo3BHyBean {
    MagInterference: number=0;        //地磁环境干扰量0-1000
    BatVal: number=0;                //电池实际电压 单位mv
    GpsQuality: number=0;            //GPS精度 单位cm
    UnlockFlowMode: number=0;        //光流模式解锁标志
    BatPer: number=0;                //电量百分比
    IsUseLongDis: number=0;            //如果该位使能，显示使用距离为0-8191m
    Distance: number=0;                //距起飞点距离 	 	 0~8191m
    RmoteVol: number=0;                 //遥控器电量 	 	 0-100%
    IMUACCFlag: number=0;                 //0 IMU 正常 1 IMU误差大
    YawRotate: number=0;
    MagErr: number=0;

    toString(): string {
        return "LGInfo3BHyBean{" +
            "MagInterference=" + this.MagInterference +
            ", BatVal=" + this.BatVal +
            ", GpsQuality=" + this.GpsQuality +
            ", UnlockFlowMode=" + this.UnlockFlowMode +
            ", BatPer=" + this.BatPer +
            ", IsUseLongDis=" + this.IsUseLongDis +
            ", Distance=" + this.Distance +
            ", RmoteVol=" + this.RmoteVol +
            ", IMUACCFlag=" + this.IMUACCFlag +
            ", YawRotate=" + this.YawRotate +
            ", MagErr=" + this.MagErr +
            '}';
    }
}