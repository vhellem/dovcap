    if isEnabled(Global_Context.Info) then
        call buildPropertyViews(Global_Context.Info)
    end if

    private sub buildPropertyViews(obj)

        dim propList, prop, propView, rel, rels

        ' Find local properties
        set propList = metis.newInstanceList
        set rels = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasProperty, 0)
        for each rel in rels
            set prop = rel.target
            if prop.type.uri = GLOBAL_Type_EkaPropertyView.uri then
                ' Remove old views
                call prop.ownerModel.deleteObject(prop)
            end if
        next
        set rels = Global_InformationManager.getAllNeighbours(obj, "", GLOBAL_Type_EkaHasProperty, 0)
        for each rel in rels
            set prop = rel.target
            if not instanceByNameInList(prop, propList) then
                if not isParamValue(prop) then
                    ' Create property view object
                    set propView = copyToPropertyView(obj, prop)
                    call propList.addLast(propView)
                end if
            end if
        next
        call addInheritedProps(obj, obj, propList)
    end sub

    private sub addInheritedProps(obj, parentobj, propList)
        dim baseobj, baseobjects
        dim rel, rels
        dim prop, propView

        ' Find inherited properties
        set baseobjects = Global_InformationManager.getAllNeighbours(parentobj, "", GLOBAL_Type_EkaIs, 0)
        for each baseobj in baseobjects
            set baseobj = baseobj.target
            set rels = Global_InformationManager.getAllNeighbours(baseobj, "", GLOBAL_Type_EkaHasProperty, 0)
            for each rel in rels
                set prop = rel.target
                if prop.type.uri = GLOBAL_Type_EkaPropertyView.uri then
                    ' Remove old views
                    call prop.ownerModel.deleteObject(prop)
                end if
            next
            set rels = Global_InformationManager.getAllNeighbours(baseobj, "", GLOBAL_Type_EkaHasProperty, 0)
            for each rel in rels
                set prop = rel.target
                if not instanceByNameInList(prop, propList) then
                    if not isParamValue(prop) then
                        ' Create property view object
                        set propView = copyToPropertyView(obj, prop)
                        call propList.addLast(propView)
                    end if
                end if
            next
            call addInheritedProps(obj, baseobj, propList)
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
        dim propView, propRel, paramName, strval

        ' Create property view object
        set propView = obj.newPart(GLOBAL_Type_EkaPropertyView)
        call copyPropertyValues(prop, propView)
        ' Connect hasProperty relationship to the new object
        set propRel = obj.ownerModel.newRelationship(GLOBAL_Type_EkaHasProperty, obj, propView)
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
    end function

