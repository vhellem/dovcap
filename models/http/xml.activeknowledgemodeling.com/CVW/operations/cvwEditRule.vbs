option explicit

dim cvwAction, cvwWorkspace
dim ruleSpec, ruleSpecs
dim cvwModel

'stop
set specContainerType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_objects.kmd#ObjType_CVW:Specification_Container_UUID")

' Find action object
set cvwModel = getCVWmodel
set ruleSpecs = cvwModel.findInstances(specContainerType, "name", "_Rules_")
if isValid (ruleSpecs) then
    if ruleSpecs.count > 0 then
        set ruleSpec = ruleSpecs(1)
        set cvwAction = new CVW_MenuAction
        set cvwAction.configObject = ruleSpec
        call cvwAction.build
        set cvwWorkspace = cvwAction.execute
        set cvwAction = Nothing
    end if
end if

