module.exports = (app, verifyToken,fyrwalk) => {
    if(process.env.NODE_ENV == "dev"){
        app.use('/api/dev', require(`../routes/orb_dev`));
    }
	app.use(`/api/orb`, verifyToken, require(`../routes/orb_net`));
    app.use('/api/devland/fyr',fyrwalk, require('../routes/fyrbridge'));
    app.use('/api/tele',verifyToken,  require(`../routes/telebridge`));
    app.use(`/api/orbland/action`, verifyToken, require(`../routes/orb_act`))
    //app.use(`/api/userland/action`, verifyToken, require(`../routes/user_act`))
    //app.use(`/api/orbland/state`,verifyToken, require(`../routes/orb_state`))
    // shift security into middleware verifyToken too coarse
    app.use('/api/nomadology',verifyToken,  require(`../routes/orb_nomad`));
	app.use(`/api/query`, require(`../routes/orb_query`)); // public (guest) till login fiasco ends
    app.use(`/api/version`, require(`../routes/version`));
	app.use(`/api/comment`, verifyToken, require(`../routes/comment`));
  	app.use(`/api/query/user`, verifyToken, require(`../routes/personal_profile`));
};
