export class HyExtendBean {
    SkyFly: number = 0;          // 冲天功能
    FarFly: number = 0;          // 渐远功能
    SpiralFly: number = 0;       // 螺旋功能
    SportMode: number = 0;       // 运动模式
    ForbidTakeOff: number = 0;   // 禁止起飞
    MotorBeepCrtl: number = 0;   // 电机警报声

    toString(): string {
        return "HyExtendBean{" +
            "SkyFly=" + this.SkyFly +
            ", FarFly=" + this.FarFly +
            ", SpiralFly=" + this.SpiralFly +
            ", SportMode=" + this.SportMode +
            ", ForbidTakeOff=" + this.ForbidTakeOff +
            ", MotorBeepCrtl=" + this.MotorBeepCrtl +
            '}';
    }
}