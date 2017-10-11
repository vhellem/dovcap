option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_Configure

    ' Types
    Public productType

    ' Modes
    Public MODE_REQUIREMENT_TYPE
    Public MODE_SPECIFICATION_TYPE
    Public MODE_PART_TYPE

    ' Properties
    Private RuleEvaluatedToProperty

    ' Class references
    Private ccRule
    Private ccRuleEngine

'-----------------------------------------------------------
'   Variant parameter code
'-----------------------------------------------------------
    Public Sub setVariantParameters(ccObject, variantObject)
        dim parentObj
        dim value, values
        dim rel, rels
        dim param, hasParam
        dim val1, vals
        dim obj, objects
        dim newValue
        dim found

        ' Find the used parameters
        set parentObj = ccObject.parent
        set values = variantObject.getNeighbourObjects(0, GLOBAL_Type_inclPV, GLOBAL_Type_CCValue)
        for each value in values
            ' Find the corresponding parameter
            set rels = value.neighbourRelationships
            for each rel in rels
                if rel.target.uri = value.uri then
                    if rel.origin.type.inherits(GLOBAL_Type_CCParam) then
                        set param = rel.origin
                        set hasParam = rel
                        exit for
                    end if
                end if
            next
            if isEnabled(param) then
                set vals = param.getNeighbourObjects(1, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_EkaValue)
                for each val1 in vals
                    found = false
                    set objects = val1.getNeighbourObjects(1, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaElement)
                    for each obj in objects
                        if obj.uri = ccObject.uri then
                            found = true
                            ' An old value exists, modify it
                            call val1.setNamedValue("value", value.getNamedValue("name"))
                            exit for
                        end if
                    next
                    if not found then
                        ' Create a new value
                        set newValue = parentObj.newPart(GLOBAL_Type_EkaValue)
                        newValue.title = param.title
                        call newValue.setNamedStringValue("value", value.getNamedStringValue("name"))
                        set rel = newValue.ownerModel.newRelationship(GLOBAL_Type_EkaHasValue, ccObject, newValue)
                    end if
                next
                if vals.count = 0 then
                    ' Create a new value
                    set newValue = parentObj.newPart(GLOBAL_Type_EkaValue)
                    newValue.title = param.title
                    call newValue.setNamedStringValue("value", value.getNamedStringValue("name"))
                    set rel = newValue.ownerModel.newRelationship(GLOBAL_Type_EkaHasValue, ccObject, newValue)
                    set rel = newValue.ownerModel.newRelationship(GLOBAL_Type_EkaHasDefinition, newValue, param)
                end if
            end if
        next
    End Sub

'-----------------------------------------------------------
'   Configuration code
'-----------------------------------------------------------
    Public Sub startConfigureCC(ccObject, variantName, projectObject)
        dim modelObj, modelObject
        dim dsObjects
        dim product, products
        dim part, parts, ccPart
        dim partType

        if not isEnabled(ccObject) then
            exit sub
        end if
        if not isEnabled(projectObject) then
            exit sub
        end if
        if isObject(productType) then
            if isValid(productType) then
                set partType = productType
            end if
        end if
        ' Do the configuration
        call configureFunctionMeans(ccObject)
        call configureDesignSolution(ccObject)
        call configureComposition(ccObject, false)

        ' Get name of configured variant
        if Len(variantName) = 0 then
            set dsObjects = findDesignSolutions(ccObject, true)
            if dsObjects.count = 1 then variantName = dsObjects(1).title
            if Len(variantName) = 0 then variantName = ccObject.title
        end if

        ' Build the part structure
        if not isEnabled(partType) then
            set partType = getMetisInstanceType(MODE_PART_TYPE)
        end if
        ' Find and delete part if it already exists
        set parts = projectObject.parts
        for each part in parts
            if part.type.inherits(partType) then
                if part.title = variantName then
                    ' Delete old structure
                    call deletePartStructure(part, partType)
                    exit for
                end if
            end if
        next
        set ccPart = projectObject.newPart(partType)
        ccPart.title = variantName
        call createPartStructure(projectObject, partType, ccPart, ccObject, true)
    End Sub

'-----------------------------------------------------------
    Public Sub configureCC(projectObject, ccPart, obj1, recursive)
        dim ccObj, obj
        dim partType

        set ccObj = obj1
        if isObject(productType) then
            if isValid(productType) then
                set partType = productType
            end if
        end if
        if not isEnabled(partType) then
            set partType = getMetisInstanceType(MODE_PART_TYPE)
        end if
        call configureFunctionMeans(ccObj)
        call configureDesignSolution(ccObj)
        call configureComposition(ccObj, false)
        call createPartStructure(projectObject, partType, ccPart, ccObj, recursive)
    End Sub

'-----------------------------------------------------------
    Public Sub configureVariant(obj1)
        dim ccObj, obj

        set ccObj = obj1
        call configureFunctionMeans(ccObj)
        call configureDesignSolution(ccObj)
        call configureComposition(ccObj, false)
    End Sub

