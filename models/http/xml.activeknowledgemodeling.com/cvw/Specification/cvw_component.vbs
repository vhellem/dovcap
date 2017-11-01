option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_SomeComponent

    ' Variant parameters
    Public Title
    Public ParameterName                 ' String

    ' Context variables
    Private model
    Private modelView
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private someType                     ' IMetisType

    ' Others
    Private cvwArg                       ' CVW_ArgumentValue

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
        dim Something

        set execute = Nothing
        ' The code
        set execute = Something
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set cObject   = model.currentInstance
        set aObject   = model.currentInstance
        set cvwArg    = new CVW_ArgumentValue
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


