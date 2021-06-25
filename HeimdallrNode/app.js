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
      "project_id": "sbpoc-b6fcb",
      "private_key_id": "9e128768bd0d39ffbb642f489e1f3a053d2f6c66",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC0QIiII3q36p4O\nwfln9ZBtH9mAT5xZzXfiiUx7yvnGXVZCUW1Sc70PjZCwdEoBYsrwjxVSrblUAYBD\nQm08Rj8keZRJrFhILQIsGb3KYzysBQqBM4+6Bx6u9X4n+2ea+x8+tXUcebWtMSzU\n0SV7qmweLoufeNde2zTR+OSPm/bwdxjMMFwUi2wJ9tX5gwAVHWGxpZlwYrLoXLN5\nnCRVVMVzH6hk8VoHaAVsiTT+8Fy9RI3AtbmzR0YtW35zqYdWA7Pt1u/vlfDSqJIC\nisyQj3OdAtUx0koXvHM51RUbgrWkwK3gA3HyvPZkztJnVeuOXc6E+GPM+OmVa6+d\nFLWJWQGTAgMBAAECggEAAUeF+zq5PRidYkBui0DbHhMq9uCvHOoQREYyNJy7tMnm\negEG9B4IhQA9uyrleD4Mb7RW8+fHbXkMloL1sIb/yBFULp5aYA9wY6y+bp3RXpfd\n5mMzIssNz4hu3/dxBFDCUi51NCxe+umNm73CSi7q+98xCYLmOxug3oP+51AK6tOt\nMi025uV/dnj5zxu9X2Oupa8HE28hW+CJ00Z6qIQbwyVid6oPWcJMz9Tl7zI1CDpi\nS76poTs2Uon9OU/2lL4ZbkAsHt/iEOs62JR4MDk1Z4k6bNeKbbQCfs/VBaqQRvjk\nJuOJ9vdRkC+dI58cqxrajuRiAiNJ7QN4upvWsvSRRQKBgQDZSb6k8GcULnh5W6p6\nagugb4QIBdx3GdE919RazBNSEs+A1ai559Jtjzfft2n8yIDgAhhDrhG8bcIY5fWA\ny1ZM9QRo3mad7gs0pPDoFuibfE5ZxktKC6WWisXmQyLtsLqjR/HclCaJNlWIfunY\nJADqu7ZDO99ueeIjcE9APsFwvwKBgQDUXZ7kTL0j3dIKwMP8j/sUQARZTW0fpMaC\ne+og3AbepO7dgxHERTMikc40qmqj9XPdvJ648fFELPIKTmcg2ESPC8Ce47Ai2OUJ\n0Yyg3E+i+huxORkmb9Oce+GBHzqqCBwrjVLhIVgJ17KezlOEkxNr3C+P6Fkxj/2g\nrT0UXIPQLQKBgEt1H56Z2cIZbT7/xVEjmIwLjfdXSbuWnKJ0XEt3yVHcNHFSQXjl\n956SeN3ZDRZ67r5cG98NCR29pAUPftVOR9cL048zhMFdlEig6wQ+SGMOpQrqIOVC\n7Cs+YAFZ2Txf/kCL0INAc618z/FJ2Z10y1i4/U+V8D6mVxDlhLAT2wtzAoGAH+RX\nYk2r8eD0FC1SwXEV8bqTbJ3WD3R9Y0ccqAai+XinbpiqaGFEBqMC5qHZFfpchiY3\nZ+rdorFlP+r6TdJsqVbIfJQQ9YrBCrJvfhDX3M/WrMy4XC9bBhsMiImaE8LYCCpX\nEfwh7oh4CKVPoY880WvlsKTiEDFhk2mwzIgAO5kCgYAN+FmB/gpZaRbUp9VnafN2\n8uvFPXWP3dv0cpCwrSiS7BbQAMRY0Q/KwKwgGW4fxhi8d/ZUqGEnmmuvcpU8UlWq\n2DpoSi6HYYoNoay8mFCAFgbXzQy8NJ+ev1mY5uBd1WzrMqyfDiuqEHHc3W5VGh6k\nhmf98GVEfld8WmSoktpkpw==\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-zrr1s@sbpoc-b6fcb.iam.gserviceaccount.com",
      "client_id": "101832228741717072639",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-zrr1s%40sbpoc-b6fcb.iam.gserviceaccount.com"
    }),
  authDomain: "sbpoc-b6fcb.firebaseapp.com"         // Auth with popup/redirect
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
      next()
    })
    .catch((error) => {
        let err = new Error(`Google Token Unauthorised`);
			err.status = 401;
			next(err);
    });
}

module.exports = { app: app };
