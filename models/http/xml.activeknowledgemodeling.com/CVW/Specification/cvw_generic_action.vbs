option explicit

Class CVW_GenericAction

    Private model
    Private modelView
    Private inst
    private instview
    private context

   '---------------------------------------------------------------------------------------------------
    Public Property Get object()
        set object = inst
    End Property

    Public Property Set oject(obj)
        if isEnabled(obj) then
            set inst = obj
        end if
    End Property


	' ----------------------------- for debugging
	private sub alertContext()
		dim  u
		u =""
		if isValid(context.Info) then
			u = u&" I: "&context.Info.title& "("& context.Info.uri &")"
		else
			u = u&" I: Invalid"
		end if
		if isValid(context.Role) then
			u = u&" R: "&context.Role.title& "("& context.Role.uri &")"
		else
			u = u&" R: Invalid"
		end if
		if isValid(GLOBAL_User) then
			u = u&" U: "& GLOBAL_User.title& "("& GLOBAL_User.uri &")"
		else
			u = u&" U: Invalid"
		end if
		if isValid(context.Task) then
			u = u&" T: "&context.Task.title& "("& context.Task.uri &")"
		else
			u = u&" T: Invalid"
		end if
		if isValid(context.View) then
			u = u&" V: "&context.View.title& "("& context.View.uri &")"
		else
			u = u&" V: Invalid"
		end if
		msgbox u
	end sub
   '---------------------------------------------------------------------------------------------------
    Public Sub execute
		'msgbox(inst.getNamedStringValue("name"))
		'Dim instView
		'set instView = metis.currentModel.currentModelView.currentInstanceView
		
		dim view, task
'stop
		set context = new IRTV_Config
		set context.inst = inst
		set context.instview = instview
		set context.model = model
		set context.modelView = modelView
		call alertContext()
		set task = new CVW_TaskManager
		if task.execute(context) then 
			set view = new CVW_ViewManager ' by default, update the view
			view.show(context)
		end if
    End Sub    
    
     '---------------------------------------------------------------------------------------------------
    Private Sub Class_Initialize
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set inst   = model.currentInstance
        set instView        = modelView.currentInstanceView
    End Sub
   '---------------------------------------------------------------------------------------------------

End Class


