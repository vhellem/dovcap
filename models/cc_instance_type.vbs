option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_InstanceType

    Public Title
    Public ConfigurableComponent            ' IMetisObject
    Public productType                      ' IMetisType
    Public productInstType                  ' IMetisType
    Public typeModel                        ' IMetisModel
    Public instanceModel                    ' IMetisModel
    Public parentFamily                     ' IMetisObject
    Public parameterRule                    ' String

    ' Properties
    Private RuleEvaluatedToProperty
    Private IsSubcomponentProperty
    Private parameterNames(10)

'-----------------------------------------------------------
    Public Function findInstances(projectObject, instTypeName)
        dim instModel, instTypeModel
        dim instanceModel, instanceType
        dim inst, instances
        dim rel
        dim i, removed

        set findInstances = Nothing
        if not isEnabled(projectObject) then
            exit function
        end if
        if isValid(typeModel) then
            set instTypeModel = typeModel
        else
            set instTypeModel = findInstanceTypeModel(projectObject)
        end if
        if isValid(instanceModel) then
            set instModel = instanceModel
        else
            set instModel = findInstanceModel(projectObject, instTypeName)
        end if
        if isEnabled(instTypeModel) and isEnabled(instModel) then
            set instanceType  = findInstanceType(instTypeName, instTypeModel)
            if isEnabled(instanceType) then
                set instances = instModel.parts
                i = 1
                for each inst in instances
                    removed = false
                    if not inst.type.inherits(instanceType.type) then
                        instances.removeAt(i)
                        removed = true
                    else
                        i = i + 1
                    end if
                next
                if instances.count > 0 then set findInstances = instances
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function findInstances2(projectObject, instanceType)
        dim instModel, instTypeModel
        dim instType, instTypes
        dim inst, instances
        dim family, families
        dim rel
        dim i, removed, found

        set findInstances2 = Nothing
        if isValid(typeModel) then
            set instTypeModel = typeModel
        else
            set instTypeModel = findInstanceTypeModel(projectObject)
        end if
        if isValid(instanceModel) then
            set instModel = instanceModel
        else
            set instModel = findInstanceModel(projectObject, instTypeName)
        end if
        if isEnabled(instTypeModel) and isEnabled(instModel) then
            if isEnabled(instanceType) then
                set instances = instModel.parts
                i = 1
                for each inst in instances
                    removed = false
                    found = false
                    if inst.type.inherits(productInstType) then
                        ' Search by EkaIs
                        set instTypes = inst.getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_AnyObject)
                        for each instType in instTypes
                            if instType.uri = instanceType.uri then
                                found = true
                                exit for
                            end if
                        next
                    end if
                    if not found then
                        instances.removeAt(i)
                    else
                        i = i + 1
                    end if
                next
                if instances.count > 0 then
                    if isEnabled(parentFamily) then
                        i = 1
                        for each inst in instances
                            set families = inst.getNeighbourObjects(1, GLOBAL_Type_EkaHasPart, GLOBAL_Type_CcFamily)
                            for each family in families
                                if family.uri = parentFamily.uri then
                                    found = true
                                    exit for
                                end if
                            next
                            if not found then
                                instances.removeAt(i)
                            else
                                i = i + 1
                            end if
                        next
                    end if
                end if
                if instances.count > 0 then set findInstances2 = instances
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function newInstance(projectObject, ccObject, varObject, instanceType, instName, searchMode, createViewProperties)
        dim contentModel, instTypeModel
        dim instModel
        dim inst, viewInst
        dim reqType, dsType
        dim subCC, subCCs
        dim varObj, usedVariants
        dim symbol, symbols
        dim rel
        dim ccConfig

        set newInstance = Nothing
        if not isEnabled(projectObject) then
            exit function
        end if
        if isValid(typeModel) then
            set instTypeModel = typeModel
        else
            set instTypeModel = findInstanceTypeModel(projectObject)
        end if
        if isValid(instanceModel) then
            set instModel = instanceModel
        else
            set instModel = findInstanceModel(projectObject, instName)
        end if
        set contentModel = instModel.ownerModel   ' instTypeModel.ownerModel
        if isEnabled(instTypeModel) and isEnabled(instModel) then
            if isEnabled(instanceType) then
                set inst = findInstance(instanceType, instName)
                if isEnabled(inst) then
                    set newInstance = inst
                else
                    set ccConfig = new CC_Configure
                    set inst = instModel.newPart(productInstType)
                    if isEnabled(inst) then
                        inst.title = instName
                        if true then
                            on error resume next
                            set rel = contentModel.newRelationship(GLOBAL_Type_EkaIs, inst, instanceType)
                        end if
                        select case productType.uri
                            case GLOBAL_Type_DS.uri
                                ' searchMode = 1:    Design parameters
                                ' searchMode = 2:    Performance parameters
                                ' searchMode = 3:    Design AND performance parameters
                                call copySolutionProperties(instanceType, inst, instModel, searchMode)
                                ' Copy from sub CCs
                                set subCCs = ccConfig.getIncludedSubComponents(ccObject)
                                for each subCC in subCCs
                                    ' Find chosen variant
                                    set usedVariants = varObject.getNeighbourObjects(0, GLOBAL_Type_usesVAR2, GLOBAL_Type_VAR)
                                    for each varObj in usedVariants
                                        if varObj.url = subCC.url then
                                            call ccConfig.setVariantParameters(subCC, varObj)
                                            call ccConfig.configureVariant(subCC)
                                            set dsType = ccConfig.getDesignSolution(subCC)
                                            call copySolutionProperties(dsType, inst, instModel, searchMode)
                                            exit for
                                        end if
                                    next
                                next
                            case GLOBAL_Type_CO.uri
                                ' Copy from current CC
                                ' searchMode = 1:    Constraint (discrete) parameters
                                ' searchMode = 2:    Constraint (range) parameters
                                ' searchMode = 3:    All constraint parameters
                                call copyConstraintProperties(instanceType, inst, instModel, searchMode)
                                ' Copy from sub CCs
                                set subCCs = ccConfig.getIncludedSubComponents(ccObject)
                                for each subCC in subCCs
                                    ' Find chosen variant
                                    set usedVariants = varObject.getNeighbourObjects(0, GLOBAL_Type_usesVAR2, GLOBAL_Type_VAR)
                                    for each varObj in usedVariants
                                        if varObj.url = subCC.url then
                                            call ccConfig.setVariantParameters(subCC, varObj)
                                            call ccConfig.configureVariant(subCC)
                                            set reqType = ccConfig.getRequirementType(subCC, varObj)
                                            call copyConstraintProperties(reqType, inst, instModel, searchMode)
                                            exit for
                                        end if
                                    next
                                next
                            case else
                                call copyProperties(instanceType, inst, instModel, true)
                        end select
                        if isEnabled(parentFamily) then
                            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasPart, parentFamily, inst)
                        end if
                        set newInstance = inst
                        ' If symbol is connected to type then connect symbol to new instance
                        set symbols = instanceType.getNeighbourObjects(0, GLOBAL_Type_EkaHasSymbol, GLOBAL_Type_EkaSymbol)
                        if symbols.count > 0 then
                            set symbol = symbols(1)
                            set rel    = contentModel.newRelationship(GLOBAL_Type_EkaHasIcon, inst, symbol)
                        end if
                        if createViewProperties then
                            ' Create/update viewInstance
                            call updateViewInstance(ccObject, inst, Nothing, instModel, 1)
                        end if
                    end if
                    set ccConfig = Nothing
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Sub copyProperties(fromObj, toObj, instModel, noValues)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
        dim fromParam, fromParams
        dim toParam
        dim enumVal, enumVals
        dim enumProp
        dim constrained, constrains
        dim propExists
        dim rel

        set contentModel = fromObj.ownerModel
        set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.title = fromProp.title then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                call copyProp(fromProp, toObj, instModel, noValues)
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub copySolutionProperties(fromObj, toObj, instModel, searchMode)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
        dim propList1, propList2
        dim minProp, maxProp, enumProp
        dim constrained, constrains
        dim enumVal, enumVals
        dim propExists
        dim rel
        dim i

        set contentModel = fromObj.ownerModel
        for i = 1 to 2
          if i = 1 then
            set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasDP, GLOBAL_Type_DP)
          elseif i = 2 then
            set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasPP, GLOBAL_Type_PP)
          end if
          set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
          for each fromProp in fromProperties
            if i = 1 and searchMode = 2 then exit for
            if i = 2 and searchMode = 1 then exit for
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.name = fromProp.name then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                ' Create the property
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedValue("name", fromProp.getNamedValue("name"))
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                ' Set the unit value
                call toProp.setNamedValue("unit", fromProp.getNamedValue("unit"))
                ' Check for constrains
                set constrains = fromProp.getNeighbourObjects(1, GLOBAL_Type_constrains, GLOBAL_Type_AnyObject)
                for each constrained in constrains
                    set rel = contentModel.newRelationship(GLOBAL_Type_constrains, constrained, toProp)
                next
                ' Check for enums
                set enumVals = fromProp.getNeighbourObjects(0, GLOBAL_Type_hasDPV, GLOBAL_Type_DPV)
                for each enumVal in enumVals
                    set enumProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                    call enumProp.setNamedValue("value", enumVal.getNamedValue("value"))
                    set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasAllowedValue, toProp, enumProp)
                next
            end if
          next
        next
    End Sub

