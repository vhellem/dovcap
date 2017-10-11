rem Main program
rem to-do: use Dictionary for parameter names/types, 
rem        add namespace and structure for soap messages
rem        ask for values for each undecided parameter interactively      

Option explicit
dim serviceObject ' global object holding the weboperation to be invoked
dim Document ' global string variable containing the request soap document

dim typeuri_ws_op = "http://xml.activeknowledgemodeling.com/system/objecttypes/web_service_operation.kmd#AKM_Web_Service_Operation"
dim typeuri_ws = "http://xml.activeknowledgemodeling.com/system/objecttypes/web_service.kmd#AKM_Web_Service"
dim typeuri_ws_port = "ttp://xml.activeknowledgemodeling.com/system/objecttypes/web_service_port.kmd#AKM_Web_Service_Port"
dim typeuri_parameter = "http://xml.activeknowledgemodeling.com/system/objecttypes/parameter.kmd#AKM_Parameter"
dim typeuri_parameter_value = "http://xml.activeknowledgemodeling.com/system/relationshiptypes/value_for_parameter.kmd#AKM_Parameter_Value"

dim property_type = "dataType"
dim property_value = "value"

Document = ""
executeService()

public function executeService()
	Dim serviceUrl, operation, inputmessage, names, values, types, namespace, protocol, temp

	names = null
	getWSPproperties serviceUrl, operation, inputmessage, protocol
	if not isNull(inputmessage) then
		getInputParameters inputmessage, names, values, types
		getNamespace inputmessage, namespace
	end if
	if protocol = "POST" then
		executePOST serviceUrl, operation, names, values, types
	elseif protocol = "GET" then
		executeGET serviceUrl, operation, names, values, types
	elseif protocol = "SOAP" then
		executeSOAP serviceUrl, operation, inputmessage, namespace
	else
		msgbox("Unable to determine protocol (HTTP GET, HTTP POST, SOAP etc.) for web service.")
	end if
end function

public function executeGET (byval sUrl, byval operation, BYREF names, BYREF values, BYREF types)
	DIM sParams, name, value, connection
	sParams ="?dummy=2&"
	' for some reasons, the first parameter tends to be ignored by some servers, therefor add dummy one 
	if not isNull(names) then
		while names.Count > 0
			name = names.dequeue
			value = values.dequeue
			sParams = sParams & name &"="& value &"&"
		wend
	end if
	sParams = left ( sParams, len(sParams) -1)
	rem  Create the HTTP object and Send the request synchronously
	Set connection = CreateObject("Microsoft.XMLHTTP")
	connection.open "GET",  sUrl& "/" & operation & sParams , false
	connection.send ""
	ShowResult connection
end function

public function executePOST(BYval sUrl, BYVAL operation, BYREF names, BYREF values, BYREF types)
	Dim sParams, name, value, connection
	sParams =""
	if not isNull(names) then
		while names.Count > 0
			name = names.dequeue()
			value = values.dequeue()
			sParams = sParams & name &"="& value &"&"
		wend
	end if
	sParams = left ( sParams, len(sParams) -1)
	rem  Create the HTTP object. 'Set the Content-Type header to the specified value. ' Send the request synchronously
	Set connection = CreateObject("Microsoft.XMLHTTP")
	connection.open "POST", sUrl& "/" &operation, false
 	connection.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
	connection.send sParams 
	ShowResult connection
end function

public function executeSOAP(BYval sUrl, BYval operation, Byref inputmessage, byval namespace)
	Dim param, name, value, connection, message, part
	message = inputmessage.getNamedStringValue("name")
	
	' build soap message from inputmessage structure
	document = "<soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' "
	document = document & "xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'> "
	document = document &"<soap:Body> "
    document = document &"<"&message&" xmlns='"&namespace&"'> "
	for each part in inputmessage.parts
		getParameterTree document, part, inputmessage.parent, false
	next
    'getParameterTree document, inputmessage, inputmessage.parent
    document = document &"</"&message&"> "
	document = document &"</soap:Body> "
	document = document &"</soap:Envelope> "
