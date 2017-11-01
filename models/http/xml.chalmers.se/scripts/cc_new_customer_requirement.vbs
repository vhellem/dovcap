' New customer requirement

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
    call ccConfig.configureRequirementTypes(projectObject, ccObject)
    ' Build types
    set reqTypes = ccConfig.getRequirementTypes(currentObj)
    if reqTypes.count > 1 then
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select variant"
        cvwSelectDialog.heading = "Select variant"
        set reqTypes = cvwSelectDialog.show(reqTypes)
    end if
    if reqTypes.count = 1 then
        set ccInstanceType = new CC_InstanceType
        set ccInstanceType.typeModel = contextInst.parent
        set ccInstanceType.instanceModel = GLOBAL_CC_CurrentProject
        set ccInstanceType.productType = GLOBAL_Type_CO
        set ccInstanceType.productInstType = GLOBAL_Type_Requirement
        ' Ask for identifiers
        compTypeName = reqTypes(1).title
        instName = InputBox("Enter identifier")
        set newInst = ccInstanceType.newInstance(varObject, compTypeName, instName)
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
            ' Populate with new instance
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

