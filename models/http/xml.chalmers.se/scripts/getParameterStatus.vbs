option explicit

Function getParameterStatusValue

    dim status
    dim ccGlobals, ccStatus
    dim currentModel, currentInstance
    dim instType
    dim hasParamType
    dim intVal

    getParameterStatusValue = -1

    set ccGlobals = new CC_Globals

    set currentModel = metis.currentModel
    set currentInstance = currentModel.currentInstance

'stop
    if isEnabled(currentInstance) then
        set instType = currentInstance.type
        select case instType.uri
            case GLOBAL_Type_VP.uri             set hasParamType = GLOBAL_Type_hasVP
            case GLOBAL_Type_DP.uri             set hasParamType = GLOBAL_Type_hasDP
            case GLOBAL_Type_PP.uri             set hasParamType = GLOBAL_Type_hasPP
            case GLOBAL_Type_CP.uri             set hasParamType = GLOBAL_Type_hasCP
            case GLOBAL_Type_CPR.uri            set hasParamType = GLOBAL_Type_hasCPR
            case GLOBAL_Type_FP.uri             set hasParamType = GLOBAL_Type_hasFP
            case GLOBAL_Type_EkaProperty.uri    set harParamType = GLOBAL_Type_EkaHasProperty
        end select

        if isValid(hasParamType) then
            set ccStatus = new CC_Status
            getParameterStatusValue = ccStatus.getParameterStatus(currentInstance, hasParamType)
            set ccStatus = Nothing
        end if
    end if

End Function

Function getObjectStatusValue

    dim currentModel, currentInstance
    dim ccGlobals, ccStatus

    set ccGlobals = new CC_Globals

    set currentModel = metis.currentModel
    set currentInstance = currentModel.currentInstance

    set ccStatus = new CC_Status
    getObjectStatusValue = ccStatus.getObjectStatus(currentInstance)

End Function




