option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ContentSpecification 

    ' Variant parameters
    Public Title
    Public ContextMode                   ' String     CurrentModel | SubModel
    Public SearchMode                    ' String     NoSearch | SelectAll | SelectOneFromList | SelectManyFromList | SelectTypeFromList
    Public PathMode                      ' String     Path | NoPath
    Public RepositoryConnection

    ' Context variables
    Public  currentModel
    Public  currentModelView
    Public  currentInstance
    Public  currentInstanceView
    Public  contextInstance
    Public  contentModel
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private propertyType                 ' IMetisType
    Private isTopType                    ' IMetisType
    Private hasValueType                 ' IMetisType
    Private hasValueConstraintType       ' IMetisType
    
    ' Methods
    Private tqlMethod1                   ' IMetisMethod

    ' Others
    Private noRelTypes                   ' Integer
    Private relTypeList()                ' Collection of relationship types
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
    Public Property Let SpecificationModel(specModel)
        if Len(specModel) > 0 then
            set specObject = metis.findInstance(specModel)
            if isEnabled(specObject) then
                set specObjectView = specObject.views(1)
            end if
        end if
    End Property

    Public Property Get SpecificationModel
        SpecificationModel = ""
        if isEnabled(specObject) then
            SpecificationModel = specObject.uri
        end if
    End Property

'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build
        dim specModel

        ' Find configuring parameter values
        SearchMode   = cvwArg.getConfiguredValue(component, "SearchMode")                  ' SelectAll | SelectOneFromList | SelectManyFromList
        ContextMode  = cvwArg.getConfiguredValue(component, "ContextMode")                 ' CurrentModel | SubModel
        specModel    = cvwArg.getConfiguredValue(component, "ContentSpecification_Model")
        if Len(specModel)> 0 then
            set specObject = metis.findInstance(specModel)
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
        dim rel, relships, relList, pathList, pathRel, pathObj
        dim inst, insts
        dim instType
        dim childView, children
        dim contView
        dim ekaInstance
        dim propVal
        dim askForType
        dim i, j, rule
        dim typeList, typeInstances
        dim cvwSelectDialog

        set execute = Nothing
        ' Check if this is a path specification
        ' If so, only find the top objects
        if not isEnabled(specObject) then
            exit function
        end if
        if SearchMode = "NoSearch" then
            exit function
        end if
        set ekaInstance = new EKA_Instance
        propVal = ekaInstance.getPropertyValue(specObject, "SearchMode")
        if Len(propVal) > 0 then
            SearchMode = propVal
        end if
        set relships = specObject.getNeighbourRelationships(0, isTopType)
        if relships.count > 0 then
            ' This is a path query - find top object types and path rules
            for each rel in relships
                set inst = rel.target
                set instType = inst.type
                if isEnabled(instType) then
                    call buildInstRules(inst, topObjectRules, noTopObjectRules, hasValueConstraintType)
                    call buildRelRules(inst, pathRules, noPathRules, relTypeList, noRelTypes)
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
                            call buildRelRule(inst, inst.origin, relRules, noRelRules, relTypeList, noRelTypes)
                        end if
                    end if
                end if
            next
        end if
        ' Now all content specification rules are captured
        ' Go on to finding the instances
        if RepositoryConnection then
            set instances = getInstancesFromRepository(instances)
        else
            set instances = getInstancesFromClient(instances, askForType)
        end if
        set ekaInstance = Nothing
        set execute = instances
    End Function

'-----------------------------------------------------------
    Private Function getInstancesFromClient(instances, askForType)
        dim cvwSelectDialog
        dim rule
        dim inst, insts
        dim typeInstances, typeList
        dim pathList, pathObj, pathRel, relList
        dim i, j

        set getInstancesFromClient = instances
        if isEnabled(contextInstance) then
            instances.addLast contextInstance
        elseif noTopObjectRules > 0 then
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
            if insts.count > 1 then
                set instances = getInstancesSelectedFromList(insts, SearchMode)
            end if
        end if
        if not askForType and instances.count > 1 then
            set instances = getInstancesSelectedFromList(instances, SearchMode)
        end if
        if PathMode = "Path" and instances.count > 0 then
            set typeInstances = Nothing
            if isEnabled(contextInstance) then
                ' Build type list of actual types to search
                set typeList = getTypeList(specObject, contextInstance, -1)
                if isValid (typeList) then
                    if typeList.count = 1 then
                        set typeInstances = typeList
                    elseif typeList.count > 1 then
                        set cvwSelectDialog = new CVW_SelectDialog
                        cvwSelectDialog.singleSelect = true
                        cvwSelectDialog.title = "Select dialog"
                        cvwSelectDialog.heading = "Search by type"
                        set typeInstances = cvwSelectDialog.show(typeList)
                    end if
                end if
            end if
            ' Check connected relationships
            set pathList = metis.newInstanceList
            if isValid(pathList) then
                for each inst in instances
                    call addPathToList(inst, pathList, typeInstances, true)
                    for each pathObj in pathList
                        if not instanceInList(pathObj, instances) then
                            instances.addLast pathObj
                        end if
                    next
                next
                if isEnabled(contextInstance) then
                    instances.removeAt(1)
                end if
                set pathList = metis.newInstanceList
                for each inst in instances
                    call addPathToList(inst, pathList, typeInstances, false)
                    for each pathRel in pathList
                        if not instanceInList(pathRel, instances) then
                            instances.addLast pathRel
                        end if
                    next
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
        set getInstancesFromClient = instances
    End Function

