option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_GenericWorkarea

	private config
	private inheritance
	private params
    
    ' Variant parameters
    Public Title                          ' String
    Public Mode                           ' String
    Public TitleBar                       ' String
    Public TitleBarAddOn                  ' String
    Public LayoutStrategy                 ' URI
    Public WindowLayoutStrategy           ' URI
    Public WindowLayoutMode               ' String
    Public HierarchyLayout                ' URI
    Public SymbolOpen                     ' URI
    Public SymbolClosed                   ' URI
    Public TextScale                      ' Float as String
    Public TreeTextScale                  ' Float as String
    Public NestedTextScaleTop             ' Float as String
    Public NestedTextScale                ' Float as String
    Public Height                         ' Integer as String
    Public Width                          ' Integer as String
    Public FilterModel                    ' URI
    Public InstanceContextModel           ' URI
    Public ModelContextModel              ' URI
    Public ViewStrategyModel              ' URI
    Public LanguageModel                  ' URI
    Public Workspace                      ' CVW_Workspace
    'public WorkspaceWin ' instance
    Public ObjectAspectRatio              ' Float as String
    Public ObjectTextScale				  ' Float as String
    Public ObjectScaleFactor			  ' Float as String
    Public RelationshipViewMode           ' Hierarchy | Relationship
    Public ContentInRepository
    Public applyFilter                    ' Boolean

    ' Context variables (public) ' All from context
    'Public currentModel
    'Public currentModelView
    'Public currentInstance
    'Public currentInstanceView
    'Public contextInstance                ' IMetisInstance

    ' Context variables (private)
    'Private model
    'Private cObject                      ' Component object   - IMetisInstance
    'Private aObject                      ' Configuring object - IMetisInstance
    Private currentWorkarea              ' IMetisObjectView
    Private searchModel

    ' Types
    Private buttonType                   ' IMetisType
    Private consistsOfType               ' IMetisType
    Private titlebarType                 ' IMetisType
    Private windowType                   ' IMetisType
    Private window2Type                  ' IMetisType
    Private hasFilterType                ' IMetisType
    Private hasLanguageType              ' IMetisType
    Private hasInstanceContextType       ' IMetisType
    Private hasInstanceContext2Type      ' IMetisType
    Private hasModelContextType          ' IMetisType
    Private hasViewStrategyType          ' IMetisType
    Private hasSearchSpecificationType   ' IMetisType
    Private specContainerType            ' IMetisType
    Private propertyType
    Private hasPropertyType

    ' Methods
    Private addMetamodelMethod           ' IMetisMethod
    Private addPartRuleMethod            ' IMetisMethod

    ' Layout strategies
    Private workareaLayoutStrategy       ' IMetisInstance
    Private workwinLayoutStrategy        ' IMetisInstance
    Private hierarchy_layout             ' IMetisInstance

    ' Components
    Private cvwArg                       ' CVW_ArgumentValue
    Private compTitleBar                 ' CVW_Component
    Private compWorkareaWindow           ' CVW_Component
    Private window                       ' CVW_Window

    ' Others
    Private work_window
    Private WorkspaceName                ' String
    Private titleBarIndex                ' Integer
    Private workareaIndex                ' Integer
    'Private sourceContainerView          ' IMetisInstanceView
    Private noFilterRules
    Private filterRules()

	
    Public Property Get parameters        'IRTV_Config
		if not isValid(params) then 
			set config = new IRTV_Config
			set params = new CVW_ParameterManager
			set params.config = config
			set inheritance = config.inheritance
		end if
        set parameters = params
    End Property

    Public Property Set parameters(obj)
        if isValid(obj) then
			set params = obj
            set config = params.config
            set workspace = config.workspace
            set inheritance = config.inheritance
			' Assume started on button
			set currentWorkarea = config.instView.parent.parent
		end if
    End Property
    

'-----------------------------------------------------------
    Public Property Get WorkWindow
		if not isValid(work_window) then
			set work_window = window.objectView.children(workareaIndex)
		end if
        set WorkWindow = work_window
    End Property

    Public Property Set WorkWindow(win)
        set work_window = win
    End Property


   '---------------------------------------------------------------------------------------------------
  '  should be global, moved her for now:'
  function findNeighbours(inst, reltype, recursive, direction) 
	dim x, d, t
	d = 0
	if direction = 1 then
		d = 1
	end if
	set findNeighbours = metis.newInstanceList()
	if not isValid(reltype) then
		exit function
	end if 
	for each x in inst.getNeighbourRelationships(d, reltype)
		if d = 0 then
			call findNeighbours.AddLast(x.target)
		else
			call findNeighbours.AddLast(x.origin)
		end if
	next
	if recursive then
		for each t in reltype.subtypes
			for each x in findNeighbours(inst, t, false, d)
				call findNeighbours.AddLast(x)
			next
		next
	end if
  end function
    
    Function findComponent(inst, componentName, recursive)
        dim usesType, uses2Type
        dim comp, components

        set findComponent = Nothing
