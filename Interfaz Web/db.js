const sql = require('mssql');

const dbConfig = {
    user: 'Daniel', // El usuario que crearon en SSMS (ej: 'sa' o usuario de equipo)
    password: '1234', // La contraseña definida en SSMS
    server: '25.40.212.201', // La IP de Hamachi
    database: 'TareaAhorros', // El nombre de la BD para la TP2
    port: 1433,
    options: {
        encrypt: false,
        trustServerCertificate: true
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

const poolPromise = new sql.ConnectionPool(dbConfig)
    .connect()
    .then(pool => {
        console.log('✅ Conectado exitosamente a SQL Server vía Hamachi (TareaAhorros)');
        return pool;
    })
    .catch(err => {
        console.error('❌ Error de conexión a la BD: ', err.message);
    });

module.exports = { sql, poolPromise };