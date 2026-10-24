
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_CATALOGS.USP_Priorities
    @i_priorityId INT = NULL,
    @i_priorityName VARCHAR(80) = NULL,
    @i_priorityCreatorId INT = NULL,
    @i_priorityModificatorId INT = NULL,
    @i_priorityEnable BIT = NULL,
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
        IF ISNULL(@i_priorityName, '') = ''
           OR ISNULL(@i_priorityCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El nombre y el creador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_priorityCreatorId
              AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El usuario creador no existe o está inactivo.';
            RETURN;
        END;

        INSERT INTO SQM_CATALOGS.TBL_Priorities
        (
            priorityName,
            priorityCreationDate,
            priorityCreatorId,
            priorityModificationDate,
            priorityModificatorId,
            priorityEnable
        )
        VALUES
        (
            @i_priorityName,
            GETDATE(),
            @i_priorityCreatorId,
            NULL,
            NULL,
            1
        );

        SET @o_Numero = 201;
        SET @o_MensajeUsuario = 'Prioridad registrada correctamente.';
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_priorityId, 0) = 0
           OR ISNULL(@i_priorityModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El ID y el modificador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_CATALOGS.TBL_Priorities
            WHERE priorityId = @i_priorityId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'La prioridad no existe.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_priorityModificatorId
              AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El usuario modificador no existe o está inactivo.';
            RETURN;
        END;

        UPDATE SQM_CATALOGS.TBL_Priorities
        SET priorityName = COALESCE(@i_priorityName, priorityName),
            priorityModificationDate = GETDATE(),
            priorityModificatorId = @i_priorityModificatorId,
            priorityEnable = COALESCE(@i_priorityEnable, priorityEnable)
        WHERE priorityId = @i_priorityId;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Prioridad actualizada correctamente.';
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
            priorityId,
            priorityName,
            priorityCreationDate,
            priorityCreatorId,
            priorityModificationDate,
            priorityModificatorId,
            priorityEnable
        FROM SQM_CATALOGS.TBL_Priorities
        ORDER BY priorityId
        OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
        FETCH NEXT @i_RowsPerPage ROWS ONLY;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Listado de prioridades ejecutado correctamente.';
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
    END;
END;
GO
