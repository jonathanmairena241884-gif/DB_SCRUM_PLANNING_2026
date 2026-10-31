
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_TaskComments
    @i_taskCommentId INT = NULL,
    @i_taskCommentParentLink INT = NULL,
    @i_taskCommentOwner INT = NULL,
    @i_taskCommentText NVARCHAR(MAX) = NULL,
    @i_taskCommentCreatorId INT = NULL,
    @i_taskCommentModificatorId INT = NULL,
    @i_taskCommentStatus BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = NULL;
    SET @o_MensajeTecnico = NULL;
    SET @o_MensajeUsuario = NULL;

    BEGIN TRY

        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_taskCommentParentLink, 0) <= 0
               OR ISNULL(@i_taskCommentOwner, 0) <= 0
               OR NULLIF(LTRIM(RTRIM(@i_taskCommentText)), N'') IS NULL
               OR ISNULL(@i_taskCommentCreatorId, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'La tarea, el propietario, el texto y el creador son obligatorios.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Tasks
                WHERE taskId = @i_taskCommentParentLink
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'La tarea indicada no existe.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_taskCommentOwner
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'El propietario no existe o está inactivo.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_taskCommentCreatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'El creador no existe o está inactivo.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            INSERT INTO SQM_GENERAL.TBL_TaskComments
            (
                taskCommentParentLink,
                taskCommentOwner,
                taskCommentText,
                taskCommentCreationDate,
                taskCommentCreatorId,
                taskCommentModificationDate,
                taskCommentModificatorId,
                taskCommentStatus
            )
            VALUES
            (
                @i_taskCommentParentLink,
                @i_taskCommentOwner,
                @i_taskCommentText,
                GETDATE(),
                @i_taskCommentCreatorId,
                NULL,
                NULL,
                COALESCE(@i_taskCommentStatus, 1)
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 201;
            SET @o_MensajeUsuario =
                'Comentario registrado correctamente.';
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_taskCommentId, 0) <= 0
               OR ISNULL(@i_taskCommentModificatorId, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'El ID del comentario y el modificador son obligatorios.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_TaskComments
                WHERE taskCommentId = @i_taskCommentId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'El comentario no existe.';
                RETURN;
            END;

            IF @i_taskCommentParentLink IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_GENERAL.TBL_Tasks
                    WHERE taskId = @i_taskCommentParentLink
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'La tarea indicada no existe.';
                RETURN;
            END;

            IF @i_taskCommentOwner IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_SECURITY.TBL_Users
                    WHERE userId = @i_taskCommentOwner
                      AND userEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'El propietario no existe o está inactivo.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_taskCommentModificatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'El usuario modificador no existe o está inactivo.';
                RETURN;
            END;

            IF @i_taskCommentText IS NOT NULL
               AND NULLIF(LTRIM(RTRIM(@i_taskCommentText)), N'') IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'El texto del comentario no puede estar vacío.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            UPDATE SQM_GENERAL.TBL_TaskComments
            SET taskCommentParentLink =
                    COALESCE(@i_taskCommentParentLink, taskCommentParentLink),
                taskCommentOwner =
                    COALESCE(@i_taskCommentOwner, taskCommentOwner),
                taskCommentText =
                    COALESCE(@i_taskCommentText, taskCommentText),
                taskCommentModificationDate = GETDATE(),
                taskCommentModificatorId = @i_taskCommentModificatorId,
                taskCommentStatus =
                    COALESCE(@i_taskCommentStatus, taskCommentStatus)
            WHERE taskCommentId = @i_taskCommentId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario =
                'Comentario actualizado correctamente.';
        END

        ELSE IF @w_Accion = 'S'
        BEGIN
            DECLARE @Offset BIGINT;

            IF @i_PageNumber <= 0 OR @i_RowsPerPage <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'La página y el tamaño deben ser mayores que cero.';
                RETURN;
            END;

            SET @Offset =
                (CAST(@i_PageNumber AS BIGINT) - 1)
                * CAST(@i_RowsPerPage AS BIGINT);

            SELECT
                taskCommentId,
                taskCommentParentLink,
                taskCommentOwner,
                taskCommentText,
                taskCommentCreationDate,
                taskCommentCreatorId,
                taskCommentModificationDate,
                taskCommentModificatorId,
                taskCommentStatus
            FROM SQM_GENERAL.TBL_TaskComments
            ORDER BY taskCommentId
            OFFSET @Offset ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            IF @@ROWCOUNT = 0
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario =
                    'No existen comentarios para la página solicitada.';
            END
            ELSE
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario =
                    'Listado de comentarios ejecutado correctamente.';
            END;
        END

        ELSE
        BEGIN
            SET @o_Numero = 405;
            SET @o_MensajeUsuario =
                'Acción no válida. Use I, U o S.';
        END;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario =
            'Ocurrió un error al procesar la operación.';

    END CATCH;
END;
GO