'-----------------------------------------------------------
    Private Function getInstancesFromRepository(instances)
        dim rule
        dim inst, insts
        dim i

        set getInstancesFromRepository = instances
        if isEnabled(contextInstance) then
            instances.addLast contextInstance
        elseif noTopObjectRules > 0 then
            for i = 1 to noTopObjectRules
                set rule = topObjectRules(i)
                if isValid(rule) then
                    set insts = findRepositoryInstances(rule)
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
                    set insts = findRepositoryInstances(rule)
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
            if insts.count > 1 then
                set instances = getInstancesSelectedFromList(insts, SearchMode)
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Function findRepositoryInstances(rule)
        dim strQuery

        set findRepositoryInstances = Nothing
        ' Build query
		strQuery = "Component.type ='" & rule.instType.title & "'"
        ' Build query method
		tqlMethod1.setArgument1 "Query0", strQuery
		tqlMethod1.setArgument1 "AllowCreateViews", 0
        ' Get instances from repository
		set findRepositoryInstances = currentModel.runMethodOnInst1(tqlMethod1, contentModel).getCollection
    End Function

'-----------------------------------------------------------
    Private Function getTypeList(specObject, inst, relDir)
        dim obj, obj2, objects
        dim foundObj
        dim rel, rel2, relships, rDir
        dim exclude

        set getTypeList = Nothing
        set relships = specObject.getNeighbourRelationships(0, isTopType)
        if isValid(relships) then
            if relships.count = 1 then
                set rel = relships(1)
                set obj = rel.target
                if obj.type.uri = inst.type.uri then
                    'inst is contextInstance
                    ' Find connected types
                    set relships = obj.neighbourRelationships
                    if isValid(relships) then
                        set getTypeList = metis.newInstanceList
                        for each rel2 in relships
                            exclude = false
                            if rel2.type.uri = hasValueType.uri then
                                exclude = true
                            elseif rel2.type.uri = hasValueConstraintType.uri then
                                exclude = true
                            end if
                            if not exclude and rel2.uri <> rel.uri then
                                if rel2.origin.uri = obj.uri then
                                    rDir = 0
                                    set obj2 = rel2.target
                                else
                                    rDir = 1
                                    set obj2 = rel2.origin
                                end if
                                if relDir = -1 or relDir = rDir then
                                    call getTypeList.addLast(obj2)
                                end if
                            end if
                        next
                    end if
                end if
            end if
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Function getInstancesSelectedFromList(instances, searchMode)
        dim cvwSelectDialog
        dim instType
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
                    set instances = findParts(contentModel, contentModel, instType, "", "")
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
        dim instType, insts, inst
        dim relships, rels, rel
        dim prop, propName, propValue, value
        dim datatype, operator
        dim i, removed

        set findConstrainedInstances = Nothing
        if isValid(rule) and isEnabled(contentModel) then
            set metis.currentModel = currentModel
            set currentModel.currentModelView = currentModelView
            if rule.operator = "eq" then
                set insts = findParts(contentModel, contentModel, rule.instType, rule.propname, rule.propvalue)
            end if
            if not isValid(insts) then
                set insts = findParts(contentModel, contentModel, rule.instType, "", "")
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
    Private Sub addPathToList(inst, instances, typeInstances, useObject)
        dim rule
        dim relDir
        dim obj, rel, rels
        dim j

        if isEnabled(inst) and isValid(instances) then
            set rels = inst.neighbourRelationships
            for each rel in rels
                if rel.origin.uri = inst.uri then
                    relDir = 0
                else
                    relDir = 1
                end if
                for j = 1 to noPathRules
                    set rule = pathRules(j)
                    if isValid(rule) then
                        if rule.relDir = relDir then
                            if relDir = 0 then
                                set obj = rel.target
                            else
                                set obj = rel.origin
                            end if
                            if obj.type.uri = rule.childType.uri then
                                if useObject then
                                    if typeInList(obj, typeInstances) then
                                        if not instanceInList(rel.target, instances) then
                                            instances.addLast rel.target
                                        end if
                                    end if
                                else
                                    if not instanceInList(rel, instances) then
                                        instances.addLast rel
                                    end if
                                end if
                            end if
                        end if
                    end if
                next
            next
        end if
    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Function typeInList(inst, typeInstances)
        dim typeInst

        typeInList = false
        if not isValid(typeInstances) then
            typeInList = true
            exit function
        end if
        for each typeInst in typeInstances
            if inst.type.inherits(typeInst.type) then
                typeInList = true
                exit function
            end if
        next
    End Function

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
        set contentModel    = currentModel
        set contextInstance = Nothing
        set cObject   = currentInstance
        set aObject   = currentInstance
        set cvwArg    = new CVW_ArgumentValue
        ' Correct current model
        set instView  = currentModelView.currentInstanceView
        set children = currentModelView.children
        ' Types
        set isTopType              = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasValueType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set hasValueConstraintType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
        set propertyType           = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        ' Methods
        Set tqlMethod1  = metis.findMethod("http://xml.activeknowledgemodeling.com/akm/operations/tql_methods.kmd#QueryUsingParameters_from_script")

        ' Others
        noRelTypes = 3
        ReDim Preserve relTypeList(noRelTypes)
        set relTypeList(1) = isTopType
        set relTypeList(2) = hasValueType
        set relTypeList(3) = hasValueConstraintType

        set instances        = metis.newInstanceList
        RepositoryConnection = false
        PathMode             = "Path"
        datatypeProp         = "datatype"
        operatorProp         = "operator"
        valueProp            = "value"
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


