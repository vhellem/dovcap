'msgbox metis.currentModel.currentInstance.getNamedValue("serviceURL").getUrl()
Dim url
url = "http://localhost:800"
dim marshall
for each marshall in metis.currentModel.findInstances(metis.findType("metis:troux#TrouxMarshalling"), "","")
	url = marshall.getNamedStringValue("serverName")
	if (instr(url, "://") <= 0) then
		url = "http://"&url
	end if
	if (instrrev(url, "/") < len(url)) then
		url = url&"/"
	end if
	exit for
	'msgbox "Server url= "&url
next

Dim task
Set task = metis.currentModel.currentInstance
Dim taskid 
Dim object 
taskid = getRepositoryId(task)
if task.type.inherits(metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task.kmd#AKM_Task")) then
	findService task, object
	if (not isEnabled(object)) then
		msgbox "The task '"&task.getNamedStringValue("name")& "' does not have a service related to it."
	else
		Dim objectid
		objectid = getRepositoryId(object)
		if (len(taskid) >0) AND (len(objectid) > 0) then
			url = url& "tip/do/mupsComponentPickerAction?context="& taskid & "&id="&objectid
			Set shel = createObject("Shell.Application")
			shel.ShellExecute url
		elseif (len(taskid) <= 0) then
			msgbox "The task '"&task.getNamedStringValue("name")& "' is not stored in the repository. Please commit it to the repository before you try to execute it on the repository."
		elseif (len(object) <= 0) then
			msgbox "The service '" & object.getNamedStringValue("name")& "' for task '"&metis.currentModel.getNamedStringValue("name")& "' is not stored in the repository. Please commit it to the repository before you try to execute it on the repository."
		end if
	end if
else 'not task, service...
	url = url&"tip/do/mupsComponentPickerAction?id="&taskid
	Set shel = createObject("Shell.Application")
	shel.ShellExecute url
end if
 
public function getRepositoryId(ByVal instance)
	Dim c
	c = InStrRev (instance.uri, "c")
	if c >0 then
		getRepositoryId = Right(instance.uri, Len(instance.uri) - c)
	else
		getRepositoryId = ""
	end if
end function

sub findService(ByVal task, byref object)
	Dim rel
	for each rel in task.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/task/relationshiptypes/task_content.kmd#AKM_Task_Content"))
		set object = rel.target
	next
	for each rel in task.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/task/relationshiptypes/task_works_on.kmd#AKM_Task_Works_On"))
		set object = rel.target
	next
end sub
'metis:stdmethods#oid7