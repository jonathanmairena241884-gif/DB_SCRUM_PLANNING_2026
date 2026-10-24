
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_CATALOGS.USP_BusinessValues
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModificatorId INT = NULL,
    @i_businessValueEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_businessValueName, '') = ''
           OR ISNULL(@i_businessValueCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El nombre y el creador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_businessValueCreatorId
              AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El usuario creador no existe o está inactivo.';
            RETURN;
        END;

        INSERT INTO SQM_CATALOGS.TBL_BusinessValues
        (
            businessValueName,
            businessValueCreationDate,
            businessValueCreatorId,
            businessValueModificationDate,
            businessValueModificatorId,
            businessValueEnable
        )
        VALUES
        (
            @i_businessValueName,
            GETDATE(),
            @i_businessValueCreatorId,
            GETDATE(),
            NULL,
            1
        );

        SET @o_Numero = 201;
        SET @o_MensajeUsuario = 'Valor de negocio registrado correctamente.';
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_businessValueId, 0) = 0
           OR ISNULL(@i_businessValueModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El ID y el modificador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_CATALOGS.TBL_BusinessValues
            WHERE businessValueId = @i_businessValueId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'El valor de negocio no existe.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_businessValueModificatorId
              AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El usuario modificador no existe o está inactivo.';
            RETURN;
        END;

        UPDATE SQM_CATALOGS.TBL_BusinessValues
        SET businessValueName =
                COALESCE(@i_businessValueName, businessValueName),
            businessValueModificationDate = GETDATE(),
            businessValueModificatorId = @i_businessValueModificatorId,
            businessValueEnable =
                COALESCE(@i_businessValueEnable, businessValueEnable)
        WHERE businessValueId = @i_businessValueId;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Valor de negocio actualizado correctamente.';
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF @i_PageNumber <= 0 OR @i_RowsPerPage <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'La página y el tamaño deben ser mayores que cero.';
            RETURN;
        END;

        SELECT
            businessValueId,
            businessValueName,
            businessValueCreationDate,
            businessValueCreatorId,
            businessValueModificationDate,
            businessValueModificatorId,
            businessValueEnable
        FROM SQM_CATALOGS.TBL_BusinessValues
        ORDER BY businessValueId
        OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
        FETCH NEXT @i_RowsPerPage ROWS ONLY;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Listado ejecutado correctamente.';
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
    END;
END;
GO
