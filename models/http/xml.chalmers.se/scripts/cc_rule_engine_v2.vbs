option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_RuleEngine

    ' Variant parameters
    Public Title                        ' String
    
    Public MODE_CONFIGURE
    Public MODE_EXECUTE

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView

    ' Context variables (private)
    Private RuleEngineProperty
    Private RuleInitCodeProperty
    Private RuleCodeProperty
    Private RulePostCodeProperty
    Private RuleEvaluatedToProperty
    Private ExprEvaluatedToProperty
    Private CcValueProperty
    Private EkaValueProperty
    Private contextInstance


'-----------------------------------------------------------
    Public Sub includeInConfiguration
        dim myModel, inst
        dim intVal

        set myModel = metis.currentModel
        set inst = myModel.currentInstance

        'MsgBox "includeInConfiguration => " & inst.title
        set intVal = metis.newValue
        call intVal.setInteger(1)
        call inst.setNamedValue(RuleEvaluatedToProperty, intVal)
    End Sub

'-----------------------------------------------------------
    Public Sub excludeFromConfiguration
        dim myModel, inst
        dim intVal

        set myModel = metis.currentModel
        set inst = myModel.currentInstance

        'MsgBox "excludeFromConfiguration => " & inst.title
        set intVal = metis.newValue
        call intVal.setInteger(0)
        call inst.setNamedValue(RuleEvaluatedToProperty, intVal)
    End Sub

'-----------------------------------------------------------
    Public Function getInstanceOf(instUri)
        dim inst

        set getInstanceOf = Nothing
        if Len(instUri) > 0 then
            set inst = metis.findInstance(instUri)
            if isEnabled(inst) then
                set getInstanceOf = inst
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function getValueOf(instUri)
        dim inst

        getValueOf = ""
        if Len(instUri) > 0 then
            set inst = metis.findInstance(instUri)
            if isEnabled(inst) then
                on error resume next
                getValueOf = inst.getNamedStringValue(CcValueProperty)
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function getParameterValue(paramUri)
        dim myModel
        dim inst
        dim ccObj, paramObj
        dim value, values
        dim definition, definitions

        ' Initialization
        getParameterValue = ""
        set myModel     = metis.currentModel
        set inst        = myModel.currentInstance
        set paramObj    = metis.findInstance(paramUri)

        'MsgBox "getParameterValue  => " & inst.title
        ' Main code
        set ccObj = getCCobject(paramObj)
        if isEnabled(ccObj) then
            set values = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
            for each value in values
                set definitions = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_AnyObject)
                for each definition in definitions
                    if definition.uri = paramObj.uri then
                        getParameterValue = value.getNamedStringValue(EkaValueProperty)
                    end if
                next
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function setParameterValue(paramUri, valueUri)
        dim myModel, model
        dim inst
        dim ccObj, paramObj, valueObj
        dim value, values
        dim intVal
        dim definition, definitions
        dim paramValue, newValue
        dim rel
        dim done, changed

        ' Initialization
        changed = false

        set myModel     = metis.currentModel
        set inst        = myModel.currentInstance
        set paramObj    = metis.findInstance(paramUri)
        set valueObj    = metis.findInstance(valueUri)
        newValue        = valueObj.getNamedStringValue(CcValueProperty)

        ' Main code
        set ccObj = getCCobject(paramObj)
        if isEnabled(ccObj) then
            done = false
            ' MsgBox "setParameterValue  => " & inst.title  & vbCrLf & "ccObj = " & ccObj.title
            set values = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
            for each value in values
                set definitions = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_AnyObject)
                for each definition in definitions
                    if definition.uri = paramObj.uri then
                        ' Existing value
                        paramValue = value.getNamedStringValue(EkaValueProperty)
                        if paramValue = newValue then
                            done = true
                            exit for
                        else
                            call value.setNamedStringValue(EkaValueProperty, newValue)
                            done = true
                            changed = true
                            exit for
                        end if
                    end if
                next
                if done then exit for
            next
            if not done then
                set value = ccObj.newPart(GLOBAL_Type_EkaValue)
                if isEnabled(value) then
                    call value.setNamedStringValue(EkaValueProperty, newValue)
                    set model = ccObj.ownerModel
                    set rel = model.newRelationship(GLOBAL_Type_EkaHasValue, ccObj, value)
                    set rel = model.newRelationship(GLOBAL_Type_EkaHasDefinition, value, paramObj)
                end if
            end if
        end if
        setParameterValue = changed
    End Function

