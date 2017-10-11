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
    Public noLevels
    Public applyFilter                   ' Boolean

    ' Context variables
    Public  currentModel
    Public  currentModelView
    Public  currentInstance
    Public  currentInstanceView
    Public  contextInstance
    Public  topInstance
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
    Private tqlMethod2                   ' IMetisMethod

    ' Others
    Private noRelTypes                   ' Integer
    Private relTypeList()                ' Collection of relationship types
    Private cvwArg                       ' CVW_ArgumentValue
    Private specObject                   ' IMetisInstance
    Private specObjectView               ' IMetisInstanceView
    Private filterObject                 ' IMetisInstance
    Private filterObjectView             ' IMetisInstanceView
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
    Public  noFilterRules
    Public  filterRules()

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
    Public Property Let FilterModel(specModel)
        if Len(specModel) > 0 then
            set filterObject = metis.findInstance(specModel)
            if isEnabled(filterObject) then
                set filterObjectView = filterObject.views(1)
            end if
        end if
    End Property

    Public Property Get FilterModel
        FilterModel = ""
        if isEnabled(specObject) then
            FilterModel = filterObject.uri
        end if
    End Property

'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build
        dim specModel, filterModel

        ' Find configuring parameter values
        SearchMode   = cvwArg.getConfiguredValue(component, "SearchMode")                  ' SelectAll | SelectOneFromList | SelectManyFromList
        ContextMode  = cvwArg.getConfiguredValue(component, "ContextMode")                 ' CurrentModel | SubModel
        specModel    = cvwArg.getConfiguredValue(component, "ContentSpecification_Model")
        filterModel  = cvwArg.getConfiguredValue(component, "FilterSpecification_Model")
        if Len(specModel)> 0 then
            set specObject = metis.findInstance(specModel)
            if isEnabled(specObject) then
                set specObjectView = specObject.views(1)
            end if
        end if
        if Len(filterModel)> 0 then
            set filterObject = metis.findInstance(filterModel)
            if isEnabled(filterObject) then
                set filterObjectView = filterObject.views(1)
            end if
        end if
   End Sub

'-----------------------------------------------------------
    ' HDJ added this alternative to build 
    Public Sub IRTVconfigure(parameters)
        on error resume next
        
        SearchMode   = parameters.getValue("SearchMode")                  ' SelectAll | SelectOneFromList | SelectManyFromList
        ContextMode  = parameters.getValue("ContextMode")                 ' CurrentModel | SubModel
        set specObject = parameters.getValue("ContentSpecification_Model")
        if isEnabled(specObject) then
			specModel    = specObject.uri
		end if
		set filterObject = parameters.getValue("FilterSpecification_Model")
		if isEnabled(filterObject) then
			filterModel    = filterObject.uri
			set filterObjectView = filterObject.views(1)
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
        dim hasTopInstance
stop
        set execute = Nothing
        hasTopInstance = false
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
                    hasTopInstance = false
                    if isEnabled(topInstance) then
                        if topInstance.type.uri = instType.uri then
                            hasTopInstance = true
                        end if
                    end if
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
        ' Find filter specification
        if isValid(filterObjectView) then
            set children = filterObjectView.children
            if isValid(children) then
                for each childView in children
                    if hasInstance(childView) then
                        set inst = childView.instance
                        if isEnabled(inst) and not isSpecificationObject(inst) and not inst.isRelationship then
                            call buildInstRules(inst, filterRules, noFilterRules, hasValueConstraintType)
                        end if
                    end if
                next
            end if
        end if
        ' Now all content specification rules are captured
        ' Go on to finding the instances
        if RepositoryConnection then
            set instances = getInstancesFromRepository(instances)
        else
            set instances = getInstancesFromClient(instances, hasTopInstance, filterRules, noFilterRules)
        end if
        ' Ask the user according to search mode
        if not askForType and instances.count > 1 then
            set instances = getInstancesSelectedFromList(instances, SearchMode)
        end if
        ' Then continue the search according to path specification
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
            if RepositoryConnection then
                set instances = getPathListFromRepository(instances, typeInstances)
            else
                set instances = getPathListFromClient(instances, typeInstances)
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
        set ekaInstance = Nothing
        set execute = instances
    End Function

