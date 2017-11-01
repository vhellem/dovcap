option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Object


    ' Variant parameters
    Public Title                          ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public workWindow
    Public ObjectAspectRatio              ' Float
    Public nestedTextFactor
    Public treeTextFactor
    Public RelationshipViewMode
    ' Types
    Private specContainerType
    Private hasViewStrategyType
    Private hasLanguageType
    Private isTopType
    Private hasInstanceContextType
    Private hasInstanceContext2Type
    Private hasValueType
    Private hasValueConstraintType
    Private propertyType
    Private hasPropertyType
    ' Others
    Public  noPathRules
    Public  pathRules()
    Private noRelTypes
    Private relTypeList()

'-----------------------------------------------------------
    Public Function newObject
        dim wObject
        dim cvwArg
        dim typeObjUri, typeObj, objType
        dim newObjectView
        dim model, modelObject
        dim instContext, instContexts
        dim specObject, specObjects
        dim strategyCont, strategyConts
        dim languageCont, languageConts, languageContView
        dim instanceCont, instanceConts
        dim children, childView, inst
        dim cvwViewStrategy, rule
        dim ekaInstance
        dim propVal
        dim rel, rels
        dim obj, parentInst, parentInstView
        dim relType, relship, relshipView
        dim cvwObjView
        dim objGeo, size
        dim contextObj
        dim selected
        dim languageRules
        dim noLanguageRules
        dim i

        ' Validate input arguments
        set newObject = Nothing
        set ekaInstance = new EKA_Instance
        if hasInstance(workWindow) then
            set wObject = workWindow.instance
            if not isEnabled(wObject) then
                ' Call error function
                exit Function
            end if
        end if
        ' Find type argument
        set cvwArg = new CVW_ArgumentValue
        typeObjUri = cvwArg.getArgumentValue(currentInstance, "Type")
        if Len(typeObjUri) > 0 then
            set typeObj = metis.findInstance(typeObjUri)
            if isEnabled(typeObj) then
                set objType = typeObj.type
                if not isEnabled(objType) then
                    ' Call error function
                    exit Function
                end if
            end if
        end if
        ' Get parent object(s)
        set model = contentModel()
        set modelObject = metis.findInstance(model.uri)
        set selected = metis.selectedObjectViews
        if selected.count = 0 then
            set parentInst = modelObject
            set parentInstView = workWindow
        elseif selected.count = 1 then
            if isInView(selected(1), workWindow) then
                if hasInstance(selected(1)) then
                    set parentInst = selected(1).instance
                    set parentInstView = selected(1)
                end if
            else
                set parentInst = modelObject
                set parentInstView = workWindow
            end if
        end if
        if not isEnabled(parentInst) then
            call MsgBox("Unable to create new object!", vbExclamation)
            exit function
        end if
        if parentInst.uri = wObject.uri then
            set parentInst = modelObject
            set parentInstView = workWindow
        end if

        ' Find language rules
        if isEnabled(wObject) then
            set languageConts = wObject.getNeighbourObjects(0, hasLanguageType, specContainerType)
            if languageConts.count > 0 then
                set languageCont = languageConts(1)
                set languageContView = languageCont.views(1)
                set children = languageContView.children
                for each childView in children
                    if hasInstance(childView) then
                        set inst= childView.instance
                        if inst.type.uri = parentInst.type.uri then
                            call buildRelRules(inst, pathRules, noPathRules, relTypeList, noRelTypes)
                        end if
                    end if
                next
            end if
        end if
        ' Find view strategies
        if isEnabled(wObject) then
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
                RelationshipViewMode = ekaInstance.getPropertyValue(strategyCont, "RelationshipViewMode")
                if Len(RelationshipViewMode) = 0 then
                    RelationshipViewMode = "Hierarchy"
                end if
            end if
        end if
        ' Get instance context parameters
        set instanceConts = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
        if instanceConts.count > 0 then
            set instanceCont = instanceConts(1)
            propVal = ekaInstance.getPropertyValue(instanceCont, "ObjectAspectRatio")
            if Len(propVal) > 0 then
                ObjectAspectRatio = CDbl(propVal)
            end if
        end if

        set cvwObjView = new CVW_ObjectView
        if parentInst.uri = modelObject.uri then
            ' Create object
            set newObject = parentInst.newPart(objType)
            set newObjectView = cvwObjView.create(workWindow, workWindow, newObject, ObjectAspectRatio)
            if newObjectView.isNested then
                newObjectView.close
            end if
        elseif isValid(cvwViewStrategy) then
            ' Check part-of rules
            for i = 1 to cvwViewStrategy.noHierarchyRules
                set rule = cvwViewStrategy.hierarchyRules(i)
                if rule.parentType.uri = parentInst.type.uri then
                    if rule.childType.uri = objType.uri then
                        ' Create object
                        set newObject = model.newObject(objType)
                        if RelationshipViewMode = "Hierarchy" then
                            parentInstView.open
                            set newObjectView = cvwObjView.create(workWindow, parentInstView, newObject, ObjectAspectRatio)
                        else
                            set newObjectView = cvwObjView.create(workWindow, workWindow, newObject, ObjectAspectRatio)
                        end if
                        ' Resize if specified
                        if ObjectAspectRatio > 0 then
                            set objGeo = newObjectView.absScaleGeometry
                            set size = objGeo.size
                            size.height = ObjectAspectRatio * size.width
                            set objGeo.size = size
                            set newObjectView.absScaleGeometry = objGeo
                        end if
                        if newObjectView.isNested then
                            newObjectView.close
                        end if
                        ' Create the relationship
                        set relship = model.newRelationship(rule.relType, parentInst, newObject)
                        if RelationshipViewMode = "Relationship" then
                            set relshipView = currentModelView.newRelationshipView(relship, parentInstView, newObjectView)
                        end if
                    end if
                end if
            next
        end if
        if not isEnabled(newObject) then
            for i = 1 to noPathRules
                set rule = pathRules(i)
                if rule.parentType.uri = parentInst.type.uri then
                    if rule.childType.uri = objType.uri then
                        ' Create the object
                        set newObject = model.newObject(objType)
                        set newObjectView = cvwObjView.create(workWindow, workWindow, newObject, ObjectAspectRatio)
                        if newObjectView.isNested then newObjectView.close
                        ' Create the relationship
                        set relship = model.newRelationship(rule.relType, parentInst, newObject)
                        set relshipView = currentModelView.newRelationshipView(relship, parentInstView, newObjectView)
                        exit for
                    end if
                end if
            next
        end if
        set cvwObjView = Nothing

        if not isEnabled(newObject) then
            call MsgBox("Creating the object violates a language rule!", vbExclamation)
            exit function
        end if

        ' Find instance context
        if parentInst.uri = modelObject.uri then
            set instContexts = wObject.getNeighbourRelationships(0, hasInstanceContext2Type)
            if instContexts.count > 0 then
                set rel = instContexts(1)
                if isEnabled(rel) then
                    set instContext = rel.target
                end if
            end if
            if isEnabled(instContext) then
                set specObjects = wObject.getNeighbourObjects(0, hasInstanceContextType, specContainerType)
                if specObjects.count > 0 then
                    set specObject = specObjects(1)
                    set rels = specObject.getNeighbourRelationships(0, isTopType)
                    if rels.count > 0 then
                        for each rel in rels
                            set obj = rel.target
                            if obj.type.uri = instContext.type.uri then
                                set contextObj = obj
                                exit for
                            end if
                        next
                    end if
                    if isEnabled(contextObj) then
                        set rels = contextObj.neighbourRelationships
                        for each rel in rels
                            if rel.origin.type.uri = instContext.type.uri then
                                if rel.target.type.uri = objType.uri then
                                    ' Create relationship
                                    set relType = rel.type
                                    set relship = model.newRelationship(relType, instContext, newObject)
                                    exit for
                                end if
                            elseif rel.target.type.uri = instContext.type.uri then
                                if rel.origin.type.uri = objType.uri then
                                    ' Create relationship
                                    set relType = rel.type
                                    set relship = model.newRelationship(relType, newObject, instContext)
                                    exit for
                                end if
                            end if
                        next
                    end if
                end if
            end if
        end if
        set ekaInstance = Nothing
    End Function

