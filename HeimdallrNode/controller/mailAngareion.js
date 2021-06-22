const AWS = require('aws-sdk');
let config = require('../config/ddb.config')
AWS.config.update({
    region: config.region
});
const moment = require('moment');
const nodemailer = require("nodemailer");

switch(process.env.NODE_ENV)
{
  case "dev": s3 = new AWS.SESV2({endpoint:config.sthree, apiVersion: "2019-09-27", });break;
  case "stage": s3 = new AWS.SESV2({apiVersion: "2019-09-27", region: config.region,}); break;
  case "prod": s3 = new AWS.SESV2({apiVersion: "2019-09-27", region: config.region,}); break;
}

// let transporter = nodemailer.createTransport({
//     SES: { ses, aws },
//   });



var Angareion = {}

Angareion.Mail = (function (){
  var interface = {};

  send = async(body, link) => {
    let transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'randomran9898@gmail.com',
        pass: 'Randomran98',
    }
    });
    let mailOptions = {
                from: "randomran9898@gmail.com",
                to: body.mail,
                subject: 'Confirm Email',
                html: `<div>Please click this link to confirm your email: <a href="${link}">Here COmraded </a></div>`,
            }

    return transporter.sendMail(mailOptions)
  }

  interface.signup = async (body,link) => {
    return await send(body,link);
  };

  return interface;

})();


module.exports = {
  Angareion: Angareion
}