'-----------------------------------------------------------
    Private Sub copyConstraintProperties(fromObj, toObj, instModel, searchMode)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
        dim minProp, maxProp, enumProp
        dim nomProp, tolProp
        dim enumVal, enumVals
        dim propExists, min_max
        dim rel

        set contentModel = fromObj.ownerModel
        if searchMode > 1 then
          set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasCPR, GLOBAL_Type_CPR)
          set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
          for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.name = fromProp.name then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                ' Create the property
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedValue("name", fromProp.getNamedValue("name"))
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                ' Set the decimals value
                call toProp.setNamedValue("comments", fromProp.getNamedValue("decimals"))
                ' Set the unit value
                call toProp.setNamedValue("unit", fromProp.getNamedValue("unit"))
                ' Get min_max option
                min_max = fromProp.getNamedValue("min_max").getInteger
                select case min_max
                    case 0
                        set minProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call minProp.setNamedStringValue("name", "Minimum")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, minProp)
                    case 1
                        set maxProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call maxProp.setNamedStringValue("name", "Maximum")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, maxProp)
                    case 2
                        set minProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call minProp.setNamedStringValue("name", "Minimum")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, minProp)
                        set maxProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call maxProp.setNamedStringValue("name", "Maximum")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, maxProp)
                    case 3
                        set nomProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call nomProp.setNamedStringValue("name", "Nominal")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, nomProp)
                    case 4
                        set nomProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call nomProp.setNamedStringValue("name", "Nominal")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, nomProp)
                        set tolProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call tolProp.setNamedStringValue("name", "Tolerance")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, tolProp)
                    case 5
                        set minProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call minProp.setNamedStringValue("name", "Minimum")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, minProp)
                        set maxProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call maxProp.setNamedStringValue("name", "Maximum")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, maxProp)
                        set nomProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call nomProp.setNamedStringValue("name", "Nominal")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, nomProp)
                        set tolProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call tolProp.setNamedStringValue("name", "Tolerance")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, tolProp)
                end select
            end if
          next
        end if
        if searchMode <> 2 then
          set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasCP, GLOBAL_Type_CP)
          set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
          for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.name = fromProp.name then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                ' Create the property
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedValue("name", fromProp.getNamedValue("name"))
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                ' Check for enums
                set enumVals = fromProp.getNeighbourObjects(0, GLOBAL_Type_hasCPV, GLOBAL_Type_CPV)
                for each enumVal in enumVals
                    set enumProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                    call enumProp.setNamedValue("value", enumVal.getNamedValue("name"))
                    set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasAllowedValue, toProp, enumProp)
                next
            end if
          next
        end if
    End Sub

