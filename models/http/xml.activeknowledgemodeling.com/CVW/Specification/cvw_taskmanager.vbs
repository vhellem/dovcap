option explicit

Class CVW_TaskManager

	private currentConfig
	
	Private model
    Private modelView
    Private inst
    Private instView
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
    
    ' this is the main body, for performing the task. 
    ' Note that if the task in question and none the tasks it inherits from has a clear code to perform, nothing is done
    ' Returns true if viewmanager should also be invoked, false if not
    public function execute(irtvconfig)
		execute = true
		set config = irtvconfig
		if not isValid(config) then 
			exit function ' do nothing
		end if
		if not isValid(config.Task) then 
			exit function ' else no view given, ignore
		end if
		if inheritance.isNothing(config.Task) then ' name signifies that nothing should be done
			execute = false
			exit function 
		else
			dim t
			for each t in Inheritance.supers(config.task)
				if Inheritance.isNothing(t) then ' do not show anything
					execute = false
					exit function
				end if
			next 
		end if
		if isType(inst, Config.TaskType) then
			if instview.children.count > 0 then
				' opening submenu
				execute = false
				exit function 
			end if
		end if
    end function
    
    
 private Sub Class_Initialize
    set model           = metis.currentModel
    set modelView       = model.currentModelView
    set inst            = model.currentInstance
    set instView        = modelView.currentInstanceView
    set currentConfig = Nothing
 end sub
	
End class