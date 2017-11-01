option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Workarea

    ' Variant parameters
    Public Title                          ' String
    Public Mode                           ' String
    Public TitleBar                       ' String
    Public LayoutStrategy                 ' URI
    Public SymbolOpen                     ' URI
    Public SymbolClosed                   ' URI
    Public TextScale                      ' Float
    Public Workspace                      ' IMetisObjectView

    ' Context variables
    Private model
    Private modelView
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private buttonType                   ' IMetisType
    Private consistsOfType               ' IMetisType
    Private titlebarType                 ' IMetisType
    Private windowType                   ' IMetisType
    Private hasViewStrategyType          ' IMetisType
    Private specContainerType            ' IMetisType

    ' Layout strategies
    Private workareaLayoutStrategy       ' IMetisInstance
    Private hierarchyLayout              ' IMetisInstance

    ' Components
    Private cvwArg                       ' CVW_ArgumentValue
    Private compTitleBar                 ' CVW_Component
    Private compWorkareaWindow           ' CVW_Component
    Private window                       ' CVW_Window

    ' Others
    Private workwindow
    Private WorkspaceName                ' String
    Private titleBarIndex                ' Integer
    Private workareaIndex                ' Integer

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
    ' Build internal structures
    Public Sub build

        ' Set variant parameters from configuring object - if given
        Title             = cvwArg.getConfiguredValue(component, "Name")
        Mode              = cvwArg.getConfiguredValue(component, "Mode")
        TitleBar          = cvwArg.getConfiguredValue(component, "TitleBar")
        LayoutStrategy    = cvwArg.getConfiguredValue(component, "LayoutStrategy")
        SymbolOpen        = cvwArg.getConfiguredValue(component, "SymbolOpen")
        SymbolClosed      = cvwArg.getConfiguredValue(component, "SymbolClosed")
        TextScale         = cvwArg.getConfiguredValue(component, "Textscale")
        if Len(TextScale) = 0 then
            TextScale = 1
        end if
        set workareaLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)

        ' Find used components
        set compTitleBar       = findCVWcomponent(component, "TitleBar")
        set compWorkareaWindow = findCVWcomponent(component, "WorkareaWindow")

   End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Propagate parameters to sub-components
        call resetCVWcomponent(compTitleBar)
        call configureCVWcomponent(component, compTitleBar)
        call resetCVWcomponent(compWorkareaWindow)
        call configureCVWcomponent(component, compWorkareaWindow)
    End Sub

'-----------------------------------------------------------
    ' Do what the component is built for - return result
    Public Function execute
        dim index

        set execute = Nothing
        ' The code
        ' Check workspace view
        if not isEnabled(Workspace) then
            exit function
        end if

        if Mode = "New" or not find(Title, Workspace) then
            ' Create workarea
            if window.create(Title, windowType, Workspace) then
                with window.objectView
                    on error resume next
                    set .layoutStrategy = workareaLayoutStrategy
                    .openSymbol         = SymbolOpen
                    .closedSymbol       = SymbolClosed
                    .absTextScale       = CInt(TextScale)
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
        end if
        call window.doParentLayout
        ' End code
        execute = true
    End Function

'-----------------------------------------------------------
    Public Function find(name, parentView)              ' as Boolean
        find = window.find(name, windowType, parentView)
    End Function

'-----------------------------------------------------------
    Private Sub createTitleBar(compTitleBar)
        dim TitleBarName, TemplateName, LayoutStrategyUri
        dim OpenSymbol, ClosedSymbol
        dim TextScale, Height
        dim layoutStrategy
        dim m, objectMenu, titleView, itemView

        ' Get variant parameter values
        TitleBarName      = cvwArg.getConfiguredValue(compTitleBar, "Name")
        TemplateName      = cvwArg.getConfiguredValue(compTitleBar, "TemplateName")
        LayoutStrategyUri = cvwArg.getConfiguredValue(compTitleBar, "LayoutStrategy")
        OpenSymbol        = cvwArg.getConfiguredValue(compTitleBar, "SymbolOpen")
        ClosedSymbol      = cvwArg.getConfiguredValue(compTitleBar, "SymbolClosed")
        TextScale         = cvwArg.getConfiguredValue(compTitleBar, "Textscale")
        Height            = cvwArg.getConfiguredValue(compTitleBar, "Height")
        set layoutStrategy  = metis.findLayoutStrategy(LayoutStrategyUri)

        ' Create title bar according to configuration
        set m = getCVWmodel
        call window.addSubWindow("Top", TitleBarName, titlebarType)
        set titleView = window.objectView.children(titlebarIndex)
        set objectMenu = m.findInstances(buttonType, "name", TemplateName)
        if isValid(objectMenu) then
            set itemView = objectMenu(1).views(1)
            call generateTree(itemView, titleView, consistsOfType, buttonType, 0.05, 1.3)
        end if
        with titleView
            on error resume next
            set .layoutStrategy = layoutStrategy
            .openSymbol         = OpenSymbol
            .closedSymbol       = ClosedSymbol
            .absTextScale       = CInt(TextScale)
            .geometry.height    = CInt(Height)
        end with

    End Sub

