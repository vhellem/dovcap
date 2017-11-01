set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView

pi = 3.1415926535897932

' find container
set modelObj = metis.findInstance(model.uri)
set containers = modelObj.parts

for each cont in containers
    set container = cont
    set containerView = cont.views(1)
    ' Remove children
    set children = containerView.children
    for each child in children
        if child.hasInstance then
            if child.instance.isObject then
                modelView.deleteObjectView child
            elseif child.instance.isRelationship then
                modelView.deleteRelationshipView
            end if
        end if
    next
    exit for
next


no_of_neighbours = InputBox("Enter number of neighbours", "User input", 0)
no_of_neighbours_2 = 8
distance_ratio = 1 / 5

' Create center object
set contGeo = containerView.geometry
w =  contGeo.width/10
h =  contGeo.height/10
x0 = contGeo.width/2 - w/2
y0 = contGeo.height/2 - h/2
set pnt = modelView.newPoint(x0, y0)
set pnt1 = modelView.newPoint(x0, y0)
set pnt2 = modelView.newPoint(x0, y0)
set size = modelView.newSize(w, h)
set size2 = modelView.newSize(w/2, h/2)
set objGeo = modelView.newRect(pnt, size)

set objView = containerView.newObjectView(inst)
set objView.geometry = objGeo

'Center object is created
if no_of_neighbours > 0 then
    dAngle1  = 2 * pi / no_of_neighbours
end if
if no_of_neighbours_2 > 0 then
    dAngle2 = 1 * pi / no_of_neighbours_2
end if
radius = contGeo.height * distance_ratio

'stop
for i = 1 to no_of_neighbours
    dAngle = dAngle1 * (i-0.5)
    dX = radius * cos(dAngle)
    dY = radius * sin(dAngle)
    pnt1.x = pnt.x + dX
    pnt1.y = pnt.y - dY
    set objGeo.point = pnt1
    set objGeo.size = size
    set objView = containerView.newObjectView(inst)
    set objView.geometry = objGeo
    set pnt2 = pnt1
    for j = 1 to no_of_neighbours_2
        dAngle = pi/2 - dAngle1 * (i-0.5) - dAngle2 * j
        dX = radius * cos(dAngle)
        dY = radius * sin(dAngle)
        pnt2.x = pnt1.x + dX
        pnt2.y = pnt1.y + dY
        set objGeo.point = pnt2
        set objGeo.size = size2
        set objView = containerView.newObjectView(inst)
        set objView.geometry = objGeo
    next
next

