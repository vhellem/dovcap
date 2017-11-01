option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_Rule


    ' Variant parameters
    Public Title                        ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public ObjectAspectRatio

    ' Types
    Private buttonType
    Private hasContextType
    Private specContainerType
    Private hasInstanceContextType

    Private actionType
    Private ccType
    Private conditionType
    Private ruleType
    Private cpValueType
    Private dpValueType
    Private fpValueType
    Private vpValueType
    Private hasActionType
    Private hasConditionType
    Private hasRuleType
    Private ifThenType
    Private inputToType
    Private isSubjectOfType
    Private outputToType

    ' Arguments
    Private currentWindow
    Private configModel

'-----------------------------------------------------------
    Public Sub execute(mode)
        dim ruleObject
        dim cvwTask

        if mode = "Edit" then
            set ruleObject = findRule()
            if not isEnabled(ruleObject) then
                MsgBox "There is no rule connected!"
                exit sub
            end if
        end if
        if not isEnabled(ruleObject) then
            set ruleObject = createRule()
        end if
        if isEnabled(ruleObject) then
            call openRuleWindow(ruleObject)
        end if
    End Sub

'-----------------------------------------------------------
    Private Function findRule()
        dim rule, rules
        dim cvwSelectDialog

        set findRule = Nothing
        set rules = currentInstance.getNeighbourObjects(0, isSubjectOfType, ruleType)
        if isValid(rules) then
            if rules.count = 1 then
                set findRule = rules(1)
            elseif rules.count > 1 then
                set cvwSelectDialog = new CVW_SelectDialog
                cvwSelectDialog.singleSelect = true
                cvwSelectDialog.title = "Select dialog"
                cvwSelectDialog.heading = "Select rule"
                set rules = cvwSelectDialog.show(rules)
                if isValid(rules) then
                    if rules.count = 1 then
                        set findRule = rules(1)
                    end if
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Function createRule()
        dim model, modelObject
        dim ruleObject, actionObject, conditionObject
        dim ruleName
        dim hasRuleRel, subjectOfRel, partOfRel, ifThenRel
        dim ccObject, ccObjects

        set createRule = Nothing
        if not isEnabled(ruleObject) then
            ' Create rule object
            ' Get model object
            set model = contentModel()
            if isEnabled(model) then
                set modelObject = metis.findInstance(model.uri)
                set ccObjects = model.findInstances(ccType, "", "")
                if isValid(ccObjects) then
                    if ccObjects.count > 0 then
                        set ccObject = ccObjects(1)
                    end if
                end if
                ' Create the rule object
                set ruleObject = modelObject.newPart(ruleType)
                if isEnabled(ruleObject) then
                    ruleName = "Rule[" & currentInstance.title & "]"
                    ruleName = InputBox("Enter rule name", "Input dialog", ruleName)
                    if Len(ruleName) > 0 then
                        ruleObject.title = ruleName
                    else
                        ruleObject.title = "Rule[" & currentInstance.title & "]"
                    end if
                    ' Connect the relationships
                    if isEnabled(ccObject) then
                        set hasRuleRel = model.newRelationship(hasRuleType, ccObject, ruleObject)
                    end if
                    set subjectOfRel = model.newRelationship(isSubjectOfType, currentInstance, ruleObject)
                    if isEnabled(subjectOfRel) then
                        ' Create condition and action objects
                        set conditionObject = modelObject.newPart(conditionType)
                        set actionObject = modelObject.newPart(actionType)
                        if isEnabled(conditionObject) and isEnabled(actionObject) then
                            ' Create relationships
                            set partOfRel = model.newRelationship(hasConditionType, ruleObject, conditionObject)
                            set partOfRel = model.newRelationship(hasActionType, ruleObject, actionObject)
                            set ifThenRel = model.newRelationship(ifThenType, conditionObject, actionObject)
                        end if
                    end if
                end if
            end if
            if isEnabled(ruleObject) then
                set createRule = ruleObject
            end if
        end if
   End Function

'-----------------------------------------------------------
    Private Sub openRuleWindow(ruleObject)
        dim cvwModel, cvwAction, cvwWorkarea
        dim actionName, actionObject, actionObjects
        dim workarea, workWindow, wObject
        dim rel, rels
        dim ruleView
        dim child, children
        dim textscale

        set cvwModel = getCVWmodel
        actionName = "_Rules_"
        set actionObjects = cvwModel.findInstances(buttonType, "name", actionName)
        if isValid (actionObjects) then
            if actionObjects.count > 0 then
                set actionObject = actionObjects(1)
                set cvwAction = new CVW_MenuAction
                set cvwAction.configObject = actionObject
                set cvwAction.contextInstance = ruleObject
                call cvwAction.build
                call cvwAction.execute
                set workarea = cvwAction.workarea
                if isValid(workarea) and isEnabled(ruleObject) then
                    set workWindow = workarea.WorkWindow
                    ' Get CVW_Workarea
                    set cvwWorkarea = new CVW_Workarea
                    set cvwWorkarea.WorkWindow = workWindow
                    ' Set context instance
                    set wObject = workWindow.instance
                    set rels = wObject.getNeighbourRelationships(0, hasInstanceContextType)
                    if rels.count > 0 then
                        set rel = rels(1)
                        set rel.target = ruleObject
                    end if
                    set cvwWorkarea = Nothing
                    call populateRule(workWindow, ruleObject, false)
                end if
                set cvwAction = Nothing
            end if
        end if

    End Sub

