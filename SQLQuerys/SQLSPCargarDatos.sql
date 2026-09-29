CREATE PROCEDURE dbo.CargarDatos
    @inXML XML
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Persona (IdTipoDocuIdentidad, ValorDocumentoIdentidad, Nombre, FechaNacimiento, Email)
    SELECT tipo.Item.value('@TipoDocuIdentidad', 'INT'),
           tipo.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)'),
           tipo.Item.value('@Nombre', 'VARCHAR(40)'),
           tipo.Item.value('@FechaNacimiento', 'DATE'),
           tipo.Item.value('@Email', 'VARCHAR(100)')
    FROM @inXML.nodes('//Persona') AS tipo(Item)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.Persona persona WHERE persona.ValorDocumentoIdentidad = tipo.Item.value('@ValorDocumentoIdentidad', 'VARCHAR(20)')
    );
    --sin temrinar por hoy asi se queda
END;