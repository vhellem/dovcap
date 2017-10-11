option explicit

dim currentModel, currentInstance
dim ccConfigure, ccModel

set currentModel = metis.currentModel
set currentInstance = currentModel.currentInstance

'stop
set ccConfigure = new CC_Configure
call ccConfigure.startConfigureCC(currentInstance, "", ccModel)
call MsgBox("Configuration completed!")
set ccConfigure = Nothing

' End