'-----------------------------------------------------------
    Private Function copyProp(fromProp, toObj, instModel, noValues)
        dim contentModel
        dim toProp
        dim rel
        dim toParam, fromParam, fromParams
        dim constrained, constrains
        dim enumVal, enumVals
        dim enumProp

        set contentModel = toObj.ownerModel
        set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
        call toProp.setNamedStringValue("name", fromProp.title)
        call toProp.setNamedStringValue("unit", fromProp.getNamedStringValue("unit"))
        call toProp.setNamedStringValue("comments", fromProp.getNamedStringValue("comments"))
        if not noValues then
            call toProp.setNamedStringValue("value", fromProp.getNamedStringValue("value"))
        end if
        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
        set fromParams = fromProp.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
        for each fromParam in fromParams
            ' Set parameter values
            set toParam = instModel.newPart(GLOBAL_Type_EkaProperty)
            call toParam.setNamedStringValue("name", fromParam.title)
            call toParam.setNamedStringValue("unit", fromParam.getNamedStringValue("unit"))
            if not noValues then
                call toParam.setNamedStringValue("value", fromParam.getNamedStringValue("value"))
            end if
            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, toParam)
        next
        ' Check for constrains
        set constrains = fromProp.getNeighbourObjects(1, GLOBAL_Type_constrains, GLOBAL_Type_AnyObject)
        for each constrained in constrains
            set rel = contentModel.newRelationship(GLOBAL_Type_constrains, constrained, toProp)
        next
        ' Check for enums
        set enumVals = fromProp.getNeighbourObjects(0, GLOBAL_Type_EkaHasAllowedValue, GLOBAL_Type_EkaProperty)
        for each enumVal in enumVals
            set enumProp = instModel.newPart(GLOBAL_Type_EkaProperty)
            call enumProp.setNamedValue("value", enumVal.getNamedValue("value"))
            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasAllowedValue, toProp, enumProp)
        next
        set copyProp = toProp
    End Function

