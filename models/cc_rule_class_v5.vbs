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

    ' Debug
    Public debug

    ' Types
    Private buttonType
    Private hasContextType
    Private specContainerType
    Private hasInstanceContextType

    Private parameterType
    Private actionType
    Private ccType
    Private csType
    Private ceType
    Private crType
    Private conditionType
    Private expressionType
    Private inputType
    Private outputType
    Private ruleType
    Private frType
    Private dsType
    Private cType
    Private cpType
    Private dpType
    Private fpType
    Private ppType
    Private vpType
    Private hasDpType
    Private hasPpType
    Private paramValueType
    Private cpValueType
    Private dpValueType
    Private fpValueType
    Private ppValueType
    Private vpValueType
    Private hasCStype
    Private hasCEtype
    Private hasCRtype
    Private usesCCtype
    Private explainsType
    Private solvesType
    Private requiresType
    Private constrainedType

    Private hasActionType
    Private hasConditionType
    Private hasExpressionType
    Private hasInputType
    Private hasOutputType
    Private hasRuleType
    Private ifThenType
    Private inputToType
    Private inputTo2Type
    Private inputTo3Type
    Private inputToRelType
    Private inputTo2RelType
    Private isSubjectOfType
    Private outputToType
    Private outputToRelType
    Private anyObjectType
    
    Private modelObjectType
    Private partType
    Private memberType
    Private propertyType
    Private hasPropertyType
    Private valueType
    Private hasValueType
    Private hasDefinitionType

    ' Methods
    Private ruleMethod
    Private expressionMethod

    ' Arguments
    Private currentWindow
    Private configModel
    Private ccRuleEngine
    Private ruleKind
    Private ExprEvaluatedToProperty
    Private RuleEvaluatedToProperty

'-----------------------------------------------------------
    Public Property Get ruleEngine
        set ruleEngine = ccRuleEngine
    End Property

'-----------------------------------------------------------
    Public Sub execute(mode)
        dim ruleObject
        dim cvwTask

        if mode = "Edit" then
            set ruleObject = findRule()
            if not isEnabled(ruleObject) then
                'MsgBox "There is no rule connected!"
                exit sub
            end if
        end if
        if isEnabled(ruleObject) then
            title = ruleObject.title
            if title = "New rule" then
                ruleKind = "Logical rule"
                set ruleObject = buildRule(ruleObject)
            elseif title = "New expression" then
                ruleKind = "Expression"
                set ruleObject = buildRule(ruleObject)
            elseif title = "New service" then
                ruleKind = "Service"
                set ruleObject = buildRule(ruleObject)
            else
                ruleKind = ruleObject.getNamedStringValue("ruleKind")
            end if
        end if
        if isEnabled(ruleObject) then
            call openRuleWindow(ruleObject)
        end if
    End Sub

'-----------------------------------------------------------
    Public Function getRules(inst)
        dim rules, noRules

        set rules = Nothing
        if inst.type.uri = ruleType.uri then
            set rules = metis.newInstanceList
            call rules.addLast(inst)
        elseif inst.isRelationship then
            set rules = metis.newInstanceList
            noRules = getRelationshipRules(inst, rules)
        elseif inst.isObject then
            set rules = inst.getNeighbourObjects(0, isSubjectOfType, ruleType)
        end if
        set getRules = rules
    End Function

'-----------------------------------------------------------
    Private Function getRelationshipRules(relship, rules)
        dim ruleIds, ruleUri, ruleObject
        dim idArray
        dim i

        getRelationshipRules = 0
        if isEnabled(relship) then
            on error resume next
            ruleIds = relship.getNamedStringValue("ruleIds")
            if Len(ruleIds) > 0 then
	            idArray = Split(ruleIds, ";", -1, 1)
                i = 0
                ruleUri = ""
                do
                    on error resume next
                    ruleUri = idArray(i)
                    if Len(ruleUri) > 0 then
                        if Left(ruleUri, 1) = "#" then
                            ruleUri = relship.url & ruleUri
                        end if
                        set ruleObject = metis.findInstance(ruleUri)
                        if isEnabled(ruleObject) then
                            if not isValid(rules) then
                                set rules = metis.newInstanceList
                            end if
                            call rules.addLast(ruleObject)
                        end if
                    else
                        exit do
                    end if
                    i = i + 1
                    ruleUri = ""
                loop
            end if
        end if
        if isValid(rules) then
            getRelationshipRules = rules.count
        end if
    End Function

