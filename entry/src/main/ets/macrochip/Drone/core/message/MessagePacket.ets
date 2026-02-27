// 消息类，用于表示完整的消息
export class Message {
  // 可以根据需要添加属性和方法
}

// 消息负载类，用于存储和操作消息内容
export class MessagePayload {
  private data: Uint8Array;
  private index: number;
  
  constructor() {
    this.data = new Uint8Array(0);
    this.index = 0;
  }
  
  // 重置索引位置
  resetIndex(): void {
    this.index = 0;
  }
  
  // 获取一个字节并移动索引
  getByte(): number {
    if (this.index < this.data.length) {
      return this.data[this.index++];
    }
    return 0;
  }
  
  // 获取当前索引位置的字节，不移动索引
  peekByte(): number {
    if (this.index < this.data.length) {
      return this.data[this.index];
    }
    return 0;
  }
  
  // 获取负载大小
  size(): number {
    return this.data.length;
  }
  
  // 获取所有字节
  getBytes(): Uint8Array {
    return this.data;
  }
  
  // 添加字节到负载
  addByte(byte: number): void {
    const newData = new Uint8Array(this.data.length + 1);
    newData.set(this.data);
    newData[this.data.length] = byte;
    this.data = newData;
  }
  
  // 添加字节数组到负载
  addBytes(bytes: Uint8Array): void {
    const newData = new Uint8Array(this.data.length + bytes.length);
    newData.set(this.data);
    newData.set(bytes, this.data.length);
    this.data = newData;
  }
}

// 校验和类，用于计算和验证消息校验和
export class CK {
  private checksum: number;
  
  constructor() {
    this.checksum = 0;
  }
  
  // 开始校验和计算，重置校验和值
  start_checksum(): void {
    this.checksum = 0;
  }
  
  // 更新校验和
  update_checksum(value: number): void {
    this.checksum ^= value & 0xFF;
  }
  
  // 完成校验和计算，比较给定的校验和字节
  finish_checksum(ckb: number): boolean {
    return (this.checksum & 0xFF) === (ckb & 0xFF);
  }
}

// 消息数据包类，用于封装无人机通信的完整数据包
export class MessagePacket {
  /** 
   * 消息总长度: msgid + payload + ck 
   */
  public len: number = 0;

  /** 
   * 消息ID - ID定义了payload的含义以及如何正确解码它
   */
  public msgid: number = 0;

  /** 
   * 完整的消息数据
   */
  public message: Message;

  /** 
   * 消息负载数据，取决于消息ID
   */
  public payload: MessagePayload;

  /** 
   * 校验和对象
   */
  public ck: CK | null = null;

  constructor() {
    this.payload = new MessagePayload();
    this.message = new Message();
  }

  /** 
   * 检查Payload的大小是否等于"len"字节，(len - msgid - ck)
   */
  public payloadIsFilled(surplus: number): boolean {
    return this.payload.size() >= (this.len - surplus);
  }

  /** 
   * 生成并验证校验和
   */
  public generateCK(ckb: number): boolean {
    if (this.ck == null) {
      this.ck = new CK();
    } else {
      this.ck.start_checksum();
    }

    this.ck.update_checksum(this.len);
    this.ck.update_checksum(this.msgid & 0xFF);

    this.payload.resetIndex();

    for (let i = 0; i < this.payload.size(); i++) {
      this.ck.update_checksum(this.payload.getByte());
    }
    return this.ck.finish_checksum(ckb);
  }
}