'-----------------------------------------------------------
    Public Function calculateReqProperties(inst)
        dim instModel
        dim rel, rels
        dim reqType, instType
        dim ccRuleEngine
        dim rule, rules

        set instModel = inst.parent
        set rels = inst.getNeighbourRelationships(0, GLOBAL_Type_EkaIs)
        if rels.count > 0 then set reqType = rels(1).target
        if isValid(reqType) then
            set rels = reqType.getNeighbourRelationships(0, GLOBAL_Type_EkaIs)
            if rels.count > 0 then set instType = rels(1).target

            ' Get rules on instType
            set ccRuleEngine = new CC_RuleEngine
            set rules = instType.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
            if rules.count > 0 then
                dim ruleStatus
                for each rule in rules
                    if ccRuleEngine.isCalculatingRule(rule) then
                        dim found

                        found = false
                        set rels = currentInst.getNeighbourRelationships(0, GLOBAL_Type_invokes)
                        for each rel in rels
                            if rel.target.uri = rule.uri then
                                found = true
                                exit for
                            end if
                        next
                        if not found then
                            dim model1
                            ' Connect invokeRel from currentInst to rule
                            set model1 = currentInst.ownerModel
                            set rel = model1.newRelationship(GLOBAL_Type_invokes, currentInst, rule)
                        end if
                    end if
                next
                ruleStatus = true
                for i = 1 to 10
                    call ccRuleEngine.clearRuleStatus(currentInst)
                    for each rule in rules
                        call ccRuleEngine.executeRule(currentInst, rule, ccRuleEngine.MODE_EXECUTE)
                        ruleStatus = currentInst.getNamedValue("ruleStatus").getInteger
                    next
                    if ruleStatus = false then exit for
                next
            end if
            set ccRuleEngine = Nothing
        end if
    End Function

