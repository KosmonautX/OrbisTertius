module.exports = (app) => {
	app.use(`/api/orb`, require(`../routes/orb_net`));
	app.use(`/api/query`, require(`../routes/orb_query`));
	app.use(`/api/dev`, require(`../routes/orb_dev`));
	app.use(`/api/comment`, require(`../routes/comment`));
	app.use(`/api/tele`, require(`../routes/tele`));
};
