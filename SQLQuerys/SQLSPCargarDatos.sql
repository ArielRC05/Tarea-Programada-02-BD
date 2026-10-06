
--Ejemplo de ejecucion
--DECLARE @resultCode INT;
--EXEC dbo.CargarDatos
--     @inXml = @xml
--     , @outResultCode = @resultCode OUTPUT;

CREATE PROCEDURE dbo.CargarDatos
    @inXml XML
    , @outResultCode INT OUTPUT -- codigo del resultado
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        BEGIN TRANSACTION;

        INSERT dbo.Persona (
            IdTipoDocuIdentidad
            , ValorDocumentoIdentidad
            , Nombre
            , FechaNacimiento
            , Email
        )
        SELECT tipo.Item.value('@TipoDocuIdentidad', 'INT')
            , tipo.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
            , tipo.Item.value('@Nombre', 'VARCHAR(64)')
            , tipo.Item.value('@FechaNacimiento', 'DATE')
            , tipo.Item.value('@Email', 'VARCHAR(128)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Personas/Persona') AS tipo(Item)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.Persona personaExistente
            WHERE personaExistente.ValorDocumentoIdentidad = tipo.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        );

        --telefono 1
        INSERT dbo.Telefono (
            IdPersona
            , Numero
        )
        SELECT persona.Id
            , N.Nodo.value('@telefono1', 'VARCHAR(32)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Personas/Persona') AS N(Nodo)
        INNER JOIN dbo.Persona persona
            ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        WHERE N.Nodo.value('@telefono1', 'VARCHAR(32)') IS NOT NULL
            AND NOT EXISTS (
                SELECT 1
                FROM dbo.Telefono telefono
                WHERE telefono.IdPersona = persona.Id
                    AND telefono.Numero = N.Nodo.value('@telefono1', 'VARCHAR(32)')
            );

        --telefono 2
        INSERT dbo.Telefono (
            IdPersona
            , Numero
        )
        SELECT persona.Id
            , N.Nodo.value('@telefono2', 'VARCHAR(32)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Personas/Persona') AS N(Nodo)
        INNER JOIN dbo.Persona persona
            ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        WHERE N.Nodo.value('@telefono2', 'VARCHAR(32)') IS NOT NULL
            AND NOT EXISTS (
                SELECT 1
                FROM dbo.Telefono telefono
                WHERE telefono.IdPersona = persona.Id
                    AND telefono.Numero = N.Nodo.value('@telefono2', 'VARCHAR(32)')
            );

        INSERT dbo.CAhorrista (
            Id
        )
        SELECT persona.Id
        FROM dbo.Persona persona
        WHERE EXISTS (
            SELECT 1
            FROM @inXml.nodes('/TareaCuentaAhorros/Cuentas/Cuenta') AS N(Nodo)
            WHERE N.Nodo.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(32)') = persona.ValorDocumentoIdentidad
        )
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.CAhorrista ahorrista
            WHERE ahorrista.Id = persona.Id
        );

        INSERT dbo.Beneficiario (
            Id
        )
        SELECT persona.Id
        FROM dbo.Persona persona
        WHERE EXISTS (
            SELECT 1
            FROM @inXml.nodes('/TareaCuentaAhorros/Beneficiarios/Beneficiario') AS N(Nodo)
            WHERE N.Nodo.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(32)') = persona.ValorDocumentoIdentidad
        )
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.Beneficiario beneficiarioExistente
            WHERE beneficiarioExistente.Id = persona.Id
        );

        INSERT dbo.Cuenta (
            IdCAhorrista
            , IdTipoCuentaAhorro
            , NumeroCuenta
            , FechaCreacion
            , Saldo
        )
        SELECT persona.Id
            , N.Nodo.value('@TipoCuentaId', 'INT')
            , N.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')
            , N.Nodo.value('@FechaCreacion', 'DATE')
            , N.Nodo.value('@Saldo', 'DECIMAL(18,2)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Cuentas/Cuenta') AS N(Nodo)
        INNER JOIN dbo.Persona persona
            ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(32)')
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.Cuenta cuentaExistente
            WHERE cuentaExistente.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')
        );

        INSERT dbo.BenefDeCA (
            IdCuenta
            , IdBeneficiario
            , IdParentesco
            , Porcentaje
            , flagActivo
            , FechaDesactivacion
        )
        SELECT cuenta.Id
            , persona.Id
            , N.Nodo.value('@IdParentezco', 'INT')
            , N.Nodo.value('@Porcentaje', 'INT')
            , 1
            , NULL
        FROM @inXml.nodes('/TareaCuentaAhorros/Beneficiarios/Beneficiario') AS N(Nodo)
        INNER JOIN dbo.Cuenta cuenta
            ON cuenta.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')
        INNER JOIN dbo.Persona persona
            ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(32)')
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.BenefDeCA beneficiarioCuenta
            WHERE beneficiarioCuenta.IdCuenta = cuenta.Id
                AND beneficiarioCuenta.IdBeneficiario = persona.Id
                AND beneficiarioCuenta.flagActivo = 1
        );

        INSERT dbo.EstadoCuenta (
            IdCuenta
            , FechaInicio
            , FechaFin
            , SaldoInicial
            , SaldoFinal
            , SaldoMinimo
            , Intereses
            , CantRetiros
            , CantDepositos
            , CantTransferenciasEntrantes
            , CantTransferenciasSalientes
        )
        SELECT cuenta.Id
            , N.Nodo.value('@fechaInicio', 'DATE')
            , N.Nodo.value('@fechafin', 'DATE')
            , N.Nodo.value('@saldoinicial', 'DECIMAL(18,2)')
            , N.Nodo.value('@saldo_final', 'DECIMAL(18,2)')
            , N.Nodo.value('@saldoMinimo', 'DECIMAL(18,2)')
            , 0
            , 0
            , 0
            , 0
            , 0
        FROM @inXml.nodes('/TareaCuentaAhorros/Estados_de_Cuenta/Estado_de_Cuenta') AS N(Nodo)
        INNER JOIN dbo.Cuenta cuenta
            ON cuenta.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.EstadoCuenta estadoCuenta
            WHERE estadoCuenta.IdCuenta = cuenta.Id
                AND estadoCuenta.FechaInicio = N.Nodo.value('@fechaInicio', 'DATE')
        );

        INSERT dbo.Usuario (
            NombreUsuario
            , Contrasena
            , flagEsAdministrador
        )
        SELECT N.Nodo.value('@User', 'VARCHAR(64)')
            , N.Nodo.value('@Pass', 'VARCHAR(64)')
            , N.Nodo.value('@EsAdministrador', 'BIT')
        FROM @inXml.nodes('/TareaCuentaAhorros/Usuarios/Usuario') AS N(Nodo)
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.Usuario usuarioExistente
            WHERE usuarioExistente.NombreUsuario = N.Nodo.value('@User', 'VARCHAR(64)')
        );

        INSERT dbo.UsuarioPuedeVer (
            IdUsuario
            , IdCuenta
        )
        SELECT usuario.Id
            , cuenta.Id
        FROM @inXml.nodes('/TareaCuentaAhorros/Usuarios_Ver/UsuarioPuedeVer') AS N(Nodo)
        INNER JOIN dbo.Usuario usuario
            ON usuario.NombreUsuario = N.Nodo.value('@User', 'VARCHAR(64)')
        INNER JOIN dbo.Cuenta cuenta
            ON cuenta.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(32)')
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.UsuarioPuedeVer puedeVer
            WHERE puedeVer.IdUsuario = usuario.Id
                AND puedeVer.IdCuenta = cuenta.Id
        );

        COMMIT TRANSACTION; --guardar cambios
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION; --revertir cambios

        INSERT dbo.DBErrors (
            NumeroError
            , EstadoError
            , SeveridadError
            , LineaDeError
            , ProcedureError
            , MensajeError
        )
        SELECT ERROR_NUMBER()
            , ERROR_STATE()
            , ERROR_SEVERITY()
            , ERROR_LINE()
            , ERROR_PROCEDURE()
            , ERROR_MESSAGE();

        SET @outResultCode = 50001; --50001 es error de plataforma
    END CATCH;
END;
GO
