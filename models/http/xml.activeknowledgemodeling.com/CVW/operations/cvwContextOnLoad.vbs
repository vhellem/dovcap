option explicit

dim model, modelObject
dim inst, context

set model = metis.currentModel
set inst  = metis.currentModel.currentInstance
stop
set context = new CVW_Context
if isEnabled(context.modelObject) then
    set ekaContext = new EKA_Context
    set ekaContext.contentModel = context.modelObject
    set ekaContext = Nothing
end if
set context = Nothing

