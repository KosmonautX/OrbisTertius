module.exports = {
    dyna: process.env.DYNA || "http://dynamodb:8000",
    sthree: process.env.STHREE || "http://localstack:3000",
    mercury: "http://mercury:3000",
    sthreebucket: "orbis-tertius" ,
    region: "ap-southeast-1",
    tableNames: {
        orb_table: "ORB_NET"
    },
};
