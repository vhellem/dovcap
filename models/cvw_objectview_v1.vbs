option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ObjectView


    ' Variant parameters
    Public Title                          ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public nestedTextFactor1
    Public nestedTextFactor2
    Public treeTextFactor

'-----------------------------------------------------------
    Public Function create(workWindow, parentInstView, obj, aspectRatio)
        dim objView
        dim objGeo, size
        dim textscale

        set create = Nothing
        set objView = parentInstView.newObjectView(obj)
        if isValid(objView) then
            if aspectRatio > 0 then
                set objGeo = objView.absScaleGeometry
                set size = objGeo.size
                size.height = aspectRatio * size.width
                set objGeo.size = size
                set objView.absScaleGeometry = objGeo
            end if
            ' Handle textscale
            textscale = getTextScaleFactor(workWindow, parentInstView, objView)
            objView.textScale = textScale
            set create = objView
        end if
    End Function

'-----------------------------------------------------------
    Private Function getTextScaleFactor(workWindow, parentView, instView)
        dim parentTs, instTs
        dim pView
        dim textscale
        dim i, level

        parentTs = workWindow.textscale
        if instView.isNested then
            level = 0
            set pView = parentView
            do while isValid(pView)
                if pView.uri = workWindow.uri then
                    exit do
                end if
                set pView = pView.parent
                level = level + 1
            loop
            textScale = parentTs * nestedTextFactor1
            for i = 1 to level
                textScale = textScale * nestedTextFactor2
            next
        else
            getTextScaleFactor = parentTs * treeTextFactor
        end if
        getTextScaleFactor = textscale

    End Function
'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView

        nestedTextFactor1 = 1.75
        nestedTextFactor2 = 1.1
        treeTextFactor    = 1
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

