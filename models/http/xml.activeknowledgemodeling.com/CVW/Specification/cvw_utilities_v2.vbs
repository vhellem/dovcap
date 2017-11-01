option explicit

'---------------------------------------------------------------------------------------------------
    function isEnabled(inst)
        on error resume next
        isEnabled = true
        if isEmpty(inst) then
            isEnabled = false
        elseif isNull(inst) then
            isEnabled = false
        elseif inst is Nothing then
            isEnabled = false
        elseif not inst.isValid then
            isEnabled = false
        end if
    end function

'---------------------------------------------------------------------------------------------------
    function isValid(inst)
        isValid = true
        if isEmpty(inst) then
            isValid = false
        elseif isNull(inst) then
            isValid = false
        elseif inst is Nothing then
            isValid = false
        end if
    end function

'---------------------------------------------------------------------------------------------------
    function hasInstance(instView)
        hasInstance = false
        if isValid(instView) then
            if instView.hasInstance then
                hasInstance = true
            end if
        end if
    end function

'---------------------------------------------------------------------------------------------------
    function instanceInList(instance, list)
		dim item

        if not isValid(list) then
            instanceInList = true
		else
            instanceInList = false
            for each item in list
                if instance.uri = item.uri then instanceInList = true
		    next
		end if
    end function

'---------------------------------------------------------------------------------------------------
    function instanceByNameInList(instance, list)
        dim item

        if not isValid(list) then
            instanceByNameInList = true
		else
            instanceByNameInList = false
            for each item in list
                if instance.name = item.name then instanceByNameInList = true
            next
        end if
    end function

'---------------------------------------------------------------------------------------------------
    function instancesInModel(instances, model)
        dim inst
        dim i, removed

        set instancesInModel = Nothing
        if isValid(instances) then
            ' If not in model, remove from list
            i = 1
            for each inst in instances
                removed = false
                if inst.ownerModel.uri <> model.uri then
                    instances.removeAt(i)
                    removed = true
                end if
                if not removed then
                    i = i + 1
                end if
            next
            set instancesInModel = instances
        end if
    end function

'---------------------------------------------------------------------------------------------------
    Function getWorkareaLabelText
        dim currentInstance
        dim title

        getWorkareaLabelText = ""

        set currentInstance = metis.currentModel.currentInstance

        if isEnabled(currentInstance) then
            title = currentInstance.title
            if InStr(title, "WorkArea_[") = 0 then
                getWorkareaLabelText = title
            end if
        end if
    End Function

'---------------------------------------------------------------------------------------------------
    Function relocate(inst, modelObject, instView)
        set relocate = inst
        if inst.parent.uri <> modelObject.uri then
            set relocate = modelObject.newPart(inst.type)
            call copyPropertyValues(inst, relocate)
            call instView.setInstance(relocate)
            model.deleteObject(inst)
        end if
    End Function

'---------------------------------------------------------------------------------------------------
    sub copyPropertyValues(fromInstance, toInstance)
        dim prop, properties
        dim value

        if isEnabled(fromInstance) and isEnabled(toInstance) then
            set properties = fromInstance.type.allProperties
            for each prop in properties
                on error resume next
                set value = fromInstance.getValue(prop)
                call toInstance.setValue(prop, value)
            next
        end if
    end sub

'---------------------------------------------------------------------------------------------------
    function findParts(contextModel, parentObj, instType, propName, propValue)
        dim part, parts
        dim part2, parts2
        dim subParts
        dim hasConstraint
        dim i, removed

        set findParts = Nothing
        set subParts = metis.newInstanceList
        hasConstraint = false
        if Len(propName) > 0 and Len(propValue) > 0 then
            hasConstraint = true
        end if
        if isEnabled(parentObj) then
            set parts = parentObj.parts
            i = 1
            for each part in parts
                removed = false
                if part.ownerModel.uri = contextModel.uri then
                    if part.isObject then
                        set parts2 = findParts(contextModel, part, instType, propName, propValue)
                        for each part2 in parts2
                            subParts.addLast part2
                        next
                        if part.type.inherits(instType) then
                            if hasConstraint then
                                sval = part.getNamedStringValue(propName)
                                if not sval = propValue then
                                    if sval = "true" then sval = "1"
                                    elseif sval = "false" then sval = "0"
                                end if
                                if not sval = propValue then
                                    parts.removeAt(i)
                                    removed = true
                                end if
                            end if
                        else
                            parts.removeAt(i)
                            removed = true
                        end if
                    else
                        parts.removeAt(i)
                        removed = true
                    end if
                    if not removed then i = i + 1
                else
                    parts.removeAt(i)
                    removed = true
                end if
            next
            for each part in subParts
                parts.addLast part
            next
            set findParts = parts
        end if
    end function

