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

    ' Types
    Private valueType
    Private hasValueType
    Private hasDefinitionType


'-----------------------------------------------------------
    Public Function getObjectStatus(subject)
        dim stat
        dim noParams, noUndefined, noReqMissing
        dim noSolMissing, noSolPartial, noSolFilled
        dim includedInConfig
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
        includedInConfig = subject.getNamedValue("ruleEvaluatedTo").getInteger
        if includedInConfig = 0 then
            getObjectStatus = 1
            exit function
        else
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
        set values = obj.getNeighbourObjects(0, hasValueType, valueType)
        for each value in values
            set defs = value.getNeighbourObjects(0, hasDefinitionType, GLOBAL_Type_CCParam)
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
        next
    End Function

'-----------------------------------------------------------
    Private Function checkParameterValue(paramValue, reqParam)
        dim minVal, maxVal
        dim reqValMin, reqValMax
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
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        ' Initialize local variables
        ' Types
        set valueType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
        set hasValueType       = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
        set hasDefinitionType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

