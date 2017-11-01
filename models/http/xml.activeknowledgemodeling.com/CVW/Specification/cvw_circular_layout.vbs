option explicit

Class CVW_CircularLayout

    Public Title

    ' Variant parameters
    Public NoLevels
    Public WorkWindow
    Public CenterObjectView

    ' Local variables
    Private model
    Private modelView
    Private radius
    Private a0                      ' Angle 1
    Private a1                      ' Angle 2
    Private a2                      ' Angle 3
    Private x0                      ' X-position
    Private y0                      ' Y-position
    Private level                   ' Current level
    Private tsRatio0                ' Text factor ratio
    Private tsRatio1                ' Text factor ratio
    Private tsRatio2                ' Text factor ratio

    Private winGeo
    Private objGeo

    Private isBuilt

    ' The number pi
    Private pi

    ' Methods
'-----------------------------------------------------------
    Public Sub build

        if isValid(WorkWindow) then
            set winGeo = WorkWindow.absScaleGeometry
            isBuilt = true
        end if

    End Sub

'-----------------------------------------------------------
    Public Function getObjectSize(level, objectView)
        dim objGeo, sf
        dim size

        set objGeo = objectView.absScaleGeometry
        sf = getScaleFactor(level)
        if isBuilt then
            set size = getSize(winGeo, objGeo, level)
        else
            set size = objGeo.size
        end if
        size.width  = size.width * sf
        size.height = size.height * sf

        set getObjectSize = size
    End Function

'-----------------------------------------------------------
    Public Function getObjectPosition(level, objectView, size, i, no)
        dim objGeo
        dim x, y, dx, dy, a, da
        dim x1, y1
        dim pnt

        set objGeo = objectView.absScaleGeometry
        radius = getRadius(winGeo, objGeo)
        if level = 0 then
            ' Calculate position of center object
            a0 = 0
            a1 = 0
            a2 = 2 * pi
            dx = size.width / 2
            dy = size.height / 2
            x1 = winGeo.width / 2
            y1 = winGeo.height / 2
            x0 = x1 - dx * 1.5
            y0 = y1 - dy * 1.5
            x  = x0
            y  = y0
        else
            a1 = 0
            if level > 1 then
                a2 = 7 * pi / 8
            else
                a2 = 2 * pi
            end if
            da = (a2 - a1) / no
            a = a0 -pi/2 + a1 + da * (i - 0.5)

            dx = size.width / 2
            dy = size.height / 2
            x = x0 + (radius + size.width) * cos(a) + dx
            y = y0 + (radius) * sin(a) + dy
        end if

        set pnt = modelView.newPoint(x, y)
        set getObjectPosition = pnt
    End Function

'-----------------------------------------------------------
    Public Sub populate(level, objView, size, point)
        dim geo
        dim winTS, ts

        if not isValid(objView) then
            set objView = WorkWindow.newObjectView(inst)
        end if
        ts = getTextScaleFactor(level)
        if objView.isNested then
            ts = ts * 4
        end if
        objView.textScale = ts
        if isValid(objView) then
            set geo = objView.absScaleGeometry
            set geo.size = size
            set geo.point = point
            set objView.absScaleGeometry = geo
        end if
    End Sub

'-----------------------------------------------------------
    Public Sub execute(workareaView, inst)
        dim objView
        dim childView, children
        dim winGeo, objGeo
        dim winSize, objSize
        dim x0, y0, h
        dim winTs, ts, sf
        dim size0, w0, h0
        dim level

        ' First remove all
        set children = workareaView.children
        for each childView in children
            modelView.deleteObjectView(childView)
        next

        ' Set level
        level = 0
        ' Then create objView in center
        set objView = workareaView.newObjectView(inst)

        ' Get geometry of center object
        set winGeo = workareaView.absScaleGeometry
        set objGeo = objView.absScaleGeometry
        ' Calculate size of center object
        set size0 = getSize(winGeo, objGeo, level)
        set objGeo.size = size0

        ' Calculate position of center object
        x0 = objGeo.x - objGeo.width / 4
        y0 = objGeo.y - objGeo.height / 2
        objGeo.x = x0
        objGeo.y = y0
        ' Set size and position
        set objView.absScaleGeometry = objGeo

        ' Calculate text size
        winTs = workareaView.textScale
        ts = winTs * tsRatio0
        ts = getTextScaleFactor(level)
        objView.textScale = ts

        ' Get radius to be used in circular layout
        radius = getRadius(winGeo, objGeo)

        ' Create neighbour objects
        call populateObjects(workareaView, objView, level+1, radius, 0, 0, 2*pi, x0, y0)
        ' Create the connecting relationships
        call populateRelationships(workareaView, objView, level+1)
    End Sub

'-----------------------------------------------------------
    Private Sub populateObjects(parentView, instView, level, radius, a0, a1, a2, x0, y0)
        dim pnt, size, size1, geo1, objGeo, winGeo
        dim da, a, x, y, dx, dy, sf, ts
        dim inst, objView
        dim obj, objects
        dim i, no, no1
        dim test
 'stop
        sf = getScaleFactor(level)
        ts = getTextScaleFactor(level)
        if instView.isNested then ts = ts * 4

        set inst = instView.instance
        set objects = inst.neighbourObjects
        no = objects.count
