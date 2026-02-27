export class BluetoothBean {
    timestamp: number = 0;       // 时间戳
    latitude: number = 0;        // 纬度
    longitude: number = 0;       // 经度
    souceType: number = 0;       // 数据源类型
    resv1: number = 0;           // 保留字段1
    AltitudeGeo: number = 0;     // 海拔高度

    toString(): string {
        return "BluetoothBean{" +
            "timestamp=" + this.timestamp +
            ", latitude=" + this.latitude +
            ", longitude=" + this.longitude +
            ", souceType=" + this.souceType +
            ", resv1=" + this.resv1 +
            ", AltitudeGeo=" + this.AltitudeGeo +
            '}';
    }
}