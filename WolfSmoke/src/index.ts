import * as AWS from "@aws-sdk/client-dynamodb-streams";
import {ServiceAccount} from "firebase-admin";
import * as fyr from 'firebase-admin';
import {DynaStream} from "./library/pregolyaStream"
import { unmarshall } from "@aws-sdk/util-dynamodb"
import { DynamoDBStreams, ListStreamsCommandOutput } from "@aws-sdk/client-dynamodb-streams";
import { triggerNotif, triggerBeacon, mutateTerritorySubscription, mutateActorSubscription, beckonComment} from "./library/fyrTongue";
import {telePostOrb, teleExtinguishOrb} from "./library/teleriaTongue"
const fs = require('fs').promises
const FILE = './shard/shardState.json'
var straum: DynamoDBStreams
switch(process.env.NODE_ENV)
{
  case 'dev': straum = new AWS.DynamoDBStreams({endpoint: process.env.DYNA, region: "localhost"}); break;
  case 'stage': straum = new AWS.DynamoDBStreams({region: "ap-southeast-1"}); break;
  case 'prod': straum = new AWS.DynamoDBStreams({region: "ap-southeast-1"}); break;
  default: straum = new AWS.DynamoDBStreams({region: "ap-southeast-1"})
}

async function main(stream: DynamoDBStreams, stream_arn:string) {
	const DynaRipples = new DynaStream(stream,stream_arn,unmarshall)
	// update the state so it will pick up from where it left last time
	// remember this has a limit of 24 hours or something along these lines
	// https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html
	DynaRipples.setShardState(await loadShardState())

  const fetchStreamState = async() => {
    setTimeout(async () => {
      await DynaRipples.fetchStreamState()
      const shardState = DynaRipples.getShardState()
      await fs.writeFile(FILE, JSON.stringify(shardState))
      fetchStreamState()
    }, 1000 * 20)
  }

	// const fetchStreamState = async () => {
	//   await DynaRipples.fetchStreamState()
	//   const shardState = DynaRipples.getShardState()
	//   await fs.writeFile(FILE, JSON.stringify(shardState))
	//   setTimeout(fetchStreamState, 1000 * 20)
	// }

  //panta rhei

  DynaRipples.on('ORB_GENESIS', async function GenesisListener(rise){
    await telePostOrb(rise)
    await triggerNotif(rise,fyr.messaging())
  });

  DynaRipples.on('ORB_USR_GENESIS', async function ActorGenesisListener(rise){
    await mutateActorSubscription(rise,fyr.messaging())
  });

  DynaRipples.on('ORB_USR_FLUX', async function ActorFluxListener(_present, _past){
  });

  DynaRipples.on('ORB_FLUX', async function FluxListener(present,_past) {
    await teleExtinguishOrb(present)
  });

  DynaRipples.on('USR_FLUX', async function FluxListener(present, past) {
    await mutateTerritorySubscription(present,fyr.messaging(),past)
    await triggerBeacon(present,fyr.messaging(),past)
  });

  DynaRipples.on('USR_GENESIS', async function GenesisListener(present) {
    await mutateTerritorySubscription(present,fyr.messaging())
  });

  DynaRipples.on('COM_GENESIS', async function GenesisListener(present) {
    await beckonComment(present,fyr.messaging()) // transplant to elixir
  });



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
  let streams: Promise<ListStreamsCommandOutput>  =  straum.listStreams({
    TableName: process.env.TABLE || "ORB_NET"})
  streams.then((data: any) => {
    try{
      main(straum, data.Streams[0]!.StreamArn as string).catch((error) => {
        console.log(error)
      })
    } catch(error) { console.log(error); throw new Error("Main Loop Failed")}})
}else{
  try{
    main(straum, process.env.DYNASTREAM_ARN as string).catch(err => {
      console.log(err)
    });
  } catch(error) { console.log(error); throw new Error("Main Loop Failed")}
}
