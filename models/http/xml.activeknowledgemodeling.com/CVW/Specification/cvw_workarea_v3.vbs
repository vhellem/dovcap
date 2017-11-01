option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Workarea

    Public  title                       ' String
    'Public  actionObjext               ' Is specified below
    'Public  objectView                 ' Is specified below

    ' Context variables
    Private model
    Private modelView
    Private aObject

    ' Arguments
    Private TitleBarLayout
    Private WindowLayout
    Private WorkareaLayout
    Private WorkspaceLayout
    Private TitleBarSymbol
    Private WindowSymbol
    Private WorkareaSymbol
    Private HierarchyLayout

    ' Types
    Private buttonType                   ' IMetisType
    Private consistsOfType               ' IMetisType
    Private titlebarType                 ' IMetisType
    Private windowType                   ' IMetisType
    Private specContainerType            ' IMetisType
    Private anyObjectType                ' IMetisType
    Private specRelType                  ' IMetisType
    Private isTopType                    ' IMetisType
    Private hasViewSpecification2Type    ' IMetisType
    Private hasLanguageSpecificationType ' IMetisType
    Private hasViewStrategyType          ' IMetisType
    Private hasViewstyleType             ' IMetisType
    Private hasPropertyType              ' IMetisType


    ' Layout strategies
    Private titleBarLayoutStrategy      ' IMetisInstance
    Private windowLayoutStrategy        ' IMetisInstance
    Private workareaLayoutStrategy      ' IMetisInstance
    Private workspaceLayoutStrategy     ' IMetisInstance
    Private hierarchyLayoutStrategy     ' IMetisInstance

    ' Others
    Private argObj                      ' CVW_ArgumentValue
    Private window                      ' CVW_Window
    Private titlebarIndex               ' Integer
    Private workareaIndex               ' Integer

    'CVW objects
    Private cvwViewSpecification
    Private cvwLanguageSpecification
    Private cvwViewStrategy
    Private cvwViewstyleSpecification

    ' Public property ---------------------
    Public Property Get objectView               'IMetisObjectView
        set objectView = window.objectView
    End Property

    ' Public property ---------------------
    Public Property Get actionObject()           'IMetisObject
        set actionObject = aObject
    End Property

    Public Property Set actionObject(obj)
        if isEnabled(obj) then
            set aObject = obj
            ' Get arguments
            TitleBarLayout      = argObj.getArgumentValue(aObject, "TitleBarLayout")
            WindowLayout        = argObj.getArgumentValue(aObject, "WindowLayout")
            WorkareaLayout      = argObj.getArgumentValue(aObject, "WorkareaLayout")
            WorkspaceLayout     = argObj.getArgumentValue(aObject, "WorkspaceLayout")
            TitleBarSymbol      = argObj.getArgumentValue(aObject, "TitleBarSymbol")
            WindowSymbol        = argObj.getArgumentValue(aObject, "WindowSymbol")
            WorkareaSymbol      = argObj.getArgumentValue(aObject, "WorkareaSymbol")
            HierarchyLayout     = argObj.getArgumentValue(aObject, "HierarchyLayout")

            ' Layout strategies
            set titleBarLayoutStrategy  = metis.findLayoutStrategy(TitleBarLayout)
            set windowLayoutStrategy    = metis.findLayoutStrategy(WindowLayout)
            set workareaLayoutStrategy  = metis.findLayoutStrategy(WorkareaLayout)
            set workspaceLayoutStrategy = metis.findLayoutStrategy(WorkspaceLayout)
            set hierarchyLayoutStrategy = metis.findLayoutStrategy(HierarchyLayout)
        end if

    End Property

'-----------------------------------------------------------
    Public Sub clean()              ' as Boolean
        call window.clean()
    End Sub

'-----------------------------------------------------------
    Public Function find(name, parentView)              ' as Boolean
        find = window.find(name, windowType, parentView)
    End Function

