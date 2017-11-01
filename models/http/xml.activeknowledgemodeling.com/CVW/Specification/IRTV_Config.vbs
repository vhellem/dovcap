option explicit

dim GLOBAL_Object
dim GLOBAL_User
dim GLOBAL_Task
dim GLOBAL_View

Class IRTV_Config
	'--- types (root/basis types) for each dimension
	public InfoType
	public RoleType
	public UserType
	public TaskType
	public ViewType
	'--- reltypes (root/basis types) for connections betwwen each dimension pair
	public RIType
	public RTType
	public RVType
	public TVType
	public TIType
	public VIType
	public ITType
	public RootRelType
	public Workspace 'CVW_Workspace
			
	'--- instance elements used for finding the configurations
	public Info ' element or connection
	public Role ' roles of GLOBAL_User in context
	public Task ' task to perform
	public View ' View to perform the task in (could be new workarea ...)
	' in case there is more than one, only infos used so far (for task with multiple contents ...
	public Infos ' element or connection
	public Roles ' roles of GLOBAL_User in context
	public Tasks ' task to perform
	public Views ' View to perform the task in (could be new workarea ...)	

	public model
    public modelView
    public inst
    public instView
    public inheritance
	
	' ---- Sets the IRTV elements of the current context. The current IRTV element should
	public sub establishIRTVContext(current, recursive)
		dim cur, inherits, o, i
        if not isValid(GLOBAL_User) then
			set GLOBAL_User = findUser()
        end if
        '1st set everything explicitly related to the trigger element (direct parameters)
        for each o in current.getNeighbourRelationships(0, RootRelType)
             if not isValid(Task) then
				if isType(o.target, TaskType) then 
					set Task = o.target
				end if 
            end if
            if not isValid(Role) then
				if isType(o.target, Roleype) then 
					set Role = o.target
				end if 
            end if
            if not isValid(View) then
				if isType(o.target, ViewType) then 
					set View = o.target
				end if 
            end if
        next
        for each o in current.getNeighbourRelationships(1, RootRelType)
			if not isValid(Task) then
				if isType(o.origin, TaskType) then 
					set Task = o.origin
				end if 
            end if
            if not isValid(Role) then
				if isType(o.origin, Roleype) then 
					set Role = o.origin
				end if 
            end if
            if not isValid(View) then
				if isType(o.origin, ViewType) then 
					set View = o.origin
				end if 
            end if
        next
        set cur = getEqualObject(current)
'msgbox "Direct neighbours scanned for "&cur.title&":"&current.uri&"->"&cur.uri
'stop
        if isType(cur, TaskType) then
			if not isValid(Task) then
				set Task = cur
			end if
			configureFromTask(cur)
		elseif isType(cur, ViewType) then
			if not isValid(View) then
				set View = cur
			end if
			configureFromView(cur)
		elseif isType(cur, RoleType) then
			if not isValid(Role) then
				set Role = cur
			end if
			configureFromRole(cur)
		else ' assume the current object is information
			if not isValid(Info) then
				set Info = cur
			end if
			configureFromInfo(cur)
        end if
'msgbox "Configuration without inheritance completed."
        if not recursive then
			exit sub
		end if
        if not (isValid(Info) and isValid(Role) and isValid(Task) and isValid(View)) then ' use inherited values
			set inherits = Nothing
			if isValid(Info) then 
				if cur.uri = Info.uri then
					set inherits = inheritance.supers(Info)
				end if
			end if
			if isValid(Role) then 
				if  cur.uri = Role.uri then
					set inherits = inheritance.supersUntilRoot(Role, RoleType)
				end if
			end if
			if isValid(Task) then 
				if  cur.uri = Task.uri then
					set inherits = inheritance.supersUntilRoot(Task, TaskType)
				end if
			end if
			if isValid(View) then 
				if  cur.uri = View.uri then
					set inherits = inheritance.supersUntilRoot(View, ViewType)
				end if
			end if
			i = 1
			on error resume next
