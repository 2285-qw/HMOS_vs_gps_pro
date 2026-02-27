export class CRC16 {
  /**
   * @param buffer
   * @return
   */
  static CRC16_CCITT(buffer: Uint8Array): number {
    let wCRCin: number = 0x0000;
    let wCPoly: number = 0x8408;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= wCPoly;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0x0000;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_CCITT_FALSE(buffer: Uint8Array): number {
    let wCRCin: number = 0xffff;
    let wCPoly: number = 0x1021;
    for (let b of buffer) {
      for (let i = 0; i < 8; i++) {
        let bit: boolean = ((b >> (7 - i)) & 1) === 1;
        let c15: boolean = ((wCRCin >> 15) & 1) === 1;
        wCRCin <<= 1;
        if (c15 !== bit) {
          wCRCin ^= wCPoly;
        }
      }
    }
    wCRCin &= 0xffff;
    return wCRCin ^ 0x0000;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_XMODEM(buffer: Uint8Array): number {
    let wCRCin: number = 0x0000;
    let wCPoly: number = 0x1021;
    for (let b of buffer) {
      for (let i = 0; i < 8; i++) {
        let bit: boolean = ((b >> (7 - i)) & 1) === 1;
        let c15: boolean = ((wCRCin >> 15) & 1) === 1;
        wCRCin <<= 1;
        if (c15 !== bit) {
          wCRCin ^= wCPoly;
        }
      }
    }
    wCRCin &= 0xffff;
    return wCRCin ^ 0x0000;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_X25(buffer: Uint8Array): number {
    let wCRCin: number = 0xffff;
    let wCPoly: number = 0x8408;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= wCPoly;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0xffff;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_MODBUS(buffer: Uint8Array): number {
    let wCRCin: number = 0xffff;
    let POLYNOMIAL: number = 0xa001;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= POLYNOMIAL;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0x0000;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_IBM(buffer: Uint8Array): number {
    let wCRCin: number = 0x0000;
    let wCPoly: number = 0xa001;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= wCPoly;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0x0000;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_MAXIM(buffer: Uint8Array): number {
    let wCRCin: number = 0x0000;
    let wCPoly: number = 0xa001;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= wCPoly;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0xffff;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_USB(buffer: Uint8Array): number {
    let wCRCin: number = 0xFFFF;
    let wCPoly: number = 0xa001;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= wCPoly;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0xffff;
  }

  /**
   * @param buffer
   * @return
   */
  static CRC16_DNP(buffer: Uint8Array): number {
    let wCRCin: number = 0x0000;
    let wCPoly: number = 0xA6BC;
    for (let b of buffer) {
      wCRCin ^= (b & 0x00ff);
      for (let j = 0; j < 8; j++) {
        if ((wCRCin & 0x0001) !== 0) {
          wCRCin >>= 1;
          wCRCin ^= wCPoly;
        } else {
          wCRCin >>= 1;
        }
      }
    }
    return wCRCin ^ 0xffff;
  }
}