'-----------------------------------------------------------
    Private Function getInstancesFromClient(instances, hasTopInstance, filterRules, noFilterRules)
        dim cvwSelectDialog, cvwFilter
        dim rule
        dim inst, insts
        dim typeInstances, typeList
        dim pathList, pathObj, pathRel, relList
        dim isValid1
        dim i, j

        set getInstancesFromClient = instances
        if isEnabled(contextInstance) then
            instances.addLast contextInstance
        elseif noTopObjectRules > 0 then
            if hasTopInstance then
                instances.addLast topInstance
            else
                if applyFilter then
                    set cvwFilter = new CVW_Filter
                end if
                for i = 1 to noTopObjectRules
                    set rule = topObjectRules(i)
                    if isValid(rule) then
                        set insts = findConstrainedInstances(rule)
                        if isValid(insts) then
                            for each inst in insts
                                isValid1 = true
                                if applyFilter then
                                    isValid1 = cvwFilter.instIsValid(inst, filterRules, noFilterRules)
                                end if
                                if isValid1 and not instanceInList(inst, instances) then
                                    instances.addLast inst
                                end if
                            next
                        end if
                    end if
                next
            end if
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
                        set insts = findConstrainedInstances(rule)
                        if isValid(insts) then
                            for each inst in insts
                                if not instanceInList(inst, instances) then
                                    instances.addLast inst
                                end if
                            next
                        end if
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
                        set insts = findConstrainedInstances(rule)
                        if isValid(insts) then
                            for each inst in insts
                                if not instanceInList(inst, instances) then
                                    instances.addLast inst
                                end if
                            next
                        end if
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
		' Debuf
		  ' MsgBox strQuery
		  ' exit function
        ' Build query method
		tqlMethod1.setArgument1 "Query0", strQuery
		tqlMethod1.setArgument1 "AllowCreateViews", 0
        ' Get instances from repository
		set findRepositoryInstances = currentModel.runMethodOnInst1(tqlMethod1, contentModel).getCollection
    End Function

'-----------------------------------------------------------
    Private Function getPathListFromClient(instances, typeInstances)
        dim inst
        dim pathObj, pathRel, pathList
        dim level

        set getPathListFromClient = Nothing
        level = 0
        if noLevels > level or noLevels = -1 then
            level = level + 1
            call addInstancePathToList(instances, typeInstances, level)
            if isEnabled(contextInstance) then
                instances.removeAt(1)
            end if
            level = level - 1
        end if
        set getPathListFromClient = instances
    End Function

'-----------------------------------------------------------
    Private Sub addInstancePathToList(instances, typeInstances, level)
        dim pathList, pathObj
        dim inst
        dim cvwFilter
        dim isValid1

        set pathList = metis.newInstanceList
        if noLevels > level or noLevels = -1 then
            set cvwFilter = new CVW_Filter
            for each inst in instances
                if applyFilter then
                    isValid1 = cvwFilter.instIsValid(inst, filterRules, noFilterRules)
                else
                    isValid1 = false
                end if
                if not applyFilter or isValid1 then
                    call addPathToList(inst, pathList, typeInstances)
                    for each pathObj in pathList
                        if not instanceInList(pathObj, instances) then
                            instances.addLast pathObj
                        end if
                    next
                end if
            next
            if noLevels > level or noLevels = -1 then
                level = level + 1
                call addInstancePathToList(instances, typeInstances, level)
                level = level - 1
            end if
            set cvwFilter = Nothing
        end if
    End Sub

