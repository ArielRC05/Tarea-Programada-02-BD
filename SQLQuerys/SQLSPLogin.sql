--login SP
ALTER PROCEDURE dbo.Login
    @inUser VARCHAR(40),
    @inPass VARCHAR(50), --contrasena
    @inIP VARCHAR(45), --el IP del usuario
    @outResultCode INT OUTPUT -- codigo del resultado
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        DECLARE @idUsuario INT;
        SELECT @idUsuario = usuario.Id 
        FROM dbo.Usuario usuario
        WHERE usuario.NombreUsuario = @inUser AND usuario.Contrasena = @inPass; --nombre y contrasena iguales 

        IF @idUsuario IS NULL
        BEGIN
            SET @outResultCode = 50002; --error en login
            RETURN;
        END;

        INSERT INTO dbo.Bitacora (IdUsuario, IdTipoOperacion, IP) --registro del login exitoso
        VALUES (@idUsuario, 1, @inIP);

        SELECT usuario.Id, --dar el usuario y si es admin
               usuario.flagEsAdministrador
        FROM dbo.Usuario usuario
        WHERE usuario.Id = @idUsuario;

    END TRY --Try y Catch es intente hacer x y si sale mal haga y basicamente
    BEGIN CATCH
        SET @outResultCode = 50001; --50001 es error al cargar datos
    END CATCH
END;
GO