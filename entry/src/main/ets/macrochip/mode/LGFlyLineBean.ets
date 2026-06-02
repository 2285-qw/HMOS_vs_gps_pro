// LGFlyLineBean.ets
export class LGFlyLineBean {
  /**
   * 航点经度 (1 / 10,000,000 deg)
   */
  PointGpsLon: number = 0;

  /**
   * 航点纬度 (1 / 10,000,000 deg)
   */
  PointGpsLat: number = 0;

  /**
   * 航点编号 0~32点
   */
  PointNum: number = 0;

  /**
   * 航点高度 0~409.5m
   */
  PointAltitude: number = 0;

  /**
   * 航点速度 0~12.7m/s
   */
  PointSpeed: number = 0;

  /**
   * 停留时间 0~255 s
   */
  PointTime: number = 0;
}