option explicit

dim model, modelView
dim inst, instView
dim workWindow
dim cvwNavigate
dim child, children, childView


set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView

if isValid(instView) then
    set workWindow = findWorkWindowView(instView)

    if isValid(workWindow) then
'stop
        'set cvwNavigate = new CVW_CircularLayout
        'call cvwNavigate.execute(workWindow, inst)
        set cvwNavigate = new CVW_Navigate
        cvwNavigate.NoNeighbourLevels = 1
        cvwNavigate.ClearMode = "NoClear"
        cvwNavigate.NeighbourRelshipType = "metis:stdtypes#oid121"
        cvwNavigate.RelDirection = 1
        cvwNavigate.ObjectAspectRatio = 0.35
        cvwNavigate.AskForObjectType = false
        call cvwNavigate.addNeighbours(workWindow, instView)
    end if
end if


