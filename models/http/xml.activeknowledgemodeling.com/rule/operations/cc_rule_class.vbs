option explicit
'-----------------------------------------------------------
'-----------------------------------------------------------
Class Rule


    ' Variant parameters
    Public Title                        ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Public ObjectAspectRatio
    Public contextModel
    Public ExpressionLayout

    ' Debug
    Public debug

    ' Types
    Private buttonType
    Private hasContextType
    Private specContainerType
    Private hasInstanceContextType

    Private anyObjectType

    Private modelObjectType

    Private partType
    Private requirementType
    Private specificationType

    ' Methods

    ' Arguments
    Private currentWindow
    Private configModel
    Private ruleKind '- handled by type rather than attribute
    Private ExprEvaluatedToProperty
    Private RuleEvaluatedToProperty
    
    ' Modes
    private REQUIREMENT_TYPE
    private SPECIFICATION_TYPE
    private PART_TYPE
    
    '-- IRTV config objects:
    private currentConfig
	private params
	
	Public Property Get config        'IRTV_Config
		if not isValid(currentConfig) then
			if not isValid(GLOBAL_Context) then ' if internal not valid, then create it ..
				set currentConfig = new IRTV_Config
			else
				set currentConfig = GLOBAL_Context
			end if 
		end if
        set config = currentConfig
    End Property

    Public Property Set config(obj)
        if isValid(obj) then
            set currentConfig = obj
            set model           = currentConfig.model
			set modelView       = currentConfig.modelView
			set inst            = currentConfig.inst
			set instView        = currentConfig.instView 
        end if
    End Property
    
    Public Property Get parameters     
		if not isValid(params) then 
			set params = new CVW_ParameterManager
			set params.config = config
		end if
        set parameters = params
    End Property

    Public Property Set parameters(obj)
        if isValid(obj) then
			set params = obj
            set config = params.config
		end if
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
				ruleKind = kind(rule)
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
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set rules = metis.newInstanceList
            call rules.addLast(inst)
        elseif inst.isRelationship then
            set rules = metis.newInstanceList
            noRules = getRelationshipRules(inst, rules)
        elseif inst.isObject then
            set rules = inst.getNeighbourObjects(1, GLOBAL_Type_subjectOf, GLOBAL_Type_Rule) ' object <--works-on-- rule
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
        dim r, rules
        dim ruleObject, expressionObject, serviceObject
        dim model, modelObject
        dim cvwSelectDialog

        set findRule = Nothing
        if currentInstance.type.uri = GLOBAL_Type_Rule.uri then
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
                set ruleObject = modelObject.newPart(GLOBAL_Type_Rule)
                if isEnabled(ruleObject) then
                    ruleObject.title = "New rule"
                    rules.addLast ruleObject
                end if
                ' Create the expression object
                set expressionObject = modelObject.newPart(GLOBAL_Type_Expr)
                if isEnabled(expressionObject) then
                    expressionObject.title = "New expression"
                    'call expressionObject.setNamedStringValue("ruleKind", "Expression")
                    rules.addLast expressionObject
                end if
                ' Create the service object
                set serviceObject = modelObject.newPart(GLOBAL_Type_Script)
                if isEnabled(serviceObject) then
                    serviceObject.title = "New service"
                    'call serviceObject.setNamedStringValue("ruleKind", "Service")
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
        dim infoObject, infoObjects
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
                set infoObjects = model.findInstances(GLOBAL_Type_EkaObject, "", "")
                if isValid(infoObjects) then
                    if infoObjects.count > 0 then
                        set infoObject = infoObjects(1)
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
                    if isEnabled(infoObject) then
                        set hasRuleRel = model.newRelationship(GLOBAL_Type_hasRule, infoObject, ruleObject)
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
                        set subjectOfRel = model.newRelationship(GLOBAL_Type_subjectOf, currentInstance, ruleObject)
                        if isEnabled(subjectOfRel) then hasSubject = true
                    end if
                    if hasSubject then
                        if isLogical then
                            ' Create condition and action objects
                            set conditionObject = modelObject.newPart(GLOBAL_Type_Condition)
                            set actionObject = modelObject.newPart(GLOBAL_Type_Action)
                            if isEnabled(conditionObject) and isEnabled(actionObject) then
                                ' Create relationships
                                set partOfRel = model.newRelationship(GLOBAL_Type_hasCondition, ruleObject, conditionObject)
                                set partOfRel = model.newRelationship(GLOBAL_Type_hasAction, ruleObject, actionObject)
                                set ifThenRel = model.newRelationship(GLOBAL_Type_ifThen, conditionObject, actionObject)
                            end if
                        else
                            ' Create expression
                            set expressionObject = modelObject.newPart(GLOBAL_Type_Expr)
                            if isEnabled(expressionObject) then
                                expressionObject.title = "Expression"
                                ' Create relationship
                                set partOfRel    = model.newRelationship(GLOBAL_Type_hasExpr, ruleObject, expressionObject)
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

        set relships = rule.getNeighbourRelationships(0, GLOBAL_Type_subjectOf)
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
'   Generate graphical view of the rule
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
                set cvwAction.contextModel = contentModel
                call cvwAction.execute
                set workarea = cvwAction.workarea
                if isValid(workarea) and isEnabled(ruleObject) then
                    set workWindow = workarea.WorkWindow
                    ' Get CVW_Workarea
                    set cvwWorkarea = new CVW_Workarea
                    set cvwWorkarea.WorkWindow = workWindow
                    ' Set context instance
                    set wObject = workWindow.instance
                    set rels = wObject.getNeighbourRelationships(0, hasInstanceContextType) ' should be "equals". -HDJ
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
    
	' ----
	private function kind(ruleObject)
        'if inheritsType(ruleObject, GLOBAL_Type_Script, config.inheritance) then
        '    kind = "Service"
        'else
        if inheritsType(ruleObject, GLOBAL_Type_Expr, config.inheritance) then
            kind = "Expression"
        else
			kind = "Logical rule"
        end if
	end function

