module.exports = (app, verifyToken,fyrwalk) => {
    if(process.env.NODE_ENV == "dev"){
        app.use('/api/dev', require(`../routes/orb_dev`));
    }
    app.use('/api/devland/auth', require(`../routes/dev_auth`));
	app.use(`/api/orb`, verifyToken, require(`../routes/orb_net`));
    app.use('/api/devland/fyr',fyrwalk, require('../routes/fyrbridge'));
    //app.use(`/api/userland/action`, verifyToken, require(`../routes/user_act`))
    //app.use(`/api/orbland/action`, verifyToken, require(`../routes/orb_act`))
    //app.use(`/api/orbland/state`,verifyToken, require(`../routes/orb_state`))
    // shift security into middleware verifyToken too coarse
    app.use('/api/nomadology',verifyToken,  require(`../routes/orb_nomad`));
	app.use(`/api/query`,verifyToken, require(`../routes/orb_query`));
    app.use(`/api/mercury`,verifyToken, require(`../routes/tele_service`));
	app.use(`/api/comment`, require(`../routes/comment`));
  	app.use(`/api/query/user`, verifyToken, require(`../routes/personal_profile`));
};
