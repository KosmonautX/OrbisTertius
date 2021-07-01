const debug = require('debug')('DynaStream')
import { EventEmitter } from "events"


export class DynaStream extends EventEmitter {
  _ddbStreams: any;
  _streamArn: string;
  _shards: Map<any,any>;
  _unmarshall: Function;

  /**
   *	@param {object} ddbStreams - an instance of DynamoDBStreams
   *	@param {string} streamArn - the arn of the stream we're consuming
   *	@param {function} unmarshall - directly from
   *			```js
   *				const { unmarshall } = require('@aws-sdk/util-dynamodb')
   *			```
   *			 if not provided then records will be returned using low level api/shape
   */
  constructor(ddbStreams: any, streamArn: string, unmarshall: Function) {
	  super()
	  this._ddbStreams = ddbStreams
	  this._streamArn = streamArn
	  this._shards = new Map()
	  this._unmarshall = unmarshall
  }
  /**
   * this will update the stream, shards and records included
   *
   */
  async fetchStreamState() {
	debug('fetchStreamState')

	await this.fetchStreamShards()
	await this.fetchStreamRecords()
  }

  /**
   * update the shard state of the stream
   * this will emit new shards / remove shards events
   */
  async fetchStreamShards() {
	debug('fetchStreamShards')

	this._trimShards()

	const params = {
	  StreamArn: this._streamArn
	}

	const { StreamDescription } = await this._ddbStreams.describeStream(params)
	const shards = StreamDescription.Shards
	const newShardIds = []

	// collect all the new shards of this stream
	for (const newShardEntry of shards) {
	  const existingShardEntry = this._shards.get(newShardEntry.ShardId)

	  if (!existingShardEntry) {
		this._shards.set(newShardEntry.ShardId, {
		  shardId: newShardEntry.ShardId
		})

		newShardIds.push(newShardEntry.ShardId)
	  }
	}

	if (newShardIds.length > 0) {
	  debug('Added %d new shards', newShardIds.length)
	  this._emitNewShardsEvent(newShardIds as any)
	}
  }

  /**
   * get latest mutants from the underlying stream
   *
   */
  async fetchStreamRecords() {
	debug('fetchStreamRecords')

	if (this._shards.size === 0) {
	  debug('no shards found, this is ok')
	  return
	}

	await this._getShardIterators()
	const records = await this._getRecords()

	debug('fetchStreamRecords', records)

	this._trimShards()
	this._emitRecordEvents(records)

	return records
  }

  /**
   * 	get a COPY of the current/internal shard state.
   * 	this, in conjuction with setShardState is used to
   * 	persist the stream state locally.
   *
   *	@returns {object}
   */
  getShardState() : Object{
      interface State {
          [index: string]: any;
      }

	const state: State = {}
	for (const [shardId, shardData] of this._shards) {
	  state[shardId] = shardData
	}
	return state

  }

  /**
   *	@param {object} shards
   */
  setShardState(shards: Object) {
	this._shards = new Map()
	for (const [shardId, shardData] of Object.entries(shards)) {
	  this._shards.set(shardId, shardData)
	}
  }

  _getShardIterators() {
	debug('_getShardIterators')
	  // return this.parallelomap(this._shards.values(), this._getShardIterator , 10)
    return this.parallelomap(this._shards.values(), ((shardData: any) => this._getShardIterator(shardData)), 10)
    //return this._getShardIterator(this._shards.values())
  }

  async  _getShardIterator(shardData: any) {
	  debug('_getShardIterator')
	  debug(shardData)

	  // no need to get an iterator if this shard already has NextShardIterator
	  if (shardData.nextShardIterator) {
	    debug('shard %s already has an iterator, skipping', shardData.shardId)
	    return
	  }
    if(shardData.shardId){
	  const params = {
	    ShardId: shardData.shardId,
	    ShardIteratorType: 'LATEST',
	    StreamArn: this._streamArn
	  }

	  const { ShardIterator } = await this._ddbStreams.getShardIterator(params)
	    shardData.nextShardIterator = ShardIterator}
  }

  async _getRecords() : Promise<any> {
	debug('_getRecords')

	//const results = await this.parallelomap(this._shards.values(), this._getShardRecords, 10)
  //const results = await this._getShardRecords(this._shards.values())
    const results = await this.parallelomap(this._shards.values(),((shardData: any) => this._getShardRecords(shardData)), 10)
	return results.flat()
  }

  async _getShardRecords(shardData: any) {
	debug('_getShardRecords')

	const params = { ShardIterator: shardData.nextShardIterator }

	try {
	  const { Records, NextShardIterator } = await this._ddbStreams.getRecords(params)
	  if (NextShardIterator) {
		shardData.nextShardIterator = NextShardIterator
	  } else {
		shardData.nextShardIterator = null
	  }

	  return Records
	} catch (e) {
	  if (e.name === 'ExpiredIteratorException') {
		debug('_getShardRecords expired iterator', shardData)
		shardData.nextShardIterator = null
	  } else {
		throw e
	  }
	}
  }

  _trimShards() {
	debug('_trimShards')

	const removedShards = []

	for (const [shardId, shardData] of this._shards) {
	  if (shardData.nextShardIterator === null) {
		debug('deleting shard %s', shardId)
		this._shards.delete(shardId)
		removedShards.push(shardId)
	  }
	}

	if (removedShards.length > 0) {
	  this._emitRemoveShardsEvent(removedShards as any)
	}
  }

  /**
   *	may have to override in subclasses to change record transformation behavior
   * 	for records emitted during _emitRecordEvents()
   */
  _transformRecord(record: any) {
	if (this._unmarshall && record) {
	  return this._unmarshall(record)
	}
  }

  _emitRecordEvents(events: any) {
	debug('_emitRecordEvents')

	for (const event of events) {
	  const keys = this._transformRecord(event.dynamodb.Keys)
	  const newRecord = this._transformRecord(event.dynamodb.NewImage)
	  const oldRecord = this._transformRecord(event.dynamodb.OldImage)

	  switch (event.eventName) {
		case 'INSERT':
		  this.emit('insert record', newRecord, keys)
		  break

		case 'MODIFY':
		  this.emit('modify record', newRecord, oldRecord, keys)
          break

		case 'REMOVE':
		  this.emit('remove record', oldRecord, keys)
		  break

		default:
		  throw new Error(`unknown dynamodb event ${event.eventName}`)
	  }
	}
  }

  _emitRemoveShardsEvent(shardIds: string) {
	this.emit('remove shards', shardIds)
  }


  _emitNewShardsEvent(shardIds: string) {
	this.emit('new shards', shardIds)
  }

  async parallelomap(items: Array<any> | any, mapper: any, limit: number) : Promise<any> {
  /**
   * to limit parallel calls on Promise.all
   */
	if (Array.isArray(items)) {
		items = items.values()
	}

	let concurrentOps = 0
	let position = 0
	let finished = false
	const map: Array<any> = []

	return new Promise(res => {
		const dispatch = async () => {
			const { done, value } = items.next()
			if (done) {
				finished = done
				if (concurrentOps === 0) return res(map)
				return
			}

			// its important to increment before the async operation
			const myPosition = position++
			concurrentOps++
			const mapResult = await mapper(value)
			if (mapResult) {
				map[myPosition] = mapResult
			}
			concurrentOps--
			dispatch()
		}

		for (let i = 0; i < limit && !finished; i++) {
			dispatch()
		}
	})
}
}
