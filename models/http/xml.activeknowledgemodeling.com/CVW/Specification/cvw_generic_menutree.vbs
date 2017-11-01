option explicit

Class	CVW_GenericMenuTree
' HDJ added support form other types of elements than buttons
' Replaces cvw_menutree.vbs

' Context variables
    Private model
    Private modelView
    Private inst
    Private instView

    ' Arguments
    Private MenuLayout
    Private LeftPaneLayout
    Private LeftPaneTreeLayout
    Private MenuSymbol
    Private LeftPaneSymbol

    ' Types
    Private winType
    Private buttonType
    Private consistsOfType
    Private equalsType
    Private menuLayoutStrategy
    Private leftPaneLayoutStrategy
    Private leftPaneTreeLayoutStrategy

    ' Others
    Private kindProperty
    Private scriptProperty
    Private kind
    Private argObj
    Private cvwWindow
    Private winName
    Private parentView

   '---------------------------------------------------------------------------------------------------
    Public Sub build(mode, textScale, scaleFactor)    ' mode = "TopMenu" | "NodeMenu"

        if mode = "MenuTree" then
            set parentView = findInstanceView(model, winType, "name", "CVW_LeftPane")
            winName = "CVW_MenuLevel1"
            ' Check if window already exists. If so, remove
            if cvwWindow.find(winName, winType, parentView) then
                cvwWindow.remove
            end if
            ' Create new window
            if cvwWindow.create(winName, winType, parentView) then
                call populateMenu1()
                if isValid(menuLayoutStrategy) then
                    set parentView.children(1).layoutStrategy = menuLayoutStrategy
                end if
                if LeftPaneSymbol <> "" then
					parentView.openSymbol   = LeftPaneSymbol
					parentView.closedSymbol = LeftPaneSymbol
				end if
				if MenuSymbol <> "" then
					parentView.children(1).openSymbol      = MenuSymbol
					parentView.children(1).closedSymbol    = MenuSymbol
				end if
                parentView.children(1).textScale       = textScale
                parentView.children(1).geometry.width  = parentView.children(1).geometry.width * scaleFactor
                parentView.children(1).geometry.height = parentView.children(1).geometry.height * scaleFactor
                call cvwWindow.doParentLayout
            end if
        elseif mode = "MenuNode" then
            set parentView = instView
            if parentView.children.count > 0 then
                call cleanTree(modelView, parentView)
                call parentView.close
            else
                call populateMenu2(textScale, scaleFactor)
                if isValid(leftPaneTreeLayoutStrategy) then
                    set parentView.layoutStrategy = leftPaneTreeLayoutStrategy
                end if
                call cvwWindow.doParentLayout
            end if
        end if
    End Sub

