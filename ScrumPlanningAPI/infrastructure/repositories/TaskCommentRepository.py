from infrastructure.database.connection import get_connection
from domain.entities.TaskCommentModels import TaskCommentCreate, TaskCommentUpdate

class TaskCommentRepository:
    def insert_comment(self, data: TaskCommentCreate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_TaskComments] @i_taskCommentParentLink=?, @i_taskCommentOwner=?, @i_taskCommentText=?, @i_taskCommentCreatorId=?, @w_Accion='I'", (data.taskCommentParentLink, data.taskCommentOwner, data.taskCommentText, data.taskCommentCreatorId))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def update_comment(self, data: TaskCommentUpdate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_TaskComments] @i_taskCommentId=?, @i_taskCommentText=?, @i_taskCommentModificatorId=?, @i_taskCommentStatus=?, @w_Accion='U'", (data.taskCommentId, data.taskCommentText, data.taskCommentModificatorId, data.taskCommentStatus))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def list_comments(self, page=1, rows=10):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_TaskComments] @i_PageNumber=?, @i_RowsPerPage=?, @w_Accion='S'", (page, rows))
        cols = [c[0] for c in cursor.description] if cursor.description else []
        data = [dict(zip(cols, r)) for r in cursor.fetchall()]
        cursor.close(); conn.close()
        return {"data": data}