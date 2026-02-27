/**
 * 设置类型：每个类型可对应右侧弹窗中的一个页面。
 * 是否展示由 RIGHT_DRAWER_PAGE_TYPES 控制：加入则显示该页，移除则不显示。
 */
export enum SettingType {
  DATA,              // 数据参数
  AROUND,            // 环绕半径
  CALIBRATION,       // 飞机校准
  FIRMWARE,          // 固件升级
  TF,                // TF卡
  TRACK,             // 飞机飞行轨迹
  UNIT,              // 单位
  OTHRE,             // 其他
  ZONE,              // 禁飞区
  CONTROL_FIRMWARE   // 飞控固件升级
}

/** 所有设置类型列表（完整枚举顺序） */
export const SETTING_TYPE_LIST: SettingType[] = [
  SettingType.DATA,
  SettingType.AROUND,
  SettingType.CALIBRATION,
  SettingType.FIRMWARE,
  SettingType.TF,
  SettingType.TRACK,
  SettingType.UNIT,
  SettingType.OTHRE,
  SettingType.ZONE,
  SettingType.CONTROL_FIRMWARE
];

/**
 * 右侧弹窗已添加的页面类型。
 * 仅此数组中的类型会在左侧导航显示并有对应右侧页面。
 * 添加页面：把对应 SettingType 加入本数组；
 * 不添加某页：从本数组中删除该类型即可。
 */
export const RIGHT_DRAWER_PAGE_TYPES: SettingType[] = [
  SettingType.DATA,
  SettingType.AROUND,
  SettingType.CALIBRATION,
  SettingType.FIRMWARE,
  SettingType.TF,
  SettingType.TRACK,
  SettingType.UNIT,
  SettingType.OTHRE,
  SettingType.ZONE,
  SettingType.CONTROL_FIRMWARE
];

/** 获取类型的展示名称 */
// 原本返回文字（如“数据参数”），现改为返回对应图标资源
export function getSettingTypeName(type: SettingType): Resource {
  switch (type) {
    case SettingType.DATA:
      return $r('app.media.ic_setting_parameter');
    case SettingType.AROUND:
      return $r('app.media.ic_setting_around');
    case SettingType.CALIBRATION:
      return $r('app.media.ic_setting_calibration');
    case SettingType.FIRMWARE:
      return $r('app.media.ic_setting_firmware');
    case SettingType.TF:
      return $r('app.media.ic_setting_tf');
    case SettingType.TRACK:
      return $r('app.media.ic_setting_track');
    case SettingType.UNIT:
      return $r('app.media.ic_setting_unit');
    case SettingType.OTHRE:
      return $r('app.media.ic_setting_other');
    case SettingType.ZONE:
      return $r('app.media.ic_setting_zone');
    case SettingType.CONTROL_FIRMWARE:
      // 与固件升级共用图标
      return $r('app.media.ic_setting_firmware');
    default:
      return $r('app.media.ic_setting_other');
  }
}
