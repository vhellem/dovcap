option explicit




'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_InstanceType

    Public Title
    Public ConfigurableComponent            ' IMetisObject
    Public productType                      ' IMetisType
    Public productInstType                  ' IMetisType

    ' Types


'-----------------------------------------------------------
    Public Function findInstances(compObj, instTypeName)
        dim instTypeModel
        dim instanceModel, instanceType
        dim inst, instances
        dim rel
        dim i, removed

        set findInstances = Nothing
        if not isEnabled(compObj) then
            exit function
        end if
        set instTypeModel = findInstanceTypeModel(compObj)
        set instanceModel = findInstanceModel(compObj, instTypeName)
        if isEnabled(instTypeModel) and isEnabled(instanceModel) then
            set instanceType  = findInstanceType(compObj, instTypeName)
            if isEnabled(instanceType) then
                set instances = instanceModel.parts
                i = 1
                for each inst in instances
                    removed = false
                    if not inst.type.inherits(productInstType) then
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
    Public Function newInstance(compObj, instTypeName, instName)
        dim contentModel, instTypeModel
        dim instanceModel, instanceType
        dim inst
        dim rel

        set newInstance = Nothing
        if not isEnabled(compObj) then
            exit function
        end if
        set contentModel = compObj.ownerModel
        set instTypeModel = findInstanceTypeModel(compObj)
        set instanceModel = findInstanceModel(compObj, instTypeName)
        if isEnabled(instTypeModel) and isEnabled(instanceModel) then
            set instanceType  = findInstanceType(compObj, instTypeName)
            if not isEnabled(instanceType) then
                set instanceType = instTypeModel.newPart(productType)
                instanceType.title = instTypeName
                call copyProperties(compObj, instanceType, instanceModel)
            end if
            if isEnabled(instanceType) then
                set inst = findInstance(instanceType, instName)
                if isEnabled(inst) then
                    set newInstance = inst
                else
                    set inst = instanceModel.newPart(productInstType)
                    if isEnabled(inst) then
                        inst.title = instName
                        set rel = contentModel.newRelationship(GLOBAL_Type_EkaIs, inst, instanceType)
                        call copyProperties(instanceType, inst, instanceModel)
                        set newInstance = inst
                    end if
                end if
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Sub copyProperties(fromObj, toObj, instModel)
        dim contentModel
        dim fromProp, fromProperties
        dim toProp, toProperties
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
                call copyPropertyValues(fromProp, toProp)
                set rel = contentModel.newRelationship(GLOBAL_Type_EkaHasProperty, toObj, toProp)
            end if
        next
    End Sub

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
    Public Function findInstanceType(compObj, instTypeName)
        dim instTypeModel
        dim instanceTypeName
        dim part, parts

        set findInstanceType = Nothing
        if isEnabled(compObj) then
            set instTypeModel = findInstanceTypeModel(compObj)

            if isEnabled(instTypeModel) then
                ' Component type model was found
                ' Find type definition
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