'---------------------------------------------------------------------------------------------------
    function isInView(instView, containerView)
        dim parentView
        dim found

        isInView = false
        if isEnabled(instView) and isEnabled(containerView) then
            set parentView = instView.parent
            if isEnabled(parentView) then
                if parentView.uri = containerView.uri then
                    isInView = true
                else
                    found = isInView(parentView, containerView)
                    if found then isInView = true
                end if
            end if
        end if

    end function

'---------------------------------------------------------------------------------------------------
    function viewExists(inst, parentView)
        dim v, view, views

        set viewExists = Nothing
        set views = inst.views
        for each view in views
            if isInView(view, parentView) then
                set viewExists = view
                exit for
            end if
        next
    end function

'---------------------------------------------------------------------------------------------------
    function relViewExists(rel, fromObjView, toObjView)
        dim relView, views

        set relViewExists = Nothing
        set views = rel.views
        for each relView in views
            if relView.origin.uri = fromObjView.uri then
                if relView.target.uri = toObjView.uri then
                    set relViewExists = relView
                end if
            end if
        next
    end function

'---------------------------------------------------------------------------------------------------
    function findInstanceView(model, objectType, propertyName, propertyValue)
        dim insts, inst, views

        set findInstanceView = Nothing
        set insts = model.findInstances(objectType, propertyName, propertyValue)
        for each inst in insts
            if isEnabled(inst) then
                set views = inst.views
                if views.count > 0 then
                    set findInstanceView =  views(1)
                    exit for
                end if
            end if
        next
    end function

'---------------------------------------------------------------------------------------------------
function findWorkWindow(instView)
    dim windowType, window2Type
    dim parentView, parentType
    dim instType

    set findWorkWindow = Nothing
    set windowType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
    set window2Type    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea2_UUID")

    if isEnabled(instView) then
        set instType = instView.instance.type
        if instType.uri = windowType.uri or instType.uri = window2Type.uri then
            set findWorkWindow = instView.instance
            exit function
        end if
        set parentView = instView.parent
        if hasInstance(parentView) then
            set parentType = parentView.instance.type
            if parentType.uri = windowType.uri or parentType.uri = window2Type.uri then
                set findWorkWindow = parentView.instance
            else
                set findWorkWindow = findWorkWindow(parentView)
            end if
        end if
    end if
end function

'---------------------------------------------------------------------------------------------------
function findWorkWindowView(instView)
    dim windowType, window2Type
    dim parentView, parentType
    dim instType

    set findWorkWindowView = Nothing
    set windowType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
    set window2Type    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea2_UUID")

    if isEnabled(instView) then
        set instType = instView.instance.type
        if instType.uri = windowType.uri or instType.uri = window2Type.uri then
            set findWorkWindowView = instView
            exit function
        end if
        set parentView = instView.parent
        if hasInstance(parentView) then
            set parentType = parentView.instance.type
            if parentType.uri = windowType.uri or parentType.uri = window2Type.uri then
                set findWorkWindowView = parentView
            else
                set findWorkWindowView = findWorkWindowView(parentView)
            end if
        end if
    end if
end function

