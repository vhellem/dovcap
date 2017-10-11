option explicit

dim model, modelView
dim inst, instView, objView1
dim modelObj
dim cont, container, containers, containerView
dim child, children
dim contGeo, pnt1, size1, objGeo1

dim no_of_neighbours, no_of_levels, no_levels
dim pi, distance_ratio, radius
dim w, h, x0, y0

set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView

pi = 3.1415926535897932

' find container
set modelObj = metis.findInstance(model.uri)
set containers = modelObj.parts

'Clear container content
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
no_of_levels = InputBox("Enter number of levels", "User input", 1)
no_levels = CInt(no_of_levels)

' Create center object
set contGeo = containerView.geometry
w =  contGeo.width/10
h =  contGeo.height/10
x0 = contGeo.width/2 - w/2
y0 = contGeo.height/2 - h/2
set pnt1 = modelView.newPoint(x0, y0)
set size1 = modelView.newSize(w, h)
set objGeo1 = modelView.newRect(pnt1, size1)

set objView1 = containerView.newObjectView(inst)
set objView1.geometry = objGeo1

'Calculate radius
distance_ratio = 1 / 5
radius = contGeo.height * distance_ratio

' Create circular layout
call addCLobjectViews(containerView, inst, radius, no_of_neighbours, 0, 0, 2*pi, x0, y0, size1, 1, no_levels)

sub addCLobjectViews(containerView, inst, radius, no, a0, a1, a2, x0, y0, size1, level, no_levels)
    dim pnt, size, objGeo
    dim da, a, x, y, dx, dy
    dim objView
    dim i, no1
 'stop
    set pnt = modelView.newPoint(x0, y0)
    set size = modelView.newSize(size1.width * 0.5, size1.height * 0.5)
    dx = size.width / 2
    dy = size.height / 2
    set objGeo = modelView.newRect(pnt, size)
    da = (a2 - a1) / no
    for i = 1 to no
        a = a0 + a1 + da*(i-1)
        x = x0 + (radius) * cos(a) + dx
        y = y0 + (radius) * sin(a) + dy
        pnt.x = x
        pnt.y = y
        set objGeo.point = pnt
        set objView = containerView.newObjectView(inst)
        set objView.geometry = objGeo
        if level < no_levels then
            select case level
            case 1 no1 = 4
            case 2 no1 = 3
            case 3 no1 = 2
            case 4 no1 = 1
            end select
            call addCLobjectViews(containerView, inst, radius, no1, a, 0, 1*pi, x, y, size, level+1, no_levels)
        end if
    next
end sub

