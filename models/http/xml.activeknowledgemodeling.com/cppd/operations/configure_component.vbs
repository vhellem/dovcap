OPTION Explicit

Dim model, modelView
Dim cc, ccView
ReDim MyParameters(0)
Dim params, param, paramName, paramValue
Dim p, part
Dim count
Dim objType, relType, paramType, hasParamType
Dim configuration
Dim mode

' Current values
set model = metis.currentModel
set modelView = model.currentModelView
set cc = model.currentInstance
set ccView = modelView.currentInstanceView

' Metamodel variables
set objType = metis.findType("http://xml.chalmers.se/object_types/configurable_component.kmd#Configurable_Component")
set relType = metis.findType("http://xml.chalmers.se/relationship_types/is_composed_using.kmd#Is_Composed_Using")
set paramType = metis.findType("http://xml.chalmers.se/object_types/parameter.kmd#VariantParameter")
set hasParamType = metis.findType("http://xml.chalmers.se/relationship_types/has_parameter.kmd#Has_Parameter")

' Initialize
set configuration = metis.newInstanceViewList
mode = 1 ' Use highlight to show configuration
'mode = 2 ' Use deletion to configure

' Get variant parameters
count = 0
set params = cc.getNeighbourObjects(0, hasParamType, paramType)
for each part in params
    if part.type.uri = paramType.uri then
        paramName = part.name
        set paramValue = part.getNamedValue("value")
        if paramValue.getInteger > 0 then
            ReDim Preserve MyParameters(count)
            MyParameters(count) = paramName
            count = count + 1
        end if
    end if
next

' To force debugging:
'stop

' Do the configuration according to the parameters defined
configuration.AddLast ccView
call configure(1, cc, MyParameters, relType, objType, configuration)

' Show the result of the configuration
if mode = 1 then
    ' Do highlight
    metis.highlightList configuration, 1
    modelView.clearSelection
end if

'---------------------- functions and procedures ------------------------
'
function evaluate(condition, parameters)
    evaluate = false
    if condition = "True" then
        evaluate = true
    else
        for each p in parameters
            if p = condition then
                evaluate = true
            end if
        next
    end if
end function

sub configure(mode, localCC, parameters, relType, objType, configuration)
    Dim count
    Dim p, part
    Dim rel, relView, rels
    Dim included
    Dim conditionValue
    Dim ccObj, ccObjView
    Dim instList

     set instList = metis.newInstanceList
    ' Find icu relationships
    set rels = localCC.getNeighbourRelationships(0, relType)
    'MsgBox "Number of icu rels: " & rels.count
    for each rel in rels
        included = false
        set ccObj = rel.target
        conditionValue = rel.getNamedStringValue("condition")
        if evaluate(conditionValue, parameters) then
            included = true
            if mode = 1 then
                set relView = rel.views.item(1)
                configuration.AddLast relView
                set ccObjView = ccObj.views.item(1)
                configuration.AddLast ccObjView
            end if
            call configure(mode, ccObj, parameters, relType, objType, configuration)
        elseif mode = 2 then
            set model.currentInstance = ccObj
            set ccObjView = ccObj.views.item(1)
            set modelView.currentInstanceView = ccObjView
            metis.runCommand "delete"
        end if
    next
end sub






















