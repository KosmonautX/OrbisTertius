module.exports = {
    dyna: process.env.DYNA,
    sthree: "http://localstack:3000",
    sthreelinkexpiry: 1200,
    admin_ids: new Set(["OpCaNTXKWaVsj7814yTzwul9PAU2"]),
    territory_markers: [8, 9, 10],
    sthreebucket: process.env.BUCKET || "orbistertius" ,
    region: process.env.AWS_DEFAULT_REGION,
    tableNames: {
        orb_table: process.env.TABLE || "ORB_NET"
    },
};
