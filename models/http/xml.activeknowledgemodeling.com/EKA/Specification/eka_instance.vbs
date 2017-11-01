option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class EKA_Instance


    ' Variant parameters
    Public Title                        ' String
    Public Instance                     ' IMetisInstance

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    ' Types
    Private objectType
    Private propertyType
    Private hasPropertyType
    Private hasValueType
    Private hasValue2Type
    Private isType


'-----------------------------------------------------------
    Public Function findObject(model, instName)
        dim instances

        set findObject = Nothing

        if isEnabled(model) then
            set instances = model.findInstances(objectType, "name", instName)
            if instances.count >= 1 then
                set findObject= instances(1)
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Property Get Properties
        set Properties = Nothing
        if isEnabled(Instance) then
            set Properties = getProperties(Instance)
        end if
    End Property

'-----------------------------------------------------------
    Public Function getPropertyValue(inst, propName)
        dim prop, properties

        getPropertyValue = ""
        set properties = inst.getNeighbourObjects(0, hasPropertyType, propertyType)
        if isValid(properties) then
            for each prop in properties
                if prop.title = propName then
                    getPropertyValue = prop.getNamedStringValue("value")
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Private Function hasValue(prop)
        dim propValue
        dim relships

        hasValue = false
        propValue = prop.getNamedStringValue("value")
        if Len(propValue) > 0 then
            hasValue = true
        else
            set relships = prop.getNeighbourRelationships(0, hasValueType)
            if isValid(relships) then
                hasValue = true
            else
                set relships = prop.getNeighbourRelationships(0, hasValue2Type)
                if isValid(relships) then
                    hasValue = true
                end if
            end if
        end if

    End Function

'-----------------------------------------------------------
    Private Function getProperties(inst)                  ' as IMetisCollection of IMetisInstance
        dim prop, props
        dim i, removed

        set getProperties = Nothing
        if isEnabled(inst) then
            set props = inst.getNeighbourObjects(0, hasPropertyType, propertyType)
            if isValid(props) then
                i = 1
                removed = false
                for each prop in props
                    if not hasValue(prop) then
                        props.removeAt(i)
                        removed = true
                    end if
                    if not removed then
                        i = i + 1
                    end if
                next
                set props = getInheritedProperties(inst, props)
            end if
            set getProperties = props
        end if

    End Function

'-----------------------------------------------------------
    Private Function getInheritedProperties(inst, props)  ' as IMetisCollection of IMetisInstance
        dim rel, rels
        dim prop, parentProps
        dim parentInst

        set rels = inst.getNeighbourRelationships(0, isType)
        for each rel in rels
            set parentInst = rel.target
            if isEnabled(parentInst) then
                set parentProps = parentInst.getNeighbourObjects(0, hasPropertyType, propertyType)
                if isValid(parentProps) then
                    for each prop in parentProps
                        if not instanceByNameInList(prop, props) then
                            props.addLast prop
                        end if
                    next
                end if
                set props = getInheritedProperties(parentInst, props)
            end if
        next
        set getInheritedProperties = props
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        ' Context variables
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        ' Types
        set objectType      = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_object.kmd#ObjType_EKA:Object_UUID")
        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        set isType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
        set hasValueType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set hasValue2Type   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue2_UUID")

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

