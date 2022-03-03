export interface LatLonPoint {
    latitude: number;
    longitude: number;
    error: {
      latitude: number;
      longitude: number;
    }
}

export type Direction = [number,number]
export type LatLonBox = [number, number, number, number]
