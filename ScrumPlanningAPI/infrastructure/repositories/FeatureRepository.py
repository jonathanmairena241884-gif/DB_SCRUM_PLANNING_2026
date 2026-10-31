# infrastructure/repositories/FeatureRepository.py
from infrastructure.database.connection import get_connection
from domain.entities.FeatureModels import FeatureCreate, FeatureUpdate

class FeatureRepository:
    
    def insert_feature(self, data: FeatureCreate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Features]
                @i_featureSummary = ?,
                @i_featureDescription = ?,
                @i_featuresAcceptanceCriteria = ?,
                @i_featureParentLink = ?,
                @i_featureOwner = ?,
                @i_featureStartDate = ?,
                @i_featureDueDate = ?,
                @i_featurePriority = ?,
                @i_featureCreatorId = ?,
                @i_featureStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.featureSummary,
            data.featureDescription,
            data.featuresAcceptanceCriteria,
            data.featureParentLink,
            data.featureOwner,
            data.featureStartDate,
            data.featureDueDate,
            data.featurePriority,
            data.featureCreatorId,
            data.featureStatus,
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

    def update_feature(self, data: FeatureUpdate):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Features]
                @i_featureId = ?,
                @i_featureSummary = ?,
                @i_featureDescription = ?,
                @i_featuresAcceptanceCriteria = ?,
                @i_featureParentLink = ?,
                @i_featureOwner = ?,
                @i_featureStartDate = ?,
                @i_featureDueDate = ?,
                @i_featurePriority = ?,
                @i_featureModificatorId = ?,
                @i_featureStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ?,
                @o_MensajeTecnico = ?,
                @o_MensajeUsuario = ?
        """, (
            data.featureId,
            data.featureSummary,
            data.featureDescription,
            data.featuresAcceptanceCriteria,
            data.featureParentLink,
            data.featureOwner,
            data.featureStartDate,
            data.featureDueDate,
            data.featurePriority,
            data.featureModificatorId,
            data.featureStatus,
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

    def list_features(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()
        o_Numero = 0
        o_MensajeTecnico = ""
        o_MensajeUsuario = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Features]
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