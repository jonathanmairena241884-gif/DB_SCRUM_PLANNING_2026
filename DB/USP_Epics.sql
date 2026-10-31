
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_Epics
    @i_epicId INT = NULL,
    @i_epicName VARCHAR(100) = NULL,
    @i_epicSummary VARCHAR(500) = NULL,
    @i_epicDescription VARCHAR(4000) = NULL,
    @i_epicParentLink INT = NULL,
    @i_epicOwner INT = NULL,
    @i_epicStartDate DATE = NULL,
    @i_epicDueDate DATE = NULL,
    @i_epicPriority INT = NULL,
    @i_epicCreatorId INT = NULL,
    @i_epicModificatorId INT = NULL,
    @i_epicStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = NULL;
    SET @o_MensajeUsuario = NULL;

    BEGIN TRY

        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_epicName, '') = ''
               OR ISNULL(@i_epicSummary, '') = ''
               OR ISNULL(@i_epicDescription, '') = ''
               OR ISNULL(@i_epicParentLink, 0) = 0
               OR ISNULL(@i_epicOwner, 0) = 0
               OR ISNULL(@i_epicCreatorId, 0) = 0
               OR ISNULL(@i_epicStatus, 0) = 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'Faltan datos obligatorios para registrar el Epic.';
                SET @o_MensajeUsuario =
                    'Nombre, resumen, descripción, iniciativa, propietario, creador y estado son obligatorios.';
                RETURN;
            END;

            IF @i_epicStartDate IS NOT NULL
               AND @i_epicDueDate IS NOT NULL
               AND @i_epicStartDate > @i_epicDueDate
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La fecha de inicio es posterior a la fecha de vencimiento.';
                SET @o_MensajeUsuario = 'La fecha de inicio no puede ser posterior a la fecha de vencimiento.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Initiatives
                WHERE initiativeId = @i_epicParentLink
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La iniciativa indicada no existe.';
                SET @o_MensajeUsuario = 'La iniciativa indicada no existe.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_epicOwner
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El propietario no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El propietario no existe o está inactivo.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_epicCreatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El creador no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El creador no existe o está inactivo.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_Status
                WHERE statusId = @i_epicStatus
                  AND statusEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El estado no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El estado no existe o está inactivo.';
                RETURN;
            END;

            IF @i_epicPriority IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Priorities
                    WHERE priorityId = @i_epicPriority
                      AND priorityEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La prioridad no existe o está inactiva.';
                SET @o_MensajeUsuario = 'La prioridad no existe o está inactiva.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            INSERT INTO SQM_GENERAL.TBL_Epics
            (
                epicName,
                epicSummary,
                epicDescription,
                epicParentLink,
                epicOwner,
                epicStartDate,
                epicDueDate,
                epicPriority,
                epicCreationDate,
                epicCreatorId,
                epicModificationDate,
                epicModificatorId,
                epicStatus
            )
            VALUES
            (
                @i_epicName,
                @i_epicSummary,
                @i_epicDescription,
                @i_epicParentLink,
                @i_epicOwner,
                @i_epicStartDate,
                @i_epicDueDate,
                @i_epicPriority,
                GETDATE(),
                @i_epicCreatorId,
                NULL,
                NULL,
                @i_epicStatus
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 201;
            SET @o_MensajeTecnico = 'INSERT ejecutado correctamente.';
            SET @o_MensajeUsuario = 'Epic registrado correctamente.';
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_epicId, 0) = 0
               OR ISNULL(@i_epicModificatorId, 0) = 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'Falta el ID del Epic o el usuario modificador.';
                SET @o_MensajeUsuario = 'El ID del Epic y el modificador son obligatorios.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Epics
                WHERE epicId = @i_epicId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeTecnico = 'No se encontró el Epic solicitado.';
                SET @o_MensajeUsuario = 'El Epic no existe.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_epicModificatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El usuario modificador no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El usuario modificador no existe o está inactivo.';
                RETURN;
            END;

            IF COALESCE(@i_epicStartDate, (
                SELECT epicStartDate
                FROM SQM_GENERAL.TBL_Epics
                WHERE epicId = @i_epicId
            )) IS NOT NULL
            AND COALESCE(@i_epicDueDate, (
                SELECT epicDueDate
                FROM SQM_GENERAL.TBL_Epics
                WHERE epicId = @i_epicId
            )) IS NOT NULL
            AND COALESCE(@i_epicStartDate, (
                SELECT epicStartDate
                FROM SQM_GENERAL.TBL_Epics
                WHERE epicId = @i_epicId
            )) > COALESCE(@i_epicDueDate, (
                SELECT epicDueDate
                FROM SQM_GENERAL.TBL_Epics
                WHERE epicId = @i_epicId
            ))
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La fecha de inicio es posterior a la fecha de vencimiento.';
                SET @o_MensajeUsuario = 'La fecha de inicio no puede ser posterior a la fecha de vencimiento.';
                RETURN;
            END;

            IF @i_epicParentLink IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_GENERAL.TBL_Initiatives
                    WHERE initiativeId = @i_epicParentLink
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La iniciativa indicada no existe.';
                SET @o_MensajeUsuario = 'La iniciativa indicada no existe.';
                RETURN;
            END;

            IF @i_epicOwner IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_SECURITY.TBL_Users
                    WHERE userId = @i_epicOwner
                      AND userEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El propietario no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El propietario no existe o está inactivo.';
                RETURN;
            END;

            IF @i_epicStatus IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Status
                    WHERE statusId = @i_epicStatus
                      AND statusEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El estado no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El estado no existe o está inactivo.';
                RETURN;
            END;

            IF @i_epicPriority IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Priorities
                    WHERE priorityId = @i_epicPriority
                      AND priorityEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La prioridad no existe o está inactiva.';
                SET @o_MensajeUsuario = 'La prioridad no existe o está inactiva.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            UPDATE SQM_GENERAL.TBL_Epics
            SET epicName = COALESCE(@i_epicName, epicName),
                epicSummary = COALESCE(@i_epicSummary, epicSummary),
                epicDescription = COALESCE(@i_epicDescription, epicDescription),
                epicParentLink = COALESCE(@i_epicParentLink, epicParentLink),
                epicOwner = COALESCE(@i_epicOwner, epicOwner),
                epicStartDate = COALESCE(@i_epicStartDate, epicStartDate),
                epicDueDate = COALESCE(@i_epicDueDate, epicDueDate),
                epicPriority = COALESCE(@i_epicPriority, epicPriority),
                epicModificationDate = GETDATE(),
                epicModificatorId = @i_epicModificatorId,
                epicStatus = COALESCE(@i_epicStatus, epicStatus)
            WHERE epicId = @i_epicId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeTecnico = 'UPDATE ejecutado correctamente.';
            SET @o_MensajeUsuario = 'Epic actualizado correctamente.';
        END

        ELSE IF @w_Accion = 'S'
        BEGIN
            IF @i_PageNumber <= 0 OR @i_RowsPerPage <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'Los parámetros de paginación deben ser mayores que cero.';
                SET @o_MensajeUsuario = 'La página y el tamaño deben ser mayores que cero.';
                RETURN;
            END;

            DECLARE @Offset BIGINT;

            SET @Offset =
                (CONVERT(BIGINT, @i_PageNumber) - 1)
                * CONVERT(BIGINT, @i_RowsPerPage);

            SELECT
                epicId,
                epicName,
                epicSummary,
                epicDescription,
                epicParentLink,
                epicOwner,
                epicStartDate,
                epicDueDate,
                epicPriority,
                epicCreationDate,
                epicCreatorId,
                epicModificationDate,
                epicModificatorId,
                epicStatus
            FROM SQM_GENERAL.TBL_Epics
            ORDER BY epicId
            OFFSET @Offset ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            IF @@ROWCOUNT = 0
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeTecnico = 'La consulta se ejecutó correctamente, pero no encontró registros en la página solicitada.';
                SET @o_MensajeUsuario = 'No se encontraron Epics para la página solicitada.';
                RETURN;
            END;

            SET @o_Numero = 200;
            SET @o_MensajeTecnico = 'SELECT ejecutado correctamente.';
            SET @o_MensajeUsuario = 'Listado de Epics ejecutado correctamente.';
        END

        ELSE
        BEGIN
            SET @o_Numero = 405;
            SET @o_MensajeTecnico = 'Se recibió una acción no permitida.';
            SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
        END;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'Ocurrió un error al procesar la operación.';

    END CATCH;
END;
GO