'-----------------------------------------------------------
    Private Sub addLackingParameters(prop)
        dim instModel, contentModel
        dim param, params
        dim newProp
        dim rel
        dim nomFound, tolFound, minFound, maxFound

        nomFound = false
        tolFound = false
        minFound = false
        maxFound = false
        set params = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
        for each param in params
            if param.title = "Nominal" then nomFound = true
            if param.title = "Tolerance" then tolFound = true
            if param.title = "Minimum" then minFound = true
            if param.title = "Maximum" then maxFound = true
        next
        set contentModel = prop.ownerModel
        set instModel = prop.parent
        if not minFound then
            set newProp = instModel.newPart(GLOBAL_Type_EkaProperty)
            call newProp.setNamedStringValue("name", "Minimum")
            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, newProp)
        end if
        if not maxFound then
            set newProp = instModel.newPart(GLOBAL_Type_EkaProperty)
            call newProp.setNamedStringValue("name", "Maximum")
            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, newProp)
        end if
        if not nomFound then
            set newProp = instModel.newPart(GLOBAL_Type_EkaProperty)
            call newProp.setNamedStringValue("name", "Nominal")
            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, newProp)
        end if
        if not tolFound then
            set newProp = instModel.newPart(GLOBAL_Type_EkaProperty)
            call newProp.setNamedStringValue("name", "Tolerance")
            set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, newProp)
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub aggregateValues(ccObj, aggregate, aggrType, projectObject)
        dim prop, properties
        dim param, params, outParams
        dim member, members
        dim memberProp, memberProps
        dim rule, rules
        dim expression, expressions
        dim model
        dim rel
        dim ekaInst
        dim minVal0, maxVal0, nomVal0, tolVal0
        dim minVal1, maxVal1, nomVal1, tolVal1
        dim i, found

        ' Clear previous values
        set properties = aggregate.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each prop in properties
            set params = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
            for each param in params
                set model = param.ownerModel
                call model.deleteObject(param)
            next
            set model = prop.ownerModel
            call model.deleteObject(prop)
        next
        ' Handle role specific parameters
        if Len(parameterRule) > 0 then
            'Find the specified parameters
            set rules = ccObj.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
            for each rule in rules
                if rule.title = parameterRule then
                    ' Find expression object
                    set expressions = rule.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
                    for each expression in expressions
                        set params = expression.getNeighbourObjects(1, GLOBAL_Type_inputToExpr1,GLOBAL_Type_CCParam)
                        set outParams = expression.getNeighbourObjects(0, GLOBAL_Type_outputFromExpr,GLOBAL_Type_CCParam)
                        for each param in outParams
                            call params.addLast(param)
                        next
                        exit for
                    next
                end if
            next
        end if
        ' Connect to aggrType
        set model = aggregate.ownerModel
        set rel = model.newRelationship(GLOBAL_Type_EkaIs, aggregate, aggrType)
        ' Build property list of aggregate properties
        set properties = aggrType.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        i = 1
        for each prop in properties
            if isValid(params) then
                found = false
                for each param in params
                    if param.title = prop.title then
                        found = true
                        exit for
                    end if
                next
                if found then
                    i = i + 1
                else
                    properties.removeAt(i)
                end if
            end if
        next
        ' Create new properties to store the aggregated values
        for each prop in properties
            dim aggrProp

            set aggrProp = copyProp(prop, aggregate, projectObject, true)
            call addLackingParameters(aggrProp)
        next
        ' Prepare aggregation
        set properties = aggregate.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        set members    = aggregate.getNeighbourObjects(0, GLOBAL_Type_EkaHasPart, GLOBAL_Type_CCObject)
        ' Do the aggregation
        set ekaInst = new EKA_Instance
        for each prop in properties
            if not ekaInst.getNumericParamValue(prop, "Minimum", minVal0) then minVal0 = Empty
            if not ekaInst.getNumericParamValue(prop, "Maximum", maxVal0) then maxVal0 = Empty
            if not ekaInst.getNumericParamValue(prop, "Nominal", nomVal0) then nomVal0 = Empty
            if not ekaInst.getNumericParamValue(prop, "Tolerance", nomVal0) then tolVal0 = Empty
            for each member in members
                set memberProps = member.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
                for each memberProp in memberProps
                    if memberProp.title = prop.title then
                        minVal1 = Empty
                        maxVal1 = Empty
                        nomVal1 = Empty
                        tolVal1 = Empty
                        ' Get the values
                        if ekaInst.getNumericParamValue(memberProp, "Minimum", minVal1) then
                            if isEmpty(minVal0) then minVal0 = minVal1
                            if minVal1 < minVal0 then minVal0 = minVal1
                        end if
                        if ekaInst.getNumericParamValue(memberProp, "Maximum", maxVal1) then
                            if isEmpty(maxVal0) then maxVal0 = maxVal1
                            if maxVal1 > maxVal0 then maxVal0 = maxVal1
                        end if
                        if ekaInst.getNumericParamValue(memberProp, "Nominal", nomVal1) then
                            tolVal1 = 0
                            minVal1 = nomVal1
                            maxVal1 = nomVal1
                            if ekaInst.getNumericParamValue(memberProp, "Tolerance", tolVal1) then
                                minVal1 = nomVal1 * (1 - tolVal1/100)
                                maxVal1 = nomVal1 * (1 + tolVal1/100)
                            end if
                        end if
                        if isEmpty(minVal0) then minVal0 = minVal1
                        if isEmpty(maxVal0) then maxVal0 = maxVal1
                        if minVal1 < minVal0 then minVal0 = minVal1
                        if maxVal1 > maxVal0 then maxVal0 = maxVal1
                        if tolVal1 > tolVal0 then tolVal0 = tolVal1
                        exit for
                    end if
                next
            next
            if not (isEmpty(minVal0) and isEmpty(maxVal0)) then
                if isEmpty(minVal0) then
                    nomVal0 = Empty
                elseif isEmpty(maxVal0) then
                    nomVal0 = Empty
                else
                    nomVal0 = (minVal0 + maxVal0) / 2
                    'tolVal0 = (maxVal0 - minVal0) / 2
                    'tolVal0 = 100 * tolVal0 / nomVal0
                end if
                call ekaInst.setNumericParamValue(prop, "Minimum", minVal0)
                call ekaInst.setNumericParamValue(prop, "Maximum", maxVal0)
                call ekaInst.setNumericParamValue(prop, "Nominal", nomVal0)
                call ekaInst.setNumericParamValue(prop, "Tolerance", Empty)
            end if
        next
        call updateViewInstance(ccObj, aggregate, Nothing, projectObject, 1)
    End Sub

