option explicit

Class CVW_MenuTree

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
    Private menuLayoutStrategy
    Private leftPaneLayoutStrategy
    Private leftPaneTreeLayoutStrategy

    ' Others
    Private kindProperty
    Private kind
    Private argObj
    Private cvwWindow
    Private winName
    Private parentView

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
    Public Sub populateMenu1()
        Dim objectMenuType, objectMenuItem
        Dim  newObjectMenu, newObjectMenuView, objectMenuView

            For each objectMenuItem in inst.neighbourRelationships
                Set newObjectMenu = objectMenuItem.target
                if newObjectMenu.type.uri = buttonType.uri THEN
                    if newObjectMenu.title <> inst.title THEN
                        kind = newObjectMenu.getNamedStringValue(kindProperty)
                        if kind = "Menu" then
                            Set newObjectMenuView           = cvwWindow.objectView.newObjectView(newObjectMenu)
                            newobjectMenuView.openSymbol    = newObjectMenu.Views(1).openSymbol
                            newobjectMenuView.closedSymbol  = newObjectMenu.Views(1).closedSymbol
                            newobjectMenuView.textScale     = 0.08
                            newobjectMenuView.close
                        end if
                  end if
              end if
            next

    End Sub

'---------------------------------------------------------------------------------------------------
    sub populateMenu2(textScale, scaleFactor)    ' textScale = 0.05, scaleFactor = 1.3
        dim  item, itemView, newItemView, rel
        on error resume next

        For each rel in inst.getNeighbourRelationships(0, consistsOfType)
            if isEnabled(rel) then
                set item = rel.target
                kind = "Menu"
                if isEnabled(item) then
                    kind = item.getNamedStringValue(kindProperty)
                    if kind = "Menu" then
                        set newItemView             = instView.newObjectView(item)
                        newItemView.openSymbol      = item.Views(1).openSymbol
                        newItemView.closedSymbol    = item.Views(1).closedSymbol
                        newItemView.textScale       = textScale
                        newItemView.geometry.width  = newItemView.parent.geometry.width * scaleFactor
                        newItemView.geometry.height = newItemView.parent.geometry.height * scaleFactor
                        newItemView.close
                        newItemView.parent.open
                    end if
                end if
            end if
        next
    end sub

   '---------------------------------------------------------------------------------------------------
    Private Sub Class_Initialize
        set model           = metis.currentModel
        set modelView       = model.currentModelView
        set inst            = model.currentInstance
        set instView        = modelView.currentInstanceView
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set consistsOfType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set winType         = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        set cvwWindow       = new CVW_Window
        set argObj          = new CVW_ArgumentValue
        kindProperty        = "kind"
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


End Class
