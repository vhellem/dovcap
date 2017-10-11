option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_InstanceType

    Public Title
    Public ConfigurableComponent            ' IMetisObject
    Public productType                      ' IMetisType
    Public productInstType                  ' IMetisType
    Public typeModel                        ' IMetisModel
    Public instanceModel                    ' IMetisModel

    ' Types


'-----------------------------------------------------------
    Public Function findInstances(compObj, instTypeName)
        dim instModel, instTypeModel
        dim instanceModel, instanceType
        dim inst, instances
        dim rel
        dim i, removed

        set findInstances = Nothing
        if not isEnabled(compObj) then
            exit function
        end if
        if isValid(typeModel) then
            set instTypeModel = typeModel
        else
            set instTypeModel = findInstanceTypeModel(compObj)
        end if
        if isValid(instanceModel) then
            set instModel = instanceModel
        else
            set instModel = findInstanceModel(compObj, instTypeName)
        end if
        if isEnabled(instTypeModel) and isEnabled(instModel) then
            set instanceType  = findInstanceType(instTypeName, instTypeModel)
            if isEnabled(instanceType) then
                set instances = instModel.parts
                i = 1
                for each inst in instances
                    removed = false
                    if not inst.type.inherits(instanceType.type) then
                        instances.removeAt(i)
                        removed = true
                    else
                        i = i + 1
                    end if
                next
                if instances.count > 0 then set findInstances = instances
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function findInstances2(compObj, instanceType)
        dim instModel, instTypeModel
        dim instType, instTypes
        dim inst, instances
        dim rel
        dim i, removed, found

        set findInstances2 = Nothing
        if isValid(typeModel) then
            set instTypeModel = typeModel
        else
            set instTypeModel = findInstanceTypeModel(compObj)
        end if
        if isValid(instanceModel) then
            set instModel = instanceModel
        else
            set instModel = findInstanceModel(compObj, instTypeName)
        end if
        if isEnabled(instTypeModel) and isEnabled(instModel) then
            if isEnabled(instanceType) then
                set instances = instModel.parts
                i = 1
                for each inst in instances
                    removed = false
                    ' Search by EkaIs
                    set instTypes = inst.getNeighbourObjects(0, GLOBAL_Type_EkaIs, GLOBAL_Type_AnyObject)
                    found = false
                    for each instType in instTypes
                        if instType.uri = instanceType.uri then
                            found = true
                            exit for
                        end if
                    next
                    if not found then
                        instances.removeAt(i)
                        removed = true
                    else
                        i = i + 1
                    end if
                next
                if instances.count > 0 then set findInstances2 = instances
            end if
        end if
    End Function

