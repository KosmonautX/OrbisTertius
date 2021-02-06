const axios = require('axios');
const dynaUser = require('./dynamoUser');
const geohash = require('./geohash');

async function getRecipient (body) {
    try {
        const geohashing = geohash.postal_to_geo(body.postal_code);
        let blockedList = await dynaUser.getBlockedList(body).catch(err => {
            err.status = 500;
            throw err;
        });
        let blockedUsers = [];
        if (blockedList.Count != 0) {
            blockedList.Items.forEach( item => {
                blockedUsers.push(parseInt(item.SK.slice(4)));
            });
        }
        if (body.commercial == true || body.commercial.toLowerCase() == 'true') {
            let users = await dynaUser.getCommercialUsers(geohashing).catch(err => {
                err.status = 500;
                throw err;
            });
            if (users.Count == 0 ) {
                return [];
            } else {
                let users_arr = [];
                users.Items.forEach( item => {
                    users_arr.push(parseInt(item.SK.slice(5)));
                });
                if (blockedUsers.length > 0) {
                    users_arr = users_arr.filter(item => !blockedUsers.includes(item))
                }
                return users_arr;
            }
        } else {
            let users = await dynaUser.getAllUsers(geohashing).catch(err => {
                err.status = 500;
                throw err;
            });
            if (users.Count == 0 ) {
                return [];
            } else {
                let users_arr = [];
                users.Items.forEach( item => {
                    users_arr.push(parseInt(item.SK.split('#')[1]));
                });
                if (blockedUsers.length > 0) {
                    users_arr = users_arr.filter(item => !blockedUsers.includes(item))
                }
                return users_arr;
            }
        }
    } catch (err) {
        console.log(err)
    }
};

async function postOrbOnTele(body, recipients) {
    try {
        const response = await axios.post('http://localhost:7000/api/fizz/tele/posting', {

            // fizzbarId: 0,
            // name: body.username,
            // purpose: "From App",
            orb_UUID: 0,
            // acceptor_id: 0,
            user_id: body.user_id,
            star_user: false,
            tele_username: body.username,
            // message_id: 0,
            user_location: body.postal_code,
            title: body.title,
            info: body.info,
            where: body.where,
            when: body.when,
            tip: body.tip,
            user_id_list: recipients,
            if_commercial: false,
        })
        // console.log(body);
    } catch (err) {
        console.log(err);
    }
};

module.exports = {
    getRecipient: getRecipient,
    postOrbOnTele: postOrbOnTele,
};