'-----------------------------------------------------------
    Public Sub configureVariant2(obj1)
        dim model
        dim ccObj, ccObjects
        dim varObject, obj
        dim varObj, usedVariants
        dim rel, rels

        set varObject = obj1
        set usedVariants = varObject.getNeighbourObjects(0, GLOBAL_Type_usesVAR2, GLOBAL_Type_VAR)
        for each varObj in usedVariants
            set ccObjects = varObj.getNeighbourObjects(1, GLOBAL_Type_hasVAR, GLOBAL_Type_CCObject)
            if ccObjects.count > 0 then
                set ccObj = ccObjects(1)
                set rels = ccObj.getNeighbourRelationships(0, GLOBAL_Type_usesVAR)
                if rels.count > 0 then
                    set rel = rels(1)
                    set rel.target = varObj
                else
                    set model = ccObj.ownerModel
                    set rel = model.newRelationship(GLOBAL_Type_usesVAR, ccObj, varObj)
                end if
                call setVariantParameters(ccObj, varObj)
                call configureVariant(ccObj)
            end if
        next

    End Sub

'-----------------------------------------------------------
    Public Sub configureRequirementTypes(projectObject, obj1)
        dim ccObj, obj

        set ccObj = obj1
        call configureFunctionMeans(ccObj)
        call buildRequirementTypes(ccObj, projectObject)
    End Sub

'-----------------------------------------------------------
    Public Function configureSpecificationTypes(projectObject, obj1)
        dim ccObj
        dim typeMode

        set ccObj = obj1
        typeMode = MODE_SPECIFICATION_TYPE
        set configureSpecificationTypes = buildInstanceTypes(ccObj, projectObject, typeMode)
    End Function

'-----------------------------------------------------------
    Public Function buildPartTypes(obj1, projectObject)
        dim ccObj
        dim typeMode

        set ccObj = obj1
        typeMode = MODE_PART_TYPE
        set buildPartTypes = buildInstanceTypes(ccObj, projectObject, typeMode)
    End Function

'-----------------------------------------------------------
    Private Function includedInConfig(inst)
        dim ival

        on error resume next
        includedInConfig = true
        if not isEnabled(inst) then
            includedInConfig = false
        end if
        ival = inst.getNamedValue(RuleEvaluatedToProperty).getInteger
        if not isEmpty(ival) then
            if ival = 0 then
                includedInConfig = false
            end if
        end if

    End Function

'-----------------------------------------------------------
'-----------------------------------------------------------
    Public Function getDesignSolutions(obj1)
        dim ccObj

        set ccObj = obj1
        ' Find DS
        set getDesignSolutions = findDesignSolutions(ccObj, true)
    End Function

'-----------------------------------------------------------
    Public Sub configureDesignSolution(obj1) ' Configures within one CC
        dim ccObj, dsObj, objects
        dim rels

        set ccObj = obj1
        ' Find DS
        set objects = findDesignSolutions(ccObj, true)
        for each dsObj in objects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                ' Configure DS
                call configureInstance(dsObj, ccRuleEngine.MODE_CONFIGURE)
            end if
        next
    End Sub

