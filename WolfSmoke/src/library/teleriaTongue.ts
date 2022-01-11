import {Mutation} from "../types/parsesTongue"
const CHANNEL_ID = "-1001239569373"
import axios from 'axios';
interface TelegramORBPost{
     [key: string]: string;
}


export async function telePostOrb(newRecord: Mutation) : Promise<void>{
    try{
        if(nature_taxonomy_parser("app_origin",newRecord.payload.orb_nature)){
            const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
            const data = new URLSearchParams();
            data.append('chat_id', CHANNEL_ID);
            var payload: TelegramORBPost = {... newRecord.payload}
            payload.orb_uuid = newRecord.PK.slice(4)
            payload.username = Math.random().toString(36).substr(3,4) + Math.random().toString().substr(2,2)
            var queryString = Object.keys(payload).filter((key) => !['tags','available','expires_in'].includes(key)).map(key => key + '=' + payload[key]).join('&');
            let message =  "https://angora.post/?" + encodeURI(queryString)
            data.append('text', message);
            return await axios.post(url, data)
        }
    }catch(e){
        console.log(e)
    }

}

export async function teleExtinguishOrb(newRecord: Mutation) : Promise<void>{
    try{
        if(!newRecord.available){
        const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
        const data = new URLSearchParams();
        data.append('chat_id', CHANNEL_ID);
        var payload: TelegramORBPost = {orb_uuid: newRecord.SK.substr(4)}
        var queryString = Object.keys(payload).map(key => key + '=' + payload[key]).join('&');
        let message =  "https://angora.delete/?" + encodeURI(queryString)
        data.append('text', message);
        return await axios.post(url, data)
        }
    }catch(e){
        console.log(e)
    }

}

function nature_taxonomy_parser(trait: string, nature: number) : boolean{
    switch(trait){
            case "telegram_origin":
            return digit_parser(0,nature) === 0
            case "app_origin":
            return digit_parser(0,nature) === 1
            default:
            return false
    }
}

function digit_parser(position: number, nature: number){
  var len = Math.floor( Math.log(nature) / Math.LN10 ) - position;
  return ( (nature / Math.pow(10, len)) % 10) | 0;
}
