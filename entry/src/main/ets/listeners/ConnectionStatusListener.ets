export interface ConnectionStatusListener{
  onDeviceConnection: () => void;
  onDeviceDisconnection: () => void;
}