'-----------------------------------------------------------
'-----------------------------------------------------------
    Public Sub configureFunctionMeans(obj1) ' Configures within one CC
        dim ccObj, obj, objects
        dim rels

        set ccObj = obj1
        ' Find top FR's
        set objects = ccObj.getNeighbourObjects(0, GLOBAL_Type_explains, GLOBAL_Type_FR)
        for each obj in objects
            if isEnabled(obj) then
                ' Check if the FR is required by a DS, if so this is not top
                set rels = obj.getNeighbourRelationships(1, GLOBAL_Type_requires)
                if rels.count = 0 then
                    ' Top FR
                    call configureFrDsC(obj)
                end if
            end if
        next
        ' Find top C's
        set objects = ccObj.getNeighbourObjects(0, GLOBAL_Type_explains, GLOBAL_Type_CO)
        for each obj in objects
            if isEnabled(obj) then
                call configureInstance(obj, ccRuleEngine.MODE_CONFIGURE)
            end if
        next
    End Sub

    Public Sub configureFrDsC(obj1)
        dim frObj
        dim obj, objects
        dim rel, rel2, rels, relships
        dim dsObj

        ' FR
        set frObj = obj1
        if isEnabled(frObj) then
            ' Configure FR
            call configureInstance(frObj, ccRuleEngine.MODE_CONFIGURE)
            ' Then look for DSs
            set relships = frObj.getNeighbourRelationships(0, GLOBAL_Type_solves)
            for each rel in relships
                 if isEnabled(rel) then
                    ' FR is solved by DS
                    call configureInstance(rel, ccRuleEngine.MODE_CONFIGURE)
                end if
            next
            ' Configure DS and C
            for each rel in relships
                 if isEnabled(rel) then
                    ' DS is found
                    set dsObj = rel.target
                    if isEnabled(dsObj) then
                        ' Find C
                        set objects = dsObj.getNeighbourObjects(0, GLOBAL_Type_constrainedBy, GLOBAL_Type_CO)
                        for each obj in objects
                            ' DS is constrained by C
                            if isEnabled(obj) then
                                ' Configure C
                                call configureInstance(obj, ccRuleEngine.MODE_CONFIGURE)
                            end if
                        next
                        ' Configure DS
                        call configureInstance(dsObj, ccRuleEngine.MODE_CONFIGURE)
                    end if
                end if
            next
            ' Check for next levels of FrDsC
            for each rel in relships
                 if isEnabled(rel) then
                    ' DS is found
                    set dsObj = rel.target
                    if isEnabled(dsObj) then
                        set rels = dsObj.getNeighbourRelationships(0, GLOBAL_Type_requires)
                        for each rel2 in rels
                            if isEnabled(rel2) then
                                call configureInstance(rel2, ccRuleEngine.MODE_CONFIGURE)
                            end if
                        next
                        for each rel2 in rels
                            if isEnabled(rel2) then
                                call configureFrDsC(rel2.target)
                            end if
                        next
                    end if
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
'-----------------------------------------------------------
    Public Sub configureComposition(obj1, recursive)
        dim ccObj
        dim rel, rels

        set ccObj = obj1
        call ccRule.transformRulesToScripts(ccObj)
        call ccRuleEngine.executeRules(ccObj, ccRuleEngine.MODE_CONFIGURE)
        set rels = ccObj.getNeighbourRelationships(0, GLOBAL_Type_hasCS)
        for each rel in rels
            call configureCS(rel, recursive)
        next
    End Sub

    Private Sub configureCS(rel1, recursive)
        dim obj
        dim relship
        dim rel, rels

        set relship = rel1
        call ccRule.transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, ccRuleEngine.MODE_CONFIGURE)
        set obj = relship.target
        call ccRule.transformRulesToScripts(obj)
        call ccRuleEngine.executeRules(obj, ccRuleEngine.MODE_CONFIGURE)
        set rels = obj.getNeighbourRelationships(0, GLOBAL_Type_hasCE)
        for each rel in rels
            call configureCE(rel, recursive)
        next
    End Sub

    Private Sub configureCE(rel1, recursive)
        dim obj
        dim relship
        dim rel, rels

        set relship = rel1
        call ccRule.transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, ccRuleEngine.MODE_CONFIGURE)
        set obj = relship.target
        call ccRule.transformRulesToScripts(obj)
        call ccRuleEngine.executeRules(obj, ccRuleEngine.MODE_CONFIGURE)
        set rels = obj.getNeighbourRelationships(0, GLOBAL_Type_hasCR)
        for each rel in rels
            call configureCR(rel, recursive)
        next
    End Sub

    Private Sub configureCR(rel1, recursive)
        dim obj
        dim relship
        dim rel, rels

        set relship = rel1
        call ccRule.transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, ccRuleEngine.MODE_CONFIGURE)
        set obj = relship.target
        call ccRule.transformRulesToScripts(obj)
        call ccRuleEngine.executeRules(obj, ccRuleEngine.MODE_CONFIGURE)
        set rels = obj.getNeighbourRelationships(0, GLOBAL_Type_usesCC)
        for each rel in rels
            call configureConfComp(rel, recursive)
        next
    End Sub

    Private Sub configureConfComp(rel1, recursive)
        dim ccObj1
        dim relship

        set relship = rel1
        call ccRule.transformRulesToScripts(relship)
        call ccRuleEngine.executeRules(relship, ccRuleEngine.MODE_CONFIGURE)
        if (recursive) then
            set ccObj1 = relship.target
            call configureComposition(ccObj1, recursive)
        end if
    End Sub

'-----------------------------------------------------------
    Private Sub configureInstance(inst1, mode)
        dim inst

        set inst = inst1
        call ccRule.transformRulesToScripts(inst)
        call ccRuleEngine.executeRules(inst, mode)
    End Sub

'-----------------------------------------------------------
'   Find instance types
'-----------------------------------------------------------
    Public Function getInstanceTypes(obj1, typeMode)
        dim ccObj
        dim obj, objs, objects
        dim pObj, dsObj
        dim mType
        dim instList

        set ccObj = obj1
        set getInstanceTypes = Nothing
        if not isEnabled(ccObj) then
            exit function
        end if
        set instList = metis.newInstanceList
        set objects = findDesignSolutions(ccObj, true)
        for each dsObj in objects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                ' Then look for the Definition type
                set mType = getMetisInstanceType(typeMode)
                set objs = dsObj.getNeighbourObjects(1, GLOBAL_Type_hasDef, mType)
                if objs.count = 0 then
                    ' No product types found found
                else
                    for each pObj in objs
                        if isEnabled(pObj) and includedInConfig(pObj) then
                            call instList.addLast(pObj)
                        end if
                    next
                end if
            end if
        next
        set getInstanceTypes = instList
    End Function

'-----------------------------------------------------------
    Public Function getRequirementTypes(obj1)
        dim ccObj
        dim obj, objs, objects
        dim cObj, dsObj
        dim instList

        set ccObj = obj1
        set getRequirementTypes = Nothing
        if not isEnabled(ccObj) then
            exit function
        end if
        set instList = metis.newInstanceList
        set objects = findDesignSolutions(ccObj, true)
        for each dsObj in objects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                ' Then look for the Constraints (non-functional requirements)
                set objs = dsObj.getNeighbourObjects(0, GLOBAL_Type_constrainedBy, GLOBAL_Type_CO)
                if objs.count = 0 then
                    ' No constraints found
                else
                    for each cObj in objs
                        if isEnabled(cObj) and includedInConfig(cObj) then
                            call instList.addLast(cObj)
                        end if
                    next
                end if
            end if
        next
        set getRequirementTypes = instList
    End Function