'-----------------------------------------------------------
    Public Function getInputParameter(strName)
        dim inst
        dim myModel
        dim expression, expressions
        dim ccObj, paramObj, paramObjects
        dim paramName
        dim rel, rels
        dim range, ranges
        dim val, sval, value, values
        dim definition, definitions
        dim rmin, rmax, s, text

        ' Initialization
        getInputParameter = Empty
        set myModel = metis.currentModel
        set inst    = myModel.currentInstance
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        else
            set expression = inst
        end if
        ' Main code
        if isEnabled(expression) then
            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr1)
            for each rel in rels
                ' Check param name
                paramName = rel.getNamedStringValue("paramId")
                if paramName = strName then
                    ' Parameter object
                    set paramObj = rel.origin
                    set ccObj = getCCobject(paramObj)
                    if isEnabled(ccObj) then
                        set values = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
                        for each value in values
                            set definitions = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_AnyObject)
                            for each definition in definitions
                                if definition.uri = paramObj.uri then
                                    ' Value found, get the value
                                    s = value.getNamedStringValue(EkaValueProperty)
                                    if Len(s) > 0 then
                                        if isNumeric(s) then
                                            val = CDbl(s)
                                            getInputParameter = val
                                        else
                                            getInputParameter = s
                                        end if
                                        exit function
                                    end if
                                    exit for
                                end if
                            next
                        next
                    elseif paramObj.type.inherits(GLOBAL_Type_CCParameter) then
                        ' This is a user input parameter
                        sval = paramObj.getNamedStringValue("inputvalue")    ' OBS
                        if Len(sval) > 0 then
                            if isNumeric(sval) then
                                val = CDbl(sval)
                                getInputParameter = val
                            else
                                getInputParameter = sval
                            end if
                            call paramObj.setNamedStringValue(EkaValueProperty, sval)
                            exit function
                        end if
                        ' No value given, ask for it
                        text = "The parameter " & strName & " has no value!" & vbCrLf
                        ' But first check if a range has been defined
                        set ranges = paramObj.parts
                        if ranges.count > 0 then
                            text = text & "The parameter value must be within the range ("
                            for each range in ranges
                                rmin = range.getNamedStringValue("min")
                                text = text & rmin & ", "
                                rmax = range.getNamedStringValue("max")
                                text = text & rmax
                            next
                            text = text & ")" & vbCrLf
                        end if
                        text = text & vbCrLf & "Please enter the value:"
                        sval = InputBox(text)
                        'sval = ""
                        if Len(sval) > 0 then
                            if isNumeric(sval) then
                                val = CDbl(sval)
                                if not isEmpty(rmin) then
                                    if rmin <= val and val <= rmax then
                                        call setParamValue(paramObj, sval)
                                    end if
                                else
                                    call setParamValue(paramObj, sval)
                                end if
                                getInputParameter = val
                            else
                                getInputParameter = sval
                            end if
                        end if
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function getInputParameterValue(strName)
        dim inst
        dim myModel
        dim expression, expressions
        dim ccObj, paramObj, paramObjects
        dim paramName, paramUri
        dim rel, rels, rels2
        dim range, ranges
        dim val, value, values
        dim definition, definitions
        dim rmin, rmax, s, text

        ' Initialization
        getInputParameterValue = Empty
        set myModel = metis.currentModel
        set inst    = myModel.currentInstance
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        else
            set expression = inst
        end if
        ' Main code
        if isEnabled(expression) then
            set rels  = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr2)
            for each rel in rels
                ' Check param name
                paramName = rel.getNamedStringValue("paramId")
                if paramName = strName then
                    ' Parameter object
                    paramUri = rel.origin.uri
                    s = getValueOf(paramUri)
                    if Len(s) > 0 then
                        if isNumeric(s) then
                            getInputParameterValue = CDbl(s)
                        else
                            getInputParameterValue = s
                        end if
                    end if
                    exit function
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function setOutputParameter(strName, newValue)
        dim myModel, model
        dim inst
        dim expression, expressions
        dim ccObj, paramObj, valueObj
        dim value, values
        dim definition, definitions
        dim paramValue
        dim paramName
        dim rel, rels

        ' Initialization
        setOutputParameter = false
        set myModel = metis.currentModel
        set inst    = myModel.currentInstance
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        end if
        ' Main code
        if isEnabled(expression) then
            set rels = expression.getNeighbourRelationships(0, GLOBAL_Type_outputFromExpr)
            for each rel in rels
                ' Check param name
                paramName = rel.getNamedStringValue("paramId")
                if paramName = strName then
                    ' Get value of parameter
                    set paramObj = rel.target
                    setOutputParameter = setParamValue(paramObj, newValue)
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Sub setCondition(cond)
        dim myModel, inst
        dim intVal, ival

        set myModel = metis.currentModel
        set inst = myModel.currentInstance

        'MsgBox "includeInConfiguration => " & inst.title
        if cond then
            ival = 1
        else
            ival = 0
        end if
        set intVal = metis.newValue
        call intVal.setInteger(ival)
        call inst.setNamedValue(ExprEvaluatedToProperty, intVal)
    End Sub

