option explicit

Class EKA_Type

    Public name
    Public label
    Public baseType
    Public file
    Public model
    Public typeMethod
    
    Private mode
    Private virtualType

'-----------------------------------------------------------
    Public Function newVirtualType    ' as Boolean
        newVirtualType = false
    End Function

'-----------------------------------------------------------
    Public Sub extendType(metaObject)
        if isEnabled(model) then
            model.runMethodOnInst(typeMethod, metaObject) ' Add argument to method
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set typeMethod = metis.findMethod("EkaTypeMethod")

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class


