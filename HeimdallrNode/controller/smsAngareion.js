const algorithm = 'aes-256-ctr';
const ENCRYPTION_KEY = process.env.SECRET_TUNNEL;
const IV_LENGTH = 16;
const axios = require('axios')

async function sms(body, messagebody) {
    let url = "http://10.12.184.21:8082/"
    let config = {
      headers:{
        Authorization:'3f4e4360'
      }
    }
      return await axios.post(url, {
        to: body.number,
        message: messagebody
        }, config);
}
