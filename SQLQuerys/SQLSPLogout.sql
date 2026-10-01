--logout

CREATE PROCEDURE dbo.Logout
    @inIdUsuario INT,
    @inIP VARCHAR(45),
    @outResultCode INT OUTPUT -- codigo del resultado
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        INSERT INTO dbo.Bitacora (IdUsuario, IdTipoOperacion, IP)--tipo 2 es logout
        VALUES (@inIdUsuario, 2, @inIP);

    END TRY --Try y Catch es intente hacer x y si sale mal haga y basicamente
    BEGIN CATCH
        SET @outResultCode = 50001; --50001 es error al cargar datos
    END CATCH
END;