set currentObj = Nothing
set ccGlobals = new CC_Globals
set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set children = workWindow.children
for each child in children
    if hasInstance(child) then
        set currentObj = child.instance
        exit for
    end if
next

set contentModel = currentObj.ownerModel
modelUrl = contentModel.uri

methodUri = "http://xml.chalmers.se/methods/cc_methods.kmd#saveModel"
set method = metis.findMethod(methodUri)
call method.setArgument1("ModelUrl", modelUrl)
call contentModel.runMethod(method)

