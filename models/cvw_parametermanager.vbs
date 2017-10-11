option explicit
Class CVW_ParameterManager
	private currentConfig
	private inh
	    
	Private model
    Private modelView
    Private inst
    Private instView
    
        ' Types
    public ElementType
	public PropertyType
    public ConsistsOfType
	public HasPropertyType			' inherits ConsistsOfType
	public HasValueType			' inherits HasPropertyType
	public HasParameterType		' inherits HasPropertyType
	public HasAllowedValueType		' inherits ConsistsOfType
	
	' properties for Property objects
	private PropType
	private PropValue
	private PropDerivedValue
	
	' properties for Parameter relationship
	private PropertyInput
	private PropertyOutput
	private PropertyMandatory
	private PropertyMultiple    
    
    Public Property Get config        'IRTV_Config
		if not isValid(currentConfig) then
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
			set inh = currentConfig.inheritance
			set inheritance = inh
		end if
    End Property

    Private Property Set inheritance(obj)
        if isValid(obj) then
            set inh = obj
        end if
    End Property
     
     private function valid(x) 
		valid = true
		if isObject(x) then
			valid = isValid(x)
		else 
		    if isEmpty(x) then
				valid = false
			elseif isNull(x) then
				valid = false
			elseif len(trim(x)) <= 0 then
				valid = false
			end if
		end if
     end function
     
     '  returns the value of the parameter, either an object or a string, given the current context
     public function getValue(name)
		if not getValueForObject(Config.Info, name, getValue) then
			if not getValueForObject(Config.Task, name, getValue) then
				if not getValueForObject(Config.Role, name, getValue) then
					if not getValueForObject(Config.View, name, getValue) then
						if not getValueForObject(GLOBAL_User, name, getValue) then
							if not getValueFromSupers(Config.Info, name, getValue) then
								if not getValueFromSupers(Config.Task, name, getValue) then
									if not getValueFromSupers(Config.Role, name, getValue) then
										if not getValueFromSupers(Config.View, name, getValue) then
											if not getValueFromSupers(GLOBAL_User, name, getValue) then
												getValue = "" ' no value found in context
											end if 
										end if
									end if
								end if
							end if
						end if
					end if
				end if
			end if
		end if
     end function
     
     private sub makeSubstitutions(byref value) 
     
		if not isObject(value) then
			dim i,j, s, p, o, v 
			i = instr(value, "$") ' start of substitution area
			s = value
			while i > 0 ' more substitutions 
				j = instr(i+1, s, "$", 1) ' end of substitution area
				if j <= 0 then 
					j = len(s) +1
				end if
				p = mid(s, i+1, j-i-1) ' parameter to subsitute in
				v = p 'value to subsitute in
				o = ""
				if instr(p,".") then ' separates object from parameter in parameter
					o = mid(p, 1, instr(p,".") -1)
					p = mid(p, instr(p,".") +1) ' parametername
				end if
				if strcomp(o, "Info", 1) and isValid(Config.Info) then ' obj to get subsisution value from is the context info object
					if not getValueForObject(Config.Info, p, v) then
						 v =""
					end if
				elseif strcomp(o, "Role", 1) and isValid(Config.Role)then
					if not getValueForObject(Config.Role, p, v) then
						 v =""
					end if
				elseif strcomp(o, "User", 1) and isValid(GLOBAL_User)then
					if not getValueForObject(GLOBAL_User, p, v) then
						 v =""
					end if
				elseif strcomp(o, "Task", 1) and isValid(Config.Task)then
					if not getValueForObject(Config.Task, p, v) then
						 v =""
					end if
				elseif strcomp(o, "View", 1) and isValid(Config.View)  then
					if not getValueForObject(Config.View, p, v) then
						 v =""
					end if
				else 
					v = getValue(p)
				end if
				if isObject(v) then
					v = v.uri
				end if
				value = mid(s, 1, i-1) & v & mid(s, j+1) ' make substitution
				s = value
				i = instr(j+1, s, "$")
			wend
		end if
     end sub
     
      '  returns the value of the parameter, either an object or a string, given the current context
     public function getValueFromSupers(obj, name, byref value)
     	getValueFromSupers = false ' no value found in context
		if isValid(obj) then
			dim o
			for each o in inheritance.supers(obj)
				if getValueForObject(o, name, value) then
					getValueFromSupers = true 
'msgbox obj.title&"(inherited from "&o.title&")."&name&" = "&value
					exit function
				end if
			next
		end if
     end function
     
     
     '  finds the value of the parameter, either an object or a string, for the given object or one that it inherits from. Returns true if found
     public function getValueForObject(object, name, byref value)
		on error resume next
		if not isValid(object) then
			getValueForObject = false
