import { MessagePacket } from '../message/MessagePacket';

/**
 * 解析抽象类，用于解析无人机通信数据
 */
export abstract class Parse {
  /**
   * 消息数据包对象
   */
  public packet: MessagePacket;

  /**
   * 构造函数，初始化消息数据包
   */
  constructor() {
    this.packet = new MessagePacket();
  }

  /**
   * 解析单个字节数据
   * @param b 要解析的字节数据
   * @returns 解析后的消息数据包，如果解析成功则返回完整的数据包，否则返回null
   */
  public abstract parse_char(b: number): MessagePacket | null;
}