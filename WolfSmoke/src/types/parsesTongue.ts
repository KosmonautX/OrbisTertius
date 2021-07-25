export interface Mutation {
    PK: string
    SK: string
    inverse?: string
    geohash?: number
    time?: number
    identifier?: string
    numeric?: number
    alphanumeric?: string
    payload?: any
}
// extend KeyElementto Relations and Time
export interface KeyElement{
    archetype: string
    id: string
    access?: string
    bridge?: string
    relationid?: string
}
