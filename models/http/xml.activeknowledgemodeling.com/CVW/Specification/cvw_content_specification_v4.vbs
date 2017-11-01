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
    Public currentInstance
    Public currentInstanceView
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
    
    Private noTopObjectRules
    Private topObjectRules()
    Private noObjectRules
    Private objectRules()
    Public  noPathRules
    Public  pathRules()
    Private noRelRules
    Private relRules()

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
        dim rel, relships, relList, pathList, pathRel
        dim inst, insts
        dim instType
        dim childView, children
        dim contView
        dim askForType
        dim i, j, rule

        set execute = Nothing
        ' Check if this is a path specification
        ' If so, only find the top objects
        if not isEnabled(specObject) then
            exit function
        end if
        set relships = specObject.getNeighbourRelationships(0, isTopType)
        if relships.count > 0 then
            ' This is a path query - find top object types and path rules
            for each rel in relships
                set inst = rel.target
                set instType = inst.type
                if isEnabled(instType) then
                    call buildInstRules(inst, topObjectRules, noTopObjectRules, hasValueConstraintType)
                    call buildRelRules(inst, pathRules, noPathRules, isTopType)
                end if
            next
        else
            ' Find all object types
            if SearchMode = "SelectTypeFromList" then
                askForType = true
                set insts = metis.newInstanceList
            else
                askForType = false
            end if
            set children = specObjectView.children
            for each childView in children
                if hasInstance(childView) then
                    set inst = childView.instance
                    if isEnabled(inst) and not isSpecificationObject(inst) and not inst.isRelationship then
                        set instType = inst.type
                        if isEnabled(instType) then
                            if askForType then
                                if not instanceInList(inst, insts) then
                                    insts.addLast inst
                                end if
                            else
                                call buildInstRules(inst, objectRules, noObjectRules, hasValueConstraintType)
                            end if
                        end if
                    end if
                end if
            next
            ' Find all relationship types
            for each childView in children
                if hasInstance(childView) then
                    set inst = childView.instance
                    if isEnabled(inst) and inst.isRelationship then
                        set instType = inst.type
                        if isEnabled(instType) then
                            call buildRelRule(inst, inst.origin, relRules, noRelRules, isTopType)
                        end if
                    end if
                end if
            next
        end if
        ' Now all content specification rules are captured
        ' Go on to finding the instances
        if noTopObjectRules > 0 then
            set pathList = metis.newInstanceList
            for i = 1 to noTopObjectRules
                set rule = topObjectRules(i)
                if isValid(rule) then
                    set insts = findConstrainedInstances(rule)
                    if isValid(insts) then
                        for each inst in insts
                            if not instanceInList(inst, instances) then
                                instances.addLast inst
                            end if
                        next
                    end if
                end if
            next
        elseif noObjectRules > 0 then
            ' This is an instance search
            for i = 1 to noObjectRules
                set rule = objectRules(i)
                if isValid(rule) then
                    set insts = findConstrainedInstances(rule)
                    if isValid(insts) then
                        for each inst in insts
                            if not instanceInList(inst, instances) then
                                instances.addLast inst
                            end if
                        next
                    end if
                end if
            next
        elseif isValid(insts) then
            if insts.count > 0 then
                set instances = getInstancesSelectedFromList(insts, SearchMode)
            end if
        end if
        if not askForType and instances.count > 0 then
            set instances = getInstancesSelectedFromList(instances, SearchMode)
        end if
        if instances.count > 0 then
            ' Check connected relationships
            if isValid(pathList) then
                for each inst in instances
                    call addPathToList(inst, pathList)
                    for each pathRel in pathList
                        if not instanceInList(pathRel, instances) then
                            instances.addLast pathRel
                        end if
                    next
                next
                for each inst in instances
                    if inst.isObject then
                        call addPathToList(inst, pathList)
                        for each pathRel in pathList
                            if not instanceInList(pathRel, instances) then
                                instances.addLast pathRel
                            end if
                        next
                    end if
                next
            end if
        end if
        if noRelRules > 0 then
            ' Find the relationships
            for j = 1 to 2
                for i = 1 to noRelRules
                    set rule = relRules(i)
                    if isValid(rule) then
                        set relList = metis.newInstanceList
                        set insts = findRelationships(relList, instances, rule)
                        if isValid(insts) then
                            for each inst in insts
                                if not instanceInList(inst, instances) then
                                    instances.addLast inst
                                end if
                            next
                        end if
                        set relList = Nothing
                    end if
                next
            next
        end if
        set execute = instances
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Function getInstancesSelectedFromList(instances, searchMode)
        dim cvwSelectDialog, context
        dim instType, contentModel
        dim askForType

        ' Handle select dialog if specified
        askForType = false
        if searchMode = "SelectAll" then
            set getInstancesSelectedFromList = instances
        else
            set cvwSelectDialog = new CVW_SelectDialog
            if searchMode = "SelectOneFromList" then
                cvwSelectDialog.singleSelect = true
            elseif searchMode = "SelectManyFromList" then
                cvwSelectDialog.singleSelect = false
            elseif searchMode = "SelectTypeFromList" then
                cvwSelectDialog.singleSelect = true
                askForType = true
            end if
            set getInstancesSelectedFromList = cvwSelectDialog.show(instances)
            if askForType then
                set instances = getInstancesSelectedFromList
                if instances.count = 1 then
                    set instType = instances(1).type
                    ' Find all instances of this type
                    set context = new EKA_Context
                    if isValid(context) then
                        set context.currentModel = currentModel
                        set context.currentModelView = currentModelView
                        set contentModel = context.contentModel
                    end if
                    set instances = findParts(contentModel, instType, "", "")
                    if instances.count > 0 then
                        cvwSelectDialog.singleSelect = false
                        set getInstancesSelectedFromList = cvwSelectDialog.show(instances)
                    else
                        set getInstancesSelectedFromList = instances
                    end if
                end if
            end if
            set cvwSelectDialog = Nothing
        end if
    End Function