'-----------------------------------------------------------
    Public Function populateRule(workWindow, ruleObject, fromOpen)
		ruleKind = kind(ruleObject)
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
                    set actions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasAction, GLOBAL_Type_Action)
                    for each action in actions
                        set actionView = viewExists(action, ruleView)
                        if not isValid(actionView) then
                            cvwObjectView.nestedTextFactor1 = 3
                            set actionView = cvwObjectView.create(workWindow, ruleView, action, 0)
                            actionView.close
                        end if
                    next
                    ' Find conditions
                    set conditions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasCondition, GLOBAL_Type_Condition)
                    for each condition in conditions
                        set conditionView = viewExists(condition, ruleView)
                        if not isValid(conditionView) then
                            cvwObjectView.nestedTextFactor1 = 3
                            set conditionView = cvwObjectView.create(workWindow, ruleView, condition, 1)
                            conditionView.close
                        end if
                    next
                    ' Find expressions
                    set expressions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
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
                            set rels = action.getNeighbourRelationships(1, GLOBAL_Type_ifThen)
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
                            set rels = condition.getNeighbourRelationships(1, GLOBAL_Type_inputTo2)
                            if rels.count = 0 then
                                set rels = condition.getNeighbourRelationships(1, GLOBAL_Type_inputTo1)
                            end if
                            for each rel in rels
                                set fromObj = rel.origin
                                if fromObj.type.uri = GLOBAL_Type_Condition.uri then
                                    set fromObjView = fromObj.views(1)
                                    if isInView(fromObjView, ruleView) then
                                        set relView = relViewExists(rel, fromObjView, conditionView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, fromObjView, conditionView)
                                        end if
                                    end if
                                elseif fromObj.type.uri = GLOBAL_Type_VPV.uri then
                                end if
                            next
                        end if
                    next
                    ' Find inputToRels from expressions
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(0, GLOBAL_Type_inputTo3)
                            for each rel in rels
                                set toObj = rel.target
                                if toObj.type.uri = GLOBAL_Type_Condition.uri then
                                    set toObjView = toObj.views(1)
                                    if isInView(toObjView, ruleView) then
                                        set relView = relViewExists(rel, expressionView, toObjView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, expressionView, toObjView)
                                        end if
                                    end if
                                elseif fromObj.type.uri = GLOBAL_Type_VPV.uri then
                                end if
                            next
                        end if
                    next
                    for each expression in expressions
                        set expressionView = expression.views(1)
                        if isValid(expressionView) then
                            set rels = expression.getNeighbourRelationships(0, GLOBAL_Type_inputTo3)
                            for each rel in rels
                                set toObj = rel.target
                                if toObj.type.uri = GLOBAL_Type_Condition.uri then
                                    set toObjView = toObj.views(1)
                                    if isInView(toObjView, ruleView) then
                                        set relView = relViewExists(rel, expressionView, toObjView)
                                        if not isValid(relView) then
                                            set relView = currentModelView.newRelationshipView(rel, expressionView, toObjView)
                                        end if
                                    end if
                                elseif fromObj.type.uri = GLOBAL_Type_VPV.uri then
                                end if
                            next
                        end if
                    next
                    ' Find inputToRels from parameter values to conditions
                    for each condition in conditions
                        set conditionView = condition.views(1)
                        if isValid(conditionView) then
                            set rels = condition.getNeighbourRelationships(1, GLOBAL_Type_inputTo1)
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
                            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr1)
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
                            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr2)
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
                            set rels = action.getNeighbourRelationships(0, GLOBAL_Type_outputTo)
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
        dim expressionLayoutStrategy
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
        dim noOutputs

        set populateExpression = Nothing
        noOutputs = 0
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
                    set expressions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
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
                            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr1)
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
                            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr2)
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
                            set rels = expression.getNeighbourRelationships(0, GLOBAL_Type_outputFromExpr)
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
                                        noOutputs = noOutputs + 1
                                    end if
                                end if
                            next
                        end if
                    next
                end if
                if noOutputs > 1 then
                    if Len(ExpressionLayout) > 0 then
                        set expressionLayoutStrategy = metis.findLayoutStrategy(ExpressionLayout)
                        set ruleView.layoutStrategy  = expressionLayoutStrategy
                    end if
                end if
                set cvwObjectView = Nothing
            end if
        end if
        set populateExpression = ruleView
    End Function



