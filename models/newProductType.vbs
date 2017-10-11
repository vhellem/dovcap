' New product type

' contextInst is the CC

set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")


' Set variant

' contextInst is the CC

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

if isEnabled(currentObj) then
    set objects = currentObj.getNeighbourObjects(0, GLOBAL_Type_hasVAR, GLOBAL_Type_VAR)
    if objects.count > 1 then
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select variant"
        cvwSelectDialog.heading = "Select variant"
        set variants = cvwSelectDialog.show(objects)
        if isValid(variants) then
            if variants.count = 1 then
                set varObject = variants(1)
                ' Connect usesVar relationship
                set rels = currentObj.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
                if rels.count = 1 then
                    set rel = rels(1)
                    set rel.target = varObject
                elseif rels.count = 0 then
                    ' Create rel
                    set model = varObject.ownerModel
                    set rel = model.newRelationship(GLOBAL_Type_usesVAR, currentObj, varObject)
                end if
            end if
        end if
    end if
end if
'stop
' Configure component according to the chosen variant
if isEnabled(varObject) then
    set currentObj = contextInst
    set ccConfig = new CC_Configure
    call ccConfig.setVariantParameters(currentObj, varObject)
    call ccConfig.configureVariant(currentObj)
    ' Get design solution (product types)
    set designSolutions = ccConfig.getDesignSolutions(currentObj)
    if designSolutions.count > 1 then
        set cvwSelectDialog = new CVW_SelectDialog
        cvwSelectDialog.singleSelect = true
        cvwSelectDialog.title = "Select design solution"
        cvwSelectDialog.heading = "Select design solution"
        set designSolutions = cvwSelectDialog.show(designSolutions)
    end if
'stop
    if designSolutions.count = 0 then
        MsgBox "This functions requires a design solution to be specified!" & vbCrLf & "No design solution was found!"
    elseif designSolutions.count = 1 then
        set ccInstanceType = new CC_InstanceType
        set ccInstanceType.typeModel = contextInst.parent
        set ccInstanceType.instanceModel = varObject
        set ccInstanceType.productType = GLOBAL_Type_DS
        set ccInstanceType.productInstType = GLOBAL_Type_Part
        ' Ask for identifiers
        instName = InputBox("Enter product type identifier")
        set newInst = ccInstanceType.newInstance(varObject, contextInst, varObject, designSolutions(1), instName, 2, false)
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


