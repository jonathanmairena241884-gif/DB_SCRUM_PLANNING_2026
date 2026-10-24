
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_Tasks
    @i_taskId INT = NULL,
    @i_taskSummary VARCHAR(200) = NULL,
    @i_taskDescription VARCHAR(MAX) = NULL,
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
        IF ISNULL(@i_taskSummary, '') = ''
           OR ISNULL(@i_taskDescription, '') = ''
           OR ISNULL(@i_taskOwner, 0) = 0
           OR ISNULL(@i_taskParentLink, 0) = 0
           OR ISNULL(@i_taskCreatorId, 0) = 0
           OR ISNULL(@i_taskStatus, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario =
                'Resumen, descripción, propietario, PBI padre, creador y estado son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_GENERAL.TBL_ProductBacklogItems
            WHERE PBIId = @i_taskParentLink
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El Product Backlog Item indicado no existe.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_taskOwner AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El propietario no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_taskCreatorId AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El creador no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_CATALOGS.TBL_Status
            WHERE statusId = @i_taskStatus AND statusEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El estado no existe o está inactivo.';
            RETURN;
        END;

        IF @i_taskActivityType IS NOT NULL
           AND NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_ActivityTypes
                WHERE activityTypeId = @i_taskActivityType
                  AND activityTypeEnable = 1
           )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El tipo de actividad no existe o está inactivo.';
            RETURN;
        END;

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

        SET @o_Numero = 201;
        SET @o_MensajeUsuario = 'Tarea registrada correctamente.';
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_taskId, 0) = 0
           OR ISNULL(@i_taskModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El ID de la tarea y el modificador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_GENERAL.TBL_Tasks
            WHERE taskId = @i_taskId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'La tarea no existe.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_taskModificatorId AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El usuario modificador no existe o está inactivo.';
            RETURN;
        END;

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

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Tarea actualizada correctamente.';
    END
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF @i_PageNumber <= 0 OR @i_RowsPerPage <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'La página y el tamaño deben ser mayores que cero.';
            RETURN;
        END;

        SELECT *
        FROM SQM_GENERAL.TBL_Tasks
        ORDER BY taskId
        OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
        FETCH NEXT @i_RowsPerPage ROWS ONLY;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Listado de tareas ejecutado correctamente.';
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
    END;
END;
GO
