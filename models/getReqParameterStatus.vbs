option explicit

Function getReqParameterStatusValue

    dim status
    dim ccGlobals, ccStatus
    dim currentModel, currentInstance
    dim instType
    dim hasParamType
    dim intVal

    getReqParameterStatusValue = -1

    set ccGlobals = new CC_Globals

    set currentModel = metis.currentModel
    set currentInstance = currentModel.currentInstance

    if not isEnabled(currentInstance) then
        exit function
    end if

'stop

    set ccStatus = new CC_Status
    getReqParameterStatusValue = ccStatus.getViewPropertyStatus(currentInstance, GLOBAL_CC_CurrentComponentFamily)
    set ccStatus  = Nothing
    set ccGlobals = Nothing

End Function

Function getReqParameterStatusExplanation

    dim status
    dim ccGlobals, ccStatus
    dim currentModel, currentInstance
    dim instType
    dim hasParamType
    dim intVal

    getReqParameterStatusExplanation = ""

    set ccGlobals = new CC_Globals

    set currentModel = metis.currentModel
    set currentInstance = currentModel.currentInstance

    if not isEnabled(currentInstance) then
        exit function
    end if

'stop

    set ccStatus = new CC_Status
    call ccStatus.getViewPropertyStatus(currentInstance, GLOBAL_CC_CurrentComponentFamily)
    getReqParameterStatusExplanation = ccStatus.explanation
    set ccStatus  = Nothing
    set ccGlobals = Nothing

End Function

Function getRequirementStatusValue

    dim currentModel, currentInstance
    dim ccGlobals, ccStatus
    dim reqType, reqTypes

    set ccGlobals = new CC_Globals

    set currentModel = metis.currentModel
    set currentInstance = currentModel.currentInstance

    if not isEnabled(currentInstance) then
        exit function
    end if

    set ccStatus = new CC_Status
    getRequirementStatusValue = ccStatus.getRequirementStatus(currentInstance, GLOBAL_CC_CurrentComponentFamily)
    set ccStatus  = Nothing
    set ccGlobals = Nothing

End Function

Function getCClineColor(isProperty)
    dim status

    getCClineColor = "white"
    if isProperty then
        status = getReqParameterStatusValue
    else
        status = getRequirementStatusValue
    end if
    if status > -1 then
        getCClineColor = "black"
    end if
    if status > -1 then
        getCClineColor = "black"
    end if
End Function