'-----------------------------------------------------------
'   Build instance types
'-----------------------------------------------------------
    Public Function buildRequirementTypes(obj1, projectObject)
        dim ccObj
        dim obj, objs, objects
        dim cObj, dsObj
        dim typeMode
        dim typName
        dim instList
        dim reqType

        set ccObj = obj1
        set buildRequirementTypes = Nothing
        if not isEnabled(ccObj) then
            exit function
        end if
        if not isEnabled(projectObject) then
            exit function
        end if
        set instList = metis.newInstanceList
        ' Find the non-functional requirements that applies to the CC
        ' First find the DS's
        set objects = findDesignSolutions(ccObj, true)
        for each dsObj in objects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                ' Then look for the Constraints (non-functional requirements)
                set objs = dsObj.getNeighbourObjects(0, GLOBAL_Type_constrainedBy, GLOBAL_Type_CO)
                if objs.count = 0 then
                    ' No constraints found
                else
                    typeMode = MODE_REQUIREMENT_TYPE
                    for each cObj in objs
                        if isEnabled(cObj) and includedInConfig(cObj) then
                            typName = "Requirements"
                            'typName = InputBox("Enter requirement type name", "Input dialog", typName)
                            set reqType = buildType(projectObject, typName, cObj, typeMode)
                            call instList.addLast(reqType)
                        end if
                    next
                end if
            end if
        next
        if instList.count > 0 then
            set buildRequirementTypes = instList
        end if
        set instList = Nothing
    End Function

'-----------------------------------------------------------
    Public Function buildInstanceTypes(obj1, projectObject, typeMode)
        dim ccObj
        dim dsObj, dsObjects
        dim typeModel, typName
        dim instType
        dim instList

        set ccObj = obj1
        set buildInstanceTypes = Nothing
        if not isEnabled(ccObj) then
            exit function
        end if
        if not isEnabled(projectObject) then
            exit function
        end if
        set instList = metis.newInstanceList
        ' Find the relevant Design solutions
        set dsObjects = findDesignSolutions(ccObj, true)
        for each dsObj in dsObjects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                typName = dsObj.title
                'typName = InputBox("Enter type name", "Input dialog", typName)
                set instType = buildType(projectObject, typName, dsObj, typeMode)
                call instList.addLast(instType)
            end if
        next
        if instList.count > 0 then
            set buildInstanceTypes = instList
        end if
        set instList = Nothing
    End Function

'-----------------------------------------------------------
    Private Function buildType(projectObject, tName, obj1, typeMode)
        dim model
        dim mType
        dim ccType, ccObj
        dim part, parts
        dim defRel, partRel

        set ccObj = obj1
        set mType = getMetisInstanceType(typeMode)
        ' Find out if type already exists
        set parts = projectObject.parts
        for each part in parts
            if part.type.inherits(mType) then
                if part.title = tName then
                    set ccType = part
                    exit for
                end if
            end if
        next
        if not isEnabled(ccType) then
            ' Create the type
            set ccType = projectObject.newPart(mType)
            if Len(tName) > 0 then
                ccType.title = tName
            else
                ccType.title = ccObj.title
            end if
            ' Relate type to its parent
            set model = ccType.ownerModel
            set partRel = model.newRelationship(GLOBAL_Type_EkaHasPart, projectObject, ccType)
            ' Relate type to its definition
            set defRel = model.newRelationship(GLOBAL_Type_hasDef, ccType, ccObj)

        end if
        ' Then build the property structure
        call createTypeProperties(projectObject, ccType, ccObj, typeMode)
        set buildType = ccType

    End Function

'-----------------------------------------------------------
    Private Function getMetisInstanceType(typeMode)

        set getMetisInstanceType = Nothing
        select case typeMode
            case MODE_REQUIREMENT_TYPE       set getMetisInstanceType = GLOBAL_Type_Requirement
            case MODE_SPECIFICATION_TYPE     set getMetisInstanceType = GLOBAL_Type_Specification
            case MODE_PART_TYPE              set getMetisInstanceType = GLOBAL_Type_Part
        end select
    End Function

