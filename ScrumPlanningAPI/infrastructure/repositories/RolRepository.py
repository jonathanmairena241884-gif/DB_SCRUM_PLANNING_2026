from infrastructure.database.connection import get_connection
from domain.entities.RolModels import RolCreate, RolUpdate

class RolRepository:
    def insert_rol(self, data: RolCreate):
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC [SQM_SECURITY].[USP_Roles] @i_rolName = ?, @i_rolCreatorId = ?, @w_Accion = 'I'", (data.rolName, data.rolCreatorId))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def update_rol(self, data: RolUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC [SQM_SECURITY].[USP_Roles] @i_rolId = ?, @i_rolName = ?, @i_rolModificatorId = ?, @i_rolEnable = ?, @w_Accion = 'U'", (data.rolId, data.rolName, data.rolModificatorId, data.rolEnable))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def list_rols(self, page=1, rows=10):
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("EXEC [SQM_SECURITY].[USP_Roles] @i_PageNumber = ?, @i_RowsPerPage = ?, @w_Accion = 'S'", (page, rows))
        cols = [c[0] for c in cursor.description] if cursor.description else []
        data = [dict(zip(cols, r)) for r in cursor.fetchall()]
        cursor.close(); conn.close()
        return {"data": data}