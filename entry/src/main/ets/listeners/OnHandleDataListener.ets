import { ExternalDevType } from './OnDeviceConnectionListener';

export enum ConnectionType {
  UDP,
  TCP,
  USB,
}

export interface OnHandleDataListener {
  onHandleData: (connectionType: ConnectionType, devTypes: ExternalDevType, data: Uint8Array) => void;
}