'stop
        'set compType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")
        set usesType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent_UUID")
        set uses2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent2_UUID")

        if isEnabled(inst) then
			set components = inst.parts
            for each comp in components
                if isEnabled(comp) then
					if isType(comp, Config.ViewType) then
						if comp.title = componentName then
							set findComponent = comp
							exit function
						end if
					end if
                end if
            next
			set components = findNeighbours(inst, Parameters.ConsistsOfType, true, 0) 
            for each comp in components
                if isEnabled(comp) then
                    if comp.title = componentName then
                        set findComponent = comp
                        exit function
                    end if
                end if
            next

            set components = findNeighbours(inst, usesType, true, 0)
            for each comp in components
                if isEnabled(comp) then
                    if comp.title = componentName then
                        set findComponent = comp
                        exit function
                    end if
                end if
            next
  
			set components = findNeighbours(inst, uses2Type, true, 0)
            for each comp in components
                if isEnabled(comp) then
                    if comp.title = componentName then
                        set findComponent = comp
                        exit function
                    end if
                end if
            next
            
            set components = findNeighbours(inst, Metis.findtype("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:DependsOn_UUID"), true, 0) 
            for each comp in components
                if isEnabled(comp) then
                    if comp.title = componentName then
                        set findComponent = comp
                        exit function
                    end if
                end if
            next
            if recursive and (not isValid(findComponent)) then ' inheritance
				dim s
				for each s in inheritance.supers(inst) 
					if s.uri <> inst.uri then
						set findComponent = findComponent(s, componentName, false)
						if isValid(findComponent) then
							exit function
						end if
					end if
				next
            
            end if
        end if
    End Function


   '-----------------------------------------------------------
    Public Property Get contentModel           'IMetisObject
        dim context, model

        ' Find ContentModel

        ' Find ContentModel
        set context = new EKA_Context
        if isValid(config) then
			set context.currentModel        = config.model
			set context.currentModelView    = config.modelView
		end if
        set context.currentInstance     = work_window.instance
        set context.currentInstanceView = work_window
        if isValid(context) then
            set contentModel = context.contentModel
            ContentInRepository = context.isRepository
        end if

        if not isEnabled (contentModel) then
            if isValid(config) then
				set model = config.model
			else
				set model = metis.currentModel
			end if
			dim x, y
			for each x in model.views ' find model view called content ...
				if (instr(1, x.title, "content", 1) >0) or (instr(1, x.title, "main", 1) >0) or (instr(1, x.title, "data", 1) >0) then
					for each y in x.children ' find child which is submodel
						if y.instance.type.uri = "metis:stdtypes#oid125" then
							set contentModel = y.instance.parts(1)
							exit property
						end if
					next
				end if
			next
        end if
        if not isEnabled (contentModel) then
			set contentModel = model
		end if
    End Property

'-----------------------------------------------------------
    Public Property Get ContentSearchModel
        set ContentSearchModel = searchModel
    End Property

    Public Property Let ContentSearchModel(search_model)
        if isvalid(work_window) then
            searchModel = search_model
            call connectContentSearchModel(searchModel)
        end if
    End Property

'-----------------------------------------------------------
    Public Sub setFilterRules(rules, noRules)
        
        dim rule
        dim i
        
        noFilterRules = noRules
        ReDim Preserve filterRules(noFilterRules)
        for i = 1 to noRules
            set rule = rules(i) 
            set filterRules(i) = rule
        next
    End Sub

'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build
    on error resume next
        ' Set variant parameters from configuring object - if given
        Title                = value(Config.View,"Name")
        Mode                 = value(Config.View,"Mode")
 'stop
        set TitleBar             = value(Config.View,"TitleBar")
        set TitleBarAddOn        = value(Config.View,"TitleBarAddOn")
        LayoutStrategy       = value(Config.View,"LayoutStrategy")
        WindowLayoutStrategy = value(Config.View,"WorkwinLayoutStrategy")
        WindowLayoutMode     = value(Config.View,"WorkwinLayoutMode")
        RelationshipViewMode = value(Config.View,"RelationshipViewMode")
        SymbolOpen           = value(Config.View,"SymbolOpen")
        SymbolClosed         = value(Config.View,"SymbolClosed")
        TextScale            = value(Config.View,"Textscale")
        TreeTextScale        = value(Config.View,"TreeTextScale")
        NestedTextScale      = value(Config.View,"NestedTextScale")
        NestedTextScaleTop   = value(Config.View,"NestedTextScaleTop")
        Height               = value(Config.View,"Height")
        Width                = value(Config.View,"Width")
        ObjectAspectRatio    = value(Config.View,"ObjectAspectRatio")
        ObjectTextScale		= value(Config.View,"ObjectTextScale")
        ObjectScaleFactor		= value(Config.View,"ObjectScaleFactor")
        set FilterModel          = value(Config.View,"FilterSpecification_Model")
        set InstanceContextModel = value(Config.View,"InstanceContext_Model")
        set ModelContextModel    = value(Config.View,"ModelContext_Model")
        set LanguageModel        = value(Config.View,"Language_Model")
        set ViewStrategyModel    = value(Config.View,"ViewStrategy_Model")
        if Len(TextScale) = 0 then
            TextScale = 1
        else
            TextScale = CDbl(TextScale)
        end if
        if Len(TreeTextScale) = 0 then
            TreeTextScale = -1
        else
            TreeTextScale = CDbl(TreeTextScale)
        end if
        if Len(NestedTextScale) = 0 then
            NestedTextScale = -1
        else
            NestedTextScale = CDbl(NestedTextScale)
        end if
        if Len(NestedTextScaleTop) = 0 then
            NestedTextScaleTop = -1
        else
            NestedTextScaleTop = CDbl(NestedTextScaleTop)
        end if
        if Len(ObjectAspectRatio) = 0 then
            ObjectAspectRatio = -1
        else
            ObjectAspectRatio = CDbl(ObjectAspectRatio)
        end if
        if Len(ObjectTextScale) = 0 then
            ObjectTextScale = -1
        else
            ObjectTextScale = CDbl(ObjectTextScale)
        end if
        if Len(ObjectScaleFactor) = 0 then
            ObjectScaleFactor = -1
        else
            ObjectScaleFactor = CDbl(ObjectScaleFactor)
        end if
        set workareaLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)
        set workwinLayoutStrategy = metis.findLayoutStrategy(WindowLayoutStrategy)

        ' Find used components
        set compTitleBar       = findComponent(config.View, "TitleBar", true)
        set compWorkareaWindow = findComponent(config.View, "WorkareaWindow", true)
   End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Propagate parameters to sub-components
        'call resetCVWcomponent(compTitleBar)
        'call configureCVWcomponent(parameters, compTitleBar, true)
        'call resetCVWcomponent(compWorkareaWindow)
        'call configureCVWcomponent(parameters, compWorkareaWindow, true)
    End Sub

