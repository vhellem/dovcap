' Export variant parameters

set model  = metis.currentModel
set ccObj  = model.currentInstance

set GLOBAL_Type_hasVP  = metis.findType("http://xml.chalmers.se/class/has_variant_parameter.kmd#has_variant_parameter")
set GLOBAL_Type_VP     = metis.findType("http://xml.chalmers.se/class/variant_parameter.kmd#variant_parameter")
set GLOBAL_Type_EkaValue         = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_value.kmd#ObjType_EKA:StringValue_UUID")
set GLOBAL_Type_EkaHasValue      = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasValue_UUID")
set GLOBAL_Type_EkaHasDefinition = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#RelType_EKA:HasDefinition_UUID")

' Find the variant parameters
set parameterDefs = ccObj.getNeighbourObjects(0, GLOBAL_Type_hasVP, GLOBAL_Type_VP)
if parameterDefs.count = 0 then
    MsgBox "No export is done due to that there are no parameters to export!"
else
    'Find the parameter values
    set parameterValues = ccObj.getNeighbourObjects(0, GLOBAL_Type_EkaHasValue, GLOBAL_Type_EkaValue)

'stop
	' Open Excel
	set XLSApplication = CreateObject("Excel.Application")
	XLSApplication.Workbooks.Add
	XLSApplication.Visible = true
	i=0
	for each param in parameterDefs
		i = i + 1
		XLSApplication.Cells(1,i).Value = param.title 'Names in row 1
		' Find correct value
		found = false
		sval = ""
		for each value in parameterValues
            set paramDefs = value.getNeighbourObjects(0, GLOBAL_Type_EkaHasDefinition, GLOBAL_Type_VP)
            for each paramDef in paramDefs
                if paramDef.uri = param.uri then
                    sval = value.getNamedStringValue("value")
                    found = true
                    exit for
                end if
            next
            if found then exit for
		next
		XLSApplication.Cells(2,i).Value = sval
	next
	XLSApplication.ActiveWindow.Zoom = 100
end if



