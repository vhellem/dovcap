option explicit

Class CVW_ArgumentValue

    Private argType
    Private argsType
    Private propertyType
    Private hasArgType
    Private hasArg2Type
    Private hasArgsType
    Private hasPropertyType
    Private valueProperty
    Private datatypeProperty
   '---------------------------------------------------------------------------------------------------
    Public Function findArgument(inst, argName)
        dim argument, arguments, group, groups
        dim found

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

        getArgumentValue = ""
        set argument = findArgument(inst, argName)
        if isEnabled(argument) then
            getArgumentValue = argument.getNamedStringValue(valueProperty)
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
        valueProperty       = "value"
        datatypeProperty    = "datatype"
    End Sub
   '---------------------------------------------------------------------------------------------------

End Class


