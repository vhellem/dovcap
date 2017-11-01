option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_Status


    ' Variant parameters
    Public Title                        ' String

    Private status                      ' -1 = Undefined,
                                        '  0 = Requirements missing
                                        '  1 = Solution missing
                                        '  2 = Solution partially fulfilled
                                        '  3 = Solution fulfilled
    Public explanation                                        

'-----------------------------------------------------------
    Public Function getObjectStatus(subject)
        dim stat
        dim noParams, noUndefined, noReqMissing
        dim noSolMissing, noSolPartial, noSolFilled
        dim includedInConfig, includedProp
        dim parameter, parameters
        dim value, values
        dim paramObj, paramStatus
        dim rel, rels
        dim req, reqs

        stat = -1
        noParams     = 0
        noUndefined  = 0
        noReqMissing = 0
        noSolMissing = 0
        noSolPartial = 0
        noSolFilled  = 0

        ' First check object status
        if isEnabled(subject) then
            if true then
                on error resume next
                set includedProp = subject.type.getProperty("ruleEvaluatedTo")
            end if
            if isValid(includedProp) then
                includedInConfig = subject.getNamedValue("ruleEvaluatedTo").getInteger
                if includedInConfig = 0 then
                    getObjectStatus = 1
                    exit function
                end if
            end if
            ' Find the parameters
            set rels = subject.neighbourRelationships
            for each rel in rels
                if rel.origin.uri = subject.uri then
                    set paramObj = rel.target
                    if paramObj.type.inherits(GLOBAL_Type_CCParam) then
                        noParams = noParams + 1
                        paramStatus = paramObj.getNamedValue("status").getInteger
                        select case paramStatus
                            case -1     noUndefined  = noUndefined + 1
                            case  0     noReqMissing = noReqMissing + 1
                            case  1     noSolMissing = noSolMissing + 1
                            case  2     noSolPartial = noSolPartial + 1
                            case  3     noSolFilled  = noSolFilled + 1
                        end select
                    end if
                end if
            next
        end if

        if noUndefined = noParams then
            if noParams > 0 then
                stat = 0
            else
                stat = -1
            end if
        elseif noReqMissing > 0 then
            stat = 0
        elseif noSolMissing > 0 then
            stat = 1
        elseif noSolFilled = noParams then
            stat = 3
        else
            stat = 2
        end if

        getObjectStatus = stat

    End Function

'-----------------------------------------------------------
    Public Function getParameterStatus(parameter, hasParameterType)
        dim rel, parentRels
        dim parentObj
        dim paramVal
        dim req, reqs
        dim paramIsValid

        ' Get parameter parent
        getParameterStatus = -1
        set parentRels = parameter.getNeighbourRelationships(1, hasParameterType)
        if parentRels.count = 0 then ' added HDJ Aug 29
			exit function
        end if
        paramIsValid = -1
        set parentObj = parentRels(1).origin
        set paramVal = getParameterValue(parentObj, parameter)
        ' Check if parameter is constrained
        set reqs = parameter.getNeighbourObjects(1, GLOBAL_Type_constrains, GLOBAL_Type_CPR)
        if reqs.count > 0 then
            if isEnabled(paramVal) then
                for each req in reqs
                    if paramIsValid then
                        paramIsValid = checkParameterValue(paramVal, req)
                    end if
                next
                getParameterStatus = paramIsValid
            else
                if not isEnabled(paramVal) then
                    getParameterStatus = 1
                elseif Len(paramVal.title) > 0 then
                    getParameterStatus = 1
                end if
            end if
        else
            getParameterStatus = 0
        end if
    End Function

'-----------------------------------------------------------
    Private Function getParameterValue(obj, parameter)
        dim value, values
        dim def, defs
        dim paramVal
        
        set getParameterValue = Nothing
		if not isValid(obj) then ' added HDJ Aug 29
			exit function
        end if
        set values = obj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
        for each value in values
            set defs = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_CCParam)
            if defs.count > 0 then
                for each def in defs
                    if def.uri = parameter.uri then
                        paramVal = value.getNamedStringValue("value")
                        if Len(paramVal) > 0 then
                            set getParameterValue = value
                            exit function
                        end if
                        exit for
                    end if
                next
            elseif value.title = parameter.title then
                paramVal = value.getNamedStringValue("value")
                if Len(paramVal) > 0 then
                    set getParameterValue = value
                    exit function
                end if
            end if
        next
    End Function

