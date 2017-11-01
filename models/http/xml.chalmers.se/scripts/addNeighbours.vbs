option explicit

public model, modelView
public valueType, rightPaneType, workareaType
public test

dim modelObj, modelType, contextType, InputValueType, InputModelType, InputContextType
dim model1, value, contextObject
dim inst, instView, instViewList
dim obj, objView, objects, parentView
dim relship, relView, relships
dim origin, originView, originViews
dim target, targetView, targetViews
dim workareaView, workareaViews, child, children
dim contGeo, objGeo, pnt1, size1, ts
dim w, h, x0, y0, radius, distance_ratio, no_levels
dim InputRightpaneType, InputWorkareaType, InputNeighbourViewstyle
dim done

InputModelType          = "http://xml.chalmers.se/class/configurable_component.kmd#configurable_component"
InputContextType        = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:ViewContext_UUID"
InputRightpaneType      = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Rightpane_UUID"
InputWorkareaType       = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workarea_UUID"
InputNeighbourViewstyle = "http://xml.chalmers.se/viewstyles/cc_viewstyle.kmd#CC_Neighbours_Viewstyle"
InputDClickMethod       = "http://xml.chalmers.se/methods/cc_methods.kmd#addDoubleClickMethod"
InputValueType          = "http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:Value_UUID"

set modelType     = metis.findType(InputModelType)
set valueType     = metis.findType(InputValueType)
set contextType   = metis.findType(InputContextType)
set rightPaneType = metis.findType(InputRightpaneType)
set workareaType  = metis.findType(InputWorkareaType)

set model = metis.currentModel
set modelView = model.currentModelView
set inst = model.currentInstance
set instView = modelView.currentInstanceView
set modelObj = findModelObject(modelType, model)

'stop

'Set viewstyle
modelView.setViewStyle InputNeighbourViewstyle
' Set doubleclick action
set method = metis.findMethod(InputDClickMethod)
if isEnabled(method) then
    model.runMethod(method)
end if

set workareaView = getWorkarea(instView)

if not workareaView is Nothing then

set parentView = workareaView.parent
set model = parentView.instance.ownerModel
set workareaViews = parentView.children
if workareaViews.count > 1 then
    call removeWorkArea(model, rightpaneType, workareaType)
    set workareaView = createWorkArea(model, rightpaneType, workareaType, "")
    call metis.doLayout(parentView)
else
    set children = workareaView.children
    for each child in children
        modelView.deleteObjectView(child)
    next
end if

'stop
set contextObject = getContextObject(contextType)
no_levels = 2
if isEnabled(contextObject) then
    set value = contextObject.getNamedValue("neighbourLevels")
    no_levels = value.getInteger
    if no_levels = 0 then no_levels = 1
end if

set objView = workareaView.newObjectView(inst)
set contGeo = workareaView.geometry
set objGeo = objView.geometry
h =  contGeo.height/12 * no_levels
objView.scale(objGeo.height / h)
ts = objView.textScale * 1.5
objView.textScale = ts
set objGeo = objView.geometry
x0 = objGeo.x
y0 = objGeo.y
' Calculate radius
select case no_levels
case 1      distance_ratio = 1 / 4
case 2      distance_ratio = 1 / 8
case 3      distance_ratio = 1 / 12
case else
            distance_ratio = 1 / 16
end select
radius = contGeo.height * distance_ratio
call addCLobjectViews(workareaView, objView, radius, 0, 0, 2*pi, x0, y0, 1, no_levels)

set objects = inst.neighbourObjects
for each obj in objects
    set model1 = obj.ownerModel
    if not model1 is Nothing then
        set relships = model1.relationships
        for each relship in relships
            done = false
            set origin = relship.origin
            set originViews = modelView.findInstanceViews(origin)
            set target = relship.target
            set targetViews = modelView.findInstanceViews(target)
            for each originView in originViews
                for each targetView in targetViews
                    set relView = modelView.newRelationshipView(relship, originView, targetView)
                    done = true
                    exit for
                next
                if done then exit for
            next
        next
    end if
next

set instViewList = metis.newInstanceViewList
instViewList.addLast instView
set modelView.selection = instViewList

end if

function viewExists(inst)
    dim v, view, views

    viewExists = false
    set views = inst.views
    for each view in views
        set v = modelView.findInstanceView(view.uri)
        if isEnabled(v) then
            viewExists = true
        end if
    next
end function