'-----------------------------------------------------------
    Private Sub createTypeProperties(projectObject, ccType, obj1, typeMode)
        dim model
        dim ccObj
        dim valueObj, valueObjects
        dim paramObj, paramObjects
        dim pObj, paramObjects2
        dim defObj, defObjects
        dim propObjects
        dim propValue, propUnit
        dim prop, rel
        dim hasParameterType1, hasParameterType2
        dim parameterType1, parameterType2
        dim propFound, paramFound
        dim minMax
        dim hasRange, hasRange1, hasRange2

        set ccObj = obj1
        if not (isEnabled(projectObject) and isEnabled(ccType) and isEnabled(ccObj)) then
            exit sub
        end if
        set model = projectObject.ownerModel
        hasRange  = false
        hasRange1 = false
        hasRange2 = false
        select case typeMode
            case Mode_Requirement_Type
                set hasParameterType1 = GLOBAL_Type_hasCP
                set parameterType1 = GLOBAL_Type_CP
                set hasParameterType2 = GLOBAL_Type_hasCPR
                set parameterType2 = GLOBAL_Type_CPR
                hasRange = true
            case Mode_Specification_Type
                set hasParameterType1 = GLOBAL_Type_hasDP
                set parameterType1 = GLOBAL_Type_DP
                set hasParameterType2 = GLOBAL_Type_hasPP
                set parameterType2 = GLOBAL_Type_PP
            case Mode_Part_Type
                set hasParameterType1 = GLOBAL_Type_hasDP
                set parameterType1 = GLOBAL_Type_DP
                set hasParameterType2 = GLOBAL_Type_hasPP
                set parameterType2 = GLOBAL_Type_PP
        end select

        ' Find properties if they already exists
        set propObjects = ccType.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        ' Find parameters
        set paramObjects  = ccObj.getNeighbourObjects(0, hasParameterType1, parameterType1)
        set paramObjects2 = ccObj.getNeighbourObjects(0, hasParameterType2, parameterType2)
        for each pObj in paramObjects2
            if isEnabled(pObj) then
                paramObjects.addLast pObj
            end if
        next
        set valueObjects = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
        for each paramObj in paramObjects
            ' The parameter
            propValue = ""
            propUnit = ""
            minMax = ""
            hasRange2 = false
            if Len(propUnit) = 0 then
                on error resume next
                propUnit = paramObj.getNamedStringValue("unit")
            end if
            if Len(minMax) = 0 and hasRange then
                on error resume next
                minMax = paramObj.getNamedStringValue("min_max")
                if minMax = "Min and Max" then
                    hasRange2 = true
                end if
            end if
            for each valueObj in valueObjects
                set defObjects = valueObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_CCParam)
                for each defObj in defObjects
                    if defObj.title = paramObj.title then
                        ' Parameter has been given a value
                        propValue = valueObj.getNamedStringValue("value")
                        exit for
                    end if
                next
            next
            ' For each parameter create a property, if it does not already exist
            propFound = false
            for each prop in propObjects
                if prop.title = paramObj.title then propFound = true
            next
            if not propFound then
                set prop = projectObject.newPart(GLOBAL_Type_EkaProperty)
                prop.title = paramObj.title
                set rel = model.newRelationship(GLOBAL_Type_EkaHasProperty, ccType, prop)
            end if
            ' Set the value, if given
            if Len(propValue) > 0 then
                call prop.setNamedStringValue("value", propValue)
            end if
            if Len(propUnit) > 0 then
                call prop.setNamedStringValue("unit", propUnit)
            end if
            if paramObj.type.inherits(parameterType1) and hasRange1 then
                call addRange(projectObject, prop)
            elseif paramObj.type.inherits(parameterType2) and hasRange2 then
                call addRange(projectObject, prop)
            end if
        next
        ' Delete old properties that are not being used anymore
        set propObjects = ccType.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each prop in propObjects
            paramFound = false
            for each paramObj in paramObjects
                if prop.title = paramObj.title then
                    paramFound = true
                    exit for
                end if
            next
            if not paramFound then
                call model.deleteObject(prop)
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Function addRange(projectObject, prop)
        dim values
        dim value
        dim rel
        dim propUnit

        propUnit = prop.getNamedStringValue("unit")
        set values = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
        if values.count = 0 then
            set value = projectObject.newPart(GLOBAL_Type_EkaProperty)
            value.title = "Minimum"
            set rel = projectObject.ownerModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, value)
            set value = projectObject.newPart(GLOBAL_Type_EkaProperty)
            value.title = "Maximum"
            set rel = projectObject.ownerModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, value)
        else
            for each value in values
                if value.title = "Minimum" then
                    minFound = true
                elseif value.title = "Maximum" then
                    maxFound = true
                end if
            next
            if not minFound then
                set value = projectObject.newPart(GLOBAL_Type_EkaProperty)
                value.title = "Minimum"
                call prop.setNamedStringValue("unit", propUnit)
                set rel = projectObject.ownerModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, value)
            end if
            if not maxFound then
                set value = projectObject.newPart(GLOBAL_Type_EkaProperty)
                value.title = "Maximum"
                call prop.setNamedStringValue("unit", propUnit)
                set rel = projectObject.ownerModel.newRelationship(GLOBAL_Type_EkaHasParameter, prop, value)
            end if
        end if
    End Function

