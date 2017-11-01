' Clear all values

'stop
    set ccObj = metis.currentModel.currentInstance
    set container = ccObj.parent
    set parts = container.parts
    for each part in parts
        if part.type.inherits(GLOBAL_Type_FR) then
            call deleteValues(part)
        end if
        if part.type.inherits(GLOBAL_Type_DS) then
            call deleteValues(part)
        end if
        if part.type.inherits(GLOBAL_Type_CO) then
            call deleteValues(part)
        end if
    next
    set parts = ccObj.parts
    for each part in parts
        if part.type.inherits(GLOBAL_Type_FR) then
            call deleteValues(part)
        end if
        if part.type.inherits(GLOBAL_Type_DS) then
            call deleteValues(part)
        end if
        if part.type.inherits(GLOBAL_Type_CO) then
            call deleteValues(part)
        end if
    next
    call deleteValues(ccObj)
    MsgBox "All values have been cleared!"

    Private Sub deleteValues(obj)
        set model = obj.ownerModel
        set values = obj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)
        for each value in values
            call model.deleteObject(value)
        next
    End Sub