'msgbox object.title&"."&name&" = " &value.title
			exit function
		end if
		getValueForObject = true
		set value = Nothing 
		value = getStringValueForObject(object,name)
		if valid(value) then
'msgbox object.title&"."&name&" = " &value
			exit function
		end if
		Set value = getObjectValueForObject(object,name)
		if isEnabled(value) then 
'msgbox object.title&"."&name&" = " &value.title
			exit function
		end if
'msgbox object.title&"."&name&" = " &value
		getValueForObject = false ' in case no value found
     end function
     
    ' find a value of the given parameter for the given object, not using inheritance, but traversing direct relationships from the 
    ' property object to other property objects 
    private function getStringValueForObject(object, name)
		on error resume next
		dim props, prop
        getStringValueForObject = ""
      		
        if name = "" then ' this is a recursive call, any value explicitly linked to another property will be used
			getStringValueForObject = getStringPropertyValue(object)
            if valid(getStringValueForObject) then
				makeSubstitutions(getStringValueForObject)
				exit function
			end if
		else 
		    getStringValueForObject = object.getNamedStringValue(name)
			if valid (getStringValueForObject) then
				makeSubstitutions(getStringValueForObject)
				exit function
			end if
        end if 
        
        set props = object.getNeighbourObjects(0, HasPropertyType, Nothing)
        for each prop in props
            if (prop.name = name) or (name = "") then
                getStringValueForObject = getStringPropertyValue(prop)
                if valid(getStringValueForObject) then
					makeSubstitutions(getStringValueForObject)
					exit function
				end if
				if inheritsType(prop, PropertyType, inheritance) then
					getStringValueForObject = getStringValueForObject(prop, "") ' recursive 
					if valid(getStringValueForObject) then
						makeSubstitutions(getStringValueForObject)
						exit function
					end if
				end if
            end if
        next
    End function
    
        ' find a value of the given property, using inheritance among properties
    private function getStringPropertyValue(prop)
    	on error resume next
		getStringPropertyValue = prop.getNamedStringValue(PropValue)
		if not valid(getStringPropertyValue) then ' check if the property inherits from somewhere explicitly
			dim p, props
			set props = inheritance.supersUntilRoot(prop, PropertyType)
			for each p in props
				getStringPropertyValue = prop.getNamedStringValue(PropValue)
				if valid(getStringPropertyValue) then
					exit function
				end if
			next
		end if 
    End function
    
    
    ' find a value of the given parameter for the given object, not using inheritance, but traversing direct relationships from the 
    ' property object to other property objects 
    private function getObjectValueForObject(object, name)
		on error resume next
		dim props, prop
        set getObjectValueForObject = Nothing
        		  
        set props = object.getNeighbourObjects(0, HasPropertyType, Nothing)
        for each prop in props
            if (prop.name = name) or (name = "") then
                set getObjectValueForObject = getObjectPropertyValue(prop)
                if isEnabled(getObjectValueForObject) then
					exit function
				end if
				if inheritsType(prop, PropertyType, inheritance) then
					set getObjectValueForObject = getObjectValueForObject(prop, "") ' recursive 
					if isEnabled(getObjectValueForObject)  then
						exit function
					end if
				end if
            end if
        next
    End function
    
     ' find a value of the given property, using inheritance among properties
    private function getObjectPropertyValue(prop)
		on error resume next
    	dim v, values
    	set getObjectPropertyValue = Nothing
    	set values = prop.getNeighbourRelationships(0, HasValueType)
    	for each v in values 
    		set getObjectPropertyValue = v.target
    		if isEnabled(getObjectPropertyValue) then
    			exit function
    		end if
    	next
		dim props, p
		set props = inheritance.supersUntilRoot(prop, PropertyType)
		for each p in props
			set values = p.getNeighbourRelationships(0, HasValueType)
    		for each v in values 
    			set getObjectPropertyValue = v.target
    			if isEnabled(getObjectPropertyValue) then
    				exit function
    			end if
    		next
		next
    End function
    
           
 private Sub Class_Initialize
    set model           = metis.currentModel
    set modelView       = model.currentModelView
    set inst = model.currentInstance
	set instView        = modelView.currentInstanceView

    ' Types
    set ElementType		= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_element.kmd#ObjType_EKA:Element_UUID")
	set PropertyType	= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
    set ConsistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
	set HasPropertyType	= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
	set HasValueType	= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
	set HasAllowedValueType	= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasAllowedValue_UUID")
	set HasParameterType= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/has_parameter.kmd#Has_parameter")
	
	PropType = "datatype"
	PropValue = "value"
	PropDerivedValue = "tempvalue"
	
	PropertyInput = "input"
	PropertyOutput = "output"
	PropertyMandatory = "mandatory"
	PropertyMultiple = "multiple_values"
	
    set currentConfig = Nothing

        
 end sub 
end class