
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE SQM_GENERAL.USP_Initiatives
    @i_initiativeId INT = NULL,
    @i_initiativeSummary VARCHAR(200) = NULL,
    @i_initiativeDescription VARCHAR(MAX) = NULL,
    @i_initiativeOwnerId INT = NULL,
    @i_initiativeGoals VARCHAR(MAX) = NULL,
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
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_initiativeSummary, '') = ''
           OR ISNULL(@i_initiativeOwnerId, 0) = 0
           OR ISNULL(@i_initiativeBusinessValueId, 0) = 0
           OR ISNULL(@i_initiativeCreatorId, 0) = 0
           OR ISNULL(@i_initiativeStatusId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario =
                'Resumen, propietario, valor de negocio, creador y estado son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_initiativeOwnerId AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El propietario no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM SQM_SECURITY.TBL_Users
            WHERE userId = @i_initiativeCreatorId AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El creador no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM SQM_CATALOGS.TBL_BusinessValues
            WHERE businessValueId = @i_initiativeBusinessValueId
              AND businessValueEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El valor de negocio no existe o está inactivo.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM SQM_CATALOGS.TBL_Status
            WHERE statusId = @i_initiativeStatusId AND statusEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El estado no existe o está inactivo.';
            RETURN;
        END;

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

        SET @o_Numero = 201;
        SET @o_MensajeUsuario = 'Iniciativa registrada correctamente.';
    END
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_initiativeId, 0) = 0
           OR ISNULL(@i_initiativeModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'El ID y el modificador son obligatorios.';
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1 FROM SQM_GENERAL.TBL_Initiatives
            WHERE initiativeId = @i_initiativeId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'La iniciativa no existe.';
            RETURN;
        END;

        UPDATE SQM_GENERAL.TBL_Initiatives
        SET initiativeSummary = COALESCE(@i_initiativeSummary, initiativeSummary),
            initiativeDescription = COALESCE(@i_initiativeDescription, initiativeDescription),
            initiativeOwner = COALESCE(@i_initiativeOwnerId, initiativeOwner),
            initiativeGoals = COALESCE(@i_initiativeGoals, initiativeGoals),
            initiativeBusinessValue = COALESCE(@i_initiativeBusinessValueId, initiativeBusinessValue),
            initiativeTargetStart  = COALESCE(@i_initiativeTargetStart, initiativeTargetStart),
            initiativeTargetEnd  = COALESCE(@i_initiativeTargetEnd, initiativeTargetEnd),
            initiativeModificationDate = GETDATE(),
            initiativeModificatorId = @i_initiativeModificatorId,
            initiativeStatus = COALESCE(@i_initiativeStatusId, initiativeStatus)
        WHERE initiativeId = @i_initiativeId;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Iniciativa actualizada correctamente.';
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
        FROM SQM_GENERAL.TBL_Initiatives
        ORDER BY initiativeId
        OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
        FETCH NEXT @i_RowsPerPage ROWS ONLY;

        SET @o_Numero = 200;
        SET @o_MensajeUsuario = 'Listado de iniciativas ejecutado correctamente.';
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'Acción no válida. Use I, U o S.';
    END;
END;
GO
