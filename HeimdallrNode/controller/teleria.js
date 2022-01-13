const axios = require('axios')

async function teleChannelPipeline(userdeetz, channel, payload = {}){
  try{
    let message = ''
    const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
    // channel to channel_id map
    change_channel= {
      "report": "-1001258902545",
      "complete": "-1001215181818",
      "read_post": "-1001250889655",
      "lonely": "-1001527758138"
    }

    switch(channel){
      case "lonely":
        message = `You have a message from ${userdeetz.username},
                   USR_ID: <code> ${userdeetz.user_id}</code>`
        break;
      case "report":
        message = `A report was sent by ${userdeetz.username},
                       USR_ID: <code> ${userdeetz.user_id}</code>
                       within ORB_UUID: <code> ${payload.orb_uuid}</code> for ${payload.reasons} `
        break;
    }

    return await axios.post(url,{
      chat_id: change_channel[channel],
      parse_mode: "HTML",
      text: message
      // "reply_markup": {
      //   "inline_keyboard": [
      //     [
      //       {
      //         "text": "Red",
      //         "callback_data": "Red"
      //       },
      //     ]
      //   ]
      // }
    })
  }catch(e){
    console.log(e)
  }}

module.exports= {
  teleChannelPipeline:teleChannelPipeline
}
