option explicit
' This class handles inheritance of e.g. configurations and property values. It performs lookup according to:
' - Explicitly modelled IS-telationships between instances
' - Types of the instances (and those they inherit from according to other rules
' - Explicit Is-relationships between instance objects that are placeholder for a type. 
'      - These are recognised by the fact that they have the same name as the type, and their type is either one of the basic IRTV types of the type they represent (type name = instance name)

dim GLOBAL_InheritanceCache '--- cache that links metis instances to a collection of the instance it inherits from
dim GLOBAL_TypeRepresentatives '--- cache that links metis types to the instance that represents it and which confioguration data may be associated with
dim GLOBAL_ConfigModel ' --- the model that contains EKA basic definitions etc.

Class EKA_Inheritance
	public InheritanceRelType
	public EqualsType
	public ConsistsOfType
	public ElementType
	
	public model
    public modelView
    public inst
    public instView

	' Elements that get true from this function implies that e.g. no task should be performed or no view shown:
	public function isNothing(byval obj)
		isNothing = false
		on error resume next
		if not isValid(obj) then
			isNothing = true
			exit function
		end if
		if instr(1,obj.title, "No ", 1) = 1 then
			isNothing = true
			exit function
		end if
		if instr(1,obj.title, "Nothing", 1) = 1 then
			isNothing = true
			exit function
		end if
		if instr(1,obj.title, "Empty", 1) = 1 then
			isNothing = true
			exit function
		end if
		if instr(1,obj.title, "Null", 1) = 1 then
			isNothing = true
			exit function
		end if
	end function
	

	public function supers(byval obj)
		set supers = supersUntilRoot(obj, Nothing)
	end function
	
	' return all the elements that obj inherits from, but do not go further than the given root type
	public function supersUntilRoot(byval obj, byval rootType)
		dim s, i
		if GLOBAL_InheritanceCache.Exists(obj.uri) then
			set supersUntilRoot  = GLOBAL_InheritanceCache.Item(obj.uri)
		else
			set supersUntilRoot = metis.newInstanceList()
			call appendSupers(obj, supersUntilRoot, "")
		end if
		if isValid(rootType) then  ' filter by type
			set s = supersUntilRoot
			set supersUntilRoot = metis.newInstanceList()
			for each i in s			
				if isType(i,rootType) then
					call supersUntilRoot.AddLast(i)
				end if
			next
		end if
	end function
	
	' clears the cache
	public function reset()
		set GLOBAL_InheritanceCache = Nothing
		set GLOBAL_InheritanceCache = CreateObject("Scripting.Dictionary")
		set GLOBAL_TypeRepresentatives = Nothing
		set GLOBAL_TypeRepresentatives = CreateObject("Scripting.Dictionary")
	end function
	
	' returns the elements added to list
	private function appendSupers(byval obj, byref list, byval handledTypes)
		on error resume next
		dim  rel, target, rels
		dim recursive, t
		if not isEnabled(list) then
			set list = metis.newInstanceList()
		end if
		if GLOBAL_InheritanceCache.Exists(obj.uri) then
			for each target in GLOBAL_InheritanceCache.Item(obj.uri)
				if not list.contains(target) then
					call list.AddLast(target)
				end if
			next 
			set appendSupers = GLOBAL_InheritanceCache.Item(obj.uri)
		else
			set appendSupers = metis.newInstanceList()
			set rels = obj.getNeighbourRelationships(0, InheritanceRelType)
			for each rel in rels
				set target = rel.target
				if not list.contains(target) then
					call list.AddLast(target)
				end if
			next
			for each rel in rels
				set target = rel.target
				if not appendSupers.contains(target) then
					call appendSupers.AddLast(target)
					set recursive = appendSupers(target, list, handledTypes)
					for each t in recursive
						if not appendSupers.contains(t) then
							call appendSupers.AddLast(t)
						end if
					next 
				end if		
			next
					' prevent recursion:
			if (instr(handledTypes, obj.type.title) <= 0) and (not appendSupers.contains(obj)) then
				set recursive = appendTypeSupers(obj, list, handledTypes)
				for each t in recursive
					if not appendSupers.contains(t) then
						call appendSupers.AddLast(t)
					end if
				next 
			end if
			call GLOBAL_InheritanceCache.Add(obj.uri, appendSupers)
		end if
		
	end function
	
	' returns the elements added to list
	private function appendTypeSupers(byval obj, byref list, byval handledTypes)
		on error resume next
		dim typerep, t, typereps, found
		dim recursive
								
		handledTypes = handledTypes & obj.type.title ' prevent recursion
			
		' find type representative if it exists, and add the elements that it inherits from
		set typereps = representatives(obj.type)
		if not isValid(typereps) then 
			set appendTypeSupers = metis.newInstanceList()
			exit function
		end if
		if typereps.count = 0 then 
			set appendTypeSupers = metis.newInstanceList()
			exit function
		end if
