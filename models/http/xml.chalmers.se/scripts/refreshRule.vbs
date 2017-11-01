option explicit

dim currentModel, currentModelView
dim currentInstance, currentInstanceView
dim ruleType, anyObjectType, isInstanceType
dim workarea, workwindow, wObject
dim indx
dim obj, objects
dim ruleObject
dim ccRule

'Initialization
    set currentModel        = metis.currentModel
    set currentModelView    = currentModel.currentModelView
    set currentInstance     = currentModel.currentInstance
    set currentInstanceView = currentModelView.currentInstanceView
    set ruleType            = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")
    set anyObjectType       = metis.findType("metis:stdtypes#oid1")
    set isInstanceType      = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasInstanceContext2_UUID")

'stop
    ' Get context instance
    set workarea = currentInstanceView.parent.parent
    indx = workarea.children.count
    set workwindow = workarea.children(indx)
    set wObject = workwindow.instance
    if isEnabled(wObject) then
        set objects = wObject.getNeighbourObjects(0, isInstanceType, anyObjectType)
        if isValid(objects) then
            if objects.count > 0 then
                for each obj in objects
                    if isEnabled(obj) then
                        if obj.type.uri = ruleType.uri then
                            set ruleObject = obj
                            exit for
                        end if
                    end if
                next
            end if
        end if
    end if
    if isEnabled(ruleObject) then
        set ccRule = new CC_Rule
        ccRule.ObjectAspectRatio = 0.3
        ccRule.debug = true
        call ccRule.populateRule(workWindow, ruleObject, false)
    end if

' End
