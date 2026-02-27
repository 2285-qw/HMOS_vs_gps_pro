export class SJHyInfo9BBean {
    Acc: number[] = [0, 0, 0];     //加速度传感器数据
    Gyr: number[] = [0, 0, 0];     //陀螺仪数据
    Mag: number[] = [0, 0, 0];     //磁力计数据

    baro: number = 0;              //气压计数据
    ImuTemp: number = 0;           //IMU温度
    BaroTemp: number = 0;          //气压计温度
    Roll: number = 0;              //横滚角
    Pitch: number = 0;             //俯仰角
    Thor: number = 0;              //油门
    Yaw: number = 0;               //偏航角
    Motor: number[] = [0, 0, 0, 0]; //电机数据

    toString(): string {
        return "SJHyInfo9BBean{" +
            "Acc=" + JSON.stringify(this.Acc) +
            ", Gyr=" + JSON.stringify(this.Gyr) +
            ", Mag=" + JSON.stringify(this.Mag) +
            ", baro=" + this.baro +
            ", ImuTemp=" + this.ImuTemp +
            ", BaroTemp=" + this.BaroTemp +
            ", Roll=" + this.Roll +
            ", Pitch=" + this.Pitch +
            ", Thor=" + this.Thor +
            ", Yaw=" + this.Yaw +
            ", Motor=" + JSON.stringify(this.Motor) +
            '}';
    }
}