'-----------------------------------------------------------
    ' Do what the component is built for - return result
    Public Function execute
        dim index, noWindows
        dim clearMode, newMode, copyMode, moveMode
        dim layout_strategy
        set execute = Nothing
        ' The code
        ' Check workspace view
        'stop
        'if not isValid(Workspace) then
        '    exit function
        'end if
        ' Set some flags
        newMode   = true
        clearMode = false
        copyMode  = false
        moveMode  = false
        if Mode   = "New" then
            newMode = true
        elseif Mode = "Reuse" then
            newMode = false
        elseif Mode = "ReuseAndClear" then
            clearMode = true
            newMode = false
        elseif Mode = "CopyView" then
            copyMode = true
        elseif Mode = "MoveView" then
            moveMode = true
        end if

        set currentWorkarea = config.instView.parent.parent
        if not find(Title, Workspace.WorkspaceWindow, currentWorkarea) then
			newMode = true
        end if
        if newMode then
            ' Create workarea
            if window.create(Title, windowType, Workspace.WorkspaceWindow) then
                with window.objectView
                    on error resume next
                    set .layoutStrategy = workareaLayoutStrategy
                    .openSymbol         = SymbolOpen
                    .closedSymbol       = SymbolClosed
                    if Len(TextScale) > 0 then
                        .absTextScale   = CInt(TextScale)
                    end if
                    if Len(Height) > 0 then
                        .geometry.height = CInt(Height)
                    end if
                    if Len(Width) > 0 then
                        .geometry.width  = CInt(Width)
                    end if
                end with
                index = 1
                if isValid(compTitleBar) then
                    ' Create title bar
                    titlebarIndex = index
                    if isEnabled(compTitleBar) then
                        call createTitleBar(compTitleBar)
                        index = index + 1
                    end if
                end if
                ' Create work window
                workareaIndex = index
                call createWorkareaWindow(compWorkareaWindow)
                index = index + 1
            end if
        else
            workareaIndex = 2
            set work_window = window.objectView.children(workareaIndex)
            if not isEnabled(work_window) then
                workareaIndex = 1
                set work_window = window.objectView.children(workareaIndex)
            end if
        end if
        if clearMode then
            call window.clean()
        end if
        if copyMode then
            call copyViewToWorkarea()
        end if
        'call window.doParentLayout
        call doWorkspaceLayout(work_window.parent.parent)

        ' End code
        execute = true
    End Function

'-----------------------------------------------------------
    Public Function find(name, parentView, instance)              ' as Boolean
        if name = "$Current$" then
            find = window.find2(windowType, parentView, instance)
        else
            find = window.find(name, windowType, parentView)
        end if
    End Function

' ------------------------------------------------------------
function value(object, name) 
	value = ""
	if not isValid(object) then
		set object = config.view
	end if
	dim found
	found = parameters.getValueForObject(object, name, value)
	if not found then
	    found = parameters.getValueFromSupers(object, name, value)
	end if
    if not found then
		value = parameters.getValue(name)
    end if
