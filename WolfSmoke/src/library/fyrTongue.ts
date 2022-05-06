import {Mutation, KeyElement} from "../types/parsesTongue"
import {KeyParser} from "./parsesUrTongue"
import {transcode_hexhash} from "../utils/geohash"
import { territory_markers } from "../config/config";

interface Message{
    notification:Object
    data?:Object
    topic?: string
    token?: string
}

interface GeoHash{
    hash: string
    radius: number
}
interface Location{
    geohashing: GeoHash
    geohashingtiny: string

}

// interface PubOrbGeoHash{
//     hashes: Array<number>
//     radius: number
//     geolock: boolean
//     geofence: Array<number>
//     hash: number

// }
interface TerritoryPub{
    [index: string]: Location
}

//type Message =  Map<string, Map<string, string|number>|string>

async function subscribe(token:string, topic:string, client:any): Promise<void>{
    client.subscribeToTopic(token, topic).then((response: any) => {console.log("Topic Subscribed", "Topic", topic)
                                                                   console.dir(response, { depth: null })
                                                                  })
        .catch((error:any)=>{
            console.log("Error sending Subscribing to Topic")
            console.dir(error, { depth: null })
        });
}

async function unsubscribe(token:string, topic:string, client:any): Promise<void>{
    client.unsubscribeFromTopic(token, topic)
        .catch((error:any)=>{
            console.log("Error sending Message" , error)
        });
}

async function sendsubscribers(message: Message ,topic: string, client: any): Promise<void>{
    message["topic"]= topic
    client.send(message).then((response: any) => {console.log("Message Sent", "Response", response, "Topic", topic)})
        .catch((error: any) => {
            console.log(`Error sending to Topic: ${topic}`)
            console.dir(error, { depth: null });
        });

}

async function sendone(message: Message ,token: string, client: any): Promise<void>{
    message["token"]= token
    client.send(message)
        .catch((error: any) => {
            console.dir(error, { depth: null });
        });

}

async function messenger(newRecord: Mutation, Element: KeyElement, client:any): Promise<void>{
    if(Element.archetype === "ORB"){
        let message = {
            notification:  {
                "title": `New Post`,
                "body": `${newRecord.payload.title}...`
            },
            data:{
                "archetype": Element.archetype,
                "id": Element.id,
                "state": "INIT",
                "time": String(newRecord.time)
            }}
        var count = 0, hash_len = newRecord.geohash.hashes.length
        while( count < hash_len) {
            let loc_topic = "LOC."+ newRecord.geohash.hashes[count] + "." + newRecord.geohash.radius
            sendsubscribers(message, loc_topic, client)
            count ++
        }}

}


// async function diffObj(): Promise,


// switch to archetype based constructor
async function switchtoken(archetype:string,topic : string | number, client: any, newtoken: string,  oldtoken?: string): Promise<void>{
    try{
        if(newtoken) subscribe(newtoken,archetype+ "." +String(topic),client)
            .catch((error) => {
                console.log('Error subscribing to topic:', error);
            });
        ;
        if(oldtoken) unsubscribe(oldtoken,archetype+ "." +String(topic),client)
            .catch((error) => {
                console.log('Error unsubscribing from topic:', error);
            });
        ;
    }
    catch(e){
        console.log(e)
    }
}

