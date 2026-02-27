import { ObjectUtils } from "../../utils/ObjectUtils";

export class HyABBean {
    UavName: Uint8Array = new Uint8Array(12);    //飞机型号 	 	 	 12个字符 	 前4个字符为司马编号如“SM01LGPF”
    UavVersion: Uint8Array = new Uint8Array(12); 	     //飞机版本

    Maxhigh: number=0;        //最大飞行高度 	 	 0~1023米
    Maxdistance: number=0;    //最大飞行距离 	 	 0~4096米
    Gohomehigh: number=0;        //返航高度 0~限距高度
    Gohomehigh2: number=0;        //保留

    getUavNameStr(): string {
        return ObjectUtils.uint8ArrayToString(this.UavName);
    }

    getUavVersionStr(): string {
        return ObjectUtils.uint8ArrayToString(this.UavVersion);
    }

    toString(): string {
        return "HyABBean{" +
            "UavName=" + this.getUavNameStr() +
            ", UavVersion=" + this.getUavVersionStr() +
            ", Maxhigh=" + this.Maxhigh +
            ", Maxdistance=" + this.Maxdistance +
            ", Gohomehigh=" + this.Gohomehigh +
            ", Gohomehigh2=" + this.Gohomehigh2 +
            '}';
    }
}