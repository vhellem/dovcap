function getParameterTitle
    dim currentModel
    dim currentInstance
    dim parameterType
    dim rel, relships

    ' Initialization
    getParameterTitle       = ""
    set currentModel        = metis.currentModel
    set currentInstance     = currentModel.currentInstance
    set parameterType       = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")

    ' Main code
    if isEnabled(currentInstance) then
        set relships = currentInstance.neighbourRelationships
        if isValid(relships) then
            for each rel in relships
                if rel.target.uri = currentInstance.uri then
                    if rel.origin.type.inherits(parameterType) then
                        getParameterTitle = rel.origin.title
                    end if
                end if
            next
        end if
    end if
end function

function getParameterParentTitle
    dim currentModel
    dim currentInstance
    dim parameterType
    dim rel, rel2, relships
    dim parentObj, paramObj

    ' Initialization
    getParameterParentTitle = ""
    set currentModel        = metis.currentModel
    set currentInstance     = currentModel.currentInstance
    set parameterType       = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")

    ' Main code
    if isEnabled(currentInstance) then
        if currentInstance.type.inherits(parameterType) then
            getParameterParentTitle = getParameterParentName(currentInstance)
        else
            set relships = currentInstance.neighbourRelationships
            if isValid(relships) then
                for each rel in relships
                    if rel.target.uri = currentInstance.uri then
                        if rel.origin.type.inherits(parameterType) then
                            set paramObj = rel.origin
                            getParameterParentTitle = getParameterParentName(paramObj)
                        end if
                    end if
                next
            end if
        end if
    end if
end function

function getParameterParentName(paramObj)
    dim rel2, rels
    dim hasCpType, hasDpType, hasFpType, hasPpType, hasVpType

    getParameterParentName = ""
    set hasCpType           = metis.findType("http://xml.chalmers.se/class/has_constraint_parameter.kmd#has_constraint_parameter")
    set hasDpType           = metis.findType("http://xml.chalmers.se/class/has_design_parameter.kmd#has_design_parameter")
    set hasFpType           = metis.findType("http://xml.chalmers.se/class/has_functional_requirement_parameter.kmd#has_functional_requirement_parameter")
    set hasPpType           = metis.findType("http://xml.chalmers.se/class/has_performance_parameter.kmd#has_performance_parameter")
    set hasVpType           = metis.findType("http://xml.chalmers.se/class/has_variant_parameter.kmd#has_variant_parameter")

    set rels = paramObj.neighbourRelationships
    for each rel2 in rels
        if rel2.target.uri = paramObj.uri then
            select case rel2.type.uri
            case hasCpType.uri
                set parentObj = rel2.origin
            case hasDpType.uri
                set parentObj = rel2.origin
            case hasFpType.uri
                set parentObj = rel2.origin
            case hasPpType.uri
                set parentObj = rel2.origin
            case hasVpType.uri
                set parentObj = rel2.origin
            end select
            if isEnabled(parentObj) then
                getParameterParentName = parentObj.title
            end if
        end if
    next
end function

