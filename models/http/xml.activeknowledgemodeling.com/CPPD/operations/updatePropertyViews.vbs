    option explicit

'stop
    dim model, modelView, inst, instView
    dim propList

    set model = metis.currentModel
    set modelView = model.currentModelView
    if isValid(modelView) then
        set instView = modelView.currentInstanceView
        if hasInstance(instView) then
            set inst = instView.instance
        else
'stop
            dim workView
            on error resume next
            set inst = model.currentInstance
            set workView = modelView.children(1).children(3).children(1).children(2)
            if isValid(workView) then
                dim v
                for each v in workView.children
                    if v.instance.uri = inst.getNamedStringValue("externalID") then
                        set instView = v
                        exit for
                    end if
                next
            end if
        end if
'stop
        if isValid(instView) then
            call updatePropertyViews(instView)
        end if
    end if
    ' End

    private sub updatePropertyViews(objView)
        dim obj, rel, rels

        set obj = objView.instance
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