'-----------------------------------------------------------
    Private Sub aggregateNumericPropertyValue(aggrProp, memberProp)
        dim i

        set ekaInst = new EKA_Instance
        for i = 1 to 4
            sval0 = ekaInst.getParameterValue(aggrProp, parameterNames(i))
            sval1 = ekaInst.getParameterValue(memberProp, parameterNames(i))
            if isNumeric(sval0) then numVal0 = CDbl(sval0)
            if isNumeric(sval1) then numVal1 = CDbl(sval1)
            numVal0 = numVal0 + numVal1
            call ekaInst.setParameterValue(memberProp, parameterNames(i), CStr(numVal0))
        next

    End Sub

'-----------------------------------------------------------
    Public Function updateViewInstance(ccObject, inst, subInst, instModel, delOption)
        dim contentModel
        dim prop, props
        dim param, params, outParams
        dim vp, viewProp, viewProps
        dim unit, value, minVal, maxVal
        dim rel
        dim subInstance, subInstances
        dim rule, rules
        dim expression, expressions
        dim found, refresh

        if parameterRule = "Refresh" then refresh = true
        set contentModel = inst.ownerModel
        if not isEnabled(subInst) then
            set props = inst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        else
            set props = subInst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        end if

        if not refresh and Len(parameterRule) > 0 then
            'Find the role specific parameters
            set rules = ccObject.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
            for each rule in rules
                if rule.title = parameterRule then
                    ' Find expression object
                    set expressions = rule.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
                    for each expression in expressions
                        set params = expression.getNeighbourObjects(1, GLOBAL_Type_inputToExpr1,GLOBAL_Type_CCParam)
                        set outParams = expression.getNeighbourObjects(0, GLOBAL_Type_outputFromExpr,GLOBAL_Type_CCParam)
                        for each param in outParams
                            call params.addLast(param)
                        next
                        exit for
                    next
                end if
            next
        end if

        i = 1
        for each prop in props
            if isValid(params) then
                found = false
                for each param in params
                    if param.title = prop.title then
                        found = true
                        exit for
                    end if
                next
                if found then
                    i = i + 1
                else
                    props.removeAt(i)
                end if
            end if
        next

        if delOption > 0 then
            ' Remove old ViewProperties
            set viewProps = inst.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
            for each viewProp in viewProps
                call contentModel.deleteObject(viewProp)
            next
        end if

        for each prop in props
            ' Find ViewProperty if it exists
            set viewProp = Nothing
            set viewProps = inst.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
            for each vp in viewProps
                if vp.title = prop.title then
                    set viewProp = vp
                    exit for
                end if
            next
            if not refresh and not isEnabled(viewProp) then
                ' Create ViewProperty
                set viewProp = instModel.newPart(GLOBAL_Type_CCProperty)
                viewProp.title = prop.title
                set rel = contentModel.newRelationship(GLOBAL_Type_CCHasProperty, inst, viewProp)
            end if
