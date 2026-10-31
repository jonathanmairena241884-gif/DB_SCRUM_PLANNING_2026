from infrastructure.database.connection import get_connection
from domain.entities.TaskModels import TaskCreate, TaskUpdate

class TaskRepository:
    def insert_task(self, data: TaskCreate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_Tasks] @i_taskSummary=?, @i_taskDescription=?, @i_taskOwner=?, @i_taskParentLink=?, @i_taskOriginalEstimate=?, @i_taskCompletedWork=?, @i_taskRemaningWork=?, @i_taskStartDate=?, @i_taskDueDate=?, @i_taskActivityType=?, @i_taskCreatorId=?, @i_taskStatus=?, @w_Accion='I'",
            (data.taskSummary, data.taskDescription, data.taskOwner, data.taskParentLink, data.taskOriginalEstimate, data.taskCompletedWork, data.taskRemaningWork, data.taskStartDate, data.taskDueDate, data.taskActivityType, data.taskCreatorId, data.taskStatus))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def update_task(self, data: TaskUpdate):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_Tasks] @i_taskId=?, @i_taskSummary=?, @i_taskDescription=?, @i_taskOwner=?, @i_taskParentLink=?, @i_taskOriginalEstimate=?, @i_taskCompletedWork=?, @i_taskRemaningWork=?, @i_taskStartDate=?, @i_taskCompletedDate=?, @i_taskDueDate=?, @i_taskActivityType=?, @i_taskModificatorId=?, @i_taskStatus=?, @w_Accion='U'",
            (data.taskId, data.taskSummary, data.taskDescription, data.taskOwner, data.taskParentLink, data.taskOriginalEstimate, data.taskCompletedWork, data.taskRemaningWork, data.taskStartDate, data.taskCompletedDate, data.taskDueDate, data.taskActivityType, data.taskModificatorId, data.taskStatus))
        res = cursor.fetchone(); conn.commit(); cursor.close(); conn.close()
        return {"status_code": res[0] if res else 200}
    def list_tasks(self, page=1, rows=10):
        conn = get_connection(); cursor = conn.cursor()
        cursor.execute("EXEC [SQM_GENERAL].[USP_Tasks] @i_PageNumber=?, @i_RowsPerPage=?, @w_Accion='S'", (page, rows))
        cols = [c[0] for c in cursor.description] if cursor.description else []
        data = [dict(zip(cols, r)) for r in cursor.fetchall()]
        cursor.close(); conn.close()
        return {"data": data}