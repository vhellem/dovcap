' Show specification structure

' contextInst is the CC

set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")

'stop

set hasContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

set currentObj = Nothing
set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set wObject = workWindow.instance
set objects = wObject.getNeighbourObjects(0, hasContextType, GLOBAL_Type_AnyObject)
if objects.count > 0 then set varObject = objects(1)
if isEnabled(varObject) then
    set rels = contextInst.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
    if rels.count > 0 then
        set rel = rels(1)
        set rel.target = varObject
    end if
end if

set ccGlobals = new CC_Globals
set ccGlobals = Nothing

set currentModel = metis.currentModel
set currentModelView = currentModel.currentModelView

if isEnabled(GLOBAL_CC_CurrentProject) then
    set projectObject = GLOBAL_CC_CurrentProject
else
    set ccProject = new CC_Project
    set projectObject = ccProject.selectProject
    set GLOBAL_CC_CurrentProject = projectObject
end if
if isEnabled(projectObject) then
    set currentObj = contextInst
    set ccConfig = new CC_Configure
    'call ccConfig.setVariantParameters(currentObj, varObject)
    'call ccConfig.configureVariant(currentObj)
    call ccConfig.configureVariant2(varObject)
    ' Remove content
    set children = workWindow.children
    for each child in children
        call currentModelView.deleteObjectView(child)
    next
    ' Build view
    symbol1 = "http://xml.activeknowledgemodeling.com/eka/views/symbols/property_collection.svg#_002aspo015j1tsi9tl6v"
    symbol2 = "http://xml.activeknowledgemodeling.com/eka/views/symbols/property_as_fields.svg#_002aspo015ldsrveaja9"
    call ccConfig.buildConstraintsView(currentObj, varObject, workWindow, workWindow, symbol1, symbol2)
end if
