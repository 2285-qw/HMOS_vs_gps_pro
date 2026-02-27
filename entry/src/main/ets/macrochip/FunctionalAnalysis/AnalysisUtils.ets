export class AnalysisUtils {
  /**
   * 将字节数组转换为位数组
   * @param data 字节数组
   * @returns 位数组 (0和1组成的数组)，从低位到高位排列
   */
  public static  bytesToBits(data: Uint8Array): number[] {
    const bits: number[] = [];
    for (let byte of data) {
      // 将每个字节转换为8位，从低位到高位
      for (let i = 0; i <= 7; i++) {
        bits.push((byte >> i) & 1);
      }
    }
    return bits;
  }

  /**
   * 从位数组中解析指定长度的数值
   * @param bits 位数组 (低位到高位排列)
   * @param length 位长度
   * @returns 解析出的数值
   */
  public static parseBits(bits: number[], length: number): number {
    let value = 0;
    // 获取需要的length长度的元素
    const targetBits = bits.splice(0, length);

    // 计算数值，从低位到高位排列，所以需要倒序处理
    for (let i = targetBits.length - 1; i >= 0; i--) {
      value = (value << 1) | targetBits[i];
    }
    return value;
  }
}