option explicit

Class CVW_ViewManager
	private currentConfig
	private params
	private inh
	
	Private model
    Private modelView
    Private inst
    Private instView
    public WorkAreaType

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
			set currentConfig  = new IRTV_Config
			set inh = currentConfig.inheritance
			set inheritance = inh
		end if
    End Property

    Private Property Set inheritance(obj)
        if isValid(obj) then
            set inh = obj
        end if
    End Property
    
    Public Property Get parameters     
		if not isValid(params) then 
			set params = new CVW_ParameterManager
			set params.config = config
		end if
        set parameters = params
    End Property

    Public Property Set parameters(obj)
        if isValid(obj) then
			set params = obj
            set config = params.config
            set inheritance = config.inheritance
		end if
    End Property
    
    
    ' This is the main body, updating the view after the task has been performed.
    ' For some tasks, no view will be shown (e.g. for serverside tasks such as web services)
    public sub show(irtvconfig)
		set config = irtvconfig
'stop		
		if not isValid(config) then 
			exit sub ' do nothing
		end if
		if not isValid(config.View) then 
msgbox "No view configured for "&Config.Info.title
			exit sub ' else no view given, ignore
		end if
		if inheritance.isNothing(config.View) then ' name signifies that nothing should be shown
msgbox "The system is configured to show nothing for "&Config.Info.title
			exit sub 
		end if 
	
		if inheritsType(inst, Config.ViewType, inheritance) then ' doubleclicked on view, open/close
			metis.currentModel.runmethod(metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/view_methods.kmd#Method_CVW:openClose_UUID"))
		elseif inheritsType(config.View, WorkAreaType, inheritance) then ' open or reuse workarea
			Dim workarea
			set workarea = new CVW_GenericWorkarea
	        set workarea.parameters = parameters
	        
	        'dim  obje, objeview
			'dim comp,configObject
	        'set configObject = metis.findInstance("file:///C|/hdj/projects/hydro/cvw_irtv_actions.kmv#_002ask601qg9chuuv6pd") ' Config.view
			'set comp = metis.findInstance("http://xml.activeknowledgemodeling.com/cvw/templates/cvw_component_library.kmv#_002ask501ree8thu0icl")
			
			' Configure workarea
			'call resetCVWcomponent(comp)
			'call configureCVWcomponent(configObject, comp, false)
			' Build and execute
			'set workarea.currentModel = model
			'set workarea.currentModelView = modelView
			'set workarea.currentInstance = inst
			'set workarea.currentInstanceView = model.currentModelView.currentInstanceView
			'set workarea.contextInstance = Context.Info
			'set workarea.component = comp
			'set workarea.configObject = configObject
			
			'if applyFilter then
			'    cvwWorkarea.applyFilter = true
			'end if
			call workarea.build  ' Build internal structures
			call workarea.configure
			workarea.title = inst.getNamedStringValue("name") 
			'if isEnabled(  Config.View) then
			'	workarea.LanguageModel =  Config.View.uri
			'end if
			call workarea.execute                ' Execute: Builds workarea (as an empty window w titlebar)
'stop
			'if isType(config.Info, config.ViewType) then
			dim ok, value
			ok = false
			ok = parameters.getValueForObject(config.View, "ContentSpecification_Model", value)
			if not ok then 
				on error resume next
				set value = parameters.getValue("ContentSpecification_Model")
				if isObject(value) and isEnabled(value) then
					ok = true
				end if
			end if
			if ok then ' the view specifies a search
				call populateByQuery(value, workarea)
			elseif isType(config.Info, config.ViewType) then ' no search specified and handled above, copy content
				ok = copyView(config.Info, workarea)
			else
				call populateByQuery(Config.View, workarea)
			end if
			'call workarea.doParentLayout
			modelView.clearSelection
		else
		msgbox "Showing nothing for "&Config.Info.title
		end if
		
    end sub
    
    	'---------------------------------------------------------------------------------------------------	
	public sub populateByQuery(query, workarea)
		dim instances, obj, objects, origin, target, col, parentview
		if isType(query, Config.ViewType) then
			set parentView = workarea.WorkWindow
			Dim s
			set s = new CVW_GenericSearch
			set s.config = config
			
			if isEnabled(Config.Infos) then
				set col = metis.newInstanceList()
				for each obj in Config.infos
					call col.addLast(obj.target)
				next
			else
				set col = metis.newInstanceList()
				call col.addLast(Config.Info)
			end if
	'stop
			set instances = s.searchFromCollection(query, col)
		else ' solution by Dag:
			'call resetCVWcomponent(query)
			'call configureCVWcomponent(query, workarea, false)
			' Build and execute
			dim cvwContentSpec
			set cvwContentSpec = new CVW_ContentSpecification
			set cvwContentSpec.currentModel     = Model
			set cvwContentSpec.currentModelView = ModelView
			set cvwContentSpec.component    = query 'workarea.WorkWindow
			set cvwContentSpec.configObject = query
			set cvwContentSpec.contentModel = workarea.ContentModel
			cvwContentSpec.RepositoryConnection = workarea.ContentInRepository
			cvwContentSpec.PathMode = "Path"
			cvwContentSpec.noLevels = 5
			if workarea.applyFilter then
				cvwContentSpec.applyFilter = true
			end if
			call cvwContentSpec.build                   ' Build internal structures
			call cvwContentSpec.IRTVconfigure(parameters)
			set instances = cvwContentSpec.execute             ' Execute methods dependent on configuratio
        
		end if
		
		'set objects = metis.newInstanceViewList()
		'For each obj in instances
		'	if not obj.isRelationship() then
		'		set s = parentView.newObjectView(obj)
		'		call objects.AddLast(s)
		'	end if
		'next
		call workarea.populate(instances, 1)
'		For each obj in instances
'			if obj.isRelationship() then
'				set origin = nothing
'				set target = nothing
''				for each s in objects
'					if s.instance.uri = obj.target.uri then
'						set target = s
''					elseif s.instance.uri = obj.origin.uri then
'						set origin = s
'					end if
'				next
'				if isEnabled(origin) and isEnabled(target) then
'					set s = metis.currentModel.currentModelview.newRelationshipView(obj, origin, target)
'				else
'					msgbox "Failed to create view for "& obj.origin.title&" ----"&obj.type.title&"----> "& obj.target.title
'				end if
'			end if
'		next
	end sub
	
   ' copy the view linked to by the button clicked into a new workarea
	public function copyView(v, wa)
		dim objeview
		copyView = true
	
		if v.views.count <=0 then
			exit function
		end if
		set objeview = v.views(1)
		
		'msgbox ("Object: " & objeview.children.count &" parts.  Menu: "& instView.children.count &" parts.")
		'if (objeview.children.count - instView.children.count) > instView.children.count then ' more than half the elements where not shown in the menu, open view		
			'call initialize(obje)
			call wa.copyViewToWorkarea(objeview)
		'end if	
		'call wa.children(2).children(wa.children(2).children.count).open()
	end function
    
 private Sub Class_Initialize
    set model           = metis.currentModel
    set modelView       = model.currentModelView
    set inst            = model.currentInstance
    set instView        = modelView.currentInstanceView
    set WorkAreaType	= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
    set currentConfig = Nothing
 end sub
	
End class