'-----------------------------------------------------------
    Public Sub clearWorkspace
        dim m, parentView
        dim childView, children

        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", "CVW_Workspace")
        if not isEnabled(parentView) then
            exit sub
        end if
        set children = parentView.children
        for each childView in children
            modelView.deleteObjectView(childView)
        next
    End Sub

'-----------------------------------------------------------
    Public Function build(name, menuName, createNew)            ' as Boolean
        dim index, m
        dim child, children
        dim parentView, part

        build = false
        ' Find CVW model
        set m = getCVWmodel
        ' Find workspace
        set parentView = findInstanceView(m, windowType, "name", "CVW_Workspace")
        if not isEnabled(parentView) then
            exit function
        end if

        if createNew or not find(name, parentView) then
            if window.create(name, windowType, parentView) then
                with window.objectView
                    set .layoutStrategy = windowLayoutStrategy
                    .openSymbol   = WindowSymbol
                    .closedSymbol = WindowSymbol
                    .absTextScale = 1
                end with
                index = 1
                if Len(menuName) > 0 then
                    ' Create title bar
                    titlebarIndex = index
                    call createTitleBar(name, menuName)
                    index = index + 1
                end if
                ' Create work window
                workareaIndex = index
                call createWorkarea(name)
                index = index + 1
            end if
        end if
        set parentView.layoutStrategy = workspaceLayoutStrategy
        call window.doParentLayout
        build = true

    End Function

   '---------------------------------------------------------------------------------------------------
    Public Sub copyViewToWorkarea(contentModel, containerType, containerName)
        dim topContainer
        dim instance
        dim workarea

        set instance = metis.findInstance(contentModel.uri)
        if instance.type.uri = containerType.uri then
            if instance.name = containerName then
                set topContainer = instance
            end if
        end if

        set topContainer = findContainer(contentModel, containerType, containerName)

        if isEnabled(topContainer) then
            set workarea = window.objectView.children(workareaIndex)
            set modelView.currentInstanceView = topContainer.views(1)
            Call metis.runCommand("copy")
            set modelView.currentInstanceView = workarea
            Call metis.runCommand("paste-structure")
            'Call metis.runCommand("paste-synchronized-view")
            'Call metis.runCommand("paste-auto-virtual-synchronized-view")
        end if

    End Sub

   '---------------------------------------------------------------------------------------------------
    Public Sub moveViewToWorkarea(contentModel, containerType, containerName)
        dim topContainer
        dim instance
        dim workarea

        set instance = metis.findInstance(contentModel.uri)
        if instance.type.uri = containerType.uri then
            if instance.name = containerName then
                set topContainer = instance
            end if
        end if

        set topContainer = findContainer(contentModel, containerType, containerName)

        if isEnabled(topContainer) then
            set workarea = window.objectView.children(workareaIndex)
            'set topContainer.parent = workarea.instance
            set topContainer.views(1).parent = workarea
        end if

    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Function findContainer(parent, contType, contName)
        dim container, containers
        dim foundContainer

        set findContainer = Nothing
        set foundContainer = Nothing
        set containers = parent.parts
        for each container in containers
            if container.type.uri = contType.uri then
                if container.name = contName then
                    set foundContainer = container
                    exit for
                else
                    set foundContainer = findContainer(container, contType, contName)
                end if
            end if
        next
        if isEnabled(foundContainer) then
            set findContainer = foundContainer
        end if
    End Function

'-----------------------------------------------------------
    Private Function createTitleBar(name, template)                ' as Boolean
        dim titlebar
        dim objectMenu, itemView
        dim m

        createTitleBar = false
        set m = getCVWmodel
        call window.addSubWindow("Top", name, titlebarType)
        set titlebar = window.objectView.children(titlebarIndex)
        set objectMenu = m.findInstances(buttonType, "name", template)
        if isValid(objectMenu) then
            set itemView = objectMenu(1).views(1)
            call generateTree(itemView, titlebar, consistsOfType, buttonType, 0.05, 1.3)
        end if
        with titlebar
            set .layoutStrategy = titleBarLayoutStrategy
            .openSymbol      = TitleBarSymbol
            .closedSymbol    = TitleBarSymbol
            .absTextScale    = 30
            .geometry.height = 100
        end with


        createTitleBar = true

    End Function

