# infrastructure/repositories/StatusRepository.py
from infrastructure.database.connection import get_connection
from domain.entities.StatusModels import StatusCreate, StatusUpdate

class StatusRepository:
    
    def insert_status(self, data: StatusCreate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_Status]
                @i_statusName = ?,
                @i_statusCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.statusName,
            data.statusCreatorId,
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

    def update_status(self, data: StatusUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_Status]
                @i_statusId = ?,
                @i_statusName = ?,
                @i_statusModificatorId = ?,
                @i_statusEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.statusId,
            data.statusName,
            data.statusModificatorId,
            data.statusEnable,
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

    def list_statuses(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_Status]
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