'---------------------------------------------------------------------------------------------------
    function buildRelRules(obj1, list, noList, excludeRelTypeList, noRelTypes)
        dim obj2, rel, rels
        dim relDir
        dim type1, type2, relType, excludeRelType
        dim cvwRule, isTopType
        dim i, exclude

        buildRelRules = false

        if isEnabled(obj1) then
            set rels = obj1.neighbourRelationships
            for each rel in rels
                if isEnabled(rel) then
                    exclude = false
                    for i = 1 to noRelTypes
                        set excludeRelType = excludeRelTypeList(i)
                        if isEnabled(excludeRelType) then
                            if excludeRelType.uri = rel.type.uri then
                                exclude = true
                                exit for
                            end if
                        end if
                    next
                    if not exclude then
                        call buildRelRule(rel, obj1, list, noList, excludeRelTypeList, noRelTypes)
                        buildRelRules = true
                    end if
                end if
            next
        end if
    end function

'-----------------------------------------------------------
    sub buildInstRules(inst, list, noList, hasConstraintType)
        dim instType
        dim rel, relships, prop
        dim operator, propName, propValue
        dim operatorProp, valueProp
        dim cvwRule

        if isEnabled(inst) then
            operatorProp = "operator"
            valueProp    = "value"
            set instType = inst.type
            set relships = inst.getNeighbourRelationships(0, hasConstraintType)
            if relships.count = 0 then
                set cvwRule = new CVW_InstRule
                set cvwRule.instType = instType
                cvwRule.title     = instType.title
                cvwRule.propname  = ""
                cvwRule.operator  = ""
                cvwRule.propValue = ""
                call addRuleToList(cvwRule, list, noList)
                exit sub
            end if
            for each rel in relships
                if isEnabled(rel) then
                    operator = rel.getNamedStringValue(operatorProp)
                    set prop = rel.target
                    if isEnabled(prop) then
                        propName = prop.name
                        propValue = prop.getNamedStringValue(valueProp)
                        set cvwRule = new CVW_InstRule
                        set cvwRule.instType = instType
                        cvwRule.title = instType.title & "_has_" & propName & "_" & operator & "_" & propValue
                        cvwRule.propname  = propName
                        cvwRule.operator  = operator
                        cvwRule.propvalue = propValue
                        call addRuleToList(cvwRule, list, noList)
                    end if
                end if
            next
        end if
    end sub

'-----------------------------------------------------------
    sub buildRelRule(rel, obj1, list, noList, excludeRelTypeList, noRelTypes)
        dim relType, relDir
        dim type1, type2, excludeRelType
        dim obj2, rel2, rels
        dim i, exclude
        dim cvwRule

        set relType = rel.type
        if rel.origin.uri = obj1.uri then
            relDir = 0
            set type1 = obj1.type
            set obj2 = rel.target
            set type2 = obj2.type
        elseif rel.target.uri = obj1.uri then
            relDir = 1
            set type1 = obj1.type
            set obj2 = rel.origin
            set type2 = obj2.type
        end if
        set cvwRule = new CVW_RelRule
        cvwRule.title = type1.title & "_" & relType.title & "_" & type2.title
        set cvwRule.parentType = type1
        set cvwRule.relType = relType
        set cvwRule.childType = type2
        cvwRule.relDir = relDir
        call addRuleToList(cvwRule, list, noList)
        
        set rels = obj2.neighbourRelationships
        for each rel2 in rels
            if isEnabled(rel2) then
                exclude = false
                for i = 1 to noRelTypes
                    if rel2.uri = rel.uri then
                        exclude = true
                        exit for
                    end if
                    set excludeRelType = excludeRelTypeList(i)
                    if isEnabled(excludeRelType) then
                        if excludeRelType.uri = rel2.type.uri then
                            exclude = true
                            exit for
                        end if
                    end if
                next
                if not exclude then
                    if not ruleInList(rel2, list, noList) then
                        call buildRelRule(rel2, obj2, list, noList, excludeRelTypeList, noRelTypes)
                    end if
                end if
            end if
        next
    end sub

'-----------------------------------------------------------
    Function ruleInList(rel, list, noList)
        dim rule
        dim indx, found
        dim type1, type2, relType
        dim title

        ruleInList = false
        set relType = rel.type
        set type1   = rel.origin.type
        set type2   = rel.target.type
        title = type1.title & "_" & relType.title & "_" & type2.title
        for indx = 1 to noList
            set rule = list(indx)
            if isValid(rule) then
                if title = rule.title then
                    ruleInList = true
                    exit for
                end if
            end if
        next
    End Function

