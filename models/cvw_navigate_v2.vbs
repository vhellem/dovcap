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
    Public RelDirection                   ' Integer = -1 | 0 | 1
    Public ClearMode                      ' String  = NoClear | Clear
    Public LayoutMode                     ' Auto | Circular
    Public AskForObjectType               ' Boolean
    Public NeighbourObjectType            ' URI
    Public NeighbourRelshipType           ' URI
    Public ObjectAspectRatio              ' Float  = Height / Width
    Public RelationshipViewMode

    ' Types
    Private specContainerType
    Private hasInstanceContextType        ' IMetisType
    Private hasLanguageModelType
    Private hasViewStrategyType
    Private neighbourObjType
    Private neighbourRelType
    Private propertyType
    Private hasPropertyType

    ' Other arguments
    Private cvwCL
    Private noRelRules
    Private relRules()

    '-----------------------------------------------------------
    Public Sub addNeighbours(workWindow, objView)
        dim wObject, obj
        dim cvwLanguageSpec
        dim languageCont, languageConts
        dim instanceCont, instanceConts
        dim strategyCont, strategyConts
        dim cvwViewStrategy
        dim propVal
        dim rel, rels, relDir
        dim size, pos
        dim level, i, no
        dim cvwSelectDialog
        dim typeList, typeInst, typeInstances
        dim parentView

        if isValid(workWindow) and isEnabled(objView) then
            set wObject = workWindow.instance
            ' Handle ClearMode
            if ClearMode = "Clear" then
                set children = workWindow.children
                for each childView in children
                    if childView.uri <> instView.uri then
                        modelView.deleteObjectView(childView)
                    end if
                next
            end if
            ' Handle neighbour types
            if Len(NeighbourObjectType) > 0 then
                set neighbourObjType = metis.findType(NeighbourObjectType)
            end if
            if Len(NeighbourRelshipType) > 0 then
                set neighbourRelType = metis.findType(NeighbourRelshipType)
            end if
            ' Get instance context parameters
            set instanceConts = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
            if instanceConts.count > 0 then
                set instanceCont = instanceConts(1)
                propVal = getPropertyValue(instanceCont, "ObjectAspectRatio")
                if Len(propVal) > 0 then
                    ObjectAspectRatio = CDbl(propVal)
                end if
            end if
            ' Get view strategy
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
                RelationshipViewMode = getPropertyValue(strategyCont, "RelationshipViewMode")
                if Len(RelationshipViewMode) = 0 then
                    RelationshipViewMode = "Hierarchy"
                end if
            end if

            ' Main action
            level = 0
            ' Resize and position current object
            if LayoutMode = "Circular" then
                set cvwCL.WorkWindow = workWindow
                set cvwCL.CenterObjectView = objView
                cvwCL.NoLevels = NoNeighbourLevels
                call cvwCL.build
                set size = cvwCL.getObjectSize(0, objView)
                set pos  = cvwCL.getObjectPosition(level, objView, size, 0, 0)
                call cvwCL.populate(level, objView, size, pos)
            end if
            set obj = objView.instance
            ' Get language constraints
            set languageConts = wObject.getNeighbourObjects(0, hasLanguageModelType, specContainerType)
            if languageConts.count > 0 then
                set languageCont = languageConts(1)
                set cvwLanguageSpec = new CVW_LanguageSpecification
                call cvwLanguageSpec.build(languageCont)
                ' Handle ask for type
                if AskForObjectType then
                    set typeList = cvwLanguageSpec.getTypeList(languageCont, obj.type, RelDirection)
                    if isValid(typeList) then
                        if typeList.count = 0 then
                            exit sub
                        elseif typeList.count = 1 then
                            set typeInstances = typeList
                        else
                            set cvwSelectDialog = new CVW_SelectDialog
                            cvwSelectDialog.singleSelect = false
                            cvwSelectDialog.title = "Select dialog"
                            cvwSelectDialog.heading = "Select neighbour type"
                            set typeInstances = cvwSelectDialog.show(typeList)
                        end if
                    end if
                end if
            end if
            ' Find neighbors
            if isValid(typeInstances) then
                for each typeInst in typeInstances
                    set neighbourObjType = typeInst.type
                    set parentView = workWindow
                    call addNeighbourViews(workWindow, parentView, objView, level, cvwLanguageSpec)
                next
            else
                MsgBox "No neighbours!"
            end if
        end if
    End Sub

    '-----------------------------------------------------------
    Private Sub addNeighbourViews(workWindow, parentView, objView, level, cvwLanguageSpec)
        dim obj, obj2
        dim rel, rels, relDir
        dim l, i, no
        dim removed

        set obj = objView.instance
        set rels = obj.neighbourRelationships


        if isValid(rels) then
            i = 0
            l = level + 1
            no = 1
            for each rel in rels
                if rel.origin.uri = obj.uri then
                    relDir = 0
                    set obj2 = rel.target
                else
                    relDir = 1
                    set obj2 = rel.origin
                end if
                removed = false
                if isValid(neighbourRelType) then
                    if rel.type.uri <> neighbourRelType.uri then
                        rels.removeAt(no)
                        removed = true
                    end if
                elseif isValid(neighbourObjType) then
                    if obj2.type.uri <> neighbourObjType.uri then
                        rels.removeAt(no)
                        removed = true
                    end if
                elseif not cvwLanguageSpec.relIsAllowed(rel) then
                    rels.removeAt(no)
                    removed = true
                else
                    if not (RelDirection = -1 or RelDirection = relDir) then
                        rels.removeAt(no)
                        removed = true
                    end if
                end if
                if not removed then
                    no = no + 1
                end if
            next
            no = rels.count
            for each rel in rels
                if rel.origin.uri = obj.uri then
                    relDir = 0
                else
                    relDir = 1
                end if

                if RelDirection = -1 or RelDirection = relDir then
                    if not l > NoNeighbourLevels then
                        i = i + 1
                        call addNeighbourView(workWindow, parentView, objView, relDir, rel, l, i, no, cvwLanguageSpec)
                    end if
                end if
            next
        end if
    End Sub

    '-----------------------------------------------------------
    Private Sub addNeighbourView(workWindow, parentView, objView, relDir, rel, level, i, no, cvwLanguageSpec)
        dim obj, relView
        dim originView, originViews
        dim targetView, targetViews
        dim view
        dim isHierarchy
        dim l

        ' Create relationship view
        l = level
        if RelationshipViewMode = "Hierarchy" then
            isHierarchy = true
        end if
        if relDir = 0 then
            set obj = rel.target
            set originView = objView
            set targetView = viewExists(obj, parentView)
            if isHierarchy then
                set parentView = objView
            end if
            if not isValid(targetView) then
                set targetView = addObjectView(workWindow, parentView, obj, l, i, no)
            end if
            set view = targetView
        else
            set obj = rel.origin
            set targetView = objView
            set originView = viewExists(obj, workWindow)
            if not isValid(originView) then
                set originView = addObjectView(workWindow, parentView, obj, l, i, no)
            end if
            set view = originView
        end if
        if isValid(originView) and isValid(targetView) then
            set relView = relViewExists(rel, originView, targetView)
            if not isValid(relView) then
                if not isHierarchy then
                    set relView = currentModelView.newRelationshipView(rel, originView, targetView)
                else
                    parentView.open
                end if
                if l < NoNeighbourLevels then
                    call addNeighbourViews(workWindow, parentView, view, l, cvwLanguageSpec)
                end if
            end if
        end if
    End Sub

    '-----------------------------------------------------------
    Private Function addObjectView(workWindow, parentView, obj, level, i, no)
        dim objView, objGeo
        dim cvwObjView
        dim textscale
        dim size, pos
        dim l

        set addObjectView = Nothing
        ' Create object view
        l = level
        set cvwObjView = new CVW_ObjectView
        set objView = cvwObjView.create(workWindow, parentView, obj, ObjectAspectRatio)
        set cvwObjView = Nothing
        if LayoutMode = "Circular" then
            set size = cvwCL.getObjectSize(l, objView)
            set pos  = cvwCL.getObjectPosition(l, objView, size, i, no)
            call cvwCL.populate(l, objView, size, pos)
        end if
        if objView.isNested then
            objView.close
        end if
        set addObjectView = objView
    End Function

'-----------------------------------------------------------
    Private Function getPropertyValue(inst, propName)
        dim prop, properties

        getPropertyValue = ""
        set properties = inst.getNeighbourObjects(0, hasPropertyType, propertyType)
        if isValid(properties) then
            for each prop in properties
                if prop.title = propName then
                    getPropertyValue = prop.getNamedStringValue("value")
                end if
            next
        end if
    End Function

    '-----------------------------------------------------------
    Private Sub Class_Initialize()

        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView

        ' Types
        set specContainerType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
        set hasLanguageModelType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification2_UUID")
        set hasViewStrategyType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        set propertyType            = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        ' CVW objects
        set cvwCL = new CVW_CircularLayout
        ' Defaults
        NoNeighbourLevels = 1
        RelDirection = -1
        ClearMode = "Clear"
        LayoutMode = "Auto"
        ObjectAspectRatio = -1
        AskForObjectType = false

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
        set cvwCL = Nothing
    End Sub

End Class

