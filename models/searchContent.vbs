option explicit

Public Sub SearchContent(ccObj, roleName, typeOption, familyOption, aggregateOption, projectOption)
    dim ccConfig, ccGlobals, ccInstanceType, ccProject, cvwSelectDialog, cvwWorkarea
    dim currentModel, currentModelView, currentObj
    dim hasContextType, hasViewStrategyType
    dim workWindow, wObject
    dim varObject, projectObject, parentVar
    dim instances, objects
    dim rel, rels
    dim child, children
    dim ccReq, ccReqs, reqType
    dim viewStrategyModel
    dim i

    set hasContextType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
    set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")

    'stop

    set ccGlobals       = new CC_Globals
    set ccInstanceType  = new CC_InstanceType
    set cvwSelectDialog = new CVW_SelectDialog

    set currentModel = metis.currentModel
    set currentModelView = currentModel.currentModelView

    GLOBAL_CC_CurrentRole = roleName

    ' Find instance context (variant object)
    set currentObj = Nothing
    set workWindow = getWorkareaView(getCVWmodel, "Workplace")
    set wObject = workWindow.instance
    set objects = wObject.getNeighbourObjects(0, hasContextType, GLOBAL_Type_AnyObject)
    if objects.count > 0 then set varObject = objects(1)
    if isEnabled(varObject) then
        set rels = ccObj.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
        if rels.count > 0 then
            set rel = rels(1)
            set rel.target = varObject
        end if
    else
        set currentObj = ccObj
    end if

    if projectOption = 0 then
        set  projectObject = varObject
    else
        ' Find current project
        if isEnabled(GLOBAL_CC_CurrentProject) then
            set projectObject = GLOBAL_CC_CurrentProject
        else
            set ccProject = new CC_Project
            set projectObject = ccProject.selectProject
            set GLOBAL_CC_CurrentProject = projectObject
        end if
    end if

    if familyOption > 0 then
        if not isEnabled(GLOBAL_CC_CurrentFamily) then
            set ccFamily = new CC_Family
            set ccFamily.ProjectObject = projectObject
            set GLOBAL_CC_CurrentFamily = ccFamily.selectFamily
            set ccFamily = Nothing
        end if
    else
        set GLOBAL_CC_CurrentFamily = Nothing
    end if

    ' Configure
    set currentObj = ccObj
    set ccConfig = new CC_Configure
    call ccConfig.setVariantParameters(currentObj, varObject)
    call ccConfig.configureVariant(currentObj)

    if typeOption > 0 then
        ' Find Constraints
        set reqType = ccConfig.getRequirementType(currentObj, varObject)
        if isEnabled(reqType) then
            ' Find CC requirements by following the Is relationship
            set ccReqs = reqType.getNeighbourObjects(1, GLOBAL_Type_EkaIs, GLOBAL_Type_Requirement)
            i = 1
            for each ccReq in ccReqs
                set parentVar = ccReq.parent
                if parentVar.uri <> varObject.uri then
                    call ccReqs.removeAt(i)
                else
                    i = i + 1
                end if
            next
            if ccReqs.count > 1 then
                cvwSelectDialog.singleSelect = true
                cvwSelectDialog.title = "Select requirement"
                cvwSelectDialog.heading = "Select requirement"
                set ccReqs = cvwSelectDialog.show(ccReqs)
            end if
            if ccReqs.count = 1 then
                if typeOption = 1 then
                    set instances = ccReqs
                end if
            end if
        end if
        ' Find next level instances
        if aggregateOption > 0 then 
            if isEnabled(GLOBAL_CC_CurrentFamily) then
                set instances = metis.newInstanceList
                call instances.addLast(GLOBAL_CC_CurrentFamily)
            end if
        elseif typeOption > 1 then
            set ccInstanceType.typeModel = ccObj.parent
            set ccInstanceType.instanceModel = GLOBAL_CC_CurrentProject
            set ccInstanceType.productType = GLOBAL_Type_Requirement
            set ccInstanceType.productInstType = GLOBAL_Type_CCInstance
            set ccInstanceType.parentFamily = GLOBAL_CC_CurrentFamily
            set instances = ccInstanceType.findInstances2(Nothing, ccReqs(1))
        end if
        ' Find the final content and prepare views
        if instances.count > 1 then
            cvwSelectDialog.singleSelect = true
            cvwSelectDialog.title   = "Select requirement"
            cvwSelectDialog.heading = "Select requirement"
            set instances = cvwSelectDialog.show(instances)
        end if

        if instances.count > 0 then
            ' Create view instances
            ccInstanceType.parameterRule = "Parameters(" & roleName & ")"
            call ccInstanceType.updateViewInstance(currentObj, instances(1), Nothing, projectObject, 1)
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
            call cvwWorkarea.populate(instances, -1)
            set children = workWindow.children
            for each child in children
                child.open
            next
        end if
    end if
End Sub