'-----------------------------------------------------------
    Private Sub createWorkareaWindow(compWorkareaWindow)
        dim WindowName, TemplateName, LayoutStrategyUri, HierarchyLayoutUri
        dim OpenSymbol, ClosedSymbol
        dim TextScale, Height
        dim layoutStrategy
        dim m

        ' Get variant parameter values
        WindowName          = cvwArg.getConfiguredValue(compWorkareaWindow, "Name")
        TemplateName        = cvwArg.getConfiguredValue(compWorkareaWindow, "TemplateName")
        LayoutStrategyUri   = cvwArg.getConfiguredValue(compWorkareaWindow, "LayoutStrategy")
        HierarchyLayoutUri  = cvwArg.getConfiguredValue(compWorkareaWindow, "HierarchyLayout")
        OpenSymbol          = cvwArg.getConfiguredValue(compWorkareaWindow, "SymbolOpen")
        ClosedSymbol        = cvwArg.getConfiguredValue(compWorkareaWindow, "SymbolClosed")
        TextScale           = cvwArg.getConfiguredValue(compWorkareaWindow, "Textscale")
        set layoutStrategy  = metis.findLayoutStrategy(LayoutStrategyUri)
        set hierarchyLayout = metis.findLayoutStrategy(HierarchyLayoutUri)

        ' Create workarea window according to configuration
        set m = getCVWmodel
        call window.addSubWindow("Top", "WorkArea_["& WindowName &"]", windowType)
        set workwindow = window.objectView.children(workareaIndex)
        with workwindow
            on error resume next
            set .layoutStrategy = layoutStrategy
            .openSymbol         = OpenSymbol
            .closedSymbol       = ClosedSymbol
            .absTextScale       = CInt(TextScale)
        end with
    End Sub

'-----------------------------------------------------------
    Public Sub populate(instances)
        dim obj, obj1, obj2, objView
        dim relType, type1, type2
        dim workarea, wObject
        dim viewStrategies, viewStrategy
        dim strategyConts, strategyCont
        dim cvwViewStrategy

        set wObject = workwindow.instance
        if layoutStrategy.uri = "akm:layout#CircularLayout1" then
            for each inst in instances
                if isEnabled(inst) then
                    if inst.isObject then
                        set cvwCircularLayout = new CVW_CircularLayout
                        call cvwCircularLayout.build
                        call cvwCircularLayout.execute(workwindow, inst)
                        exit for
                    end if
                end if
            next
        else
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
            end if
            for each obj in instances
                set objView = creTreeView(obj, true, Nothing, workwindow, cvwViewStrategy)
            next
        end if
    End Sub

'-----------------------------------------------------------
    Private Function creTreeView(obj, isTop, instances, parentView, cvwViewStrategy)
        dim obj1, obj2, objView
        dim relType, type1, type2
        dim workarea, wObject
        dim strategies, strategy
        dim relDir, rels, rel
        dim childInst, childInstView
        dim textScale, parentAbsScale, objAbsScale
        dim found

        if isEnabled(obj) then
            ' Create view of each of the top instances
            set objView = parentView.newObjectView(obj)
            ' Handle textscale
            if isTop then
                objView.textScale = 0.5
                if isEnabled(hierarchyLayout) then
                    set objView.layoutStrategy = hierarchyLayout
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

            for i = 1 to noHierarchyRules
                set rule = hierarchyRules(i)
                if obj.type.uri = rule.parentType.uri then
                    set rels = obj.getNeighbourRelationships(rule.relDir, rule.relType)
                    for each rel in rels
                        if rule.relDir = 0 then
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
    Public Sub connectViewStrategy(vsComponent)
        dim specModelUri, specModel
        dim obj, rel

        if isEnabled(vsComponent) then
            ' Find view strategy specification, if given
            specModelUri = cvwArg.getArgValue(vsComponent, aObject, "ViewStrategy_Model")
            if Len(specModelUri) > 0 then
                set specModel = metis.findInstance(specModelUri)
                if isEnabled(specModel) then
                    ' Connect rel from workwindow to viewstrategy specification container
                    set workwindow = getWorkWindow
                    set obj = workwindow.instance
                    set rel = model.newRelationship(hasViewStrategyType, obj, specModel)
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Function getWorkWindow
        if Len(TitleBar) > 0 then
            set getWorkWindow = window.objectView.children(2)
        else
            set getWorkWindow = window.objectView.children(1)
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set cObject   = model.currentInstance
        set aObject   = model.currentInstance
        ' Types
        set titlebarType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set windowType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        ' Arguments
        set cvwArg    = new CVW_ArgumentValue
        set Workspace = Nothing
        set window    = new CVW_Window

    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