'-----------------------------------------------------------
    Private Function findConstrainedInstances(rule)
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
        if isValid(rule) and isEnabled(contentModel) then
            set metis.currentModel = currentModel
            set currentModel.currentModelView = currentModelView
            if rule.operator = "eq" then
                set insts = findParts(contentModel, rule.instType, rule.propname, rule.propvalue)
            end if
            if not isValid(insts) then
                set insts = findParts(contentModel, rule.instType, "", "")
                if insts.count > 0 then
                    for each inst in insts
                        i = 1
                        removed = false
                        if isEnabled(inst) then
                            if not valueIsValid(inst, rule.propname, rule.operator, rule.propvalue) then
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
            if insts.count > 0 then
                set findConstrainedInstances = insts
            end if
        end if
    End Function


   '---------------------------------------------------------------------------------------------------
    Private Sub addPathToList(inst, instances)
        dim rule
        dim rel, rels
        dim j

        if isEnabled(inst) and isValid(instances) then
            for j = 1 to noPathRules
                set rule = pathRules(j)
                if isValid(rule) then
                    set rels = inst.getNeighbourRelationships(rule.relDir, rule.relType)
                    for each rel in rels
                        if rule.relDir = 0 then
                            if rel.target.type.uri = rule.childType.uri then
                                if not instanceInList(rel, instances) then
                                    instances.addLast rel
                                end if
                                if not instanceInList(rel.target, instances) then
                                    instances.addLast rel.target
                                end if
                            end if
                        else
                            if rel.origin.type.uri = rule.parentType.uri then
                                if not instanceInList(rel, instances) then
                                    instances.addLast rel
                                end if
                                if not instanceInList(rel.origin, instances) then
                                    instances.addLast rel.origin
                                end if
                            end if
                        end if
                    next
                end if
            next
        end if
    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Function findRelationships(relList, objects, rule)
        dim obj
        dim rel, rels
        dim indx
        dim type1, type2

        for each obj in objects
            set rels = obj.neighbourRelationships
            if isValid(rels) then
                for each rel in rels
                    if rel.origin.uri = obj.uri then
                        if rule.relDir = 0 then
                            set type1 = rule.parentType
                            set type2 = rule.childType
                        else
                            set type1 = rule.childType
                            set type2 = rule.parentType
                        end if
                        if rel.type.uri = rule.relType.uri then
                            if rel.origin.type.uri = type1.uri then
                                if rel.target.type.uri = type2.uri then
                                    if not instanceInList(rel, relList) then
                                        if instanceInList(rel.target, objects) then
                                            relList.addLast rel
                                        end if
                                    end if
                                end if
                            end if
                        end if
                    end if
                next
            end if
        next
        set findRelationships = relList
    End Function

'-----------------------------------------------------------
    Private Function valueIsValid(inst, propName, operator, value)
        dim propValue, numValue, stringValue, strValue
        dim isNumber, number

        valueIsValid = false
        if Len(propName) = 0 then
            valueIsValid = true
            exit function
        end if
        set propValue = inst.getNamedValue(propName)
        if propValue.isInteger then
            isNumber = true
            numValue = propValue.getInteger
            if value = "true" then 
                value = "1"
            elseif value = "false" then 
                value = "0"
            end if
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
    Private Sub addTypeToList(itype, list, no)
        dim instType
        dim indx, found

        found = false
        for indx = 1 to no
            set instType = list(indx)
            if isValid(instType) then
                if instType.uri = itype.uri then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            no = no + 1
            ReDim Preserve list(no)
            set list(no) = itype
        end if
    End Sub


'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim instView, children

        set currentModel     = metis.currentModel
        set currentModelView = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set cObject   = currentInstance
        set aObject   = currentInstance
        set cvwArg    = new CVW_ArgumentValue
        ' Correct current model
        set instView  = currentModelView.currentInstanceView
        set children = currentModelView.children
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


