
rem msgbox ("Found method script file ")
rem Main program
rem to-do: use Dictionary for parameter names/types, 
rem        add namespace and structure for soap messages
rem        ask for values for each undecided parameter interactively      

executeService()

public function executeService()
	Dim serviceUrl, operation, filename, namespace, protocol, param
	dim Document ' global string variable containing the request soap document
	Document = ""

	getWSPproperties serviceUrl, operation, namespace, filename, protocol, param
	getDocument Document, filename

	'msgbox ("WS properties :"&serviceUrl&", "& operation &", "& protocol&", "&namespace)
	if protocol = "POST" then
		executePOST serviceUrl, operation, namespace, Document, param
	elseif protocol = "GET" then
		executeGET serviceUrl, operation, namespace, Document, param
	elseif protocol = "SOAP" then
		executeSOAP serviceUrl, operation, namespace, Document, param
	else
		msgbox("Unable to determine protocol (HTTP GET, HTTP POST, SOAP etc.) for web service.")
	end if
end function

public function getDocument (byref doc, byval filename)
	Dim xmldoc, i
	set xmldoc = CreateObject("Msxml2.DOMDocument.3.0")
	xmldoc.async = false
	xmldoc.load(filename)
	doc = xmldoc.xml
	' remove <?xml ...> node
	i = instr(1, doc, "?>")
	if i > 0 then
		doc = right (doc, len(doc) - i - 1)
	end if
	'msgbox ("XML input from "&filename& " = "&doc)
end function

public function executeGET (byval sUrl, byval operation, byval namespace, byval Document, byval param)
	DIM sParams, connection
	sParams ="?dummy=2&"&param&"="&Document

	rem  Create the HTTP object and Send the request synchronously
	Set connection = CreateObject("Microsoft.XMLHTTP")
	connection.open "GET",  sUrl& "/" & operation & sParams , false
	connection.send ""
	ShowResult connection, sParams, sUrl
end function

public function executePOST(byval sUrl, byval operation, byval namespace, byval Document, byval param)
	Dim sParams, connection
	sParams = param&"="&Document
	rem  Create the HTTP object. 'Set the Content-Type header to the specified value. ' Send the request synchronously
	Set connection = CreateObject("Microsoft.XMLHTTP")
	connection.open "POST", sUrl& "/" &operation, false
 	connection.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
	connection.send sParams 
	ShowResult connection, sParams, sUrl
end function

public function executeSOAP (byval sUrl, byval operation, byval namespace, byref Document, byval param)
	Dim connection, doc
	
	' build soap message
	doc = "<soap:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' "
	doc = doc & "xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'> "
	doc = doc &"<soap:Body> "
    doc = doc &"<"&operation&" xmlns='"&namespace&"'> "
    if len(trim(param)) > 0 then
		doc = doc & "<"&param&">"& Document & "</"&param&">"
	else
		doc = doc & Document 
	end if
    doc = doc &"</"&operation&"> "
	doc = doc &"</soap:Body> "
	doc = doc &"</soap:Envelope> "
'msgbox "SOAP message: "&document

	Set connection = CreateObject("Microsoft.XMLHTTP")
	connection.open "POST", sUrl, false
 	connection.setRequestHeader "Content-Type", "text/xml; charset=utf-8"
 	connection.setRequestHeader "SOAPAction", namespace &operation
 	'connection.setRequestHeader "MessageType", "CALL"
	connection.send doc 
	'"<?xml version='1.0' encoding='utf-8'?>" & document
	ShowResult connection, doc, sUrl
end function

public function showResult (byval connection, byval Document, byval sUrl) 
	'msgbox (connection.responseText)
	' in future version, read paths/names of files for xslt, xml-storage, and html storage from model
	' filenames for output processing:
	dim xmlout, htmlout, xsltin 'filenames
	dim xmlDoc, htmlDoc, xsltDoc, shel, html
	dim text, service, typ, i 'objects

	getFileNames xmlout, htmlout, xsltin
	if connection.status = 200 then
		i = instr(sUrl,"/AKM")
		Set xmlDoc = connection.responseXML
		if i > 0 then
			text = left(sUrl, i-1)
			text = text & connection.responseText
		else
			text = connection.responseText			
		end if
		set typ = metis.findType("http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid5")
		for each service in metis.currentModel.findInstances(typ, "", "" )
			service.setNamedStringValue "ServiceURL", text 
		next
		xmldoc.save(xmlout)
		set xsltDoc = CreateObject("Msxml2.DOMDocument.3.0")
		xsltDoc.async = false
		xsltDoc.load(xsltin)
		html = xmlDoc.transformNode(xsltDoc)
	    set htmlDoc = CreateObject("Msxml2.DOMDocument.3.0")
		htmldoc.loadXML(html)
		htmldoc.save(htmlout)
	else
		msgbox ("Error in web service response. Code: "&connection.status& " Error: "&connection.statusText&" Full response:"&connection.responseText)
		'if len(Document) > 0 then
			' msgbox ("Original Request: "&Document)
			set htmlDoc = CreateObject("Msxml2.DOMDocument.3.0")
			htmlDoc.loadXML(Document)
			htmlDoc.save(htmlout)
		'end if
	end if
		Set shel = createObject("Shell.Application")
		shel.ShellExecute htmlout
