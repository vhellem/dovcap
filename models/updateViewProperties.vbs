option explicit

dim model
dim inst, instModel
dim currentInst
dim instUri
dim ccInstanceType
dim workWindow, wObject
dim child, children
dim rels
dim viewStrategyModel
dim cvwWorkarea

set model = metis.currentModel
set currentInst  = model.currentInstance

'stop

instUri = currentInst.getNamedStringValue("externalID")
if Len(instUri) > 0 then
    set inst = metis.findInstance(instUri)
    if isEnabled(inst) then
        set model = inst.ownerModel
        set instModel = inst.parent

'stop
        set ccInstanceType = new CC_InstanceType
        set ccInstanceType.typeModel = model
        set ccInstanceType.instanceModel = instModel
        set ccInstanceType.productType = GLOBAL_Type_CO
        set ccInstanceType.productInstType = GLOBAL_Type_Requirement
        if Len(GLOBAL_CC_CurrentRole) > 0 then
            ccInstanceType.parameterRule = "Refresh"
        end if
        call ccInstanceType.updateViewInstance(ccObject, inst, Nothing, instModel, 0)
    end if
'stop
end if
        