'-----------------------------------------------------------
    Private Function checkParameterValue(paramValue, reqParam)
        dim minVal, maxVal, nomVal, tolVal
        dim reqValMin, reqValMax, reqValNom, reqValTol
        dim paramVal
        dim sval, fval

        on error resume next
        checkParameterValue = 3
        if isEnabled(reqParam) then
            sval = paramValue.title
            if sval = "Undefined" then
                checkParameterValue = 0
                exit function
            elseif Len(sval) = 0 then
                checkParameterValue = 0
                exit function
            end if
            if isNumeric(sval) then
                fval = CDbl(sval)
                minVal = reqParam.getNamedStringValue("minimum")
                if Len(minVal) > 0 then
                    if isNumeric(minVal) then
                        reqValMin = CDbl(minVal)
                    end if
                end if
                maxVal = reqParam.getNamedStringValue("maximum")
                if Len(maxVal) > 0 then
                    if isNumeric(maxVal) then
                        reqValMax = CDbl(maxVal)
                    end if
                end if
                nomVal = reqParam.getNamedStringValue("nominal")
                if Len(nomVal) > 0 then
                    if isNumeric(nomVal) then
                        reqValNom = CDbl(nomVal)
                    end if
                    tolVal = reqParam.getNamedStringValue("tolerance")
                    if Len(tolVal) > 0 then
                        if isNumeric(tolVal) then
                            reqValTol = CDbl(tolVal) * (reqValNom / 100)
                            reqValMin = reqValNom - reqValTol
                            reqValMax = reqValNom + reqValTol
                        end if
                    end if
                end if
                if isEmpty(reqValMin) and isEmpty(reqValMax) then
                    checkParameterValue = -1
                elseif isEmpty(reqValMin) then
                    if fval <= reqValMax then
                        checkParameterValue = 3
                    else
                        checkParameterValue = 1
                    end if
                elseif isEmpty(reqValMax) then
                    if fval >= reqValMin then
                        checkParameterValue = 3
                    else
                        checkParameterValue = 1
                    end if
                elseif reqValMin <= fval and fval <= reqValMax then
                    checkParameterValue = 3
                elseif fval < reqValMin or fval > reqValMax then
                    checkParameterValue = 1
                else
                    checkParameterValue = 2
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function calculateStatus(dsObj)
        dim status
        dim coStatus, dpStatus, ppStatus

        status = -1 ' Undefined

        ' Get constraint parameter status, -1 = Undefined, 2 = Partially given, 3 = All given
        set objects = dsObj.getNeighbourObjects(0, GLOBAL_Type_constrainedBy, GLOBAL_Type_CO)
        if objects.count > 0 then
            coStatus = getParameterStatus(dsObj, coObjects, GLOBAL_Type_hasCPR, GLOBAL_Type_CPR)
            if coStatus > 0 and coStatus < 3 then
                status = 0
            elseif coStatus = 3 then
                status = 1
            end if
        end if
        ' Get design parameter status, -1 = Undefined, 2 = Partially given, 3 = All given
        set dsObjects = metis.newInstanceList
        dsObjects.addLast dsObj
        dpStatus = getParameterStatus(dsObj, dsObjects, GLOBAL_Type_hasDP, GLOBAL_Type_DP)
        ' Get performance parameter status, -1 = Undefined, 2 = Partially given, 3 = All given
        ppStatus = getParameterStatus(dsObj, dsObjects, GLOBAL_Type_hasPP, GLOBAL_Type_PP)

        if dpStatus < 3 or ppStatus < 3 then
            status = 2
        elseif dpStatus = 3 and ppStatus = 3 then
            status = 3
        end if

        calculateStatus = status
    End Function