'-----------------------------------------------------------
'   Build part structure
'-----------------------------------------------------------
    Private Sub createPartStructure(projectObject, partType, ccPart, obj1, recursive)
        dim projectModel
        dim ccObj, csObj, ceObj, crObj
        dim csRels, ceRels, crRels, ccRels
        dim csRel, ceRel, crRel, ccRel
        dim part, obj, objects
        dim symbol, symbols
        dim rel

        set ccObj = obj1
        set projectModel = metis.load(projectObject.url)

        ' The product has already been created
        ' Check for symbol, connect as icon if there is one
        set symbols = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasSymbol, GLOBAL_Type_EkaSymbol)
        if symbols.count > 0 then
            set symbol = symbols(1)
            set rel    = projectModel.newRelationship(GLOBAL_Type_EkaHasIcon, ccPart, symbol)
        end if

        ' Find and create properties
        call createPartProperties(projectObject, ccPart, ccObj)
        ' Product corresponding to the CC has been created, including its properties
        ' Continue with structure?
        if not recursive then
            exit sub
        end if

        ' Create part structure
        set csRels = obj1.getNeighbourRelationships(0, GLOBAL_Type_hasCS)
        for each csRel in csRels
            if includedInConfig(csRel) then
                set csObj = csRel.target
                set ceRels = csObj.getNeighbourRelationships(0, GLOBAL_Type_hasCE)
                for each ceRel in ceRels
                    if includedInConfig(ceRel) then
                        set ceObj = ceRel.target
                        if includedInConfig(ceObj) then
                            ' CE found - create and connect the new part
                            set part   = projectObject.newPart(partType)
                            if isEnabled(part) then
                                part.title = ceObj.title
                                set rel    = projectModel.newRelationship(GLOBAL_Type_EkaHasMember, ccPart, part)
                                set crRels = ceObj.getNeighbourRelationships(0, GLOBAL_Type_hasCR)
                                for each crRel in crRels
                                    if includedInConfig(crRel) then
                                        set crObj = crRel.target
                                        set ccRels = crObj.getNeighbourRelationships(0, GLOBAL_Type_usesCC)
                                        for each ccRel in ccRels
                                            if includedInConfig(ccRel) then
                                                set obj = ccRel.target
                                                call configureCC(projectObject, part, obj, true)
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
    Private Sub createPartProperties(projectObject, ccPart, obj1)
        dim model
        dim ccObj
        dim dsObj, dsObjects

        set ccObj = obj1
        set model = projectObject.ownerModel
        ' Find DSs
        set dsObjects = findDesignSolutions(ccObj, true)
        for each dsObj in dsObjects
            if isEnabled(dsObj) then
                ' Check if DS is included in configuration
                if includedInConfig(dsObj) then
                    call createPartProps(dsObj, model, projectObject, ccPart)
                else
                    ' What do we do if DS is not part of the configuration??
                end if
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub createPartProps(obj1, model, projectObject, ccPart)
        dim pObj
        dim valueObj, valueObjects
        dim paramObj, paramObjects
        dim defObj, defObjects
        dim ppObj, ppObjects
        dim propValue, propUnit
        dim prop, rel

        set pObj = obj1
        ' Find parameters
        set paramObjects = pObj.getNeighbourObjects(0, GLOBAL_Type_hasDP, GLOBAL_Type_DP)
        set ppObjects    = pObj.getNeighbourObjects(0, GLOBAL_Type_hasPP, GLOBAL_Type_PP)
        for each ppObj in ppObjects
            if isEnabled(ppObj) then
                paramObjects.addLast ppObj
            end if
        next
        set valueObjects = pObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
        for each paramObj in paramObjects
            ' Design parameter
            propValue = ""
            propUnit = paramObj.getNamedStringValue("unit")
            for each valueObj in valueObjects
                set defObjects = valueObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_CCParam)
                for each defObj in defObjects
                    if defObj.title = paramObj.title then
                        ' Parameter has been given a value
                        propValue = valueObj.getNamedStringValue("value")
                        exit for
                    end if
                next
            next
            ' For each parameter create a property
            set prop = projectObject.newPart(GLOBAL_Type_EkaProperty)
            prop.title = paramObj.title
            ' Set the value, if given
            if Len(propValue) > 0 then
                call prop.setNamedStringValue("value", propValue)
            end if
            if Len(propUnit) > 0 then
                call prop.setNamedStringValue("unit", propUnit)
            end if
            set rel = model.newRelationship(GLOBAL_Type_EkaHasProperty, ccPart, prop)
        next
    End Sub

'-----------------------------------------------------------
    Private Sub deletePartStructure(product, partType)
        dim model
        dim part, parts
        dim prop, properties

        set model = product.ownerModel
        set parts = product.getNeighbourObjects(0, GLOBAL_Type_EkaHasMember, partType)
        for each part in parts
            call deletePartStructure(part, partType)
        next
        set properties = product.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each prop in properties
            call model.deleteObject(prop)
        next
        call model.deleteObject(product)
    End Sub

'---------------------------------------------------------------
    Public Sub buildConstraintsStructure(obj1, varObject, reqObj)
        dim obj, objs, objects
        dim obj2, obj2s
        dim cObj, dsObj
        dim ccObj, csObj, ceObj, crObj
        dim csRels, ceRels, crRels, ccRels
        dim csRel, ceRel, crRel, ccRel
        dim typeMode
        dim typName
        dim inst, instObjects
        dim req, reqObjects
        dim reqType, reqTypes
        dim parentVar
        dim varObj, usedVariants
        dim i, found

        set ccObj = obj1
        if not isEnabled(ccObj) then
            exit sub
        end if
        ' Find the non-functional requirements that applies to the CC
        ' First find the DS's
        set objects = findDesignSolutions(ccObj, true)
        for each dsObj in objects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                ' Then look for the Constraints (non-functional requirements)
                set objs = dsObj.getNeighbourObjects(0, GLOBAL_Type_constrainedBy, GLOBAL_Type_CO)
                if objs.count = 0 then
                    ' No constraints found
                else
                    typeMode = MODE_REQUIREMENT_TYPE
                    for each cObj in objs
                        if isEnabled(cObj) and includedInConfig(cObj) then
                            ' Find the requirement types
                            set reqTypes = getRequirementTypes(ccObj)
                            for each reqType in reqTypes
                                set reqObjects = reqType.getNeighbourObjects(1, GLOBAL_Type_EkaIs, GLOBAL_Type_Requirement)
                                i = 1
                                for each req in reqObjects
                                    set parentVar = req.parent
                                    if parentVar.uri <> varObject.uri then
                                        call reqObjects.removeAt(i)
                                    else
                                        i = i + 1
                                    end if
                                next
                                for each req in reqObjects
                                    if isEnabled(reqObj) then
                                        set obj2s = reqObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasMember, GLOBAL_Type_CCInstance)
                                        found = false
                                        for each obj2 in ibj2s
                                            if obj2.uri = req.uri then found = true
                                        next
                                        if not found then
                                            set rel = model.newRelationship(GLOBAL_Type_EkaHasMember, reqObj, req)
                                        end if
                                    end if
                                    set instObjects = req.getNeighbourObjects(1, GLOBAL_Type_EkaIs, GLOBAL_Type_CCInstance)
                                    for each inst in instObjects
                                        ' Then follow CS-CE structure to locate 'sub' components
                                        set csRels = ccObj.getNeighbourRelationships(0, GLOBAL_Type_hasCS)
                                        for each csRel in csRels
                                            if includedInConfig(csRel) then
                                                set csObj = csRel.target
                                                set ceRels = csObj.getNeighbourRelationships(0, GLOBAL_Type_hasCE)
                                                for each ceRel in ceRels
                                                    if includedInConfig(ceRel) then
                                                        set ceObj = ceRel.target
                                                        if includedInConfig(ceObj) then
                                                            set crRels = ceObj.getNeighbourRelationships(0, GLOBAL_Type_hasCR)
                                                            for each crRel in crRels
                                                                if includedInConfig(crRel) then
                                                                    set crObj = crRel.target
                                                                    set ccRels = crObj.getNeighbourRelationships(0, GLOBAL_Type_usesCC)
                                                                    for each ccRel in ccRels
                                                                        if includedInConfig(ccRel) then
                                                                            set obj = ccRel.target
                                                                            ' Find chosen variant, if possible
                                                                            set usedVariants = varObject.getNeighbourObjects(0, GLOBAL_Type_usesVAR2, GLOBAL_Type_VAR)
                                                                            for each varObj in usedVariants
                                                                                if varObj.url = obj.url then
                                                                                    call buildConstraintsStructure(obj, varObj, req)
                                                                                    exit for
                                                                                end if
                                                                            next
                                                                        end if
                                                                    next
                                                                end if
                                                            next
                                                        end if
                                                    end if
                                                next
                                            end if
                                        next
                                    next
                                next
                            next
                        end if
                    next
                end if
            end if
        next
    End Sub

