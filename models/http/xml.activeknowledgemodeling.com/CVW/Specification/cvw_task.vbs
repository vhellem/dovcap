option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Task

    ' Context variables
    Public  currentModel
    Public  currentModelView
    Public  currentInstance
    Public  currentInstanceView
    Public  useObjectType
    Public  noViewLevels
    Public  noNeighbourLevels
    Public  selectCurrent
    Public  contentModel
    Public  applyFilter

    Private buttonType
    Private consistsOfType
    Private specContainerType
    Private hasFilterType
    Private hasInstanceContextType
    Private hasSearchSpecificationType
    Private isTopType

    Private cvwArgValue

'-----------------------------------------------------------
    Public Sub openObjectWindow(obj, taskName, isTop)
        dim cvwModel, cvwAction, cvwWorkarea, cvwContentSpec
        dim actionName, actionObject
        dim workarea, workWindow, wObject
        dim searchCont, searchConts
        dim filterCont, filterConts
        dim rel, rels
        dim child, children
        dim selection
        dim instances

        if not isEnabled(obj) then
            exit sub
        end if

        set cvwModel = getCVWmodel
        set actionObject = findActionObject(obj, taskName)
        if isEnabled(actionObject) then
            set cvwAction = new CVW_MenuAction
            set cvwAction.configObject = actionObject
            if not isTop then
                set cvwAction.contextInstance  = obj
            end if
            call cvwAction.build
            if applyFilter then
                cvwAction.applyFilter = true
            end if
            call cvwAction.execute
            set workarea = cvwAction.workarea
            if isValid(workarea) then
                set workWindow = workarea.WorkWindow
                ' Get CVW_Workarea
                set cvwWorkarea = new CVW_Workarea
                set cvwWorkarea.WorkWindow = workWindow
                ' Set context instance
                set wObject = workWindow.instance
                set rels = wObject.getNeighbourRelationships(0, hasInstanceContextType)
                if rels.count > 0 then
                    set rel = rels(1)
                    set rel.target = obj
                end if
                ' Get search specification
                set searchConts = wObject.getNeighbourObjects(0, hasSearchSpecificationType, specContainerType)
                if searchConts.count > 0 then
                    set searchCont = searchConts(1)
                    ' Build the content specification
                    set cvwContentSpec = new CVW_ContentSpecification
                    set cvwContentSpec.currentModel     = currentModel
                    set cvwContentSpec.currentModelView = currentModelView
                    if isEnabled(contentModel) then
                        set cvwContentSpec.contentModel = contentModel
                    else
                        set cvwContentSpec.contentModel = cvwWorkarea.contentModel
                    end if
                    if isTop then
                        set cvwContentSpec.topInstance      = obj
                        call relocateIsTop(searchCont, obj)
                    else
                        set cvwContentSpec.contextInstance  = obj
                    end if
                    cvwContentSpec.SpecificationModel   = searchCont.uri
                    cvwContentSpec.PathMode = "Path"
                    cvwContentSpec.noLevels = noNeighbourLevels
                    if applyFilter then
                        cvwContentSpec.applyFilter = true
                        set filterConts = wObject.getNeighbourObjects(0, hasFilterType, specContainerType)
                        if filterConts.count > 0 then
                            set filterCont = filterConts(1)
                            cvwContentSpec.FilterModel = filterCont.uri
                        end if
                    end if
                    ' Do the search
                    set instances = cvwContentSpec.execute
                    if isValid(instances) then
                        cvwWorkarea.ContentSearchModel = cvwContentSpec.SpecificationModel
                        call cvwWorkarea.populate(instances, noViewLevels)
                        if isTop and selectCurrent then
                            set selection = metis.newInstanceList
                            selection.addLast obj
                            call currentModelView.select(selection)
                        end if
                    end if
                    set cvwContentSpec = Nothing
                end if
                call doWorkspaceLayout(workWindow.parent.parent)
                set cvwWorkarea = Nothing
            end if
            set cvwAction = Nothing
        end if

    End Sub

'-----------------------------------------------------------
    Private Sub relocateIsTop(searchCont, contextObj)
        dim obj
        dim part, parts
        dim rel, relships
        dim relView, partView

        set relships = searchCont.getNeighbourRelationships(0, isTopType)
        if relships.count > 0 then
            set rel = relships(1)
            set obj = rel.target
            if obj.type.uri = contextObj.type.uri then
                exit sub
            end if
            set relView = rel.views(1)
            set parts = searchCont.parts
            if parts.count > 0 then
                for each part in parts
                    if part.type.uri = contextObj.type.uri then
                        set rel.target = part
                        set partView = part.views(1)
                        set relView.target = partView
                        exit sub
                    end if
                next
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Function findActionObject(inst, actionName)
        dim cvwModel
        dim taskObject, taskObjects, actionObjects
        dim obj, typeInst, typeInstUri

        set findActionObject = Nothing
        set cvwModel = getCVWmodel
        ' Find specified action object
        set taskObjects = cvwModel.findInstances(buttonType, "name", actionName)
        if isValid (taskObjects) then
            if taskObjects.count > 0 then
                set taskObject = taskObjects(1)
                ' Find member corresponding to type
                set actionObjects = taskObject.getNeighbourObjects(0, consistsOfType, buttonType)
                if actionObjects.count > 0 then
                    for each obj in actionObjects
                        typeInstUri = cvwArgValue.getArgumentValue(obj, "Type")
                        set typeInst = metis.findInstance(typeInstUri)
                        if isEnabled(typeInst) then
                            if inst.type.uri = typeInst.type.uri then
                                set findActionObject = obj
                                exit for
                            end if
                        end if
                    next
                end if
                if not isEnabled(findActionObject) and not useObjectType then
                    set findActionObject = taskObject
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Sub doWorkspaceLayout(objView)
        dim layoutStrategy
        dim workspaceLayoutStrategy
        
        set workspaceLayoutStrategy = objView.layoutStrategy
        set layoutStrategy = metis.findLayoutStrategy("http://xml.activeknowledgemodeling.com/akm/views/matrix_layouts.kmd#_002ash3011bccb0hs5tr")
        set objView.layoutStrategy = layoutStrategy
        call metis.doLayout(objView)
        set objView.layoutStrategy = workspaceLayoutStrategy
        call metis.doLayout(objView)
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        ' Types
        set buttonType                 = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType             = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set specContainerType          = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasFilterType              = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#ObjType_CVW:hasFilterSpecification_UUID")
        set hasInstanceContextType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set hasSearchSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasSearchSpecification_UUID")
        set isTopType                  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        ' Others
        useObjectType = false
        selectCurrent  = false
        noViewLevels  = -1
        noNeighbourLevels = 2
        applyFilter = false
        set cvwArgValue = new CVW_ArgumentValue
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArgValue = Nothing
    End Sub

End Class


