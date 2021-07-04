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
interface KeyElement{
    archetype: string
    id: string
    access?: string
    bridge?: string
    relationid?: string
}

interface Message{
    notification:Object
    data?:Object
    topic?: string
}

//type Message =  Map<string, Map<string, string|number>|string>

function KeyParser(PK:string, SK:string)
{
    if(SK.startsWith(PK))
    {
        let attr = SK.split('#')
        let Element: KeyElement = {archetype:attr[0], id: attr[1]};
        Element.access = attr[2]
        Element.bridge = attr[3]
        return Element
    }
    // else
    //     {
    //         let relation = SK.split('#')
    //         let entity = PK.split('#')
    //         let Element: KeyElement = {archetype:entity[0]+relation[0], id: entity[1], relationid: relation[1]}

    //     }
}

async function subscribe(token:string, topic:string, client:any): Promise<void>{
    const topic_new = "/topics/" + topic;
    client.subscribeToTopic(token, topic_new).then((response:any) => {console.log("Message Sent", response)})
            .catch((error:any)=>{
                console.log("Errpr sending Message" , error)
            });
}

async function unsubscribe(token:string, topic:string, client:any): Promise<void>{
    const topic_old = "/topics/" + topic;
    client.subscribeToTopic(token, topic_old).then((response:any) => {console.log("Message Sent", response)})
            .catch((error:any)=>{
                console.log("Errpr sending Message" , error)
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
                console.log("Errpr sending Message" , error)
            })
    }}



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

export async function insnotif(newRecord: Mutation, client: any): Promise<void>{
    try {
        if(newRecord.PK === newRecord.SK) {
            let Element = KeyParser(newRecord.PK, newRecord.SK);
            if (Element) await messenger(newRecord,Element,client);}
    } catch (e) {
            console.log(e)
        }
}

export async function modnotif(newRecord: Mutation, client: any,  oldRecord?: Mutation): Promise<void>{
    try {
        if(newRecord.identifier){
            var Element = KeyParser(newRecord.PK, newRecord.SK);
            if (Element?.access==="pub"){
                if (newRecord.geohash!==oldRecord?.geohash){
                    await switchsubscribe("LOC",newRecord.identifier,client, newRecord.geohash,oldRecord?.geohash)
                }
                else if (newRecord.numeric !== oldRecord?.numeric){
                    await switchsubscribe("LOC",newRecord.identifier,client, newRecord.numeric,oldRecord?.numeric)
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
