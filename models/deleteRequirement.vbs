' Delete requirement

' contextInst is the CC

'stop

set modelView = metis.currentModel.currentModelView
set currentObj = Nothing
set ccGlobals = new CC_Globals
set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set children = workWindow.children
if children.count > 0 then
    answer = MsgBox("Do you really want to delete?", 36)
    if answer = vbYes then
        for each child in children
            if hasInstance(child) then
                set inst = child.instance
                set model = inst.ownerModel
                set properties = inst.getNeighbourObjects(0, GLOBAL_Type_CCHasProperty, GLOBAL_Type_CCProperty)
                for each prop in properties
                    call model.deleteObject(prop)
                next
                set properties = inst.getNeighbourObjects(0, GLOBAL_Type_EkaHasProperty, GLOBAL_Type_EkaProperty)
                for each prop in properties
                    call model.deleteObject(prop)
                next
                call modelView.deleteObjectView(child)
                call model.deleteObject(inst)
            end if
        next
    end if
end if

