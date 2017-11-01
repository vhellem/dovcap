' Edit properties / parameters

' contextInst is the CC

' Initialize
set ccGlobals = new CC_Globals
set ccGlobals = Nothing

set model  = metis.currentModel

set workWindow = getWorkareaView(getCVWmodel, "Workplace")
set currentInst = workWindow.children(1).instance
roleName = "Component Family Responsible"
methodUri  = "http://xml.chalmers.se/methods/virtual_methods.kmd#editReqProperties"
set method = metis.findMethod(methodUri)
call editRoleParameters(model, contextInst, currentInst, roleName, method)

' End


