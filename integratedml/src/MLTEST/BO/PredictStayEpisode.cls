Class MLTEST.BO.PredictStayEpisode Extends Ens.BusinessOperation
{

Property ModelName As %String(MAXLEN = 100);

/// Description
Parameter SETTINGS = "ModelName";

Parameter INVOCATION = "Queue";

/// Description
Method PredictStay(pRequest As MLTEST.Data.PredictionRequest, pResponse As MLTEST.Data.PredictionResponse) As %Status
{
    set predictionRequest = pRequest
    set pResponse = ##class("MLTEST.Data.PredictionResponse").%New()
    set pResponse.EpisodeId = predictionRequest.EpisodeId
    set tSC = $$$OK
    // CHECK IF MODEL EXISTS 
    set sql = "SELECT MODEL_NAME FROM INFORMATION_SCHEMA.ML_MODELS WHERE MODEL_NAME = '"_..ModelName_"'"
    set statement = ##class(%SQL.Statement).%New()
    set status = statement.%Prepare(sql)
    if ($$$ISOK(status)) {
        set resultSet = statement.%Execute()
        if (resultSet.%SQLCODE = 0) {
            set modelExists = 0
            while (resultSet.%Next() '= 0) {
                if (resultSet.%GetData(1) '= "") {
                    set modelExists = 1
                    // GET STAY PREDICTION WITH THE LAST EPISODE PERSISTED
                    set sqlPredict = "SELECT PREDICT("_..ModelName_") AS PredictedStay FROM MLTEST_Data.Episode WHERE %ID = ?"
                    set statementPredict = ##class(%SQL.Statement).%New(), statement.%ObjectSelectMode = 1
                    set statusPredict = statementPredict.%Prepare(sqlPredict)
                    if ($$$ISOK(statusPredict)) {
                        set resultSetPredict = statementPredict.%Execute(predictionRequest.EpisodeId)
                        if (resultSetPredict.%SQLCODE = 0) {
                                while (resultSetPredict.%Next() '= 0) {
                                    set pResponse.PredictedStay = resultSetPredict.%GetData(1)
                                }
                        }
                    }
                    else {
                        set tSC = statusPredict
                    }
                }
            }
            if (modelExists = 0) {
                // CREATION OF THE PREDICTION MODEL
                set sqlCreate = "CREATE MODEL "_..ModelName_" PREDICTING (Stay) FROM MLTEST_Data.EpisodeTrain"
                set statementCreate = ##class(%SQL.Statement).%New()
                set statusCreate = statementCreate.%Prepare(sqlCreate)
                if ($$$ISOK(status)) {
                    set resultSetCreate = statementCreate.%Execute()
                    if (resultSetCreate.%SQLCODE = 0) {
                        // MODEL IS TRAINED WITH THE CSV DATA PRE-LOADED
                        set sqlTrain = "TRAIN MODEL "_..ModelName
                        set statementTrain = ##class(%SQL.Statement).%New()
                        set statusTrain = statementTrain.%Prepare(sqlTrain)
                        if ($$$ISOK(statusTrain)) {
                            set resultSetTrain = statementTrain.%Execute()
                            if (resultSetTrain.%SQLCODE = 0) {
                                // VALIDATION OF THE MODEL WITH THE PRE-LOADED EPISODES
                                set sqlValidate = "VALIDATE MODEL "_..ModelName_" FROM MLTEST_Data.Episode"                                
                                set statementValidate = ##class(%SQL.Statement).%New()
                                set statusValidate = statementValidate.%Prepare(sqlValidate)
                                if ($$$ISOK(statusValidate)) {
                                    set resultSetValidate = statementValidate.%Execute()
                                    if (resultSetValidate.%SQLCODE = 0) {
                                        // GET STAY PREDICTION WITH THE LAST EPISODE PERSISTED
                                        set sqlPredict = "SELECT PREDICT("_..ModelName_") AS PredictedStay FROM MLTEST_Data.Episode WHERE %ID = ?"
                                        set statementPredict = ##class(%SQL.Statement).%New(), statement.%ObjectSelectMode = 1
                                        set statusPredict = statementPredict.%Prepare(sqlPredict)
                                        if ($$$ISOK(statusPredict)) {
                                            set resultSetPredict = statementPredict.%Execute(predictionRequest.EpisodeId)
                                            if (resultSetPredict.%SQLCODE = 0) {
                                                while (resultSetPredict.%Next() '= 0) {
                                                    set pResponse.PredictedStay = resultSetPredict.%GetData(1)
                                                }
                                            }
                                        }
                                        else {
                                            set tSC = statusPredict
                                        }
                                    }
                                }
                                else {
                                    set tSC = statusValidate
                                }
                            }
                        }
                        else {
                            set tSC = statusTrain
                        }
                    }
                }
                else {
                    set tSC = status
                }
            }
        }
    }
    else {
        set tSC = status
    }
    quit tSC
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="MLTEST.Data.PredictionRequest">
    <Method>PredictStay</Method>
  </MapItem>
</MapItems>
}

}
