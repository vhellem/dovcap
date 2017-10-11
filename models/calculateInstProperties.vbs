' Calculate method
' contextInst is the CC

    ' Initialize
    set ccGlobals = new CC_Globals
    set ccGlobals = Nothing
    set hasContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

    set model  = metis.currentModel

    set currentObj = Nothing
    set workWindow = getWorkareaView(getCVWmodel, "Workplace")
    set currentInst = workWindow.children(1).instance
    set instModel = currentInst.parent

'stop
    set ccInstanceType = new CC_InstanceType
    call ccInstanceType.calculateReqProperties(currentInst)

    set ccInstanceType.typeModel = model
    set ccInstanceType.instanceModel = instModel
    set ccInstanceType.productType = GLOBAL_Type_CO
    set ccInstanceType.productInstType = GLOBAL_Type_Requirement
    if Len(GLOBAL_CC_CurrentRole) > 0 then
        ccInstanceType.parameterRule = "Refresh"
    end if
    call ccInstanceType.updateViewInstance(ccObject, currentInst, Nothing, instModel, 0)