'-----------------------------------------------------------
'   Transform rules to scripts
'-----------------------------------------------------------
    Public Sub transformRulesToScripts(parentInst)
        dim r, rules
        dim intVal

        set rules = getRules(parentInst)
        if rules.count > 0 then
            for each r in rules
                if isEnabled(r) then
                    call transformToScript(r)
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

        if isEnabled(ruleObject) then
            ruleKind = kind(ruleObject)
            if ruleKind = "Expression" or ruleKind = "Service" then
                call transformExpressionToScript(ruleObject) ' HDJ added this first step
                'text1 = ruleObject.getNamedStringValue("ruleInitCode")
                'text2 = ruleObject.getNamedStringValue("ruleCode")
                'text3 = ruleObject.getNamedStringValue("rulePostCode")
                'call ruleObject.setNamedStringValue("ruleCode", text1 & text2 & text3)
                set expressions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)               
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

'-------------------------returns input parameter objects of a rule (recursive)  ----------------------------------
    Private function getInputs(rule)
		dim s, p, rels
		set rels = parameters.getAllNeighbours(rule, "", GLOBAL_Type_inputToExpr1, 0)
		set getInputs = metis.newInstanceList()
		for each p in rels
			if not getInputs.contains(p.target) then getInputs.addLast(p.target)
		next
		' check inherited parameters ...
		for each s in config.inheritance.supers(rule)
			for each p in parameters.getAllNeighbours(s, "", GLOBAL_Type_inputToExpr1, 0)
				if not getInputs.contains(p.target) then getInputs.addLast(p.target)
			next
		next
        ' check recursively all related condititions and actions, which have to be included
        for each s in parameters.getAllNeighbours(rule, "", GLOBAL_Type_EkaHasPart, 0) ' by inheritance this includes has_action, has_condition
 			for each p in getInputs(s.target)
				if not getInputs.contains(p) then getInputs.addLast(p)
			next       
        next
    end function
    
 '----------------------- returns output parameter objects of a rule (recursive) ------------------------------------
    Private function getOutputs(rule)
    	dim s, p, rels
		set getOutputs = metis.newInstanceList()
    	set rels = parameters.getAllNeighbours(rule, "", GLOBAL_Type_outputTo, 0)
    	for each p in rels
			if not getOutputs.contains(p.target) then getOutputs.addLast(p.target)
		next
		' check inherited parameters ...
		for each s in config.inheritance.supers(rule)
			for each p in parameters.getAllNeighbours(s, "", GLOBAL_Type_outputTo, 0)
				if not getOutputs.contains(p.target) then getOutputs.addLast(p.target)
			next
		next
        ' check recursively all related conditions and actions, which have to be included
        for each s in parameters.getAllNeighbours(rule, "", GLOBAL_Type_EkaHasPart , 0)
 			for each p in getOutputs(s.target)
				if not getOutputs.contains(p) then getOutputs.addLast(p)
			next       
        next
        
    end function

