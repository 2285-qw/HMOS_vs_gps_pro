export interface OnDeviceConnectionListener{
  onDeviceConnection: (type: ExternalDevType) => void;
  onDeviceDisconnection: (type: ExternalDevType) => void;
}
export enum ExternalDevType {
  WIFI,
  USB
}
