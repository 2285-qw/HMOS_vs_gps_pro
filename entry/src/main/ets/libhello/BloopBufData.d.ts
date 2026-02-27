// entry/src/main/ets/types/native.d.ts
declare module 'vison_main.so' {
  export function createBuffer(bufType: number, memSize: number): bigint;
  export function writeData(handle: bigint, data: Uint8Array, len: number): number;
  export function getOneFrame(handle: bigint, head: Uint8Array, frame: Uint8Array): number;
  // 其他方法声明
}