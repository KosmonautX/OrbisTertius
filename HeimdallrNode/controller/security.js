function checkUser(jwt, user_id) {
    switch (jwt){
        case jwt.role == "barb":
            let err = new Error("Guest User needs to Login for action");
            err.status = 401;
            throw err;
        case jwt.user_id != user_id :
            let err = new Error("User does not match");
            err.status = 401;
            throw err;
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
}
