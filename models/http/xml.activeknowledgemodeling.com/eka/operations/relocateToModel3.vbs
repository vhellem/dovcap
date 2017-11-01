option explicit

dim model, modelObject, ownerModel, modelView
dim parentInst, inst, instView
dim context
dim isModel

set model     = metis.currentModel
set modelView = model.currentModelView
set inst      = metis.currentModel.currentInstance
set instView  = modelView.currentInstanceView

stop
set parentInst = instView.parent.instance
if parentInst.ownerModel.uri <> model.uri then
    set metis.currentModel = parentInst.ownerModel
end if

isModel = false
set context = new EKA_Context
set context.currentModel = model
set context.currentModelView = modelView
if isValid(context) then
    set modelObject = context.contentModel
    if isEnabled(modelObject) then
        set ownerModel = modelObject.ownerModel
        if not isEnabled(ownerModel) then isModel = true
        if isModel then
            if modelObject.uri <> model.uri then
                call relocate(inst, modelObject, instView)
            end if
        else
            call relocate(inst, modelObject, instView)
        end if
    end if
end if


