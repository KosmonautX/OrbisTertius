module.exports = {
    dyna: process.env.DYNA,
    sthree: process.env.STHREE || "http://localstack:3000",
    mercury: "http://mercury:3000",
    sthreebucket: process.env.BUCKET || "orbistertius" ,
    region: "ap-southeast-1",
    tableNames: {
        orb_table: process.env.TABLE || "ORB_NET"
    },
};
