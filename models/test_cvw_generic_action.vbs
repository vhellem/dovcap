' VBScript source code
option explicit

    ' Context variables
    Dim model
    Dim modelView
    Dim inst
    Dim instView

    ' Arguments
    Dim MenuLayout
    Dim LeftPaneLayout
    Dim LeftPaneTreeLayout
    Dim MenuSymbol
    Dim LeftPaneSymbol

    ' Types
    Dim winType
    Dim buttonType
    Dim consistsOfType
    Dim equalsType
    Dim menuLayoutStrategy
    Dim leftPaneLayoutStrategy
    Dim leftPaneTreeLayoutStrategy

    ' Others
    Dim kindProperty
    Dim scriptProperty
    Dim kind
    Dim argObj
    Dim cvwWindow
    Dim winName
    Dim parentView
    

dim objView
dim cvwMenu, cvwStatusBar 

set model = metis.currentModel
set modelView = model.currentModelView
set objView = modelView.currentInstanceView

call Class_Initialize()
call build("MenuTree", 1.3, 1)

set cvwStatusBar = new CVW_StatusBar
cvwStatusBar.topMenuStatus(objView)
cvwStatusBar.populateStatusBars(objView)

' HDJ added support form other types of elements than buttons
' Replaces cvw_menutree.vbs

   '---------------------------------------------------------------------------------------------------
    Public Sub build(mode, textScale, scaleFactor)    ' mode = "TopMenu" | "NodeMenu"
        dim parentView

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
                parentView.openSymbol   = LeftPaneSymbol
                parentView.closedSymbol = LeftPaneSymbol
                parentView.children(1).openSymbol      = MenuSymbol
                parentView.children(1).closedSymbol    = MenuSymbol
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
    Sub populateMenu1()
        Dim objectMenuType, objectMenuItem, obj
        Dim newObjectMenu
        set obj = getEqualObject(inst)
        For each objectMenuItem in obj.neighbourRelationships
            Set newObjectMenu = objectMenuItem.target
			call populate(newObjectMenu)
        next
        For each newObjectMenu in obj.parts
			call populate(newObjectMenu)
        next
    End Sub
    
    sub populate(byval newObject)
		Dim menuitem , newobjectMenuView, objectMenuView, nm
		set menuitem = newObject
        if menuitem.type.uri <> buttonType.uri THEN 
			' general object - reuse associated actionbutton if existing (equals relationship)
			set menuitem = getEqualObject2(menuitem, buttonType)
		end if
		if menuitem.type.uri = buttonType.uri THEN
			if menuitem.title <> inst.title THEN
				'kind = newObjectMenu.getNamedStringValue(kindProperty)
				'if kind = "Menu" then
					Set newObjectMenuView           = cvwWindow.objectView.newObjectView(menuitem)
					newobjectMenuView.openSymbol    = menuitem.Views(1).openSymbol
					newobjectMenuView.closedSymbol  = menuitem.Views(1).closedSymbol
					newobjectMenuView.textScale     = 0.08
					newobjectMenuView.close
				'end if
			end if
		else
			' general object without associated actionbutton - create new actionbutton
			Set menuitem = model.newObject(buttonType)
			nm = newObject.getNamedStringValue("name")
			call menuitem.setNamedStringValue("name", nm)
			call menuitem.setNamedStringValue("script", "Dim action"&vbCRLf& "set action = new CVW_GenericAction" &vbCRLf& "call action.execute" )
			call model.newRelationship(equalsType, menuitem, newObject) 
			Set newObjectMenuView = cvwWindow.objectView.newObjectView(menuitem)
			newobjectMenuView.openSymbol    = newObject.Views(1).openSymbol
			newobjectMenuView.closedSymbol  = newObject.Views(1).closedSymbol
			newobjectMenuView.textScale     = 0.08
			newobjectMenuView.close
		end if
	end Sub
'---------------------------------------------------------------------------------------------------
    sub populateMenu2(textScale, scaleFactor)    ' textScale = 0.05, scaleFactor = 1.3
        dim  item, itemView, newItemView, rel
        on error resume next

        For each rel in inst.getNeighbourRelationships(0, consistsOfType)
            if isEnabled(rel) then
                set item = rel.target
                'kind = "Menu"
                if isEnabled(item) then
                    'kind = item.getNamedStringValue(kindProperty)
                    'if kind = "Menu" then
                        set newItemView             = instView.newObjectView(item)
                        newItemView.openSymbol      = item.Views(1).openSymbol
                        newItemView.closedSymbol    = item.Views(1).closedSymbol
                        newItemView.textScale       = textScale
                        newItemView.geometry.width  = newItemView.parent.geometry.width * scaleFactor
                        newItemView.geometry.height = newItemView.parent.geometry.height * scaleFactor
                        newItemView.close
                        newItemView.parent.open
                    'end if
                end if
            end if
        next
    end sub

   '---------------------------------------------------------------------------------------------------
    Sub Class_Initialize
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
        LeftPaneLayout      = argObj.getArgumentValue(inst, "LeftPaneLayout")
        LeftPaneTreeLayout  = argObj.getArgumentValue(inst, "LeftPaneTreeLayout")
        MenuSymbol          = argObj.getArgumentValue(inst, "MenuSymbol")
        LeftPaneSymbol      = argObj.getArgumentValue(inst, "LeftPaneSymbol")
        set menuLayoutStrategy          = metis.findLayoutStrategy(MenuLayout)
        set leftPaneLayoutStrategy      = metis.findLayoutStrategy(LeftPaneLayout)
        set leftPaneTreeLayoutStrategy  = metis.findLayoutStrategy(LeftPaneTreeLayout)
    End Sub
   '---------------------------------------------------------------------------------------------------

' in case the specObject is just a placeholder for a real object, return that, else return inputted obj
function getEqualObject(Byval specObject)
	dim rel
	set getEqualObject = specObject
	 For each rel in specObject.getNeighbourRelationships(0, equalsType) 
		set getEqualObject = rel.target
		Exit function
	 next
	 For each rel in specObject.getNeighbourRelationships(1, equalsType) 
		set getEqualObject = rel.origin
		Exit function
	 next
end function

function getEqualObject2(Byval specObject, byval objtype)
	dim rel
	set getEqualObject2 = specObject
	 For each rel in specObject.getNeighbourRelationships(0, equalsType)
		if isType(rel.target, objType) then
			set getEqualObject2 = rel.target
		end if
		Exit function
  next
  For each rel in specObject.getNeighbourRelationships(1, equalsType)
	if isType(rel.origin, objType) then
		set getEqualObject2 = rel.origin
	end if
	Exit function
  next
end function

' return true of obj is instanece of type, or has Is relationship to the typ object
function isType(byval obj, byval typ)
 isType = false
 if obj.type.inherits(typ) then
  isType = true
 end if
end function


