//import { DynamoDBStreamsClient} from "@aws-sdk/client-dynamodb-streams";
import * as AWS from "@aws-sdk/client-dynamodb-streams";
// import { MulticastMessage, TopicMessage } from "./interface/notif";
import {ServiceAccount} from "firebase-admin";
import * as fyr from 'firebase-admin';
import {DynaStream} from "./library/pregolyaStream"
import { unmarshall } from "@aws-sdk/util-dynamodb"
const fs = require('fs').promises
const STREAM_ARN = "arn:aws:dynamodb:ddblocal:000000000000:table/ORB_NET/stream/2021-07-02T10:04:03.407"
const FILE = 'shardState.json'

async function main() {
	const ddbStream = new DynaStream(
		new AWS.DynamoDBStreams({endpoint: process.env.DYNA, region: "localhost"}),
		STREAM_ARN,
		unmarshall,fyr.messaging())

	// update the state so it will pick up from where it left last time
	// remember this has a limit of 24 hours or something along these lines
	// https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html
	ddbStream.setShardState(await loadShardState())

	const fetchStreamState = async () => {
		await ddbStream.fetchStreamState()
		const shardState = ddbStream.getShardState()
		await fs.writeFile(FILE, JSON.stringify(shardState))
		setTimeout(fetchStreamState, 1000 * 20)
	}

	fetchStreamState().catch(err => {
        console.log(err)
    });
}

async function loadShardState() {
	try {
		return JSON.parse(await fs.readFile(FILE, 'utf8'))
	} catch (e) {
		if (e.code === 'ENOENT') return {}
		throw e
	}
}
const adminConfig: ServiceAccount = {
  "projectId": "scratchbac-v1-ee11a",
  "privateKey": process.env.FYR_KEY,
  "clientEmail": "firebase-adminsdk-b1dh2@scratchbac-v1-ee11a.iam.gserviceaccount.com",
}
fyr.initializeApp({
  credential: fyr.credential.cert(adminConfig),
})
main()
