Option Explicit
'*********************************************************************
'Troux R&D prototype software, MPCE
'April 2005
'*********************************************************************

'Global variables
Dim objCurrentModel, objCurrentInstance, object, u

' Store initial current model and instance                           
Set objCurrentModel = metis.currentModel
Set objCurrentInstance = objCurrentModel.currentInstance

for each object in objCurrentModel.findInstances(metis.findType("http://metadata.troux.info/meaf/objecttypes/online_document.kmd#CompType_MEAF:OnlineDocument_UUID"),"", "")
	u = getUrl( object)
 	call object.setNamedStringValue("filename", u)
next


function getUrl(byval object)
 Dim urlvalue
 urlvalue = object.getNamedValue("filename").getUrl()
 if len(urlvalue) > 0 then
  getUrl = urlvalue
 elseif isNull(object.parent) then
  getUrl = "http://HavardJorgensen/team/repository"
 else 
  getUrl = getUrl(object.parent) & "/"& object.getNamedStringValue("name")
 end if
end function