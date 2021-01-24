require(`./resources/global`); //initialized all global variable;
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

const secret = require(`./resources/global`).SECRET;

logger.token(`date`, () => {
	return moment().format(`YYYY-MM-DD HH:mm:ss`);
});

require(`log-prefix`)(function () {
	return `[` + moment().format(`YYYY-MM-DD HH:mm:ss`) + `]`;
});

app.use(logger(`[:date] :method :url :status :res[content-length] - :response-time ms`));
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

app.get('/verify', (req, res) => {
	// let verified = verifyToken(req, res)
	let verified 
	if (req.headers.authorization) {
		verified = verifyToken(req.headers.authorization)
	} else {
		res.json({"good":"bye"})
	}
	if (verified) {
		res.json(verified);
	} else {
		res.json({"good":"bye"})
	}
    
});

require(`./route_paths/orb_net`)(app);

// set port, listen for requests
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
});


const dynamodb = new AWS.DynamoDB({endpoint: new AWS.Endpoint("http://dynamodb:8000")});
// const user_template = require('./blueprint/user_table.json');
const orb_template = require('./blueprint/orb_net_table.json')

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

function verifyToken(jwtoken) {
    try {
      const iss = "Princeton";
      const sub = "ScratchBac";
      const exp = "10min";
      const verifyOptions = {
        issuer : iss,
        subject : sub,
        maxAge : exp,
        algorithms : ["HS256"]
      };
    //   req.token = req.headers["authorization"] || "";
	//   req.token = req.token.replace(/BEARER /gi, ``);
      if (jwtoken) {
        let verified = jwt.verify(jwtoken, secret, verifyOptions);
        return verified;
      }
    } catch (err) {
      console.log(err)
    }
  }

module.exports = { app: app };
