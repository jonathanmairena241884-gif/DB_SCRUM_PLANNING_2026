# infrastructure/repositories/InitiativeRepository.py
from infrastructure.database.connection import get_connection
from domain.entities.InitiativeModels import InitiativeCreate, InitiativeUpdate

class InitiativeRepository:
    
    def insert_initiative(self, data: InitiativeCreate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Initiatives]
                @i_initiativeSummary = ?,
                @i_initiativeDescription = ?,
                @i_initiativeOwnerId = ?,
                @i_initiativeGoals = ?,
                @i_initiativeBusinessValueId = ?,
                @i_initiativeTargetStart = ?,
                @i_initiativeTargetEnd = ?,
                @i_initiativeCreatorId = ?,
                @i_initiativeStatusId = ?,
                @w_Accion = 'I',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.initiativeSummary,
            data.initiativeDescription,
            data.initiativeOwnerId,
            data.initiativeGoals,
            data.initiativeBusinessValueId,
            data.initiativeTargetStart,
            data.initiativeTargetEnd,
            data.initiativeCreatorId,
            data.initiativeStatusId,
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

    def update_initiative(self, data: InitiativeUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Initiatives]
                @i_initiativeId = ?,
                @i_initiativeSummary = ?,
                @i_initiativeDescription = ?,
                @i_initiativeOwnerId = ?,
                @i_initiativeGoals = ?,
                @i_initiativeBusinessValueId = ?,
                @i_initiativeTargetStart = ?,
                @i_initiativeTargetEnd = ?,
                @i_initiativeModificatorId = ?,
                @i_initiativeStatusId = ?,
                @w_Accion = 'U',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.initiativeId,
            data.initiativeSummary,
            data.initiativeDescription,
            data.initiativeOwnerId,
            data.initiativeGoals,
            data.initiativeBusinessValueId,
            data.initiativeTargetStart,
            data.initiativeTargetEnd,
            data.initiativeModificatorId,
            data.initiativeStatusId,
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

    def list_initiatives(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Initiatives]
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