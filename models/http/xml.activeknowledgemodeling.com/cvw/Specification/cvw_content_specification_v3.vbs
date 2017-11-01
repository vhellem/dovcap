option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ContentSpecification   ' A CVW Component

    ' Variant parameters
    Public Title
    Public ContextMode                   ' String
    Public SearchMode                    ' String
    Public SpecificationModel            ' String

    ' Context variables
    Public  currentModel
    Public  currentModelView
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private isTopType                    ' IMetisType
    Private propertyType                 ' IMetisType
    Private hasValueConstraintType       ' IMetisType

    ' Others
    Private cvwArg                       ' CVW_ArgumentValue
    Private specObject                   ' IMetisInstance
    Private specObjectView               ' IMetisInstanceView
    Private instances                    ' Collection of IMetisInstance
    Private datatypeProp                 ' String
    Private operatorProp                 ' String
    Private valueProp                    ' String
    
    Private noRelTypes
    Private RelTypes()

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
        ' Find configuring parameter values
        SearchMode         = cvwArg.getConfiguredValue(component, "SearchMode")                  ' SelectAll | SelectOneFromList | SelectManyFromList
        ContextMode        = cvwArg.getConfiguredValue(component, "ContextMode")                 ' CurrentModel | SubModel
        SpecificationModel = cvwArg.getConfiguredValue(component, "ContentSpecification_Model")
        if Len(SpecificationModel)> 0 then
            set specObject = metis.findInstance(SpecificationModel)
            if isEnabled(specObject) then
                set specObjectView = specObject.views(1)
            end if
        end if
   End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Only relevant if this component uses other components
    End Sub

'-----------------------------------------------------------
    ' Execute: Find the instances and return the result
    Public Function execute
        dim rel, relships, relList
        dim inst, insts
        dim instType
        dim childView, children
        dim contView

        set execute = Nothing
        ' Check if this is a path specification
        ' If so, only find the top objects
        if not isEnabled(specObject) then
            exit function
        end if
        set relships = specObject.getNeighbourRelationships(0, isTopType)
        if relships.count > 0 then
            ' This is a path query - get start objects
            for each rel in relships
                set inst = rel.target
                set instType = inst.type
                if isEnabled(instType) then
                    ' Find all instances of this type in the given model
                    set insts = findConstrainedInstances(inst)
                    if isValid(insts) then
                        for each inst in insts
                            if not instanceInList(inst, instances) then
                                instances.addLast inst
                            end if
                        next
                    end if
                end if
            next
        elseif isEnabled(specObjectView) then
            ' This is an instance search
            ' Find the instances in the container
            set children = specObjectView.children
            for each childView in children
                if hasInstance(childView) then
                    set inst = childView.instance
                    if isEnabled(inst) and not isSpecificationObject(inst) and not inst.isRelationship then
                        set instType = inst.type
                        if isEnabled(instType) then
                            ' Find all instances of this type in the given model
                            set insts = findConstrainedInstances(inst)
                            if isValid(insts) then
                                for each inst in insts
                                    if not instanceInList(inst, instances) then
                                        instances.addLast inst
                                    end if
                                next
                            end if
                        end if
                    end if
                end if
            next
            if isValid(instances) then
                set instances = getInstancesSelectedFromList(instances, SearchMode)
            end if
            for each childView in children
                if hasInstance(childView) then
                    set inst = childView.instance
                    if isEnabled(inst) and inst.isRelationship then
                        set instType = inst.type
                        if isEnabled(instType) then
                            call addRelType(instType)
                            set relList = metis.newInstanceList
                            set insts = findRelationships(relList, instances)
                            for each inst in insts
                                instances.addLast inst
                            next
                            set relList = Nothing
                        end if
                    end if
                end if
            next
        end if
        set execute = instances
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Function findRelationships(relList, objects)
        dim obj
        dim rel, rels
        dim indx

        for each obj in objects
            set rels = obj.neighbourRelationships
            if isValid(rels) then
                for each rel in rels
                    if rel.origin.uri = obj.uri then
                        for indx = 1 to noRelTypes
                            if rel.type.uri = relTypes(indx).uri then
                                if not instanceInList(rel, relList) then
                                    if instanceInList(rel.target, objects) then
                                        relList.addLast rel
                                    end if
                                end if
                            end if
                        next
                    end if
                next
            end if
        next
        set findRelationships = relList
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Function getInstancesSelectedFromList(instances, searchMode)
        dim cvwSelectDialog

        ' Handle select dialog if specified
        if searchMode = "SelectAll" then
            set getInstancesSelectedFromList = instances
        else
            set cvwSelectDialog = new CVW_SelectDialog
            if searchMode = "SelectOneFromList" then
                cvwSelectDialog.singleSelect = true
            elseif searchMode = "SelectManyFromList" then
                cvwSelectDialog.singleSelect = false
            end if
            set getInstancesSelectedFromList = cvwSelectDialog.show(instances)
            set cvwSelectDialog = Nothing
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
    Private Sub addRelType(rtype)
        dim relType
        dim indx, found

        found = false
        for indx = 1 to noRelTypes
            set relType = relTypes(indx)
            if isValid(relType) then
                if relType.uri = rtype.uri then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noRelTypes = noRelTypes + 1
            ReDim Preserve relTypes(noRelTypes)
            set relTypes(noRelTypes) = rtype
        end if
    End Sub


'-----------------------------------------------------------
    Private Function findConstrainedInstances(obj)
        DIM contentModel, context
        dim instType, insts, inst
        dim relships, rels, rel
        dim prop, propName, propValue, value
        dim datatype, operator
        dim i, removed

        set findConstrainedInstances = Nothing
        'set contentModel = findInstModel(ContextMode, "ContentModel")
        set context = new EKA_Context
        if isValid(context) then
            set context.currentModel = currentModel
            set context.currentModelView = currentModelView
            set contentModel = context.contentModel
        end if
        if isEnabled(obj) and isEnabled(contentModel) then
            set metis.currentModel = currentModel
            set currentModel.currentModelView = currentModelView
            ' Find constraints
            set instType = obj.type
            set relships = obj.getNeighbourRelationships(0, hasValueConstraintType)
            if relships.count = 1 then
                set rel = relships(1)
                set prop = rel.target
                operator = rel.getNamedStringValue(operatorProp)
                if operator = "eq" then
                    set insts = findParts(contentModel, instType, prop.name, prop.getNamedStringValue(valueProp))
                end if
            end if
            if not isValid(insts) then
                set insts = findParts(contentModel, instType, "", "")
            end if
            if isValid(insts) then
                ' If constrained by property values, remove from list
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
            end if
            if insts.count > 0 then
                set findConstrainedInstances = insts
            end if
        end if
    End Function

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
    Private Sub Class_Initialize()
        dim instView, children

        set currentModel     = metis.currentModel
        set currentModelView = currentModel.currentModelView
        set cObject   = currentModel.currentInstance
        set aObject   = currentModel.currentInstance
        set cvwArg    = new CVW_ArgumentValue
        ' Correct current model
        set instView  = currentModelView.currentInstanceView
        set children = currentModelView.children
        if isValid(children) then
            on error resume next
            'set currentModel = children(1).instance.ownerModel
            'set metis.currentModel = currentModel
        end if
        ' Types
        set isTopType              = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasValueConstraintType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
        set propertyType           = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        ' Others
        set instances = metis.newInstanceList
        datatypeProp  = "datatype"
        operatorProp  = "operator"
        valueProp     = "value"
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


