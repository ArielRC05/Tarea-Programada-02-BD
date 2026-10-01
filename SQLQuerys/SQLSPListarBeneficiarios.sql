--listar los beneficiarios de una cuenta
ALTER PROCEDURE dbo.ListarBeneficiarios
    @inIdUsuario INT,
    @inNumeroCuenta VARCHAR(20),
    @outResultCode INT OUTPUT -- codigo del resultado
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        DECLARE @idCuenta INT;

        --revisar que la cuenta si la pueda ver el usuario
        SELECT @idCuenta = cuenta.Id 
        FROM dbo.UsuarioPuedeVer puedeVer
        INNER JOIN dbo.Cuenta cuenta ON cuenta.Id = puedeVer.IdCuenta
        WHERE puedeVer.IdUsuario = @inIdUsuario AND cuenta.NumeroCuenta = @inNumeroCuenta;

        IF @idCuenta IS NULL
        BEGIN
            SET @outResultCode = 50003; --50003 es error si la cuenta no es de ese usuario
            RETURN;
        END;

        SELECT beneficiarioCuenta.Id AS IdBenefDeCA,--beneficiario activo de la CA
               persona.ValorDocumentoIdentidad,
               persona.Nombre,
               persona.FechaNacimiento,
               persona.Email,
               parentesco.Nombre AS Parentesco,
               beneficiarioCuenta.Porcentaje

        FROM dbo.BenefDeCA beneficiarioCuenta
        INNER JOIN dbo.Persona persona ON persona.Id = beneficiarioCuenta.IdBeneficiario --busca el id de la persona
        INNER JOIN dbo.Parentesco parentesco ON parentesco.Id = beneficiarioCuenta.IdParentesco --busca el parentesco
        WHERE beneficiarioCuenta.IdCuenta = @idCuenta AND beneficiarioCuenta.flagActivo = 1 
        ORDER BY persona.Nombre;

    END TRY --Try y Catch es intente hacer x y si sale mal haga y basicamente
    BEGIN CATCH
        SET @outResultCode = 50001; --50001 es error al cargar datos
    END CATCH
END;