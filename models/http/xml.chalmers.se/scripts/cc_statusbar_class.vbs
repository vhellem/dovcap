option explicit

class CC_StatusBar

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView

'------------------------------------------------------------
    Public Sub topMenuStatus (instView)
        dim topMenuObject, inst

        set inst = instView.instance
        For each topMenuObject in instView.parent.children
            if topMenuObject.title = inst.title then
                topMenuObject.open
            else
                topMenuObject.close
            end if
        next

    end sub

'------------------------------------------------------------
    Public  sub populateStatusBars(instView)
        Dim  titleBarType, titleBar, titleBarString

        set titleBarType  = metis.findType("http://metadata.troux.info/meaf/objecttypes/general_object.kmd#CompType_MEAF:GeneralObject_UUID")
        set titleBar  = model.findInstances(titleBarType, "comments" ,"CVW_TitleBar")

        set cvwWorkarea = new CVW_Workarea
        set cvwWorkarea.WorkWindow = workWindow



        titleBarString = "> " & instView.title
        titleBar.item(1).setNamedStringValue "name", titleBarString
    end sub


'-----------------------------------------------------------
    Private Function contentModel           'IMetisObject
        dim context

        ' Find ContentModel
        set contentModel = currentModel
        set context = new EKA_Context
        set context.currentModel        = currentModel
        set context.currentModelView    = currentModelView
        set context.currentInstance     = work_window.instance
        set context.currentInstanceView = work_window
        if isValid(context) then
            set contentModel = context.contentModel
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        ' Assume started on button
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class