' --- finds and sets the initcode and precode properties of a rule based on input parameters-----

private sub setInputs(rule, inputs, outputs)
	dim decl, value, comment, param, name, first
	first = true
	
	decl = "dim parameters"
	value = "set parameters = new CVW_ParameterManager" & vbcrlf
	comment = "'----------------------------------------------------------------------------" & vbcrlf
    comment  = comment & "' Context parameters: "
            
	for each param in inputs
		name = param.getNamedStringValue("name")
		if Len(name) > 0 then
			if not instr(1,decl,name,1) then ' ignore duplicate names
				decl = decl & ", " & name
				if first then 
					first = false
				else 
					comment = comment & ", " & name 
				end if
				value = value & name & " = parameters.getValue(" & Chr(34) & name & Chr(34) & ")" & vbcrlf 
			end if
		end if
	next
	for each param in outputs
		name = param.getNamedStringValue("name")
		if Len(name) > 0 then
			if not instr(1,decl,name,1) then ' ignore duplicate names
				decl = decl & ", " & name
				if first then 
					first = false
				else 
					comment = comment & ", " & name 
				end if
			end if
		end if
	next
    call rule.setNamedStringValue("ruleInitCode", decl & vbcrlf & value)
    call rule.setNamedStringValue("rulePreCode", comment)
end sub


' --- finds and sets the postcode property of a rule based on output parameters-----
private sub setOutputs(rule, parameters)
	dim postscript, param, name
	postscript = ""
	for each param in parameters
		name = param.getNamedStringValue("name")
		if Len(name) > 0 then	
           postScript = postScript & "call parameters.setValue(" & Chr(34) & name & Chr(34) & ", " & name & ")" & vbcrlf
        end if
    next
    postScript = postScript & "set parameters = Nothing" & vbcrlf
    postScript = postScript & "' End"& vbcrlf
    call rule.setNamedStringValue("rulePostCode", postScript)
end sub
'-----------------------------------------------------------
    Private Sub transformExpressionToScript(expression)
		dim inputs, outputs
		set inputs = getInputs(expression)
		set outputs = getOutputs(expression)
		call setInputs(expression, inputs, outputs)
		call setOutputs(expression, outputs)
    End Sub

