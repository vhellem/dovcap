option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_MenuAction

    ' Variant parameters
    Public Title
    Public ParameterName                 ' String
    Public noViewLevels
    Public noNeighbourLevels
    Public TreeTextScale                  ' Float as String
    Public NestedTextScaleTop             ' Float as String
    Public NestedTextScale                ' Float as String
    Public applyFilter                   ' Boolean

    ' Context variables
    Public  currentModel
    Public  currentModelView
    Public  currentInstance
    Public  currentInstanceView
    Public  contextInstance

    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance
    Private work_area

    ' Types
    Private actionType                   ' IMetisType
    Private componentType                ' IMetisType
    Private isType
    Private consistsOfType               ' IMetisType
    Private usesType                     ' IMetisType
    Private anyObjectType
    Private isInstanceType

    ' Others
    Private cvwArg                       ' CVW_ArgumentValue
    Private kind                         ' String
    Private MatrixLayout1                ' String
    Private MatrixLayout2                ' String

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
    Public Property Get workarea               'IMetisObject
        set workarea = Nothing
        if isValid(work_area) then
            set workarea = work_area
        end if
    End Property
'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build
        kind = configObject.getNamedStringValue("kind")
   End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Only relevant if this component uses other components
    End Sub

'-----------------------------------------------------------
    ' Do what the component is built for - return result
    Public Function execute
        dim action, actions
        dim comp, components
        'dim contextInstance
        dim instances, objects
        dim workspace, workspaceWindow
        dim workWindow, wObject
        dim layoutStrategy
        dim contentSpec
        dim child, geo
        dim indx, wa, win
        dim cvwContentSpec, cvwAction
        dim i

        set execute = Nothing
        set workspace = Nothing
        ' The code
        if kind = "Menu" then
            ' Find actions
            set actions = configObject.getNeighbourObjects(0, consistsOfType, actionType)
            for each action in actions
                if isEnabled(action) then
                    set cvwAction = new CVW_MenuAction
                    cvwAction.noNeighbourLevels = noNeighbourLevels
                    set cvwAction.configObject = action
                    call cvwAction.build
                    cvwAction.applyFilter = applyFilter
                    set workspace = cvwAction.execute
                end if
            next
        elseif kind = "Action" then
            set components = metis.newInstanceList
            set components = findComponents(configObject, components)
            for each comp in components
                if isEnabled(comp) then
                    if comp.name = "Workspace" then
                        set workspace = execWorkspace(comp)
                        set workspaceWindow = workspace.WorkspaceWindow
                        exit for
                    end if
                end if
            next
            for each comp in components
                if isEnabled(comp) then
                    if comp.name = "Workarea" then
                        set work_area = execWorkarea(comp, workspaceWindow)
                        set workWindow = work_area.WorkWindow
                        set wObject = workWindow.instance
                        if isEnabled(wObject) then
                            set objects = wObject.getNeighbourObjects(0, isInstanceType, anyObjectType)
                            if isValid(objects) then
                                if objects.count > 0 then
                                    set contextInstance = objects(1)
                                end if
                            end if
                        end if
                        exit for
                    end if
                end if
            next
            for each comp in components
                if isEnabled(comp) then
                    if comp.name = "ContentSpecification" then
                        set contentSpec = comp
                        set instances = Nothing
                        set cvwContentSpec = execContentSpecification(contentSpec, work_area.ContentModel, work_area.ContentInRepository, contextInstance, instances)
                        exit for
                    end if
                end if
            next
            if isValid(work_area) and isValid(cvwContentSpec) then
                work_area.ContentSearchModel = cvwContentSpec.SpecificationModel
                if isValid(instances) then
                    ' Textscale handling
                    if TreeTextScale > 0 then work_area.TreeTextScale = TreeTextScale
                    if NestedTextScale > 0 then work_area.NestedTextScale = NestedTextScale
                    if NestedTextScaleTop > 0 then work_area.NestedTextScaleTop = NestedTextScaleTop
                    ' Copy filter rules
                    call work_area.setFilterRules(cvwContentSpec.filterRules, cvwContentSpec.noFilterRules)
                    ' Populate work_area
                    call work_area.populate(instances, noViewLevels)
                end if
            end if
            if isValid(workspace) then
                if workspace.LayoutStrategy = "akm:layout#AutoMatrix" then
                    if workspaceWindow.children.count <= 2 then
                        set layoutStrategy = metis.findLayoutStrategy(MatrixLayout1)
                    else
                        set layoutStrategy = metis.findLayoutStrategy(MatrixLayout2)
                    end if
                    set workspaceWindow.layoutStrategy = layoutStrategy
                end if
                ' Hack: Move the windows a little to trigger the aoutolayout
                for each wa in workspaceWindow.children
                    indx = wa.children.count
                    set win = wa.children(indx)
                    if isValid(win) then
                        set geo = win.geometry
                        geo.x = geo.x + 1
                        set win.geometry = geo
                    end if
                next
            end if
        end if
        set components = Nothing
        set execute = workspace
    End Function

