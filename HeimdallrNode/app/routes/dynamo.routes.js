const orb_controller = require('../controllers/orb_net');
const user_controller = require('../controllers/user_interactions');

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header('Access-Control-Allow-Headers', 'x-access-token, Origin, Content-Type, Accept');
        next();
    });

    app.get('/api/orb/get', orb_controller.retrieveOrb);

    app.get('/api/orb/getLoc', orb_controller.retrieveOrbByLoc);

    app.get('/api/orb/getRange', orb_controller.retrieveOrbByLocRange);

    app.get('/api/orb/getName', orb_controller.retrieveOrbByName);

    app.get('/api/orb/getRecent', orb_controller.retrieveOrbByRecency);

    app.post('/api/orb/post', orb_controller.create);

    app.get('/api/user/get', user_controller.retrieveUser);

    app.post('/api/user/create', user_controller.create);

    app.get('/api/user/getps', user_controller.retrieveUserByPS);
};
