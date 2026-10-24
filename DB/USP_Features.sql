
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_Features
    @i_featureId INT = NULL,
    @i_featureSummary VARCHAR(200) = NULL,
    @i_featureDescription VARCHAR(MAX) = NULL,
    @i_featuresAcceptanceCriteria VARCHAR(MAX) = NULL,
    @i_featureParentLink INT = NULL,
    @i_featureOwner INT = NULL,
    @i_featureStartDate DATE = NULL,
    @i_featureDueDate DATE = NULL,
    @i_featurePriority INT = NULL,
    @i_featureCreatorId INT = NULL,
    @i_featureModificatorId INT = NULL,
    @i_featureStatus INT = NULL,
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
        IF ISNULL(@i_featureSummary, '') = ''
           OR ISNULL(@i_featureDescription, '') = ''
           OR ISNULL(@i_featuresAcceptanceCriteria, '') = ''
           OR ISNULL(@i_featureParentLink, 0) = 0
           OR ISNULL(@i_featureOwner, 0) = 0
           OR ISNULL(@i_featureCreatorId, 0) = 0
           OR ISNULL(@i_featureStatus, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario =
                'Resumen, descripción, criterios de aceptación, epic padre, propietario, creador y estado son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_GENERAL.TBL_Epics
            WHERE epicId = @i_featureParentLink
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El epic padre indicado no existe.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_featureOwner AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El propietario no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_featureCreatorId AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El creador no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_CATALOGS.TBL_Status
            WHERE statusId = @i_featureStatus AND statusEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El estado no existe o está inactivo.';
            RETURN;
        END;

        IF @i_featurePriority IS NOT NULL
           AND NOT EXISTS (
                SELECT 1
                FROM SQM_CATALOGS.TBL_Priorities
                WHERE priorityId = @i_featurePriority
                  AND priorityEnable = 1
           )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'La prioridad no existe o está inactiva.';
            RETURN;
        END;

        INSERT INTO SQM_GENERAL.TBL_Features
        (
            featureSummary,
            featureDescription,
            featuresAcceptanceCriteria,
            featureParentLink,
            featureOwner,
            featureStartDate,
            featureDueDate,
            featurePriority,
            featureCreationDate,
            featureCreatorId,
            featureModificationDate,
            featureModificatorId,
            featureStatus
        )
        VALUES
        (
            @i_featureSummary,
            @i_featureDescription,
            @i_featuresAcceptanceCriteria,
            @i_featureParentLink,
            @i_featureOwner,
            @i_featureStartDate,
            @i_featureDueDate,
            @i_featurePriority,
            GETDATE(),
            @i_featureCreatorId,
            NULL,
            NULL,
            @i_featureStatus
        );

        SET @o_Numero = 201;
        SET @o_MensajeUsuario = 'Feature registrado correctamente.';
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_featureId, 0) = 0
           OR ISNULL(@i_featureModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El ID del feature y el modificador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_GENERAL.TBL_Features
            WHERE featureId = @i_featureId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'El feature no existe.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_featureModificatorId AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El usuario modificador no existe o está inactivo.';
            RETURN;
        END;

        UPDATE SQM_GENERAL.TBL_Features
        SET featureSummary = COALESCE(@i_featureSummary, featureSummary),
            featureDescription = COALESCE(@i_featureDescription, featureDescription),
            featuresAcceptanceCriteria = COALESCE(@i_featuresAcceptanceCriteria, featuresAcceptanceCriteria),
            featureParentLink = COALESCE(@i_featureParentLink, featureParentLink),
            featureOwner = COALESCE(@i_featureOwner, featureOwner),
            featureStartDate = COALESCE(@i_featureStartDate, featureStartDate),
            featureDueDate = COALESCE(@i_featureDueDate, featureDueDate),
            featurePriority = COALESCE(@i_featurePriority, featurePriority),
            featureModificationDate = GETDATE(),
            featureModificatorId = @i_featureModificatorId,
            featureStatus = COALESCE(@i_featureStatus, featureStatus)
        WHERE featureId = @i_featureId;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Feature actualizado correctamente.';
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
        FROM SQM_GENERAL.TBL_Features
        ORDER BY featureId
        OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
        FETCH NEXT @i_RowsPerPage ROWS ONLY;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Listado de features ejecutado correctamente.';
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
    END;
END;
GO
