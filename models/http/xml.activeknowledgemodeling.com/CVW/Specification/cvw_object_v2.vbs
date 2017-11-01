option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Object


    ' Variant parameters
    Public Title                        ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public workWindow

    Public onTitleBar
    'Types
    Private specContainerType
    Private hasViewStrategyType
    Private hasLanguageType
    Private isTopType
    Private hasInstanceContextType
    Private hasInstanceContext2Type
    Private hasValueConstraintType

'-----------------------------------------------------------
    Public Function newObject
        dim workarea, workwindow, wObject
        dim cvwArg
        dim typeObjUri, typeObj, objType
        dim newObjectView
        dim model, modelObject
        dim instContext, instContexts
        dim specObject, specObjects
        dim strategyCont, strategyConts
        dim cvwViewStrategy, rule
        dim rel, rels
        dim obj, parentInst, parentInstView
        dim relType, relship
        dim contextObj
        dim selected
        dim languageRules
        dim noLanguageRules
        dim i

        set newObject = Nothing
        ' Find workwindow
        if onTitleBar then
            set workarea   = currentInstanceView.parent.parent
            set workwindow = workarea.children(2)
        else
            set workwindow = findWorkWindowView(currentInstanceView)
        end if
        set wObject = workwindow.instance
        ' Find type argument
        set cvwArg = new CVW_ArgumentValue
        typeObjUri = cvwArg.getArgumentValue(currentInstance, "Type")
        if Len(typeObjUri) > 0 then
            set typeObj = metis.findInstance(typeObjUri)
            set objType = typeObj.type
        end if
        ' Get parent object(s)
        set model = contentModel(workwindow)
        set modelObject = metis.findInstance(model.uri)
        set selected = metis.selectedObjectViews
        if selected.count = 0 then
            set parentInst = modelObject
            set parentInstView = workwindow
        elseif selected.count = 1 then
            if hasInstance(selected(1)) then
                set parentInst = selected(1).instance
                set parentInstView = selected(1)
            else
                set parentInst = modelObject
                set parentInstView = workwindow
            end if
        end if
        if parentInst.uri = wObject.uri then
            set parentInst = modelObject
            set parentInstView = workwindow
        end if

        ' Find view strategies
        if isEnabled(wObject) then
            set strategyConts = wObject.getNeighbourObjects(0, hasViewStrategyType, specContainerType)
            if strategyConts.count > 0 then
                set strategyCont = strategyConts(1)
                set cvwViewStrategy = new CVW_ViewStrategy
                call cvwViewStrategy.build(strategyCont)
            end if
        end if

        ' Check part-of rules
        if parentInst.uri = modelObject.uri then
            ' Create object
            set newObject = parentInst.newPart(objType)
            set newObjectView = parentInstView.newObjectView(newObject)
        elseif isValid(cvwViewStrategy) then
            for i = 1 to cvwViewStrategy.noHierarchyRules
                set rule = cvwViewStrategy.hierarchyRules(i)
                if rule.parentType.uri = parentInst.type.uri then
                    if rule.childType.uri = objType.uri then
                        ' Create object
                        set newObject = parentInst.newPart(objType)
                        set newObjectView = parentInstView.newObjectView(newObject)
                        ' Create the relationship
                        set relship = model.newRelationship(rule.relType, parentInst, newObject)
                    end if
                end if
            next
        end if

        if not isEnabled(newObject) then
            call MsgBox("Creating the object violates a language rule!", vbExclamation)
            exit function
        end if

        ' Find instance context
        if isEnabled(wObject) and parentInst.uri = modelObject.uri then
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
    End Function

'-----------------------------------------------------------
    Private Function contentModel(workwindow)           'IMetisObject
        dim context

        ' Find ContentModel
        set contentModel = currentModel
        set context = new EKA_Context
        set context.currentModel        = currentModel
        set context.currentModelView    = currentModelView
        set context.currentInstance     = workwindow.instance
        set context.currentInstanceView = workwindow
        if isValid(context) then
            set contentModel = context.contentModel
        end if
        set context = Nothing
    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        onTitleBar = false
        ' Types
        set hasViewStrategyType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy2_UUID")
        set specContainerType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")
        set hasLanguageType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasLanguageSpecification2_UUID")
        set isTopType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasInstanceContextType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext_UUID")
        set hasInstanceContext2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set hasValueConstraintType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

