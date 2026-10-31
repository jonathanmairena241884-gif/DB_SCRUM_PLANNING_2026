from infrastructure.database.connection import get_connection
from domain.entities.PBIModels import PBICreate, PBIUpdate

class PBIRepository:
    def insert_pbi(self, data: PBICreate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_ProductBacklogItems] @i_PBISummary=?, @i_PBIDescription=?, @i_PBIsAcceptanceCriteria=?, @i_PBIOwner=?, @i_PBIParentLink=?, @i_PBIStoryPoint=?, @i_PBIStartDate=?, @i_PBIDueDate=?, @i_PBIPriority=?, @i_PBICreatorId=?, @i_PBIStatus=?, @w_Accion='I'", 
            (data.PBISummary, data.PBIDescription, data.PBIsAcceptanceCriteria, data.PBIOwner, data.PBIParentLink, data.PBIStoryPoint, data.PBIStartDate, data.PBIDueDate, data.PBIPriority, data.PBICreatorId, data.PBIStatus))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def update_pbi(self, data: PBIUpdate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_ProductBacklogItems] @i_PBIId=?, @i_PBISummary=?, @i_PBIDescription=?, @i_PBIsAcceptanceCriteria=?, @i_PBIOwner=?, @i_PBIParentLink=?, @i_PBIStoryPoint=?, @i_PBIStartDate=?, @i_PBIDueDate=?, @i_PBIPriority=?, @i_PBIModificatorId=?, @i_PBIStatus=?, @w_Accion='U'", 
            (data.PBIId, data.PBISummary, data.PBIDescription, data.PBIsAcceptanceCriteria, data.PBIOwner, data.PBIParentLink, data.PBIStoryPoint, data.PBIStartDate, data.PBIDueDate, data.PBIPriority, data.PBIModificatorId, data.PBIStatus))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def list_pbis(self, page=1, rows=10):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_ProductBacklogItems] @i_PageNumber=?, @i_RowsPerPage=?, @w_Accion='S'", (page, rows))
        cols = [c[0] for c in cursor.description] if cursor.description else []
        data = [dict(zip(cols, r)) for r in cursor.fetchall()]
        cursor.close(); conn.close()
        return {"data": data}