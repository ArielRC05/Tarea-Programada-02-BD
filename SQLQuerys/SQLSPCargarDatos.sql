ALTER PROCEDURE dbo.CargarDatos
    @inXML XML,
    @outResultCode INT OUTPUT -- codigo del resultado 
AS
BEGIN 
    SET NOCOUNT ON;

    BEGIN TRY
        SET @outResultCode = 0;

        BEGIN TRANSACTION;

        INSERT INTO dbo.Persona (IdTipoDocuIdentidad, ValorDocumentoIdentidad, Nombre, FechaNacimiento, Email)
        SELECT tipo.Item.value('@TipoDocuIdentidad', 'INT'),
               tipo.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
               tipo.Item.value('@Nombre', 'VARCHAR(64)'),
               tipo.Item.value('@FechaNacimiento', 'DATE'),
               tipo.Item.value('@Email', 'VARCHAR(100)')
        FROM @inXML.nodes('/TareaCuentaAhorros/Personas/Persona') AS tipo(Item)
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Persona sujeto WHERE sujeto.ValorDocumentoIdentidad = tipo.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(32)')
        );
        
        --telefono 1
        INSERT INTO dbo.Telefono (IdPersona, Numero)
        SELECT persona.Id,
               N.Nodo.value('@telefono1', 'VARCHAR(20)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Personas/Persona') AS N(Nodo)
        INNER JOIN dbo.Persona persona ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)') --unir datos de persona tabla con persona del XML si coinciden con sus documentos identidad
        WHERE N.Nodo.value('@telefono1', 'VARCHAR(20)') IS NOT NULL AND NOT EXISTS (
              SELECT 1 FROM dbo.Telefono telefono WHERE telefono.IdPersona = persona.Id AND telefono.Numero = N.Nodo.value('@telefono1', 'VARCHAR(20)')
        );
        
        --telefono 2
        INSERT INTO dbo.Telefono (IdPersona, Numero)
        SELECT persona.Id,
               N.Nodo.value('@telefono2', 'VARCHAR(20)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Personas/Persona') AS N(Nodo)
        INNER JOIN dbo.Persona persona ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidad', 'VARCHAR(32)') --unir datos de persona tabla con persona del XML si coinciden con sus documentos identidad
        WHERE N.Nodo.value('@telefono2', 'VARCHAR(20)') IS NOT NULL AND NOT EXISTS (
              SELECT 1 FROM dbo.Telefono telefono WHERE telefono.IdPersona = persona.Id AND telefono.Numero = N.Nodo.value('@telefono2', 'VARCHAR(20)')
        );

        INSERT INTO dbo.CAhorrista (IdPersona)
        SELECT persona.Id
        FROM dbo.Persona persona
        WHERE EXISTS (
            SELECT 1 FROM @inXml.nodes('/TareaCuentaAhorros/Cuentas/Cuenta') AS N(Nodo) WHERE N.Nodo.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(32)') = persona.ValorDocumentoIdentidad
        ) AND NOT EXISTS (
            SELECT 1 FROM dbo.CAhorrista ahorrista WHERE ahorrista.IdPersona = persona.Id
        );

        INSERT INTO dbo.Beneficiario (IdPersona)
        SELECT persona.Id
        FROM dbo.Persona persona
        WHERE EXISTS (
            SELECT 1 FROM @inXml.nodes('/TareaCuentaAhorros/Beneficiarios/Beneficiario') AS N(Nodo) WHERE N.Nodo.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(32)') = persona.ValorDocumentoIdentidad
        ) AND NOT EXISTS (
            SELECT 1 FROM dbo.Beneficiario beneficiarioExistente WHERE beneficiarioExistente.IdPersona = persona.Id
        );

        INSERT INTO dbo.Cuenta (IdCAhorrista, IdTipoCuentaAhorro, NumeroCuenta, FechaCreacion, Saldo)
        SELECT persona.Id,
               N.Nodo.value('@TipoCuentaId', 'INT'),N.Nodo.value('@NumeroCuenta', 'VARCHAR(20)'),
               N.Nodo.value('@FechaCreacion', 'DATE'),
               N.Nodo.value('@Saldo', 'DECIMAL(18,2)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Cuentas/Cuenta') AS N(Nodo)
        INNER JOIN dbo.Persona persona ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(32)')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Cuenta cuentaExistente WHERE cuentaExistente.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(20)')
        );

        INSERT INTO dbo.BenefDeCA (IdCuenta, IdBeneficiario, IdParentesco, Porcentaje)
        SELECT cuenta.Id,
               persona.Id,
               N.Nodo.value('@IdParentezco', 'INT'),
               N.Nodo.value('@Porcentaje', 'INT')
        FROM @inXml.nodes('/TareaCuentaAhorros/Beneficiarios/Beneficiario') AS N(Nodo)
        INNER JOIN dbo.Cuenta cuenta ON cuenta.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(20)')
        INNER JOIN dbo.Persona persona ON persona.ValorDocumentoIdentidad = N.Nodo.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(32)')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.BenefDeCA beneficiarioCuenta
            WHERE beneficiarioCuenta.IdCuenta = cuenta.Id
              AND beneficiarioCuenta.IdBeneficiario = persona.Id
              AND beneficiarioCuenta.flagActivo = 1
        );

        INSERT INTO dbo.EstadoCuenta (IdCuenta, FechaInicio, FechaFin, SaldoInicial, SaldoMinimo, SaldoFinal)
        SELECT cuenta.Id,
               N.Nodo.value('@fechaInicio', 'DATE'),
               N.Nodo.value('@fechafin', 'DATE'),
               N.Nodo.value('@saldoinicial', 'DECIMAL(18,2)'),
               N.Nodo.value('@saldoMinimo', 'DECIMAL(18,2)'),
               N.Nodo.value('@saldo_final', 'DECIMAL(18,2)')
        FROM @inXml.nodes('/TareaCuentaAhorros/Estados_de_Cuenta/Estado_de_Cuenta') AS N(Nodo)
        INNER JOIN dbo.Cuenta cuenta ON cuenta.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(20)')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.EstadoCuenta estadoCuenta
            WHERE estadoCuenta.IdCuenta = cuenta.Id
              AND estadoCuenta.FechaInicio = N.Nodo.value('@fechaInicio', 'DATE')
        );

        INSERT INTO dbo.Usuario (NombreUsuario, Contrasena, flagEsAdministrador)
        SELECT N.Nodo.value('@User', 'VARCHAR(64)'),
               N.Nodo.value('@Pass', 'VARCHAR(50)'),
               N.Nodo.value('@EsAdministrador', 'BIT')
        FROM @inXml.nodes('/TareaCuentaAhorros/Usuarios/Usuario') AS N(Nodo)
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Usuario usuarioExistente WHERE usuarioExistente.NombreUsuario = N.Nodo.value('@User', 'VARCHAR(64)')
        );

        INSERT INTO dbo.UsuarioPuedeVer (IdUsuario, IdCuenta)
        SELECT usuario.Id
             , cuenta.Id
        FROM @inXml.nodes('/TareaCuentaAhorros/Usuarios_Ver/UsuarioPuedeVer') AS N(Nodo)
        INNER JOIN dbo.Usuario usuario ON usuario.NombreUsuario = N.Nodo.value('@User', 'VARCHAR(64)')
        INNER JOIN dbo.Cuenta cuenta ON cuenta.NumeroCuenta = N.Nodo.value('@NumeroCuenta', 'VARCHAR(20)')
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.UsuarioPuedeVer puedeVer
            WHERE puedeVer.IdUsuario = usuario.Id
              AND puedeVer.IdCuenta = cuenta.Id
        );

        COMMIT TRANSACTION; --guardar cambios

    END TRY --Try y Catch es intente hacer x y si sale mal haga y basicamente
    BEGIN CATCH
        ROLLBACK TRANSACTION; --revertir cambios
        SET @outResultCode = 50001; --50001 es error al cargar datos
    END CATCH
END;