'-----------------------------------------------------------
    Public Sub buildConstraintsView(obj1, varObject, parentView, workWindow, symbol1, symbol2)
        dim obj, objs, objects
        dim obj2, obj2s
        dim cObj, dsObj
        dim ccObj, csObj, ceObj, crObj
        dim csRels, ceRels, crRels, ccRels
        dim csRel, ceRel, crRel, ccRel
        dim typeMode
        dim typName
        dim inst, instObjects
        dim req, reqObjects
        dim reqType, reqTypes
        dim parentVar
        dim objView
        dim cvwObjectView
        dim varObj, usedVariants
        dim textscale
        dim isTop
        dim i, found

        set ccObj = obj1
        if not isEnabled(ccObj) then
            exit sub
        end if
        if parentView.uri = workWindow.uri then
            isTop = true
        else
            isTop = false
        end if
        ' Find the non-functional requirements that applies to the CC
        ' First find the DS's
        set objects = findDesignSolutions(ccObj, true)
        for each dsObj in objects
            if isEnabled(dsObj) and includedInConfig(dsObj) then
                ' Then look for the Constraints (non-functional requirements)
                set objs = dsObj.getNeighbourObjects(0, GLOBAL_Type_constrainedBy, GLOBAL_Type_CO)
                if objs.count = 0 then
                    ' No constraints found
                else
                    typeMode = MODE_REQUIREMENT_TYPE
                    for each cObj in objs
                        if isEnabled(cObj) and includedInConfig(cObj) then
                            ' Find the requirement types
                            set reqTypes = getRequirementTypes(ccObj)
                            for each reqType in reqTypes
                                set reqObjects = reqType.getNeighbourObjects(1, GLOBAL_Type_EkaIs, GLOBAL_Type_Requirement)
                                i = 1
                                for each req in reqObjects
                                    set parentVar = req.parent
                                    if parentVar.uri <> varObject.uri then
                                        call reqObjects.removeAt(i)
                                    else
                                        i = i + 1
                                    end if
                                next
                                for each req in reqObjects
                                    'if isEnabled(req) then
                                    '    set obj2s = req.getNeighbourObjects(0, GLOBAL_Type_EkaHasMember, GLOBAL_Type_CCInstance)
                                    '    found = false
                                    '    for each obj2 in ibj2s
                                    '        if obj2.uri = req.uri then found = true
                                    '    next
                                    '    if not found then
                                    '        set rel = model.newRelationship(GLOBAL_Type_EkaHasMember, reqObj, req)
                                    '    end if
                                    'end if
                                    set instObjects = req.getNeighbourObjects(1, GLOBAL_Type_EkaIs, GLOBAL_Type_CCInstance)
                                    for each inst in instObjects
                                        ' Create object view
                                        set cvwObjectView = new CVW_ObjectView
                                        cvwObjectView.treeTextFactor = -1
                                        cvwObjectView.nestedTextFactor1 = -1
                                        cvwObjectView.nestedTextFactor2 = -1
                                        cvwObjectView.heightRatio = -1
                                        set objView = cvwObjectView.create(workWindow, parentView, inst, 0)
                                        if isTop and Len(symbol1) > 0 then
                                            objView.openSymbol   = symbol1
                                            objView.closedSymbol = symbol1
                                        end if
                                        if not isTop and Len(symbol2) > 0 then
                                            objView.openSymbol   = symbol2
                                            objView.closedSymbol = symbol2
                                            textscale = 0.25
                                            objView.textScale = textScale
                                        end if
                                        ' Then follow CS-CE structure to locate 'sub' components
                                        set csRels = ccObj.getNeighbourRelationships(0, GLOBAL_Type_hasCS)
                                        for each csRel in csRels
                                            if includedInConfig(csRel) then
                                                set csObj = csRel.target
                                                set ceRels = csObj.getNeighbourRelationships(0, GLOBAL_Type_hasCE)
                                                for each ceRel in ceRels
                                                    if includedInConfig(ceRel) then
                                                        set ceObj = ceRel.target
                                                        if includedInConfig(ceObj) then
                                                            set crRels = ceObj.getNeighbourRelationships(0, GLOBAL_Type_hasCR)
                                                            for each crRel in crRels
                                                                if includedInConfig(crRel) then
                                                                    set crObj = crRel.target
                                                                    set ccRels = crObj.getNeighbourRelationships(0, GLOBAL_Type_usesCC)
                                                                    for each ccRel in ccRels
                                                                        if includedInConfig(ccRel) then
                                                                            set obj = ccRel.target
                                                                            ' Find chosen variant, if possible
                                                                            set usedVariants = varObject.getNeighbourObjects(0, GLOBAL_Type_usesVAR2, GLOBAL_Type_VAR)
                                                                            for each varObj in usedVariants
                                                                                if varObj.url = obj.url then
                                                                                    call buildConstraintsView(obj, varObj, objView, workWindow, symbol1, symbol2)
                                                                                    exit for
                                                                                end if
                                                                            next
                                                                        end if
                                                                    next
                                                                end if
                                                            next
                                                        end if
                                                    end if
                                                next
                                            end if
                                        next
                                    next
                                next
                            next
                        end if
                    next
                end if
            end if
        next
        if isTop then
            if isValid(objView) then
                call objView.doLayout
            end if
        end if
    End Sub

