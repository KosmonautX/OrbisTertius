module.exports = {
    HOST: 'localhost',
    USER: 'root',
    PASSWORD: 'Junwei97',
    DB: 'LoginInfo',
    dialect: 'mysql',
    pool: {
        max: 5,
        min: 0,
        acquire: 30000,
        idle: 10000,
    },
};