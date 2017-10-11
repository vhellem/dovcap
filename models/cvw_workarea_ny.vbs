option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Workarea

    ' Variant parameters
    Public Title                          ' String
    Public Mode                           ' String
    Public TitleBar                       ' String
    Public TitleBarAddOn                  ' String
    Public LayoutStrategy                 ' URI
    Public WindowLayoutStrategy           ' URI
    Public WindowLayoutMode               ' String
    Public HierarchyLayout                ' URI
    Public SymbolOpen                     ' URI
    Public SymbolClosed                   ' URI
    Public TextScale                      ' Float as String
    Public Height                         ' Integer as String
    Public Width                          ' Integer as String
    Public InstanceContextModel           ' URI
    Public ModelContextModel              ' URI
    Public ViewStrategyModel              ' URI
    Public LanguageModel                  ' URI
    Public Workspace                      ' IMetisObjectView
    Public ObjectAspectRatio              ' Float
    Public RelationshipViewMode           ' Hierarchy | Relationship
    Public ContentInRepository

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public contextInstance                ' IMetisInstance

    ' Context variables (private)
    Private model
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance
    Private currentWorkarea              ' IMetisObjectView
    Private searchModel

    ' Types
    Private buttonType                   ' IMetisType
    Private consistsOfType               ' IMetisType
    Private titlebarType                 ' IMetisType
    Private windowType                   ' IMetisType
    Private window2Type                  ' IMetisType
    Private hasLanguageType              ' IMetisType
    Private hasInstanceContextType       ' IMetisType
    Private hasInstanceContext2Type      ' IMetisType
    Private hasModelContextType          ' IMetisType
    Private hasViewStrategyType          ' IMetisType
    Private hasSearchSpecificationType   ' IMetisType
    Private specContainerType            ' IMetisType
    Private propertyType
    Private hasPropertyType

    ' Methods
    Private addMetamodelMethod           ' IMetisMethod
    Private addPartRuleMethod            ' IMetisMethod

    ' Layout strategies
    Private workareaLayoutStrategy       ' IMetisInstance
    Private workwinLayoutStrategy        ' IMetisInstance
    Private hierarchy_layout             ' IMetisInstance

    ' Components
    Private cvwArg                       ' CVW_ArgumentValue
    Private compTitleBar                 ' CVW_Component
    Private compWorkareaWindow           ' CVW_Component
    Private window                       ' CVW_Window

    ' Others
    Private work_window
    Private WorkspaceName                ' String
    Private titleBarIndex                ' Integer
    Private workareaIndex                ' Integer
    Private sourceContainerView          ' IMetisInstanceView

'-----------------------------------------------------------
    Public Property Get component           'IMetisObject
        set component = cObject
    End Property

    Public Property Set component(obj)
        if isEnabled(obj) then
            set cObject = obj
        end if
    End Property

'-----------------------------------------------------------
    Public Property Get configObject           'IMetisObject
        set configObject = aObject
    End Property

    Public Property Set configObject(obj)
        if isEnabled(obj) then
            set aObject = obj
        end if
    End Property

'-----------------------------------------------------------
    Public Property Get WorkWindow
        set WorkWindow = work_window
    End Property

    Public Property Set WorkWindow(win)
        set work_window = win
    End Property

'-----------------------------------------------------------
    Public Property Get contentModel           'IMetisObject
        dim context

        ' Find ContentModel
        set contentModel = currentModel
        set context = new EKA_Context
        set context.currentModel        = currentModel
        set context.currentModelView    = currentModelView
        set context.currentInstance     = work_window.instance
        set context.currentInstanceView = work_window
        if isValid(context) then
            set contentModel = context.contentModel
            ContentInRepository = context.isRepository
        end if
    End Property

'-----------------------------------------------------------
    Public Property Get ContentSearchModel
        set ContentSearchModel = searchModel
    End Property

    Public Property Let ContentSearchModel(search_model)
        if isvalid(work_window) then
            searchModel = search_model
            call connectContentSearchModel(searchModel)
        end if
    End Property