'msgbox "SOAP message: "&document

	Set connection = CreateObject("Microsoft.XMLHTTP")
	connection.open "POST", sUrl, false
 	connection.setRequestHeader "Content-Type", "text/xml; charset=utf-8"
 	connection.setRequestHeader "SOAPAction", namespace&operation
 	'connection.setRequestHeader "MessageType", "CALL"
	connection.send document 
	'"<?xml version='1.0' encoding='utf-8'?>" & document
	ShowResult connection
end function

'append a the XML representation of a parameter to the doc string for Soap requests
' the final boolan parameter is just to avoid outputting the name of the message twice, 
' because its already done when invoking the method on the topleve message (input or output element
public function getParameterTree (byref doc, byval node, byref top, byval duplicate)
	dim name, value, part, subname, desc, i
	name = node.getNamedStringValue("name")
	' in case of recursion by name lookup (below) do not add duplicates tags
	'i = instrrev(doc, "<"&name&">", -1, vbTextCompare)
	'if node.type.uri = "http://xml.metis.no/xml/object_types/attribute.kmd#oid1" then
	'	exit function ' attributes represents alternative values, all shoukld not be included
	'end if
	desc = node.getNamedStringValue(property_type)
	if not duplicate then
		if isnull(desc) or len(desc) = 0 then 
			doc = doc & "<"&name&">"
		else 
			desc = trim (desc)
			doc = doc & "<"&name&" xsi:type='"&desc&"'>"
		end if		
	end if
	if node.parts.count > 0 then
		'decomposed node, recursive ...
		for each part in node.parts
			getParameterTree doc, part, top, false
		next
	else 'output value
	    getParameterValue node, name, value
		doc = doc & value
	end if
	if not duplicate then
		doc = doc & "</"&name&"> "
	end if
end function

