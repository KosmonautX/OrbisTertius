import * as AWS from "@aws-sdk/client-dynamodb-streams";
import {ServiceAccount} from "firebase-admin";
import * as fyr from 'firebase-admin';
import {DynaStream} from "./library/pregolyaStream"
import { unmarshall } from "@aws-sdk/util-dynamodb"
import { DynamoDBStreamsClient, ListStreamsCommandOutput } from "@aws-sdk/client-dynamodb-streams";
const fs = require('fs').promises
const FILE = 'shardState.json'

async function main(stream: DynamoDBStreamsClient, stream_arn:string) {
    if(process.env.STREAM_ARN){
	const ddbStream = new DynaStream(stream,stream_arn,unmarshall,fyr.messaging())
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
}

async function loadShardState() {
	try {
		return JSON.parse(await fs.readFile(FILE, 'utf8'))
	} catch (e) {
		if (e.code === 'ENOENT') return {}
		throw e
	}
}

// function sleep (time: number) {
//   return new Promise((resolve) => setTimeout(resolve, time));
// }


const adminConfig: ServiceAccount = {
  "projectId": process.env.FYR_PROJ,
  "privateKey": process.env.FYR_KEY!.replace(/\\n/g, '\n'),
  "clientEmail": "firebase-adminsdk-b1dh2@"+process.env.FYR_PROJ+".iam.gserviceaccount.com",
}
fyr.initializeApp({
  credential: fyr.credential.cert(adminConfig),
})

if(process.env.NODE_ENV === 'dev'){
  var straum = new AWS.DynamoDBStreams({endpoint: process.env.DYNA, region: "localhost"});
  let streams: Promise<ListStreamsCommandOutput>  =  straum.listStreams({
    TableName: process.env.TABLE || "ORB_NET"})
  streams.then((data: any) => {
    try{
      main(straum, data.Streams[0]!.StreamArn as string)
    } catch(error) { console.log(error); throw new Error("Main Loop Failed")}})
    .catch((error) => {
      console.log(error)
    })
}else{
  var straum = new AWS.DynamoDBStreams({region: "ap-southeast-1"});

  try{
    main(straum, process.env.DYNASTREAM_ARN as string)
  } catch(error) { console.log(error); throw new Error("Main Loop Failed")}
}
