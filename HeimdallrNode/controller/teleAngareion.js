const axios = require('axios');

async function exchangeContact(contacted,user_id,username,title){
    try {
        const url = `https://api.telegram.org/bot${process.env.NEIB}/sendMessage`
        const data = new URLSearchParams();
        data.append('chat_id', contacted);
        message = `Click [here](tg://user?id=${user_id}) to message *${username}* about: ${title}`
        data.append('text', message);
        data.append('parse_mode', "markdown")
        return await axios.post(url, data)
    } catch (err) {
        console.log(err)
    }
};

module.exports = {
    exchangeContact:exchangeContact
};
