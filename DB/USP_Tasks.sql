
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_Tasks
(
    @i_taskId INT = NULL,
    @i_taskSummary VARCHAR(500) = NULL,
    @i_taskDescription VARCHAR(2000) = NULL,
    @i_taskOwner INT = NULL,
    @i_taskParentLink INT = NULL,
    @i_taskOriginalEstimate DECIMAL(10,2) = NULL,
    @i_taskCompletedWork DECIMAL(10,2) = NULL,
    @i_taskRemaningWork DECIMAL(10,2) = NULL,
    @i_taskStartDate DATE = NULL,
    @i_taskCompletedDate DATE = NULL,
    @i_taskDueDate DATE = NULL,
    @i_taskActivityType INT = NULL,
    @i_taskCreatorId INT = NULL,
    @i_taskModificatorId INT = NULL,
    @i_taskStatus INT = NULL,
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

        -- INSERTAR TAREA
        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_taskSummary, '') = ''
                SET @o_MensajeUsuario = 'EL RESUMEN ES OBLIGATORIO';

            ELSE IF ISNULL(@i_taskDescription, '') = ''
                SET @o_MensajeUsuario = 'LA DESCRIPCION ES OBLIGATORIA';

            ELSE IF ISNULL(@i_taskOwner, 0) = 0
                SET @o_MensajeUsuario = 'EL OWNER ES OBLIGATORIO';

            ELSE IF ISNULL(@i_taskParentLink, 0) = 0
                SET @o_MensajeUsuario = 'EL PBI PADRE ES OBLIGATORIO';

            ELSE IF ISNULL(@i_taskCreatorId, 0) = 0
                SET @o_MensajeUsuario = 'EL CREADOR ES OBLIGATORIO';

            ELSE IF ISNULL(@i_taskStatus, 0) = 0
                SET @o_MensajeUsuario = 'EL STATUS ES OBLIGATORIO';

            ELSE IF @i_taskStartDate IS NOT NULL
                AND @i_taskDueDate IS NOT NULL
                AND @i_taskStartDate > @i_taskDueDate
                SET @o_MensajeUsuario = 'LA FECHA DE INICIO NO PUEDE SER MAYOR A LA FECHA DE VENCIMIENTO';

            ELSE IF @i_taskCompletedDate IS NOT NULL
                AND @i_taskStartDate IS NOT NULL
                AND @i_taskCompletedDate < @i_taskStartDate
                SET @o_MensajeUsuario = 'LA FECHA DE FINALIZACION NO PUEDE SER MENOR A LA FECHA DE INICIO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_ProductBacklogItems
                WHERE PBIId = @i_taskParentLink
            )
                SET @o_MensajeUsuario = 'EL PRODUCT BACKLOG ITEM NO EXISTE';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_taskOwner
                  AND userEnable = 1
            )
                SET @o_MensajeUsuario = 'EL OWNER NO EXISTE O NO ESTA HABILITADO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_taskCreatorId
                  AND userEnable = 1
            )
                SET @o_MensajeUsuario = 'EL CREADOR NO EXISTE O NO ESTA HABILITADO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_Status
                WHERE statusId = @i_taskStatus
                  AND statusEnable = 1
            )
                SET @o_MensajeUsuario = 'EL STATUS NO EXISTE O NO ESTA HABILITADO';

            ELSE IF @i_taskActivityType IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_ActivityTypes
                    WHERE activityTypeId = @i_taskActivityType
                      AND activityTypeEnable = 1
                )
                SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD NO EXISTE O NO ESTA HABILITADO';

            IF @o_MensajeUsuario IS NOT NULL
            BEGIN
                SET @o_Numero = 400;
            END
            ELSE
            BEGIN
                BEGIN TRANSACTION;

                INSERT INTO SQM_GENERAL.TBL_Tasks
                (
                    taskSummary,
                    taskDescription,
                    taskOwner,
                    taskParentLink,
                    taskOriginalEstimate,
                    taskCompletedWork,
                    taskRemaningWork,
                    taskStartDate,
                    taskCompletedDate,
                    taskDueDate,
                    taskActivityType,
                    taskCreationDate,
                    taskCreatorId,
                    taskModificationDate,
                    taskModificatorId,
                    taskStatus
                )
                VALUES
                (
                    @i_taskSummary,
                    @i_taskDescription,
                    @i_taskOwner,
                    @i_taskParentLink,
                    @i_taskOriginalEstimate,
                    @i_taskCompletedWork,
                    @i_taskRemaningWork,
                    @i_taskStartDate,
                    @i_taskCompletedDate,
                    @i_taskDueDate,
                    @i_taskActivityType,
                    GETDATE(),
                    @i_taskCreatorId,
                    NULL,
                    NULL,
                    @i_taskStatus
                );

                COMMIT TRANSACTION;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'TAREA REGISTRADA CORRECTAMENTE';
            END
        END

        -- ACTUALIZAR TAREA
        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_taskId, 0) = 0
                SET @o_MensajeUsuario = 'EL ID DE LA TAREA ES OBLIGATORIO';

            ELSE IF ISNULL(@i_taskModificatorId, 0) = 0
                SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Tasks
                WHERE taskId = @i_taskId
            )
                SET @o_MensajeUsuario = 'LA TAREA NO EXISTE';

            ELSE IF NOT EXISTS (
                SELECT 1
                FROM SQM_SECURITY.TBL_Users
                WHERE userId = @i_taskModificatorId
                  AND userEnable = 1
            )
                SET @o_MensajeUsuario = 'EL MODIFICADOR NO EXISTE O NO ESTA HABILITADO';

            ELSE IF EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Tasks
                WHERE taskId = @i_taskId
                  AND COALESCE(@i_taskStartDate, taskStartDate) IS NOT NULL
                  AND COALESCE(@i_taskDueDate, taskDueDate) IS NOT NULL
                  AND COALESCE(@i_taskStartDate, taskStartDate) >
                      COALESCE(@i_taskDueDate, taskDueDate)
            )
                SET @o_MensajeUsuario = 'LA FECHA DE INICIO NO PUEDE SER MAYOR A LA FECHA DE VENCIMIENTO';

            ELSE IF EXISTS (
                SELECT 1
                FROM SQM_GENERAL.TBL_Tasks
                WHERE taskId = @i_taskId
                  AND @i_taskCompletedDate IS NOT NULL
                  AND COALESCE(@i_taskStartDate, taskStartDate) IS NOT NULL
                  AND @i_taskCompletedDate <
                      COALESCE(@i_taskStartDate, taskStartDate)
            )
                SET @o_MensajeUsuario = 'LA FECHA DE FINALIZACION NO PUEDE SER MENOR A LA FECHA DE INICIO';

            ELSE IF @i_taskParentLink IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_GENERAL.TBL_ProductBacklogItems
                    WHERE PBIId = @i_taskParentLink
                )
                SET @o_MensajeUsuario = 'EL PRODUCT BACKLOG ITEM NO EXISTE';

            ELSE IF @i_taskOwner IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_SECURITY.TBL_Users
                    WHERE userId = @i_taskOwner
                      AND userEnable = 1
                )
                SET @o_MensajeUsuario = 'EL OWNER NO EXISTE O NO ESTA HABILITADO';

            ELSE IF @i_taskStatus IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_Status
                    WHERE statusId = @i_taskStatus
                      AND statusEnable = 1
                )
                SET @o_MensajeUsuario = 'EL STATUS NO EXISTE O NO ESTA HABILITADO';

            ELSE IF @i_taskActivityType IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM SQM_CATALOGS.TBL_ActivityTypes
                    WHERE activityTypeId = @i_taskActivityType
                      AND activityTypeEnable = 1
                )
                SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD NO EXISTE O NO ESTA HABILITADO';

            IF @o_MensajeUsuario IS NOT NULL
            BEGIN
                SET @o_Numero = 400;

                IF @o_MensajeUsuario = 'LA TAREA NO EXISTE'
                    SET @o_Numero = 404;
            END
            ELSE
            BEGIN
                BEGIN TRANSACTION;

                UPDATE SQM_GENERAL.TBL_Tasks
                SET taskSummary = COALESCE(@i_taskSummary, taskSummary),
                    taskDescription = COALESCE(@i_taskDescription, taskDescription),
                    taskOwner = COALESCE(@i_taskOwner, taskOwner),
                    taskParentLink = COALESCE(@i_taskParentLink, taskParentLink),
                    taskOriginalEstimate = COALESCE(@i_taskOriginalEstimate, taskOriginalEstimate),
                    taskCompletedWork = COALESCE(@i_taskCompletedWork, taskCompletedWork),
                    taskRemaningWork = COALESCE(@i_taskRemaningWork, taskRemaningWork),
                    taskStartDate = COALESCE(@i_taskStartDate, taskStartDate),
                    taskCompletedDate = COALESCE(@i_taskCompletedDate, taskCompletedDate),
                    taskDueDate = COALESCE(@i_taskDueDate, taskDueDate),
                    taskActivityType = COALESCE(@i_taskActivityType, taskActivityType),
                    taskModificationDate = GETDATE(),
                    taskModificatorId = @i_taskModificatorId,
                    taskStatus = COALESCE(@i_taskStatus, taskStatus)
                WHERE taskId = @i_taskId;

                COMMIT TRANSACTION;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'TAREA ACTUALIZADA CORRECTAMENTE';
            END
        END

        -- CONSULTAR TAREAS
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
               OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'LA PAGINA Y EL TAMANO DEBEN SER MAYORES A CERO';
            END
            ELSE
            BEGIN
                SET @w_Offset =
                    (CONVERT(BIGINT, @i_PageNumber) - 1)
                    * CONVERT(BIGINT, @i_RowsPerPage);

                SELECT
                    taskId,
                    taskSummary,
                    taskDescription,
                    taskOwner,
                    taskParentLink,
                    taskOriginalEstimate,
                    taskCompletedWork,
                    taskRemaningWork,
                    taskStartDate,
                    taskCompletedDate,
                    taskDueDate,
                    taskActivityType,
                    taskCreationDate,
                    taskCreatorId,
                    taskModificationDate,
                    taskModificatorId,
                    taskStatus
                FROM SQM_GENERAL.TBL_Tasks
                ORDER BY taskId
                OFFSET @w_Offset ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @w_totalRows = @@ROWCOUNT;

                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'TAREAS LISTADAS CORRECTAMENTE';
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
            SET @o_MensajeUsuario = 'ACCION NO VALIDA. USE I, U O S.';
            SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
        END

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @o_Numero = 500;
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LA TAREA';
        SET @o_MensajeTecnico = CONCAT(
            'ERROR EN USP_Tasks - ',
            ERROR_PROCEDURE(), ' - ',
            ERROR_LINE(), ' - ',
            ERROR_MESSAGE()
        );

    END CATCH
END;
GO
