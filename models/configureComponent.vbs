'stop
set contextInstance = contextInst
if isEnabled(GLOBAL_CC_CurrentProject) then
    set projectObject = GLOBAL_CC_CurrentProject
else
    set ccProject = new CC_Project
    set projectObject = ccProject.selectProject
    set GLOBAL_CC_CurrentProject = projectObject
end if
set hasContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

varName = ""
set varObjects = contextInstance.getNeighbourObjects(0, GLOBAL_Type_usesVAR, GLOBAL_Type_VAR)
if varObjects.count = 1 then varName = varObjects(1).title

if isEnabled(projectObject) then
    set ccConfigure = new CC_Configure
    set ccConfigure.productType = GLOBAL_Type_Product
'stop
    call ccConfigure.startConfigureCC(contextInstance, varName, projectObject)
    MsgBox "Configuration completed"
    set ccConfigure = Nothing
end if



