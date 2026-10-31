
USE DB_SCRUM_PLANNING;
GO

CREATE OR ALTER PROCEDURE [SQM_SECURITY].[USP_Roles]
(
    @i_rolId INT = NULL,
    @i_rolName VARCHAR(80) = NULL,
    @i_rolCreatorId INT = NULL,
    @i_rolModificatorId INT = NULL,
    @i_rolEnable BIT = NULL,
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

    -- INSERTAR ROL --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(LTRIM(RTRIM(@i_rolName)), '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL ROL ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_rolCreatorId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION TRX_INS_ROLES;

                INSERT INTO [SQM_SECURITY].[TBL_Roles]
                (
                    rolName,
                    rolCreationDate,
                    rolCreatorId,
                    rolModificationDate,
                    rolModificatorId,
                    rolEnable
                )
                VALUES
                (
                    @i_rolName,
                    GETDATE(),
                    @i_rolCreatorId,
                    GETDATE(),
                    NULL,
                    1
                );

                COMMIT TRANSACTION TRX_INS_ROLES;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'ROL REGISTRADO CORRECTAMENTE';
            END TRY
            BEGIN CATCH
                IF XACT_STATE() <> 0
                    ROLLBACK TRANSACTION TRX_INS_ROLES;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR ROL';
                SET @o_MensajeTecnico = CONCAT_WS(
                    ' - ',
                    'ERROR AL REGISTRAR ROL',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
            END CATCH
        END
    END

    -- ACTUALIZAR ROL --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_rolId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL ROL ES OBLIGATORIO';
        END
        ELSE IF ISNULL(@i_rolModificatorId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END
        ELSE
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION TRX_UPD_ROLES;

                UPDATE [SQM_SECURITY].[TBL_Roles]
                SET
                    rolName = COALESCE(@i_rolName, rolName),
                    rolModificationDate = GETDATE(),
                    rolModificatorId = @i_rolModificatorId,
                    rolEnable = COALESCE(@i_rolEnable, rolEnable)
                WHERE rolId = @i_rolId;

                IF @@ROWCOUNT = 0
                BEGIN
                    ROLLBACK TRANSACTION TRX_UPD_ROLES;

                    SET @o_Numero = 404;
                    SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
                END
                ELSE
                BEGIN
                    COMMIT TRANSACTION TRX_UPD_ROLES;

                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'ROL ACTUALIZADO CORRECTAMENTE';
                END
            END TRY
            BEGIN CATCH
                IF XACT_STATE() <> 0
                    ROLLBACK TRANSACTION TRX_UPD_ROLES;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR ROL';
                SET @o_MensajeTecnico = CONCAT_WS(
                    ' - ',
                    'ERROR AL ACTUALIZAR ROL',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
            END CATCH
        END
    END

    -- LISTAR ROLES --
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

            BEGIN TRY
                SELECT
                    rolId,
                    rolName,
                    rolCreationDate,
                    rolCreatorId,
                    rolModificationDate,
                    rolModificatorId,
                    rolEnable
                FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK)
                ORDER BY rolId
                OFFSET @w_Offset ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @w_totalRows = @@ROWCOUNT;

                IF @w_totalRows > 0
                BEGIN
                    SET @o_Numero = 200;
                    SET @o_MensajeUsuario = 'ROLES LISTADOS CORRECTAMENTE';
                END
                ELSE
                BEGIN
                    SET @o_Numero = 204;
                    SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
                END
            END TRY
            BEGIN CATCH
                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL LISTAR ROLES';
                SET @o_MensajeTecnico = CONCAT_WS(
                    ' - ',
                    'ERROR AL LISTAR ROLES',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
            END CATCH
        END
    END

    -- ACCION INVALIDA --
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END
END;
GO
