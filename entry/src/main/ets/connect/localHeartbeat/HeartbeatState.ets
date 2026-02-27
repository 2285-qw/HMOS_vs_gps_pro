// HeartbeatState.ets
/**
 * 心跳状态枚举
 */
export enum HeartbeatState {
  NONE = 'none',       // 无心跳
  NORMAL = 'normal',   // 心跳正常
  LOST = 'lost'        // 心跳丢失
}

/**
 * 心跳事件类型
 */
export enum HeartbeatEvent {
  COMMUNICATION_SUCCESS = 'communication_success',
  COMMUNICATION_LOST = 'communication_lost',
  COMMUNICATION_RESTORE = 'communication_restore'
}