// switch fcm token on identifier
async function switchsubscribe(archetype:string, token : string, client: any, newtopic?: string | number,  oldtopic?: string| number,): Promise<void>{
    try{
        if(newtopic) subscribe(token,archetype+ "." +String(newtopic),client)
            .catch((error) => {
                console.log('Error subscribing to topic:', error);
            });
        ;
        if(oldtopic) unsubscribe(token,archetype+ "." +String(oldtopic),client)
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

// beacon under rework to subscriber token centered system
export async function triggerBeacon(newRecord: Mutation, client: any, oldRecord: Mutation): Promise<void>{
    try {
        // generalise into KeyElementRElations later
        if(newRecord.identifier){
            var Element:KeyElement
            Element = KeyParser(newRecord.PK, newRecord.SK)
            if (Element?.access==="pub"){
            if(oldRecord.identifier){
                if(newRecord.identifier !== oldRecord.identifier) switchtoken("USR", Element.id, client,  newRecord.identifier, oldRecord.identifier)
                else switchtoken("USR", Element.id, client,  newRecord.identifier, oldRecord.identifier)
            }}}
    } catch (e) {
        console.log(e)
    }
}

export async function territory_subscriber(neoTerritory: TerritoryPub, identifier: string, client: any, retroTerritory?: TerritoryPub): Promise<void>{
    try {
        if(retroTerritory){
            Object.entries(neoTerritory).forEach(([geoName, address]) =>{
                if(!retroTerritory[geoName]){
                    switchsubscribe("LOC",identifier,client, address.geohashing.hash + "." + address.geohashing.radius)
                    if(address.geohashingtiny) {
                        for (const radius of territory_markers) {
                            if(radius != address.geohashing.radius) {
                                switchsubscribe("LOC",identifier,client, transcode_hexhash(address.geohashingtiny, radius) + "." + radius)
                            }
                        }
                    }
                }
                else if(address.geohashing.hash !== retroTerritory[geoName].geohashing.hash){
                    switchsubscribe("LOC", identifier, client, address.geohashing.hash + "." + address.geohashing.radius, retroTerritory[geoName].geohashing.hash + "." + retroTerritory[geoName].geohashing.radius)
                    if(address.geohashingtiny) {
                        for (const radius of territory_markers) {
                            if(radius != address.geohashing.radius) {
                                let newTer = transcode_hexhash(address.geohashingtiny, radius) + "." + radius
                                let oldTer = transcode_hexhash(retroTerritory[geoName].geohashingtiny, radius) + "." + radius
                                switchsubscribe("LOC",identifier,client, newTer, oldTer)
                            }
                        }
                    }
                }

            })}
        else{
            Object.entries(neoTerritory).forEach(([_geoName, address]) =>{
                switchsubscribe("LOC",identifier,client, address.geohashing.hash + "." + address.geohashing.radius)
                    if(address.geohashingtiny) {
                        for (const radius of territory_markers) {
                            if(radius != address.geohashing.radius) {
                                switchsubscribe("LOC",identifier,client, transcode_hexhash(address.geohashingtiny, radius) + "." + radius)
                            }
                        }
                    }
            })
        }
    } catch (e) {
        console.log(e)
    }
}

export async function mutateTerritorySubscription(newRecord: Mutation, client: any,  oldRecord?: Mutation): Promise<void>{
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

export async function beckonComment(newRecord: Mutation, client: any): Promise<void>{
    try{
        if(newRecord.identifier){
            var Element = KeyParser(newRecord.PK, newRecord.SK)
            switch(Element.archetype){
                case 'COM':
                    switchsubscribe("COM",newRecord.identifier,client, Element.id)
                    let orb_message = {
                        notification:{
                            "title": `${newRecord.payload.username} commented on your post...`, // username
                            "body": `${newRecord.payload.comment}`},
                        data:{
                            "archetype": Element.archetype,
                            "id": Element.id,
                            "orb_uuid": newRecord.payload.orb_uuid,
                            "time": String(newRecord.time)
                        }}
                    sendsubscribers(orb_message, "ORB." + newRecord.payload.orb_uuid , client)
                            .catch((error)=>{
                                console.log("Error sending Message" , error)
                            })
                    // send message to ORB
                    break;
                case 'COMCOM':
                    switchsubscribe("COM",newRecord.identifier,client, Element.relation)
                    let com_message = {
                        notification:{
                            "title": `${newRecord.payload.username} replied to your comment...`, // username
                            "body": `${newRecord.payload.comment}`},
                        data:{
                            "archetype": Element.archetype,
                            "id": String(Element.id),
                            "parent": Element.relation,
                            "orb_uuid": newRecord.payload.orb_uuid,
                            "time": String(newRecord.time)
                        }}
                    sendsubscribers(com_message, "COM." +  Element.relation, client).catch((error)=>{
                        console.log("Error sending Message" , error)
                    })
                    // switchsubscribe("ORB",newRecord.identifier,client, newRecord.PK.slice(4) + "." + newRecord.inverse.slice(4,8))
                    break;
            }

        }

    } catch(e){
        console.log(e)
    }


}

export async function mutateActorSubscription(newRecord: Mutation, client: any,   _oldRecord?: Mutation): Promise<void>{
    try {
        //send through KeyElement later
        if(newRecord.identifier && newRecord.inverse){
            switch(newRecord.inverse.slice(0,8)){
                case '600#INIT':
                    switchsubscribe("ORB",newRecord.identifier,client, newRecord.PK.slice(4))
                    break;
                case '500#ACPT':
                    switchsubscribe("ORB",newRecord.identifier,client, newRecord.PK.slice(4))
                    // switchsubscribe("ORB",newRecord.identifier,client, newRecord.PK.slice(4) + "." + newRecord.inverse.slice(4,8))
                    break;
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