'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build
        ' Set variant parameters from configuring object - if given
        Title                = cvwArg.getConfiguredValue(component, "Name")
        Mode                 = cvwArg.getConfiguredValue(component, "Mode")
        TitleBar             = cvwArg.getConfiguredValue(component, "TitleBar")
        TitleBarAddOn        = cvwArg.getConfiguredValue(component, "TitleBarAddOn")
        LayoutStrategy       = cvwArg.getConfiguredValue(component, "LayoutStrategy")
        WindowLayoutStrategy = cvwArg.getConfiguredValue(component, "WorkwinLayoutStrategy")
        WindowLayoutMode     = cvwArg.getConfiguredValue(component, "WorkwinLayoutMode")
        RelationshipViewMode = cvwArg.getConfiguredValue(component, "RelationshipViewMode")
        SymbolOpen           = cvwArg.getConfiguredValue(component, "SymbolOpen")
        SymbolClosed         = cvwArg.getConfiguredValue(component, "SymbolClosed")
        TextScale            = cvwArg.getConfiguredValue(component, "Textscale")
        Height               = cvwArg.getConfiguredValue(component, "Height")
        Width                = cvwArg.getConfiguredValue(component, "Width")
        ObjectAspectRatio    = cvwArg.getConfiguredValue(component, "ObjectAspectRatio")
        InstanceContextModel = cvwArg.getConfiguredValue(component, "InstanceContext_Model")
        ModelContextModel    = cvwArg.getConfiguredValue(component, "ModelContext_Model")
        LanguageModel        = cvwArg.getConfiguredValue(component, "Language_Model")
        ViewStrategyModel    = cvwArg.getConfiguredValue(component, "ViewStrategy_Model")
        if Len(TextScale) = 0 then
            TextScale = 1
        end if
        if Len(ObjectAspectRatio) = 0 then
            ObjectAspectRatio = -1
        end if
        set workareaLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)
        set workwinLayoutStrategy = metis.findLayoutStrategy(WindowLayoutStrategy)

        ' Find used components
        set compTitleBar       = findCVWcomponent(component, "TitleBar")
        set compWorkareaWindow = findCVWcomponent(component, "WorkareaWindow")
   End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Propagate parameters to sub-components
        call resetCVWcomponent(compTitleBar)
        call configureCVWcomponent(component, compTitleBar, true)
        call resetCVWcomponent(compWorkareaWindow)
        call configureCVWcomponent(component, compWorkareaWindow, true)
    End Sub

'-----------------------------------------------------------
    ' Do what the component is built for - return result
    Public Function execute
        dim index, noWindows
        dim clearMode, newMode, copyMode, moveMode
        dim layout_strategy

        set execute = Nothing
        ' The code
        ' Check workspace view
        if not isValid(Workspace) then
            exit function
        end if
        ' Set some flags
        newMode   = true
        clearMode = false
        copyMode  = false
        moveMode  = false
        if Mode   = "New" then
            newMode = true
        elseif Mode = "Reuse" then
            newMode = false
        elseif Mode = "ReuseAndClear" then
            clearMode = true
            newMode = false
        elseif Mode = "CopyView" then
            copyMode = true
        elseif Mode = "MoveView" then
            moveMode = true
        end if

        set currentWorkarea = currentInstanceView.parent.parent
        if newMode or not find(Title, Workspace, currentWorkarea) then
            ' Create workarea
            if window.create(Title, windowType, Workspace) then
                with window.objectView
                    on error resume next
                    set .layoutStrategy = workareaLayoutStrategy
                    .openSymbol         = SymbolOpen
                    .closedSymbol       = SymbolClosed
                    if Len(TextScale) > 0 then
                        .absTextScale   = CInt(TextScale)
                    end if
                    if Len(Height) > 0 then
                        .geometry.height = CInt(Height)
                    end if
                    if Len(Width) > 0 then
                        .geometry.width  = CInt(Width)
                    end if
                end with
                index = 1
                if Len(TitleBar) > 0 then
                    ' Create title bar
                    titlebarIndex = index
                    if isEnabled(compTitleBar) then
                        call createTitleBar(compTitleBar)
                    end if
                    index = index + 1
                end if
                ' Create work window
                workareaIndex = index
                call createWorkareaWindow(compWorkareaWindow)
                index = index + 1
            end if
        else
            workareaIndex = 2
            set work_window = window.objectView.children(workareaIndex)
            if not isEnabled(work_window) then
                workareaIndex = 1
                set work_window = window.objectView.children(workareaIndex)
            end if
        end if
        if clearMode then
            call window.clean()
        end if
        if copyMode then
            call copyViewToWorkarea()
        end if
        'call window.doParentLayout
        call doWorkspaceLayout(work_window.parent.parent)

        ' End code
        execute = true
    End Function