'-----------------------------------------------------------
    Private Function findRule()
        dim rule, rules
        dim ruleObject, expressionObject, serviceObject
        dim model, modelObject
        dim cvwSelectDialog

        set findRule = Nothing
        if currentInstance.type.uri = ruleType.uri then
            set findRule = currentInstance
            exit function
        end if
        set rules = getRules(currentInstance)
        if isValid(rules) then
            ' Get model object
            set model = contentModel()
            if isEnabled(model) then
                set modelObject = metis.findInstance(model.uri)
                ' Create the rule object
                set ruleObject = modelObject.newPart(ruleType)
                if isEnabled(ruleObject) then
                    ruleObject.title = "New rule"
                    rules.addLast ruleObject
                end if
                ' Create the expression object
                set expressionObject = modelObject.newPart(ruleType)
                if isEnabled(expressionObject) then
                    expressionObject.title = "New expression"
                    call expressionObject.setNamedStringValue("ruleKind", "Expression")
                    rules.addLast expressionObject
                end if
                ' Create the service object
                set serviceObject = modelObject.newPart(ruleType)
                if isEnabled(serviceObject) then
                    serviceObject.title = "New service"
                    call serviceObject.setNamedStringValue("ruleKind", "Service")
                    rules.addLast serviceObject
                end if
            end if
            if rules.count = 0 then
                exit function
            else
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
                if isEnabled(findRule) then
                    if findRule.uri <> ruleObject.uri or rules.count = 0 then
                        model.deleteObject(ruleObject)
                    end if
                    if findRule.uri <> expressionObject.uri or rules.count = 0 then
                        model.deleteObject(expressionObject)
                    end if
                    if findRule.uri <> serviceObject.uri or rules.count = 0 then
                        model.deleteObject(serviceObject)
                    end if
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Function buildRule(ruleObject)
        dim model, modelObject
        dim actionObject, conditionObject
        dim expressionObject, inputObject, outputObject
        dim ruleName
        dim hasRuleRel, subjectOfRel, partOfRel, ifThenRel
        dim ccObject, ccObjects
        dim ruleIds
        dim idArray
        dim hasSubject
        dim isLogical

        set buildRule = Nothing
        if not isEnabled(ruleObject) then
            exit function
        else
            ' Create rule object
            ' Get model object
            if ruleKind = "Expression" or ruleKind = "Service" then
                isLogical = false
            else
                isLogical = true
            end if
            set model = contentModel()
            if isEnabled(model) then
                set modelObject = metis.findInstance(model.uri)
                set ccObjects = model.findInstances(ccType, "", "")
                if isValid(ccObjects) then
                    if ccObjects.count > 0 then
                        set ccObject = ccObjects(1)
                    end if
                end if
                title = ruleObject.title
                if title = "New rule" then
                    ruleName = "Rule[" & currentInstance.title & "]"
                elseif title = "New expression" then
                    ruleName = "Expression[" & currentInstance.title & "]"
                elseif title = "New service" then
                    ruleName = "Service[" & currentInstance.title & "]"
                end if
                if Len(ruleName) > 0 then
                    ruleName = InputBox("Enter rule name", "Input dialog", ruleName)
                    if Len(ruleName) > 0 then
                        ruleObject.title = ruleName
                    else
                        exit function
                    end if
                    ' Connect the relationships
                    if isEnabled(ccObject) then
                        set hasRuleRel = model.newRelationship(hasRuleType, ccObject, ruleObject)
                    end if
                    hasSubject = false
                    if currentInstance.isRelationship then
                        ruleIds = currentInstance.getNamedStringValue("ruleIds")
                        if currentInstance.url = ruleObject.url then
	                        idArray = Split(ruleObject.uri, "#", -1, 1)
	                        if Len(ruleIds) > 0 then
                                ruleIds = ruleIds & ";"
                            end if
                            ruleIds = ruleIds & Chr(35) & idArray(1)
                        else
                            ruleIds = ruleObject.uri
                        end if
                        call currentInstance.setNamedStringValue("ruleIds", ruleIds)
                        hasSubject = true
                    else
                        set subjectOfRel = model.newRelationship(isSubjectOfType, currentInstance, ruleObject)
                        if isEnabled(subjectOfRel) then hasSubject = true
                    end if
                    if hasSubject then
                        if isLogical then
                            ' Create condition and action objects
                            set conditionObject = modelObject.newPart(conditionType)
                            set actionObject = modelObject.newPart(actionType)
                            if isEnabled(conditionObject) and isEnabled(actionObject) then
                                ' Create relationships
                                set partOfRel = model.newRelationship(hasConditionType, ruleObject, conditionObject)
                                set partOfRel = model.newRelationship(hasActionType, ruleObject, actionObject)
                                set ifThenRel = model.newRelationship(ifThenType, conditionObject, actionObject)
                            end if
                        else
                            ' Create expression
                            set expressionObject = modelObject.newPart(expressionType)
                            if isEnabled(expressionObject) then
                                expressionObject.title = "Expression"
                                ' Create relationship
                                set partOfRel    = model.newRelationship(hasExpressionType, ruleObject, expressionObject)
                                'set inputObject  = expressionObject.newPart(inputType)
                                'set outputObject = expressionObject.newPart(outputType)
                            end if
                        end if
                    end if
                end if
            end if
            if isEnabled(ruleObject) then
                set buildRule = ruleObject
            end if
        end if
   End Function

'-----------------------------------------------------------
    Public Function getSubjectOf(rule)
        dim model
        dim rel, relships
        dim r, rules, noRules
        
        set getSubjectOf = Nothing

        set relships = rule.getNeighbourRelationships(1, isSubjectOfType)
        if relships.count > 0 then
            set getSubjectOf = relships(1).origin
        else
            set model = contentModel
            set relships = model.relationships
            for each rel in relships
                if isEnabled(rel) then
                    set rules = Nothing
                    noRules = getRelationshipRules(rel, rules)
                    if noRules > 0 then
                        for each r in rules
                            if r.uri = rule.uri then
                                set getSubjectOf = rel
                                exit function
                            end if
                        next
                    end if
                end if
            next
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
                'set cvwAction.contextInstance = ruleObject
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
                    if ruleKind = "Expression" then
                        call populateExpression(workWindow, ruleObject, false)
                    elseif ruleKind = "Service" then
                        call populateExpression(workWindow, ruleObject, false)
                    else
                        call populateLogicalRule(workWindow, ruleObject, false)
                    end if
                end if
                set cvwAction = Nothing
            end if
        end if

    End Sub

'-----------------------------------------------------------
    Public Function populateRule(workWindow, ruleObject, fromOpen)

        ruleKind = ruleObject.getNamedStringValue("ruleKind")
        if ruleKind = "Expression" then
            call populateExpression(workWindow, ruleObject, fromOpen)
        elseif ruleKind = "Service" then
            call populateExpression(workWindow, ruleObject, fromOpen)
        else
            call populateLogicalRule(workWindow, ruleObject, fromOpen)
        end if
    End Function

