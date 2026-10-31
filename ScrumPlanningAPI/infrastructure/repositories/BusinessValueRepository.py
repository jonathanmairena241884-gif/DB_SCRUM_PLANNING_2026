# infrastructure/repositories/BusinessValueRepository.py
from infrastructure.database.connection import get_connection
from domain.entities.BusinessValueModels import BusinessValueCreate, BusinessValueUpdate

class BusinessValueRepository:
    
    def insert_business_value(self, data: BusinessValueCreate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_BusinessValues]
                @i_businessValueName = ?,
                @i_businessValueCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = ?,
                @o_MensajeUsuario = ?
        """, (data.businessValueName, data.businessValueCreatorId, o_Numero, o_MensajeUsuario))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_MensajeUsuario}

    def update_business_value(self, data: BusinessValueUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_BusinessValues]
                @i_businessValueId = ?,
                @i_businessValueName = ?,
                @i_businessValueModificatorId = ?,
                @i_businessValueEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ?,
                @o_MensajeUsuario = ?
        """, (data.businessValueId, data.businessValueName, data.businessValueModificatorId, data.businessValueEnable, o_Numero, o_MensajeUsuario))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_MensajeUsuario}

    def list_business_values(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_BusinessValues]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = ?,
                @o_MensajeUsuario = ?
        """, (page_number, rows_per_page, o_Numero, o_MensajeUsuario))

        columns = [col[0] for col in cursor.description] if cursor.description else []
        data = [dict(zip(columns, row)) for row in cursor.fetchall()] if columns else []
        
        cursor.close()
        conn.close()
        return {"data": data}