'-----------------------------------------------------------
    Sub addRuleToList(cvwRule, list, noList)
        dim rule
        dim indx, found

        found = false
        for indx = 1 to noList
            set rule = list(indx)
            if isValid(rule) then
                if cvwRule.title = rule.title then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noList = noList + 1
            ReDim Preserve list(noList)
            set list(noList) = cvwRule
        end if
    End Sub

'---------------------------------------------------------------------------------------------------
    sub generateTree(sourceNodeView, targetNodeView, hasNodeType, nodeType, textScale, scaleFactor)    ' textScale = 0.05, scaleFactor = 1.3
        dim  node, itemView, newItemView

        if not (hasInstance(sourceNodeView) and isEnabled(nodeType) and isEnabled(hasNodeType)) then
            exit sub
        end if

        set node = sourceNodeView.instance
        For each itemView in node.getNeighbourRelationships(0, hasNodeType)
            set newItemView             = targetNodeView.newObjectView(itemView.target)
            newItemView.openSymbol      = itemView.target.Views(1).openSymbol
            newItemView.closedSymbol    = itemView.target.Views(1).closedSymbol
            newItemView.textScale       = textScale
            newItemView.geometry.width  = newItemView.parent.geometry.width * scaleFactor
            newItemView.geometry.height = newItemView.parent.geometry.height * scaleFactor
            newItemView.close
            newItemView.parent.open
        next
    end sub
