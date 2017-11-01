option explicit

Function ekaGetPropertyLabel
    dim ekaProp

    ekaGetPropertyLabel = ""
    set ekaProp = new EKA_Property
    set ekaProp.metisObject = metis.currentModel.currentInstance
    ekaGetPropertyLabel = ekaProp.Label

End Function

Function ekaGetPropertyIcon
    dim ekaProp
stop
    ekaGetPropertyIcon = ""
    set ekaProp = new EKA_Property
    set ekaProp.metisObject = metis.currentModel.currentInstance
    ekaGetPropertyIcon = ekaProp.getIcon

End Function

'-----------------------------------------------------------
'-----------------------------------------------------------
Class EKA_Property

    Public metisObject

    Private IsType
    Private PropertyType
    Private PropertyIcon
    Private ValueIcon
    Private PropertyAndValueIcon
    Private types_ok
    Private hasName
    Private hasValue

'-----------------------------------------------------------
    Public Property Let Name(strName)
        if isEnabled(metisObject) then
            call metisObject.setNamedStringValue("name", strName)
        end if
    End Property

    Public Property Get Name
        if isEnabled(metisObject) then
            Name = metisObject.getNamedStringValue("name")
        end if
    End Property

'-----------------------------------------------------------
    Public Property Let Value(strVal)
        if isEnabled(metisObject) then
            call metisObject.setNamedStringValue("value", strVal)
        end if
    End Property

    Public Property Get Value
        if isEnabled(metisObject) then
            Value = metisObject.getNamedStringValue("value")
        end if
    End Property

'-----------------------------------------------------------
    Public Property Get Label
        if isEnabled(metisObject) then
            if Len(Name) > 0 then
                Label = Name
            elseif types_ok then
                Label = getValue(metisObject)
            end if
        end if
    End Property

'-----------------------------------------------------------
    Private Function getValue(inst)
        dim value
        dim prop, parentProps

        getValue = ""
        if isEnabled(inst) then
            value = inst.getNamedStringValue("value")
            if Len(value) = 0 then
                set parentProps = inst.getNeighbourObjects(1, IsType, PropertyType)
                for each prop in parentProps
                    if isEnabled(prop) then
                        value = getValue(prop)
                        if Len(value) > 0 then
                            getValue = value
                            exit for
                        end if
                    end if
                next
            else
                getValue = value
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function getIcon
    
            getIcon = PropertyIcon
            if Len(Name) > 0 and Len(Value) > 0 then
                getIcon = PropertyAndValueIcon
            elseif Len(Value) > 0 then
                getIcon = ValueIcon
            end if

    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        types_ok = false
        hasName = false
        hasValue = false
        set PropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        if isEnabled(PropertyType) then
            set IsType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
            if isEnabled(IsType) then
                types_ok = true
            end if
        end if
        PropertyIcon         = "http://xml.activeknowledgemodeling.com/eka/views/symbols/productproperty.svg#oid1"
        ValueIcon            = "http://xml.activeknowledgemodeling.com/eka/views/symbols/productproperty.svg#oid1"
        PropertyAndValueIcon = "http://xml.activeknowledgemodeling.com/eka/views/symbols/productproperty.svg#oid1"
        if not types_ok then
            MsgBox "Initialization of EKA_Property failed!"
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub


End Class
'-----------------------------------------------------------
'-----------------------------------------------------------

