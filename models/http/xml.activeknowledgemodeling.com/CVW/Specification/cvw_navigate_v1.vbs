option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Navigate

    ' Variant parameters
    Public Title                          ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public NoNeighbourLevels

    ' Types
    Private specContainerType
    Private hasLanguageModelType

    ' Other arguments
    Private cvwCL
    Private noRelRules
    Private relRules()

    '-----------------------------------------------------------
    Public Sub addNeighbours(workWindow, objView)
        dim wObject, obj
        dim languageCont, languageConts
        dim cvwLanguageSpec
        dim rel, rels, relDir
        dim selected
        dim size, pos
        dim level, i, no

        if isValid(workWindow) and isEnabled(objView) then
            level = 0
            ' Resize and position current object
            set cvwCL.WorkWindow = workWindow
            set cvwCL.CenterObjectView = objView
            cvwCL.NoLevels = NoNeighbourLevels
            call cvwCL.build
            set size = cvwCL.getObjectSize(0, objView)
            set pos  = cvwCL.getObjectPosition(level, objView, size, 0, 0)
            call cvwCL.populate(level, objView, size, pos)
            set wObject = workWindow.instance
            set obj = objView.instance
            set selected = metis.newInstanceList
            call selected.addLast(obj)
            call currentModelView.select(selected)
            ' Get language constraints
            set languageConts = wObject.getNeighbourObjects(0, hasLanguageModelType, specContainerType)
            if languageConts.count > 0 then
                set languageCont = languageConts(1)
                set cvwLanguageSpec = new CVW_LanguageSpecification
                call cvwLanguageSpec.build(languageCont)
            end if
            ' Find neighbors
            set rels = obj.neighbourRelationships
            if isValid(rels) then
                i = 0
                no = 0
                level = level + 1
                for each rel in rels
                    if cvwLanguageSpec.relIsAllowed(rel) then no = no + 1
                next
                for each rel in rels
                    if cvwLanguageSpec.relIsAllowed(rel) then
                        if rel.origin.uri = obj.uri then
                            relDir = 0
                        else
                            relDir = 1
                        end if
                        i = i + 1
                        call addNeighbourView(workWindow, relDir, objView, rel, level, i, no)
                    end if
                next
            end if

        end if
    End Sub

    '-----------------------------------------------------------
    Private Sub addNeighbourView(workWindow, relDir, objView, rel, level, i, no)
        dim obj, relView
        dim originView, originViews
        dim targetView, targetViews
        dim l

        ' Create relationship view
        l = level
        if relDir = 0 then
            set obj = rel.target
            set targetView = viewExists(obj, workWindow)
            if not isValid(targetView) then
                set targetView = addObjectView(workWindow, obj, l, i, no)
            end if
            set originView = objView
        else
            set obj = rel.origin
            set originView = viewExists(obj, workWindow)
            if not isValid(originView) then
                set originView = addObjectView(workWindow, obj, l, i, no)
            end if
            set targetView = objView
        end if
        if isValid(originView) and isValid(targetView) then
            set relView = relViewExists(rel, originView, targetView)
            if not isValid(relView) then
                set relView = currentModelView.newRelationshipView(rel, originView, targetView)
            end if
        end if
    End Sub

    '-----------------------------------------------------------
    Private Function addObjectView(workWindow, obj, level, i, no)
        dim objView
        dim textscale
        dim size, pos

        set addObjectView = Nothing
        ' Create object view
        set objView = workWindow.newObjectView(obj)
        set size = cvwCL.getObjectSize(level, objView)
        set pos  = cvwCL.getObjectPosition(level, objView, size, i, no)
        call cvwCL.populate(level, objView, size, pos)
        if objView.isNested then
            objView.close
            textScale = workWindow.textScale
            textScale = textscale * 1.75
        else
            textscale = 0.5
        end if
        objView.textScale = textScale
        set addObjectView = objView
    End Function

    '-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView

        ' Types
        set specContainerType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasLanguageModelType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification2_UUID")
        ' CVW objects
        set cvwCL = new CVW_CircularLayout
        NoNeighbourLevels = 1
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