'-----------------------------------------------------------
    Public Function populateRule(workWindow, ruleObject, fromOpen)
        dim ruleView
        dim child, children
        dim action, actions, actionView
        dim condition, conditions, conditionView
        dim fromObj, fromObjView
        dim parameterValue, parameterValueView
        dim rel, rels, relView, view, views
        dim textscale
        dim objGeo, size
        dim objHeight

        set populateRule = Nothing
        if not fromOpen then
            if isValid(workWindow) then
                set children = workWindow.children
                for each child in children
                    call currentModelView.deleteObjectView(child)
                next
            end if
        end if
        if isValid(workWindow) and isEnabled(ruleObject) then
            set ruleView = workWindow
            if isValid(ruleView) then
                if hasInstance(ruleView) then
                    ' Find actions
                    set actions = ruleObject.getNeighbourObjects(0, hasActionType, actionType)
                    for each action in actions
                        set actionView = viewExists(action, ruleView)
                        if not isValid(actionView) then
                            set actionView = ruleView.newObjectView(action)
                            set objGeo = actionView.absScaleGeometry
                            set size = objGeo.size
                            if size.height / size.width > ObjectAspectRatio then
                                size.height = size.width * 0.2 'ObjectAspectRatio
                                size.width  = 2 * size.height
                                set objGeo.size = size
                                set actionView.absScaleGeometry = objGeo
                                if actionView.isNested then
                                    textScale = ruleView.textScale
                                    textScale = textscale * 1.75
                                else
                                    textscale = 0.5
                                end if
                                actionView.textscale = textscale
                            end if
                        end if
                    next
                    ' Find conditions
                    set conditions = ruleObject.getNeighbourObjects(0, hasConditionType, conditionType)
                    for each condition in conditions
                        set conditionView = viewExists(condition, ruleView)
                        if not isValid(conditionView) then
                            set conditionView = ruleView.newObjectView(condition)
                            set objGeo = conditionView.absScaleGeometry
                            set size = objGeo.size
                            if size.height / size.width > ObjectAspectRatio then
                                size.height = size.width * 0.2 'ObjectAspectRatio
                                size.width = size.height
                                set objGeo.size = size
                                set conditionView.absScaleGeometry = objGeo
                                if conditionView.isNested then
                                    textScale = ruleView.textScale
                                    textScale = textscale * 1.75
                                else
                                    textscale = 0.5
                                end if
                                conditionView.textscale = textscale
                            end if
                        end if
                    next
                    ' Find ifThenRels
                    for each action in actions
                        set actionView = action.views(1)
                        if isValid(actionView) then
                            set rels = action.getNeighbourRelationships(1, ifThenType)
                            for each rel in rels
                                set condition = rel.origin
                                set conditionView = condition.views(1)
                                if isInView(conditionView, ruleView) then
                                    set relView = relViewExists(rel, conditionView, actionView)
                                    if not isValid(relView) then
                                        set relView = currentModelView.newRelationshipView(rel, conditionView, actionView)
                                    end if
                                end if
                            next
                        end if
                    next
                    ' Find inputToRels to conditions
                    for each condition in conditions
                        set conditionView = condition.views(1)
                        if isValid(conditionView) then
                            set rels = condition.getNeighbourRelationships(1, inputToType)
                            for each rel in rels
                                set fromObj = rel.origin
                                if fromObj.type.uri = conditionType.uri then
                                    set fromObjView = fromObj.views(1)
                                    if isInView(fromObjView, ruleView) then
                                        set relView = relViewExists(rel, fromObjView, conditionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, fromObjView, conditionView)
                                        end if
                                    end if
                                elseif fromObj.type.uri = vpValueType.uri then
                                end if
                            next
                        end if
                    next
                    ' Find inputToRels to parameter values
                    for each condition in conditions
                        set conditionView = condition.views(1)
                        if isValid(conditionView) then
                            set rels = condition.getNeighbourRelationships(1, inputToType)
                            for each rel in rels
                                set parameterValue = rel.origin
                                if isParameterValueType(parameterValue) then
                                    set parameterValueView = Nothing
                                    set views = parameterValue.views
                                    if isValid(views) then
                                        for each view in views
                                            if isInView(view, ruleView) then
                                                set parameterValueView = view
                                                exit for
                                            end if
                                        next
                                    end if
                                    if not isValid(parameterValueView) then
                                        ' Create view of parameterValue
                                        set parameterValueView = ruleView.newObjectView(parameterValue)
                                        set objGeo = parameterValueView.absScaleGeometry
                                        set size = objGeo.size
                                        if size.height / size.width > ObjectAspectRatio then
                                            size.height = ObjectAspectRatio * size.width
                                            set objGeo.size = size
                                            set parameterValueView.absScaleGeometry = objGeo
                                        end if
                                        if parameterValueView.isNested then
                                            textScale = ruleView.textScale
                                            textScale = textscale * 2.25
                                        else
                                            textscale = 0.5
                                        end if
                                        parameterValueView.textscale = textscale
                                    end if
                                    if isValid(parameterValueView) then
                                        set relView = relViewExists(rel, parameterValueView, conditionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, parameterValueView, conditionView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                    next
                    ' Find outputToRels to parameter values
                        if isValid(actionView) then
                            set action = actionView.instance
                            set rels = action.getNeighbourRelationships(0, outputToType)
                            for each rel in rels
                                set parameterValue = rel.target
                                if isParameterValueType(parameterValue) then
                                    set parameterValueView = Nothing
                                    set views = parameterValue.views
                                    if isValid(views) then
                                        for each view in views
                                            if isInView(view, ruleView) then
                                                set parameterValueView = view
                                                exit for
                                            end if
                                        next
                                    end if
                                    if not isValid(parameterValueView) then
                                        ' Create view of parameterValue
                                        set parameterValueView = ruleView.newObjectView(parameterValue)
                                        if parameterValueView.isNested then
                                            textScale = ruleView.textScale
                                            textScale = textscale * 1.75
                                        else
                                            textscale = 0.5
                                        end if
                                        parameterValueView.textscale = textscale
                                    end if
                                    if isValid(parameterValueView) then
                                        set relView = relViewExists(rel, actionView, parameterValueView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, actionView, parameterValueView)
                                            set objGeo = parameterValueView.absScaleGeometry
                                            set size = objGeo.size
                                            if size.height / size.width > ObjectAspectRatio then
                                                size.height = ObjectAspectRatio * size.width
                                                set objGeo.size = size
                                                set parameterValueView.absScaleGeometry = objGeo
                                            end if
                                        end if
                                    end if
                                end if
                            next
                        end if
                end if
            end if
        end if
        set populateRule = ruleView

    End Function

'-----------------------------------------------------------
    Private Function isParameterValueType(inst)
        dim instType

        isParameterValueType = false
        set instType = inst.type
        if instType.uri = vpValueType.uri then
            isParameterValueType = true
        elseif instType.uri = dpValueType.uri then
            isParameterValueType = true
        elseif instType.uri = cpValueType.uri then
            isParameterValueType = true
        elseif instType.uri = fpValueType.uri then
            isParameterValueType = true
        end if
    End Function

'-----------------------------------------------------------
    Private Function contentModel           'IMetisObject
        dim context

        ' Find ContentModel
        if isValid(currentWindow) then
            set contentModel = currentModel
            set context = new EKA_Context
            set context.currentModel        = currentModel
            set context.currentModelView    = currentModelView
            set context.currentInstance     = currentWindow.instance
            set context.currentInstanceView = currentWindow
            if isValid(context) then
                if isEnabled(context.contentModel) then
                    set contentModel = context.contentModel
                end if
            end if
            set context = Nothing
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim inst
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set currentWindow       = findWorkWindowView(currentInstanceView)

        ' Types
        set buttonType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set hasContextType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set hasInstanceContextType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

        set actionType       = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#action")
        set ccType           = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
        set conditionType    = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#condition")
        set ruleType         = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")
        set cpValueType      = metis.findType("http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value")
        set dpValueType      = metis.findType("http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value")
        set fpValueType      = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value")
        set vpValueType      = metis.findType("http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value")
        set inputToType      = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to")
        set outputToType     = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#has_output")
        set hasConditionType = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_condition")
        set hasActionType    = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_action")
        set hasRuleType      = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_rule")
        set ifThenType       = metis.findType("http://xml.chalmers.se/class/rule.kmd#if_then")
        set isSubjectOfType  = metis.findType("http://xml.chalmers.se/class/rule.kmd#subject_of_rule")
        ' Model
        set inst = metis.findInstance("http://xml.chalmers.se/metamodels/cvw_cc_actions_1.kmv#_002ask601qg2tl2ra0ce")
        set configModel  = currentInstance.ownerModel
        ' Variables
        ObjectAspectRatio = 1.0

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

