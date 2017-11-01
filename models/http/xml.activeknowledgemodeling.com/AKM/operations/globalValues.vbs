option explicit

public model, modelView
public workplaceType, leftpaneType, rightpaneType, leftpaneWorkareaType, workareaType

dim InputWorkplaceType, InputLeftpaneType, InputRightpaneType, InputLeftpaneWorkareaType, InputWorkareaType

set model = metis.currentModel
set modelView = model.currentModelView

InputWorkplaceType        = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workplace_UUID"
InputRightpaneType        = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Rightpane_UUID"
InputLeftpaneType         = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Leftpane_UUID"
InputWorkareaType         = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workarea_UUID"
InputLeftpaneWorkareaType = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:LeftpaneWorkarea_UUID"

set workplaceType         = metis.findType(InputWorkplaceType)
set rightPaneType         = metis.findType(InputRightpaneType)
set leftPaneType          = metis.findType(InputLeftpaneType)
set leftPaneWorkareaType  = metis.findType(InputLeftpaneWorkareaType)
set workareaType          = metis.findType(InputWorkareaType)

