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
set objType = metis.findType("http://xml.activeknowledgemodeling.com/CPPD/languages/cc_objects.kmd#ObjType_CPPD:ConfigurableComponent_UUID")
set relType = metis.findType("http://xml.activeknowledgemodeling.com/CPPD/languages/cc_relships.kmd#RelType_CPPD:IsComposedUsing_UUID")
set paramType = metis.findType("http://xml.activeknowledgemodeling.com/EKA/languages/eka_parameter.kmd#ObjType_EKA:Parameter_UUID")
set hasParamType = metis.findType("http://xml.activeknowledgemodeling.com/EKA/languages/eka_relships.kmd#RelType_EKA:HasParameter_UUID")
set isAType = metis.findType("http://xml.activeknowledgemodeling.com/EKA/languages/eka_relships.kmd#RelType_EKA:isA_UUID")

' Initialize
set configuration = metis.newInstanceViewList
mode = 1 ' Use highlight to show configuration
'mode = 2 ' Use deletion to configure

' To force debugging:
'stop

' Do the configuration according to the parameters defined
configuration.AddLast ccView
call configure(1, cc, relType, isAType, objType, configuration)

' Show the result of the configuration
if mode = 1 then
    ' Do highlight
    metis.highlightList configuration, 1
    modelView.clearSelection
end if

'---------------------- functions and procedures ------------------------
'
sub configure(mode, localCC, relType, isAType, objType, configuration)
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
        if evaluate(ccObj) then
            included = true
            if mode = 1 then
                set relView = rel.views.item(1)
                configuration.AddLast relView
                set ccObjView = ccObj.views.item(1)
                configuration.AddLast ccObjView
            end if
            call configure(mode, ccObj, relType, objType, configuration)
        elseif mode = 2 then
            set model.currentInstance = ccObj
            set ccObjView = ccObj.views.item(1)
            set modelView.currentInstanceView = ccObjView
            metis.runCommand "delete"
        end if
    next
end sub

function evaluate(obj)

    evaluate = true

end function






