'-----------------------------------------------------------
    Private Function createWorkarea(name)                ' as Boolean
        dim workarea

        set createWorkarea = Nothing
        call window.addSubWindow("Top", "WorkArea_["& name &"]", windowType)
        set workarea = window.objectView.children(workareaIndex)
        with workarea
            set .layoutStrategy = workareaLayoutStrategy
            .openSymbol   = WorkareaSymbol
            .closedSymbol = WorkareaSymbol
            .absTextScale = 200
        end with
        set createWorkarea = workarea

    End Function

'-----------------------------------------------------------
    Public Sub setSpecification(specObject)
        ' Connect to specification objects
    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Sub setViewSpecification(cont)
        dim relships, rel
        dim viewstyle

        set cvwViewSpecification = new CVW_ViewSpecification
        set relships = cont.neighbourrelationships
        for each rel in relships
            if not rel.target.uri = cont.uri then
                if isEnabled(rel) then
                    if rel.type.uri = hasLanguageSpecificationType.uri then
                        if not isValid(cvwViewSpecification.languageSpecification) then
                            set cvwLanguageSpecification = new CVW_LanguageSpecification
                            call cvwLanguageSpecification.build(rel.target)
                            set cvwViewSpecification.languageSpecification = cvwLanguageSpecification
                        end if
                    elseif rel.type.uri = hasViewStrategyType.uri then
                        if not isValid(cvwViewSpecification.viewStrategy) then
                            set cvwViewStrategy = new CVW_ViewStrategy
                            call cvwViewStrategy.build(rel.target)
                            set cvwViewSpecification.viewStrategy = cvwViewStrategy
                        end if
                    elseif rel.type.uri = hasViewstyleType.uri then
                        if not isValid(cvwViewSpecification.viewstyleSpecification) then
                            set cvwViewstyleSpecification = new CVW_ViewstyleSpecification
                            call cvwViewstyleSpecification.build(rel.target)
                            set cvwViewSpecification.viewstyleSpecification = cvwViewstyleSpecification
                        end if
                    elseif rel.type.uri = hasPropertyType.uri then
                        viewstyle = argObj.getArgumentValue(cont, "Viewstyle")
                        if Len(viewstyle) > 0 then
                            modelView.setViewStyle(viewStyle)
                        end if
                    end if
                end if
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Function creTreeView(obj, isTop, instances, parentView, strategyCont)
        dim obj1, obj2, objView
        dim relType, type1, type2
        dim workarea, wObject
        dim strategies, strategy
        dim relDir, rels, rel
        dim childInst, childInstView
        dim textScale, parentAbsScale, objAbsScale
        dim found

        if isEnabled(obj) then
            ' Create view of each the (top) instances
            set objView = parentView.newObjectView(obj)
            ' Handle textscale
            if isTop then
                objView.textScale = 0.5
                if isEnabled(hierarchyLayoutStrategy) then
                    set objView.layoutStrategy = hierarchyLayoutStrategy
                end if
            else
                objView.textScale = 0.125
            end if
            if objView.isNested then
                objView.close
                textScale = parentView.textScale
                if isTop then
                    objView.textScale = textScale * 0.5
                else
                    objView.textScale = textScale * 1.1
                end if
            end if

            ' Find view strategies
            set strategies = strategyCont.getNeighbourObjects(0, isTopType, anyObjectType)
            for each obj1 in strategies
                if isEnabled(obj1) then
                    found = false
                    if obj.type.uri = obj1.type.uri then
                        set rels = obj1.neighbourRelationships
                        for each rel in rels
                            if isEnabled(rel) then
                                if not isTopType.uri = rel.type.uri then
                                    set relType = rel.type
                                    if rel.origin.uri = obj1.uri then
                                        relDir = 0
                                        set obj2 = rel.target
                                        set type2 = obj2.type
                                        found = true
                                        exit for
                                    elseif rel.target.uri = obj1.uri then
                                        relDir = 1
                                        set obj2 = rel.origin
                                        set type2 = obj2.type
                                        found = true
                                        exit for
                                    end if
                                end if
                            end if
                        next
                    end if
                    if (found) then
                        ' Create children
                        set rels = obj.getNeighbourRelationships(relDir, relType)
                        for each rel in rels
                            if relDir = 0 then
                                set childInst = rel.target
                            else
                                set childInst = rel.origin
                            end if
                            if isValid(instances) then
                                if instanceInList(obj2,instances) then
                                    set childInstView = creTreeView(childInst, false, instances, objView, strategyCont)
                                end if
                            else
                                set childInstView = creTreeView(childInst, false, instances, objView, strategyCont)
                            end if
                        next
                    end if
                end if
            next
        end if
        if objView.isNested then
            call objView.doLayout
            if isTop then
                objView.open
            end if
        end if
        set creTreeView = objView
    End Function

