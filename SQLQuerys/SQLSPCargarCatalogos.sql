CREATE PROCEDURE dbo.CargarCatalogos
    @inXML XML --parametro de tipo XML
AS
BEGIN
    SET NOCOUNT ON; --evita mensajes de rows affected

    INSERT INTO dbo.TipoDocuIdentidad (Id, Nombre)
    SELECT tipo.Item.value('@Id', 'INT'),
           tipo.Item.value('@Nombre', 'VARCHAR(50)')
    FROM @inXML.nodes('//TipoDocuIdentidad') AS tipo(Item) --.nodes() significa busca elementos en XML que son /...
    WHERE NOT EXISTS ( --si no existe insertar
        SELECT 1 FROM dbo.TipoDocuIdentidad docu WHERE docu.Id = tipo.Item.value('@Id', 'INT') --el valor del xml
    );

    INSERT INTO dbo.TipoMoneda (Id, Nombre, Simbolo)
    SELECT tipo.Item.value('@Id', 'INT'),
           tipo.Item.value('@Nombre', 'VARCHAR(30)'),
           tipo.Item.value('@Simbolo', 'NVARCHAR(3)')
    FROM @inXML.nodes('//TipoMoneda') AS tipo(Item)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.TipoMoneda moneda WHERE moneda.Id = tipo.Item.value('@Id', 'INT')
    );
 
    INSERT INTO dbo.Parentesco (Id, Nombre)
    SELECT tipo.Item.value('@Id', 'INT'),
           tipo.Item.value('@Nombre', 'VARCHAR(20)')
    FROM @inXML.nodes('//Parentezco') AS tipo(Item)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Parentesco pariente WHERE pariente.Id = tipo.Item.value('@Id', 'INT')
    );

    INSERT INTO dbo.TipoCuentaAhorro (Id, Nombre, IdTipoMoneda, SaldoMinimo, MultaSaldoMin, CargoAnual,NumRetirosHumano, NumRetirosAutomatico, ComisionHumano,ComisionAutomatico, Interes)
    SELECT tipo.Item.value('@Id', 'INT'),
           tipo.Item.value('@Nombre', 'VARCHAR(50)'),
           tipo.Item.value('@IdTipoMoneda', 'INT'),
           tipo.Item.value('@SaldoMinimo', 'MONEY'),
           tipo.Item.value('@MultaSaldoMin', 'MONEY'),
           tipo.Item.value('@CargoAnual', 'MONEY'),
           tipo.Item.value('@NumRetirosHumano', 'INT'),
           tipo.Item.value('@NumRetirosAutomatico', 'INT'),
           tipo.Item.value('@comisionHumano', 'MONEY'),
           tipo.Item.value('@comisionAutomatico', 'MONEY'),
           tipo.Item.value('@interes', 'DECIMAL(5,2)')
    FROM @inXML.nodes('//TipoCuentaAhorro') AS tipo(Item)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.TipoCuentaAhorro cuenta WHERE cuenta.Id = tipo.Item.value('@Id', 'INT')
    );

    INSERT INTO dbo.TipoOperacion (Id, Nombre)
    SELECT tipo.Item.value('@Id', 'INT'),
           tipo.Item.value('@Nombre', 'VARCHAR(60)')
    FROM @inXML.nodes('//TipoOperacion') AS tipo(Item)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.TipoOperacion operacion WHERE operacion.Id = tipo.Item.value('@Id', 'INT')
    );

END;