function instanceInList(instance, list)
    dim item
	instanceInList = false
    test = instance.uri

	for each item in list
        test = item.uri
		if instance.uri = item.uri then
            instanceInList = true
        end if
	next
end function

function getWorkarea(instView)
    dim parent, parentView, parentType

    set getWorkarea = Nothing
    if instView.hasInstance then
        set parentView = instView.parent
        if isEnabled(parentView) then
            set parent = parentView.instance
            set parentType = parent.type
            if parentType.uri = workareaType.uri then
                set getWorkarea = parentView
            else
                set getWorkarea = getWorkarea(parentView)
            end if
        end if
    end if
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

function findModelObject(modelObjectType, model)
    dim inst, instances, obj

    set findModelObject = Nothing
    set obj = metis.findInstance(model.uri)
    if isEnabled(modelObjectType) then
        set instances = obj.parts
        for each inst in instances
            if isEnabled(inst) then
                if inst.type.uri = modelObjectType.uri then
                    set findModelObject = inst
                    exit for
                end if
            end if
        next
        if isEnabled(findModelObject) then
            exit function
        end if
        for each inst in instances
            if isEnabled(inst) then
                if inst.isConnectorType then
                    set findModelObject = inst.parts(1)
                    exit for
                end if
            end if
        next
        if isEnabled(findModelObject) then
            exit function
        end if
    end if
    set findModelObject = obj
end function

    sub addCLobjectViews(parentView, instView, radius, a0, a1, a2, x0, y0, level, no_levels)
        dim pnt, size, size1, geo1, objGeo
        dim da, a, x, y, dx, dy, sf, ts
        dim inst, objView
        dim obj, objects
        dim i, no, no1
        dim test
 'stop
        set inst = instView.instance
        ts = parentView.textScale
        select case level
        case 1      sf = 0.5
                    if no_levels = 1 then
                        ts = 1.25
                    else 
                        ts = 1.8
                    end if
        case 2      sf = 1.0
                    ts = 2.15 'ts * (no_levels + 16)
        case 3      sf = 1.2
                    ts = 2.25 'ts * (no_levels + 20)
        case else   sf = 1.5
                    ts = 2.25 'ts * (no_levels + 24)
        end select

        set objects = inst.neighbourObjects
        no = 0
        for each obj in objects
            if not obj.type.inherits(valueType) then
                no = no + 1
            end if
        next
'stop
        if no > 0 then
            set geo1 = instView.geometry
            set size1 = geo1.size
            set pnt = modelView.newPoint(x0, y0)
            set size = modelView.newSize(size1.width * sf, size1.height * sf)
            dx = size.width / 2
            dy = size.height / 2
            set objGeo = modelView.newRect(pnt, size)
            da = (a2 - a1) / no
        end if
        i = 1
        for each obj in objects
            if isEnabled(obj) then
                if not obj.type.inherits(valueType) then
                    if not viewExists(obj) then
                        ' Create object view
                        a = a0 -pi/2 + a1 + da*(i-0.5)
                        'a = a0 + a1 + da*(i-1)
                        x = x0 + (radius) * cos(a) + dx
                        y = y0 + (radius) * sin(a) + dy
                        pnt.x = x
                        pnt.y = y
                        set objGeo.point = pnt
                        set objView = parentView.newObjectView(obj)
                        objView.textScale = ts
                        set objView.geometry = objGeo
                        i = i + 1
                        ' Recursive call
                        if level < no_levels then
                            call addCLobjectViews(parentView, objView, radius, a, 0, 7*pi/8, x, y, level+1, no_levels)
                        end if
                    end if
                end if
            end if
        next
    end sub

    function getContextObject(contextType)
        dim contexts, context

        set getContextObject = Nothing
        set contexts = model.findInstances(contextType, "", "")
        for each context in contexts
            if isEnabled(context) then
                set getContextObject = context
                exit for
            end if
        next

    end function

    function createWorkArea(model, parentContainerType, workAreaType, workAreaName)
        dim parentContainers, parentCont
        dim workAreas, workArea, workAreaView

        set createWorkArea = Nothing
        set parentContainers = model.findInstances(parentContainerType, "", "")
        if parentContainers.Count > 0 then
            set parentCont = parentContainers(1)
            set workArea = parentCont.newPart(workAreaType)
	        call workArea.setNamedStringValue("name", workAreaName)
	        set workAreaView = parentCont.Views(1).newObjectView(workArea)
            if isEnabled(workAreaView) then
                set createWorkArea = workAreaView
            end if
        end if

    end function


