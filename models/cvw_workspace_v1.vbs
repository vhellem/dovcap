option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Workspace


    ' Variant parameters
    Public Title                        ' String
    Public ClearMode                    ' String
    Public LayoutStrategy               ' String
    Public SymbolOpen                   ' String
    Public SymbolClosed                 ' String
    Public ViewStyle                    ' String
    Public MetamodelMethod              ' String
    Public DClickMethod                 ' String

    ' Context variables
    Private model
    Private modelView
    Private cObject
    Private aObject

    ' Types
    Private windowType                   ' IMetisType

    ' Layout strategies
    Private workspaceLayoutStrategy     ' IMetisInstance

    ' Others
    Private cvwArg                      ' CVW_ArgumentValue
    Private window                      ' CVW_Window

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
        Title               = cvwArg.getArgValue(component, configObject, "Name")
        Viewstyle           = cvwArg.getArgValue(component, configObject, "Viewstyle")
        ClearMode           = cvwArg.getArgValue(component, configObject, "ClearMode")
        LayoutStrategy      = cvwArg.getArgValue(component, configObject, "LayoutStrategy")
        SymbolOpen          = cvwArg.getArgValue(component, configObject, "SymbolOpen")
        SymbolClosed        = cvwArg.getArgValue(component, configObject, "SymbolClosed")
        MetamodelMethod     = cvwArg.getArgValue(component, configObject, "MetamodelMethod")
        DClickMethod        = cvwArg.getArgValue(component, configObject, "DClickMethod")
        ' Set default values
        if Len(Title) = 0 then Title = "CVW_Workspace"
        ' Set argument dependent values
        set workspaceLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)
    End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Only relevant if CVW_Workspace uses other components
    End Sub

'-----------------------------------------------------------
    Public Function execute             ' Return workspace objectview
        dim m, parentView
        dim method, strategy

        set execute = Nothing
        ' Find workspace
        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", Title)
        if not isEnabled(parentView) then
            exit function
        end if

        if ClearMode = "Clear" then
            call clearWorkspace
        end if
        if isEnabled(workspaceLayoutStrategy) then
            set parentView.layoutStrategy = workspaceLayoutStrategy
        end if
        if Len(Viewstyle) > 0 then
            call modelView.setViewStyle(Viewstyle)
        end if
        if Len(SymbolOpen) > 0 then
            parentView.openSymbol = SymbolOpen
        end if
        if Len(SymbolClosed) > 0 then
            parentView.closedSymbol = SymbolClosed
        end if
        if Len(MetamodelMethod) > 0 then
            set method = metis.findMethod(MetamodelMethod)
            if isEnabled(method) then
                model.runMethod(method)
            end if
        end if
        if Len(DClickMethod) > 0 then
            set method = metis.findMethod(DClickMethod)
            if isEnabled(method) then
                model.runMethod(method)
            end if
        end if
        set execute = parentView

    End Function

'-----------------------------------------------------------
    Private Sub clearWorkspace
        dim m, parentView
        dim childView, children

        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", Title)
        if not isEnabled(parentView) then
            exit sub
        end if
        set children = parentView.children
        for each childView in children
            modelView.deleteObjectView(childView)
        next
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set cObject         = model.currentInstance
        set aObject         = model.currentInstance
        set windowType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        ' CVW objects
        set window          = new CVW_Window
        set cvwArg          = new CVW_ArgumentValue
        ' Read variant parameters from component
        Title               = cvwArg.getArgumentValue(cObject, "Name")
        Viewstyle           = cvwArg.getArgumentValue(cObject, "Viewstyle")
        ClearMode           = cvwArg.getArgumentValue(cObject, "ClearMode")
        LayoutStrategy      = cvwArg.getArgumentValue(cObject, "LayoutStrategy")
        SymbolOpen          = cvwArg.getArgumentValue(cObject, "SymbolOpen")
        SymbolClosed        = cvwArg.getArgumentValue(cObject, "SymbolClosed")
        MetamodelMethod     = cvwArg.getArgumentValue(cObject, "MetamodelMethod")
        DClickMethod        = cvwArg.getArgumentValue(cObject, "DClickMethod")
        ' Set default values
        if Len(Title) = 0 then Title = "CVW_Workspace"
        ' Set argument dependent values
        set workspaceLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
        set window = Nothing
        set cvwArg = Nothing
    End Sub

End Class

