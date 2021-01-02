module.exports = (app) => {
	app.use(`/api/orb`, require(`../routes/orb_net`));
};
