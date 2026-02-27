export class LGInfo3HyBean {
    MagInterference: number=0; 	 	 //地磁环境干扰量0-1000
    BatVal: number=0; 	 	 	 	 //电池实际电压 单位mv
    GpsQuality: number=0; 	 	 	 //GPS精度 单位cm

    toString(): string {
        return "LGInfo3HyBean{" +
            "MagInterference=" + this.MagInterference +
            ", BatVal=" + this.BatVal +
            ", GpsQuality=" + this.GpsQuality +
            '}';
    }
}