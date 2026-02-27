export class LGTestBean {
    gyro_x: number=0;            //陀螺仪X轴      -32767~32767
    gyro_y: number=0;            //陀螺仪Y轴      -32767~32767
    gyro_z: number=0;            //陀螺仪Z轴      -32767~32767
    acc_x: number=0;                //加速度X轴       -32767~32767
    acc_y: number=0;                //加速度Y轴       -32767~32767
    acc_z: number=0;                //加速度Z轴       -32767~32767
    mag_x: number=0;            //罗盘X轴       -32767~32767
    mag_y: number=0;            //罗盘Y轴       -32767~32767
    mag_z: number=0;            //罗盘Z轴       -32767~32767
    BatVal: number=0;        //电池电压          20.48 V
    GpsNum: number=0;        //卫星颗数          0~31颗
    AttitudeRoll: number=0;    //横滚角            -180~0~180 deg 使用时请减去180度
    AttitudePitch: number=0;    //俯仰角           -180~0~180 deg 使用时请减去180度
    AttitudeYaw: number=0;    //偏航角             0~360 deg
    InsInitOk: number=0;        //陀螺仪正常          0无陀螺仪，1陀螺仪初始化正常
    BaroInitOk: number=0;        //气压计正常         0无气压计，1气压计初始化正常
    MagInitOk: number=0;        //罗盘正常       0无罗盘，1罗盘初始化正常
    GpsInitOk: number=0;        //GPS正常          0无GPS，1有GPS初始化正常
    FlowInitOk: number=0;        //光流正常          0无光流，1光流初始化正常
    AirplaneLon: number=0;        //GPS经度        1 / 10000 000 deg
    AirplaneLat: number=0;        //GPS纬度        1 / 10000 000 deg
    temperature: number=0;        //温度          -127~127 (degree Celsius)
    baro_alt: number=0;        //气压计高度       -100.0~309.5m（收到数据减去1000）
    GpsFine: number=0;        //GPS定位        0没有定位，1已经定位
    GpsQuality: number=0;    //GPS定位精度    0~20.48m
    current1: number=0;        //电流检测1       0~63
    current2: number=0;        //电流检测2       0~63

    toString(): string {
        return "LGTestBean{" +
            "gyro_x=" + this.gyro_x +
            ", gyro_y=" + this.gyro_y +
            ", gyro_z=" + this.gyro_z +
            ", acc_x=" + this.acc_x +
            ", acc_y=" + this.acc_y +
            ", acc_z=" + this.acc_z +
            ", mag_x=" + this.mag_x +
            ", mag_y=" + this.mag_y +
            ", mag_z=" + this.mag_z +
            ", BatVal=" + this.BatVal +
            ", GpsNum=" + this.GpsNum +
            ", AttitudeRoll=" + this.AttitudeRoll +
            ", AttitudePitch=" + this.AttitudePitch +
            ", AttitudeYaw=" + this.AttitudeYaw +
            ", InsInitOk=" + this.InsInitOk +
            ", BaroInitOk=" + this.BaroInitOk +
            ", MagInitOk=" + this.MagInitOk +
            ", GpsInitOk=" + this.GpsInitOk +
            ", FlowInitOk=" + this.FlowInitOk +
            ", AirplaneLon=" + this.AirplaneLon +
            ", AirplaneLat=" + this.AirplaneLat +
            ", temperature=" + this.temperature +
            ", baro_alt=" + this.baro_alt +
            ", GpsFine=" + this.GpsFine +
            ", GpsQuality=" + this.GpsQuality +
            ", current1=" + this.current1 +
            ", current2=" + this.current2 +
            '}';
    }
}