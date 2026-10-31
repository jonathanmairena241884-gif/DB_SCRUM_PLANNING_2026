USE [DB_SCRUM_PLANNING];
GO

CREATE OR ALTER PROCEDURE [SQM_CATALOGS].[USP_BusinessValues]
(
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModificatorId INT = NULL,
    @i_businessValueEnable BIT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @w_totalRows INT;
    DECLARE @w_Offset BIGINT;

    SET @o_Numero = NULL;
    SET @o_MensajeTecnico = NULL;
    SET @o_MensajeUsuario = NULL;

    /* INSERTAR VALOR DE NEGOCIO */
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(LTRIM(RTRIM(@i_businessValueName)), '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE ES OBLIGATORIO';
            RETURN;
        END;

        IF ISNULL(@i_businessValueCreatorId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [SQM_SECURITY].[TBL_Users]
            WHERE userId = @i_businessValueCreatorId
              AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario =
                'EL USUARIO CREADOR NO EXISTE O ESTA INACTIVO';
            RETURN;
        END;

        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO [SQM_CATALOGS].[TBL_BusinessValues]
            (
                businessValueName,
                businessValueCreationDate,
                businessValueCreatorId,
                businessValueModificationDate,
                businessValueModificatorId,
                businessValueEnable
            )
            VALUES
            (
                @i_businessValueName,
                GETDATE(),
                @i_businessValueCreatorId,
                GETDATE(),
                NULL,
                1
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 201;
            SET @o_MensajeUsuario =
                'VALOR DE NEGOCIO REGISTRADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario =
                'ERROR AL REGISTRAR VALOR DE NEGOCIO';

            SET @o_MensajeTecnico =
                CONCAT_WS(
                    ' - ',
                    'ERROR AL REGISTRAR VALOR DE NEGOCIO',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
        END CATCH;

        RETURN;
    END;

    /* ACTUALIZAR VALOR DE NEGOCIO */
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_businessValueId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID ES OBLIGATORIO';
            RETURN;
        END;

        IF ISNULL(@i_businessValueModificatorId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [SQM_CATALOGS].[TBL_BusinessValues]
            WHERE businessValueId = @i_businessValueId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO NO EXISTE';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [SQM_SECURITY].[TBL_Users]
            WHERE userId = @i_businessValueModificatorId
              AND userEnable = 1
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario =
                'EL USUARIO MODIFICADOR NO EXISTE O ESTA INACTIVO';
            RETURN;
        END;

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_CATALOGS].[TBL_BusinessValues]
            SET businessValueName =
                    COALESCE(@i_businessValueName, businessValueName),
                businessValueModificationDate = GETDATE(),
                businessValueModificatorId = @i_businessValueModificatorId,
                businessValueEnable =
                    COALESCE(@i_businessValueEnable, businessValueEnable)
            WHERE businessValueId = @i_businessValueId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario =
                'VALOR DE NEGOCIO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario =
                'ERROR AL ACTUALIZAR VALOR DE NEGOCIO';

            SET @o_MensajeTecnico =
                CONCAT_WS(
                    ' - ',
                    'ERROR AL ACTUALIZAR VALOR DE NEGOCIO',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
        END CATCH;

        RETURN;
    END;

    /* LISTAR VALORES DE NEGOCIO CON PAGINACION */
    ELSE IF @w_Accion = 'S'
    BEGIN
        IF ISNULL(@i_PageNumber, 0) <= 0
           OR ISNULL(@i_RowsPerPage, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario =
                'LA PAGINA Y EL TAMANO DE PAGINA DEBEN SER MAYORES QUE CERO';
            RETURN;
        END;

        SET @w_Offset =
            (CONVERT(BIGINT, @i_PageNumber) - 1)
            * CONVERT(BIGINT, @i_RowsPerPage);

        BEGIN TRY
            SELECT
                businessValueId,
                businessValueName,
                businessValueCreationDate,
                businessValueCreatorId,
                businessValueModificationDate,
                businessValueModificatorId,
                businessValueEnable
            FROM [SQM_CATALOGS].[TBL_BusinessValues]
            ORDER BY businessValueId
            OFFSET @w_Offset ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT;

            IF @w_totalRows > 0
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario =
                    'VALORES DE NEGOCIO LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario =
                    'NO HAY MAS REGISTROS PARA LISTAR';
            END;
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario =
                'ERROR AL LISTAR VALORES DE NEGOCIO';

            SET @o_MensajeTecnico =
                CONCAT_WS(
                    ' - ',
                    'ERROR AL LISTAR VALORES DE NEGOCIO',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
        END CATCH;

        RETURN;
    END;

    /* ACCION NO VALIDA */
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'ACCION NO VALIDA. USE I, U O S';
        SET @o_MensajeTecnico =
            'EL PROCEDIMIENTO NO TIENE HABILITADA ESA OPCION';
    END;
END;
GO