'-----------------------------------------------------------
  public  Sub populateMenu1()
        Dim objectMenuType, objectMenuItem, obj, query
        Dim newObjectMenu
        set obj = getEqualObject(inst)
        set query = getQuery(obj)
        if isEnabled(query) then 
        ' perform query to populate the menu
			call populateByQuery(query, 0, 0, cvwWindow.objectView)
		else
			For each objectMenuItem in obj.neighbourRelationships
				Set newObjectMenu = objectMenuItem.target
				if isType(newObjectMenu, obj.type) then
					call populate(newObjectMenu, 0, 0, cvwWindow.objectView)
				end if
			next
			For each newObjectMenu in obj.parts
				if isType(newObjectMenu, obj.type) then
					call populate(newObjectMenu, 0 , 0, cvwWindow.objectView)
				end if
			next
		end if
    End Sub
    
    public sub populateMenu2(textScale, scaleFactor)    ' textScale = 0.05, scaleFactor = 1.3
        dim  item, itemView, newItemView, rel, obj, query
        on error resume next
        set obj = getEqualObject(inst)
		set query = getQuery(obj)
        if isEnabled(query) then 
			' perform query to populate the menu
			call populateByQuery(query, textScale, scaleFactor, instView)
		else
			'For each rel in obj.getNeighbourRelationships(0, consistsOfType)
			'	if isEnabled(rel) then
			'		set item = rel.target
			'		'kind = "Menu"
			'		if isEnabled(item) then
			'			'kind = item.getNamedStringValue(kindProperty)
			'			'if kind = "Menu" then
			'			if isType(newObjectMenu, obj.type) then
			'				call populate(item, textScale, scaleFactor, instView)
			'			end if
			'		end if
			'	end if
			'next
			For each rel in obj.neighbourRelationships
				Set item = rel.target
				if isType(item, obj.type) and not (item.uri = obj.uri) then
					call populate(item, textScale, scaleFactor, instView)
				end if
			next
			For each item in obj.parts
				if isType(item, obj.type) then
				'msgbox("Item: "&item.getNamedStringValue("name"))
					call populate(item, textScale, scaleFactor, instView)
				end if
			next
		end if
    end sub
    
   public sub populate(byval newObject, byval textScale, byval scaleFactor, byval parentview)
		Dim menuitem , newobjectMenuView, objectMenuView, nm, codestring 
		set menuitem = newObject
		set newobjectMenuView = Nothing
        if menuitem.type.uri <> buttonType.uri THEN 
			' general object - reuse associated actionbutton if existing (equals relationship)
			set menuitem = getEqualObject2(menuitem, buttonType)
		end if
		if menuitem.type.uri = buttonType.uri THEN
			if menuitem.title <> inst.title THEN
				'kind = newObjectMenu.getNamedStringValue(kindProperty)
				'if kind = "Menu" then
					Set newObjectMenuView = parentView.newObjectView(menuitem)
				'end if
			end if
		else
			' general object without associated actionbutton - create new actionbutton
			Set menuitem = model.newObject(buttonType)
			nm = newObject.getNamedStringValue("name")
			call menuitem.setNamedStringValue("name", nm)
			
			codestring = "dim instview"
			codestring = codestring & vbCRLf & "set instView = metis.currentModel.currentModelView.currentInstanceView"
			codestring = codestring & vbCRLf& "if instView.children.count > 0 then" 
			codestring = codestring & vbCRLf& "   call cleanTree(metis.currentModel.currentModelView, instView)" 
            codestring = codestring & vbCRLf& "   call instView.close"
			codestring = codestring & vbCRLf& "else "
			codestring = codestring & vbCRLf& " if (not isValid(instView.parent)) or (instView.parent.instance.type.uri <> instView.instance.type.uri) then" ' max two levels
			codestring = codestring & vbCRLf& "   dim cvwMenu2"
			codestring = codestring & vbCRLf& "   set cvwMenu2 = new CVW_GenericMenuTree"
			codestring = codestring & vbCRLf& "   call cvwMenu2.build("&Chr(34)&"MenuNode"&Chr(34)&", 0.05, 1.3)"
			codestring = codestring & vbCRLf& " end if"
			codestring = codestring & vbCRLf& "if instView.children.count = 0 then"  ' do not open view if opened submenu
			codestring = codestring & vbCRLf& " Dim action"&vbCRLf& "set action = new CVW_GenericAction" &vbCRLf& "call action.execute"
			codestring = codestring & vbCRLf& "end if" 
			codestring = codestring & vbCRLf& "end if"


			call menuitem.setNamedStringValue("script", codestring )
		
			call model.newRelationship(equalsType, menuitem, newObject) 
			  
			Set newObjectMenuView = parentview.newObjectView(menuitem)
		
			Set menuitem = newObject ' for setting below
		end if

		if isEnabled(newobjectMenuView) then
			newobjectMenuView.openSymbol    = "http://xml.hydro.com/views/symbols.svg#_002asnd00ssha9fmf0ru" 'menuitem.Views(1).openSymbol
			newobjectMenuView.closedSymbol  = "http://xml.hydro.com/views/symbols.svg#_002asnd00ssha9sfv9i0" 'menuitem.Views(1).closedSymbol
			if textScale >0 then
				newobjectMenuView.textScale       = textScale
			else
				newobjectMenuView.textScale     = 0.08
			end if
			if scaleFactor > 0 then
			newobjectMenuView.geometry.width  = parentview.geometry.width * scaleFactor
			newobjectMenuView.geometry.height = parentview.geometry.height * scaleFactor
			end if
			newobjectMenuView.close
			parentview.open
		end if
	end Sub
	
	'---------------------------------------------------------------------------------------------------	
	public sub populateByQuery(query, textScale, scaleFactor, parentView)
		dim instances, newObjectMenu
		
		' Build and execute
		Dim s
		set s = new CVW_GenericSearch
		
		set instances = s.search(query)
		For each newObjectMenu in instances
			call populate(newObjectMenu, textScale, scaleFactor, parentView)
		next
	end sub


	'------------------------------------------------------------------------------------------------------
	' return Nothing if there is not query associated with the given object, or a query object (specification container) if it is
	' in the future, queris should be inherited from e.g. the type, and parameterised
	'------------------------------------------------------------------------------------------------------
	public function getQuery(byval object)
		set getQuery = Nothing
		if isType(object, metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")) then
			set getQuery = object
		end if
	end function
   '---------------------------------------------------------------------------------------------------
    private Sub Class_Initialize
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set inst            = model.currentInstance
        set instView        = modelView.currentInstanceView
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set winType         = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set equalsType		= metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Equals_UUID")
        set cvwWindow       = new CVW_Window
        set argObj          = new CVW_ArgumentValue
        kindProperty        = "kind"
        scriptProperty		= "script"
        MenuLayout          = argObj.getArgumentValue(inst, "MenuLayout")
        if MenuLayout = "" then 
			MenuLayout = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#Layout_CVW:MenuLayoutVertical"
        end if 
        LeftPaneLayout      = argObj.getArgumentValue(inst, "LeftPaneLayout") '
        LeftPaneTreeLayout  = argObj.getArgumentValue(inst, "LeftPaneTreeLayout") 
        if LeftPaneTreeLayout = "" then 
			LeftPaneTreeLayout = "http://xml.activeknowledgemodeling.com/cvw/views/cvw_layout_strategies.kmd#Layout_CVW:WorkareaVertical"
        end if
        MenuSymbol          = argObj.getArgumentValue(inst, "MenuSymbol") 
        if MenuSymbol = "" then 
			MenuSymbol = "http://xml.hydro.com/views/symbols.svg#_002asng00r9815hq7rrn"
        end if
        LeftPaneSymbol      = argObj.getArgumentValue(inst, "LeftPaneSymbol") 
        if LeftPaneSymbol = "" then 
			LeftPaneSymbol = "http://xml.hydro.com/views/symbols.svg#_002asng00r9815hq7rrn"
        end if
        set menuLayoutStrategy          = metis.findLayoutStrategy(MenuLayout)
        set leftPaneLayoutStrategy      = metis.findLayoutStrategy(LeftPaneLayout)
        set leftPaneTreeLayoutStrategy  = metis.findLayoutStrategy(LeftPaneTreeLayout)
        ' itemsymbol http://xml.hydro.com/views/symbols.svg#_002asnd00ssha9fmf0ru
    End Sub
   '---------------------------------------------------------------------------------------------------

End Class
