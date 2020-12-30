module.exports = (app) => {
	app.use(`/api/user`, require(`../routes/dynamo/user`));
};
