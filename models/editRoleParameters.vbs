option explicit

Public Sub editRoleParameters(model, ccObj, inst, roleName, method)
    dim rule, rules
    dim expression, expressions
    dim param, params
    dim prop, props
    dim roleRule
    dim argName
    dim i

    if not isValid(model)   then exit sub
    if not isEnabled(ccObj) then exit sub
    if not isEnabled(inst)  then exit sub
    if not isValid(method)  then exit sub

    if Len(roleName) = 0 then
        call model.runMethodOnInst(method, inst)
        exit sub
    end if

    roleRule = "Parameters(" & roleName & ")"
    'Find the role specific parameters
    set rules = contextInst.getNeighbourObjects(0, GLOBAL_Type_invokes, GLOBAL_Type_Rule)
    for each rule in rules
        if rule.title = roleRule then
            ' Find expression object
            set expressions = rule.getNeighbourObjects(0, GLOBAL_Type_hasExpr, GLOBAL_Type_Expr)
            for each expression in expressions
                exit for
            next
            if isEnabled(currentInst) and isEnabled(expression) then
                i = 0
                ' Find the input parameters and process them
                set params = expression.getNeighbourObjects(1, GLOBAL_Type_inputToExpr1,GLOBAL_Type_CCParam)
                set props  = currentInst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
                for each prop in props
                    for each param in params
                        if param.title = prop.title then
                            ' Then what??
                            i = i + 1
                            argName = "PropertyObject" & CStr(i)
                            call method.setArgument1(argName, prop.uri)
                            exit for
                        end if
                    next
                next
                set paramRels = expression.getNeighbourRelationships(0, GLOBAL_Type_outputFromExpr)
                set params = expression.getNeighbourObjects(0, GLOBAL_Type_outputFromExpr,GLOBAL_Type_CCParam)
                set props  = currentInst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
                for each prop in props
                    dim paramRel, paramRels

                    for each paramRel in paramRels
                        set param = paramRel.target
                        if param.title = prop.title then
                            dim param1, params1
                            dim isReadOnly
                            
                            isReadOnly = paramRel.getNamedStringValue("paramId") = "isReadOnly"
                            if not isReadOnly then
                                ' Clear property value
                                set params1 = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
                                for each param1 in params1
                                    call param1.setNamedStringValue("value", "")
                                next
                                call prop.setNamedStringValue("value", "")
                            end if
                            exit for
                        end if
                    next
                next
                call model.runMethodOnInst(method, currentInst)
            end if
        end if
    next
End Sub

