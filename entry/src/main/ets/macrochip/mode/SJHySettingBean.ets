export class SJHySettingBean {
  UseMagDec: number = 0; // 是否使用 APP 的磁偏角 1 为使用 0 为不使用
  MagDec: number = 0; // 当地磁偏角 -127~127 deg
  Limhigh: number = 0; // 最大限飞高度 0~1023 米
  Limdistance: number = 0; // 最大限飞距离 0~4096 米
  Gohomehigh: number = 0; // 返航高度 0~限距高度
}
