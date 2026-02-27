export class SJHyInfo9CBean {
    MagInterference: number=0;        //地磁环境干扰量0-1000
    BatVal: number=0;                //电池实际电压 单位mv
    GpsQuality: number=0;            //GPS精度 单位cm
    IndoorMode: number=0;        //室内模式标志
    BatPer: number=0;                //电量百分比
    IsUseLongDis: number=0;            //如果该位使能，显示使用距离为0-8191m
    Distance: number=0;                //距起飞点距离 	 	 0~8191m
    RmoteVol: number=0;                //遥控器电量 0-100%
    IMUAccFlag: number=0;                //0 IMU 正常 1 IMU 误差大
    YawRotate: number=0;               // 0 未旋转 1 旋转
    MagErr: number=0;                  //0 地磁正常，1 地磁失效
    HeighLimt: number=0;               //达到高度限制
    DistanceLimit: number=0;           //达到距离限制
    WiFiTestMode: number=0;           //1进入WiFi测试模式0正常模式
    OAWarn: number=0;           //障碍物报警
    OADis: number=0;           //避障传感器距离单位m0-31米
    MagNeedCal: number=0;           //1飞机需要地磁校准0正常状态
    SportMode: number=0;            //运动模式标志
    OASensor: number=0;             //1 避障传感器正常
    ZoomInOut: number=0;            //图像放大缩小0正常，1缩小，2放大
    AutoMode: number=0;             //自动模式类型 //0操控模式1返航到起飞点上空（航向对准起飞点）//2返航到起飞点上空（航向维持返航前角度）//3 返航到起飞点自动降落（航向对准起飞点）//4返航到起飞点自动降落（航向维持返航前角度）//5 返航到围栏内6自动航点模式7环绕模式
    RtlSetp: number=0;              //返航步骤0未启动1爬升中2航向对准起飞点中3返航中4下降// 5悬停在起飞点6落地中7成功落地8航向恢复解锁前角度
    CruiseHor: number=0;            //水平巡航模式 0：未启动 1：启动
    CruiseVer: number=0;             //高度巡航模式 0：未启动 1：启动
    Resv: number=0;                //保留
    SkyFlySta: number=0;           //自主冲天模式状态 0：未启动 1：冲天 2：结束 3:返回
    FarFlySta: number=0;           //自主渐远模式状态 0：未启动 1：渐远 2：结束 3:返回
    SpiralSta: number=0;           //自主螺旋模式状态 0：未启动 1：螺旋 2：结束 3:返回
    BatLegal: number=0;           //是否正版电池 0非正版 1正版

    toString(): string {
        return "SJHyInfo9CBean{" +
            "MagInterference=" + this.MagInterference +
            ", BatVal=" + this.BatVal +
            ", GpsQuality=" + this.GpsQuality +
            ", IndoorMode=" + this.IndoorMode +
            ", BatPer=" + this.BatPer +
            ", IsUseLongDis=" + this.IsUseLongDis +
            ", Distance=" + this.Distance +
            ", RmoteVol=" + this.RmoteVol +
            ", IMUAccFlag=" + this.IMUAccFlag +
            ", YawRotate=" + this.YawRotate +
            ", MagErr=" + this.MagErr +
            ", HeighLimt=" + this.HeighLimt +
            ", DistanceLimit=" + this.DistanceLimit +
            ", WiFiTestMode=" + this.WiFiTestMode +
            ", OAWarn=" + this.OAWarn +
            ", OADis=" + this.OADis +
            ", MagNeedCal=" + this.MagNeedCal +
            ", SportMode=" + this.SportMode +
            ", OASensor=" + this.OASensor +
            ", ZoomInOut=" + this.ZoomInOut +
            ", AutoMode=" + this.AutoMode +
            ", RtlSetp=" + this.RtlSetp +
            ", CruiseHor=" + this.CruiseHor +
            ", CruiseVer=" + this.CruiseVer +
            ", Resv=" + this.Resv +
            ", SkyFlySta=" + this.SkyFlySta +
            ", FarFlySta=" + this.FarFlySta +
            ", SpiralSta=" + this.SpiralSta +
            ", BatLegal=" + this.BatLegal +
            '}';
    }
}