'-----------------------------------------------------------
'-----------------------------------------------------------
    Private Function findDesignSolutions(obj1, inConfig)
        dim ccObj
        dim obj, objects
        dim dsObj, dsObjects
        dim primary

        set ccObj = obj1
        set findDesignSolutions = metis.newInstanceList
        set dsObjects = ccObj.getNeighbourObjects(0, GLOBAL_Type_hasDS, GLOBAL_Type_DS)
        for each dsObj in dsObjects
            if not inConfig or includedInConfig(dsObj) then
                call findDesignSolutions.addLast(dsObj)
            end if
        next
        if findDesignSolutions.count > 0 then
            exit function
        end if

        ' DS not found directly - try via FR
        ' Find primary FR's
        set objects = ccObj.getNeighbourObjects(0, GLOBAL_Type_explains, GLOBAL_Type_FR)
        for each obj in objects
            if isEnabled(obj) then
                primary = obj.getNamedValue("primary").getInteger
                if primary = 1 then
                    ' Top FR - find DSs
                    set dsObjects = obj.getNeighbourObjects(0, GLOBAL_Type_solves, GLOBAL_Type_DS)
                    if not isValid(findDesignSolutions) then
                        set findDesignSolutions = dsObjects
                    else
                        for each dsObj in dsObjects
                            if not inConfig or includedInConfig(dsObj) then
                                call findDesignSolutions.addLast(dsObj)
                            end if
                        next
                    end if
                end if
            end if
        next
    End Function

'-----------------------------------------------------------
    Private Function getTypeModel(obj1, typeMode)
        dim projectName
        dim ccModel
        dim ccObj
        dim modelObject, newObject
        dim projects
        dim part, parts
        dim cvwSelectDialog

        set getTypeModel = Nothing
        set ccObj = obj1

        ' Create the project object
        set ccModel = ccObj.ownerModel
        if not isValid(projects) then
            set projects = metis.newInstanceList
            set parts = ccModel.parts
            for each part in parts
                if part.type.inherits(GLOBAL_Type_Model) then
                    projects.addLast part
                end if
            next
        end if
        set newObject = ccModel.newObject(GLOBAL_Type_Model)
        if isEnabled(newObject) then
            newObject.title = "New project"
            projects.addLast newObject
        end if
        if projects.count = 0 then
            exit function
        else
            set cvwSelectDialog = new CVW_SelectDialog
            cvwSelectDialog.singleSelect = true
            cvwSelectDialog.title = "Select project"
            cvwSelectDialog.heading = "Select project"
            set projects = cvwSelectDialog.show(projects)
            if isValid(projects) then
                if projects.count = 1 then
                    set modelObject = projects(1)
                    if modelObject.title = "New project" then
                        projectName = ccObj.title
                        projectName = InputBox("Enter project name", "Input dialog", projectName)
                        if Len(projectName) > 0 then
                            modelObject.title = projectName
                        else
                            exit function
                        end if
                    end if
                    set getTypeModel = modelObject
                end if
                if modelObject.uri <> newObject.uri or projects.count = 0 then
                    ccModel.deleteObject(newObject)
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        set ccGlobals = Nothing
        ' Initialize rule class
        set ccRule       = new CC_Rule
        set ccRuleEngine = new CC_RuleEngine

        ' Properties
        RuleEvaluatedToProperty = "ruleEvaluatedTo"

        ' Modes
        MODE_REQUIREMENT_TYPE    = 1
        MODE_SPECIFICATION_TYPE  = 2
        MODE_PART_TYPE           = 4
        
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