'-----------------------------------------------------------
    Public Function find(name, parentView, instance)              ' as Boolean
        if name = "$Current$" then
            find = window.find2(windowType, parentView, instance)
        else
            find = window.find(name, windowType, parentView)
        end if
    End Function

'-----------------------------------------------------------
    Private Sub createTitleBar(compTitleBar)
        dim TitleBarName, TemplateName, TemplateAddOn
        dim OpenSymbol, ClosedSymbol
        dim TextScale, Height
        dim TitleLayout, layout_strategy
        dim m, objectMenu, objectMenuAddOn, titleView, itemView

        ' Get variant parameter values
        TitleBarName      = cvwArg.getConfiguredValue(compTitleBar, "Name")
        TemplateName      = cvwArg.getConfiguredValue(compTitleBar, "TemplateName")
        TemplateAddOn     = cvwArg.getConfiguredValue(compTitleBar, "TemplateAddOn")
        TitleLayout       = cvwArg.getConfiguredValue(compTitleBar, "LayoutStrategy")
        OpenSymbol        = cvwArg.getConfiguredValue(compTitleBar, "SymbolOpen")
        ClosedSymbol      = cvwArg.getConfiguredValue(compTitleBar, "SymbolClosed")
        TextScale         = cvwArg.getConfiguredValue(compTitleBar, "Textscale")
        Height            = cvwArg.getConfiguredValue(compTitleBar, "Height")
        set layout_strategy = metis.findLayoutStrategy(TitleLayout)

        ' Create title bar according to configuration
        set m = getCVWmodel
        set objectMenu = metis.findInstance(TemplateName)
        if not isEnabled(objectMenu) then
            set objectMenu = m.findInstances(buttonType, "name", TemplateName)
        end if
        if Len(TemplateAddOn) > 0 then
            set objectMenuAddOn = metis.findInstance(TemplateAddOn)
            if not isEnabled(objectMenuAddOn) then
                set objectMenuAddOn = m.findInstances(buttonType, "name", TemplateAddOn)
            end if
        end if
        call window.addSubWindow("Top", TitleBarName, titlebarType)
        set titleView = window.objectView.children(titlebarIndex)
        if isValid(objectMenu) then
            set itemView = objectMenu.views(1)
            call generateTree(itemView, titleView, consistsOfType, buttonType, 0.05, 1.3)
        end if
        if isValid(objectMenuAddOn) then
            set itemView = objectMenuAddOn.views(1)
            call generateTree(itemView, titleView, consistsOfType, buttonType, 0.05, 1.3)
        end if
        with titleView
            on error resume next
            set .layoutStrategy = layout_strategy
            .openSymbol         = OpenSymbol
            .closedSymbol       = ClosedSymbol
            if Len(TextScale) > 0 then
                .absTextScale       = CInt(TextScale)
            end if
            if Len(Height) > 0 then
                .geometry.height    = CInt(Height)
            end if
        end with

    End Sub

