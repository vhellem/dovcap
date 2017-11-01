option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim method
dim fromUrl, toUrl

set currentModel = metis.currentModel
set currentModelView = currentModel.currentModelView
set currentInstance = currentModel.currentInstance
set currentInstanceView = currentModelView.currentInstanceView

set method = metis.findMethod("http://xml.chalmers.se/methods/cc_methods.kmd#relocateRelship")

'stop

if currentInstance.isRelationship then
    fromUrl = currentInstance.origin.url
    toUrl   = currentInstance.target.url
    if fromUrl <> toUrl then
        call currentModel.runMethodOnInst(method, currentInstance)
    end if
end if


