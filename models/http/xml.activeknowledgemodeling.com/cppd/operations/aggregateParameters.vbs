on error resume next
dim inst, t, view

set view = getWorkarea(GLOBAL_Context.instview)
set view = view.children(view.children.count)
if view.children.count = 1 then set inst = view.children(1).instance

if not isEnabled(GLOBAL_Context.Infos) then
    set t = getEqualObject(view.instance)
    if isEnabled(t) then
        if view.instance.uri <> t.uri then
            set inst = t
        else
            msgbox "First select the object(s), then click the button."
        end if
    else
        msgbox "First select the object(s), then click the button."
    end if
elseif GLOBAL_Context.Infos.count = 0 then
    if not isEnabled(inst) then
        msgbox "First select the object(s), then click the button."
    end if
else
    for each t in GLOBAL_Context.Infos
        set inst = t
        exit for
    next
end if
if isEnabled(inst) then
    call aggregateParameters(inst)
end if

private sub aggregateParameters(family)
    dim obj, rel, rels, rel2, rels2
    dim constraint, prop, propName, param, paramDef, paramDefList

    ' Find the parameter definitions by first going to the Constraint
    set paramDefList = metis.newInstanceList
    set rels = Global_InformationManager.getAllNeighbours(family, "", GLOBAL_Type_EkaIs, 0)
    if rels.count = 1 then set constraint = rels(1).target
    if isEnabled(constraint) then
        set rels = Global_InformationManager.getAllNeighbours(constraint, "", GLOBAL_Type_EkaHasProperty, 0)
        for each rel in rels
            set prop = rel.target
            set rels2 = Global_InformationManager.getAllNeighbours(prop, "", GLOBAL_Type_EkaHasAggregatedParameter, 0)
            for each rel2 in rels2
                set param = rel2.target
                if not instanceInList(param, paramDefList) then call paramDefList.addLast(param)
            next
        next
    end if
    if paramDefList.count > 0 then
        ' The parameter definitions are found, start the aggregation
        for each paramDef in paramDefList
            propName = getParamName(paramDef)
            if Len(propName) > 0 then
                ' Initialize the aggregate object
                set aggrParam = initAggrParameter(family, propName, paramDef)
                ' Find the family members
                set rels = Global_InformationManager.getAllNeighbours(family, "", GLOBAL_Type_EkaIs, 1)
                for each rel in rels
                    dim member
                    set member = rel.origin
                    ' Then find the properties of this member
                    set rels2 = Global_InformationManager.getAllNeighbours(member, "", GLOBAL_Type_EkaHasProperty, 0)
                    for each rel2 in rels2
                        set prop = rel2.target
                        if prop.title = propName then
                            call addToAggregate(propName, prop, aggrParam)
                            exit for
                        end if
                    next
                next
            end if
        next
    end if
end sub

private sub addToAggregate(propName, valObj, aggrObj)
    dim obj, rel, rels
    dim s1, s2, v1, v2

    set rels = Global_InformationManager.getAllNeighbours(valObj, "", GLOBAL_Type_EkaHasParameter, 0)
    for each rel in rels
        dim param, aggrParam
        set obj = rel.target
        if obj.title = propName then
            ' Check if the property has parameters
            set rels = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasParameter, 0)
            if rels.count > 0 then
                for each rel in rels
                    set param = rel.target
                    set aggrParam = getParameter(aggrObj, param.title)
                next
            else
                set param = valObj
                set aggrParam = aggrObj
            end if
            s1 = param.getNamedStringValue("value")
            s2 = aggrParam.getNamedStringValue("value")
            if isNumeric(s1) then v1 = CDbl(s1) else v1 = 0
            if isNumeric(s2) then v2 = CDbl(s2) else v2 = 0
            v2 = v2 + v1
            s2 = CStr(v2)
            call aggrParam.setNamedStringValue("value", s2)
        end if
    next
end sub

private function initAggrParameter(family, propName, paramDef)
    dim rel, rels
    dim param

    set param = nothing
    set rels = Global_InformationManager.getAllNeighbours(family, "", GLOBAL_Type_EkaHasAggregatedProperty, 0)
    for each rel in rels
        if rel.target.title = propName then set param = rel.target
    next
    if not isValid(param) then
        set param = family.ownerModel.newObject(GLOBAL_Type_EkaProperty)
        if isValid(param) then set rel = family.ownerModel.newRelationship(GLOBAL_Type_EkaHasAggregatedProperty, family, param)
    end if
    call param.setNamedStringValue("value", "")
    set initAggrParameter = param
end function

private function getParamName(param)
    dim p, rels

    set rels = Global_InformationManager.getAllNeighbours(param, "", GLOBAL_Type_EkaHasAggregatedParameter, 1)
    if rels.count = 1 then set p = rels(1).origin
    if isEnabled(p) then getParamName = p.title else getParamName = ""
end function

