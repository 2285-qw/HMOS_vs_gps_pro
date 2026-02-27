
 export interface AnalysisListener{
  data:(type: number, data?: Uint8Array) => void;
}