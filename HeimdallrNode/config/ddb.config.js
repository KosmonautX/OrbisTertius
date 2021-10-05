module.exports = {
    dyna: process.env.DYNA,
    sthree: "http://localstack:3000",
    sthreelinkexpiry: 60,
    sthreebucket: process.env.BUCKET || "orbistertius" ,
    region: process.env.AWS_DEFAULT_REGION,
    tableNames: {
        orb_table: process.env.TABLE || "ORB_NET"
    },
};