'-----------------------------------------------------------
    Public Sub setRuleStatus(ccObj, status)    ' Boolean
        dim intVal
        on error resume next

        set intVal = metis.newValue
        if status then
            if ccObj.getNamedValue("ruleStatus").getInteger = 0 then
                call intVal.setInteger(1)
                call ccObj.setNamedValue("ruleStatus", intVal)
            end if
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub clearRuleStatus(ccObj)    ' Boolean
        dim intVal
        on error resume next

        set intVal = metis.newValue
        call intVal.setInteger(0)
        call ccObj.setNamedValue("ruleStatus", intVal)
    End Sub

'-----------------------------------------------------------
    Private Function setParamValue(paramObj, newValue)
        dim model, inst
        dim ccObj, valueObj
        dim value, values
        dim definition, definitions
        dim paramValue
        dim paramName
        dim rel
        dim done
        dim changed

        changed = false
        ' Main code
        if isEnabled(paramObj) then
            set ccObj = getCCobject(paramObj)
            if isEnabled(ccObj) then
                done = false
                set values = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
                for each value in values
                    set definitions = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_AnyObject)
                    for each definition in definitions
                        if definition.uri = paramObj.uri then
                            ' There is an existing value - replace it with the new value
                            paramValue = value.getNamedStringValue(EkaValueProperty)
                            if isNumeric(paramValue) then
                                if CStr(paramValue) = CStr(newValue) then
                                    done = true
                                    exit for
                                end if
                            elseif paramValue = newValue then
                                done = true
                                exit for
                            else
                                call value.setNamedStringValue(EkaValueProperty, newValue)
                                done = true
                                changed = true
                                exit for
                            end if
                        end if
                    next
                    if done then exit for
                next
                if not done then
                    set model = metis.currentModel
                    set inst  = model.currentInstance
                    set value = ccObj.newPart(GLOBAL_Type_EkaValue)
                    set metis.currentModel = model
                    set metis.currentModel.currentInstance = inst
                    if isEnabled(value) then
                        call value.setNamedStringValue(EkaValueProperty, newValue)
                        set model = ccObj.ownerModel
                        set rel = model.newRelationship(GLOBAL_Type_EkaHasValue, ccObj, value)
                        set rel = model.newRelationship(GLOBAL_Type_EkaHasDefinition, value, paramObj)
                        changed = true
                    end if
                end if
            else
                call paramObj.setNamedStringValue(EkaValueProperty, newValue)
            end if
        end if
        setParamValue = changed
    End Function