'    msgbox object.title&"."&name&" = "&value
end function
'-----------------------------------------------------------
    Private Sub createTitleBar(compTitleBar)
    		on error resume next
        dim TitleBarName, TemplateName, TemplateAddOn
        dim OpenSymbol, ClosedSymbol
        dim TextScale, Height
        dim TitleLayout, layout_strategy
        dim m, objectMenu, objectMenuAddOn, titleView, itemView

        ' Get variant parameter values
		'hdj:
		TitleBarName = Title
        'TitleBarName      = parameters.getValue( "Name")
        dim found
        found = parameters.getValueForObject(compTitleBar, "TemplateName", TemplateName)
        if not found then
			set TemplateName = parameters.getValue("TemplateName")
			if not isValid(TemplateName) then
				TemplateName = parameters.getValue("TemplateName")
			end if
		end if 
		found = parameters.getValueForObject(compTitleBar, "TemplateAddOn", TemplateAddOn)
		if not found then
			set TemplateAddOn = parameters.getValue("TemplateAddOn")
			if not isValid(TemplateAddOn) then
				TemplateAddOn = parameters.getValue("TemplateAddOn")
			end if
		end if 
        TitleLayout = value(compTitleBar, "LayoutStrategy")
        OpenSymbol = value(compTitleBar, "SymbolOpen")
        ClosedSymbol = value(compTitleBar, "SymbolClosed")
        TextScale = value(compTitleBar, "Textscale")
        Height = value(compTitleBar, "Height")
        set layout_strategy = metis.findLayoutStrategy(TitleLayout)

        ' Create title bar according to configuration
        set m = getCVWmodel
        if isObject(TemplateName) then
			set objectMenu = TemplateName
        else
			set objectMenu = metis.findInstance(TemplateName)
		end if
        if not isEnabled(objectMenu) then
            set objectMenu = m.findInstances(buttonType, "name", TemplateName)
            if objectMenu.count = 0 then
				set objectMenu = nothing
            else
				set objectMenu = objectMenu(1)
            end if
        end if
        if isObject(TemplateAddOn) then
			set objectMenuAddOn = TemplateAddOn
		else 
			set objectMenuAddOn = metis.findInstance(TemplateAddOn) 
		end if
        if not isEnabled(objectMenuAddOn) then
            set objectMenuAddOn = m.findInstances(buttonType, "name", TemplateAddOn)
            if objectMenuAddOn.count = 0 then
				set objectMenuAddOn = nothing
            else
				set objectMenuAddOn = objectMenuAddOn(1)
            end if
        end if
        call window.addSubWindow("Top", TitleBarName, titlebarType)
        set titleView = window.objectView.children(titlebarIndex)
        if isValid(objectMenu) then
            set itemView = objectMenu.views(1)
            call generateTree(itemView, titleView, consistsOfType, buttonType, 0.05, 1.3)
        end if
        if isValid(objectMenuAddOn) then
			set itemView = nothing
            set itemView = objectMenuAddOn.views(1)
            call generateTree(itemView, titleView, consistsOfType, buttonType, 0.05, 1.3)
        end if
        with titleView
            on error resume next
            set .layoutStrategy = layout_strategy
            .openSymbol         = OpenSymbol
            .closedSymbol       = ClosedSymbol
            if Len(TextScale) > 0 then
                .absTextScale       = CInt(TextScale)
            end if
            if Len(Height) > 0 then
                .geometry.height    = CInt(Height)
            end if
        end with

    End Sub

'-----------------------------------------------------------
    Private Sub createWorkareaWindow(compWorkareaWindow)
    		on error resume next
        dim WindowName, TemplateName, TemplateAddOn
        dim OpenSymbol, ClosedSymbol
        dim TextScale, Height, Width
        dim WindowLayout, layout_strategy
        dim m

        ' Get variant parameter values
        dim found
        WindowName = value(compWorkareaWindow, "Name")
        found = parameters.getValueForObject(compWorkareaWindow, "TemplateName", TemplateName)
        if not found then
			set TemplateName = parameters.getValue("TemplateName")
			if not isValid(TemplateName) then
				TemplateName = parameters.getValue("TemplateName")
			end if
		end if 
		found = parameters.getValueForObject(compWorkareaWindow, "TemplateAddOn", TemplateAddOn)
		if not found then
			set TemplateAddOn = parameters.getValue("TemplateAddOn")
			if not isValid(TemplateAddOn) then
				TemplateAddOn = parameters.getValue("TemplateAddOn")
			end if
		end if 
        WindowLayout = value(compWorkareaWindow, "LayoutStrategy")
        HierarchyLayout = value(compWorkareaWindow, "TreeLayout")
        OpenSymbol = value(compWorkareaWindow, "SymbolOpen")
        ClosedSymbol = value(compWorkareaWindow, "SymbolClosed")
        TextScale = value(compWorkareaWindow, "Textscale")
        Height = value(compWorkareaWindow, "Height")
        Width = value(compWorkareaWindow, "Width")
        set layout_strategy  = metis.findLayoutStrategy(WindowLayout)
        set hierarchy_layout = metis.findLayoutStrategy(HierarchyLayout)

        ' Create workarea window according to configuration
        set m = getCVWmodel
        if WindowLayoutMode = "Manual" then
            call window.addSubWindow("Top", "WorkArea_["& WindowName &"]", window2Type)
            set work_window = window.objectView.children(workareaIndex)
            set config.model.currentInstance = work_window.instance
            set config.modelView.currentInstanceView = work_window
            metis.runCommand("toggle-next-fixed-layout")
            set config.model.currentInstance = config.inst
            set config.modelView.currentInstanceView = config.instView
        else
            call window.addSubWindow("Top", "WorkArea_["& WindowName &"]", windowType)
            set work_window = window.objectView.children(workareaIndex)
        end if
        with work_window
            on error resume next
            set .layoutStrategy = layout_strategy
            .openSymbol         = OpenSymbol
            .closedSymbol       = ClosedSymbol
            if Len(TextScale) > 0 then
                .absTextScale       = CInt(TextScale)
            end if
            if Len(Height) > 0 then
                .geometry.height = CInt(Height)
            end if
            if Len(Width) > 0 then
                .geometry.width  = CInt(Width)
            end if
        end with
        call metis.doLayout(work_window.parent)

        ' Set view strategy if given
        call connectFilter()
        call connectLanguageModel()
        call connectModelContext()
        call connectInstanceContext()
        call connectViewStrategy()
    End Sub

