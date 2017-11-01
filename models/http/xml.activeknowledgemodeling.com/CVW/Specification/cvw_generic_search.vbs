option explicit
'------------------------------------------------------------------------------------------------
' Searching copied from cvw_content_specification, and simplified
'------------------------------------------------------------------------------------------------

Class	CVW_GenericSearch

' Context variables
    Private model
    Private modelView
    Private inst
    Private instView
    private ContentInRepository
    
	private hasTopInstance
	private topObjectRules()
	private noTopObjectRules
	private ObjectRules()
	private noObjectRules
	private pathRules()
	private noPathRules
	private relTypeList()
	private noRelTypes
	private noRelRules
	private relRules()
	private filterRules()
	private noFilterRules
	private filterObjectView
	private isTopType, hasValueConstraintType, hasValueType
	private applyFilter
        
    private currentConfig
    private inh

    Public Property Get config        'IRTV_Config
		if not isValid(currentConfig) then  ' if internal not valid, then create it ...
			set currentConfig = new IRTV_Config
			set inheritance = currentConfig.inheritance
		end if
        set config = currentConfig
    End Property

    Public Property Set config(obj)
        if isValid(obj) then
            set currentConfig = obj
            set inheritance = currentConfig.inheritance
            set model           = currentConfig.model
			set modelView       = currentConfig.modelView
			set inst            = currentConfig.inst
			set instView        = currentConfig.instView 
        end if
    End Property
    
    Private Property Get inheritance   'EKA_Inheritance
		if isValid(inh) then  ' if internal not valid, then create it ...
			set inheritance = inh
		else
			set currentConfig = new IRTV_Config
			set inheritance = currentConfig.inheritance
		end if
    End Property

    Private Property Set inheritance(obj)
        if isValid(obj) then
            set inh = obj
        end if
    End Property
    
    
   public function search (qobj)
		set search = query (getContentModel(), qobj, ContentInRepository, nothing)
   end function
   
   public function searchFromCollection (qobj, collection)
		set searchFromCollection = query (getContentModel(), qobj, ContentInRepository, collection)
   end function
       
    public function getContentModel()           'IMetisObject
        dim context
        ' Find ContentModel
        set getContentModel = model
        set context = new EKA_Context
        set context.currentModel        = model
        set context.currentModelView    = modelView
        'set context.currentInstance     = work_window.instance
        'set context.currentInstanceView = work_window
        if isValid(context) then
            set getContentModel = context.contentModel
            ContentInRepository = context.isRepository
        end if
        if not isEnabled (getContentModel) then
			dim x, y
			for each x in model.views ' find model view called content ...
				if (instr(1, x.title, "content", 1) >0) or (instr(1, x.title, "main", 1) >0) or (instr(1, x.title, "data", 1) >0) then
					for each y in x.children ' find child which is submodel
						if y.instance.type.uri = "metis:stdtypes#oid125" then
							set getContentModel = y.instance.parts(1)
							exit function
						end if
					next
				end if
			next
        end if
        if not isEnabled (getContentModel) then
			set getContentModel = model
			ContentInRepository = false
		end if
    End function
       
        
    private function query (contentmodel, queryobject, repository, selected)
   ' stop
		set query = Nothing
        dim rel, relships, relList, pathList, pathRel, pathObj
        dim inst, insts, instances
        dim instType
        dim childView, children
        dim contView
        dim propVal
        dim i, j, rule
        dim typeList, typeInstances
       
        applyFilter = false
        set isTopType              = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasValueType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set hasValueConstraintType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
        
        noRelTypes = 3
        ReDim Preserve relTypeList(noRelTypes)
        set relTypeList(1)   = isTopType
        set relTypeList(2)   = hasValueType
        set relTypeList(3)   = hasValueConstraintType
        
        noTopObjectRules     = 0
        noPathRules          = 0
        noFilterRules        = 0
        noRelRules = 0
        
        set filterObjectView = Nothing   
        
        hasTopInstance = false
        if not isEnabled(queryobject) then
            exit function
        end if
        
        set relships = queryobject.getNeighbourRelationships(0, isTopType)
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
			set relships = queryobject.getNeighbourRelationships(0, Config.VIType) ' HDJ added
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
				set children = queryobject.views(1).children
				for each childView in children
					set inst = childView.instance
					if isEnabled(inst) and not inst.isRelationship then
						set instType = inst.type
						if isEnabled(instType) then
						call buildInstRules(inst, objectRules, noObjectRules, hasValueConstraintType)
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
        end if
        
        ' Find filter specification
        if isValid(filterObjectView) then
            set children = filterObjectView.children
            if isValid(children) then
				applyFilter = true
                for each childView in children
                    if hasInstance(childView) then
                        set inst = childView.instance
                        if isEnabled(inst) and not inst.isRelationship then
                            call buildInstRules(inst, filterRules, noFilterRules, hasValueConstraintType)
                        end if
                    end if
                next
            end if
        end if
        

        ' Now all content specification rules are captured
        ' Go on to finding the instances
        set instances = nothing
        if isValid(selected) then
			if selected.count > 0 then
				set instances = selected
			end if
		end if
		
		if not isValid(instances) then
		    set instances        = metis.newInstanceList
			if repository then
				set instances = getInstancesFromRepository(instances, contentmodel)
			else
				set instances = getInstancesFromClient(instances, hasTopInstance, filterRules, noFilterRules, contentmodel)
			end if
		end if
        
        
        if noPathRules > 0 then 'used to be rel
            ' Find the relationships
            dim k
            for j = 1 to 3 ' max number of links to traverse
				k = instances.count
                for i = 1 to noPathRules
                    set rule = pathRules(i)
                    if isValid(rule) and isValid (instances) then
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
                if k >= instances.count then ' no new elements added ...
					exit for
                end if
            next
        end if
		set query = instances 
    End Function
    
    
    '-----------------------------------------------------------
    Private Function getInstancesFromClient(instances, hasTopInstance, filterRules, noFilterRules, contentModel)
        dim cvwSelectDialog, cvwFilter
        dim rule
        dim inst, insts
        dim typeInstances, typeList
        dim pathList, pathObj, pathRel, relList
        dim isValid1
        dim i, j

        set getInstancesFromClient = instances
        if noTopObjectRules > 0 then
            if hasTopInstance then
                instances.addLast topInstance
            else
                if applyFilter then
                    set cvwFilter = new CVW_Filter
                end if
                for i = 1 to noTopObjectRules
                    set rule = topObjectRules(i)
                    if isValid(rule) then
                        set insts = findConstrainedInstances(rule, contentModel)
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
                    set insts = findConstrainedInstances(rule, contentModel)
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
                set instances = insts
            end if
        end if
        set getInstancesFromClient = instances
    End Function

