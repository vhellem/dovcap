option explicit

dim ekaObject

set ekaObject = new EKA_Object
ekaObject.metisObject = metis.currentModel.currentInstance

msgbox ekaObject.Label

Class EKA_Object

    Public metisObject
    
    Private virtualType
    Private virtualFile
    Private IsType
    Private PropertyType
    Private HasPropertyType
    Private types_ok

'-----------------------------------------------------------
    Public Sub generateType
        dim ekaType
        dim prop, properties

        set ekaType = new EKA_Type
        ekaType.name = "test1"
        ekaType.label = "Test 1"
        set ekaType.baseType = metisObject.type

        set properties = metisObject.getNeighbourObjects(0, HasPropertyType, PropertyType)
        for each prop in properties
            if isEnabled(prop) then
                call ekaType.addProperty(prop)
            end if
        next
        for each mtd in methods
            if isEnabled(mtd) then
                call ekaType.addMethod(mtd)
            end if
        next

        ekaType.file = virtualFile
        call ekaType.newVirtualType()

    End Sub

'-----------------------------------------------------------
    Public Function generateObject(inst, ekaType)           ' as IMetisObject
    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        types_ok = false
        set PropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        if isEnabled(PropertyType) then
            set IsType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
            if isEnabled(IsType) then
                set HasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
                if isEnabled(HasPropertyType) then
                    init_ok = true
                end if
            end if
        end if
        if not types_ok then
            MsgBox "Initialization of EKA_Property failed!"
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