'-----------------------------------------------------------
    Public Sub populate(instances, noLevels)
        dim obj, obj1, obj2, objView
        dim origin, target
        dim relType, type1, type2
        dim inst, workarea, wObject
        dim viewStrategies, viewStrategy
        dim instanceConts, instanceCont
        dim strategyConts, strategyCont
        dim cvwViewStrategy, cvwCircularLayout
        dim ekaInstance
        dim rel, relView, hasViewList
        dim originView, originViews, targetView, targetViews
        dim propVal
        dim done

        ' Get variant parameter values
        'if TreeTextScale < 0 then TreeTextScale = cvwArg.getConfiguredValue(compWorkareaWindow, "TreeTextScale")
        'if NestedTextScale < 0 then NestedTextScale = cvwArg.getConfiguredValue(compWorkareaWindow, "NestedTextScale")
        'if NestedTextScaleTop < 0 then NestedTextScaleTop = cvwArg.getConfiguredValue(compWorkareaWindow, "NestedTextScaleTop")

        set wObject = work_window.instance
        set ekaInstance = new EKA_Instance
        if WindowLayoutStrategy = "akm:layout#CircularLayout1" then
            for each inst in instances
                if isEnabled(inst) then
                    if inst.isObject then
                        set cvwCircularLayout = new CVW_CircularLayout
                        call cvwCircularLayout.build
                        call cvwCircularLayout.execute(work_window, inst)
                        exit for
                    end if
                end if
            next
        else
            ' Get view strategy
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
                propVal = ekaInstance.getPropertyValue(strategyCont, "RelationshipViewMode")
                if Len(propVal) > 0 then
                    RelationshipViewMode = propVal
                end if
            end if
            ' Get instance context parameters
            'set instanceConts = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
            'if instanceConts.count > 0 then
            '    set instanceCont = instanceConts(1)
            '    propVal = ekaInstance.getPropertyValue(instanceCont, "ObjectAspectRatio")
            '    if Len(propVal) > 0 then
            '        ObjectAspectRatio = CDbl(propVal)
            '    end if
            'end if
            set hasViewList = metis.newInstanceList
            call addViewsToList(hasViewList, work_window)
            for each obj in instances
                if not obj.isRelationship then
                    if not instanceInList(obj, hasViewList) then
                        set objView = creTreeView(obj, hasViewList, work_window, cvwViewStrategy, 0, noLevels)
                    end if
                end if
            next
            for each rel in instances
                done = false
                if rel.isRelationship then
                    set origin = rel.origin
                    set originViews = config.modelView.findInstanceViews(origin)
                    set target = rel.target
                    set targetViews = config.modelView.findInstanceViews(target)
                    for each originView in originViews
                        if isInView(originView, work_window) then
                            for each targetView in targetViews
                                if isInView(targetView, work_window) then
                                    if isValid(cvwViewStrategy) then
                                        done = isHierarchyRelView(rel, originView, targetView, cvwViewStrategy)
                                    end if
                                    if not done then
                                        set relView = config.modelView.newRelationshipView(rel, originView, targetView)
                                    end if
                                end if
                            next
                        end if
                    next
                end if
            next
        end if

        ' Do the layout on work_window
        if work_window.instance.type.uri <> window2Type.uri then
            call metis.doLayout(work_window)
        end if

        ' Set layout strategy on topObject
        if isEnabled(hierarchy_layout) and isEnabled(objView) then
            set objView.layoutStrategy = hierarchy_layout
        end if
        if isEnabled(objView) then
            ' Do the layout on topObject
            call metis.doLayout(objView)
        end if
        set ekaInstance = Nothing
    End Sub

