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
                        removed = true
                    else
                        i = i + 1
                    end if
                next
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
                            call updateViewInstance(inst, Nothing, instModel)
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
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedStringValue("name", fromProp.title)
                call toProp.setNamedStringValue("unit", fromProp.getNamedStringValue("unit"))
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
                        set tolProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                        call tolProp.setNamedStringValue("name", "Tolerance")
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, tolProp)
                    case 4
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
    Public Sub aggregateValues(aggregate, aggrType, projectObject)
        dim prop, properties
        dim param, params
        dim member, members
        dim memberProp, memberProps
        dim model
        dim ekaInst
        dim minVal0, maxVal0, nomVal0, tolVal0
        dim minVal1, maxVal1, nomVal1, tolVal1

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
        ' Connect to aggrType
        set model = aggregate.ownerModel
        set rel = model.newRelationship(GLOBAL_Type_EkaIs, aggregate, aggrType)
        ' Create new properties to store the aggregated values
        set properties = aggrType.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each prop in properties
            call copyProperties(aggrType, aggregate, projectObject, true)
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
                                if isEmpty(minVal0) then minVal0 = minVal1
                                if isEmpty(maxVal0) then maxVal0 = maxVal1
                                if minVal1 < minVal0 then minVal0 = minVal1
                                if maxVal1 > maxVal0 then maxVal0 = maxVal1
                                if tolVal1 > tolVal0 then tolVal0 = tolVal1
                            end if
                        end if
                        exit for
                    end if
                next
            next
            if not (isEmpty(minVal0) and isEmpty(maxVal0)) then
                nomVal0 = (minVal0 + maxVal0) / 2
                'tolVal0 = (maxVal0 - minVal0) / 2
                'tolVal0 = 100 * tolVal0 / nomVal0
                call ekaInst.setNumericParamValue(prop, "Minimum", minVal0)
                call ekaInst.setNumericParamValue(prop, "Maximum", maxVal0)
                call ekaInst.setNumericParamValue(prop, "Nominal", nomVal0)
                call ekaInst.setNumericParamValue(prop, "Tolerance", tolVal0)
            end if
        next
        call updateViewInstance(aggregate, Nothing, projectObject)
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
    Public Function updateViewInstance(inst, subInst, instModel)
        dim contentModel
        dim prop, props
        dim param, params
        dim vp, viewProp, viewProps
        dim unit, value, minVal, maxVal
        dim rel
        dim subInstance, subInstances

        set contentModel = inst.ownerModel
        if not isEnabled(subInst) then
            set props = inst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        else
            set props = subInst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
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
            if not isEnabled(viewProp) then
                ' Create the view property
'stop
                set viewProp = instModel.newPart(GLOBAL_Type_CCProperty)
                viewProp.title = prop.title
                set rel = contentModel.newRelationship(GLOBAL_Type_CCHasProperty, inst, viewProp)
            end if
            if isEnabled(viewProp) then
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
                                minVal = FormatNumber(minVal, 3)
                                call viewProp.setNamedStringValue("min", minVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("min", "")
                        end if
                    elseif param.title = "Maximum" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, 3)
                                call viewProp.setNamedStringValue("max", maxVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("min", "")
                        end if
                    elseif param.title = "Nominal" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, 3)
                                call viewProp.setNamedStringValue("nominal", maxVal)
                            end if
                        else
                            call viewProp.setNamedStringValue("nominal", "")
                        end if
                    elseif param.title = "Tolerance" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, 3)
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
            call updateViewInstance(inst, subInstance, instModel)
        next

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