'-----------------------------------------------------------
    Public Function getRequirementStatus(currentObj, familyObj)
        dim prop, properties
        dim typeProp, typeProps
        dim reqType, reqTypes
        dim ival
        dim status, propStatus
        dim noProps, noTrue, noFalse, noPartly, noUndefined

        ' Current object is a CC requirement or CC instance
        ' The reqType object is a CC requirement or CC instance

        noProps = 0
        noTrue  = 0
        noFalse = 0
        noPartly = 0
        noUndefined = 0

        ' Get the properties
        set properties = currentObj.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
        if isEnabled(familyObj) then
            dim i, found
            set typeProps  = familyObj.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
            ' Remove properties without type definition
            i = 1
            for each prop in properties
                found = false
                for each typeProp in typeProps
                    if typeProp.title = prop.title then
                        found = true
                        exit for
                    end if
                next
                if not found then
                    properties.removeAt(i)
                else
                    i = i + 1
                end if
            next
            for each prop in properties
                for each typeProp in typeProps
                    if typeProp.title = prop.title then
                        explanation = ""
                        propStatus = isAllowedValue(prop, typeProp, explanation)
                        if propStatus = -1 then noUndefined = noUndefined + 1
                        if propStatus = 0  then noFalse = noFalse + 1
                        if propStatus = 1  then noPartly = noPartly + 1
                        if propStatus = 2  then noTrue = noTrue + 1
                    end if
                next
            next
        else
            ' Find reqType
            set reqTypes = currentObj.getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_AnyObject)
            for each reqType in reqTypes
                set typeProps  = reqType.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty) 
                for each prop in properties
                    for each typeProp in typeProps
                        if typeProp.title = prop.title then
                            explanation = ""
                            propStatus = isAllowedValue(prop, typeProp, explanation)
                            if propStatus = -1 then noUndefined = noUndefined + 1
                            if propStatus = 0  then noFalse = noFalse + 1
                            if propStatus = 1  then noPartly = noPartly + 1
                            if propStatus = 2  then noTrue = noTrue + 1
                        end if
                    next
                next
            next
        end if
        noProps = properties.count
        noProps = noProps - noUndefined
        if noProps = 0 then
            status = -1
        elseif noTrue = noProps then
            status = 3
        elseif noFalse = noProps then
            status = 1
        else
            status = 2
        end if
        getRequirementStatus = status

    End Function

'-----------------------------------------------------------
    Public Function getViewPropertyStatus(prop, familyObj)
        dim parentRels
        dim parentObj
        dim propName
        dim reqParam, reqParams
        dim reqType, reqTypes
        dim param, params
        dim constrains
        dim status

        status = -1
        getViewPropertyStatus = status

        if not isEnabled(prop) then
            exit function
        end if

        ' Get property parent
        set parentRels = prop.getNeighbourRelationships(1, GLOBAL_Type_CCHasProperty)
        if parentRels.count = 0 then
			exit function
        end if
        set parentObj = parentRels(1).origin
        propName = prop.title
        ' Check if specification
        if parentObj.type.inherits(GLOBAL_Type_Specification) then
            ' Find params
            set params = parentObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
            for each param in params
                if param.title = propName then
                    ' Check for constrains
                    set constrains = param.getNeighbourObjects(1, GLOBAL_Type_constrains, GLOBAL_Type_AnyObject)
                    for each reqParam in constrains
                        getViewPropertyStatus = isAllowedValue(param, reqParam, explanation)
                        exit function
                    next
                end if
            next
        else
            if isEnabled(familyObj) then
                set reqParams = familyObj.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
                for each reqParam in reqParams
                    if reqParam.title = propName then
                        explanation = ""
                        getViewPropertyStatus = isAllowedValue(prop, reqParam, explanation)
                        exit function
                    end if
                next
            else
                ' Find reqType
                set reqTypes = parentObj.getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_AnyObject)
                for each reqType in reqTypes
                    set reqParams = reqType.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
                    for each reqParam in reqParams
                        if reqParam.title = propName then
                            explanation = ""
                            getViewPropertyStatus = isAllowedValue(prop, reqParam, explanation)
                            exit function
                        end if
                    next
                next
            end if
        end if
        getViewPropertyStatus = status

    End Function

