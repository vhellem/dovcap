option explicit

'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_LanguageSpecification

    Public  title

    Public currentModel
    Public currentModelView
    Public currentInstance
    Public currentInstanceView
    Private noObjTypes          ' Integer
    Private objTypes            ' List of IMetisType
    Private noRelTypes          ' Integer
    Private relTypes            ' List of IMetisType
    Private consistOfType       ' IMetisType
    Private propertyType
    Private anyObjectType

'-----------------------------------------------------------
    Public Property Get noObjectTypes
        noObjectTypes = noObjTypes
    end Property

'-----------------------------------------------------------
    Public Property Get objectTypes
        set objectTypes = objTypes
    end Property

'-----------------------------------------------------------
    Public Property Get noRelshipTypes
        noRelshipTypes = noRelTypes
    end Property

'-----------------------------------------------------------
    Public Property Get relshipTypes
        set relshipTypes = relTypes
    end Property

'-----------------------------------------------------------
    Public Sub build(specificationObject)

        ' Build code
        call setTypes(specificationObject, 1) ' 1 = object types
        call setTypes(specificationObject, 2) ' 2 = relship types

    End Sub

'-----------------------------------------------------------
    Public Function relIsAllowed(rel)
        dim i

        relIsAllowed = false
        if isEnabled(rel) then
            for i = 1 to noRelTypes
                if rel.type.uri = relTypes(i).uri then
                    relIsAllowed = true
                    exit for
                end if
            next
        end if
    End Function

'-----------------------------------------------------------
    Public Function getTypeList(specificationObject, objType, relDir)
        dim obj, objects
        dim foundObj
        dim rel, relships, rDir

        set getTypeList = Nothing
        ' Find type
        set objects = specificationObject.parts
        if objects.count > 0 then
            for each obj in objects
                if objType.inherits(obj.type) then
                'if obj.type.uri = objType.uri then
                    set foundObj = obj
                    exit for
                end if
            next
            set relships = foundObj.neighbourRelationships
            if relships.count > 0 then
                set getTypeList = metis.newInstanceList
                for each rel in relships
                    if rel.target.uri = foundObj.uri then
                        if rel.origin.uri <> specificationObject.uri then
                            set obj = rel.origin
                            rDir = 1
                        else
                            set obj = Nothing
                        end if
                    else
                        set obj = rel.target
                        rDir = 0
                    end if
                    if isEnabled(obj) then
                        if obj.type.uri = propertyType.uri then
                            set obj = Nothing
                        end if
                    end if
                    if isEnabled(obj) and (relDir = -1 or relDir = rDir) then
                        if not typeAlreadyInList(getTypeList, obj) then
                            call getTypeList.addLast(obj)
                        end if
                    end if
                next
            end if
        end if
    End Function

'-----------------------------------------------------------
    Private Function typeAlreadyInList(typeList, inst)
        dim t

        typeAlreadyInList = false
        for each t in typeList
            if t.type.uri = inst.type.uri then
                typeAlreadyInList = true
                exit for
            end if
        next
    End Function

'-----------------------------------------------------------
    Private Sub setTypes(specificationObject, mode)
        dim obj, objects
        dim relship, relships
        dim rel, rels

        set objects = specificationObject.parts
        if objects.count > 0 then
            for each obj in objects
                if isEnabled(obj) then
                    if mode = 1 then ' Object type
                        addObjectType(obj.type)
                    else               ' Relationship type
                        set relships = obj.neighbourRelationships
                        for each rel in relships
                            if rel.origin.uri = obj.uri then
                                addRelshipType(rel.type)
                            end if
                        next
                    end if
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub addObjectType(objectType)
        dim objType
        dim found
        
        found = false
        for each objType in objTypes
            if isEnabled(objType) then
                if objType.uri = objectType.uri then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            ' Maintain the list
            noObjTypes = noObjTypes + 1
            objTypes.addLast(objectType)
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub addRelshipType(relshipType)
        dim relType
        dim found

        found = false
        for each relType in relTypes
            if isEnabled(relType) then
                if relType.uri = relshipType.uri then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            ' Maintain the list
            noRelTypes = noRelTypes + 1
            relTypes.addLast relshipType
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        set currentModel        = metis.currentModel
        set currentModelView    = currentModel.currentModelView
        set currentInstance     = currentModel.currentInstance
        set currentInstanceView = currentModelView.currentInstanceView
        noObjTypes = 0
        set objTypes = metis.newInstanceList
        noRelTypes = 0
        set relTypes = metis.newInstanceList
        ' Types
        set propertyType        = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_property.kmd#ObjType_EKA:Property_UUID")
        set anyObjectType       = metis.findType("metis:stdtypes#oid1")
    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
    End Sub

End Class