'-----------------------------------------------------------
    Public Sub populateView(instances)
        dim obj, obj1, obj2, objView
        dim relType, type1, type2
        dim workarea, wObject
        dim viewSpecs, viewSpec
        dim strategyConts, strategyCont

        set wObject = objectView.instance
        set strategyCont = Nothing
        set viewSpecs = wObject.getNeighbourObjects(0, hasViewSpecification2Type, specContainerType)
        if viewSpecs.count > 0 then
            set viewSpec = viewSpecs(1)
            call setViewSpecification(viewSpec)
            if isValid(cvwViewstyleSpecification) then
                call cvwViewstyleSpecification.setViewstyle
            end if
            ' Find strategy container
            set strategyConts = viewSpec.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
            end if
        end if
        set workarea = window.objectView.children(workareaIndex)
        for each obj in instances
            set objView = creTreeView(obj, true, Nothing, workarea, strategyCont)
        next
    End Sub

'-----------------------------------------------------------
    Public Sub doLayout()
        window.doLayout
    End Sub

'-----------------------------------------------------------
    Public Sub doParentLayout()
        window.doParentLayout
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set aObject         = model.currentInstance
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set titlebarType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set windowType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set specContainerType            = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set anyObjectType                = metis.findType("metis:stdtypes#oid1")
        set specRelType                  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:specificationRel_UUID")
        set isTopType                    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasViewSpecification2Type    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewSpecification2_UUID")
        set hasLanguageSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification_UUID")
        set hasViewStrategyType          = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy_UUID")
        set hasViewstyleType             = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewstyleSpecification_UUID")
        set hasPropertyType              = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        set window          = new CVW_Window
        set argObj          = new CVW_ArgumentValue
        TitleBarLayout      = argObj.getArgumentValue(aObject, "TitleBarLayout")
        WindowLayout        = argObj.getArgumentValue(aObject, "WindowLayout")
        WorkareaLayout      = argObj.getArgumentValue(aObject, "WorkareaLayout")
        WorkspaceLayout     = argObj.getArgumentValue(aObject, "WorkspaceLayout")
        TitleBarSymbol      = argObj.getArgumentValue(aObject, "TitleBarSymbol")
        WindowSymbol        = argObj.getArgumentValue(aObject, "WindowSymbol")
        WorkareaSymbol      = argObj.getArgumentValue(aObject, "WorkareaSymbol")
        HierarchyLayout     = argObj.getArgumentValue(aObject, "HierarchyLayout")

        set titleBarLayoutStrategy  = metis.findLayoutStrategy(TitleBarLayout)
        set windowLayoutStrategy    = metis.findLayoutStrategy(WindowLayout)
        set workareaLayoutStrategy  = metis.findLayoutStrategy(WorkareaLayout)
        set workspaceLayoutStrategy = metis.findLayoutStrategy(WorkspaceLayout)
        set hierarchyLayoutStrategy = metis.findLayoutStrategy(HierarchyLayout)
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class


