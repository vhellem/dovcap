' Search specifications

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
    call ccConfig.setVariantParameters(currentObj, varObject)
    call ccConfig.configureVariant(currentObj)
    set prodTypes = ccConfig.getInstanceTypes(currentObj, ccConfig.MODE_PART_TYPE)
    if prodTypes.count = 0 then
        set prodTypes = ccConfig.buildInstanceTypes(currentObj, projectObject, ccConfig.MODE_PART_TYPE)
    end if
    if prodTypes.count > 1 then
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select product type"
        cvwSelectDialog.heading = "Select product type"
        set prodTypes = cvwSelectDialog.show(prodTypes)
    end if
    if prodTypes.count = 1 then
        ' Find specifications
        set specs = prodTypes(1).getNeighbourObjects(1, GLOBAL_Type_EkaIs, GLOBAL_Type_Specification)
        i = 1
        for each spec in specs
            set parentVar = spec.parent
            if parentVar.uri <> projectObject.uri then
                call specs.removeAt(i)
            else
                i = i + 1
            end if
        next
        if specs.count > 1 then
            set cvwSelectDialog = new CVW_SelectDialog
            cvwSelectDialog.singleSelect = true
            cvwSelectDialog.title = "Select specification"
            cvwSelectDialog.heading = "Select specification"
            set specs = cvwSelectDialog.show(specs)
        end if

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
        ' Populate with new content
        set cvwWorkarea = new CVW_Workarea
        set cvwWorkarea.WorkWindow = workWindow
        cvwWorkarea.ViewStrategyModel = viewStrategyModel.uri
        call cvwWorkarea.populate(specs, -1)
        set children = workWindow.children
        for each child in children
            child.open
        next
    end if
end if

