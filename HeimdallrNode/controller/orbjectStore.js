const ddb_config = require('../config/ddb.config');
const AWS = require('aws-sdk');
switch(process.env.NODE_ENV)
{
  case 'dev': s3 = new AWS.S3({endpoint:ddb_config.sthree, s3ForcePathStyle: true, signatureVersion: 'v4'}); break;
  case 'stage': s3 = new AWS.S3({region:ddb_config.region, signatureVersion: 'v4'}); break;
  case 'prod': s3 = new AWS.S3({region:ddb_config.region, signatureVersion: 'v4'}); break;
}

const serve3 = {
  async preSign(action,entity, uuid, form, retry=5) {
    try{
    var sign = s3.getSignedUrl(action, {
      Bucket: ddb_config.sthreebucket,
      Key: entity+ '/' +uuid + '/' + form, Expires: ddb_config.sthreelinkexpiry
    });
    if(sign.length < 50 && retry > 0){
      retry --
      console.log(sign)
      sign = serve3.preSign(action,entity,uuid,form, retry);}

      return sign;}
    catch(error){
      console.log(e)
    }
  },

};

module.exports= {
  serve3:serve3
}
