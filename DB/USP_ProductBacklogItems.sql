
CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_ProductBacklogItems]
(
    @i_PBIId INT = NULL,
    @i_PBISummary VARCHAR(500) = NULL,
    @i_PBIDescription VARCHAR(2000) = NULL,
    @i_PBIsAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_PBIOwner INT = NULL,
    @i_PBIParentLink INT = NULL,
    @i_PBIStoryPoint INT = NULL,
    @i_PBIStartDate DATE = NULL,
    @i_PBIDueDate DATE = NULL,
    @i_PBIPriority INT = NULL,
    @i_PBICreationDate DATETIME = NULL,
    @i_PBICreatorId INT = NULL,
    @i_PBIModificationDate DATETIME = NULL,
    @i_PBIModificatorId INT = NULL,
    @i_PBIStatus INT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_totalRows INT,
            @w_Offset BIGINT;

    SET @o_Numero = NULL;
    SET @o_MensajeTecnico = NULL;
    SET @o_MensajeUsuario = NULL;

    BEGIN TRY

        -- INSERTAR PBI
        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_PBISummary, '') = ''
                SET @o_MensajeUsuario = 'EL RESUMEN ES OBLIGATORIO';

            ELSE IF ISNULL(@i_PBIDescription, '') = ''
                SET @o_MensajeUsuario = 'LA DESCRIPCION ES OBLIGATORIA';

            ELSE IF ISNULL(@i_PBIsAcceptanceCriteria, '') = ''
                SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';

            ELSE IF ISNULL(@i_PBIOwner, 0) = 0
                SET @o_MensajeUsuario = 'EL OWNER ES OBLIGATORIO';

            ELSE IF ISNULL(@i_PBIParentLink, 0) = 0
                SET @o_MensajeUsuario = 'EL FEATURE PADRE ES OBLIGATORIO';

            ELSE IF ISNULL(@i_PBICreatorId, 0) = 0
                SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';

            ELSE IF ISNULL(@i_PBIStatus, 0) = 0
                SET @o_MensajeUsuario = 'EL STATUS ES OBLIGATORIO';

            ELSE IF @i_PBIStartDate IS NOT NULL
                AND @i_PBIDueDate IS NOT NULL
                AND @i_PBIStartDate > @i_PBIDueDate
                SET @o_MensajeUsuario = 'LA FECHA DE INICIO NO PUEDE SER MAYOR A LA FECHA DE VENCIMIENTO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Features
                WHERE featureId = @i_PBIParentLink
            )
                SET @o_MensajeUsuario = 'EL FEATURE PADRE NO EXISTE';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_PBIOwner
                  AND userEnable = 1
            )
                SET @o_MensajeUsuario = 'EL OWNER NO EXISTE O NO ESTA HABILITADO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_PBICreatorId
                  AND userEnable = 1
            )
                SET @o_MensajeUsuario = 'EL CREADOR NO EXISTE O NO ESTA HABILITADO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_Status
                WHERE statusId = @i_PBIStatus
                  AND statusEnable = 1
            )
                SET @o_MensajeUsuario = 'EL STATUS NO EXISTE O NO ESTA HABILITADO';

            ELSE IF @i_PBIPriority IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Priorities
                    WHERE priorityId = @i_PBIPriority
                      AND priorityEnable = 1
                )
                SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA HABILITADA';

            IF @o_MensajeUsuario IS NOT NULL
            BEGIN
                SET @o_Numero = 400;
            END
            ELSE
            BEGIN
                BEGIN TRANSACTION;

                INSERT INTO SQM_GENERAL.TBL_ProductBacklogItems
                (
                    PBISummary,
                    PBIDescription,
                    PBIsAcceptanceCriteria,
                    PBIOwner,
                    PBIParentLink,
                    PBIStoryPoint,
                    PBIStartDate,
                    PBIDueDate,
                    PBIPriority,
                    PBICreationDate,
                    PBICreatorId,
                    PBIModificationDate,
                    PBIModificatorId,
                    PBIStatus
                )
                VALUES
                (
                    @i_PBISummary,
                    @i_PBIDescription,
                    @i_PBIsAcceptanceCriteria,
                    @i_PBIOwner,
                    @i_PBIParentLink,
                    @i_PBIStoryPoint,
                    @i_PBIStartDate,
                    @i_PBIDueDate,
                    @i_PBIPriority,
                    COALESCE(@i_PBICreationDate, GETDATE()),
                    @i_PBICreatorId,
                    NULL,
                    NULL,
                    @i_PBIStatus
                );

                COMMIT TRANSACTION;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'PBI REGISTRADO CORRECTAMENTE';
            END
        END

        -- ACTUALIZAR PBI
        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_PBIId, 0) = 0
                SET @o_MensajeUsuario = 'EL ID DEL PBI ES OBLIGATORIO';

            ELSE IF ISNULL(@i_PBIModificatorId, 0) = 0
                SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_ProductBacklogItems
                WHERE PBIId = @i_PBIId
            )
                SET @o_MensajeUsuario = 'EL PBI NO EXISTE';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_PBIModificatorId
                  AND userEnable = 1
            )
                SET @o_MensajeUsuario = 'EL MODIFICADOR NO EXISTE O NO ESTA HABILITADO';

            ELSE IF EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_ProductBacklogItems
                WHERE PBIId = @i_PBIId
                  AND COALESCE(@i_PBIStartDate, PBIStartDate) IS NOT NULL
                  AND COALESCE(@i_PBIDueDate, PBIDueDate) IS NOT NULL
                  AND COALESCE(@i_PBIStartDate, PBIStartDate) >
                      COALESCE(@i_PBIDueDate, PBIDueDate)
            )
                SET @o_MensajeUsuario = 'LA FECHA DE INICIO NO PUEDE SER MAYOR A LA FECHA DE VENCIMIENTO';

            ELSE IF @i_PBIParentLink IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_GENERAL.TBL_Features
                    WHERE featureId = @i_PBIParentLink
                )
                SET @o_MensajeUsuario = 'EL FEATURE PADRE NO EXISTE';

            ELSE IF @i_PBIOwner IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_SECURITY.TBL_Users
                    WHERE userId = @i_PBIOwner
                      AND userEnable = 1
                )
                SET @o_MensajeUsuario = 'EL OWNER NO EXISTE O NO ESTA HABILITADO';

            ELSE IF @i_PBIStatus IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Status
                    WHERE statusId = @i_PBIStatus
                      AND statusEnable = 1
                )
                SET @o_MensajeUsuario = 'EL STATUS NO EXISTE O NO ESTA HABILITADO';

            ELSE IF @i_PBIPriority IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Priorities
                    WHERE priorityId = @i_PBIPriority
                      AND priorityEnable = 1
                )
                SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA HABILITADA';

            IF @o_MensajeUsuario IS NOT NULL
            BEGIN
                SET @o_Numero = 400;

                IF @o_MensajeUsuario = 'EL PBI NO EXISTE'
                    SET @o_Numero = 404;
            END
            ELSE
            BEGIN
                BEGIN TRANSACTION;

                UPDATE SQM_GENERAL.TBL_ProductBacklogItems
                SET PBISummary = COALESCE(@i_PBISummary, PBISummary),
                    PBIDescription = COALESCE(@i_PBIDescription, PBIDescription),
                    PBIsAcceptanceCriteria = COALESCE(@i_PBIsAcceptanceCriteria, PBIsAcceptanceCriteria),
                    PBIOwner = COALESCE(@i_PBIOwner, PBIOwner),
                    PBIParentLink = COALESCE(@i_PBIParentLink, PBIParentLink),
                    PBIStoryPoint = COALESCE(@i_PBIStoryPoint, PBIStoryPoint),
                    PBIStartDate = COALESCE(@i_PBIStartDate, PBIStartDate),
                    PBIDueDate = COALESCE(@i_PBIDueDate, PBIDueDate),
                    PBIPriority = COALESCE(@i_PBIPriority, PBIPriority),
                    PBIModificationDate = COALESCE(@i_PBIModificationDate, GETDATE()),
                    PBIModificatorId = @i_PBIModificatorId,
                    PBIStatus = COALESCE(@i_PBIStatus, PBIStatus)
                WHERE PBIId = @i_PBIId;

                COMMIT TRANSACTION;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PBI ACTUALIZADO CORRECTAMENTE';
            END
        END

        -- CONSULTAR PBI
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
               OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'LOS PARAMETROS DE PAGINACION SON OBLIGATORIOS Y DEBEN SER MAYORES A CERO';
            END
            ELSE
            BEGIN
                SET @w_Offset =
                    (CONVERT(BIGINT, @i_PageNumber) - 1)
                    * CONVERT(BIGINT, @i_RowsPerPage);

                SELECT
                    PBIId,
                    PBISummary,
                    PBIDescription,
                    PBIsAcceptanceCriteria,
                    PBIOwner,
                    PBIParentLink,
                    PBIStoryPoint,
                    PBIStartDate,
                    PBIDueDate,
                    PBIPriority,
                    PBICreationDate,
                    PBICreatorId,
                    PBIModificationDate,
                    PBIModificatorId,
                    PBIStatus
                FROM SQM_GENERAL.TBL_ProductBacklogItems
                ORDER BY PBIId
                OFFSET @w_Offset ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @w_totalRows = @@ROWCOUNT;

                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'PBIs LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END
        END

        -- ACCION NO HABILITADA
        ELSE
        BEGIN
            SET @o_Numero = 405;
            SET @o_MensajeUsuario = 'METODO NO HABILITADO';
            SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
        END

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @o_Numero = 500;
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR EL PBI';
        SET @o_MensajeTecnico = CONCAT(
            'ERROR EN USP_ProductBacklogItems - ',
            ERROR_PROCEDURE(), ' - ',
            ERROR_LINE(), ' - ',
            ERROR_MESSAGE()
        );

    END CATCH
END;
GO
