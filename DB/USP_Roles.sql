
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_SECURITY.USP_Roles
    @i_rolId INT = NULL,
    @i_rolName VARCHAR(80) = NULL,
    @i_rolCreatorId INT = NULL,
    @i_rolModificatorId INT = NULL,
    @i_rolEnable BIT = NULL,
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
        IF ISNULL(@i_rolName, '') = ''
           OR @i_rolCreatorId IS NULL
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El nombre y el creador son obligatorios.';
            RETURN;
        END;

        INSERT INTO SQM_SECURITY.TBL_Roles
        (
            rolName,
            rolCreationDate,
            rolCreatorId,
            rolModificationDate,
            rolModificatorId,
            rolEnable
        )
        VALUES
        (
            @i_rolName,
            GETDATE(),
            @i_rolCreatorId,
            GETDATE(),
            NULL,
            1
        );

        SET @o_Numero = 201;
        SET @o_MensajeUsuario = 'Rol registrado correctamente.';
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_rolId, 0) = 0
           OR @i_rolModificatorId IS NULL
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El ID y el modificador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM SQM_SECURITY.TBL_Roles
            WHERE rolId = @i_rolId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'El rol no existe.';
            RETURN;
        END;

        UPDATE SQM_SECURITY.TBL_Roles
        SET rolName = COALESCE(@i_rolName, rolName),
            rolModificationDate = GETDATE(),
            rolModificatorId = @i_rolModificatorId,
            rolEnable = COALESCE(@i_rolEnable, rolEnable)
        WHERE rolId = @i_rolId;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Rol actualizado correctamente.';
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF @i_PageNumber <= 0 OR @i_RowsPerPage <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'La página y el tamaño deben ser mayores que cero.';
            RETURN;
        END;

        SELECT rolId,
               rolName,
               rolCreationDate,
               rolCreatorId,
               rolModificationDate,
               rolModificatorId,
               rolEnable
        FROM SQM_SECURITY.TBL_Roles
        ORDER BY rolId
        OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
        FETCH NEXT @i_RowsPerPage ROWS ONLY;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Listado de roles ejecutado correctamente.';
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
    END;
END;
GO