dim msg	
'msg = "Inheriting from " &vbcrlf
			if isValid(inherits) then 
				while (i <= inherits.count) and not (isValid(Info) and isValid(Role) and isValid(Task) and isValid(View))
					set o = inherits(i)
'msg = msg & o.title&" ("&o.uri&"), ("&i&" of "&inherits.count&")" &vbcrlf
					call establishIRTVContext(o, false)
					i = i +1
				wend
'msgbox msg
			end if
        end if
	end sub 

' returns relationship between task and role
	public function getRoleInTask(r, t)
		on error resume next
		set getRoleInTask = Nothing
		if not isValid(t) then
			exit function
		end if
		if not isValid(r) then
			exit function
		end if
		dim inherits, ro
		set inherits = inheritance.supersUntilRoot(r, RoleType)
		for each ro in t.getNeighbourRelationships(1, RTType)
			if r = ro.origin then 
				set getRoleInTask = ro
				exit function
			end if
			if inherits.contains(ro.origin) then 
				set getRoleInTask = ro
				exit function
			end if
		next
	end function
	
	public function getRoleOn(r, e)
		on error resume next
		set getRoleOn = Nothing
		if not isValid(e) then
			exit function
		end if
		if not isValid(r) then
			exit function
		end if
		dim inherits, ro
		set inherits = inheritance.supersUntilRoot(r, RoleType)
		for each ro in e.getNeighbourRelationships(1, RIType)
			if r = ro.origin then 
				set getRoleOn = ro
				exit function
			end if
			if inherits.contains(ro.origin) then 
				set getRoleOn = ro
				exit function
			end if
		next
	end function
	
	public function getInfo(e)
		on error resume next
		set getInfo = e
		if not isValid(e) then
			exit function
		end if
		dim ro, temp
		if isType(e, TaskType) then
			set temp = e.getNeighbourRelationships(0, TIType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					set Infos = temp
					set getInfo = temp(1).target
				end if
			end if
		elseif isType(e, RoleType) then
			set temp = e.getNeighbourRelationships(0, RIType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					set Infos = temp
					set getInfo = temp(1).target
				end if
			end if
		elseif isType(e, ViewType) then
			set temp = e.getNeighbourRelationships(0, VIType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					set Infos = temp
					set getInfo = temp(1).target
				end if
			end if		
		else' assume information object in itself ...
		end if
	end function
	
	public function getTask(e, r)
		on error resume next
		set getTask = Nothing
		if not isValid(e) then
			exit function
		end if
		if not isValid(r) then
			exit function
		end if
		dim inherits, ro, typ, rel
		set inherits = inheritance.supersUntilRoot(r, RoleType)
		for each rel in e.getNeighbourRelationships(0, ITType) ' default task of e
			set getTask = rel.target
			exit function
		next
		
		if isType(e, ViewType) then
			set typ = TVType
		else
			set typ = TIType
		end if
		for each rel in e.getNeighbourRelationships(1, typ) ' all tasks linked to e
			if not isValid(r) then
				set getTask = rel.origin
				exit function
			end if
			for each ro in rel.origin.getNeighbourRelationships(1, RTType) ' roles linked to the task candidate
				if r = ro.origin then 
					set getTask = rel.origin
					exit function
				end if
				if inherits.contains(ro.origin) then 
					set getTask = rel.origin
					exit function
				end if
			next
		next
	end function
	
	public function getView(e, r, t)
		on error resume next
		set getView = Nothing
		dim temp, ro
		if isValid(e) then
			set temp = e.getNeighbourRelationships(1, VIType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					for each ro in temp
						if isType(ro.origin, ViewType) then
							set getView = ro.origin
							exit function
						end if					
					next
				end if
			end if
		end if
		if isValid(t) then
			set temp = t.getNeighbourRelationships(0, TVType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					for each ro in temp
						if isType(ro.target, ViewType) then
							set getView = ro.target
							exit function
						end if					
					next
				end if
			end if
		end if
		if isValid(r) then
			set temp = r.getNeighbourRelationships(0, RVType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					for each ro in temp
						if isType(ro.target, ViewType) then
							set getView = ro.target
							exit function
						end if					
					next
				end if
			end if
		end if	
		if isValid(t) then
			set temp = t.getNeighbourRelationships(1, VIType) ' task as info ...
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					for each ro in temp
						if isType(ro.origin, ViewType) then
							set getView = ro.origin
							exit function
						end if					
					next
				end if
			end if
		end if		
		if isValid(r) then
			set temp = r.getNeighbourRelationships(1, VIType)
			if isValid(temp) then
				if temp.count >= 1 then 'handle multiple values later
					for each ro in temp
						if isType(ro.origin, ViewType) then
							set getView = ro.origin
							exit function
						end if					
					next
				end if
			end if
		end if	
	end function
	
	' these four subs find IRTV elements based on one of the elements (either current or something inherited)
	public sub configureFromTask(t)
		if not isValid(Role) then
			set Role = getRoleInTask(GLOBAL_User, t)
		end if
		if not isValid(Info) then
			set Info = getInfo(t)
			if isValid(Info) and not isValid(Role) then ' user has no role on task, maybe on info?
				set Role = getRoleOn(Info,GLOBAL_User)
			end if
		end if
		if not isValid(View) then
			set View = getView(Info, Role, t)
			if isValid(View) and not isValid(Info) then ' View given, not info, use default for view
				set Info = getInfo(View)
				if isValid(Info) and not isValid(Role) then ' user has no role on task, maybe on info?
					set Role = getRoleOn(Info,GLOBAL_User)
				end if
			end if
			if isValid(View) and not isValid(Role) then' user has no role on task, maybe on view?
				set Role = getRoleOn(GLOBAL_User,View)
			end if
		end if
	end sub
	
	public sub configureFromInfo(i)
		if not isValid(Role) then
			set Role = getRoleOn(GLOBAL_User, i)
		end if
		if not isValid(Task) then
			set Task = getTask(i, GLOBAL_User)
			if isValid(Role) and not isValid(Task) then ' no task found for the user, maybe the role provides a default one?
				set Task = getTask(i,Role)
			end if
			if isValid(Task) and not isValid(Role) then ' user has no role on info, maybe on task?
				set Role = getRoleInTask(GLOBAL_User,Task)
			end if
		end if
		if not isValid(View) then
			set View = getView(i, Role, Task)
			if isValid(View) and not isValid(Task) then ' no task found, maybe the view provides a default one?
				set Task = getTask(View,Role)
				if isValid(Task) and not isValid(Role) then ' user has no role on info, maybe on task?
					set Role = getRoleInTask(GLOBAL_User,Task)
				end if
			end if
			if isValid(View) and not isValid(Role) then' user has no role on info or task, maybe on view?
				set Role = getRoleOn(GLOBAL_User,View)
				if isValid(Role) and not isValid(Task) then ' no task found for the user, maybe the role provides a default one?
					set Task = getTask(Info,Role)
				end if
			end if	
		end if
	end sub
	
	public sub configureFromRole(r)
		if not isValid(Info) then
			set Info = getInfo(r)
		end if
		if not isValid(Task) then
			set Task = getTask(Info,r)
			if isValid(Task) and not isValid(Info) then ' user has no role on task, maybe on info?
				set Info = getInfo(Task)
			end if
		end if
		if not isValid(View) then
			set View = getView(Info,r, Task)
			if isValid(View) and not isValid(Task) then ' no task found, maybe the view provides a default one?
				set Task = getTask(View,r)
				if isValid(Task) and not isValid(Info) then ' user has no role on task, maybe on info?
					set Info = getInfo(Task)
				end if
			end if
			if isValid(View) and not isValid(Info) then' user has no role on info or task, maybe on view?
				set Info = getInfo(View)
				if isValid(Info) and not isValid(Task) then
					set Task = getTask(Info,r)
				end if
			end if
		end if
	end sub
	
	public sub configureFromView(v)
		if not isValid(Role) then
			set Role = getRoleOn(GLOBAL_User, v)
		end if
		if not isValid(Task) then
			set Task = getTask(v, GLOBAL_User)
			if isValid(Role) and not isValid(Task) then ' no task found for the user, maybe the role provides a default one?
				set Task = getTask(v,Role)
			end if
			if isValid(Task) and not isValid(Role) then ' user has no role on info, maybe on task?
				set Role = getRoleInTask(GLOBAL_User,Task)
			end if
		end if
		if not isValid(Info) then
			set Info = getInfo(v)
			if isValid(Task) and not isValid(Info) then ' no info given from view, maybe from task?
				set Info = getInfo(Task)
			end if
			if isValid(Info) and not isValid(Task) then ' no tasl given from view, maybe from info?
				set Task = getTask(Info, GLOBAL_User)
				if isValid(Role) and not isValid(Task) then ' no task found for the user, maybe the role provides a default one?
					set Task = getTask(Info,Role)
				end if
			end if
			if isValid(Info) and not isValid(Role) then' user has no role on view or task, maybe on info?
				set Role = getRoleOn(GLOBAL_User,Info)
				if isValid(Role) and not isValid(Task) then ' no task given from view, maybe from info?
					set Task = getTask(Info, Role)
				end if
			end if
		end if
	end sub
	
	' Find the current user from the modedl (selecting among available persons) ----
	public function findUser()
		set findUser = selectOneOfType(UserType, "Which user are you?")
		if not isValid(findUser) then
			set findUser = selectOneOfType(RoleType, "Which role do you play?")
		end if
	end function
	
	private function selectOneOfType(aType, question) 
		dim o, l
		set l = metis.newInstanceList()
		set selectOneOfType = Nothing
			for each o in metis.currentModel.findInstances(aType, "", "")
			if isValid(o) then
				if len(o.title) >0 then
					call l.AddLast(o)
				end if
			end if
		next
		if (l.count > 1) then
			set selectOneOfType = selectAmong(question, true, l)
		elseif (l.count = 1) then
			set selectOneOfType = l(1)
		end if
	end function
	
	private function selectAmong(tekst, singleselect, list)
		dim dia, l
		set selectAmong = Nothing
		set dia = new CVW_SelectDialog
		dia.singleSelect = singleselect
		dia.title = tekst
		dia.heading = tekst
		set l = dia.show(list)
		if isObject(l) and l.count >0 then
			set selectAmong = l(1)
		end if
	end function

    private Sub Class_Initialize
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set inst            = model.currentInstance
        set instView        = modelView.currentInstanceView
        set inheritance = new EKA_Inheritance
        set inheritance.model           = model
		set inheritance.modelView       = modelView
		set inheritance.inst            = inst
		set inheritance.instView        = instView 
		
		set workspace = new CVW_Workspace
		call workspace.build
			
        set InfoType		= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_object.kmd#ObjType_EKA:Object_UUID")
        set RoleType		= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/role_actor.kmd#Role_Actor")
        set TaskType		= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_task.kmd#ekaTask")
        set ViewType		= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_irtv.kmd#View_IRTV")
        set UserType		= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/person.kmd#IRTV:Person")
        set RIType			= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/uses.kmd#IRTV:Uses")
		set RTType			= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/participates.kmd#IRTV:Participates")
		set RVType			= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/applies_view.kmd#IRTV:Applies")
		set TVType			= RVType
		set TIType			= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#works_on")
		set VIType			= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
		set ITType			= metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/hasdefault.kmd#IRTV:Has_default")
		set RootRelType		= metis.findType("http://metadata.troux.info/meaf/abstracttypes/generic_relationship_type.kmd#BasicRelationshipType")
        set Info = Nothing 
        set Role = Nothing
        set Task = Nothing
        set View = Nothing
        set Infos = Nothing 
        set Roles = Nothing
        set Tasks = Nothing
        set Views = Nothing
        call establishIRTVContext(inst, true)
    end sub
End Class