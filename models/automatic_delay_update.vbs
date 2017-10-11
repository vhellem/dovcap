Option Explicit
'*********************************************************************
'Troux R&D prototype software, MPCE
'April 2005
'*********************************************************************

'Global variables
Dim objCurrentModel, objCurrentInstance, object
DIM d, nd

d = 0
nd = 0

' Store initial current model and instance                           
Set objCurrentModel = metis.currentModel
Set objCurrentInstance = objCurrentModel.currentInstance

for each object in objCurrentModel.findInstances(metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task.kmd#AKM_Task"), "", "")
	if isDelayed(object) then
		call object.setNamedStringValue("delayed", "1")
		d = d + 1
	else
		call object.setNamedStringValue("delayed", "0")
		nd = nd + 1
	end if
next
msgbox "Updated delay status on all tasks in the model: "& d &" tasks were delayed, " &nd & " were not."

function isDelayed(byval object)
	DIM actual, planned, status
	isDelayed = false
	status = object.getNamedValue("status_AKM").getInteger()
	select case status
	case -1, 0, 5 ' not started
		planned = getDate(object,"plannedStartDate")
		if not (planned = Empty) then
			if dateDiff("d", planned, Now) > 0 then 
				isDelayed = true
				exit function
			end if
		else
			'msgbox "Task not started: " &object.getNamedStringValue("name")& " has no planned start."
		end if
		planned = getDate(object,"plannedFinishDate")
		if not (planned = Empty) then
			 'msgbox dateDiff("d", planned, now)
			if dateDiff("d", planned, Now) > 0 then 
				isDelayed = true
				exit function
			end if
		else
			'msgbox "Task not started: " &object.getNamedStringValue("name")& " has no planned finish."
		end if
	case 1, 2, 3 ' ongoing
		planned = getDate(object, "plannedStartDate")
		actual = getDate(object,"actualStartDate")
		if not ((planned = Empty) or (actual = Empty)) then
			'msgbox dateDiff("d", planned, actual)
			if dateDiff("d", planned, actual) > 0 then
				isDelayed = true
				exit function
			end if
		else
			'msgbox "Task not started: " &object.getNamedStringValue("name")& " has no planned or actual start."
		end if
		planned = getDate(object,"plannedFinishDate")
		if not (planned = Empty) then
			'msgbox dateDiff("d", planned, now)
			if dateDiff("d", planned, Now) > 0  then 
				isDelayed = true
				exit function
			end if		
		else
			'msgbox "Task not started: " &object.getNamedStringValue("name")& " has no planned finish."
		end if
	case 4, 6 ' completed
		isDelayed = false
	end select
end function

function getDate(byval object, byval prop) 
	Dim datestring
	getDate = null
	set datestring = object.getNamedValue(prop)
	if datestring is nothing then
		exit function
	end if
	datestring = datestring.getDate()
	if len(trim(datestring)) = 0 then
		exit function
	end if
	'msgbox prop&" of object "&object.getNamedStringValue("name")& " = "&datestring
	getDate = CDate(datestring)
	'if isDate(datestring) then
	'	msgbox prop&" of object "&object.getNamedStringValue("name")& " = "&datestring&" is date."
	'	msgbox getDate
	'else 
	'	msgbox object.getNamedStringValue("name")& " has no "&prop&":" &datestring
	'end if
end function