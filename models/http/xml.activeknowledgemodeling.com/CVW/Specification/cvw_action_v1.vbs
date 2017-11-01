option explicit

Class CVW_Action

    Private model
    Private modelView
    Private aObject
    Private kind
    Private kindProperty

    ' Types
    Private actionType
    Private hasContentSpecType
    Private specContainerType
    Private specRelType
    Private hasViewSpecificationType
    Private hasViewSpecification2Type
    Private hasLanguageSpecificationType
    Private hasViewStrategyType
    Private hasViewstyleType
    Private consistsOfType

    ' Arguments
    Private argContextMode
    Private argSearchMode
    Private argToolbarTitle
    Private argWorkareaTitle
    Private argWorkareaMode
    Private argWorkspaceMode

    ' CVW classes
    Private cvwArgValue

   '---------------------------------------------------------------------------------------------------
    Public Property Get actionObject()
        set actionObject = aObject
    End Property

    Public Property Set actionObject(obj)
        if isEnabled(obj) then
            set aObject = obj

            ' Get arguments
            argContextMode   = cvwArgValue.getArgumentValue(aObject, "ContextMode")   ' CurrentModel | Repository | SubModel
            argSearchMode    = cvwArgValue.getArgumentValue(aObject, "SearchMode")    ' SelectAll | SelectOneFromList | SelectManyFromList
            argToolbarTitle  = cvwArgValue.getArgumentValue(aObject, "ToolbarTitle")  ' "" | "Name of toolbar"
            argWorkareaTitle = cvwArgValue.getArgumentValue(aObject, "WorkareaTitle") ' "" | "Name of workarea"
            argWorkareaMode  = cvwArgValue.getArgumentValue(aObject, "WorkareaMode")  ' New | Reuse | ReuseAndClear
            argWorkspaceMode = cvwArgValue.getArgumentValue(aObject, "WorkspaceMode") ' Clear | NoAction
        end if

    End Property

   '---------------------------------------------------------------------------------------------------
    Public Sub initialize(aObj)
        set aObject = aObj
        ' Get arguments
        set cvwArgValue = new CVW_ArgumentValue
        argContextMode   = cvwArgValue.getArgumentValue(aObject, "ContextMode")   ' CurrentModel | Repository | SubModel
        argSearchMode    = cvwArgValue.getArgumentValue(aObject, "SearchMode")    ' SelectAll | SelectOneFromList | SelectManyFromList
        argToolbarTitle  = cvwArgValue.getArgumentValue(aObject, "ToolbarTitle")  ' "" | "Name of toolbar"
        argWorkareaTitle = cvwArgValue.getArgumentValue(aObject, "WorkareaTitle") ' "" | "Name of workarea"
        if Len(argWorkareaTitle) = 0 then argWorkareaTitle = aObject.title
        argWorkareaMode  = cvwArgValue.getArgumentValue(aObject, "WorkareaMode")  ' None | New | Reuse | ReuseAndClear
        if Len(argWorkareaMode) = 0 then argWorkareaMode = "None"
        argWorkspaceMode = cvwArgValue.getArgumentValue(aObject, "WorkspaceMode") ' Clear | NoAction
    End Sub

   '---------------------------------------------------------------------------------------------------
    Public Sub execute
        dim instances
        dim containers, cont
        dim objects, obj, rel
        dim cvwWorkarea, cvwViewSpec, cvwSubAction
        dim clearMode, newMode, searchMode

        if isEnabled(aObject) then
            ' Initialize
            set cvwWorkarea = Nothing

            ' Perform action on actionObject
            ' [1] Handle workspace
            if argWorkspaceMode = "Clear" then
                set cvwWorkarea = new CVW_Workarea
                cvwWorkarea.clearWorkspace
            end if
            ' [2] Handle workarea
            if argWorkareaMode <> "None" then
                clearMode = false
                newMode = true
                if argWorkareaMode = "New" then
                    newMode = true
                elseif argWorkareaMode = "Reuse" then
                    newMode = false
                elseif argWorkareaMode = "ReuseAndClear" then
                    clearMode = true
                    newMode = false
                end if
                if not isValid(cvwWorkarea) then
                    set cvwWorkarea = new CVW_Workarea
                end if
                set cvwWorkarea.actionObject = aObject
                call cvwWorkarea.build(argWorkareaTitle, argToolbarTitle, newMode)
                if clearMode then
                    cvwWorkarea.clean
                end if
            end if
            ' [3] Handle contents
            set instances = getInstancesFromContentSpecification
            if isValid(instances) then
                set instances = getInstancesSelectedFromList(instances, argSearchMode)
            end if
            ' [4] Handle view specifications
            if isValid(instances) then
                set containers = actionObject.getNeighbourObjects(0, hasViewSpecificationType, specContainerType)
                if containers.count > 0 then
                    set cont = containers(1)
                    if isEnabled(cont) then
                        set obj = cvwWorkarea.objectView.instance
                        set rel = model.newRelationship(hasViewSpecification2Type, obj, cont)
                    end if
                end if
                ' [5] Generate views
                if isValid(cvwWorkarea) then
                    call cvwWorkarea.populateView(instances)
                    call cvwWorkarea.doLayout()
                end if
            end if

            ' Finally - Perform action on  sub-actionobjects
            set objects = actionObject.getNeighbourObjects(0, consistsOfType, actionType)
            if isValid(objects) then
                for each obj in objects
                    if isEnabled(obj) then
                        kind = obj.getNamedStringValue(kindProperty)
                        if kind = "Action" then
                            set cvwSubAction = new CVW_Action
                            call cvwSubAction.initialize(obj)
                            call cvwSubAction.execute()
                        end if
                    end if
                next
            end if
        end if

    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Sub connectWorkareaToViewspec(objView, cont)
        if hasInstance(objView) and isEnabled(cont) then
            set obj = objView.instance
            set rel = model.newRelationship(relType, obj, cont)
        end if
    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Function getInstancesSelectedFromList(instances, searchMode)
        dim cvwSelectDialog

        ' Handle select dialog if specified
        if searchMode = "SelectAll" then
            set getInstancesSelectedFromList = instances
        else
            set cvwSelectDialog = new CVW_SelectDialog
            if searchMode = "SelectOneFromList" then
                cvwSelectDialog.singleSelect = true
            elseif searchMode = "SelectManyFromList" then
                cvwSelectDialog.singleSelect = false
            end if
            set getInstancesSelectedFromList = cvwSelectDialog.show(instances)
            set cvwSelectDialog = Nothing
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Function getInstancesFromContentSpecification
        dim containers, cont
        dim cvwContentSpec

        set getInstancesFromContentSpecification = Nothing
        set containers = aObject.getNeighbourObjects(0, hasContentSpecType, specContainerType)
        for each cont in containers
            if isEnabled(cont) then
                set cvwContentSpec = new CVW_ContentSpecification
                set cvwContentSpec.model = getInstanceModel
                set getInstancesFromContentSpecification = cvwContentSpec.findInstances(cont.views(1))
                set cvwContentSpec = Nothing
            end if
        next
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Function getInstanceModel
        dim connector
        dim child, children
        dim part, parts
        dim modelView, modelViews

        set getInstanceModel = Nothing
        select case argContextMode
        case "CurrentModel"
            set getInstanceModel = model
        case "SubModel"
            set connector = Nothing
            set modelViews = model.views
            for each modelView in modelViews
                set children = modelView.children
                for each child in children
                    if child.isConnector then
                        set connector = child
                        exit for
                    end if
                next
                if isEnabled(connector) then
                    exit for
                end if
            next
            if isEnabled(connector) then
                set children = connector.children
                if children.count > 0 then
                    set child = children(1)
                    set parts = child.instance.parts
                    for each part in parts
                        if isEnabled(part) then
                            set getInstanceModel = part.ownerModel
                            exit for
                        end if
                    next
                end if
            end if
        end select
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Sub Class_Initialize
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set aObject   = model.currentInstance
        kindProperty  = "kind"
        ' Types
        set actionType                   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#Objype_CVW:Button_UUID")
        set hasContentSpecType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasContentSpecification_UUID")
        set specContainerType            = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set specRelType                  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:specificationRel_UUID")
        set hasViewSpecificationType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewSpecification1_UUID")
        set hasViewSpecification2Type    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewSpecification2_UUID")
        set hasLanguageSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification_UUID")
        set hasViewStrategyType          = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy_UUID")
        set hasViewstyleType             = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewstyleSpecification_UUID")
        set consistsOfType               = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_relships.kmd#RelType_CVW:consistsOfNode_UUID")
        ' Get arguments
        set cvwArgValue = new CVW_ArgumentValue
        argContextMode   = cvwArgValue.getArgumentValue(aObject, "ContextMode")   ' CurrentModel | Repository | SubModel
        argSearchMode    = cvwArgValue.getArgumentValue(aObject, "SearchMode")    ' SelectAll | SelectOneFromList | SelectManyFromList
        argToolbarTitle  = cvwArgValue.getArgumentValue(aObject, "ToolbarTitle")  ' "" | "Name of toolbar"
        argWorkareaTitle = cvwArgValue.getArgumentValue(aObject, "WorkareaTitle") ' "" | "Name of workarea"
        if Len(argWorkareaTitle) = 0 then argWorkareaTitle = aObject.title
        argWorkareaMode  = cvwArgValue.getArgumentValue(aObject, "WorkareaMode")  ' None | New | Reuse | ReuseAndClear
        if Len(argWorkareaMode) = 0 then argWorkareaMode = "None"
        argWorkspaceMode = cvwArgValue.getArgumentValue(aObject, "WorkspaceMode") ' Clear | NoAction
    End Sub
   '---------------------------------------------------------------------------------------------------

End Class