'-----------------------------------------------------------
    Private Sub createWorkareaWindow(compWorkareaWindow)
        dim WindowName, TemplateName, TemplateAddOn
        dim OpenSymbol, ClosedSymbol
        dim TextScale, Height, Width
        dim WindowLayout, layout_strategy
        dim m

        ' Get variant parameter values
        WindowName          = cvwArg.getConfiguredValue(compWorkareaWindow, "Name")
        TemplateName        = cvwArg.getConfiguredValue(compWorkareaWindow, "TemplateName")
        TemplateAddOn        = cvwArg.getConfiguredValue(compWorkareaWindow, "TemplateAddOn")
        WindowLayout        = cvwArg.getConfiguredValue(compWorkareaWindow, "LayoutStrategy")
        HierarchyLayout     = cvwArg.getConfiguredValue(compWorkareaWindow, "TreeLayout")
        OpenSymbol          = cvwArg.getConfiguredValue(compWorkareaWindow, "SymbolOpen")
        ClosedSymbol        = cvwArg.getConfiguredValue(compWorkareaWindow, "SymbolClosed")
        TextScale           = cvwArg.getConfiguredValue(compWorkareaWindow, "Textscale")
        Height              = cvwArg.getConfiguredValue(compWorkareaWindow, "Height")
        Width               = cvwArg.getConfiguredValue(compWorkareaWindow, "Width")
        set layout_strategy  = metis.findLayoutStrategy(WindowLayout)
        set hierarchy_layout = metis.findLayoutStrategy(HierarchyLayout)

        ' Create workarea window according to configuration
        set m = getCVWmodel
        if WindowLayoutMode = "Manual" then
            call window.addSubWindow("Top", "WorkArea_["& WindowName &"]", window2Type)
            set work_window = window.objectView.children(workareaIndex)
            set currentModel.currentInstance = work_window.instance
            set currentModelView.currentInstanceView = work_window
            metis.runCommand("toggle-next-fixed-layout")
            set currentModel.currentInstance = currentInstance
            set currentModelView.currentInstanceView = currentInstanceView
        else
            call window.addSubWindow("Top", "WorkArea_["& WindowName &"]", windowType)
            set work_window = window.objectView.children(workareaIndex)
        end if
        with work_window
            on error resume next
            set .layoutStrategy = layout_strategy
            .openSymbol         = OpenSymbol
            .closedSymbol       = ClosedSymbol
            if Len(TextScale) > 0 then
                .absTextScale       = CInt(TextScale)
            end if
            if Len(Height) > 0 then
                .geometry.height = CInt(Height)
            end if
            if Len(Width) > 0 then
                .geometry.width  = CInt(Width)
            end if
        end with
        call metis.doLayout(work_window.parent)

        ' Set view strategy if given
        call connectLanguageModel()
        call connectModelContext()
        call connectInstanceContext()
        call connectViewStrategy()
    End Sub