'-----------------------------------------------------------
    Public Function newInstance(compObj, instanceType, instName, createViewProperties)
        dim contentModel, instTypeModel
        dim instModel
        dim inst, viewInst
        dim symbol, symbols
        dim rel

        set newInstance = Nothing
        if not isEnabled(compObj) then
            exit function
        end if
        if isValid(typeModel) then
            set instTypeModel = typeModel
        else
            set instTypeModel = findInstanceTypeModel(compObj)
        end if
        if isValid(instanceModel) then
            set instModel = instanceModel
        else
            set instModel = findInstanceModel(compObj, instName)
        end if
        set contentModel = instModel.ownerModel   ' instTypeModel.ownerModel
        if isEnabled(instTypeModel) and isEnabled(instModel) then
            if isEnabled(instanceType) then
                set inst = findInstance(instanceType, instName)
                if isEnabled(inst) then
                    set newInstance = inst
                else
                    set inst = instModel.newPart(productInstType)
                    if isEnabled(inst) then
                        inst.title = instName
                        if true then
                            on error resume next
                            set rel = contentModel.newRelationship(GLOBAL_Type_EkaIs, inst, instanceType)
                        end if
                        select case productType.uri
                            case GLOBAL_Type_DS.uri
                                call copySolutionProperties(instanceType, inst, instModel)
                            case GLOBAL_Type_CO.uri
                                call copyConstraintProperties(instanceType, inst, instModel)
                            case else
                                call copyProperties(instanceType, inst, instModel, true)
                        end select
                        set newInstance = inst
                        ' If symbol is connected to type then connect symbol to new instance
                        set symbols = instanceType.getNeighbourObjects(0, GLOBAL_Type_EkaHasSymbol, GLOBAL_Type_EkaSymbol)
                        if symbols.count > 0 then
                            set symbol = symbols(1)
                            set rel    = contentModel.newRelationship(GLOBAL_Type_EkaHasIcon, inst, symbol)
                        end if
                        if createViewProperties then
                            ' Create/update viewInstance
                            call updateViewInstance(inst, instModel)
                        end if
                    end if
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Sub copyProperties(fromObj, toObj, instModel, noValues)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
        dim fromParam, fromParams
        dim toParam
        dim enumVal, enumVals
        dim enumProp
        dim propExists
        dim rel

        set contentModel = fromObj.ownerModel
        set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.title = fromProp.title then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                if noValues then
                    call toProp.setNamedStringValue("name", fromProp.title)
                    call toProp.setNamedStringValue("unit", fromProp.getNamedStringValue("unit"))
                else
                    call copyPropertyValues(fromProp, toProp)
                end if
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                set fromParams = fromProp.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
                for each fromParam in fromParams
                ' Set parameter values
                    set toParam = instModel.newPart(GLOBAL_Type_EkaProperty)
                    call toParam.setNamedStringValue("name", fromParam.title)
                    call toParam.setNamedStringValue("unit", fromParam.getNamedStringValue("unit"))
                    'call toParam.setNamedStringValue("value", fromParam.getNamedStringValue("value"))
                    set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, toParam)
                next
                ' Check for enums
                set enumVals = fromProp.getNeighbourObjects(0, GLOBAL_Type_EkaHasAllowedValue, GLOBAL_Type_EkaProperty)
                for each enumVal in enumVals
                    set enumProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                    call enumProp.setNamedValue("value", enumVal.getNamedValue("value"))
                    set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasAllowedValue, toProp, enumProp)
                next
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub copySolutionProperties(fromObj, toObj, instModel)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
        dim minProp, maxProp, enumProp
        dim enumVal, enumVals
        dim propExists
        dim rel

        set contentModel = fromObj.ownerModel
        set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasDP, GLOBAL_Type_DP)
        set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.name = fromProp.name then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                ' Create the property
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedValue("name", fromProp.getNamedValue("name"))
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                ' Set the unit value
                call toProp.setNamedValue("unit", fromProp.getNamedValue("unit"))
                ' Check for enums
                set enumVals = fromProp.getNeighbourObjects(0, GLOBAL_Type_hasDPV, GLOBAL_Type_DPV)
                for each enumVal in enumVals
                    set enumProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                    call enumProp.setNamedValue("value", enumVal.getNamedValue("value"))
                    set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasAllowedValue, toProp, enumProp)
                next
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub copyConstraintProperties(fromObj, toObj, instModel)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
        dim minProp, maxProp, enumProp
        dim enumVal, enumVals
        dim propExists
        dim rel

        set contentModel = fromObj.ownerModel
        set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasCPR, GLOBAL_Type_CPR)
        set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.name = fromProp.name then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                ' Create the property
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedValue("name", fromProp.getNamedValue("name"))
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                ' Set the unit value
                call toProp.setNamedValue("unit", fromProp.getNamedValue("unit"))
                ' Set the min and max values
                set minProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call minProp.setNamedStringValue("name", "Minimum")
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, minProp)
                set maxProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call maxProp.setNamedStringValue("name", "Maximum")
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasParameter, toProp, maxProp)
            end if
        next
        set fromProperties = fromObj.getNeighbourObjects(0, GLOBAL_Type_hasCP, GLOBAL_Type_CP)
        set toProperties   = toObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each fromProp in fromProperties
            ' Check if property already exists in toObj
            propExists = false
            for each toProp in toProperties
                if toProp.name = fromProp.name then
                    propExists = true
                    exit for
                end if
            next
            if not propExists then
                ' Create the property
                set toProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                call toProp.setNamedValue("name", fromProp.getNamedValue("name"))
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
                ' Check for enums
                set enumVals = fromProp.getNeighbourObjects(0, GLOBAL_Type_hasCPV, GLOBAL_Type_CPV)
                for each enumVal in enumVals
                    set enumProp = instModel.newPart(GLOBAL_Type_EkaProperty)
                    call enumProp.setNamedValue("value", enumVal.getNamedValue("name"))
                    set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasAllowedValue, toProp, enumProp)
                next
            end if
        next
    End Sub