'-----------------------------------------------------------
    Private Function isAllowedValue(prop, typeProp, explanation)     ' -1 = Undefined,  0 = Not within range,    1 = Partly within range,    2 = Within range
        dim propValue, propMinValue, propMaxValue, propNomValue, propTolValue
        dim typePropValue, typePropMinValue, typePropMaxValue, typePropNomValue, typePropTolValue
        dim smin, smax, snom, stol
        dim isAllowed1, isAllowed2

        isAllowedValue = -1

        propValue = prop.getNamedStringValue("value")
        typePropValue = typeProp.getNamedStringValue("value")

        if Len(propValue) > 0 then
            if Len(typePropValue) > 0 then
                if propValue = typePropValue then
                    isAllowedValue = 2
                else
                    isAllowedValue = 0
                end if
                exit function
            end if
        end if

        if Len(propValue) = 0 then
            on error resume next
            smin = prop.getNamedStringValue("min")
            smax = prop.getNamedStringValue("max")
            snom = prop.getNamedStringValue("nominal")
            stol = prop.getNamedStringValue("tolerance")

            if Len(smin) > 0 then
                if isNumeric(smin) then
                    propMinValue = CDbl(smin)
                end if
            else
                propMinValue = -99999
            end if
            if Len(smax) > 0 then
                if isNumeric(smax) then
                    propMaxValue = CDbl(smax)
                end if
            else
                propMaxValue = -99999
            end if
            if Len(snom) > 0 then
                if isNumeric(snom) then
                    propNomValue = CDbl(snom)
                    if Len(stol) > 0 then
                        if isNumeric(stol) then
                            propTolValue = CDbl(stol)
                            propTolValue = propTolValue * propNomValue / 100
                            propMinValue = propNomValue - propTolValue
                            propMaxValue = propNomValue + propTolValue
                        end if
                    'else
                    '    propMinValue = propNomValue
                    '    propMaxValue = propNomValue
                    end if
                end if
            end if
        end if

        if Len(typePropValue) = 0 then
            smin = typeProp.getNamedStringValue("min")
            smax = typeProp.getNamedStringValue("max")
            snom = typeProp.getNamedStringValue("nominal")
            stol = typeProp.getNamedStringValue("tolerance")
            if Len(smin) = 0 and Len(smax) = 0 and Len(snom) = 0 then
                isAllowedValue = -1
                explanation = ""
                exit function
            end if
            if Len(smin) > 0 then
                if isNumeric(smin) then
                    typePropMinValue = CDbl(smin)
                end if
            else
                typePropMinValue = -99999
            end if
            if Len(smax) > 0 then
                if isNumeric(smax) then
                    typePropMaxValue = CDbl(smax)
                end if
            else
                typePropMaxValue = -99999
            end if
            if Len(snom) > 0 then
                if isNumeric(snom) then
                    typePropNomValue = CDbl(snom)
                    if Len(stol) > 0 then
                        if isNumeric(stol) then
                            typePropTolValue = CDbl(stol)
                            typePropTolValue = typePropTolValue * typePropNomValue / 100
                            typePropMaxValue = typePropNomValue - typePropTolValue
                            typePropMaxValue = typePropNomValue + typePropTolValue
                        end if
                    'else
                    '    typePropMinValue = typePropNomValue
                    '    typePropMaxValue = typePropNomValue
                    end if
                end if
            end if
        end if

        isAllowedValue = 0
        if propMinValue = -99999 and propMaxValue = -99999 then
            isAllowed1 = 5    ' Target
            isAllowed2 = 5    ' Target
        elseif propMinValue = -99999 then
            isAllowed1 = -9    ' Undefined
            if typePropMinValue <> -99999 then
                isAllowed1 = -1
            end if
        elseif typePropMinValue = -99999 then
            isAllowed1 = 0
            if typePropMaxValue <> -99999 then
                if propMinValue > typePropMaxValue then
                    isAllowed1 = 2  ' Too high
                end if
            end if
        elseif propMinValue = typePropMinValue then
            isAllowed1 = 0      ' Exact
        elseif propMinValue > typePropMinValue then
            isAllowed1 = 1      ' Higher
            if typePropMaxValue <> -99999 then
                if propMinValue > typePropMaxValue then
                    isAllowed1 = 2  ' Too high
                    if typePropMinValue = -99999 then
                        explanation = "Specified range: ... - " & typePropMaxValue
                    else
                        explanation = "Specified range: " & typePropMinValue & " - " & typePropMaxValue
                    end if
                end if
            end if
        else
            isAllowed1 = -1     ' Too low
        end if
        if propMinValue = -99999 and propMaxValue = -99999 then
            isAllowed1 = 5    ' Target
            isAllowed2 = 5    ' Target
        elseif propMaxValue = -99999 then
            isAllowed2 = -9
        elseif typePropMaxValue = -99999 then
            isAllowed2 = 0
            if typePropMinValue <> -99999 then
                if propMaxValue < typePropMinValue then
                    isAllowed2 = -2     ' Too low
                end if
            end if
        elseif propMaxValue = typePropMaxValue then
            isAllowed2 = 0      ' Exact
        elseif propMaxValue < typePropMaxValue then
            isAllowed2 = -1      ' Lower
            if typePropMinValue <> -99999 then
                if propMaxValue < typePropMinValue then
                    isAllowed2 = -2     ' Too low
                    if typePropMaxValue = -99999 then
                        explanation = "Specified range: " & typePropMinValue & " - ..."
                    else
                        explanation = "Specified range: " & typePropMinValue & " - " & typePropMaxValue
                    end if
                end if
            end if
        else
            isAllowed2 = 1      ' Too high
        end if
        if propMaxValue <> -99999 and propMaxValue < propMinValue then
            isAllowed1 = 2
            isAllowed2 = -2
        end if

        ' Calculate allowedValue and explanation
        if typePropMinValue = -99999 then
            explanation = "Specified range: " & "...  -  " & typePropMaxValue
        elseif typePropMaxValue = -99999 then
            explanation = "Specified range: " & typePropMinValue & "  -  ..."
        else
            explanation = "Specified range: " & typePropMinValue & "  -  " & typePropMaxValue
        end if

        if isAllowed1 = 5 and isAllowed2 = 5 then
            if isEmpty(propNomValue) then
                isAllowedValue = -1
                explanation = ""
                exit function
            elseif typePropMinValue <> -99999 and typePropMaxValue <> -99999 then
                if propNomValue >= typePropMinValue and propNomValue <= typePropMaxValue then
                    isAllowedValue = 2
                    exit function
                end if
            elseif typePropMinValue <> -99999  then
                if propNomValue >= typePropMinValue then
                    isAllowedValue = 2
                    exit function
                end if
            elseif typePropMaxValue <> -99999 then
                if propNomValue <= typePropMaxValue then
                    isAllowedValue = 2
                    exit function
                end if
            end if
        end if
        if isAllowed1 = -9 and isAllowed2 = -9 then
            isAllowedValue = -1
        elseif isAllowed1 = 2 and isAllowed2 = -2 then
            isAllowedValue = 0
            explanation = "Specified range: Illegal specification"
            exit function
        end if
        if isAllowed1 = -9 and isAllowed2 = -1 then
            isAllowedValue = 1
            explanation = "Specified range: ... - " & typePropMaxValue
            exit function
        end if
        dim testMode
        testMode = 2
        if testMode = 1 then
            if isAllowed1 = -9 and isAllowed2 = -2 then isAllowedValue = 0      ' Undefined and Too low
            if isAllowed1 = -9 and isAllowed2 = -1 then isAllowedValue = 1      ' Undefined and Lower
            if isAllowed1 = -9 and isAllowed2 =  0 then isAllowedValue = 2      ' Undefined and Exact
            if isAllowed1 =  1 and isAllowed2 =  0 then isAllowedValue = 2      ' Higher and Exact
            if isAllowed1 =  0 and isAllowed2 = -9 then isAllowedValue = 2      ' Exact and Undefined
            if isAllowed1 =  0 and isAllowed2 = -1 then isAllowedValue = 2      ' Exact and Lower
            if isAllowed1 =  0 and isAllowed2 =  0 then isAllowedValue = 2      ' Exact and Exact
            if isAllowed1 =  0 and isAllowed2 =  1 then isAllowedValue = 2      ' Exact and Higher
            if isAllowed1 = -1 and isAllowed2 =  0 then isAllowedValue = 2      ' Lower and Exact
            if isAllowed1 = -1 and isAllowed2 =  1 then isAllowedValue = 2      ' Lower and Higher
            if isAllowedValue = 2 then
                'explanation = ""
                exit function
            end if

            if isAllowed1 =  2 and isAllowed2 = -9 then isAllowedValue = 0      ' Too high and Undefined
            if isAllowed1 =  2 and isAllowed2 = -2 then isAllowedValue = 0      ' Too high and Too low
            if isAllowed1 =  2 and isAllowed2 = -1 then isAllowedValue = 0      ' Too high and Lower
            if isAllowed1 =  2 and isAllowed2 =  0 then isAllowedValue = 0      ' Too high and Exact
            if isAllowed1 =  2 and isAllowed2 =  1 then isAllowedValue = 0      ' Too high and Higher
            if isAllowed1 =  1 and isAllowed2 =  1 then isAllowedValue = 1      ' Higher and Higher
            if isAllowed1 =  1 and isAllowed2 = -1 then isAllowedValue = 1      ' Higher and Lower
            if isAllowed1 =  1 and isAllowed2 = -9 then isAllowedValue = 1      ' Higher and Undefined
            if isAllowed1 = -1 and isAllowed2 = -9 then isAllowedValue = 1      ' Lower and Undefined
            if isAllowed1 = -1 and isAllowed2 = -1 then isAllowedValue = 1      ' Lower and Lower

        elseif testMode = 2 then
            if isAllowed1 = -9 and isAllowed2 = -2 then isAllowedValue = 0      ' Undefined and Too low
            if isAllowed1 = -9 and isAllowed2 = -1 then isAllowedValue = 1      ' Undefined and Lower
            if isAllowed1 = -9 and isAllowed2 =  0 then isAllowedValue = 2      ' Undefined and Exact
            if isAllowed1 =  1 and isAllowed2 =  0 then isAllowedValue = 2      ' Higher and Exact
            if isAllowed1 =  0 and isAllowed2 = -9 then isAllowedValue = 2      ' Exact and Undefined
            if isAllowed1 =  0 and isAllowed2 = -1 then isAllowedValue = 2      ' Exact and Lower
            if isAllowed1 =  0 and isAllowed2 =  0 then isAllowedValue = 2      ' Exact and Exact
            if isAllowed1 =  0 and isAllowed2 =  1 then isAllowedValue = 1      ' Exact and Higher
            if isAllowed1 = -1 and isAllowed2 =  0 then isAllowedValue = 1      ' Lower and Exact
            if isAllowed1 = -1 and isAllowed2 =  1 then isAllowedValue = 0      ' Lower and Higher
            if isAllowedValue = 2 then
                'explanation = ""
                exit function
            end if

            if isAllowed1 =  2 and isAllowed2 = -9 then isAllowedValue = 0      ' Too high and Undefined
            if isAllowed1 =  2 and isAllowed2 = -2 then isAllowedValue = 0      ' Too high and Too low
            if isAllowed1 =  2 and isAllowed2 = -1 then isAllowedValue = 0      ' Too high and Lower
            if isAllowed1 =  2 and isAllowed2 =  0 then isAllowedValue = 0      ' Too high and Exact
            if isAllowed1 =  2 and isAllowed2 =  1 then isAllowedValue = 0      ' Too high and Higher
            if isAllowed1 =  1 and isAllowed2 =  1 then isAllowedValue = 1      ' Higher and Higher
            if isAllowed1 =  1 and isAllowed2 = -1 then isAllowedValue = 2      ' Higher and Lower
            if isAllowed1 =  1 and isAllowed2 = -9 then isAllowedValue = 2      ' Higher and Undefined
            if isAllowed1 = -1 and isAllowed2 = -9 then isAllowedValue = 0      ' Lower and Undefined
            if isAllowed1 = -1 and isAllowed2 = -1 then isAllowedValue = 1      ' Lower and Lower
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

