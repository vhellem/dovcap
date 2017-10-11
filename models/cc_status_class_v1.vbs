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
    Private ccType
    Private frType
    Private dsType
    Private coType
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
    Private parameterType
    Private coParameterType
    Private constrainsType
    Private constrainedType
    Private constrainedByType
    Private hasCoParamType

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
                    if paramObj.type.inherits(parameterType) then
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
            stat = -1
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
        if isEnabled(paramVal) then
            ' Check if parameter is constrained
            set reqs = parameter.getNeighbourObjects(1, constrainsType, cpType)
            if reqs.count > 0 then
                for each req in reqs
                    if paramIsValid then
                        paramIsValid = checkParameterValue(paramVal, req)
                    end if
                next
                getParameterStatus = paramIsValid
            else
                if Len(paramVal.title) > 0 then
                    getParameterStatus = 3
                end if
            end if
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
            set defs = value.getNeighbourObjects(0, hasDefinitionType, parameterType)
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
        dim range, ranges
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
                ' Find value range to compare to
                set ranges = reqParam.parts
                if ranges.count > 0 then
                    checkParameterValue = false
                    reqValMin = ranges(1).getNamedValue("min").getFloat
                    reqValMax = ranges(1).getNamedValue("max").getFloat
                    if reqValMin <= fval and fval <= reqValMax then
                        checkParameterValue = 3
                    elseif fval < reqValMin or fval > reqValMax then
                        checkParameterValue = 1
                    else
                        checkParameterValue = 2
                    end if
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
        set objects = dsObj.getNeighbourObjects(0, constrainedByType, coType)
        if objects.count > 0 then
            coStatus = getParameterStatus(dsObj, coObjects, hasCpType, cpType)
            if coStatus > 0 and coStatus < 3 then
                status = 0
            elseif coStatus = 3 then
                status = 1
            end if
        end if
        ' Get design parameter status, -1 = Undefined, 2 = Partially given, 3 = All given
        set dsObjects = metis.newInstanceList
        dsObjects.addLast dsObj
        dpStatus = getParameterStatus(dsObj, dsObjects, hasDpType, dpType)
        ' Get performance parameter status, -1 = Undefined, 2 = Partially given, 3 = All given
        ppStatus = getParameterStatus(dsObj, dsObjects, hasPpType, ppType)

        if dpStatus < 3 or ppStatus < 3 then
            status = 2
        elseif dpStatus = 3 and ppStatus = 3 then
            status = 3
        end if

        calculateStatus = status

    End Function
    
'-----------------------------------------------------------
    Private Sub Class_Initialize()
        ' Types
        set frType             = metis.findType("http://xml.chalmers.se/class/functional_requirement.kmd#functional_requirement")
        set dsType             = metis.findType("http://xml.chalmers.se/class/design_solution.kmd#design_solution")
        set coType             = metis.findType("http://xml.chalmers.se/class/constraint.kmd#constraint")
        set cpType             = metis.findType("http://xml.chalmers.se/class/constraint_parameter.kmd#constraint_parameter")
        set dpType             = metis.findType("http://xml.chalmers.se/class/design_parameter.kmd#design_parameter")
        set fpType             = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter.kmd#functional_requirement_parameter")
        set ppType             = metis.findType("http://xml.chalmers.se/class/performance_parameter.kmd#performance_parameter")
        set vpType             = metis.findType("http://xml.chalmers.se/class/variant_parameter.kmd#variant_parameter")
        set hasDpType          = metis.findType("http://xml.chalmers.se/class/has_design_parameter.kmd#has_design_parameter")
        set hasPpType          = metis.findType("http://xml.chalmers.se/class/has_performance_parameter.kmd#has_performance_parameter")
        set paramValueType     = metis.findType("http://xml.chalmers.se/class/cc_value.kmd#CC_value")
        set cpValueType        = metis.findType("http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value")
        set dpValueType        = metis.findType("http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value")
        set fpValueType        = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value")
        set ppValueType        = metis.findType("http://xml.chalmers.se/class/performance_parameter_value.kmd#performance_parameter_value")
        set vpValueType        = metis.findType("http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value")
        set constrainedByType  = metis.findType("http://xml.chalmers.se/class/is_constrained_by.kmd#Is_constrained_by")
        set parameterType      = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")
        set constrainsType     = metis.findType("http://xml.chalmers.se/class/constrains_parameter.kmd#constrains_parameter")
        set valueType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
        set hasValueType       = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
        set hasDefinitionType  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")

    'Private coParameterType
    'Private constrainedType
    'Private constrainedByType
    'Private hasCoParamType

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

