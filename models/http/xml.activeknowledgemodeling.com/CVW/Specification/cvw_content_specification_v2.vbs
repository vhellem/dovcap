option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ContentSpecification

    Public  title                       ' String
    Public  model                       ' IMetisModel

    Private pathRelType                 ' IMetisType
    Private propertyType                ' IMetisType
    Private hasValueConstraintType      ' IMetisType
    Private datatypeProp                ' String
    Private operatorProp                ' String
    Private valueProp                   ' String
    Private instances                   ' IMetisCollection of IMetisInstance(s)


'-----------------------------------------------------------
    Private Function valueIsValid(inst, propName, operator, value)
        dim propValue, numValue, stringValue, strValue
        dim isNumber, number

        valueIsValid = false
        set propValue = inst.getNamedValue(propName)
        if propValue.isInteger then
            isNumber = true
            numValue = propValue.getInteger
            number = CInt(value)
        elseif propValue.isFloat then
            isNumber = true
            numValue = propValue.getFloat
            number = CDbl(value)
        else
            isNumber = false
            stringValue = propValue.getString
        end if
        if isNumber then
            select case operator
            case "lt"
                if numValue < number then
                    valueIsValid = true
                end if
            case "le"
                if numValue <= number then
                    valueIsValid = true
                end if
            case "eq"
                if numValue = number then
                    valueIsValid = true
                end if
            case "ne"
                if numValue <> number then
                    valueIsValid = true
                end if
            case "ge"
                if numValue >= number then
                    valueIsValid = true
                end if
            case "gt"
                if numValue > number then
                    valueIsValid = true
                end if
            end select
        else
            select case operator
            case "eq"
                if stringValue = value then
                    valueIsValid = true
                end if
            case "ne"
                if stringValue <> value then
                    valueIsValid = true
                end if
            end select
        end if

    End Function

'-----------------------------------------------------------
    Private Function isSpecificationObject(inst)
        dim rels

        isSpecificationObject = false
        if isEnabled(inst) then
            set rels = inst.getNeighbourRelationships(1, hasValueConstraintType)
            if rels.count > 0 then
                isSpecificationObject = true
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Function findConstrainedInstances(obj, cont)
        dim instType, insts, inst
        dim relships, rels, relship, rel, relType, relDir
        dim prop, propName, propValue, value
        dim datatype, operator
        dim i, removed

        set findConstrainedInstances = Nothing
        if isEnabled(obj) then
            ' Find instances
            set instType = obj.type
            set insts = model.findInstances(instType, "", "")
            ' If constrained by property values, remove from list
            set relships = obj.getNeighbourRelationships(0, hasValueConstraintType)
            for each rel in relships
                if isEnabled(rel) then
                    set prop = rel.target
                    if prop.type.inherits(propertyType) then
                        operator = rel.getNamedStringValue(operatorProp)
                        propName = prop.name
                        propValue = prop.getNamedStringValue(valueProp)
                        i = 1
                        for each inst in insts
                            removed = false
                            if isEnabled(inst) then
                                if not valueIsValid(inst, propName, operator, propValue) then
                                    insts.removeAt(i)
                                    removed = true
                                end if
                                if not removed then
                                    i = i + 1
                                end if
                            end if
                        next
                    end if
                end if
            next
            ' If constrained by relationship
            set relships = cont.getNeighbourRelationships(0, pathRelType)
            for each relship in relships
                if isEnabled(relship) then
                    ' Top object
                    set inst = relship.target
                    set rels = inst.neighbourRelationships
                    for each rel in rels
                        if rel.type.uri <> hasValueConstraintType.uri then
                            if rel.origin.uri <> cont.uri then
                                if rel.origin.uri = inst.uri then
                                    relDir = 0
                                elseif rel.target.uri = inst.uri then
                                    relDir = 1
                                end if
                                set relType = rel.type
                                exit for
                            end if
                        end if
                    next
                    i = 1
                    if isEnabled(relType) then
                        for each inst in insts
                            removed = false
                            set rels = inst.getNeighbourRelationships(relDir, relType)
                            if rels.count > 0 then
                                insts.removeAt(i)
                                removed = true
                            end if
                            if not removed then
                                i = i + 1
                            end if
                        next
                    end if
                end if
            next
            if insts.count > 0 then
                set findConstrainedInstances = insts
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function findInstances(contView)      ' Specification container
        dim cont
        dim relships, relships2, rel
        dim children, childView
        dim instType, insts, inst
        dim obj

        set findInstances = metis.newInstanceList

        if not isEnabled(model) then
            exit function
        end if

        set cont = contView.instance
        ' Check if this is a path specification
        ' If so, only find the top objects
        set relships = cont.getNeighbourRelationships(0, pathRelType)
        if relships.count > 0 then
            ' This is a path query - get start objects
            for each rel in relships
                set inst = rel.target
                set instType = inst.type
                if isEnabled(instType) then
                    ' Find all instances of this type in the given model
                    set insts = findConstrainedInstances(inst, cont)
                    for each inst in insts
                        if not instanceInList(inst, instances) then
                            findInstances.addLast inst
                        end if
                    next
                end if
            next
        else
            ' This is an instance search
            ' Find the instances in the container
            set children = contView.children
            for each childView in children
                if hasInstance(childView) then
                    set inst = childView.instance
                    if isEnabled(inst) and not isSpecificationObject(inst) and not inst.isRelationship then
                        set instType = inst.type
                        if isEnabled(instType) then
                            ' Find all instances of this type in the given model
                            set insts = findConstrainedInstances(inst, cont)
                            if isValid(insts) then
                                for each inst in insts
                                    if not instanceInList(inst, findInstances) then
                                        findInstances.addLast inst
                                    end if
                                next
                            end if
                        end if
                    end if
                end if
            next
        end if
        if findInstances.count = 0 then
            set findInstances = Nothing
        end if

    End Function

'-----------------------------------------------------------
    Public Function findByCriteria(criteria)
        if isEnabled(criteria) then
            set instances = model.runCriteria(criteria)
        end if

    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set pathRelType            = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasValueConstraintType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
        set propertyType           = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        datatypeProp  = "datatype"
        operatorProp  = "operator"
        valueProp     = "value"
        set instances = metis.newInstanceList
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
        set instances = Nothing
    End Sub

'-----------------------------------------------------------
End Class

