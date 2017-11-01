    dim col, queries, query, s
    dim i, inst, instances
    dim current, worksOn
    dim appliesType
    dim rel, rels
    dim isNew

    isNew = false
    set rels = Global_InformationManager.getAllNeighbours(Global_Context.Task, "", Global_Context.TIType, 0)
    if rels.count = 0 then
        set appliesType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/applies_view.kmd#IRTV:Applies")
        set current = metis.currentModel.currentInstance
        set queries = Global_InformationManager.getAllNeighbours(current, "", appliesType, 0)
        for each query in queries
            dim scope
            set scope = query.target
            set col = metis.newInstanceList

		    if isEnabled (scope) then
		       set instances = Global_ViewManager.selectScope(scope, col)
            end if
            if instances.count > 0 then
                set Global_Context.Infos = metis.newInstanceList
                set inst = instances(1)
                set Global_Context.Info = inst
            end if
            for each i in instances
                call  Global_Context.model.newRelationship(Global_Context.TIType, Global_Context.Task, i)
                call  Global_Context.Infos.addLast(i)
            next
            isNew = true
            exit for
        next
    else
        set rel = rels(1)
        set inst = rel.target
    end if
    if isEnabled(inst) then
        call buildPropertyViews(inst)
        if isNew then call buildPropertyViews(inst)
    end if
    
    private sub buildPropertyViews(obj)
        dim rel, rels

        ' Find local properties
        set rels = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasProperty, 0)
        for each rel in rels
            dim prop, propView
            set prop = rel.target
            if not isParamValue(prop) then
                if prop.type.uri = GLOBAL_Type_EkaProperty.uri then
                    set propView = copyToPropertyView(obj, prop)
                end if
            else
                dim propArray, propName, paramName, strval
                dim r, relships
'stop
                propArray = Split(prop.title, ".", -1, 1)
                propName  = propArray(0)
                paramName = propArray(1)
                ' Find property view object

                set relships = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasProperty, 0)
                for each r in relships
                    set propView = r.target
                    if propView.type.uri = GLOBAL_Type_EkaPropertyView.uri then
                        if propView.title = propName then
                            select case paramName
                            case "Minimum"
                                strval = prop.getNamedStringValue("value")
                                if Len(strval) > 0 then call propView.setNamedStringValue("minval", strval)
                            case "Maximum"
                                strval = prop.getNamedStringValue("value")
                                if Len(strval) > 0 then call propView.setNamedStringValue("maxval", strval)
                            case "Nominal"
                                strval = prop.getNamedStringValue("value")
                                if Len(strval) > 0 then call propView.setNamedStringValue("value", strval)
                            case "Tolerance"
                                strval = prop.getNamedStringValue("value")
                                if Len(strval) > 0 then call propView.setNamedStringValue("tolerance", strval)
                            end select
                        end if
                    end if
                next
            end if
        next
    end sub

    private function isParamValue(prop)
        if InStr(1, prop.title, ".") > 0 then isParamValue = true else isParamValue = false
    end function

    private function getParamValue(obj, paramName)
        dim rel, rels, param
        set rels = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasProperty, 0)
        for each rel in rels
            set param = rel.target
            if param.title = paramName then
                getParamValue = param.getNamedStringValue("value")
                exit function
            end if
        next
    end function

    private function copyToPropertyView(obj, prop)
        dim propView, paramName, strval
        dim rel, rels

        ' Find property view object
        set rels = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasProperty, 0)
        for each rel in rels
            set propView = rel.target
            if propView.type.uri = GLOBAL_Type_EkaPropertyView.uri then
                if propView.title = prop.title then
                    call copyPropValues(prop, propView)
'stop
                    ' Check for parameters
                    paramName = prop.title & ".Minimum"
                    strval = getParamValue(obj, paramName)
                    if Len(strval) > 0 then call propView.setNamedStringValue("minval", strval)
                    paramName = prop.title & ".Maximum"
                    strval = getParamValue(obj, paramName)
                    if Len(strval) > 0 then call propView.setNamedStringValue("maxval", strval)
                    paramName = prop.title & ".Nominal"
                    strval = getParamValue(obj, paramName)
                    if Len(strval) > 0 then call propView.setNamedStringValue("value", strval)
                    paramName = prop.title & ".Tolerance"
                    strval = getParamValue(obj, paramName)
                    if Len(strval) > 0 then call propView.setNamedStringValue("tolerance", strval)
                    set copyToPropertyView = propView
                    exit for
                end if
            end if
        next
    end function

    private sub copyPropValues(prop1, prop2)
        dim val1, val2

        val1 = prop1.getNamedStringValue("value")
        val2 = prop2.getNamedStringValue("value")
        if val1 <> val2 then
            call prop2.setNamedStringValue("value", val1)
        end if
    end sub

