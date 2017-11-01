option explicit

' Edit Rule

dim ccRule
dim inst
dim ruleType

set ruleType = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")

set inst = metis.currentModel.currentInstance
if not inst.type.uri = ruleType.uri then

'stop

    set ccRule = new CC_Rule
    ccRule.ObjectAspectRatio = 0.3
    call ccRule.execute("Edit")
end if

' End