'-----------------------------------------------------------
    Private Function getPathListFromRepository(instances, typeInstances)
        dim strQuery
        dim objType
        dim rule
        dim j

        set getPathListFromRepository = instances
        ' Begin code
        ' Build the TQL query
        for j = 1 to noPathRules
            set rule = pathRules(j)
            if isValid(rule) then
                if rule.relDir = 0 then
                    set objType = rule.childType
                else
                    set objType = rule.parentType
                end if
                if typeInList2(objType, typeInstances) then
                    strQuery = "Relationship.type ='" & rule.relType.title & "' AND Relationship.hasComponent(Component.type ='" & rule.childType.title & "') AND Relationship.hasComponent(Component.type ='" & rule.parentType.title & "') OR "
                end if
            end if
        next
        if Len(strQuery) > 0 then
            strQuery = Left(strQuery, Len(strQuery) - 4)
            ' Debug
                ' MsgBox strQuery
                ' exit function
            ' Build query method
            tqlMethod2.setArgument1 "Query0", strQuery
            tqlMethod2.setArgument1 "EnsureRelationshipEndObjects", 0
            ' Get instances from repository
            set getPathListFromRepository = currentModel.runMethodOnInst1(tqlMethod2, contentModel).getCollection
        end if
        ' End code
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
        dim cvwFilter
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
                    set cvwFilter = new CVW_Filter
                    i = 1
                    for each inst in insts
                        removed = false
                        if isEnabled(inst) then
                            if not cvwFilter.valueIsValid(inst, rule.propname, rule.operator, rule.propvalue) then
                                insts.removeAt(i)
                                removed = true
                            end if
                            if not removed then
                                i = i + 1
                            end if
                        end if
                    next
                    set cvwFilter = Nothing
                end if
            end if
            if insts.count > 0 then
                set findConstrainedInstances = insts
            end if
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Private Sub addPathToList(inst, instances, typeInstances)
        dim rule
        dim relDir
        dim obj, rel, rels
        dim cvwFilter
        dim isValid1, isValid2
        dim j

        if isEnabled(inst) and isValid(instances) then
            set cvwFilter = new CVW_Filter
            set rels = inst.neighbourRelationships
            for each rel in rels
                if applyFilter then
                    isValid1 = cvwFilter.instIsValid(rel, filterRules, noFilterRules)
                else
                    isValid1 = true
                end if
                if not applyFilter or isValid1 then
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
                                    if typeInList(obj, typeInstances) then
                                        if applyFilter then
                                            isValid2 = cvwFilter.instIsValid(obj, filterRules, noFilterRules)
                                        else 
                                            isValid2 = false
                                        end if
                                        if not applyFilter or isValid2 then
                                            if not instanceInList(obj, instances) then
                                                instances.addLast obj
                                            end if
                                        end if
                                    end if
                                    if not instanceInList(rel, instances) then
                                        instances.addLast rel
                                    end if
                                    exit for
                                end if
                            end if
                        end if
                    next
                end if
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
    Private Function typeInList2(objType, typeInstances)
        dim typeInst

        typeInList2 = false
        if not isValid(typeInstances) then
            typeInList2 = true
            exit function
        end if
        for each typeInst in typeInstances
            if objType.inherits(typeInst.type) then
                typeInList2 = true
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
        set topInstance     = Nothing
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
        Set tqlMethod2  = metis.findMethod("http://xml.activeknowledgemodeling.com/akm/operations/tql_methods.kmd#RelationshipOnlyQuery")

        ' Others
        noRelTypes = 3
        ReDim Preserve relTypeList(noRelTypes)
        set relTypeList(1)   = isTopType
        set relTypeList(2)   = hasValueType
        set relTypeList(3)   = hasValueConstraintType

        set instances        = metis.newInstanceList
        noTopObjectRules     = 0
        noPathRules          = 0
        noFilterRules        = 0
        RepositoryConnection = false
        noLevels             = 1
        applyFilter          = false
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


