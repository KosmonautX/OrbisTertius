const axios = require('axios')

async function teleChannelPipeline(payload, userdeetz, channel){
  try{
    const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
    // channel to channel_id map
    change_channel= {
      "report": "-1001258902545",
      "complete": "-1001215181818",
      "read_post": "-1001250889655",
      "lonely": "-1001527758138"
    }
    let message = `You have a message from ${userdeetz.username} <code> ${userdeetz.user_id}</code>`
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