'-----------------------------------------------------------
    Private Function getInstancesFromRepository(instances, topObjectRules, noTopObjectRules, contentModel)
        dim rule
        dim inst, insts
        dim i

        set getInstancesFromRepository = instances
        if noTopObjectRules > 0 then
            for i = 1 to noTopObjectRules
                set rule = topObjectRules(i)
                if isValid(rule) then
                    set insts = findRepositoryInstances(rule, contentModel)
                    if isValid(insts) then
                        set insts = findConstrainedInstances(rule, contentModel)
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
                    set insts = findRepositoryInstances(rule, contentModel)
                    if isValid(insts) then
                        set insts = findConstrainedInstances(rule, contentModel)
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
                set instances = insts
            end if
        end if
    End Function
    
    
'-----------------------------------------------------------
    Private Function findRepositoryInstances(rule, contentModel)
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
		set findRepositoryInstances = model.runMethodOnInst1(tqlMethod1, contentModel).getCollection
    End Function
    '-----------------------------------------------------------
    
     Private Function findConstrainedInstances(rule, contentModel)
        dim instType, insts, inst
        dim relships, rels, rel
        dim prop, propName, propValue, value
        dim datatype, operator
        dim cvwFilter
        dim i, removed

        set findConstrainedInstances = Nothing
        if isValid(rule) and isEnabled(contentModel) then
            set metis.currentModel = model
            set metis.currentModel.currentModelView = modelView
            if rule.operator = "eq" then
                set insts = findParts(contentModel, contentModel, rule.instType, rule.propname, rule.propvalue)
            end if
            if not isValid(insts) then
                set insts = findParts(contentModel, contentModel, rule.instType, "", "")
                if insts.count > 0 then
                    set cvwFilter = new CVW_Filter
                    for each inst in insts
                        i = 1
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
    Private Function findRelationships(relList, objects, rule) ' HDJ alterned, also add neighbour objects according to the rules
        dim obj, other
        dim rel, rels
        dim indx
        dim type1, type2

        for each obj in objects
            set rels = obj.neighbourRelationships
            if isValid(rels) then
                for each rel in rels
                   if rel.origin.uri = obj.uri then
						set other = rel.target
                    else
						set other = rel.origin
                    end if
                    if rule.relDir = 0 then
                        set type1 = rule.parentType
                        set type2 = rule.childType
                    else
                        set type1 = rule.childType
                        set type2 = rule.parentType
                    end if
                    if rel.type.uri = rule.relType.uri then
                        if isType(rel.origin, type1)  then
                            if isType(rel.target, type2)  then
								if not instanceInList(other, objects) then
									relList.addLast other
								end if
                                if not instanceInList(rel, relList) then
                                    relList.addLast rel
                                end if
                            end if
                        end if
                    end if
                next
            end if
        next
        set findRelationships = relList
    End Function
    
     '---------------------------------------------------------------------------------------------------
    private Sub Class_Initialize
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set inst            = model.currentInstance
        set instView        = modelView.currentInstanceView
        ContentInRepository = false
   End Sub
   '---------------------------------------------------------------------------------------------------

End Class
