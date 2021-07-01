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
app.use(bodyParser.json({ limit: `500mb` }));
app.use(bodyParser.urlencoded({ limit: `500mb`, extended: true, parameterLimit: 50000 }));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, `public`)));
app.use(cors({ exposedHeaders: `Content-Disposition` }));

// root route
app.get('/', (req, res) => {
    res.json({ message: 'Root Access Successful' });
});

if(process.env.NODE_ENV == "dev"){
    app.post('/auth_server' , function (req,res) {
        let payload = {};
        if (!req.body.user_id){
            payload.device_id = req.body.device_id
            payload.username = "AttilaHun"
            payload.role = "barb"
        } else {
            payload.user_id = req.body.user_id;
            payload.username = "ChongaldXrump";
            payload.role = "pleb";
        }
        const iss = 'Princeton';
        const sub = 'ScratchBac';
        const exp = '20min'
        const signOptions = {
            issuer: iss,
            subject: sub,
            expiresIn: exp,
            algorithm: 'HS256',
        };
        const token = jwt.sign(payload, secret, signOptions);
        res.send({payload: token});
    });
}


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
	let status = err.status || 500;
	res.status(status);
	res.send({
		"status": status,
		"message": err.message
	});
});

function verifyToken(req, res, next) {
    // use firebase auth to preserve functionality
    try {
		const iss = "Princeton";
		const sub = "ScratchBac";
		const exp = "1d";
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
		if (err.message == "maxAge exceeded") err.status = 403;
        if (err.message == "jwt expired") err.status = 403;
      	next(err);
    }
}

fyr.initializeApp({
    credential: fyr.credential.cert({
        "type": "service_account",
        "project_id": "scratchbac-v1-ee11a",
        "private_key_id": "5a37185e016ecc397228fc6f6fea664f76bb4ccd",
        "private_key": process.env.FYR_KEY.replace(/\\n/g, '\n'),
        "client_email": "firebase-adminsdk-b1dh2@scratchbac-v1-ee11a.iam.gserviceaccount.com",
        "client_id": "110193704511744996466",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-b1dh2%40scratchbac-v1-ee11a.iam.gserviceaccount.com"
    }),
    authDomain: "scratchbac-v1-ee11a.firebaseapp.com"         // Auth with popup/redirect
    // databaseURL: "https://YOUR_APP.firebaseio.com", // Realtime Database
  // storageBucket: "YOUR_APP.appspot.com",          // Storage
  // messagingSenderId: "123456789",                 // Cloud Messaging
  // measurementId: "G-12345"                        // Analytics
  });

function fyrwalk(req, res, next) {
  fyr
    .auth()
    .verifyIdToken(req.headers["authorization"])
    .then((decodedToken) => {
        req.user_id = decodedToken.uid;
      next();
    })
    .catch((error) => {
        let err = new Error(`Google Token Unauthorised`);
			err.status = 401;
			next(err);
    });
}

module.exports = { app: app };
