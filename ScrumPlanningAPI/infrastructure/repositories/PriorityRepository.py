from infrastructure.database.connection import get_connection
from domain.entities.PriorityModels import PriorityCreate, PriorityUpdate

class PriorityRepository:
    def insert_priority(self, data: PriorityCreate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_CATALOGS].[USP_Priorities] @i_priorityName = ?, @i_priorityCreatorId = ?, @w_Accion = 'I'", (data.priorityName, data.priorityCreatorId))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def update_priority(self, data: PriorityUpdate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_CATALOGS].[USP_Priorities] @i_priorityId = ?, @i_priorityName = ?, @i_priorityModificatorId = ?, @i_priorityEnable = ?, @w_Accion = 'U'", (data.priorityId, data.priorityName, data.priorityModificatorId, data.priorityEnable))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def list_priorities(self, page=1, rows=10):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_CATALOGS].[USP_Priorities] @i_PageNumber = ?, @i_RowsPerPage = ?, @w_Accion = 'S'", (page, rows))
        cols = [c[0] for c in cursor.description] if cursor.description else []
        data = [dict(zip(cols, r)) for r in cursor.fetchall()]
        cursor.close(); conn.close()
        return {"data": data}