end function

public function getFileNames (byref xml, byref html, byref xslt)
	dim root, coll, model, temp
	set model = metis.currentModel
	root = metis.urlToFileName(model.url)
	root = left (root, len(root) - 4) ' & "-" &model.currentInstance.getNamedStringValue("name")
	xml =  root &"-response.xml" 
	html = root &"-response.html" 
	set coll = model.findInstances (metis.findType("metis:stdtypes#oid32"), "Name", "XSLT")
	for each root in coll
		'msgbox ("Found online doc xslt: "&root.getNamedStringValue("name"))
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

Public Function getWSPproperties( BYREF serviceUrl, BYREF operation, byref namespace, byref filename, byref protocol, byref param)

	Dim model, obj, pt, temp, obj2

	serviceUrl = "http://localhost/AKMii/Components/KEE/UpdateAKMii.asmx"
	operation = "CreateOrUpdateForm"
	protocol = "SOAP"
	namespace = "http://tempuri.org/"

	set model = metis.currentModel
	if isNull(model) then
	    msgbox ("No current model in Metis! Select an object and try again!")
	    exit function
	end if
	filename = metis.urlToFileName(model.url)
	filename = left(filename, len(filename) -4) & "_mxl.xml"
	
	'set obj2 = Nothing
	set obj = model.currentInstance
	if (typename(obj) = "Nothing") then
		'msgbox ("current object is nothing")
		getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.findInstances(metis.findType("http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11"), "", "" )
	elseif isNull(obj) then
		'msgbox ("current object is null")
		getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.findInstances(metis.findType("http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11"), "", "" )
	elseif obj.type.uri <> "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11" then
		'msgbox ("current object is not configuration service")
		getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.findInstances(metis.findType("http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11"), "", "" )
	else
		'msgbox ("current object is configuration webservice")
	end if

	'if obj2 <> Nothing then
		'if isEmpty(obj2) or isNull(obj2) or  then
	'	getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.findInstances(metis.findType("http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11"), "", "" )
	'else
	'if (not isEmpty(obj2)) and (not isNull(obj2)) and isObject(obj2) then
	'	msgbox ("isObject")
	'	if obj2.type.uri = "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11" then 
	'		set obj = obj2
	'	else 
	'		obj2 = Nothing
	'	end if
	'end if
	'if obj2 = Nothing then
	'	getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.findInstances(metis.findType("http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11"), "", "" )
	'end if
		'getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.currentInstance.parts 
	'end if
	'	if isNull(obj) then 
	'		getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.currentInstance.parent.parts
	'	end if
	'	if isNull(obj) then 
	'		getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.currentInstance.neighbourObjects
	'	end if
	'	if isNull(obj) then 
	'		getObjectofTypeInCollection obj, "http://xml.computas.com/xml/kee/metamodels/application_ui_database.kmd#oid11", model.currentInstance.parent.neighbourObjects
	'	end if
	'end if
	'if isNull(obj) then
			
	if not isNull(obj) then
		' config webservice found
	on error resume next
		param = obj.getNamedStringValue("Parameter")
		serviceUrl = obj.getNamedStringValue("ServiceURL")
		operation = obj.getNamedStringValue("Operation")
		namespace = obj.getNamedStringValue("Namespace")
	'msgbox ("Service found: "&serviceUrl&"/"&operation&" in "&namespace & " with parameter "&param)
	'dim prop, ut
	'ut = ""
	'for each prop in obj.type.allProperties
	'	ut = ut & "    "& prop.name&"="&obj.getNamedStringValue(prop.name)
	'next
	'msgbox(ut)
		temp = obj.getNamedStringValue("description")
	on error goto 0
		if instr (lcase(temp), "get") > 0 then
			protocol = "GET"
		elseif (instr (lcase(temp), "post") > 0) OR (instr ("http", lcase(temp)) > 0) then
			protocol = "POST"
		else
			protocol = "SOAP"
		end if
	else
		msgbox("Unable to find configuration web service object.")
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