'-----------------------------------------------------------
    Private Function getCCobject(inst)
        dim model
        dim part, parts
        dim typeUri
        dim paramObj
        dim hasValueType, hasParamType
        dim rel, rels, paramRels
        dim ccRule1

        set getCCobject = Nothing
        if inst.isRelationship then
            set inst = inst.origin
        end if
        if inst.type.uri = GLOBAL_Type_CC.uri then
            set getCCobject = inst
        elseif inst.type.uri = GLOBAL_Type_Rule.uri then
            set rels = inst.getNeighbourRelationships(1, GLOBAL_Type_subjectOf)
            if rels.count > 0 then
                set getCCobject = rels(1).origin
            else
                ' Find the relship that is the subject of the rule
                set ccRule1 = new CC_Rule
                set rel = ccRule.getSubjectOf(inst)
                set ccRule1 = Nothing
                if isEnabled(rel) then
                    set getCCobject = rel.origin
                end if
            end if
        else
            typeUri = inst.type.uri
            if typeUri = GLOBAL_Type_VP.uri or typeUri = GLOBAL_Type_VPV.uri then
                set hasValueType = GLOBAL_Type_hasVPV
                set hasParamType = GLOBAL_Type_hasVP
            elseif typeUri = GLOBAL_Type_FP.uri or typeUri = GLOBAL_Type_FPV.uri then
                set hasValueType = GLOBAL_Type_hasFPV
                set hasParamType = GLOBAL_Type_hasFP
            elseif typeUri = GLOBAL_Type_DP.uri or typeUri = GLOBAL_Type_DPV.uri then
                set hasValueType = GLOBAL_Type_hasDPV
                set hasParamType = GLOBAL_Type_hasDP
            elseif typeUri = GLOBAL_Type_CP.uri or typeUri = GLOBAL_Type_CPV.uri then
                set hasValueType = GLOBAL_Type_hasCPV
                set hasParamType = GLOBAL_Type_hasCP
            elseif typeUri = GLOBAL_Type_CPR.uri or typeUri = GLOBAL_Type_CPV.uri then
                set hasValueType = GLOBAL_Type_hasCPV
                set hasParamType = GLOBAL_Type_hasCPR
            elseif typeUri = GLOBAL_Type_PP.uri or typeUri = GLOBAL_Type_PPV.uri then
                set hasValueType = GLOBAL_Type_hasPPV
                set hasParamType = GLOBAL_Type_hasPP
            end if
            if isValid(hasValueType) then
                set paramRels = inst.getNeighbourRelationships(1, hasValueType)
                if paramRels.count > 0 then
                    set paramObj = paramRels(1).origin
                    set rels = paramObj.getNeighbourRelationships(1, hasParamType)
                    if rels.count > 0 then
                        set getCCobject = rels(1).origin
                    end if
                else
                    set rels = inst.getNeighbourRelationships(1, hasParamType)
                    if rels.count > 0 then
                        set getCCobject = rels(1).origin
                    end if
                end if
            elseif isValid(hasParamType) then
                set rels = inst.getNeighbourRelationships(1, hasParamType)
                if rels.count > 0 then
                    set getCCobject = rels(1).origin
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Sub evaluateRuleInputs(inst1)
        dim expression, expressions
        dim rel, rels
        dim ccObj
        dim paramObj, paramUri
        dim value, values
        dim definition, definitions
        dim s

        evaluateRuleInputs = true
        set inst = inst1
        if inst.type.uri = GLOBAL_Type_Rule.uri then
            set expressions = inst.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
            end if
        else
            set expression = inst
        end if
        if isEnabled(expression) then
            ' Check input parameter values
            set rels = expression.getNeighbourRelationships(1, GLOBAL_Type_inputToExpr1)
            for each rel in rels
                ' Parameter object
                set paramObj = rel.origin
                set ccObj = getCCobject(paramObj)
                if isEnabled(ccObj) then
                    set values = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
                    for each value in values
                        set definitions = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_AnyObject)
                        for each definition in definitions
                            if definition.uri = paramObj.uri then
                                ' Value found, get the value
                                s = value.getNamedStringValue(EkaValueProperty)
                                if Len(s) = 0 or s = "Undefined" then
                                    evaluateRuleInputs = false
                                end if
                            end if
                        next
                    next
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub executeRules(inst1, mode)
        dim inst
        dim ccRule1
        dim rule, rules
        dim includeInConfig
        dim included
        dim test

        ' Initialize
        set inst = inst1
        included = true
        test = 1
        call clearRuleStatus(inst)
        ' Execute rules
        set includeInConfig = metis.newValue
        set ccRule1 = new CC_Rule
        set rules = ccRule1.getRules(inst)
        if rules.count > 0 then
            call includeInConfig.setInteger(0)
        end if
        for each rule in rules
            on error resume next