'-----------------------------------------------------------
    Private Function creTreeView(obj, hasViewList, parentView, cvwViewStrategy, level, noLevels)
        dim obj1, obj2, objView
        dim relType, type1, type2
        dim workarea, wObject
        dim strategies, strategy
        dim relDir, rels, rel, relView
        dim childInst, childInstView
        dim textScale, parentAbsScale, objAbsScale
        dim i, found
        dim rule
        dim cvwObjView, cvwFilter
        dim objGeo, size

        if level >= noLevels then
            if noLevels > -1 then
                set creTreeView = Nothing
                exit Function
            end if
        end if

        if isEnabled(obj) then
            ' Create view of each of the top instances
            set cvwObjView = new CVW_ObjectView
            cvwObjView.treeTextFactor    = TreeTextScale
            cvwObjView.nestedTextFactor1 = NestedTextScaleTop
            cvwObjView.nestedTextFactor2 = NestedTextScale
            set objView = cvwObjView.create(work_window, parentView, obj, ObjectAspectRatio)
				objView.TextScale = ObjectTextScale 'hdj
				objView.ScaleFactor = ObjectScaleFactor
            set cvwObjView = Nothing
            if objView.isNested then
                objView.close
            end if
            if isValid(hasViewList) then
                hasViewList.addLast obj
            end if
            if isValid(cvwViewStrategy) then
                set cvwFilter = new CVW_Filter
                for i = 1 to cvwViewStrategy.noHierarchyRules
                    set rule = cvwViewStrategy.hierarchyRules(i)
                    if obj.type.uri = rule.parentType.uri then
                        set rels = obj.getNeighbourRelationships(rule.relDir, rule.relType)
                        for each rel in rels
                            if not applyFilter or cvwFilter.instIsValid(rel, filterRules, noFilterRules) then
                                if rule.relDir = 0 then
                                    set childInst = rel.target
                                else
                                    set childInst = rel.origin
                                end if
                                if not applyFilter or cvwFilter.instIsValid(childInst, filterRules, noFilterRules) then
                                    level = level + 1
                                    if RelationshipViewMode = "Hierarchy" then
                                        set childInstView = creTreeView(childInst, hasViewList, objView, cvwViewStrategy, level, noLevels)
                                    elseif not instanceInList(childInst, hasViewList) then
                                        set childInstView = creTreeView(childInst, hasViewList, work_window, cvwViewStrategy, level, noLevels)
                                        set relView = config.modelView.newRelationshipView(rel, objView, childInstView)
                                    end if
                                    level = level - 1
                                end if
                            end if
                        next
                    end if
                next
                set cvwFilter = Nothing
            end if
        end if
        if objView.isNested then
            'if level = 0 then
                call objView.doLayout
            '    objView.open
            'end if
        end if
        set creTreeView = objView
    End Function

    '---------------------------------------------------------------------------------------------------
    Private Function isHierarchyRelView(rel, originView, targetView, cvwViewStrategy)
        dim rule
        dim i

        isHierarchyRelView = false
        for i = 1 to cvwViewStrategy.noHierarchyRules
            set rule = cvwViewStrategy.hierarchyRules(i)
            if rule.relType.uri = rel.type.uri then
                if rule.relDir = 0 then
                    if rel.origin.type.uri = rule.parentType.uri then
                        if rel.target.type.uri = rule.childType.uri then
                            isHierarchyRelView = true
                        end if
                    end if
                elseif rule.relDir = 1 then
                    if rel.target.type.uri = rule.parentType.uri then
                        if rel.origin.type.uri = rule.childType.uri then
                            isHierarchyRelView = true
                        end if
                    end if
                end if
            end if
        next
    End Function

   '---------------------------------------------------------------------------------------------------
    Public Sub copyViewToWorkarea(byval sourceContainerView) 'hdj changed
        dim topContainer
        dim instance
        dim workwin

'sourceContainerView.open
        if isEnabled(sourceContainerView) then
            set workwin = window.objectView.children(workareaIndex)
            dim mv, m2
            set m2 = sourceContainerView.parent
            set mv = m2
            while isValid(m2)
				set mv = m2
				set m2 = mv.parent
            wend
            on error resume next
            set metis.currentModel = sourceContainerView.instance.ownerModel
            if metis.currentModel.currentModelView.uri <> mv.uri then
				set metis.currentModel.currentModelView = mv
			end if
            set metis.currentModel.currentModelView.currentInstanceView = sourceContainerView
            Call metis.runCommand("copy")
            set metis.currentModel = config.model
            set metis.currentModel.currentModelView = config.modelView
            set metis.currentModel.currentModelView.currentInstanceView = workwin
'stop
            'Call metis.runCommand("active-auto-layout")
            Call metis.runCommand("unset-auto-layout") 
            Call metis.runCommand("paste-view")
            set metis.currentModel.currentModelView.currentInstanceView =  workwin.children(workwin.children.count)
            Call metis.runCommand("toggle-fixed-layout")
            Call metis.runCommand("toggle-next-fixed-layout")
            Call metis.runCommand("toggle-sub-fixed-layout") 'next
            ' scale to fit to workwin:
            workwin.children(workwin.children.count).TextScale = ObjectTextScale
            call scaleView(workwin, true)
			set metis.currentModel.currentModelView.currentInstanceView = workwin
			set workwin.layoutStrategy = metis.findLayoutStrategy("http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#_002asku01k3ugo3o9942")
			'workwin.doLayout
			'Call metis.runCommand("active-auto-layout") 'off
            'Call metis.runCommand("active-auto-layout") 'on
            Call metis.runCommand("unset-auto-layout")
            config.modelView.clearSelection
            'call workwin.children(workwin.children.count).open()
        end if
    End Sub
    
    
    public sub scaleview(view, full) 
		on error resume next
		if isValid(view) then
			dim factor, c, maxx, maxy, scalex, scaley, minx, miny, offsetx, offsety, p, m, i, l
			factor = 1
			if view.children.count >0 then
				factor = view.ScaleFactor
				maxx = -10000000
				maxy = -10000000
				minx = 10000000
				miny = 10000000
				for each c in view.children
					if c.geometry.x + c.geometry.width > maxx then
						maxx = c.geometry.x + c.geometry.width
					end if
					if c.geometry.y + c.geometry.height > maxy then
						maxy = c.geometry.y + c.geometry.height
					end if
					if c.geometry.x < minx then
						minx = c.geometry.x 
					end if
					if c.geometry.y < miny then
						miny = c.geometry.y 
					end if
				next
				if full then
					scalex = view.geometry.width / ( (maxx-minx) * factor)
					scaley = view.geometry.height / ( (maxy-miny) * factor)
					offsetx = 0
					offsety = 0
				else
					scalex = 0.9 * view.geometry.width / ( (maxx-minx) * factor)
					scaley = 0.8 * view.geometry.height / ( (maxy-miny) * factor)
					offsetx = 0.05* view.geometry.width / factor ' margin
					offsety = 0.15* view.geometry.height / factor ' room for header text
				end if
				'msgbox "Scaling children of " & view.instance.title & " x: " &scalex & " y: " &scaley
				for each c in view.children
					if  scaley < scalex then
						c.scale(scaley)
						'c.textscale = c.textscale * scaley
					else
						c.scale(scalex)
						'c.textscale = c.textscale * scalex
					end if
					if full then 'position in middle...
