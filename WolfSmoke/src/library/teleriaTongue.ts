import {Mutation} from "../types/parsesTongue"
const CHANNEL_ID = "-1001239569373"
import axios from 'axios';
interface TelegramORBPost{
     [key: string]: string;
}


export async function telePostOrb(newRecord: Mutation) : Promise<void>{
    try{
        const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
        const data = new URLSearchParams();
        data.append('chat_id', CHANNEL_ID);
        var payload: TelegramORBPost = {... newRecord.payload}
        payload.orb_uuid = newRecord.PK.slice(4)
        var queryString = Object.keys(payload).filter((key) => !['tags','available','expires_in'].includes(key)).map(key => key + '=' + payload[key]).join('&');
        let message =  "https://angora.post/?" + encodeURI(queryString)
        data.append('text', message);
        return await axios.post(url, data)
    }catch(e){
        console.log(e)
    }

}

export async function teleExtinguishOrb(oldRecord: Mutation) : Promise<void>{
    try{
        const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
        const data = new URLSearchParams();
        data.append('chat_id', CHANNEL_ID);
        var payload: TelegramORBPost = {orb_uuid: oldRecord.SK.substr(15)}
        var queryString = Object.keys(payload).map(key => key + '=' + payload[key]).join('&');
        let message =  "https://angora.delete/?" + encodeURI(queryString)
        data.append('text', message);
        return await axios.post(url, data)
    }catch(e){
        console.log(e)
    }

}
