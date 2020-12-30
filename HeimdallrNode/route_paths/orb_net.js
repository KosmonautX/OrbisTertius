module.exports = (app) => {
	app.use(`/api/orb`, require(`../routes/dynamo/orb_net`));
};
