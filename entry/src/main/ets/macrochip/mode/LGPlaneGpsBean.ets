export class LGPlaneGpsBean {
    AirplaneLon: number=0; 	 	 //飞机GPS经度 	 	 1 / 10000 000 deg
    AirplaneLat: number=0; 	 	 //飞机GPS纬度 	 	 1 / 10000 000 deg
    Altitude: number=0; 	 	 //距起飞点高度 	 	 -100.0~309.5m（收到数据减去1000）
    Distance: number=0; 	 	 //距起飞点距离 	 	 0~819.1m
    Speed: number=0; 	 	 	 //水平速度 	 	 	 0~12.7m/s
    Velocity: number=0; 	 	 	 //垂直速度 	 	 -12.7~+12.7m/s

    toString(): string {
        return "LGPlaneGpsBean{" +
            "AirplaneLon=" + this.AirplaneLon +
            ", AirplaneLat=" + this.AirplaneLat +
            ", Altitude=" + this.Altitude +
            ", Distance=" + this.Distance +
            ", Speed=" + this.Speed +
            ", Velocity=" + this.Velocity +
            '}';
    }
}