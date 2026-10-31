# infrastructure/repositories/EpicRepository.py
from infrastructure.database.connection import get_connection
from domain.entities.EpicModels import EpicCreate, EpicUpdate

class EpicRepository:
    
    def insert_epic(self, data: EpicCreate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Epics]
                @i_epicName = ?,
                @i_epicSummary = ?,
                @i_epicDescription = ?,
                @i_epicParentLink = ?,
                @i_epicOwner = ?,
                @i_epicStartDate = ?,
                @i_epicDueDate = ?,
                @i_epicPriority = ?,
                @i_epicCreatorId = ?,
                @i_epicStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.epicName,
            data.epicSummary,
            data.epicDescription,
            data.epicParentLink,
            data.epicOwner,
            data.epicStartDate,
            data.epicDueDate,
            data.epicPriority,
            data.epicCreatorId,
            data.epicStatus,
            o_Numero,
            o_MensajeTecnico,
            o_MensajeUsuario
        ))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "status_code": result[0] if result else o_Numero, 
            "message": result[1] if result else o_MensajeUsuario
        }

    def update_epic(self, data: EpicUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Epics]
                @i_epicId = ?,
                @i_epicName = ?,
                @i_epicSummary = ?,
                @i_epicDescription = ?,
                @i_epicParentLink = ?,
                @i_epicOwner = ?,
                @i_epicStartDate = ?,
                @i_epicDueDate = ?,
                @i_epicPriority = ?,
                @i_epicModificatorId = ?,
                @i_epicStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.epicId,
            data.epicName,
            data.epicSummary,
            data.epicDescription,
            data.epicParentLink,
            data.epicOwner,
            data.epicStartDate,
            data.epicDueDate,
            data.epicPriority,
            data.epicModificatorId,
            data.epicStatus,
            o_Numero,
            o_MensajeTecnico,
            o_MensajeUsuario
        ))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        return {
            "status_code": result[0] if result else o_Numero, 
            "message": result[1] if result else o_MensajeUsuario
        }

    def list_epics(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Epics]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (page_number, rows_per_page, o_Numero, o_MensajeTecnico, o_MensajeUsuario))

        columns = [col[0] for col in cursor.description] if cursor.description else []
        data = [dict(zip(columns, row)) for row in cursor.fetchall()] if columns else []
        
        cursor.close()
        conn.close()
        return {"data": data}