'stop
						c.geometry.x = -0.5 * (c.geometry.width * factor - view.geometry.width)
						c.geometry.y = -0.5 * (c.geometry.height * factor - view.geometry.height)
					else
						p = c.geometry
						p.width =  - minx * scalex + offsetx
						p.height = - miny * scaley + offsety
						c.moveRelative(p)
					end if
					'c.geometry.x = (c.geometry.x - minx) * scalex + offsetx
				
					'c.geometry.y = (c.geometry.y - miny) * scaley + offsety
					'if c.instance.isRelationship() then 
					'stop
					'	if c.hasPath() then
					'		m = "Points for relationship: " & vbcrlf
					'		l = metis.newInstanceList()
					'		for i = 1 to c.path.count
					'			set p = c.path.item(i)
					'			m = m & "("& p.x &","&p.y&") "
					'			p.x = (p.x - minx) * scalex + offsetx
					'			p.y = (p.y - miny) * scaley + offsety
					'			m = m & "->("& p.x &","&p.y&") "
					'			call l.addLast(p)
					'			'set c.path.item(i) = p
					'		next
					'		set c.path = l
					'		m = m & vbcrlf& "Converted into:          "& vbcrlf
					'		for each p in c.path
					'			m = m & "("& p.x &","&p.y&")"
					'		next
					'		msgbox m
					'	end if
					'else 
					'	c.geometry.x = (c.geometry.x - minx) * scalex + offsetx
					'	c.geometry.width = c.geometry.width * scalex
					'	c.textscale = c.textscale / scalex
					'	c.geometry.y = (c.geometry.y - miny) * scaley + offsety
					'	c.geometry.height = c.geometry.height * scaley
					'end if
				next
				for each c in view.children
					call scaleview(c, false)
				next
			end if
		end if
    end sub

   '---------------------------------------------------------------------------------------------------
    Private Sub addViewsToList(hasViewList, parentView)
        dim child, children
        dim inst

        set children = parentView.children
        for each child in children
            if hasInstance(child) then
                set inst = child.instance
                if not instanceInList(inst, hasViewList) then
                    hasViewList.addLast inst
                end if
            end if
            call addViewsToList(hasViewList, child)
        next

    End Sub

   '---------------------------------------------------------------------------------------------------
    Private Function findContainer(parent, contType, contName)
        dim container, containers
        dim foundContainer

        set findContainer = Nothing
        set foundContainer = Nothing
        set containers = parent.parts
        for each container in containers
            if container.type.uri = contType.uri then
                if container.name = contName then
                    set foundContainer = container
                    exit for
                else
                    set foundContainer = findContainer(container, contType, contName)
                end if
            end if
        next
        if isEnabled(foundContainer) then
            set findContainer = foundContainer
        end if
    End Function

'-----------------------------------------------------------
    Private Sub connectLanguageModel()
        dim langModel
        dim obj, rel
        dim langObjView