'-----------------------------------------------------------
    Private Sub transformLogicalRuleToScript(ruleObject)
        dim lineNo
        dim action, actions, outputs, ifThens
        dim operator, operation
        dim condition
        dim paramType, paramObj, valueObj
        dim script(), text, tt
        dim setParam
        dim i
        
        call transformExpressionToScript(ruleObject) ' set inputs and outputs ... HDJ added

        ' Find the action
        set actions = parameters.getAllNeighbours(ruleObject, "", GLOBAL_Type_hasAction, 0)
        if actions.count > 0 then
            'setParam = false
            text = ""
            for each action in actions
				set action = action.target ' list of relationships ...
				call transformExpressionToScript(action)
                lineNo = 0
				'set action = actions(1)
				'operation = "setParameterValue" 'action.getNamedStringValue("operation")
				'if operation = "setParameterValue" then
				'    setParam = true
				'end if
				'if Len(operation) > 0 then
				ReDim Preserve script(lineNo + 5)
				lineNo = lineNo + 1
				script(lineNo) = "end if"
				lineNo = lineNo + 1
				if debug then
					script(lineNo) = "    GLOBAL_TaskManager.perform( " & Chr(34)& action.uri & Chr(34)&")"
				else
					'script(lineNo) = "    GLOBAL_TaskManager.perform( " & Chr(34)& action.uri & Chr(34)&")"
					script(lineNo) = action.getNamedStringValue("ruleCode")
				end if
				' get all inherited neighbours related by reltype has_output or a subtype ...
				'set outputs = parameters.getAllNeighbours(action, "", GLOBAL_Type_outputTo, 0) 'action.getNeighbourObjects(0, GLOBAL_Type_outputTo, anyObjectType)
				' Parameter resolution ...
				'if outputs.count > 0 then
				'    set valueObj = outputs(1)
				'    'set paramObj = getCcParameterObj(valueObj)
				'    'if debug then
				'    '    paramType = getCcParameterType(valueObj)
				'    '    script(lineNo) = script(lineNo) & "(" & Chr(34) & paramType & ", " & Chr(34) & paramObj.title & Chr(34) & ", " & Chr(34) & valueObj.title & Chr(34) & ") "
				'    'else
				'        script(lineNo) = script(lineNo) & "(" & Chr(34) & valueObj.name & Chr(34) & ", " & Chr(34) & valueObj.uri & Chr(34) & ") "
				'    'end if
				'end if

				lineNo = lineNo + 1
				script(lineNo) = "if condition then"
				' Find the conditions
				set ifThens = parameters.getAllNeighbours(action, "", GLOBAL_Type_ifThen, 1)
				tt = ""
				for each condition in ifThens
					set condition = condition.origin ' list of relships
					tt = getCondition(ruleObject, condition, tt, debug)
					if Len(tt) = 0 then exit for
					tt = tt & " AND "
				next
				if Len(tt) > 0 then
					lineNo = lineNo + 1
					script(lineNo) = "condition = " & left(tt,len(tt)-5)
				end if
				'text = '"set rEngine = new RuleEngine" & vbCrLf
				for i = lineNo to 1 step -1
					text = text & script(i) & vbCrLf
				next
            next
            'if setParam then
            '    text = text & "call rEngine.includeInConfiguration" & vbCrLf
            'end if
            'text = text & "set rEngine = Nothing" & vbCrLf
            if Len(text) > 0 then
                if debug then
                    MsgBox text
                else
                    call ruleObject.setNamedStringValue("ruleCode", "dim condition" & vbcrlf & text)
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
        set inputRels = parameters.getAllNeighbours(condition,"", GLOBAL_Type_EkaHasPart  , 0)   'condition.getNeighbourRelationships(1, GLOBAL_Type_inputTo1)
        'set rels = parameters.getAllNeighbours(condition,"",GLOBAL_Type_inputTo3, 0) 'condition.getNeighbourRelationships(1, GLOBAL_Type_inputTo3)
        operator = condition.getNamedStringValue("operator")
        'for each rel in rels
        '    inputRels.addLast rel
        'next
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
                set valueObj = inputRel.target ' origin
                if valueObj.type.uri = GLOBAL_Type_Expr.uri then
                    set expression = valueObj
                    call transformExpressionToScript(expression)
                    '' Execute expression
                    'testCondition = "FALSE"
                    'set intVal = metis.newValue
                    'call intVal.setInteger(0)
                    'call expression.setNamedValue(ExprEvaluatedToProperty, intVal)
                    'set model = expression.ownerModel
                    'call model.runMethodOnInst(GLOBAL_Method_ExprExecute, expression)
                    'ival = expression.getNamedValue(ExprEvaluatedToProperty).getInteger
                    'if ival > 0 then
                    '    testCondition = "TRUE"
                    'end if
                    text = text & " (" & expression.getNamedStringValue("ruleCode")& ")"
                else
                    'set paramObj = getCcParameterObj(valueObj)
                    'if debug then
                    '    paramType = getCcParameterType(valueObj)
                    '    text = text & "(getParameterValue(" & Chr(34) & paramType & Chr(34) & ", " & Chr(34) & paramObj.title & Chr(34) & ") = " & Chr(34) & valueObj.title &  Chr(34) & ")"
                    'else
                        text = text & "(parameters.getValue(" & Chr(34) & valueObj.title & Chr(34) & ") = " & Chr(34) & valueObj.getNamedStringValue("value") &  Chr(34) & ")"
                    'end if
                end if
                if i < inputRels.count then
                    text = text & " " & operator & " "
                end if
            next

            set inputRels = condition.getNeighbourRelationships(1, GLOBAL_Type_inputTo2)
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
    Private Function contentModel           'IMetisObject
        dim context

        ' Find ContentModel
        if isValid(contextModel) then
            set contentModel = contextModel
            exit function
        end if
        if isValid(currentWindow) then
            set contentModel = currentModel
            set context = new EKA_Context
            set context.currentModel        = currentModel
            set context.currentModelView    = currentModelView
            set context.currentInstance     = currentWindow.instance
            set context.currentInstanceView = currentWindow
            if isValid(context) then
                if isEnabled(context.contentModel) then
                    set contextModel = context.contentModel
                    set contentModel = contextModel
                end if
            end if
            set context = Nothing
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()

        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        set currentWindow       = findWorkWindowView(currentInstanceView)
        set contextModel        = Nothing

        ' Initialize global variables
        if not RuleGlobalsInitialized then
			dim r
			set r = new Rule_Globals
		end if

        ' Types
        set buttonType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set hasContextType   = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")
        set hasInstanceContextType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

        set anyObjectType    = metis.findType("metis:stdtypes#oid1")

        set modelObjectType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_space.kmd#ObjType_EKA:Space_UUID")

        set partType          = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        set requirementType   = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        set specificationType = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")

        ' Methods

        ' Model
        'set inst = metis.findInstance("http://xml.chalmers.se/metamodels/cvw_cc_actions_1.kmv#_002ask601qg2tl2ra0ce")
        set configModel  = currentInstance.ownerModel

        ' Variables
        ExpressionLayout = "http://xml.activeknowledgemodeling.com/cvw/views/matrix_layouts.kmd#_002ash3011bccb0hs5tr"
        ExprEvaluatedToProperty = "expressionEvaluatedTo"
        RuleEvaluatedToProperty = "ruleEvaluatedTo"
        ruleKind = "Logical rule"
        ObjectAspectRatio = 1.0
        debug = false

        ' Modes
        REQUIREMENT_TYPE    = 1
        SPECIFICATION_TYPE  = 2
        PART_TYPE           = 3

    End Sub
    
End Class