' Returns the value of the parameter, extracted from the context unless explicitly provided
public function getParameterValue(byval parameter, byval name, byref val)
	if not isNull(parameter) then
		val = parameter.getNamedStringValue(property_value
		if (val = "") then
			getValueInCollection name, val, parameter.parts
		end if
		if (val = "") then
			getValueInCollection name, val, parameter.neighbourObjects
		end if
		if (val = "") and (not isNull (serviceObject.parent)) then
			getValueInCollection name, val, parameter.parent.parts
		end if
		if (val = "") and (not isNull (serviceObject.parent)) then
			getValueInCollection name, val, parameter.parent.neighbourObjects
		end if
	end if	
end function

public function getValue(byval name, byref val)
	getParameterValue serviceObject, name, val
end function

public function getValueInCollection(byval name, byref val, byref collection)
	dim part, temp
	on error resume next
	val = ""
	For each part in collection
		if part.getNamedStringValue("name") = name then
			temp = trim(part.getNamedStringValue("value"))
			if isNull(temp) or len(temp) = 0 then
				temp = trim(part.getNamedStringValue("description"))
			end if
			if (not isNull(temp)) and len(temp) > 0 then
				val = temp
				exit for
			end if
		else 
'msgbox("Did not find value for "&name&" in object "&part.getNamedStringValue("name"))
		end if
	next
	on error goto 0
end function

public function showResult (byval connection) 
	msgbox (connection.responseText)
	' in future version, read paths/names of files for xslt, xml-storage, and html storage from model
	' filenames for output processing:
	dim xmlout, htmlout, xsltin 'filenames
	dim xmlDoc, htmlDoc, xsltDoc, shel, html 'objects

	getFileNames xmlout, htmlout, xsltin
	if connection.status = 200 then
		Set xmlDoc = connection.responseXML
		xmldoc.save(xmlout)
		set xsltDoc = CreateObject("Msxml2.DOMDocument.3.0")
		xsltDoc.async = false
		xsltDoc.load(xsltin)
		html = xmlDoc.transformNode(xsltDoc)
	    set htmlDoc = CreateObject("Msxml2.DOMDocument.3.0")
		htmldoc.loadXML(html)
		htmldoc.save(htmlout)
		Set shel = createObject("Shell.Application")
		shel.ShellExecute htmlout
	else
		msgbox ("Error in web service response. Code: "&connection.status& " Error: "&connection.statusText&" Full response:"&connection.responseText)
		if len(Document) > 0 then
			msgbox ("Original Request: "&Document)
		end if
	end if
end function

public function getFileNames (byref xml, byref html, byref xslt)
	dim root, coll, model, temp
	set model = metis.currentModel
	root = metis.urlToFileName(model.url)
	root = left (root, len(root) - 4) & "-" &model.currentInstance.getNamedStringValue("name")
	xml =  root &"-response.xml" 
	html = root &"-response.html" 
	set coll = model.findInstances (metis.findType("metis:stdtypes#oid32"), "Name", "XSLT")
	for each root in coll
		msgbox ("Found online doc xslt: "&root.getNamedStringValue("name"))
		xslt = trim(root.getNamedStringValue("filename"))
		if (not isNull(xslt)) and (len(xslt) > 0) then
			xslt = metis.urlToFileName(xslt)
			exit function
		end if
	next
	set coll = model.findInstances (metis.findType("metis:stdtypes#oid32"), "", "")
	for each root in coll
		set temp = root.getNamedValue("filename")
		if (not isNull(temp)) then
			temp = temp.getString()
			if (len(temp) > 0) then
				xslt = metis.urlToFileName(temp)
				exit function
			end if
		end if
	next
	' default value:
	xslt = metis.getProperty("System_InstallationDirectory")&"/xml/http/xml.computas.com/xml/kee/methods/wsresult2html.xslt"
end function

Public Function getWSPproperties( BYREF serviceUrl, BYREF operation, BYREF inputmessage, BYREF protocol)

	Dim model, obj, pt
	Dim inputs, iName, iValue, iType, temp

	serviceUrl = ""
	operation = ""
	protocol = ""
	inputmessage = null

	set model = metis.currentModel
	set serviceObject = model.currentInstance
	operation = serviceObject.getNamedStringValue("name")
'msgbox ("Invoking webservice: "& operation)
	rem set temp = serviceObject.parent.neighbourObjects
	
	' find mechanism
	getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid6", serviceObject.parts 
	if isNull(obj) then 
		getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid6", serviceObject.parent.parts
	end if
	if isNull(obj) then 
		getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid6", serviceObject.neighbourObjects
	end if
	if isNull(obj) then 
		getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid6", serviceObject.parent.neighbourObjects
	end if
	if not isNull(obj) then
		serviceUrl = obj.getNamedStringValue("description")
		'msgbox ("Invoking webservice: "& serviceUrl &" from mechanism "& obj.uri&" of type"&obj.type.uri)
		temp = obj.getNamedStringValue("name")
		if instr (lcase(temp), "soap") > 0 then 
			protocol = "SOAP"
		elseif instr (lcase(temp), "get") > 0 then
			protocol = "GET"
		elseif (instr (lcase(temp), "post") > 0) OR (instr ("http", lcase(temp)) > 0) then
			protocol = "POST"
		else
			temp = msgbox("Unable to determine protocol for web service. Use HTTP GET?", vbYesNoCancel)
			if temp = vbYes then 
				protocol = "GET"
			elseif temp= vbNo then
				temp = msgbox("Use HTTP POST?", vbYesNoCancel)
				if temp = vbYes then 
					protocol = "POST"
				elseif temp= vbNo then
					temp = msgbox("Use SOAP?", vbYesNoCancel)
					if temp = vbYes then 
						protocol = "SOAP"
					end if
				end if
			end if
		end if
	else
		msgbox("Unable to find web service url and protocol.")
	end if

	' find input
	getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid3", serviceObject.parts 
	if isNull(obj) then 
		getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid3", serviceObject.neighbourObjects
	end if
	if isNull(obj) then 
		getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid3", serviceObject.parent.parts
	end if
	if isNull(obj) then 
		getObjectofTypeInCollection obj, "http://xml.metis.no/xml/object_types/flowlogic.kmd#oid3", serviceObject.parent.neighbourObjects
	end if
	'if found input, find information object (message)
	if not isNull(obj) then
		getObjectofTypeInCollection pt, "http://xml.metis.no/xml/object_types/information_object.kmd#oid1", obj.neighbourObjects
		if isnull(pt) then
			getObjectofTypeInCollection pt, "http://xml.metis.no/xml/object_types/information_object.kmd#oid1", obj.parent.neighbourObjects
		end if
		if not isnull(pt) then
			set inputmessage = pt
		end if
	end if
	if isNull(inputmessage) then
		msgbox("Unable to find input message object.")
	end if
End Function

public function getObjectofTypeInCollection(byref object, byval typeuri, byref collection)
	dim o
	object = null
	on error resume next
	For each o in collection
		if o.type.uri = typeuri then
			set object = o
			'msgbox ("Found "&typeuri& ": "&object.uri& "-" &object.type.uri )
			exit for
		end if
	next
	on error goto 0
end function

Public Function getInputParameters(BYREF inputmessage, BYREF names, BYREF values, BYREF types)

	Dim model, obj, part
	Dim inputs, value, sNames, sValues, sTypes, temp, tempo
	
	set names = CreateObject("System.Collections.Queue")
	set types = CreateObject("System.Collections.Queue")
	set values = CreateObject("System.Collections.Queue")
	
	if Not IsObject(inputmessage) then  
		'msgbox ("Found No Parameters")
		' names = Array() values = Array()	types = Array()
		exit function
	end if
	
	sNames = ""
	sValues = ""
	sTypes = ""
	For each part in inputmessage.parts
		set temp = part.neighbourObjects
		if temp.isEmpty then
			names.Enqueue(part.getNamedStringValue("name"))
			getValue part.getNamedStringValue("name"), value
			values.Enqueue(value)
			types.Enqueue(part.getNamedStringValue("description"))
			'sNames = sNames &",'"&part.getNamedStringValue("name")&"'"
			'sValues = sValues &",'"&part.getNamedStringValue("description")&"'"
			'sTypes = sTypes & ",'"&part.getNamedStringValue("description")&"'"
		else
			For each obj in temp
				rem soap case: goto structure that contains actual parameters, set inoutmessage and namespace for later traversal
				if obj.type.uri = "http://xml.metis.no/xml/object_types/information_object.kmd#oid1" then
					set inputmessage = obj
					' get namespace from parent, mainly relevant for soap and other protocols where the parameter structure is not
					' determined by message elements, but through initial xsd part
					set obj = inputMessage.parent
					'if not isnull(obj) then
					'	namespace = obj.getNamedStringValue("name")
					'end if
					'getInputParameters inputmessage, names, values, types, namespace
					exit function		
				end if
			next
		end if
	Next
'msgbox ("Found "&names.Count() &" Parameters: "& names.ToString() &" with types "& types.ToString())
End Function

public function getNamespace (Byval inmessage, byref nmsp)
	dim candidates, candidate, n
	nmsp = ""
	if not isnull(inmessage.parent) then
		if (inmessage.parent.uri = "http://xml.metis.no/xml/object_types/informationgroup.kmd#oid1" ) then
			nmsp = inmessage.parent.getNamedStringValue("name")
		end if
	end if
	if nmsp = "" then 'not found, search for any informationgroup in model
		set candidates = metis.currentmodel.findInstances(metis.findType("http://xml.metis.no/xml/object_types/informationgroup.kmd#oid1"), "", "")
		if (not isnull(candidates)) then
			for each candidate in candidates 
				n = candidate.getNamedStringValue("name")
				if (not isNull(n)) and len(trim(n)) > 0 then
					nmsp = n
					if InStr(1, n, "schema", 1) <= 0  then ' mask out mapping object, but keep it as value if nothing else found
						exit function
					end if
				end if
			next
		end if
	end if
end function

