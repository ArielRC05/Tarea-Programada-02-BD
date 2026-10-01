--listar las cuentas del usuario, para que las vea y tenga (por si ocupa para acceder o ver a cual acceder)
ALTER PROCEDURE dbo.ListarCuentasUsuario
    @inIdUsuario INT,
    @outResultCode INT OUTPUT -- codigo del resultado
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        SELECT cuenta.NumeroCuenta,
               tipoCuenta.Nombre AS TipoCuenta,
               moneda.Simbolo AS SimboloMoneda,
               cuenta.Saldo,
               cuenta.FechaCreacion
        FROM dbo.UsuarioPuedeVer puedeVer
        INNER JOIN dbo.Cuenta cuenta ON cuenta.Id = puedeVer.IdCuenta --buscar cuenta id
        INNER JOIN dbo.TipoCuentaAhorro tipoCuenta  ON tipoCuenta.Id = cuenta.IdTipoCuentaAhorro -- --buscar tipo de cuenta
        INNER JOIN dbo.TipoMoneda moneda ON moneda.Id = tipoCuenta.IdTipoMoneda --buscar tipo moneda
        WHERE puedeVer.IdUsuario = @inIdUsuario
        ORDER BY cuenta.NumeroCuenta;

    END TRY --Try y Catch es intente hacer x y si sale mal haga y basicamente
    BEGIN CATCH
        SET @outResultCode = 50001; --50001 es error al cargar datos
    END CATCH
END;