'-----------------------------------------------------------
    Public Sub populate(instances, noLevels)
        dim obj, obj1, obj2, objView
        dim origin, target
        dim relType, type1, type2
        dim inst, workarea, wObject
        dim viewStrategies, viewStrategy
        dim instanceConts, instanceCont
        dim strategyConts, strategyCont
        dim cvwViewStrategy, cvwCircularLayout
        dim ekaInstance
        dim rel, relView, hasViewList
        dim originView, originViews, targetView, targetViews
        dim propVal
        dim done

        set wObject = work_window.instance
        set ekaInstance = new EKA_Instance
        if WindowLayoutStrategy = "akm:layout#CircularLayout1" then
            for each inst in instances
                if isEnabled(inst) then
                    if inst.isObject then
                        set cvwCircularLayout = new CVW_CircularLayout
                        call cvwCircularLayout.build
                        call cvwCircularLayout.execute(work_window, inst)
                        exit for
                    end if
                end if
            next
        else
            ' Get view strategy
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
                propVal = ekaInstance.getPropertyValue(strategyCont, "RelationshipViewMode")
                if Len(propVal) > 0 then
                    RelationshipViewMode = propVal
                end if
            end if
            ' Get instance context parameters
            set instanceConts = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
            if instanceConts.count > 0 then
                set instanceCont = instanceConts(1)
                propVal = ekaInstance.getPropertyValue(instanceCont, "ObjectAspectRatio")
                if Len(propVal) > 0 then
                    ObjectAspectRatio = CDbl(propVal)
                end if
            end if
            set hasViewList = metis.newInstanceList
            call addViewsToList(hasViewList, work_window)
            for each obj in instances
                if not obj.isRelationship then
                    if not instanceInList(obj, hasViewList) then
                        set objView = creTreeView(obj, hasViewList, work_window, cvwViewStrategy, 0, noLevels)
                    end if
                end if
            next
            for each rel in instances
                done = false
                if rel.isRelationship then
                    set origin = rel.origin
                    set originViews = currentModelView.findInstanceViews(origin)
                    set target = rel.target
                    set targetViews = currentModelView.findInstanceViews(target)
                    for each originView in originViews
                        if isInView(originView, work_window) then
                            for each targetView in targetViews
                                if isInView(targetView, work_window) then
                                    if isValid(cvwViewStrategy) then
                                        done = isHierarchyRelView(rel, originView, targetView, cvwViewStrategy)
                                    end if
                                    if not done then
                                        set relView = currentModelView.newRelationshipView(rel, originView, targetView)
                                    end if
                                end if
                            next
                        end if
                    next
                end if
            next
        end if

        ' Do the layout on work_window
        if work_window.instance.type.uri <> window2Type.uri then
            call metis.doLayout(work_window)
        end if

        ' Set layout strategy on topObject
        if isEnabled(hierarchy_layout) and isEnabled(objView) then
            set objView.layoutStrategy = hierarchy_layout
        end if
        if isEnabled(objView) then
            ' Do the layout on topObject
            call metis.doLayout(objView)
        end if
        set ekaInstance = Nothing
    End Sub

