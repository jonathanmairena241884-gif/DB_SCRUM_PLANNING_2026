USE [DB_SCRUM_PLANNING];
GO

CREATE OR ALTER PROCEDURE [SQM_SECURITY].[USP_Users]
(
    @i_userId INT = NULL,
    @i_userFullName VARCHAR(80) = NULL,
    @i_userName VARCHAR(80) = NULL,
    @i_userEmail VARCHAR(80) = NULL,
    @i_userPassword VARCHAR(256) = NULL,
    @i_userRolId INT = NULL,
    @i_userCreationDate DATETIME = NULL,
    @i_userCreatorId INT = NULL,
    @i_userModificationDate DATETIME = NULL,
    @i_userModificatorId INT = NULL,
    @i_userEnable BIT = NULL,
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

    DECLARE @w_userPasswordEncrypted VARBINARY(256);
    DECLARE @w_totalRows INT;
    DECLARE @w_Offset BIGINT;

    SET @o_Numero = NULL;
    SET @o_MensajeTecnico = NULL;
    SET @o_MensajeUsuario = NULL;

    /* INSERTAR USUARIO */
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(LTRIM(RTRIM(@i_userFullName)), '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE COMPLETO ES OBLIGATORIO';
            RETURN;
        END;

        IF ISNULL(LTRIM(RTRIM(@i_userName)), '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO ES OBLIGATORIO';
            RETURN;
        END;

        IF ISNULL(LTRIM(RTRIM(@i_userEmail)), '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO ELECTRONICO ES OBLIGATORIO';
            RETURN;
        END;

        IF ISNULL(@i_userPassword, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA CONTRASEÑA ES OBLIGATORIA';
            RETURN;
        END;

        IF @i_userRolId IS NULL
           OR NOT EXISTS
           (
               SELECT 1
               FROM [SQM_SECURITY].[TBL_Roles]
               WHERE rolId = @i_userRolId
                 AND rolEnable = 1
           )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE O NO ESTA HABILITADO';
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [SQM_SECURITY].[TBL_Users]
            WHERE userName = @i_userName
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
            RETURN;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM [SQM_SECURITY].[TBL_Users]
            WHERE userEmail = @i_userEmail
        )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO ELECTRONICO YA EXISTE';
            RETURN;
        END;

        BEGIN TRY
            BEGIN TRANSACTION;

            OPEN SYMMETRIC KEY KEY_HASH
            DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;

            SET @w_userPasswordEncrypted =
                [SQM_SECURITY].[Fn_EncryptByKey](@i_userPassword);

            CLOSE SYMMETRIC KEY KEY_HASH;

            INSERT INTO [SQM_SECURITY].[TBL_Users]
            (
                userFullName,
                userName,
                userEmail,
                userPassword,
                userRolId,
                userCreationDate,
                userCreatorId,
                userModificationDate,
                userModificatorId,
                userEnable
            )
            VALUES
            (
                @i_userFullName,
                @i_userName,
                @i_userEmail,
                @w_userPasswordEncrypted,
                @i_userRolId,
                COALESCE(@i_userCreationDate, GETDATE()),
                @i_userCreatorId,
                GETDATE(),
                NULL,
                1
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 201;
            SET @o_MensajeUsuario = 'USUARIO REGISTRADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL REGISTRAR USUARIO';

            SET @o_MensajeTecnico =
                CONCAT_WS(
                    ' - ',
                    'ERROR AL REGISTRAR USUARIO',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
        END CATCH;

        RETURN;
    END;

    /* ACTUALIZAR USUARIO */
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_userId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL USUARIO ES OBLIGATORIO';
            RETURN;
        END;

        IF ISNULL(@i_userModificatorId, 0) <= 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM [SQM_SECURITY].[TBL_Users]
            WHERE userId = @i_userId
        )
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL USUARIO NO EXISTE';
            RETURN;
        END;

        IF @i_userName IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM [SQM_SECURITY].[TBL_Users]
               WHERE userName = @i_userName
                 AND userId <> @i_userId
           )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
            RETURN;
        END;

        IF @i_userEmail IS NOT NULL
           AND EXISTS
           (
               SELECT 1
               FROM [SQM_SECURITY].[TBL_Users]
               WHERE userEmail = @i_userEmail
                 AND userId <> @i_userId
           )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO ELECTRONICO YA EXISTE';
            RETURN;
        END;

        IF @i_userRolId IS NOT NULL
           AND NOT EXISTS
           (
               SELECT 1
               FROM [SQM_SECURITY].[TBL_Roles]
               WHERE rolId = @i_userRolId
                 AND rolEnable = 1
           )
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE O NO ESTA HABILITADO';
            RETURN;
        END;

        IF @i_userPassword IS NOT NULL
           AND @i_userPassword = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA CONTRASEÑA NO PUEDE ESTAR VACIA';
            RETURN;
        END;

        BEGIN TRY
            BEGIN TRANSACTION;

            IF @i_userPassword IS NOT NULL
            BEGIN
                OPEN SYMMETRIC KEY KEY_HASH
                DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;

                SET @w_userPasswordEncrypted =
                    [SQM_SECURITY].[Fn_EncryptByKey](@i_userPassword);

                CLOSE SYMMETRIC KEY KEY_HASH;
            END;

            UPDATE [SQM_SECURITY].[TBL_Users]
            SET userFullName = COALESCE(@i_userFullName, userFullName),
                userName = COALESCE(@i_userName, userName),
                userEmail = COALESCE(@i_userEmail, userEmail),
                userPassword = COALESCE(
                    @w_userPasswordEncrypted,
                    userPassword
                ),
                userRolId = COALESCE(@i_userRolId, userRolId),
                userModificationDate = GETDATE(),
                userModificatorId = @i_userModificatorId,
                userEnable = COALESCE(@i_userEnable, userEnable)
            WHERE userId = @i_userId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'USUARIO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR USUARIO';

            SET @o_MensajeTecnico =
                CONCAT_WS(
                    ' - ',
                    'ERROR AL ACTUALIZAR USUARIO',
                    ERROR_PROCEDURE(),
                    ERROR_LINE(),
                    ERROR_MESSAGE()
                );
        END CATCH;

        RETURN;
    END;

    /* LISTAR USUARIOS CON PAGINACION */
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
                userId,
                userFullName,
                userName,
                userEmail,
                userRolId,
                userCreationDate,
                userCreatorId,
                userModificationDate,
                userModificatorId,
                userEnable
            FROM [SQM_SECURITY].[TBL_Users]
            ORDER BY userId
            OFFSET @w_Offset ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT;

            IF @w_totalRows > 0
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIOS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END;
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS USUARIOS';

            SET @o_MensajeTecnico =
                CONCAT_WS(
                    ' - ',
                    'ERROR AL LISTAR USUARIOS',
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