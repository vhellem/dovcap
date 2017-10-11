option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Window

    Public title                  ' String
    Public size                   ' IMetisRect
    Public layoutStrategy         ' IMetisInstance
    Public objectView             ' IMetisObjectView
    Private model                 ' IMetisModel
    Private modelView             ' IMetisModelView
    Private noSubWindows          ' Integer
    Private subWindows()          ' Array of CVW_Window's
    Private pos                   ' Enum of strings

'-----------------------------------------------------------
    Public Function create(name, winType, parentView)    ' as Boolean
        dim parent, obj, window

        create = false
        if isEnabled(parentView) then
            if parentView.hasInstance then
                set parent = parentView.instance
                set obj = parent.newPart(winType)
	            call obj.setNamedStringValue("name", name)
	            set window = parentView.newObjectView(obj)
                if isEnabled(window) then
                    set objectView = window
                    title = name
                    create = true
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function find(name, winType, parentView)      ' as Boolean
        dim objViews, objView, obj

        find = false
        if isValid(parentView) then
            set objViews = parentView.children
            for each objView in objViews
                if isEnabled(objView) then
                    if objView.hasInstance then
                        set obj = objView.instance
                        if obj.name = name then
                            set objectView = objView
                            find = true
                            exit for
                        end if
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function find2(winType, parentView, instView)      ' as Boolean
        dim objViews, objView, obj

        find2 = false
        if isValid(parentView) then
            set objViews = parentView.children
            for each objView in objViews
                if isEnabled(objView) then
                    if objView.uri = instView.uri then
                        set objectView = objView
                        find2 = true
                        exit for
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Sub addSubWindow(pos, name, winType)
        dim cvwWin
        dim indx, found
        
        found = false
        for indx = 1 to noSubWindows
            set cvwWin = subWindows(indx)
            if not cvwWin is Nothing then
                if cvwWin.title = name and cvwWin.Position = pos then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            set cvwWin = new CVW_Window
            call cvwWin.create(name, winType, objectView)
            cvwWin.title = name
            cvwWin.Position = pos
            ' Maintain the array
            noSubWindows = noSubWindows + 1
            ReDim Preserve subWindows(noSubWindows)
            set subWindows(noSubWindows) = cvwWin
        end if

    End Sub

'-----------------------------------------------------------
    Public Sub removeSubWindow(pos, name, winType)
        dim cvwWin
        dim indx, ix, found

        found = false
        for indx = 1 to noSubWindows
            set cvwWin = subWindows(indx)
            if not cvwWin is Nothing then
                if cvwWin.title = name and cvwWin.Position = pos then
                    found = true
                    cvwWin.remove
                    if indx = noSubWindows then
                        noSubWindows = noSubWindows - 1
                        ReDim Preserve subWindows(noSubWindows)
                    end if
                    exit for
                end if
            end if
        next
        if found  and indx < noSubWindows then
            for ix = indx to noSubWindows - 1
                set subWindows(ix) = subWindows(ix + 1)
            next
            noSubWindows = noSubWindows - 1
            ReDim Preserve subWindows(noSubWindows)
        end if

    End Sub

'-----------------------------------------------------------
    Public Sub clean()
        dim children, childView

        if isEnabled(objectView) then
            set children = objectView.children
            for each childView in children
                modelView.deleteObjectView(childView)
            next
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub remove()
        if isEnabled(model) and isEnabled(objectView) then
            if objectView.hasInstance then
                call model.deleteObject(objectView.instance)
                set objectView = Nothing
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub populate()
    End Sub

'-----------------------------------------------------------
    Public Sub doLayout()
        if isEnabled(objectView) then
            call metis.doLayout(objectView)
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub doParentLayout()
        if isEnabled(objectView) then
            call metis.doLayout(objectView.parent)
        end if
    End Sub

'-----------------------------------------------------------
    Public Property Let Position(strPos)
        select case strPos
            case "Top"    pos = 1
            case "Bottom" pos = 2
            case "Left"   pos = 3
            case "Right"  pos = 4
        End select
    End Property

    Public Property Get Position
        Select Case pos
            case 1  Position = "Top"
            case 2  Position = "Bottom"
            case 3  Position = "Left"
            case 4  Position = "Right"
        End Select
    End Property

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set model = metis.currentModel
        set modelView = model.currentModelView
        set objectView = Nothing
        set size = Nothing
        set layoutStrategy = Nothing
        noSubWindows = 0
        ReDim subWindows(noSubWindows)
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub


'------------------------------------------------------------------------------------------
' -------------------------ST ----------------------------------------------------------
'------------------------------------------------------------------------------------------

    Public Function getInstView(objectType, propertyName, PropertyValue)
     dim inst

     set inst = model.findInstances(objectType ,propertyName,PropertyValue)
     if inst.count > 0 then
        set getInstView =  inst.item(1).views(1)
    else
        set getInstView = Nothing
   end if
   End Function

'-----------------------------------------------------------
    Public Sub populateMenu(objectMenu, objectTargetType)
    '[a]-------------------------------
        Dim objectMenuType, objectMenuItems
        Dim  newObjectMenu, newObjectMenuView, objectMenuView

           For each objectMenuItems in objectMenu.instance.neighbourRelationships
              Set newObjectMenu = objectMenuItems.target
              if objectMenuItems.target.type.uri = objectTargetType.uri THEN
                  if objectMenuItems.target.title <> objectMenu.title THEN
                       Set newObjectMenuView                 = objectView.newObjectView(newObjectMenu)
                       newobjectMenuView.openSymbol    = newObjectMenu.Views(1).openSymbol
                       newobjectMenuView.closedSymbol  = newObjectMenu.Views(1).closedSymbol
                       newobjectMenuView.textScale         = 0.08
                       newobjectMenuView.close
                  end if
              end if
            next

    End Sub


End Class
'-----------------------------------------------------------
'-----------------------------------------------------------


