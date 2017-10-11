option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_MenuAction

    ' Variant parameters
    Public Title
    Public ParameterName                 ' String

    ' Context variables
    Public  currentModel
    Public  currentModelView
    Public currentInstance
    Public currentInstanceView
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private actionType                   ' IMetisType
    Private componentType                ' IMetisType
    Private consistsOfType               ' IMetisType
    Private usesType                     ' IMetisType

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
        dim instances
        dim workarea, workspace
        dim workspaceWindow
        dim layoutStrategy
        dim contentSpec
        dim child, geo
        dim indx, wa, win

        set execute = Nothing
        set workspace = Nothing
        ' The code
        if kind = "Menu" then
            ' Find actions
            set actions = configObject.getNeighbourObjects(0, consistsOfType, actionType)
            for each action in actions
                if isEnabled(action) then
                    set cvwAction = new CVW_MenuAction
                    set cvwAction.configObject = action
                    call cvwAction.build
                    set workspace = cvwAction.execute
                end if
            next
        elseif kind = "Action" then
            set instances = Nothing
            set components = configObject.getNeighbourObjects(0, usesType, componentType)
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
                        set workarea = execWorkarea(comp, workspaceWindow)
                        exit for
                    end if
                end if
            next
            for each comp in components
                if isEnabled(comp) then
                    if comp.name = "ContentSpecification" then
                        set contentSpec = comp
                        set instances = execContentSpecification(contentSpec, workarea.contentModel)
                        exit for
                    end if
                end if
            next
            if isValid(workarea) and isValid(instances) then
                call workarea.populate(instances, contentSpec)
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
        set execute = workspace
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
        set cvwWorkarea.component = comp
        set cvwWorkarea.configObject = configObject
        if not isValid(workspace) then
            set cvwWorkspace = new CVW_Workspace
            set workspace = cvwWorkspace.execute             ' Execute methods dependent on configuration
        end if
        set cvwWorkarea.workspace = workspace
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
    Private Function execContentSpecification(comp, contentModel)
        dim instances
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
        call cvwContentSpec.build                          ' Build internal structures
        set instances = cvwContentSpec.execute             ' Execute methods dependent on configuration
        if isValid(instances) then
            if instances.count > 0 then
                set execContentSpecification = instances
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set cObject   = currentInstance
        set aObject   = currentInstance
        set cvwArg    = new CVW_ArgumentValue

        set actionType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set componentType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set usesType        = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent2_UUID")

        MatrixLayout1 = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#Layout_CVW:ContainerMatrixHorizontal"
        MatrixLayout2 = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#Layout_CVW:ContainerLayout"

    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


