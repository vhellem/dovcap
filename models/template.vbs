Option Explicit
'*********************************************************************
'AKM R&D prototype software
'September 2006
'*********************************************************************

'Global variables
Dim objCurrentModel, objCurrentInstance, object

' Store initial current model and instance                           
Set objCurrentModel = metis.currentModel
Set objCurrentInstance = objCurrentModel.currentInstance

findPartnerAndRelate objCurrentInstance, objCurrentModel.findInstances(metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task.kmd#AKM_Task"), "", "")
metis.runCommand "select-all"
metis.runCommand "ensure-relationship-views"

function findPartnerAndRelate (byval o, byref objs )
	for each object in objs
		if (object.name = o.name) and (object.uri <> o.uri) then
			'msgbox "Found match "&o.name&":"&object.uri&"-"&o.uri
			createRelationship o, object
			Exit for
		end if
	next
end function

function createRelationship(byval from, byval til)
	Dim rel, object, typen
	Set typen = metis.findType("http://xml.activeknowledgemodeling.com/task/relationshiptypes/template.kmd#AKM_Template")
	Set rel = objCurrentModel.newRelationship(typen, from, til)
	'msgbox "Created new template relationship "&from.name&" - "&rel.uri
	for each object in from.parts
		findPartnerAndRelate object, til.parts
	next
end function