'-----------------------------------------------------------
    Private Function getTextScaleFactor(instView, parentView)
        dim parentTs, instTs

        parentTs = parentView.textscale
        if instView.isNested then
            getTextScaleFactor = parentTs * nestedTextFactor
        else
            getTextScaleFactor = parentTs * treeTextFactor
        end if

    End Function

'-----------------------------------------------------------
    Private Function contentModel           'IMetisObject
        dim context

        ' Find ContentModel
        set contentModel = currentModel
        set context = new EKA_Context
        set context.currentModel        = currentModel
        set context.currentModelView    = currentModelView
        set context.currentInstance     = workWindow.instance
        set context.currentInstanceView = workWindow
        if isValid(context) then
            if isEnabled(context.contentModel) then
                set contentModel = context.contentModel
            end if
        end if
        set context = Nothing
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set workWindow          = currentInstanceView
        ' Factors
        nestedTextFactor   = 1
        treeTextFactor     = 1
        ObjectAspectRatio  = -1
        RelationshipViewMode = "Hierarchy"
        ' Types
        set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        set specContainerType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasLanguageType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification2_UUID")
        set isTopType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
        set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set hasValueType            = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set hasValueConstraintType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        ' Others
        noPathRules = 0
        noRelTypes  = 3
        ReDim Preserve relTypeList(noRelTypes)
        set relTypeList(1) = isTopType
        set relTypeList(2) = hasValueType
        set relTypeList(3) = hasValueConstraintType

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