'-----------------------------------------------------------
    Private Function populateLogicalRule(workWindow, ruleObject, fromOpen)
        dim ruleView
        dim child, children
        dim action, actions, actionView
        dim condition, conditions, conditionView
        dim expression, expressions, expressionView
        dim fromObj, fromObjView, toObj, toObjView
        dim parameterValue, parameterValueView
        dim parameterObject, parameterObjectView
        dim rel, rels, relView, view, views
        dim cvwObjectView
        dim textscale
        dim objGeo, size
        dim objHeight

        set populateLogicalRule = Nothing
        if not fromOpen then
            if isValid(workWindow) then
                set children = workWindow.children
                for each child in children
                    call currentModelView.deleteObjectView(child)
                next
            end if
        end if
        if isValid(workWindow) and isEnabled(ruleObject) then
            set ruleView = viewExists(ruleObject, workWindow)
            if isValid(ruleView) then
                if fromOpen then
                    textscale = ruleView.textscale
                    textscale = textscale / 1
                    ruleView.textScale = textScale
                end if
            else
                set ruleView = workWindow.newObjectView(ruleObject)
                textscale = ruleView.textscale
                textscale = textscale / 5
                ruleView.textScale = textScale
            end if
            if isValid(ruleView) then
                set cvwObjectView = new CVW_ObjectView
                cvwObjectView.heightRatio = ObjectAspectRatio
                if hasInstance(ruleView) then
                    ' Find actions
                    set actions = ruleObject.getNeighbourObjects(0, hasActionType, actionType)
                    for each action in actions
                        set actionView = viewExists(action, ruleView)
                        if not isValid(actionView) then
                            cvwObjectView.nestedTextFactor1 = 3
                            set actionView = cvwObjectView.create(workWindow, ruleView, action, 0)
                            actionView.close
                        end if
                    next
                    ' Find conditions
                    set conditions = ruleObject.getNeighbourObjects(0, hasConditionType, conditionType)
                    for each condition in conditions
                        set conditionView = viewExists(condition, ruleView)
                        if not isValid(conditionView) then
                            cvwObjectView.nestedTextFactor1 = 3
                            set conditionView = cvwObjectView.create(workWindow, ruleView, condition, 1)
                            conditionView.close
                        end if
                    next
                    ' Find expressions
                    set expressions = ruleObject.getNeighbourObjects(0, hasExpressionType, expressionType)
                    for each expression in expressions
                        set expressionView = viewExists(expression, ruleView)
                        if not isValid(expressionView) then
                            cvwObjectView.nestedTextFactor1 = 1.75
                            set expressionView = cvwObjectView.create(workWindow, ruleView, expression, 0)
                            expressionView.close
                        end if
                        exit for
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
                            set rels = condition.getNeighbourRelationships(1, inputTo2Type)
                            if rels.count = 0 then
                                set rels = condition.getNeighbourRelationships(1, inputToType)
                            end if
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
                    ' Find inputToRels from expressions
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(0, inputTo3Type)
                            for each rel in rels
                                set toObj = rel.target
                                if toObj.type.uri = conditionType.uri then
                                    set toObjView = toObj.views(1)
                                    if isInView(toObjView, ruleView) then
                                        set relView = relViewExists(rel, expressionView, toObjView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, expressionView, toObjView)
                                        end if
                                    end if
                                elseif fromObj.type.uri = vpValueType.uri then
                                end if
                            next
                        end if
                    next
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(0, inputTo3Type)
                            for each rel in rels
                                set toObj = rel.target
                                if toObj.type.uri = conditionType.uri then
                                    set toObjView = toObj.views(1)
                                    if isInView(toObjView, ruleView) then
                                        set relView = relViewExists(rel, expressionView, toObjView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, expressionView, toObjView)
                                        end if
                                    end if
                                elseif fromObj.type.uri = vpValueType.uri then
                                end if
                            next
                        end if
                    next
                    ' Find inputToRels from parameter values to conditions
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
                                        cvwObjectView.nestedTextFactor1 = 2.25
                                        set parameterValueView = cvwObjectView.create(workWindow, ruleView, parameterValue, 0)
                                        parameterValueView.close
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
                    ' Find inputToRels from parameter( value)s to expressions
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(1, inputToRelType)
                            for each rel in rels
                                set parameterObject = rel.origin
                                if isParameterType(parameterObject) then
                                    set parameterObjectView = Nothing
                                    set views = parameterObject.views
                                    if isValid(views) then
                                        for each view in views
                                            if isInView(view, ruleView) then
                                                set parameterObjectView = view
                                                exit for
                                            end if
                                        next
                                    end if
                                    if not isValid(parameterObjectView) then
                                        cvwObjectView.nestedTextFactor1 = 2.25
                                        set parameterObjectView = cvwObjectView.create(workWindow, ruleView, parameterObject, 0)
                                        parameterObjectView.close
                                    end if
                                    if isValid(parameterObjectView) then
                                        set relView = relViewExists(rel, parameterObjectView, expressionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, parameterObjectView, expressionView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                    next
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(1, inputTo2RelType)
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
                                        cvwObjectView.nestedTextFactor1 = 2.25
                                        set parameterValueView = cvwObjectView.create(workWindow, ruleView, parameterValue, 0)
                                        parameterValueView.close
                                    end if
                                    if isValid(parameterValueView) then
                                        set relView = relViewExists(rel, parameterValueView, expressionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, parameterValueView, expressionView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                    next
                    ' Find outputToRels from actions to parameter values
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
                                        cvwObjectView.nestedTextFactor1 = 2.25
                                        set parameterValueView = cvwObjectView.create(workWindow, ruleView, parameterValue, 0)
                                        parameterValueView.close
                                    end if
                                    if isValid(parameterValueView) then
                                        set relView = relViewExists(rel, actionView, parameterValueView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, actionView, parameterValueView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                end if
                set cvwObjectView = Nothing
            end if
        end if
        set populateLogicalRule = ruleView
    End Function

'-----------------------------------------------------------
    Private Function populateExpression(workWindow, ruleObject, fromOpen)
        dim ruleView
        dim child, children
        dim expression, expressions, expressionView
        dim fromObj, fromObjView
        dim parameterObject, parameterObjectView
        dim parameterValue, parameterValueView
        dim rel, rels, relView, view, views
        dim part, parts, partView
        dim cvwObjectView
        dim textscale
        dim objGeo, size
        dim objHeight
        dim isInput

        set populateExpression = Nothing
        if not fromOpen then
            if isValid(workWindow) then
                set children = workWindow.children
                for each child in children
                    call currentModelView.deleteObjectView(child)
                next
            end if
        end if
        if isValid(workWindow) and isEnabled(ruleObject) then
            set ruleView = viewExists(ruleObject, workWindow)
            if isValid(ruleView) then
                if fromOpen then
                    textscale = ruleView.textscale
                    textscale = textscale / 1
                    ruleView.textScale = textScale
                end if
            else
                set ruleView = workWindow.newObjectView(ruleObject)
                textscale = ruleView.textscale
                textscale = textscale / 5
                ruleView.textScale = textScale
            end if
            if isValid(ruleView) then
                set cvwObjectView = new CVW_ObjectView
                cvwObjectView.heightRatio = ObjectAspectRatio
                if hasInstance(ruleView) then
                    ' Find expressions
                    set expressions = ruleObject.getNeighbourObjects(0, hasExpressionType, expressionType)
                    for each expression in expressions
                        set expressionView = viewExists(expression, ruleView)
                        if not isValid(expressionView) then
                            cvwObjectView.nestedTextFactor1 = 1.75
                            set expressionView = cvwObjectView.create(workWindow, ruleView, expression, 0)
                            expressionView.close
                        end if
                        exit for
                    next
                    ' Find inputToRels from parameter values
                    if isEnabled(expression) then
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(1, inputToRelType)
                            for each rel in rels
                                set parameterObject = rel.origin
                                if isParameterType(parameterObject) then
                                    set parameterObjectView = Nothing
                                    set views = parameterObject.views
                                    if isValid(views) then
                                        for each view in views
                                            if isInView(view, ruleView) then
                                                set parameterObjectView = view
                                                exit for
                                            end if
                                        next
                                    end if
                                    if not isValid(parameterObjectView) then
                                        ' Create view of parameterValue
                                        cvwObjectView.nestedTextFactor1 = 1.75
                                        set parameterObjectView = cvwObjectView.create(workWindow, ruleView, parameterObject, 0)
                                        parameterObjectView.close
                                    end if
                                    if isValid(parameterObjectView) then
                                        set relView = relViewExists(rel, parameterObjectView, expressionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, parameterObjectView, expressionView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                    end if
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(1, inputTo2RelType)
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
                                        cvwObjectView.nestedTextFactor1 = 2.25
                                        set parameterValueView = cvwObjectView.create(workWindow, ruleView, parameterValue, 0)
                                        parameterValueView.close
                                    end if
                                    if isValid(parameterValueView) then
                                        set relView = relViewExists(rel, parameterValueView, expressionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, parameterValueView, expressionView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                    next
                    ' Find outputToRels to parameter values
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(0, outputToRelType)
                            for each rel in rels
                                set parameterObject = rel.target
                                if isParameterType(parameterObject) then
                                    set parameterObjectView = Nothing
                                    set views = parameterObject.views
                                    if isValid(views) then
                                        for each view in views
                                            if isInView(view, ruleView) then
                                                set parameterObjectView = view
                                                exit for
                                            end if
                                        next
                                    end if
                                    if not isValid(parameterObjectView) then
                                        ' Create view of parameterValue
                                        cvwObjectView.nestedTextFactor1 = 1.75
                                        set parameterObjectView = cvwObjectView.create(workWindow, ruleView, parameterObject, 0)
                                        parameterObjectView.close
                                    end if
                                    if isValid(parameterObjectView) then
                                        set relView = relViewExists(rel, expressionView, parameterObjectView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, expressionView, parameterObjectView)
                                        end if
                                    end if
                                end if
                            next
                        end if
                    next
                end if
                set cvwObjectView = Nothing
            end if
        end if
        set populateExpression = ruleView
    End Function

'-----------------------------------------------------------
    Public Sub startConfigureCC(obj1, variantName)
        dim modelObj, modelObject
        dim product, products
        dim parts, ccPart

        if not isEnabled(obj1) then
            exit sub
        end if

        set parts = contentModel.parts
        for each modelObj in parts
            if modelObj.type.uri = modelObjectType.uri then
                if modelObj.title = obj1.title then
                    ' Model object is found - find variant
                    set products = modelObj.parts
                    for each product in products
                        if product.title = variantName then
                            ' Variant is found - delete
                            call deletePartStructure(product)
                        end if
                    next
                    set modelObject = modelObj
                    exit for
                end if
            end if
        next
        if not isEnabled(modelObject) then
            ' Create the model object
            set modelObject = contentModel.newObject(modelObjectType)
            modelObject.title = obj1.title
        end if
        ' Start building the part structure
        set ccPart = modelObject.newPart(partType)
        if Len(variantName) > 0 then
            ccPart.title = variantName
        else
            ccPart.title = obj1.title
        end if
        call configureCC(modelObject, ccPart, obj1)
    End Sub

'-----------------------------------------------------------
    Public Sub configureCC(modelObj, ccPart, obj)
        call configureFunctionMeans(obj)
        call configureTopCC(obj)
        call createPartStructure(modelObj, ccPart, obj)
    End Sub

'-----------------------------------------------------------
    Private Sub createPartStructure(modelObject, ccPart, obj1)
        dim csObj, ceObj, crObj
        dim csRels, ceRels, crRels, ccRels
        dim csRel, ceRel, crRel, ccRel
        dim part, obj, objects
        dim rel

        ' Find and create properties
        call createPartProperties(modelObject, ccPart, obj1)
        ' Create part structure
        set csRels = obj1.getNeighbourRelationships(0, hasCStype)
        for each csRel in csRels
            if includedInConfig(csRel) then
                set csObj = csRel.target
                set ceRels = csObj.getNeighbourRelationships(0, hasCEtype)
                for each ceRel in ceRels
                    if includedInConfig(ceRel) then
                        set ceObj = ceRel.target
                        if includedInConfig(ceObj) then
                            ' CE found - create and connect the new part
                            set part   = modelObject.newPart(partType)
                            if isEnabled(part) then
                                part.title = ceObj.title
                                set rel    = contentModel.newRelationship(memberType, ccPart, part)
                                set crRels = ceObj.getNeighbourRelationships(0, hasCRtype)
                                for each crRel in crRels
                                    if includedInConfig(crRel) then
                                        set crObj = crRel.target
                                        set ccRels = crObj.getNeighbourRelationships(0, usesCCtype)
                                        for each ccRel in ccRels
                                            if includedInConfig(ccRel) then
                                                set obj = ccRel.target
                                                call configureCC(modelObject, part, obj)
                                            end if
                                        next
                                    end if
                                next
                            end if
                        end if
                    end if
                next
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub createPartProperties(modelObject, ccPart, obj2)
        dim model, rel
        dim frObj, frObjects
        dim dsObj, dsObjects
        dim ppObj, ppObjects
        dim paramObj, paramObjects
        dim valueObj, valueObjects
        dim defObj, defObjects
        dim propName, propValue
        dim prop
        dim primary

        set model = modelObject.ownerModel
        ' Find FRs
        set ppObjects = obj2.getNeighbourObjects(0, hasPpType, ppType)
        for each ppObj in ppObjects
            call createPartProps(ppObj, model, modelObject, ccPart)
        next
        ' Find FRs
        set frObjects = obj2.getNeighbourObjects(0, explainsType, frType)
        for each frObj in frObjects
            if isEnabled(frObj) then
                ' Check if the FR is primary
                primary = frObj.getNamedValue("primary").getInteger
                if primary > 0 then
                    ' Find the corresponding DSs
                    set dsObjects = frObj.getNeighbourObjects(0, solvesType, dsType)
                    for each dsObj in dsObjects
                        ' Check if DS is included in configuration
                        if includedInConfig(dsObj) then
                            call createPartProps(dsObj, model, modelObject, ccPart)
                        end if
                    next
                end if
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub createPartProps(obj, model, modelObject, ccPart)
        dim valueObj, valueObjects
        dim paramObj, paramObjects
        dim defObj, defObjects
        dim propValue
        dim prop, rel

        ' Find parameters
        set paramObjects = obj.getNeighbourObjects(0, hasDpType, dpType)
        set valueObjects = obj.getNeighbourObjects(0, hasValueType, valueType)
        for each paramObj in paramObjects
            ' Design parameter
            propValue = ""
            for each valueObj in valueObjects
                set defObjects = valueObj.getNeighbourObjects(0, hasDefinitionType, parameterType)
                for each defObj in defObjects
                    if defObj.title = paramObj.title then
                        ' Parameter has been given a value
                        propValue = valueObj.getNamedStringValue("value")
                        exit for
                    end if
                next
            next
            ' For each parameter create a property
            set prop = modelObject.newPart(propertyType)
            prop.title = paramObj.title
            if Len(propValue) > 0 then
                ' Set the value, if given
                call prop.setNamedStringValue("value", propValue)
            end if
            set rel = model.newRelationship(hasPropertyType, ccPart, prop)
        next
    End Sub

'-----------------------------------------------------------
    Private Sub deletePartStructure(product)
        dim model
        dim part, parts
        dim prop, properties

        set model = product.ownerModel
        set parts = product.getNeighbourObjects(0, memberType, partType)
        for each part in parts
            call deletePartStructure(part)
        next
        set properties = product.getNeighbourObjects(0, hasPropertyType, propertyType)
        for each prop in properties
            call model.deleteObject(prop)
        next
        call model.deleteObject(product)
    End Sub

'-----------------------------------------------------------
    Private Function includedInConfig(inst)
        dim ival

        on error resume next
        includedInConfig = true
        if not isEnabled(inst) then
            includedInConfig = false
        end if
        ival = inst.getNamedValue(RuleEvaluatedToProperty).getInteger
        if ival = 0 then
            includedInConfig = false
        end if

    End Function
'-----------------------------------------------------------
    Public Sub configureTopCC(obj)
        dim rel, rels
        dim mode

        call transformRulesToScripts(obj)
        mode = 1
        call ccRuleEngine.executeRules(obj, mode)
        set rels = obj.getNeighbourRelationships(0, hasCStype)
        for each rel in rels
            call configureCS(rel, mode)
        next
    End Sub

    Private Sub configureCS(relship, mode)
        dim obj
        dim rel, rels

        call transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, mode)
        set obj = relship.target
        call transformRulesToScripts(obj)
        call ccRuleEngine.executeRules(obj, mode)
        set rels = obj.getNeighbourRelationships(0, hasCEtype)
        for each rel in rels
            call configureCE(rel, mode)
        next
    End Sub

    Private Sub configureCE(relship, mode)
        dim obj
        dim rel, rels

        call transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, mode)
        set obj = relship.target
        call transformRulesToScripts(obj)
        call ccRuleEngine.executeRules(obj, mode)
        set rels = obj.getNeighbourRelationships(0, hasCRtype)
        for each rel in rels
            call configureCR(rel, mode)
        next
    End Sub

    Private Sub configureCR(relship, mode)
        dim obj
        dim rel, rels

        call transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, mode)
        set obj = relship.target
        call transformRulesToScripts(obj)
        call ccRuleEngine.executeRules(obj, mode)
        set rels = obj.getNeighbourRelationships(0, usesCCtype)
        for each rel in rels
            call configureSubCC(rel, mode)
        next
    End Sub

    Private Sub configureSubCC(relship, mode)
        dim obj

        call transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, mode)
        'set obj = relship.target
        'call transformRulesToScripts(obj)
        'call ccRuleEngine.executeRules(obj, mode)
    End Sub

'-----------------------------------------------------------
    Public Sub configureFunctionMeans(obj1)
        dim obj, objects
        dim rels
        dim mode

        mode = 1
        ' Find top FR's
        set objects = obj1.getNeighbourObjects(0, explainsType, frType)
        for each obj in objects
            if isEnabled(obj) then
                ' Check if the FR is required by a DS, if so this is not top
                set rels = obj.getNeighbourRelationships(1, requiresType)
                if rels.count = 0 then
                    ' Top FR
                    call configureFrDsC(obj, mode)
                end if
            end if
        next
        ' Find top C's
        set objects = obj1.getNeighbourObjects(0, explainsType, cType)
        for each obj in objects
            if isEnabled(obj) then
                call configureInstance(obj, mode)
            end if
        next
    End Sub

    Public Sub configureFrDsC(frObj, mode)
        dim obj, objects
        dim rel, rel2, rels, relships
        dim dsObj

        ' FR
        if isEnabled(frObj) then
            ' Configure FR
            call configureInstance(frObj, mode)
            ' Then look for DSs
            set relships = frObj.getNeighbourRelationships(0, solvesType)
            for each rel in relships
                 if isEnabled(rel) then
                    ' FR is solved by DS
                    call configureInstance(rel, mode)
                end if
            next
            ' Configure DS and C
            for each rel in relships
                 if isEnabled(rel) then
                    ' DS is found
                    set dsObj = rel.target
                    if isEnabled(dsObj) then
                        ' Find C
                        set objects = dsObj.getNeighbourObjects(0, constrainedType, cType)
                        for each obj in objects
                            ' DS is constrained by C
                            if isEnabled(obj) then
                                ' Configure C
                                call configureInstance(obj, mode)
                            end if
                        next
                        ' Configure DS
                        call configureInstance(dsObj, mode)
                    end if
                end if
            next
            ' Check for next levels of FrDsC
            for each rel in relships
                 if isEnabled(rel) then
                    ' DS is found
                    set dsObj = rel.target
                    if isEnabled(dsObj) then
                        set rels = dsObj.getNeighbourRelationships(0, requiresType)
                        for each rel2 in rels
                            if isEnabled(rel2) then
                                call configureInstance(rel2, mode)
                            end if
                        next
                        for each rel2 in rels
                            if isEnabled(rel2) then
                                call configureFrDsC(rel2.target, mode)
                            end if
                        next
                    end if
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub configureInstance(inst, mode)
        call transformRulesToScripts(inst)
        call ccRuleEngine.executeRules(inst, mode)
    End Sub

'-----------------------------------------------------------
    Public Sub transformRulesToScripts(parentInst)
        dim rule, rules
        dim intVal

        set rules = getRules(parentInst)
        if rules.count > 0 then
            for each rule in rules
                if isEnabled(rule) then
                    call transformToScript(rule)
                end if
            next
        else
            set intVal = metis.newValue
            call intVal.setInteger(1)
            call parentInst.setNamedValue(RuleEvaluatedToProperty, intVal)
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub transformToScript(ruleObject)
        dim expression, expressions
        dim text1, text2, text3
        dim ruleKind

        if isEnabled(ruleObject) then
            ruleKind = ruleObject.getNamedStringValue("ruleKind")
            if ruleKind = "Expression" or ruleKind = "Service" then
                set expressions = ruleObject.getNeighbourObjects(0, hasExpressionType, expressionType)
                if expressions.count > 0 then
                    set expression = expressions(1)
                    call transformExpressionToScript(expression)
                    ' Set complete script in rule object
                    text1 = expression.getNamedStringValue("ruleInitCode")
                    text2 = expression.getNamedStringValue("ruleCode")
                    text3 = expression.getNamedStringValue("rulePostCode")
                    call ruleObject.setNamedStringValue("ruleCode", text1 & text2 & text3)
                end if
            else
                call transformLogicalRuleToScript(ruleObject)
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub transformExpressionToScript(expression)
        dim expressions
        dim rel, rels
        dim inputs(), noInputs
        dim inputs2(), noInputs2
        dim outputs(), noOutputs
        dim initScript(), preScript(), mainScript(), postScript()
        dim s, i, j, lineNo
        dim text1, text2, text3

            ' Find input parameters
            set rels = expression.getNeighbourRelationships(1, inputToRelType)
            noInputs = rels.count
            i = 0
            if noInputs > 0 then
                ReDim Preserve inputs(noInputs + 1)
                for each rel in rels
                    s = rel.getNamedStringValue("paramId")
                    if Len(s) > 0 then
                        i = i + 1
                        inputs(i) = s
                    end if
                next
            end if
            ' Find input parameter values
            set rels = expression.getNeighbourRelationships(1, inputTo2RelType)
            noInputs2 = rels.count
            i = 0
            if rels.count > 0 then
                ReDim Preserve inputs2(noInputs2 + 1)
                for each rel in rels
                    s = rel.getNamedStringValue("paramId")
                    if Len(s) > 0 then
                        i = i + 1
                        inputs2(i) = s
                    end if
                next
            end if
            ' Find output parameters
            set rels = expression.getNeighbourRelationships(0, outputToRelType)
            noOutputs = rels.count
            i = 0
            if noOutputs > 0 then
                ReDim Preserve outputs(noOutputs + 1)
                for each rel in rels
                    s = rel.getNamedStringValue("paramId")
                    if Len(s) > 0 then
                        i = i + 1
                        outputs(i) = s
                    end if
                next
            end if
            ' Find condition parameter
            set rels = expression.getNeighbourRelationships(0, inputTo3Type)
            if rels.count > 0 then
                noOutputs = noOutputs + rels.count
                ReDim Preserve outputs(noOutputs + 1)
                for each rel in rels
                    s = rel.getNamedStringValue("paramId")
                    if Len(s) > 0 then
                        i = i + 1
                        outputs(i) = s
                    end if
                next
            end if
            ' Build InitCode script
            ReDim Preserve initScript(noInputs + noInputs2 + 10)
            initScript(1) = "dim ccRuleEngine, contextInst"
            s = "dim "
            for i = 1 to noInputs
                if Len(inputs(i)) > 0 then
                    if i > 1 then s = s & ", "
                    s = s & inputs(i)
                end if
            next
            for j = 1 to noInputs2
                if Len(inputs2(j)) > 0 then
                    if i > 1 then s = s & ", "
                    i = i + j
                    s = s & inputs2(j)
                end if
            next
            for j = 1 to noOutputs
                if Len(outputs(j)) > 0 then
                    if i > 1 then s = s & ", "
                    i = i + j
                    s = s & outputs(j)
                end if
            next
            if Len(s) <= 4 then  s = ""
            initScript(2) = s
            initScript(3) = ""
            initScript(4) = "set ccRuleEngine = new CC_RuleEngine"
            initScript(5) = ""
            lineNo = 5
            for i = 1 to noInputs
                if Len(inputs(i)) > 0 then
                    lineNo = lineNo + 1
                    initScript(lineNo) = inputs(i) & " = ccRuleEngine.getInputParameter(" & Chr(34) & inputs(i) & Chr(34) & ")"
                end if
            next
            for i = 1 to noInputs2
                if Len(inputs2(i)) > 0 then
                    lineNo = lineNo + 1
                    initScript(lineNo) = inputs2(i) & " = ccRuleEngine.getInputParameterValue(" & Chr(34) & inputs2(i) & Chr(34) & ")"
                end if
            next
            initScript(lineNo + 1) = ""
            ' Build Code script
            ReDim Preserve preScript(7)
            preScript(1) = "'----------------------------------------------------------------------------"
            preScript(2) = ""
            preScript(3) = "' Context parameters: ccRuleEngine, contextInst"

            s = "' Input parameter(s):  "
            for i = 1 to noInputs
                if Len(inputs(i)) > 0 then
                    if i > 1 then s = s & ", "
                    s = s & inputs(i)
                end if
            next
            for j = 1 to noInputs2
                if Len(inputs2(j)) > 0 then
                    if i > 1 then s = s & ", "
                    i = i + j
                    s = s & inputs2(j)
                end if
            next
            preScript(4) = s
            s = "' Output parameter(s): "
            for i = 1 to noOutputs
                if Len(outputs(i)) > 0 then
                    if i > 1 then s = s & ", "
                    s = s & outputs(i)
                end if
            next
            preScript(5) = s
            preScript(6) = "'----------------------------------------------------------------------------"

            ' Build PostCode script
            ReDim Preserve postScript(noOutputs + 10)
            lineNo = 1
            postScript(1) = ""
            postScript(2) = ""
            lineNo = 2
            for i = 1 to noOutputs
                if Len(outputs(i)) > 0 then
                    lineNo = lineNo + 1
                    if outputs(i) = "Condition" then
                        postScript(lineNo) = "call ccRuleEngine.setCondition(" & outputs(i) & ")"
                    else
                        postScript(lineNo) = "call ccRuleEngine.setOutputParameter(" & Chr(34) & outputs(i) & Chr(34) & ", " & outputs(i) & ")"
                    end if
                end if
            next
            postScript(lineNo + 1) = ""
            postScript(lineNo + 2) = "set ccRuleEngine = Nothing"
            postScript(lineNo + 3) = ""
            postScript(lineNo + 4) = "' End"

            i = 1
            text1 = ""
            do while not isEmpty(initScript(i))
                text1 = text1 & initScript(i) & vbCrLf
                i = i + 1
            loop
            call expression.setNamedStringValue("ruleInitCode", text1)
            i = 1
            text2 = ""
            do while not isEmpty(preScript(i))
                text2 = text2 & preScript(i) & vbCrLf
                i = i + 1
            loop
            call expression.setNamedStringValue("rulePreCode", text2)
            i = 1
            text3 = ""
            do while not isEmpty(postScript(i))
                text3 = text3 & postScript(i) & vbCrLf
                i = i + 1
            loop
            call expression.setNamedStringValue("rulePostCode", text3)

    End Sub

'-----------------------------------------------------------
    Private Sub transformLogicalRuleToScript(ruleObject)
        dim lineNo
        dim action, actions, outputs, ifThens
        dim operator, operation
        dim condition
        dim paramType, paramObj, valueObj
        dim script(), text
        dim setParam
        dim i

        lineNo = 0
        ' Find the action
        set actions = ruleObject.getNeighbourObjects(0, hasActionType, actionType)
        if actions.count > 0 then
            setParam = false
            set action = actions(1)
            operation = action.getNamedStringValue("operation")
            if operation = "setParameterValue" then
                setParam = true
            end if
            if Len(operation) > 0 then
                ReDim Preserve script(lineNo + 5)
                lineNo = lineNo + 1
                script(lineNo) = "end if"
                lineNo = lineNo + 1
                if debug then
                    script(lineNo) = "    call " & operation
                else
                    script(lineNo) = "    call ccRuleEngine." & operation
                end if
                set outputs = action.getNeighbourObjects(0, outputToType, anyObjectType)
                if outputs.count > 0 then
                    set valueObj = outputs(1)
                    set paramObj = getCcParameterObj(valueObj)
                    if debug then
                        paramType = getCcParameterType(valueObj)
                        script(lineNo) = script(lineNo) & "(" & Chr(34) & paramType & ", " & Chr(34) & paramObj.title & Chr(34) & ", " & Chr(34) & valueObj.title & Chr(34) & ") "
                    else
                        script(lineNo) = script(lineNo) & "(" & Chr(34) & paramObj.uri & Chr(34) & ", " & Chr(34) & valueObj.uri & Chr(34) & ") "
                    end if
                end if

                lineNo = lineNo + 1
                script(lineNo) = "if condition then"
                ' Find the conditions
                set ifThens = action.getNeighbourObjects(1, ifThenType, conditionType)
                if ifThens.count <> 0 then
                    set condition = ifThens(1)
                    text = ""
                    text = getCondition(ruleObject, condition, text, debug)
                    if Len(text) = 0 then exit sub
                end if
                if Len(text) > 0 then
                    lineNo = lineNo + 1
                    script(lineNo) = "condition = " & text & vbCrLf
                end if
                text = "set ccRuleEngine = new CC_RuleEngine" & vbCrLf
                for i = lineNo to 1 step -1
                    text = text & script(i) & vbCrLf
                next
                if setParam then
                    text = text & "call ccRuleEngine.includeInConfiguration" & vbCrLf
                end if
                text = text & "set ccRuleEngine = Nothing" & vbCrLf
                if Len(text) > 0 then
                    if debug then
                        MsgBox text
                    else
                        call ruleObject.setNamedStringValue("ruleCode", text)
                    end if
                end if
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Private Function getCondition(ruleObject, condition, text, debug)
        dim model
        dim inputRel, inputRels
        dim rel, rels
        dim valueObj, paramObj
        dim paramType, operator
        dim conditionObj
        dim testCondition
        dim expression
        dim i, ival, intVal

        operator = condition.getNamedStringValue("operator")
        if operator = "NOT" then
            text = text & " NOT "
        end if
        set inputRels = condition.getNeighbourRelationships(1, inputToType)
        set rels = condition.getNeighbourRelationships(1, inputTo3Type)
        operator = condition.getNamedStringValue("operator")
        for each rel in rels
            inputRels.addLast rel
        next
        if inputRels.count = 0 then
            if not (operator = "TRUE" or operator = "FALSE") then
                MsgBox "Syntax error: " & vbCrLf & "Illegal condition in rule: " & Chr(34) & ruleObject.title & Chr(34), vbExclamation
                getCondition = ""
            else
                getCondition = operator
            end if
        else
            i = 0
            for each inputRel in inputRels
                i = i + 1
                set valueObj = inputRel.origin
                if valueObj.type.uri = expressionType.uri then
                    set expression = valueObj
                    call transformExpressionToScript(expression)
                    ' Execute expression
                    testCondition = "FALSE"
                    set intVal = metis.newValue
                    call intVal.setInteger(0)
                    call expression.setNamedValue(ExprEvaluatedToProperty, intVal)
                    set model = expression.ownerModel
                    call model.runMethodOnInst(expressionMethod, expression)
                    ival = expression.getNamedValue(ExprEvaluatedToProperty).getInteger
                    if ival > 0 then
                        testCondition = "TRUE"
                    end if
                    text = text & " " & testCondition
                    if i < inputRels.count then
                        text = text & " " & operator & " "
                    end if
                else
                    set paramObj = getCcParameterObj(valueObj)
                    if debug then
                        paramType = getCcParameterType(valueObj)
                        text = text & "(getParameterValue(" & Chr(34) & paramType & Chr(34) & ", " & Chr(34) & paramObj.title & Chr(34) & ") = " & Chr(34) & valueObj.title &  Chr(34) & ")"
                    else
                        text = text & "(ccRuleEngine.getParameterValue(" & Chr(34) & paramObj.uri & Chr(34) & ") = ccRuleEngine.getValueOf(" & Chr(34) & valueObj.uri &  Chr(34) & "))"
                    end if
                    if i < inputRels.count then
                        text = text & " " & operator & " "
                    end if
                end if
            next

            set inputRels = condition.getNeighbourRelationships(1, inputTo2Type)
            for each inputRel in inputRels
                set conditionObj = inputRel.origin
                text = text & " " & operator & " ("
                text = getCondition(ruleObject, conditionObj, text, debug)
                text = text & ")"
            next
            getCondition = text
        end if
    End Function

'-----------------------------------------------------------
    Private Function getCcParameterObj(valueObj)
        dim paramType
        dim hasValueType
        dim hasVPVtype, hasCPVtype, hasFPVtype, hasDPVtype, hasPPVtype
        dim paramObj, paramRels

        set getCcParameterObj = Nothing

        set hasVPVtype = metis.findType("http://xml.chalmers.se/class/has_variant_parameter_value.kmd#has_variant_parameter_value")
        set hasCPVtype = metis.findType("http://xml.chalmers.se/class/has_constraint_parameter_value.kmd#has_constraint_parameter_value")
        set hasFPVtype = metis.findType("http://xml.chalmers.se/class/has_functional_requirement_parameter_value.kmd#has_functional_requirement_parameter_value")
        set hasDPVtype = metis.findType("http://xml.chalmers.se/class/has_design_parameter_value.kmd#has_design_parameter_value")
        set hasPPVtype = metis.findType("http://xml.chalmers.se/class/has_performance_parameter_value.kmd#has_performance_parameter_value")

        paramType = getCcParameterType(valueObj)
        select case paramType
        case "VP"   set hasValueType = hasVPVtype
        case "CP"   set hasValueType = hasCPVtype
        case "FP"   set hasValueType = hasFPVtype
        case "DP"   set hasValueType = hasDPVtype
        case "PP"   set hasValueType = hasPPVtype
        end select
        if isValid(hasValueType) then
            set paramRels = valueObj.getNeighbourRelationships(1, hasValueType)
            if paramRels.count > 0 then
                set paramObj = paramRels(1).origin
                if isEnabled(paramObj) then
                    set getCcParameterObj = paramObj
                end if
            end if
        end if

    End Function

'-----------------------------------------------------------
    Private Function getCcParameterType(valueObj)
        dim vType
        dim vpvType, cpvType, fpvType, dpvType, ppvType

        getCcParameterType = ""

        set cpvType      = metis.findType("http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value")
        set dpvType      = metis.findType("http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value")
        set fpvType      = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value")
        set ppvType      = metis.findType("http://xml.chalmers.se/class/performance_parameter_value.kmd#performance_parameter_value")
        set vpvType      = metis.findType("http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value")

        set vType = valueObj.type
        if vType.inherits(vpvType) then
            getCcParameterType = "VP"
        elseif vType.inherits(cpvType) then
            getCcParameterType = "CP"
        elseif vType.inherits(fpvType) then
            getCcParameterType = "FP"
        elseif vType.inherits(dpvType) then
            getCcParameterType = "DP"
        elseif vType.inherits(ppvType) then
            getCcParameterType = "PP"
        end if
    End Function

'-----------------------------------------------------------
    Private Function isParameterType(inst)
        dim instType

        isParameterType = false
        set instType = inst.type
        if inst.type.inherits(parameterType) then
            isParameterType = true
        end if
    End Function

'-----------------------------------------------------------
    Private Function isParameterValueType(inst)
        dim instType

        isParameterValueType = false
        set instType = inst.type
        if inst.type.inherits(valueType) then
            isParameterValueType = true
        elseif inst.type.inherits(paramValueType) then
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
        'dim inst

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
        set csType           = metis.findType("http://xml.chalmers.se/class/composition_set.kmd#composition_set")
        set ceType           = metis.findType("http://xml.chalmers.se/class/composition_element.kmd#composition_element")
        set crType           = metis.findType("http://xml.chalmers.se/class/composition_request.kmd#composition_request")
        set frType           = metis.findType("http://xml.chalmers.se/class/functional_requirement.kmd#functional_requirement")
        set dsType           = metis.findType("http://xml.chalmers.se/class/design_solution.kmd#design_solution")
        set cType            = metis.findType("http://xml.chalmers.se/class/constraint.kmd#constraint")
        set frType           = metis.findType("http://xml.chalmers.se/class/functional_requirement.kmd#functional_requirement")
        set cpType           = metis.findType("http://xml.chalmers.se/class/constraint_parameter.kmd#constraint_parameter")
        set dpType           = metis.findType("http://xml.chalmers.se/class/design_parameter.kmd#design_parameter")
        set fpType           = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter.kmd#functional_requirement_parameter")
        set ppType           = metis.findType("http://xml.chalmers.se/class/performance_parameter.kmd#performance_parameter")
        set vpType           = metis.findType("http://xml.chalmers.se/class/variant_parameter.kmd#variant_parameter")
        set hasDpType        = metis.findType("http://xml.chalmers.se/class/has_design_parameter.kmd#has_design_parameter")
        set hasPpType        = metis.findType("http://xml.chalmers.se/class/has_performance_parameter.kmd#has_performance_parameter")
        set paramValueType   = metis.findType("http://xml.chalmers.se/class/cc_value.kmd#CC_value")
        set cpValueType      = metis.findType("http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value")
        set dpValueType      = metis.findType("http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value")
        set fpValueType      = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value")
        set ppValueType      = metis.findType("http://xml.chalmers.se/class/performance_parameter_value.kmd#performance_parameter_value")
        set vpValueType      = metis.findType("http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value")
        set explainsType     = metis.findType("http://xml.chalmers.se/class/is_explained_by.kmd#Is_explained_by")
        set solvesType       = metis.findType("http://xml.chalmers.se/class/is_solved_by.kmd#is_solved_by")
        set requiresType     = metis.findType("http://xml.chalmers.se/class/requires_function.kmd#requires_function")
        set constrainedType  = metis.findType("http://xml.chalmers.se/class/is_constrained_by.kmd#Is_constrained_by")
        set parameterType    = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")

        set conditionType    = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#condition")
        set expressionType   = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#expression")
        set inputToRelType   = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#input_to")
        set inputTo2RelType  = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#input_to_2")
        set outputToRelType  = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#output_to")
        set ruleType         = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")
        set inputToType      = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to")
        set inputTo2Type     = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to_2")
        set inputTo3Type     = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to_3")
        set outputToType     = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#has_output")
        set hasActionType    = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_action")
        set hasConditionType = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_condition")
        set hasExpressionType = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_expression")
        set hasInputType     = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_input")
        set hasOutputType    = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_output")
        set hasRuleType      = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_rule")
        set ifThenType       = metis.findType("http://xml.chalmers.se/class/rule.kmd#if_then")
        set isSubjectOfType  = metis.findType("http://xml.chalmers.se/class/rule.kmd#subject_of_rule")
        set anyObjectType    = metis.findType("metis:stdtypes#oid1")
        set hasCStype  = metis.findType("http://xml.chalmers.se/class/is_composed_using.kmd#is_composed_using")
        set hasCEtype  = metis.findType("http://xml.chalmers.se/class/has_composition_element.kmd#has_composition_element")
        set hasCRtype  = metis.findType("http://xml.chalmers.se/class/has_composition_request.kmd#has_composition_request")
        set usesCCtype = metis.findType("http://xml.chalmers.se/class/uses_configurable_component.kmd#uses_configurable_component")

        set partType         = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        set memberType       = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Member_UUID")
        set modelObjectType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID")
        set propertyType     = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        set valueType        = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
        set hasValueType     = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
        set hasDefinitionType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")

        ' Methods
        set ruleMethod        = metis.findMethod("http://xml.chalmers.se/methods/rule_methods.kmd#evaluateRule")
        set expressionMethod  = metis.findMethod("http://xml.chalmers.se/methods/rule_methods.kmd#evaluateExpression")

        ' Model
        'set inst = metis.findInstance("http://xml.chalmers.se/metamodels/cvw_cc_actions_1.kmv#_002ask601qg2tl2ra0ce")
        set configModel  = currentInstance.ownerModel

        ' Variables
        set ccRuleEngine = new CC_RuleEngine

        ExprEvaluatedToProperty = "expressionEvaluatedTo"
        RuleEvaluatedToProperty = "ruleEvaluatedTo"
        ruleKind = "Logical rule"
        ObjectAspectRatio = 1.0
        debug = false

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
        set ccRuleEngine = Nothing
    End Sub

End Class

