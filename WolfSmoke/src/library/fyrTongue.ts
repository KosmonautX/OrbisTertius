import {Mutation, KeyElement} from "../types/parsesTongue"
import {KeyParser} from "./parsesUrTongue"

interface Message{
    notification:Object
    data?:Object
    topic?: string
}
interface GeoHash{
    hash: number
    granularity: number
}
interface TerritoryPub{
    [index: string]: GeoHash
}

//type Message =  Map<string, Map<string, string|number>|string>

async function subscribe(token:string, topic:string, client:any): Promise<void>{
    const topic_new = "/topics/" + topic;
    client.subscribeToTopic(token, topic_new).then((response:any) => {console.log("Message Sent", response)})
            .catch((error:any)=>{
                console.log("Error sending Message" , error)
            });
}

async function unsubscribe(token:string, topic:string, client:any): Promise<void>{
    const topic_old = "/topics/" + topic;
    client.subscribeToTopic(token, topic_old).then((response:any) => {console.log("Message Sent", response)})
            .catch((error:any)=>{
                console.log("Error sending Message" , error)
            });
}

async function sendsubscribers(message: Message ,topic: string, client: any): Promise<void>{
    message["topic"]= "/topics/" +topic
    client.send(message)
        .then((response:any) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', response);
        })
        .catch((error: any) => {
            console.log('Error sending message:', error);
        });

}

async function messenger(newRecord: Mutation, Element: KeyElement, client:any): Promise<void>{
    if(Element.archetype === "ORB"){
        let message = {notification:  {
            "title": `An ${newRecord.numeric} ORB just rose in the horizon`,
            "body": `${newRecord.payload.title}...`
        },
                       data:{
                           "archetype": Element.archetype,
                           "id": Element.id,
                           "state": "INIT",
                           "time": String(newRecord.time)
        }}
        sendsubscribers(message, newRecord.alphanumeric!.replace('#',"."), client).then((response) => {console.log("Message Sent", response)})
            .catch((error)=>{
                console.log("Error sending Message" , error)
            })
    }}

// async function diffObj(): Promise,


// switch to archetype based constructor
async function switchsubscribe(archetype:string,token : string, client: any, newtopic?: string | number,  oldtopic?: string| number,): Promise<void>{
    try{
        if(newtopic) subscribe(token,archetype+ "." +String(newtopic),client).then((response) => {
            console.log('Successfully subscribed to topic:', response);
        })
            .catch((error) => {
                console.log('Error subscribing to topic:', error);
            });
        ;
        if(oldtopic) unsubscribe(token,archetype+ "." +String(oldtopic),client).then((response) => {
            console.log('Successfully unsubscribed from topic:', response);
        })
            .catch((error) => {
                console.log('Error unsubscribing from topic:', error);
            });
        ;
    }
    catch(e){
        console.log(e)
    }
}

export async function triggerNotif(newRecord: Mutation, client: any): Promise<void>{
    try {
        if(newRecord.PK === newRecord.SK){
            let Element = KeyParser(newRecord.PK, newRecord.SK);
            // shift to Location feed listener
            if (Element) await messenger(newRecord,Element,client);}
    } catch (e) {
            console.log(e)
        }
}

export async function territory_subscriber(neoTerritory: TerritoryPub, identifier: string, client: any, retroTerritory?: TerritoryPub): Promise<void>{
    try {
        if(retroTerritory){
        Object.entries(neoTerritory).forEach(([geoName, address]) =>{
            if(!retroTerritory[geoName]){
                switchsubscribe("LOC",identifier,client, address.hash)
            }
            else if(address.hash !== retroTerritory[geoName].hash){
                switchsubscribe("LOC", identifier, client, address.hash, retroTerritory[geoName].hash)}
        })}
        else{
            Object.entries(neoTerritory).forEach(([geoName, address]) =>{
                switchsubscribe("LOC",identifier,client, address.hash)
            })
        }
    } catch (e) {
            console.log(e)
        }
}

export async function mutateSubscription(newRecord: Mutation, client: any,  oldRecord?: Mutation): Promise<void>{
    try {
        if(newRecord.identifier){
            var Element = KeyParser(newRecord.PK, newRecord.SK);
            if (Element?.access==="pub"){
                if (oldRecord?.geohash){
                    if (newRecord.geohash!==oldRecord?.geohash){
                        await territory_subscriber(newRecord.geohash, newRecord.identifier, client, oldRecord.geohash)
                    }
                }
                else if(newRecord.geohash) {
                    await territory_subscriber(newRecord.geohash, newRecord.identifier, client)
                }
            }


        }   } catch (e) {
            console.log(e)
        }
}


// class BaseTongue {
//     PK: string
//     SK: string
//     old: Mutation
//     archetype?: string
//     id?: string
//     access?: string
//     bridge?: string
//     inverse?: string
//     geohash?: number
//     time?: number
//     identifier?: string
//     numeric?: number
//     alphanumeric?: string
//     Client: any

//     constructor(newRecord: Mutation, oldRecord: Mutation, client: any){

//         Object.assign(this, newRecord)
//         this.old = {... oldRecord};
//         this.PK= newRecord.PK
//         this.SK= newRecord.SK
//         if(this.SK.startsWith(this.PK))
//         {
//             let entity = this.SK.split('#')
//             this.archetype = entity[0]
//             this.id = entity[1]
//             this.access = entity[2]
//             this.bridge = entity[3]
//         }
//         this.Client = client
//     }

// }                               //

// export class ArchiveTongue extends BaseTongue{



// }