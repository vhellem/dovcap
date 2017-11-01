option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim buttonType, anyObjectType, isInstanceType
dim workarea, workwindow, wObject
dim indx
dim cvwTask
dim obj, objects
dim selected
dim inst

'Initialization
    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView
    set buttonType          = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
    set anyObjectType       = metis.findType("metis:stdtypes#oid1")
    set isInstanceType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

    
    if not currentInstance.type.inherits(buttonType) then
        set inst = currentInstance
    else
'stop
        ' Get context instance
        set selected = metis.selectedObjectViews
        if selected.count = 1 then
            set inst = selected(1).instance
        elseif selected.count = 0 then
            set workarea = currentInstanceView.parent.parent
            indx = workarea.children.count
            set workwindow = workarea.children(indx)
            set wObject = workwindow.instance
            if isEnabled(wObject) then
                set objects = wObject.getNeighbourObjects(0, isInstanceType, anyObjectType)
                if isValid(objects) then
                    if objects.count > 0 then
                        for each obj in objects
                            if isEnabled(obj) then
                                set inst = obj
                                exit for
                            end if
                        next
                    end if
                end if
            end if
        end if
    end if
    if isEnabled(inst) then
        set cvwTask = new CVW_Task
        cvwTask.noLevels = 1
'stop
        call cvwTask.openObjectWindow(inst, "FR-DS-C window", true)
        set cvwTask = Nothing
    end if

' End

