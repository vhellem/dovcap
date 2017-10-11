' Copy

' contextInst is the CC

'stop

set modelView = metis.currentModel.currentModelView
set currentObj = Nothing
set ccGlobals = new CC_Globals
set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set specs = metis.newInstanceList
set children = workWindow.children
for each child in children
    if hasInstance(child) then
        set inst = child.instance
        set modelObject = inst.parent
        set instType = inst.type
        set isTypes = inst.getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_AnyObject)
        ' Create the copy
        instName = InputBox("Enter identifier")
        set newInst = modelObject.newPart(instType)
        if Len(instName) > 0 then
            newInst.title = instName
            ' Check family connection
            set families = inst.getNeighbourObjects(1, GLOBAL_Type_EkaHasPart, GLOBAL_Type_CcFamily)
            for each family in families
                set rel = modelObject.ownerModel.newRelationship(GLOBAL_Type_EkaHasPart, family, newInst)
            next
            ' Copy IS relationship
            for each isType in isTypes
                set rel = modelObject.ownerModel.newRelationship(GLOBAL_Type_EkaIs, newInst, isType)
            next
            ' Then copy the EKA properties
            set ccInstanceType = new CC_InstanceType
            call ccInstanceType.copyProperties(inst, newInst, modelObject, false)
            ' And copy the view properties
            set properties = inst.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
            for each prop in properties
                call copyProp(modelObject, inst, prop, newInst, true)
            next
            call specs.addLast(newInst)
        end if
    end if
next

        ' Find view strategy model
        set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        set wObject = workWindow.instance
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


Private Sub copyProp(modelObject, fromInst, fromProp, toInst, isCcProp)
    dim toProp
    dim constrained, constrains
    dim rel

    if isCcProp then
        set toProp = modelObject.newPart(GLOBAL_Type_CCProperty)
        call copyPropertyValues(fromProp, toProp)
        set rel = modelObject.ownerModel.newRelationship(GLOBAL_Type_CCHasProperty, toInst, toProp)
    else
        set toProp = modelObject.newPart(GLOBAL_Type_EkaProperty)
        call copyPropertyValues(fromProp, toProp)
        set rel = modelObject.ownerModel.newRelationship(GLOBAL_Type_EkaHasProperty, toInst, toProp)
        set constrains = fromProp.getNeighbourObjects(1, GLOBAL_Type_constrains, GLOBAL_Type_AnyObject)
        for each constrained in constrains
            set rel = modelObject.ownerModel.newRelationship(GLOBAL_Type_constrains, constrained, toProp)
        next
    end if
End Sub