'stop
        if Len(LanguageModel) > 0 then
            set langModel = metis.findInstance(LanguageModel)
            if isEnabled(langModel) then
                set langObjView = langModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to language model specification container
                    set obj = work_window.instance
                    set rel = config.model.newRelationship(hasLanguageType, obj, langModel)
                    ' Create metamodel and connect to model
                    if isEnabled(addMetamodelMethod) then
                        set config.model.currentInstance = langModel
                        set config.modelView.currentInstanceView = langObjView
                        call config.model.runMethodOnInst(addMetamodelMethod, langModel)
                        set config.model.currentInstance = config.inst
                        set config.modelView.currentInstanceView = config.instView
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectModelContext()
        dim specModel
        dim obj, rel
        dim specObjView
        dim context

        if Len(ModelContextModel) > 0 then
            set specModel = metis.findInstance(ModelContextModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to model context specification container
                    set obj = work_window.instance
                    set rel = config.model.newRelationship(hasModelContextType, obj, specModel)
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectFilter()
        dim specModel
        dim obj, rel
        dim specObjView
        dim context

        if Len(FilterModel) > 0 then
            set specModel = metis.findInstance(FilterModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to model context specification container
                    set obj = work_window.instance
                    set rel = config.model.newRelationship(hasFilterType, obj, specModel)
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectInstanceContext()
        dim specModel
        dim specObjView
        dim cvwContentSpec
        dim contextObj, obj, rel
        dim instances
        dim cvwInstance
        dim instName
        dim workarea, titleObj
        dim indx

        'if Len(InstanceContextModel) > 0 then
            'set specModel = metis.findInstance(InstanceContextModel)
            'if isEnabled(specModel) then
                'set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to instanceContext specification container
                    set obj = work_window.instance
                    set rel = config.model.newRelationship(hasInstanceContextType, obj, Config.Info)
                    ' Connect rel from window to actual context instance
                    set cvwContentSpec = new CVW_ContentSpecification
                    set cvwContentSpec.currentModel     = config.model
                    set cvwContentSpec.currentModelView = config.modelView
                    set cvwContentSpec.contentModel     = contentModel
                    set cvwContentSpec.contextInstance  = Config.Info '??
                    cvwContentSpec.SearchMode           = "SelectOneFromList"
                    cvwContentSpec.PathMode             = "NoPath"
                    cvwContentSpec.SpecificationModel   = contentModel
                    ' Find actual context instance
                    set instances = cvwContentSpec.execute
                    if instances.count > 0 then
                        set contextObj = instances(1)
                        set rel = config.model.newRelationship(hasInstanceContext2Type, obj, contextObj)
                        set cvwInstance = new CVW_Instance
                        set cvwInstance.currentInstance = work_window.instance
                        set cvwInstance.currentInstanceView = work_window
                        instName = cvwInstance.getInstanceName
                        set cvwInstance = Nothing
                        if Len(instName) > 0 then
                            set workarea = work_window.parent
                            indx = workarea.children.count
                            if indx > 1 then
                                set titleObj = workarea.children(1).instance
                                titleObj.name = instName
                                titleObj.title = instName
                            end if
                        end if
                    end if
                end if
           ' end if
        'end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectViewStrategy()
        dim specModel
        dim obj, rel
        dim specObjView
        dim strategyCont, strategyConts
        dim cvwViewStrategy
        dim ekaInstance

        if Len(ViewStrategyModel) > 0 then
            set specModel = metis.findInstance(ViewStrategyModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to viewstrategy specification container
                    set obj = work_window.instance
                    set rel = config.model.newRelationship(hasViewStrategyType, obj, specModel)
                    ' Check for properties
                    set cvwViewStrategy = new CVW_ViewStrategy
                    call cvwViewStrategy.build(strategyCont)
                    set ekaInstance = new EKA_Instance
                    WindowLayoutStrategy = ekaInstance.getPropertyValue(specModel, "WorkwinLayoutStrategy")
                    if Len(WindowLayoutStrategy) > 0 then
                        set workwinLayoutStrategy = metis.findLayoutStrategy(WindowLayoutStrategy)
                        set work_window.layoutStrategy = workwinLayoutStrategy
                    end if
                    set ekaInstance = Nothing
                    set cvwViewStrategy = Nothing
                    ' Create metamodel and connect to model
                    if isEnabled(addPartRuleMethod) then
                        set config.model.currentInstance = specModel
                        set config.modelView.currentInstanceView = specObjView
                        call config.model.runMethodOnInst(addPartRuleMethod, specModel)
                        set config.model.currentInstance = config.inst
                        set config.modelView.currentInstanceView = config.instView
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub connectContentSearchModel(searchModel)
        dim specModel
        dim wObject, rel
        dim specObjView
        dim searchConts
        dim context

        if Len(searchModel) > 0 then
            set specModel = metis.findInstance(searchModel)
            if isEnabled(specModel) then
                set specObjView = specModel.views(1)
                if isEnabled(work_window) then
                    ' Connect rel from work_window to model context specification container
                    set wObject = work_window.instance
                    set searchConts = wObject.getNeighbourObjects(0, hasSearchSpecificationType, specContainerType)
                    if searchConts.count = 0 then
                        set rel = config.model.newRelationship(hasSearchSpecificationType, wObject, specModel)
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub doWorkspaceLayout(objView)
        'dim layoutStrategy
        'dim workspaceLayoutStrategy
               ' set workspaceLayoutStrategy = objView.layoutStrategy
       ' set layoutStrategy = metis.findLayoutStrategy("http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#_002ash3011bccb0hs5tr")
       ' set objView.layoutStrategy = layoutStrategy
       ' call metis.doLayout(objView)
       ' set objView.layoutStrategy = workspaceLayoutStrategy
       ' call metis.doLayout(objView)
        dim noWindows
        
		' CVW Matrix Swimlane
		noWindows = Workspace.WorkspaceWindow.children.count
		if noWindows <= 4 then
			Workspace.LayoutStrategy = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#_002asku01kfln2ekgenp"
		elseif noWindows <= 9 then
			Workspace.LayoutStrategy = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#_002asmr01a0gisog7tn2"
		else
			Workspace.LayoutStrategy = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#_002asmr018p5t7j8b6cr"
		end if
		Workspace.execute
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set parameters = Nothing

        ' Types
        set titlebarType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set windowType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set window2Type     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea2_UUID")
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set hasFilterType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasFilterSpecification_UUID")
        set hasLanguageType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification2_UUID")
        set hasViewStrategyType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        set hasModelContextType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasModelContext_UUID")
        set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
        set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set specContainerType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasSearchSpecificationType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasSearchSpecification_UUID")
        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        ' Methods
        set addMetamodelMethod  = metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/spec_methods.kmd#addVirtualMetamodel")
        set addPartRuleMethod   = metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/spec_methods.kmd#addPartRules")
        ' Arguments
        TreeTextScale        = -1
        NestedTextScaleTop   = -1
        NestedTextScale      = -1
        ObjectAspectRatio    = -1
        WindowLayoutStrategy = ""
        RelationshipViewMode = "Hierarchy"
        ContentInRepository  = false
        set window    = new CVW_Window
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()

    End Sub

End Class


