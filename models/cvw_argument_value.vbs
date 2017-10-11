option explicit

Class CVW_ArgumentValue

    Private argType
    Private argsType
    Private propertyType
    Private equalsType
    Private hasArgType
    Private hasArg2Type
    Private hasArgsType
    Private hasPropertyType
    Private valueProperty
    Private tempValueProperty
    Private datatypeProperty
    Private buttonType
    Private isType
    Private hasValueType

   '---------------------------------------------------------------------------------------------------
    Public Function findArgument(inst, argName)
        dim argument, arguments, group, groups
        dim parent, parents
        dim found
        on error resume next

        set findArgument = Nothing
        found = false
        set arguments = inst.getNeighbourObjects(0, hasPropertyType, propertyType)
        for each argument in arguments
            if argument.name = argName then
                set findArgument = argument
                found = true
                exit for
            end if
        next
        if not found then
            ' Check if property has properties
            set groups = inst.getNeighbourObjects(0, hasPropertyType, propertyType)
            for each group in groups
                set arguments = group.getNeighbourObjects(0, hasPropertyType, propertyType)
                for each argument in arguments
                    if argument.name = argName then
                        set findArgument = argument
                        found = true
                        exit for
                    end if
                next
            next
        end if
        if not found then
            ' Check if action inherits from other actions
            set parents = inst.getNeighbourObjects(0, isType, buttonType)
            for each parent in parents
                if isEnabled(parent) then
                    set findArgument = findArgument(parent, argName)
                    if isEnabled(findArgument) then
                        found = true
                        exit for
                    end if
                end if
            next
        end if
        if not found then
            set arguments = inst.getNeighbourObjects(0, hasArgType, argType)
            for each argument in arguments
                if argument.name = argName then
                    set findArgument = argument
                    found = true
                    exit for
                end if
            next
        end if
        if not found then
            ' Check if argument groups
            set groups = inst.getNeighbourObjects(0, hasArgsType, argsType)
            for each group in groups
                set arguments = group.getNeighbourObjects(0, hasArg2Type, argType)
                for each argument in arguments
                    if argument.name = argName then
                        set findArgument = argument
                        found = true
                        exit for
                    end if
                next
            next
        end if
        if not found then
            set arguments = inst.parts
            for each argument in arguments
                if isEnabled(argument) then
                    if argument.type.uri = argType.uri then
                        if argument.name = argName then
                            set findArgument = argument
                            found = true
                            exit for
                        end if
                    end if
                end if
            next
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Public Function getArgumentValue(inst, argName)
        dim argument, arguments
        dim rel, relships

        getArgumentValue = ""
        set argument = findArgument(inst, argName)
        if isEnabled(argument) then

            ' Check for has value references
            set relships = argument.getNeighbourRelationships(0, hasValueType)
            if relships.count > 0 then
                for each rel in relships
                    if isEnabled(rel) then
                        getArgumentValue = rel.target.uri
                        exit for
                    end if
                next
            else
                getArgumentValue = argument.getNamedStringValue(valueProperty)
            end if
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Public Function getConfiguredValue(inst, argName)
        dim argument, arguments

        getConfiguredValue = ""
        set argument = findArgument(inst, argName)
        if isEnabled(argument) then
            getConfiguredValue = argument.getNamedStringValue(tempValueProperty)
            if Len(getConfiguredValue) = 0 then
                getConfiguredValue = argument.getNamedStringValue(valueProperty)
            end if
        end if
    End Function

    '---------------------------------------------------------------------------------------------------
    Public Function getArgValue(component, configObject, argName)
        dim argument, arguments, configArgs
        dim prop, props
        dim obj, objects
        dim spec, specs
        dim found, checkEquals

        getArgValue = ""
        found = false
        if configObject.type.uri <> component.type.uri then
            checkEquals = true
        else
            checkEquals = false
        end if

        set arguments   = component.getNeighbourObjects(0, hasPropertyType, propertyType)
        set configArgs  = configObject.getNeighbourObjects(0, hasPropertyType, propertyType)
        for each argument in arguments
            set prop = getConfiguringProperty(configArgs, argument, checkEquals)
            if isEnabled(prop) then
                ' Check for specification container
                set specs = prop.getNeighbourRelationships(0, hasValueType)
                if specs.count > 0 then
                    for each spec in specs
                        if isEnabled(spec) then
                            getArgValue = spec.uri
                            found = true
                            exit for
                        end if
                    next
                else
                    ' No specification container - just get the value
                    getArgValue = prop.getNamedStringValue(valueProperty)
                    found = true
                end if
                if found then exit for
            end if
        next
        if not found then
            getArgValue = getArgumentValue(component, argName)
        end if
    End Function

    '---------------------------------------------------------------------------------------------------

    Private Sub Class_Initialize
        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        set argType         = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:ActionArgument_UUID")
        set argsType        = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:ActionArguments_UUID")
        set hasArgType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_relships.kmd#RelType_CVW:hasArgument_UUID")
        set hasArg2Type     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_relships.kmd#RelType_CVW:hasArgument2_UUID")
        set hasArgsType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_relships.kmd#RelType_CVW:hasArguments_UUID")
        set buttonType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
        set isType          = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Is_UUID")
        set hasValueType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set equalsType      = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Equals_UUID")
        valueProperty       = "value"
        tempValueProperty   = "tempvalue"
        datatypeProperty    = "datatype"
    End Sub
   '---------------------------------------------------------------------------------------------------

End Class


