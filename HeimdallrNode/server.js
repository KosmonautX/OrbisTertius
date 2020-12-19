const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const AWS = require('aws-sdk');
const app = express();
const fs = require("fs");

const ddb = require('./app/config/ddb.config')
AWS.config.update({
    region: ddb.region,
    endpoint: ddb.endpoint
});

var corsOptions = {
    origin: 'http://localhost:5001',
};

app.use(cors(corsOptions));

// parse requests of content-type application/json
app.use(bodyParser.json());

// parse requests of content-type - application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: true }));

// root route
app.get('/', (req, res) => {
    res.json({ message: 'Root Access Successful' });
});

const db = require('./app/models');
const Role = db.role;

// production
// db.sequelize.sync(); 
// // dev
// db.sequelize.sync({ force: true }).then(() => {
//     console.log('Drop and Resync Db');
//     initial();
// });

// routes
require('./app/routes/auth.routes')(app);
require('./app/routes/user.routes')(app);
require('./app/routes/dynamo.routes')(app);

// set port, listen for requests
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
});

function initial() {
    Role.create({
        id: 1,
        name: 'user',
    });

    Role.create({
        id: 2,
        name: 'moderator',
    });

    Role.create({
        id: 3,
        name: 'admin',
    });
}

const dynamodb = new AWS.DynamoDB({endpoint: new AWS.Endpoint("http://dynamodb:8000")});
const user_template = require('./blueprint/user_table.json');
const orb_template = require('./blueprint/orb_net_table.json')

dynamodb.createTable(user_template, function(err, data) {
    if (err) {
        if (err.code === "ResourceInUseException" && err.message === "Cannot create preexisting table") {
            console.log("message ====>" + err.message);
            debugger;
        } else {

            console.log("ERR: ", err);

        }
    } else{
        console.log("USER TABLE CREATED: ", data);
    }
});

dynamodb.createTable(orb_template, function(err, data) {
    if (err) {
        if (err.code === "ResourceInUseException" && err.message === "Cannot create preexisting table") {
            console.log("message ====>" + err.message);
        } else {

            console.log("ERR: ", err);

        }

    } else{
        console.log("ORB TABLE CREATED: ", data);
    }
});
