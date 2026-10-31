
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_CATALOGS.USP_ActivityTypes
    @i_activityTypeId INT = NULL,
    @i_activityTypeName VARCHAR(80) = NULL,
    @i_activityTypeCreatorId INT = NULL,
    @i_activityTypeModificatorId INT = NULL,
    @i_activityTypeEnable BIT = NULL,
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
            IF ISNULL(@i_activityTypeName, '') = ''
               OR ISNULL(@i_activityTypeCreatorId, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'Faltan datos obligatorios para registrar el tipo de actividad.';
                SET @o_MensajeUsuario = 'El nombre y el creador son obligatorios.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_activityTypeCreatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El usuario creador no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El usuario creador no existe o no se encuentra habilitado.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            INSERT INTO SQM_CATALOGS.TBL_ActivityTypes
            (
                activityTypeName,
                activityTypeCreationDate,
                activityTypeCreatorId,
                activityTypeModificationDate,
                activityTypeModificatorId,
                activityTypeEnable
            )
            VALUES
            (
                @i_activityTypeName,
                GETDATE(),
                @i_activityTypeCreatorId,
                NULL,
                NULL,
                1
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 201;
            SET @o_MensajeTecnico = 'Tipo de actividad registrado correctamente.';
            SET @o_MensajeUsuario = 'Tipo de actividad registrado correctamente.';
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_activityTypeId, 0) <= 0
               OR ISNULL(@i_activityTypeModificatorId, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El identificador o el usuario modificador no es válido.';
                SET @o_MensajeUsuario = 'El ID y el usuario modificador son obligatorios.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_ActivityTypes
                WHERE activityTypeId = @i_activityTypeId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeTecnico = 'No se encontró el tipo de actividad indicado.';
                SET @o_MensajeUsuario = 'El tipo de actividad que intenta actualizar no existe.';
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_activityTypeModificatorId
                  AND userEnable = 1
            )
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeTecnico = 'El usuario modificador no existe o está inactivo.';
                SET @o_MensajeUsuario = 'El usuario modificador no existe o no se encuentra habilitado.';
                RETURN;
            END;

            BEGIN TRANSACTION;

            UPDATE SQM_CATALOGS.TBL_ActivityTypes
            SET activityTypeName = COALESCE(@i_activityTypeName, activityTypeName),
                activityTypeModificationDate = GETDATE(),
                activityTypeModificatorId = @i_activityTypeModificatorId,
                activityTypeEnable = COALESCE(@i_activityTypeEnable, activityTypeEnable)
            WHERE activityTypeId = @i_activityTypeId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeTecnico = 'Tipo de actividad actualizado correctamente.';
            SET @o_MensajeUsuario = 'Tipo de actividad actualizado correctamente.';
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
                (CAST(@i_PageNumber AS BIGINT) - 1)
                * CAST(@i_RowsPerPage AS BIGINT);

            SELECT
                activityTypeId,
                activityTypeName,
                activityTypeCreationDate,
                activityTypeCreatorId,
                activityTypeModificationDate,
                activityTypeModificatorId,
                activityTypeEnable
            FROM SQM_CATALOGS.TBL_ActivityTypes
            ORDER BY activityTypeId
            OFFSET @w_Offset ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            IF @@ROWCOUNT = 0
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeTecnico = 'No existen registros en la página solicitada.';
                SET @o_MensajeUsuario = 'No hay tipos de actividad disponibles en la página solicitada.';
            END
            ELSE
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeTecnico = 'Listado de tipos de actividad ejecutado correctamente.';
                SET @o_MensajeUsuario = 'Listado de tipos de actividad ejecutado correctamente.';
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