'stop
        if no > 0 then
            ' Get geometry of parent object
            set winGeo = parentView.absScaleGeometry
            set objGeo = instView.absScaleGeometry
            ' Calculate size of parent object
            set size1 = getSize(winGeo, objGeo, level)

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
                'if not obj.type.inherits(valueType) then
                    set objView = viewExists(obj, parentView)
                    if not isValid(objView) then
                        ' Create object view
                        a = a0 -pi/2 + a1 + da*(i-0.5)
                        'a = a0 + a1 + da*(i-1)
                        x = x0 + (radius + size.width) * cos(a) + dx
                        y = y0 + (radius) * sin(a) + dy
                        pnt.x = x
                        pnt.y = y
                        set objGeo.point = pnt
                        set objView = parentView.newObjectView(obj)
                        objView.textScale = ts
                        set objView.absScaleGeometry = objGeo
                        i = i + 1
                        ' Recursive call
                        if level < NoLevels then
                            call populateObjects(parentView, objView, level+1, radius, a, 0, 7*pi/8, x, y)
                        end if
                    end if
                'end if
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Sub populateRelationships(parentView, objView, level)
        dim obj
        dim relship, relships
        dim origin, target
        dim originView, targetView
        dim originViews, targetViews
        dim relView
        dim done

        set obj = objView.instance
        set relships = obj.neighbourRelationships
        for each relship in relships
            done = false
            set origin = relship.origin
            set target = relship.target
            if obj.uri = origin.uri then
                set originView = objView
                set targetViews = target.views
                for each targetView in targetViews
                    if isInParentView(parentView, targetView) then
                        set relView = modelView.newRelationshipView(relship, originView, targetView)
                        if level < NoLevels then
                            call populateRelationships(parentView, targetView, level+1)
                        end if
                        exit for
                    end if
                next
            elseif obj.uri = target.uri then
                set targetView = objView
                set originViews = origin.views
                for each originView in originViews
                    if isInParentView(parentView, originView) then
                        set relView = modelView.newRelationshipView(relship, originView, targetView)
                        if level < NoLevels then
                            call populateRelationships(parentView, originView, level+1)
                        end if
                        exit for
                    end if
                next
            end if
        next
    End Sub

'-----------------------------------------------------------
    Private Function isInParentView(parentView, objView)
        dim children, childView

        isInParentView = false
        set children = parentView.children
        for each childView in children
            if objView.uri = childView.uri then
                isInParentView = true
            end if
        next
    End Function

'-----------------------------------------------------------
    Private Function getRadius(winGeo, objGeo)
        dim w, h, distance_ratio
        dim w1, h1, r1, r2

        w = objGeo.width
        h = objGeo.height
        w1 = winGeo.width
        h1 = winGeo.height
        r1 = h1 / (2 * NoLevels) - h/2

        select case NoLevels
        case 1      distance_ratio = 1
        case 2      distance_ratio = 1.25
        case 3      distance_ratio = 1.5
        case else
                    distance_ratio = 1.5
        end select
        r2 = w * distance_ratio
        getRadius = r1
    End Function

'-----------------------------------------------------------
    Private Function getSize(winGeo, objGeo, level)
        dim winSize, objSize
        dim w0, h0
        dim sf

        set winSize = winGeo.size
        set objSize = objGeo.size
        select case level
        case 0      sf = 0.1 / NoLevels
        case 1      sf = 0.1 / NoLevels
        case 2      sf = 0.1 / NoLevels
        case else   sf = 0.1 / NoLevels
        end select
        h0 = winSize.height * sf
        w0 = h0 * objGeo.width / objGeo.height
        set getSize = modelView.newSize(w0, h0)
    End Function

'-----------------------------------------------------------
    Private Function getScaleFactor(level)
        select case level
        case 0      getScaleFactor = 1.0
        case 1      getScaleFactor = 0.7
        case 2      getScaleFactor = 0.5
        case 3      getScaleFactor = 0.25
        case else   getScaleFactor = 0.125
        end select
    End Function

'-----------------------------------------------------------
    Private Function getTextScaleFactor(level)
        select case level
        case 0      getTextScaleFactor = 0.35
        case 1      getTextScaleFactor = 0.5
        case 2      getTextScaleFactor = 0.75       'ts * (NoLevels + 16)
        case 3      getTextScaleFactor = 1       'ts * (NoLevels + 20)
        case else   getTextScaleFactor = 1.25       'ts * (NoLevels + 24)
        end select
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()

        set model     = metis.currentModel
        set modelView = model.currentModelView

        isBuilt = false

        pi       = 3.1415926535897932

        tsRatio0 = 0.1
        tsRatio1 = 1
        tsRatio2 = 1

        NoLevels = 2

    End Sub

End Class