'-----------------------------------------------------------
    Private Function creTreeView(obj, hasViewList, parentView, cvwViewStrategy, level, noLevels)
        dim obj1, obj2, objView
        dim relType, type1, type2
        dim workarea, wObject
        dim strategies, strategy
        dim relDir, rels, rel, relView
        dim childInst, childInstView
        dim textScale, parentAbsScale, objAbsScale
        dim i, found
        dim rule
        dim cvwObjView
        dim objGeo, size

        if level >= noLevels then
            if noLevels > -1 then
                set creTreeView = Nothing
                exit Function
            end if
        end if

        if isEnabled(obj) then
            ' Create view of each of the top instances
            set cvwObjView = new CVW_ObjectView
            set objView = cvwObjView.create(work_window, parentView, obj, ObjectAspectRatio)
            set cvwObjView = Nothing
            if objView.isNested then
                objView.close
            end if
            if isValid(hasViewList) then
                hasViewList.addLast obj
            end if
            if isValid(cvwViewStrategy) then
                for i = 1 to cvwViewStrategy.noHierarchyRules
                    set rule = cvwViewStrategy.hierarchyRules(i)
                    if obj.type.uri = rule.parentType.uri then
                        set rels = obj.getNeighbourRelationships(rule.relDir, rule.relType)
                        for each rel in rels
                            if rule.relDir = 0 then
                                set childInst = rel.target
                            else
                                set childInst = rel.origin
                            end if
                            level = level + 1
                            if RelationshipViewMode = "Hierarchy" then
                                set childInstView = creTreeView(childInst, hasViewList, objView, cvwViewStrategy, level, noLevels)
                            elseif not instanceInList(childInst, hasViewList) then
                                set childInstView = creTreeView(childInst, hasViewList, work_window, cvwViewStrategy, level, noLevels)
                                set relView = currentModelView.newRelationshipView(rel, objView, childInstView)
                            end if
                            level = level - 1
                        next
                    end if
                next
            end if
        end if
        if objView.isNested then
            'if level = 0 then
                call objView.doLayout
            '    objView.open
            'end if
        end if
        set creTreeView = objView
    End Function

    '---------------------------------------------------------------------------------------------------
    Private Function isHierarchyRelView(rel, originView, targetView, cvwViewStrategy)
        dim rule
        dim i

        isHierarchyRelView = false
        for i = 1 to cvwViewStrategy.noHierarchyRules
            set rule = cvwViewStrategy.hierarchyRules(i)
            if rule.relType.uri = rel.type.uri then
                if rule.relDir = 0 then
                    if rel.origin.type.uri = rule.parentType.uri then
                        if rel.target.type.uri = rule.childType.uri then
                            isHierarchyRelView = true
                        end if
                    end if
                elseif rule.relDir = 1 then
                    if rel.target.type.uri = rule.parentType.uri then
                        if rel.origin.type.uri = rule.childType.uri then
                            isHierarchyRelView = true
                        end if
                    end if
                end if
            end if
        next
    End Function

   '---------------------------------------------------------------------------------------------------
    Public Sub copyViewToWorkarea()
        dim topContainer
        dim instance
        dim workwin

        if isEnabled(sourceContainerView) then
            set workwin = window.objectView.children(workareaIndex)
            set currentModelView.currentInstanceView = sourceContainerView
            Call metis.runCommand("copy")
            set currentModelView.currentInstanceView = workwin
            Call metis.runCommand("paste-structure")
            'Call metis.runCommand("paste-synchronized-view")
            'Call metis.runCommand("paste-auto-virtual-synchronized-view")
            set currentModelView.currentInstanceView = currentInstanceView
            currentModelView.clearSelection
        end if
    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Sub addViewsToList(hasViewList, parentView)
        dim child, children
        dim inst

        set children = parentView.children
        for each child in children
            if hasInstance(child) then
                set inst = child.instance
                if not instanceInList(inst, hasViewList) then
                    hasViewList.addLast inst
                end if
            end if
            call addViewsToList(hasViewList, child)
        next

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
    Private Sub connectLanguageModel()
        dim langModel
        dim obj, rel
        dim langObjView

        if Len(LanguageModel) > 0 then
            set langModel = metis.findInstance(LanguageModel)
            if isEnabled(langModel) then
                set langObjView = langModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to language model specification container
                    set obj = work_window.instance
                    set rel = currentModel.newRelationship(hasLanguageType, obj, langModel)
                    ' Create metamodel and connect to model
                    if isEnabled(addMetamodelMethod) then
                        set currentModel.currentInstance = langModel
                        set currentModelView.currentInstanceView = langObjView
                        call currentModel.runMethodOnInst(addMetamodelMethod, langModel)
                        set currentModel.currentInstance = currentInstance
                        set currentModelView.currentInstanceView = currentInstanceView
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectModelContext()
        dim specModel
        dim obj, rel
        dim specObjView
        dim context

        if Len(ModelContextModel) > 0 then
            set specModel = metis.findInstance(ModelContextModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to model context specification container
                    set obj = work_window.instance
                    set rel = currentModel.newRelationship(hasModelContextType, obj, specModel)
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectInstanceContext()
        dim specModel
        dim specObjView
        dim cvwContentSpec
        dim contextObj, obj, rel
        dim instances
        dim cvwInstance
        dim instName
        dim workarea, titleObj
        dim indx

        if Len(InstanceContextModel) > 0 then
            set specModel = metis.findInstance(InstanceContextModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to instanceContext specification container
                    set obj = work_window.instance
                    set rel = currentModel.newRelationship(hasInstanceContextType, obj, specModel)
                    ' Connect rel from window to actual context instance
                    set cvwContentSpec = new CVW_ContentSpecification
                    set cvwContentSpec.currentModel     = currentModel
                    set cvwContentSpec.currentModelView = currentModelView
                    set cvwContentSpec.contentModel     = contentModel
                    set cvwContentSpec.contextInstance  = contextInstance
                    cvwContentSpec.SearchMode           = "SelectOneFromList"
                    cvwContentSpec.PathMode             = "NoPath"
                    cvwContentSpec.SpecificationModel   = InstanceContextModel
                    ' Find actual context instance
                    set instances = cvwContentSpec.execute
                    if instances.count > 0 then
                        set contextObj = instances(1)
                        set rel = currentModel.newRelationship(hasInstanceContext2Type, obj, contextObj)
                        set cvwInstance = new CVW_Instance
                        set cvwInstance.currentInstance = work_window.instance
                        set cvwInstance.currentInstanceView = work_window
                        instName = cvwInstance.getInstanceName
                        set cvwInstance = Nothing
                        if Len(instName) > 0 then
                            set workarea = work_window.parent
                            indx = workarea.children.count
                            if indx > 1 then
                                set titleObj = workarea.children(1).instance
                                titleObj.name = instName
                                titleObj.title = instName
                            end if
                        end if
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectViewStrategy()
        dim specModel
        dim obj, rel
        dim specObjView
        dim strategyCont, strategyConts
        dim cvwViewStrategy
        dim ekaInstance

        if Len(ViewStrategyModel) > 0 then
            set specModel = metis.findInstance(ViewStrategyModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to viewstrategy specification container
                    set obj = work_window.instance
                    set rel = currentModel.newRelationship(hasViewStrategyType, obj, specModel)
                    ' Check for properties
                    set cvwViewStrategy = new CVW_ViewStrategy
                    call cvwViewStrategy.build(strategyCont)
                    set ekaInstance = new EKA_Instance
                    WindowLayoutStrategy = ekaInstance.getPropertyValue(specModel, "WorkwinLayoutStrategy")
                    if Len(WindowLayoutStrategy) > 0 then
                        set workwinLayoutStrategy = metis.findLayoutStrategy(WindowLayoutStrategy)
                        set work_window.layoutStrategy = workwinLayoutStrategy
                    end if
                    set ekaInstance = Nothing
                    set cvwViewStrategy = Nothing
                    ' Create metamodel and connect to model
                    if isEnabled(addPartRuleMethod) then
                        set currentModel.currentInstance = specModel
                        set currentModelView.currentInstanceView = specObjView
                        call currentModel.runMethodOnInst(addPartRuleMethod, specModel)
                        set currentModel.currentInstance = currentInstance
                        set currentModelView.currentInstanceView = currentInstanceView
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectContentSearchModel(searchModel)
        dim specModel
        dim wObject, rel
        dim specObjView
        dim searchConts
        dim context

        if Len(searchModel) > 0 then
            set specModel = metis.findInstance(searchModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to model context specification container
                    set wObject = work_window.instance
                    set searchConts = wObject.getNeighbourObjects(0, hasSearchSpecificationType, specContainerType)
                    if searchConts.count = 0 then
                        set rel = currentModel.newRelationship(hasSearchSpecificationType, wObject, specModel)
                    end if
                end if
            end if
        end if
    End Sub

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
    Private Function getTextScaleFactor(instView, parentView)
        dim parentTs, instTs

        parentTs = parentView.textscale
        if parentView.isNested then
            getTextScaleFactor = parentTs * nestedTextFactor
        else
            getTextScaleFactor = parentTs * treeTextFactor
        end if

    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set contextInstance = Nothing
        ' Assume started on button
        set currentWorkarea = currentInstanceView.parent.parent

        set cObject   = currentInstance
        set aObject   = currentInstance
        ' Types
        set titlebarType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set windowType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set window2Type     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea2_UUID")
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set hasLanguageType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification2_UUID")
        set hasViewStrategyType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        set hasModelContextType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasModelContext_UUID")
        set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
        set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set specContainerType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasSearchSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasSearchSpecification_UUID")
        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        ' Methods
        set addMetamodelMethod  = metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/spec_methods.kmd#addVirtualMetamodel")
        set addPartRuleMethod   = metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/spec_methods.kmd#addPartRules")
        ' Arguments
        ObjectAspectRatio    = -1
        WindowLayoutStrategy = ""
        RelationshipViewMode = "Hierarchy"
        ContentInRepository  = false
        set cvwArg    = new CVW_ArgumentValue
        set Workspace = Nothing
        set window    = new CVW_Window
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class

