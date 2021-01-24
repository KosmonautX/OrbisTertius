module.exports = (app) => {
	app.use(`/api/orb`, require(`../routes/orb_net`));
	app.use(`/api/query`, require(`../routes/orb_query`));
	app.use(`/api/dev`, require(`../routes/orb_dev`));
<<<<<<< HEAD
	app.use(`/api/tele`, require(`../routes/tele`));
=======
	// app.use(`/api/tele`, require(`../routes/tele`));
>>>>>>> bd812916f9badc0c98e5c70db5a2dc2e3d8f1eb2
};
