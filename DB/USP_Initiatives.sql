
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_Initiatives
    @i_initiativeId INT = NULL,
    @i_initiativeSummary VARCHAR(200) = NULL,
    @i_initiativeDescription VARCHAR(2000) = NULL,
    @i_initiativeOwnerId INT = NULL,
    @i_initiativeGoals VARCHAR(255) = NULL,
    @i_initiativeBusinessValueId INT = NULL,
    @i_initiativeTargetStart DATE = NULL,
    @i_initiativeTargetEnd DATE = NULL,
    @i_initiativeCreatorId INT = NULL,
    @i_initiativeModificatorId INT = NULL,
    @i_initiativeStatusId INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_Offset BIGINT;

    SET @o_Numero = NULL;
    SET @o_MensajeTecnico = NULL;
    SET @o_MensajeUsuario = NULL;

    BEGIN TRY

        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_initiativeSummary, '') = ''
               OR ISNULL(@i_initiativeOwnerId, 0) <= 0
               OR ISNULL(@i_initiativeBusinessValueId, 0) <= 0
               OR ISNULL(@i_initiativeCreatorId, 0) <= 0
               OR ISNULL(@i_initiativeStatusId, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'Faltan datos obligatorios para registrar la iniciativa.';
                SET @o_MensajeUsuario = 'Resumen, propietario, valor de negocio, creador y estado son obligatorios.';
                RETURN;
            END;

            IF @i_initiativeTargetStart IS NOT NULL
               AND @i_initiativeTargetEnd IS NOT NULL
               AND @i_initiativeTargetStart > @i_initiativeTargetEnd
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La fecha inicial es posterior a la fecha final.';
                SET @o_MensajeUsuario = 'La fecha de inicio no puede ser posterior a la fecha de finalización.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_initiativeOwnerId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El propietario no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El propietario indicado no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_initiativeCreatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El creador no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El usuario creador no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_BusinessValues
                WHERE businessValueId = @i_initiativeBusinessValueId
                  AND businessValueEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El valor de negocio no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El valor de negocio indicado no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_Status
                WHERE statusId = @i_initiativeStatusId
                  AND statusEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El estado no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El estado indicado no existe o no se encuentra habilitado.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            INSERT INTO SQM_GENERAL.TBL_Initiatives
            (
                initiativeSummary,
                initiativeDescription,
                initiativeOwner,
                initiativeGoals,
                initiativeBusinessValue,
                initiativeTargetStart,
                initiativeTargetEnd,
                initiativeCreationDate,
                initiativeCreatorId,
                initiativeModificationDate,
                initiativeModificatorId,
                initiativeStatus
            )
            VALUES
            (
                @i_initiativeSummary,
                @i_initiativeDescription,
                @i_initiativeOwnerId,
                @i_initiativeGoals,
                @i_initiativeBusinessValueId,
                @i_initiativeTargetStart,
                @i_initiativeTargetEnd,
                GETDATE(),
                @i_initiativeCreatorId,
                NULL,
                NULL,
                @i_initiativeStatusId
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 201;
            SET @o_MensajeTecnico = 'Iniciativa registrada correctamente.';
            SET @o_MensajeUsuario = 'Iniciativa registrada correctamente.';
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_initiativeId, 0) <= 0
               OR ISNULL(@i_initiativeModificatorId, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El identificador de iniciativa o modificador no es válido.';
                SET @o_MensajeUsuario = 'El ID de la iniciativa y el usuario modificador son obligatorios.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Initiatives
                WHERE initiativeId = @i_initiativeId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeTecnico = 'No se encontró la iniciativa indicada.';
                SET @o_MensajeUsuario = 'La iniciativa que intenta actualizar no existe.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_initiativeModificatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El usuario modificador no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El usuario modificador no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF @i_initiativeOwnerId IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_SECURITY.TBL_Users
                    WHERE userId = @i_initiativeOwnerId
                      AND userEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El nuevo propietario no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El propietario indicado no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF @i_initiativeBusinessValueId IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_BusinessValues
                    WHERE businessValueId = @i_initiativeBusinessValueId
                      AND businessValueEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El nuevo valor de negocio no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El valor de negocio indicado no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF @i_initiativeStatusId IS NOT NULL
               AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Status
                    WHERE statusId = @i_initiativeStatusId
                      AND statusEnable = 1
               )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El nuevo estado no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El estado indicado no existe o no se encuentra habilitado.';
                RETURN;
            END;

            IF COALESCE(@i_initiativeTargetStart,
                        (SELECT initiativeTargetStart
                         FROM SQM_GENERAL.TBL_Initiatives
                         WHERE initiativeId = @i_initiativeId))
               >
               COALESCE(@i_initiativeTargetEnd,
                        (SELECT initiativeTargetEnd
                         FROM SQM_GENERAL.TBL_Initiatives
                         WHERE initiativeId = @i_initiativeId))
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'La fecha inicial es posterior a la fecha final.';
                SET @o_MensajeUsuario = 'La fecha de inicio no puede ser posterior a la fecha de finalización.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            UPDATE SQM_GENERAL.TBL_Initiatives
            SET initiativeSummary = COALESCE(@i_initiativeSummary, initiativeSummary),
                initiativeDescription = COALESCE(@i_initiativeDescription, initiativeDescription),
                initiativeOwner = COALESCE(@i_initiativeOwnerId, initiativeOwner),
                initiativeGoals = COALESCE(@i_initiativeGoals, initiativeGoals),
                initiativeBusinessValue = COALESCE(@i_initiativeBusinessValueId, initiativeBusinessValue),
                initiativeTargetStart = COALESCE(@i_initiativeTargetStart, initiativeTargetStart),
                initiativeTargetEnd = COALESCE(@i_initiativeTargetEnd, initiativeTargetEnd),
                initiativeModificationDate = GETDATE(),
                initiativeModificatorId = @i_initiativeModificatorId,
                initiativeStatus = COALESCE(@i_initiativeStatusId, initiativeStatus)
            WHERE initiativeId = @i_initiativeId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeTecnico = 'Iniciativa actualizada correctamente.';
            SET @o_MensajeUsuario = 'Iniciativa actualizada correctamente.';
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

            SET @w_Offset =
                (CAST(@i_PageNumber AS BIGINT) - 1) * CAST(@i_RowsPerPage AS BIGINT);

            SELECT *
            FROM SQM_GENERAL.TBL_Initiatives
            ORDER BY initiativeId
            OFFSET @w_Offset ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            IF @@ROWCOUNT = 0
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeTecnico = 'La consulta no encontró registros para la página solicitada.';
                SET @o_MensajeUsuario = 'No hay iniciativas disponibles en la página solicitada.';
            END
            ELSE
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeTecnico = 'Listado de iniciativas ejecutado correctamente.';
                SET @o_MensajeUsuario = 'Listado de iniciativas ejecutado correctamente.';
            END;
        END

        ELSE
        BEGIN
            SET @o_Numero = 405;
            SET @o_MensajeTecnico = 'Acción no reconocida por el procedimiento.';
            SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
        END;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'Ocurrió un error al procesar la solicitud.';

    END CATCH;
END;
GO
