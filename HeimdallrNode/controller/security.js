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
        case "boni":
            throw new Error("Return thee to your pastures")
            break;

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

function checkAdmin(req, next) {
    try{
    if (req.verification.role !== "boni") {
        throw new Error("You ain't serving");}
    }catch(err){
        err.status = 401
        next(err);
    }
}

module.exports = {
    checkUser: checkUser,
    checkAdmin: checkAdmin,
    checkActor: checkActor,
}
