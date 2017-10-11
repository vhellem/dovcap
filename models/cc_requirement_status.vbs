


    Public Function getRequirementStatus(reqType)
        dim prop, properties
        dim typeProp, typeProperties
        dim ival


        ' Current object = CC requirement
        ' Input parameters are: reqType
        
        ' Get the properties
        set properties = currentObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        set typeProps  = reqType.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each prop in properties
            for each typeProp in typeProps
                if typeProp.title = prop.title
                    status = isAllowedValue(prop, typeProp)
                end if
            next
        next
    End Function

    Private Function isAllowedValue(prop, typeProp)             ' -1 = Undefined,  0 = Not within range,    1 = Within range
        dim propValue, propMinValue, propMaxValue
        dim typePropValue, typePropMinValue, typePropMaxValue

        isAllowedValue = -1

        propValue = getValue(prop, "")
        typePropValue = getValue(typeProp, "")
        if Len(propValue) > 0 then
            if Len(typePropValue) > 0 then
                if propValue = typePropValue then
                    isAllowedValue = 1
                else
                    isAllowedValue = 0
                end if
                exit function
            end if
        end if

        if Len(propValue) = 0 then
            propMinValue = getValue(prop, "Minimum")
            propMaxValue = getValue(prop, "Maximum")
            if propMinValue = -9999 and propMaxValue = -9999 then
                isAllowedValue = -1
                exit function
            end if
        end if
        if Len(typePropValue) = 0 then
            typePropMinValue = getValue(typeProp, "Minimum")
            typePropMaxValue = getValue(typeProp, "Maximum")
        end if
        isAllowedValue = 0

        if propMinValue >= typePropMinValue then
            if propMaxValue = -9999 then
                isAllowedValue = 1
            elseif propMaxValue <= typePropMaxValue then
                ' Within range
                isAllowedValue = 1
            end if
        end if
    End Function
    

    Private Function getValue(prop, paramName)
        dim parameter, parameters
        dim sval
    
        if Len(paramName) > 0 then
            set parameters = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
            for each parameter in parameters
                if parameter.title = paramName then
                    sval = parameter.getNamedStringValue("value")
                    if Len(sval) = 0 then
                        sval = -9999
                    elseif isNumber(sval) then
                        getValue = CDbl(sval)
                    else
                        getValue = sval
                    end if
                    exit for
                end if
            next
        else
            getValue = parameter.getNamedStringValue("value")
        end if
    End Function

