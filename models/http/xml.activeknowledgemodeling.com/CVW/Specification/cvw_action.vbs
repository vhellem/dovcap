option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_MenuAction

    ' Variant parameters
    Public Title
    Public ParameterName                 ' String

    ' Context variables
    Private model
    Private modelView
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
       dim parameterValue

        ' Find configuring parameter values
        parameterValue = cvwArg.getArgValue(component, configObject, ParameterName)

        ' Build structure

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
        dim component, components
        dim instances
        dim workarea, workspace

        execute = false
        ' The code
        if kind = "Menu" then
            ' Find actions
            set actions = cObject.getNeighbourRelationships(0, consistsOfType, actionType)
            for each action in actions
                set cvwAction = new CVW_MenuAction
                cvwAction.execute
            next
        elseif kind = "Action" then
            set instances = Nothing
            set components = cObject.getNeighbourObjects(0, usesType, componentType)
            for each component in components
                if isEnabled(component) then
                    if component.name = "ContentSpecification" then
                        set instances = execContentSpecification(component)
                    elseif component.name = "Workspace" then
                        set workspace = execWorkspace(component)
                    elseif component.name = "Workarea" then
                        set workarea = execWorkarea(component, workspace)
                    end if
                    if isValid(workarea) and isValid(instances) then
                        call workarea.populate(instances)
                    end if
                end if
            next
        end if

        execute = true
    End Function

'-----------------------------------------------------------
    Private Function execWorkarea(component, workspace)
        dim cvwWorkarea

        set execWorkarea = Nothing
        ' Configure workarea
        call resetCVWcomponent(component)
        call configureCVWcomponent(aObject, component)
        ' Build and execute
        set cvwWorkarea = new CVW_Workarea
        set cvwWorkarea.component = component
        set cvwWorkarea.configObject = aObject
        set cvwWorkarea.workspace = workspace
        call cvwWorkarea.build                          ' Build internal structures
        call cvwWorkarea.configure
        call cvwWorkarea.execute                        ' Execute: Builds workarea (as an empty window w titlebar)
        
        set execWorkarea = cvwWorkarea
    End Function

'-----------------------------------------------------------
    Private Function execWorkspace(component)
        dim workspace, cvwWorkspace

        set execWorkspace = Nothing
        ' Configure workspace
        call resetCVWcomponent(component)
        call configureCVWcomponent(aObject, component)
        ' Build and execute
        set cvwWorkspace = new CVW_Workspace
        set cvwWorkspace.component = component
        set cvwWorkspace.configObject = aObject
        call cvwWorkspace.build                          ' Build internal structures
        set workspace = cvwWorkspace.execute             ' Execute methods dependent on configuration
        if isValid(workspace) then
            set execWorkspace = workspace
        end if
    End Function

'-----------------------------------------------------------
    Private Function execContentSpecification(component)
        dim instances
        dim cvwContentSpec

        ' Configure content specification
        set execContentSpecification = Nothing
        call resetCVWcomponent(component)
        call configureCVWcomponent(cObject, component)
        ' Build and execute
        set cvwContentSpec = new CVW_ContentSpecification
        set cvwContentSpec.component = component
        set cvwContentSpec.configObject = cObject
        call cvwContentSpec.build                          ' Build internal structures
        set instances = cvwContentSpec.execute             ' Execute methods dependent on configuration
        if instances.count > 0 then
            set execContentSpecification = instances
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set cObject   = model.currentInstance
        set aObject   = model.currentInstance
        set cvwArg    = new CVW_ArgumentValue
        kind = cObject.getNamedStringValue("kind")

        set actionType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set componentType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set usesType        = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent2_UUID")

    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


