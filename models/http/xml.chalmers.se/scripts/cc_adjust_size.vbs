option explicit

dim model, parent
dim modelView, instView, parentView
dim geo, instGeo, parentGeo
dim pnt, size

set model = metis.currentModel
set modelView = model.currentModelView
set instView = modelView.currentInstanceView
set parentView = instView.parent
set parent = parentView.instance
'stop
if parent.isContainer then
    set parentGeo = parentView.geometry
    set instGeo = instView.geometry
    set pnt = modelView.newPoint(0, 0)
    set size = modelView.newSize(0, 0)
    set geo = modelView.newRect(pnt, size)
    set geo = setGeo(parentGeo, geo, 0, 0, 1, 1)
    instGeo.x = geo.x
    instGeo.y = geo.y
    instGeo.width = geo.width
    instGeo.height = geo.height
end if
'---------------------------------------------

function setGeo(fromGeo, toGeo, xpos, ypos, w, h) ' All numbers between 0 and 1
    toGeo.x = fromGeo.width * xpos
    toGeo.y = fromGeo.height * ypos
    toGeo.width = fromGeo.width * w
    toGeo.height = fromGeo.height * h
    set setGeo = toGeo
end function

function isEnabled(inst)
    isEnabled = true
    if isEmpty(inst) then
        isEnabled = false
    elseif isNull(inst) then
        isEnabled = false
    elseif inst is Nothing then
        isEnabled = false
    elseif not inst.isValid then
        isEnabled = false
    end if
end function

