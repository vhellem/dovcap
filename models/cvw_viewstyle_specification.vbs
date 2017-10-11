option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ViewstyleSpecification

    Public  title                       ' String
    Public viewStyle                    ' URI

    Private model
    Private modelView
    Private noObjectVisualizations      ' Integer
    Private noRelshipVisualizations     ' Integer
    Private objectVisualizations()      ' Array of CVW_ObjectVisualization
    Private relshipVisualizations()     ' Array of CVW_RelshipVisualization
    ' Types
    Private argumentType

'-----------------------------------------------------------
    Public Sub build(spec_object)
        dim argObj
    
        if isEnabled(spec_object) then
            ' Check for viewstyle
            set argObj = new CVW_ArgumentValue
            viewStyle = argObj.getArgumentValue(spec_object, "WorkareaViewstyle")
            ' Check for Object viewstyle specification object

            ' Check for Relship viewstyle specification object

        end if

    End Sub

'-----------------------------------------------------------
    Public Sub setViewstyle
        on error resume next
        if Len(viewStyle) > 0 then
            modelView.setViewStyle(viewStyle)
        end if
    End Sub

'-----------------------------------------------------------
    Public Function findObjectVisualization(visTitle)
        dim indx, objVis

        set findObjectVisualization = Nothing
        for indx = 1 to noObjectVisualizations
            set objVis = objectVisualizations(indx)
            if not objVis is Nothing then
                if objVis.title = visTitle then
                    set findObjectVisualization = objVis
                    exit for
                end if
            end if
        next

    End Function

'-----------------------------------------------------------
    Public Function findRelshipVisualization(visTitle)
        dim indx, relVis

        set findRelshipVisualization = Nothing
        for indx = 1 to noRelshipVisualizations
            set relVis = relshipVisualizations(indx)
            if not relVis is Nothing then
                if relVis.title = visTitle then
                    set findRelshipVisualization = relVis
                    exit for
                end if
            end if
        next

    End Function

'-----------------------------------------------------------
    Public Sub addObjectVisualization(objVisualization)
        dim cvwObjVisualization
        dim indx, found

        found = false
        for indx = 1 to noObjectVisualizations
            set cvwObjVisualization = objectVisualizations(indx)
            if not cvwObjVisualization is Nothing then
                if cvwObjVisualization.title = objVisualization.title then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noObjectVisualizations = noObjectVisualizations + 1
            ReDim Preserve objectVisualizations(noObjectVisualizations)
            set objectVisualizations(noObjectVisualizations) = objVisualization
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub addRelshipVisualization(relVisualization)
        dim cvwRelVisualization
        dim indx, found

        found = false
        for indx = 1 to noRelshipVisualizations
            set cvwRelVisualization = relshipVisualizations(indx)
            if not cvwRelVisualization is Nothing then
                if cvwRelVisualization.title = relVisualization.title then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noRelshipVisualizations = noRelshipVisualizations + 1
            ReDim Preserve relshipVisualizations(noRelshipVisualizations)
            set relshipVisualizations(noRelshipVisualizations) = relVisualization
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set model = metis.currentModel
        set modelView = model.currentModelView
        noObjectVisualizations = 0
        ReDim objectVisualizations(noObjectVisualizations)
        noRelshipVisualizations = 0
        ReDim relshipVisualizations(noRelshipVisualizations)
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub
End Class

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ObjectVisualization

    Public title              ' String
    Public layoutStrategy     ' IMetisInstance
    Public symbolOpen         ' Uri
    Public symbolClosed       ' Uri
    Public icon               ' Uri
    Public scaleFactor        ' Float
    Public textFactor         ' Float
    Public fillColor          ' String
    Public lineColor          ' String

End Class

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_RelshipVisualization

    Public title             ' String
    
    ' Variant parameters
    Public lineColor         ' String
    Public lineWidth         ' Integer
    Public lineStyle         ' String
    Public arrowKind         ' String
    Public useAutoline       ' Boolean
    Public useSpline         ' Boolean
    Public showStartText     ' Boolean
    Public showMiddleText    ' Boolean
    Public showEndText       ' Boolean
    
End Class


