'		if typereps.contains(obj) then ' prevent extra recursion if the obj is itself a typerep..
'			dim trt
'			set trt = metis.newInstanceList()
'			for each t in typereps
'				if (t.uri <> obj.uri) then
'					call trt.AddLast(t)
'				end if
'			next
'			set typereps = trt
'		end if
		found = false
		if isEnabled(typereps) then
			set appendTypeSupers = metis.newInstanceList()
			for each typerep in typereps
				found = true
				if not list.contains(typerep) then
					call list.AddLast(typerep)
				end if
				if (typerep.uri <> obj.uri) and not appendTypeSupers.contains(typerep) then
					call appendTypeSupers.AddLast(typerep)
					if GLOBAL_InheritanceCache.Exists(typerep.uri) then
						for each t in GLOBAL_InheritanceCache.Item(typerep.uri)
							if not list.contains(t) then
								list.AddLast(t)
							end if
							if not appendTypeSupers.contains(t) then
								call appendTypeSupers.AddLast(t)
							end if
						next 
					else
						set recursive = appendSupers(typerep, list, handledtypes)
						for each t in recursive
							if not appendTypeSupers.contains(t) then
								call appendTypeSupers.AddLast(t)
							end if
						next
					end if
				end if
			next
		end if
		if found then ' supers already found and handled
			exit function
		end if
		' handle supertypes recursively
		set t = obj.type
		set typereps = Nothing
		while (not isEnabled(typereps)) and isEnabled(t)
			set t = t.baseType
			set typereps = representatives(t)
		wend
		if isEnabled(typereps) then
			if not isValid(appendTypeSupers) then
				set appendTypeSupers = metis.newInstanceList()
			end if
			for each typerep in typereps
				if not list.contains(typerep) then
					call list.AddLast(typerep)
				end if
				if (instr(handledTypes, obj.type.title) <= 0) and not appendTypeSupers.contains(typerep) then
					call appendTypeSupers.addLast(typerep)
					set recursive = appendTypeSupers(typerep, list, handledtypes)
					if isValid(recusive) then
						for each t in recursive
							if not appendTypeSupers.contains(t) then
								call appendTypeSupers.AddLast(t)
							end if
						next 
					end if
				end if
			next
		end if
		call GLOBAL_InheritanceCache.Add(obj.uri, appendTypeSupers)
	end function
		
		' returns the first object which has the same name (preferably type) as the type. 
		' These objects are used for associating properties and configurations to all objects of the type.
	public function representative(byval aType)
		on error resume next
		dim reps, o, r
		set reps = Nothing
		set reps = representatives(aType)
		set representative = Nothing
		if isValid(reps) then
			set representative = reps(1)
		end if
	end function
	
		' returns  all objects that have the same name (preferably type) as the type. 
		' These objects are used for associating properties and configurations to all objects of the type.
	public function representatives(byval aType)
		dim o, tt
		on error resume next
		if GLOBAL_TypeRepresentatives.Exists(aType.uri) then
			set representatives = GLOBAL_TypeRepresentatives.Item(aType.uri)
			exit function
		end if
		set representatives = Nothing
'stop
		set representatives = findAll(aType, aType.title)
		if not isValid(representatives) then
			set metis.currentModel = GLOBAL_ConfigModel
			set representatives = findAll (aType, aType.title)
			set metis.currentModel = model
		elseif representatives.count = 0 then
			set metis.currentModel = GLOBAL_ConfigModel
			set representatives = findAll (aType, aType.title)
			set metis.currentModel = model
		else
			set metis.currentModel = GLOBAL_ConfigModel
			for each o in findAll(aType, aType.title)
				if not representatives.contains(o) then 
					call representatives.AddLast(o)
				end if
			next
			set metis.currentModel = model
		end if
		if isValid(representatives) then
			call GLOBAL_TypeRepresentatives.Add(aType.uri, representatives)
			'tt = "        "
			'for each o in representatives
			'	tt = tt + ", " + o.uri
			'next
			'msgbox aType.title& " has "& representatives.count & " representatives: " +tt
		end if
		if isEnabled(representatives)  then 
			if representatives.count = 0 then ' no found
				set representatives = Nothing
			end if
		end if
	end function
	
	
	'find an  object with the type and name in the current model
	private function find(aType, name)
		Dim o
		set find = Nothing
		for each o in metis.currentModel.findInstances(aType, "name", name)
			if isValid(o) then
				set find = o
				exit function
			end if
		next
		for each o in metis.currentModel.findInstances(ElementType, "name", name)
			if isValid(o) then
				set find = o
				exit function
			end if
		next
	end function
	
		'find an  object with the type and name in the current model
	private function findAll(aType, name)
		Dim o
		set findAll = Nothing
		set findAll = metis.currentModel.findInstances(aType, "name", name)
		if not isValid(findAll) then
			set findAll = metis.currentModel.findInstances(ElementType, "name", name)
		else
			for each o in metis.currentModel.findInstances(ElementType, "name", name)
				if isValid(o) then
					if o.type.uri = ElementType.uri then
						if not findAll.contains(o) then 
							call findAll.AddLast(o)
						end if
					end if
				end if
			next
		end if
	end function
	
    private Sub Class_Initialize
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set inst            = model.currentInstance
        set instView        = modelView.currentInstanceView
        set InheritanceRelType			= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
        set EqualsType		= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Equals_UUID")
        set ConsistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set ElementType		= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_element.kmd#ObjType_EKA:Element_UUID")
        'set GLOBAL_ConfigModel = metis.findInstance("http://xml.activeknowledgemodeling.com/cvw/templates/irtv.kmv#_002as5401d4bqcg5f0b3")
        if not isEnabled(GLOBAL_ConfigModel) then
'stop
			set GLOBAL_ConfigModel = metis.load("http://xml.activeknowledgemodeling.com/cvw/templates/irtv.kmv")
			set metis.currentModel = model ' reset after load
			set metis.currentModel.currentModelView = modelView
			'set GLOBAL_ConfigModel = metis.findInstance("http://xml.activeknowledgemodeling.com/cvw/templates/irtv.kmv#_002as5401d4bqcg5f0b3")
        end if 
        if not isValid(GLOBAL_InheritanceCache) then
			set GLOBAL_InheritanceCache = CreateObject("Scripting.Dictionary")
        end if
        if not isValid(GLOBAL_TypeRepresentatives) then
			set GLOBAL_TypeRepresentatives = CreateObject("Scripting.Dictionary")
		end if
    end sub
       
End Class