'stop
            test = executeRule(inst, rule, mode)
            if test = 0 then
                included = false
                ' MsgBox "Rule execution failed: " & rule.title
            end if
        next
        if included then
            call includeInConfig.setInteger(1)
        end if
        call inst.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
        set ccRule1 = Nothing
    End Sub

'-----------------------------------------------------------
    Public Function executeRule(inst1, ruleObject, mode)
        on error resume next

        dim context
        dim model
        dim intVal
        dim prop
        dim rule, ruleEngine, ruleKind
        dim includeInConfig
        dim evaluatedTo
        dim text, text1, text2, text3
        dim expression, expressions
        dim isExpression

        ' Initialization
        set context = inst1
        executeRule = 0
        set model = ruleObject.ownerModel
        ruleKind = ruleObject.getNamedStringValue("ruleKind")
        if mode = MODE_CONFIGURE then ' Configure
            if ruleKind = "Service" then
                executeRule = 1
                exit function
            end if
        elseif mode = MODE_EXECUTE then ' Execute service
            if not ruleKind = "Service" then
                executeRule = 1
                exit function
            end if
        end if
        isExpression = false
        if ruleKind = "Expression" or ruleKind = "Service" then
            set expressions = ruleObject.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            if expressions.count > 0 then
                set expression = expressions(1)
                isExpression = true
            end if
        end if
        ' Rule execution
        set prop = ruleObject.type.getProperty(RuleEngineProperty)
        if isEnabled(prop) then
            ruleEngine = ruleObject.getNamedValue(RuleEngineProperty).getInteger
            select case ruleEngine
            case 0
                executeRule = 1
                exit function
            case 1
                set includeInConfig = metis.newValue
                if isExpression then
                    if not evaluateRuleInputs(expression) then
                    end if
                    call includeInConfig.setInteger(1)
                    call ruleObject.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
                    text = "set contextInst = ccRuleEngine.getInstanceOf(" & Chr(34) & context.uri & Chr(34) & ")" & vbCrLf
                    text1 = expression.getNamedValue(RuleInitCodeProperty).getString
                    text2 = expression.getNamedValue(RuleCodeProperty).getString
                    text3 = expression.getNamedValue(RulePostCodeProperty).getString
                    rule = text1 & text & text2 & text3
                    if Len(rule) > 0 then
                        call ruleObject.setNamedStringValue(RuleCodeProperty, rule)
                        call model.runMethodOnInst(GLOBAL_Method_RuleExecute, ruleObject)
                        executeRule = 1
                    end if
                else
                    rule = ruleObject.getNamedValue(RuleCodeProperty).getString
                    if Len(rule) > 0 then
                        text = "set contextInst = ccRuleEngine.getInstanceOf(" & Chr(34) & context.uri & Chr(34) & ")" & vbCrLf
                        rule = text & rule
                        call includeInConfig.setInteger(0)
                        call ruleObject.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
                        call model.runMethodOnInst(GLOBAL_Method_RuleExecute, ruleObject)
                        executeRule = ruleObject.getNamedValue(RuleEvaluatedToProperty).getInteger
                    else
                        call includeInConfig.setInteger(1)
                        call ruleObject.setNamedValue(RuleEvaluatedToProperty, includeInConfig)
                        executeRule = 1
                    end if
                end if
            end select
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        ' Initialize local variables
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView

        ' Modes
        MODE_CONFIGURE = 1
        MODE_EXECUTE   = 2

        ' Variables
        RuleEngineProperty      = "ruleEngine"
        RuleInitCodeProperty    = "ruleInitCode"
        RuleCodeProperty        = "ruleCode"
        RulePostCodeProperty    = "rulePostCode"
        RuleEvaluatedToProperty = "ruleEvaluatedTo"
        ExprEvaluatedToProperty = "expressionEvaluatedTo"
        CcValueProperty         = "name"
        EkaValueProperty        = "value"
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

