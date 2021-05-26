var checkUser = function (req, next) {
    try{
    switch (req.verification.role){
        case "barb":
            throw new Error("Guest User needs to Login for action");
        case "pleb":
            if(req.verification.user_id === req.body.user_id){
                break;
            }
            else{
                throw new Error("User does not match");
            }

        default:
            throw new Error("Unknown Role")
    }
    }
    catch(err){
        err.status = 401
        next(err);
    }
}

var checkActor = function(auth, actor_id){
    switch (auth.role){
        case "barb":
            throw new Error("Guest User needs to Login for action");
        case "pleb":
            if(auth.user_id === actor_id){
                break;
            }
            else{
                throw new Error("User does not match");
            }

        default:
            throw new Error("Unknown Role")
    }
}

function checkAdmin(jwt) {
    if (jwt != 'penguinman') {
        let err = new Error("User is not admin");
        err.status = 401;
        throw err;
    }
}

module.exports = {
    checkUser: checkUser,
    checkAdmin: checkAdmin,
    checkActor: checkActor,
}