'----------------------------------------------------------------------------------------------------------------------

    sub cleanTree(modelView, nodeView)
        dim  itemView

        for each itemView in nodeView.children
            call modelView.deleteObjectView(itemView)
        next

    end sub

   '---------------------------------------------------------------------------------------------------
    Function getInstModel(contextMode, modelName)
        dim model, connector
        dim child, children
        dim part, parts
        dim m, modelView, modelViews

        set getInstModel = Nothing
        set model = getCVWmodel
        select case contextMode
        case "CurrentModel"
            set getInstModel = model
        case "SubModel"
            set connector = Nothing
            set modelViews = model.views
            for each modelView in modelViews
                set children = modelView.children
                for each child in children
                    if child.isConnector then
                        set connector = child
                        set children = connector.children
                        if children.count > 0 then
                            set child = children(1)
                            set parts = child.instance.parts
                            for each part in parts
                                if isEnabled(part) then
                                    set m = part.ownerModel
                                    if Len(modelName) > 0 then
                                        if m.title = modelName then
                                            set getInstModel = part.ownerModel
                                            exit for
                                        end if
                                    else
                                        set getInstModel = m
                                        exit for
                                    end if
                                end if
                            next
                        end if
                        if isEnabled(getInstModel) then
                            exit for
                        end if
                    end if
                next
                if isEnabled(getInstModel) then
                    exit for
                end if
            next
        end select
    End Function

   '---------------------------------------------------------------------------------------------------
    Function findInstModel(modelContext, modelViewName)
        dim model, connector
        dim child, children
        dim part, parts
        dim m, modelView, modelViews

        set findInstModel = Nothing
        set model = getCVWmodel
        select case modelContext
        case "CurrentModel"
            set findInstModel = model
        case "SubModel"
            set connector = Nothing
            set modelViews = getCVWmodel.views
            for each modelView in modelViews
                if modelView.title = modelViewName then
                    set children = modelView.children
                    for each child in children
                        if child.isConnector then
                            set connector = child
                            set children = connector.children
                            if children.count > 0 then
                                set child = children(1)
                                set parts = child.instance.parts
                                for each part in parts
                                    if isEnabled(part) then
                                        set m = part.ownerModel
                                        set findInstModel = m
                                        exit for
                                    end if
                                next
                            end if
                            if isEnabled(findInstModel) then
                                exit for
                            end if
                        end if
                    next
                    exit for
                end if
            next
        end select
    End Function

   '---------------------------------------------------------------------------------------------------
    Function getCVWmodel
        dim model, modelView
        dim child, children
        dim part

        set model = metis.currentModel
        set modelView = model.currentModelView

        set getCVWmodel = model

        if isEnabled(modelView) then
            ' Find CVW model
            set children = modelView.children
            if children.count > 0 then
                for each child in children
                    if hasInstance(child) then
                        set part = child.instance
                        if isEnabled(part) then
                            set getCVWmodel = part.ownerModel
                            exit for
                        end if
                    end if
                next
            end if
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Sub resetCVWcomponent(component)
        dim prop, properties
        dim hasPropertyType, propertyType

        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")

        set properties = component.getNeighbourObjects(0, hasPropertyType, propertyType)
        for each prop in properties
            on error resume next
            propValue = prop.getNamedStringValue("value")
            call prop.setNamedStringValue("tempvalue", propValue)
        next
    End Sub

   '---------------------------------------------------------------------------------------------------
    Sub configureCVWcomponent(configuringObject, component, useConfiguredValue)
        dim compProp, configProp
        dim compProps, configProps
        dim spec, specs
        dim rel, relships
        dim hasPropertyType, hasValueType, propertyType, compType, specContainerType
        dim propValue, checkEquals

        set compType        = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")
        set propertyType    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set hasPropertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasProperty_UUID")
        set hasValueType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set specContainerType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")

        if configuringObject.type.uri <> compType.uri then
            checkEquals = true
        else
            checkEquals = false
        end if
        set compProps   = component.getNeighbourObjects(0, hasPropertyType, propertyType)
        set ekaInstance = new EKA_Instance
        set ekaInstance.Instance = configuringObject
        set configProps = ekaInstance.Properties
        'set configProps = configuringObject.getNeighbourObjects(0, hasPropertyType, propertyType)
        for each compProp in compProps
            set configProp = getConfiguringProperty(configProps, compProp, checkEquals)
            if isEnabled(configProp) then
                ' Check for has value references
                set relships = configProp.getNeighbourRelationships(0, hasValueType)
                if relships.count > 0 then
                    for each rel in relships
                        if isEnabled(rel) then
                            call compProp.setNamedStringValue("tempvalue", rel.target.uri)
                            exit for
                        end if
                    next
                else
                    if useConfiguredValue then
                        propValue = configProp.getNamedStringValue("tempvalue")
                    else
                        propValue = configProp.getNamedStringValue("value")
                    end if
                    if Len(propValue) > 0 then
                        call compProp.setNamedStringValue("tempvalue", propValue)
                    end if
                end if
            end if
        next
    End Sub

   '---------------------------------------------------------------------------------------------------
    Function getConfiguringProperty(configProps, compProp, checkEquals)
        dim equalsType, propertyType
        dim equalProps
        dim prop, configProp

        set getConfiguringProperty = Nothing

        set equalsType   = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:Equals_UUID")
        set propertyType = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")

        set equalProps = compProp.getNeighbourObjects(0, equalsType, propertyType)
        for each prop in equalProps
            for each configProp in configProps
                if prop.uri = configProp.uri then
                    set getConfiguringProperty = configProp
                    exit for
                end if
            next
        next
        if not isEnabled(getConfiguringProperty) and checkEquals then
            for each configProp in configProps
                if compProp.title = configProp.title then
                    set getConfiguringProperty = configProp
                    exit for
                end if
            next
        end if
    End Function

   '---------------------------------------------------------------------------------------------------
    Function findCVWcomponent(inst, componentName)
        dim uses1Type, uses2Type, compType
        dim comp, components
        dim found

        set findCVWcomponent = Nothing

        set compType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_objects.kmd#ObjType_CVW:CVW_Component_UUID")
        set usesType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:usesComponent_UUID")
        set uses2Type = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:uses2Component_UUID")

        found = false
        if isEnabled(inst) then
            if inst.type.uri = compType.uri then
                set components = inst.getNeighbourObjects(0, usesType, compType)
                for each comp in components
                    if isEnabled(comp) then
                        if comp.title = componentName then
                            set findCVWcomponent = comp
                            found = true
                            exit for
                        end if
                    end if
                next
            end if
            if not found then
                set components = inst.getNeighbourObjects(0, uses2Type, compType)
                for each comp in components
                    if isEnabled(comp) then
                        if comp.title = componentName then
                            set findCVWcomponent = comp
                            found = true
                            exit for
                        end if
                    end if
                next
            end if
        end if
    End Function


