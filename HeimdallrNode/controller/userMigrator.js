const admin = require("firebase-admin")

const migrator = {
  async fetch(uid) {
    return admin.auth().getUser(uid)
  }};

module.exports= {
  migrator:migrator
}
