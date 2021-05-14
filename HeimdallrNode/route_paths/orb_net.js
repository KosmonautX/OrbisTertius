module.exports = (app, verifyToken) => {
    if(process.env.NODE_ENV == "dev"){
        app.use('/api/dev', require('../routes/orb_dev'));
    }
	app.use(`/api/orb`, verifyToken, require(`../routes/orb_net`));
	// app.use(`/api/orb`, require(`../routes/orb_net`));
    // shift security into middleware verifyToken too coarse
	app.use(`/api/query`,verifyToken, require(`../routes/orb_query`));
	app.use(`/api/comment`, require(`../routes/comment`));
	app.use(`/api/tele`, require(`../routes/tele`));
  	app.use(`/api/query/user`, verifyToken, require(`../routes/personal_profile`));
};
