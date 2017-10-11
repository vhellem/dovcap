' New product / material specification

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
else
    set currentObj = contextInst
end if

set ccGlobals = new CC_Globals
set ccGlobals = Nothing

set currentModel = metis.currentModel
set currentModelView = currentModel.currentModelView

'stop

' Select project
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
    call ccConfig.setVariantParameters(currentObj, varObject)
    call ccConfig.configureVariant(currentObj)
    ' Find product type
    set prodType = ccConfig.getInstanceType(currentObj, projectObject, ccConfig.MODE_PART_TYPE)
    if not isEnabled(prodType) then
        MsgBox "This functions requires a product type to be specified!" & vbCrLf & "No product type was found!"
    else
            set ccInstanceType = new CC_InstanceType
            set ccInstanceType.typeModel = contextInst.parent
            set ccInstanceType.instanceModel = GLOBAL_CC_CurrentProject
            set ccInstanceType.productType = GLOBAL_Type_Part
            set ccInstanceType.productInstType = GLOBAL_Type_Specification
            ' Ask for identifiers
            instName = InputBox("Enter identifier")
            set newInst = ccInstanceType.newInstance(projectObject, contextInst, varObject, prodType, instName, 1, false)
            if isEnabled(newInst) then
                ' Find view strategy model
                set rels = wObject.getNeighbourRelationships(0, hasViewStrategyType)
                if rels.count > 0 then
                    set viewStrategyModel = rels(1).target
                end if
                ' Remove content
                set children = workWindow.children
                for each child in children
                    call currentModelView.deleteObjectView(child)
                next
                ' Populate view with new instance
                set instances = metis.newInstanceList
                instances.addLast newInst
                set cvwWorkarea = new CVW_Workarea
                set cvwWorkarea.WorkWindow = workWindow
                cvwWorkarea.ViewStrategyModel = viewStrategyModel.uri
                call cvwWorkarea.populate(instances, -1)
                set children = workWindow.children
                for each child in children
                    child.open
                next
            end if
    end if
end if

