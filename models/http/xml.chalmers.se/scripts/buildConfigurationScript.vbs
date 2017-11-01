option explicit

dim currentModel, currentInstance
dim ccRule

set currentModel = metis.currentModel
set currentInstance = currentModel.currentInstance

'stop

set ccRule = new CC_Rule
ccRule.debug = false

call ccRule.transformToScript(currentInstance)

set ccRule = Nothing