'-----------------------------------------------------------
    Private Function findComponents(inst, components)
        dim comp, comps, parents

        set findComponents = Nothing
        Do
            set comps = inst.getNeighbourObjects(0, usesType, componentType)
            if comps.count > 0 then
                for each comp in comps
                    components.addLast comp
                next
            end if
            set parents = inst.getNeighbourObjects(0, isType, actionType)
            if isValid(parents) then
                for each inst in parents
                    set comps = findComponents(inst, components)
                    for each comp in comps
                        if not instanceInList(comp, comps) then
                            components.addLast comp
                        end if
                    next
                next
            end if
            exit do
        Loop
        set findComponents = components
    End Function

'-----------------------------------------------------------
    Private Function execWorkarea(comp, workspace)
        dim cvwWorkarea, cvwWorkspace

        set execWorkarea = Nothing
        ' Configure workarea
        call resetCVWcomponent(comp)
        call configureCVWcomponent(configObject, comp, false)
        ' Build and execute
        set cvwWorkarea = new CVW_Workarea
        set cvwWorkarea.currentModel = currentModel
        set cvwWorkarea.currentModelView = currentModelView
        set cvwWorkarea.currentInstance = currentInstance
        set cvwWorkarea.currentInstanceView = currentInstanceView
        set cvwWorkarea.contextInstance = contextInstance
        set cvwWorkarea.component = comp
        set cvwWorkarea.configObject = configObject
        if not isValid(workspace) then
            set cvwWorkspace = new CVW_Workspace
            set workspace = cvwWorkspace.execute             ' Execute methods dependent on configuration
        end if
        set cvwWorkarea.workspace = workspace
        if applyFilter then
            cvwWorkarea.applyFilter = true
        end if
        call cvwWorkarea.build                          ' Build internal structures
        call cvwWorkarea.configure
        call cvwWorkarea.execute                        ' Execute: Builds workarea (as an empty window w titlebar)

        set execWorkarea = cvwWorkarea
    End Function

'-----------------------------------------------------------
    Private Function execWorkspace(comp)
        dim workspace, cvwWorkspace

        set execWorkspace = Nothing
        ' Configure workspace
        call resetCVWcomponent(comp)
        call configureCVWcomponent(configObject, comp, false)
        ' Build and execute
        set cvwWorkspace = new CVW_Workspace
        set cvwWorkspace.component = comp
        set cvwWorkspace.configObject = configObject
        call cvwWorkspace.build                          ' Build internal structures
        set workspace = cvwWorkspace.execute             ' Execute methods dependent on configuration
        if isValid(workspace) then
            set execWorkspace = cvwWorkspace
        end if
    End Function

'-----------------------------------------------------------
    Private Function execContentSpecification(comp, contentModel, contentInRepository, contextInstance, instances)
        dim cvwContentSpec

        ' Configure content specification
        set execContentSpecification = Nothing
        call resetCVWcomponent(component)
        call configureCVWcomponent(configObject, comp, false)
        ' Build and execute
        set cvwContentSpec = new CVW_ContentSpecification
        set cvwContentSpec.currentModel     = currentModel
        set cvwContentSpec.currentModelView = currentModelView
        set cvwContentSpec.component    = comp
        set cvwContentSpec.configObject = configObject
        set cvwContentSpec.contentModel = contentModel
        cvwContentSpec.RepositoryConnection = contentInRepository
        cvwContentSpec.PathMode = "Path"
        cvwContentSpec.noLevels = noNeighbourLevels
        if applyFilter then
            cvwContentSpec.applyFilter = true
        end if
        call cvwContentSpec.build                          ' Build internal structures
        set instances = cvwContentSpec.execute             ' Execute methods dependent on configuration
        set execContentSpecification = cvwContentSpec
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set contextInstance = Nothing
        set cObject   = currentInstance
        set aObject   = currentInstance
        set cvwArg    = new CVW_ArgumentValue
        set work_area = Nothing

        set actionType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set componentType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")
        set isType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set usesType        = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent2_UUID")
        set anyObjectType   = metis.findType("metis:stdtypes#oid1")
        set isInstanceType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

        MatrixLayout1 = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#Layout_CVW:ContainerMatrixHorizontal"
        MatrixLayout2 = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#Layout_CVW:ContainerLayout"

        noViewLevels = -1
        noNeighbourLevels = 2
        TreeTextScale = -1
        NestedTextScale = -1
        NestedTextScaleTop = -1
        applyFilter          = false

    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


