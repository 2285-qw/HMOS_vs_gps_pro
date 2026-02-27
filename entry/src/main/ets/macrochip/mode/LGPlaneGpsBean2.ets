export class LGPlaneGpsBean2 {
    AirplaneLon: number=0; 	 	 //飞机GPS经度 	 	 1 / 10000 000 deg
    AirplaneLat: number=0; 	 	 //飞机GPS纬度 	 	 1 / 10000 000 deg
    Altitude: number=0; 	 	 //距起飞点高度 	 	 -3276.8m ~ 3276.7m
    Distance: number=0; 	 	 //距起飞点距离 	 	 0~65535m
    Speed: number=0; 	 	 	 //水平速度 	 	 	 0~25.5m/s
    Velocity: number=0; 	 	 	 //垂直速度 	 	 -12.7~+12.7m/s

    toString(): string {
        return "LGPlaneGpsBean2{" +
            "AirplaneLon=" + this.AirplaneLon +
            ", AirplaneLat=" + this.AirplaneLat +
            ", Altitude=" + this.Altitude +
            ", Distance=" + this.Distance +
            ", Speed=" + this.Speed +
            ", Velocity=" + this.Velocity +
            '}';
    }
}