'stop

            if isEnabled(viewProp) then
                dim decimals

                ' Set decimals
                decimals = getDecimals(prop)
                if Len(decimals) = 0 then decimals = 3
                ' Set unit
                unit = prop.getNamedStringValue("unit")
                if Len(unit) > 0 then call viewProp.setNamedStringValue("unit", unit)
                ' Set value
                value = prop.getNamedStringValue("value")
                if Len(value) > 0 then call viewProp.setNamedStringValue("min", value)
                ' Set min and max values
                set params = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
                for each param in params
                    if param.title = "Minimum" then
                        minVal = param.getNamedStringValue("value")
                        if Len(minVal) > 0 then
                            if isNumeric(minVal) then
                                minVal = FormatNumber(minVal, decimals)
                                call viewProp.setNamedStringValue("min", minVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("min", "")
                        end if
                    elseif param.title = "Maximum" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, decimals)
                                call viewProp.setNamedStringValue("max", maxVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("max", "")
                        end if
                    elseif param.title = "Nominal" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, decimals)
                                call viewProp.setNamedStringValue("nominal", maxVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("nominal", "")
                        end if
                    elseif param.title = "Tolerance" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, 0)
                                call viewProp.setNamedStringValue("tolerance", maxVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("tolerance", "")
                        end if
                    end if
                next
            end if
        next
        ' Handle subInstances
        set subInstances = inst.getNeighbourObjects(0, GLOBAL_Type_EkaHasMember, inst.type)
        for each subInstance in subInstances
            call updateViewInstance(inst, subInstance, instModel, delOption)
        next

    End Function

'-----------------------------------------------------------
    Private Function getDecimals(prop)
        dim decimals

        getDecimals = 3
        decimals = prop.getNamedStringValue("comments")
        if Len(decimals) > 0 then
            if isNumeric(decimals) then
                getDecimals = CInt(decimals)
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function findInstance(instType, instName)
        dim inst, instances

        set findInstance = Nothing
        if isEnabled(instType) then
            set instances = instType.getNeighbourObjects(1, GLOBAL_Type_EkaIs, productType)
            for each inst in instances
                if inst.title = instName then
                    set findInstance = inst
                    exit for
                end if
            next
        end if

    End Function

'-----------------------------------------------------------
    Public Function findInstanceType(instTypeName, instTypeModel)
        dim instanceTypeName
        dim part, parts

        set findInstanceType = Nothing
        if isEnabled(instTypeModel) then
            'Find type definition
            set parts = instTypeModel.parts
            for each part in parts
                if part.type.inherits(productType) then
                    if part.title = instTypeName then
                        ' Type definition is found
                        set findInstanceType = part
                        exit for
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function findInstanceModel(projectObject, instTypeName)
        dim spaceObj
        dim modelObj, models
        dim instanceTypeName

        set findInstanceModel = Nothing

        if isEnabled(projectObject) then
            instanceTypeName = projectObject.title & ":" & instTypeName
            set spaceObj = findInstanceTypeModel(projectObject)
            if isEnabled(spaceObj) then
                ' Component type model was found
                ' Try to find corresponding instance type model
                set models = spaceObj.parts
                for each modelObj in models
                    if modelObj.title = instanceTypeName then
                        ' Instance type model exists
                        set findInstanceModel = modelObj
                        exit function
                    end if
                next
                ' Instance type model does not exist, create a new one
                set modelObj = spaceObj.newPart(GLOBAL_Type_EkaSpace)
                modelObj.title = instanceTypeName
                set findInstanceModel = modelObj
                exit function
            end if
        end if

    End Function

'-----------------------------------------------------------
    Public Function findInstanceTypeModel(projectObject)
        dim contentModel
        dim spaceObj, spaces

        set findInstanceTypeModel = Nothing
        if isEnabled(projectObject) then
            set contentModel = projectObject.ownerModel
            set spaces = contentModel.parts
            ' Find component type model
            for each spaceObj in spaces
                if spaceObj.type.uri = GLOBAL_Type_EkaSpace.uri then
                    if spaceObj.title = projectObject.title then
                        set findInstanceTypeModel = spaceObj
                        exit function
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        set ccGlobals = Nothing
        parameterRule = ""
        ' Initialize local variables
        set productType      = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        set productInstType  = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        ' Properties
        RuleEvaluatedToProperty = "ruleEvaluatedTo"
        IsSubcomponentProperty  = "isSubcomponent"
        
        parameterNames(1) = "value"
        parameterNames(2) = "Minimum"
        parameterNames(3) = "Maximum"
        parameterNames(4) = "Nominal"
        parameterNames(5) = "Tolerance"

    End Sub

End Class

