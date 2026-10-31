# infrastructure/repositories/ActivityTypeRepository.py
from infrastructure.database.connection import get_connection
from domain.entities.ActivityTypeModels import ActivityTypeCreate, ActivityTypeUpdate

class ActivityTypeRepository:
    
    def insert_activity_type(self, data: ActivityTypeCreate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ActivityTypes]
                @i_activityTypeName = ?,
                @i_activityTypeCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.activityTypeName,
            data.activityTypeCreatorId,
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

    def update_activity_type(self, data: ActivityTypeUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ActivityTypes]
                @i_activityTypeId = ?,
                @i_activityTypeName = ?,
                @i_activityTypeModificatorId = ?,
                @i_activityTypeEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.activityTypeId,
            data.activityTypeName,
            data.activityTypeModificatorId,
            data.activityTypeEnable,
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

    def list_activity_types(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ActivityTypes]
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