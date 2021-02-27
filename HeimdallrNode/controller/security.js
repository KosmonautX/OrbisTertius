function checkUser(jwt, user_id) {
    if (jwt != user_id) {
        let err = new Error("User does not match");
        err.status = 401;
        throw err;
    }
}

function checkAdmin(jwt) {
    if (jwt != 'admin') {
        let err = new Error("User is not admin");
        err.status = 401;
        throw err;
    }
}

module.exports = {
    checkUser: checkUser,
    checkAdmin: checkAdmin,
}