const createError = require(`http-errors`);
const express = require(`express`);
const path = require(`path`);
const cookieParser = require(`cookie-parser`);
const bodyParser = require(`body-parser`);
const logger = require(`morgan`);
const moment = require(`moment`);
const jwt = require(`jsonwebtoken`);
const app = express();
const cors = require(`cors`);
const AWS = require('aws-sdk');
const fs = require("fs");
const fyr = require("firebase-admin");

const secret = process.env.SECRET_TUNNEL;
const log = '../timber';

logger.token(`date`, () => {
	return moment().format(`YYYY-MM-DD HH:mm:ss`);
});

require(`log-prefix`)(function () {
	return `[` + moment().format(`YYYY-MM-DD HH:mm:ss`) + `]`;
});

// app.use(logger(`[:date] :method :url :status :res[content-length] - :response-time ms`));
if (!fs.existsSync(log)){
    fs.mkdirSync(log);
}
app.use(logger('common', {
	stream: fs.createWriteStream(log + '/access.log' , {flags: 'a'}, {mode: 0o755 })
}));
app.use(bodyParser.json({ limit: `8mb` }));
app.use(bodyParser.urlencoded({ limit: `8mb`, extended: true, parameterLimit: 50000 }));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, `public`)));
app.use(cors({ exposedHeaders: `Content-Disposition` }));

// root route
app.get('/', (req, res) => {
    res.json({ message: 'Root Access Successful' });
});

require(`./route_paths/orb_net`)(app, verifyToken, fyrwalk);

// set port, listen for requests
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
});

try{
    const dynamodb = new AWS.DynamoDB({endpoint: new AWS.Endpoint("http://dynamodb:8000")});
    // const user_template = require('./blueprint/user_table.json');
    const orb_template = require('./blueprint/orb_net_table.json');

    // dynamodb.createTable(user_template, function(err, data) {
    //     if (err) {
    //         console.log("ERR: ", err);
    //     } else{
    //         console.log("USER TABLE CREATED: ", data);
    //     }
    // });

    dynamodb.createTable(orb_template, function(err, data) {
        if (err) {
            console.log("ERR: ", err);
        } else{
            console.log("ORB TABLE CREATED: ", data);
        }
    });

}
catch (err){
    if (err.code === "ResourceInUseException" && err.message === "Cannot create preexisting table") {
        console.log("message ====>" + err.message);
    } else {
        console.error("Unable to create table. Error JSON:", JSON.stringify(err, null, 2)); 
    }
}


// catch 404 and forward to error handler
let error404Map = new Map();
app.use(function (req, res, next) {
	let err = `${req.method} -> ${req.originalUrl} is not a proper route!`;
	if (!error404Map.get(err)) {
		if (req.originalUrl.includes(`.jpeg`) || req.originalUrl.includes(`.png`)) {
		} else console.debug(err);
	} else {
		error404Map.set(err, true);
	}
	next(createError(404));
});

// error handler
app.use(function (err, req, res, next) {
	// set locals, only providing error in development
	res.locals.message = err.message;
	res.locals.error = req.app.get(`env`) === `development` ? err : {};
	// render the error page
    if(typeof(err.status) == "number"){
        let status = err.status || 500;
        res.status(status).send({
            "status": status,
            "message": err.message
        });}
});

function verifyToken(req, res, next) {
    // use firebase auth to preserve functionality
    try {
		const iss = "Princeton";
		const sub = "ScratchBac";
		const exp = "7d";
		const verifyOptions = {
			issuer : iss,
			subject : sub,
			maxAge : exp,
			algorithms : ["HS256"]
		};
		req.token = req.headers["authorization"] || "";
		req.token = req.token.replace(/BEARER /gi, ``);
		// prod!
        if (req.token) {
			req.verification = jwt.verify(req.token, secret, verifyOptions);
			next();
		} else {
			let err = new Error(`No token, please login again!`);
			err.status = 401;
			next(err);
		}
    } catch (err) {
		if (err.message == "maxAge exceeded") err.status = 401;
        if (err.message == "jwt expired") err.status = 401;
      	next(err);
    }
}

{
    let proj = process.env.FYR_PROJ
    fyr.initializeApp({
        credential: fyr.credential.cert({
            "project_id": proj,
            "private_key": process.env.FYR_KEY.replace(/\\n/g, '\n'),
            "client_email": process.env.FYR_EMAIL,
        }),
        authDomain: proj+".firebaseapp.com"         // Auth with popup/redirect
        // databaseURL: "https://YOUR_APP.firebaseio.com", // Realtime Database
        // storageBucket: "YOUR_APP.appspot.com",          // Storage
        // messagingSenderId: "123456789",                 // Cloud Messaging
        // measurementId: "G-12345"                        // Analytics
    });
}

function fyrwalk(req, res, next) {
    fyr
        .auth()
        .verifyIdToken(req.headers["authorization"])
        .then((decodedToken) => {
            res.user_id = decodedToken.uid;
            next();
        })
        .catch((error) => {
            if (error.code == 'auth/id-token-revoked') {
                let err = new Error(`Signout User`);
			    err.status = 401;
			    next(err);
            }else{
                let err = new Error(`Google Token Unauthorised`);
			    err.status = 401;
		        next(err);
            }
        });
}

module.exports = { app: app };