'-----------------------------------------------------------
    Public Function updateViewInstance(inst, instModel)
        dim contentModel
        dim prop, props
        dim param, params
        dim vp, viewProp, viewProps
        dim unit, value, minVal, maxVal
        dim rel

        set contentModel = inst.ownerModel
        set props = inst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
        for each prop in props
            ' Find ViewProperty if it exists
            set viewProp = Nothing
            set viewProps = inst.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
            for each vp in viewProps
                if vp.title = prop.title then
                    set viewProp = vp
                    exit for
                end if
            next
            if not isEnabled(viewProp) then
                ' Create the view property
'stop                
                set viewProp = instModel.newPart(GLOBAL_Type_CCProperty)
                viewProp.title = prop.title
                set rel = contentModel.newRelationship(GLOBAL_Type_CCHasProperty, inst, viewProp)
            end if
            if isEnabled(viewProp) then
                ' Set unit
                unit = prop.getNamedStringValue("unit")
                if Len(unit) > 0 then call viewProp.setNamedStringValue("unit", unit)
                ' Set value
                value = prop.getNamedStringValue("value")
                if Len(value) > 0 then call viewProp.setNamedStringValue("min", value)
                ' Set min and max values
                set params = prop.getNeighbourObjects(0, GLOBAL_Type_EkaHasParameter, GLOBAL_Type_EkaProperty)
                for each param in params
                    if param.title = "Minimum" then
                        minVal = param.getNamedStringValue("value")
                        if Len(minVal) > 0 then
                            if isNumeric(minVal) then
                                minVal = FormatNumber(minVal, 3)
                                call viewProp.setNamedStringValue("min", minVal)
                            end if
                        end if
                    elseif param.title = "Maximum" then
                        maxVal = param.getNamedStringValue("value")
                        if Len(maxVal) > 0 then
                            if isNumeric(maxVal) then
                                maxVal = FormatNumber(maxVal, 3)
                                call viewProp.setNamedStringValue("max", maxVal)
                            end if
                        end if
                    end if
                next
                ' Set status
            end if
        next

    End Function

'-----------------------------------------------------------
    Public Function findInstance(instType, instName)
        dim inst, instances

        set findInstance = Nothing
        if isEnabled(instType) then
            set instances = instType.getNeighbourObjects(1, GLOBAL_Type_EkaIs, productType)
            for each inst in instances
                if inst.title = instName then
                    set findInstance = inst
                    exit for
                end if
            next
        end if

    End Function

'-----------------------------------------------------------
    Public Function findInstanceType(instTypeName, instTypeModel)
        dim instanceTypeName
        dim part, parts

        set findInstanceType = Nothing
        if isEnabled(instTypeModel) then
            'Find type definition
            set parts = instTypeModel.parts
            for each part in parts
                if part.type.inherits(productType) then
                    if part.title = instTypeName then
                        ' Type definition is found
                        set findInstanceType = part
                        exit for
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function findInstanceModel(compObj, instTypeName)
        dim spaceObj
        dim modelObj, models
        dim instanceTypeName

        set findInstanceModel = Nothing

        if isEnabled(compObj) then
            instanceTypeName = compObj.title & ":" & instTypeName
            set spaceObj = findInstanceTypeModel(compObj)
            if isEnabled(spaceObj) then
                ' Component type model was found
                ' Try to find corresponding instance type model
                set models = spaceObj.parts
                for each modelObj in models
                    if modelObj.title = instanceTypeName then
                        ' Instance type model exists
                        set findInstanceModel = modelObj
                        exit function
                    end if
                next
                ' Instance type model does not exist, create a new one
                set modelObj = spaceObj.newPart(GLOBAL_Type_EkaSpace)
                modelObj.title = instanceTypeName
                set findInstanceModel = modelObj
                exit function
            end if
        end if

    End Function

'-----------------------------------------------------------
    Public Function findInstanceTypeModel(compObj)
        dim contentModel
        dim spaceObj, spaces

        set findInstanceTypeModel = Nothing
        if isEnabled(compObj) then
            set contentModel = compObj.ownerModel
            set spaces = contentModel.parts
            ' Find component type model
            for each spaceObj in spaces
                if spaceObj.type.uri = GLOBAL_Type_EkaSpace.uri then
                    if spaceObj.title = compObj.title then
                        set findInstanceTypeModel = spaceObj
                        exit function
                    end if
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        dim ccGlobals

        ' Initialize global variables
        set ccGlobals = new CC_Globals
        set ccGlobals = Nothing
        ' Initialize local variables
        set productType      = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        set productInstType  = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")

    End Sub

End Class

