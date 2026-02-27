// OnHeartbeatListener.ets
/**
 * 心跳监听器接口
 */
export interface OnHeartbeatListener {
  onCommunicationSuccess:() =>void;    // 连接成功
  onCommunicationLost:() =>void;       // 连接丢失
  onCommunicationRestore:() =>void;   // 连接恢复
}