dim coll, gate, relship, obj, nabo, obje, dif, sfile, collo
Dim dialog, xmlspec, xml, start

' ASK THE USER WHICH FILE TO IMPORT
Set dialog = CreateObject("UserAccounts.CommonDialog") 
sfile = dialog.ShowOpen

if sFile then  ' else= cancel -> quit import, but do manipulation of data structures
  sFile = dialog.FileName
sFile = getXMLUrl (sFile)

' OPEN WSDL IMPORT SPECIFICATION
Set xmlspec = CreateObject("Msxml2.DOMDocument.3.0")
xmlspec.load("C:\Programfiler\Metis\Metis5.2\xml\http\xml.activeknowledgemodeling.com\system\methods\dif-wsdl-pp.xml")
xml = xmlspec.xml

' INSERT CHOSEN FILENAME (AS URL) INTO THE XML SPECIFICATION
filename = "http://xml.activeknowledgemodeling.com/system/methods/wsdl-example.xml"
start = InStr(xml, filename)
while start > 0
    xml = left(xml, start-1) & sFile & right(xml, len(xml) + 1 - start - len(filename))
   start = InStr(xml, filename)
wend

' PERFORM THE SPECIFIED IMPORT
Set dif= CreateObject("Metis.XMLDBIF.5.2")
'sfile = "file:///C|/hdj/dev/client/dif-wsdl-pp.xml"
dif.specificationFileXML = xml

dif.setOption "@createviews@", "true"
dif.targetModel = metis.currentModel
dif.progressBarVisible = true
dif.progressBarLogVisible = true
dif.progressBarLogExpanded = true
'dif.progressBarInteractive = true
On Error Resume Next
dif.executeImport
if Err.number <> 0 then
'MsgBox dif.log
end if
end if

'stop
'MsgBox dif.log

' MERGE ALL Data parameters with their parts
'set coll = metis.currentModel.findInstances (metis.findType("http://xml.activeknowledgemodeling.com/system/objecttypes/parameter.kmd#AKM_Parameter"), "", "")
'for each gate in coll
'   set collo = gate.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/part.kmd#AKM_ParameterPart"))
'   copyTargets collo, gate, true, false
'next
'set coll = metis.currentModel.findInstances (metis.findType("http://xml.activeknowledgemodeling.com/system/objecttypes/parameter.kmd#AKM_Parameter"), "", "")
'for each gate in coll
'   set collo = gate.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/template.kmd#AKM_Template"))
'   copyTargets collo, gate, true, true
'next

'metis.postponeGUIUpdates(true)
'function fff()
' MERGE ALL INPUT MESSAGE WITH THEIR DATA COUNTERPARTS
set coll = metis.currentModel.findInstances (metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task_input.kmd#AKM_Task_Input"), "", "")
for each gate in coll
   set collo = gate.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/part.kmd#AKM_ParameterPart"))
   copyTargets collo, gate, false
next
set coll = metis.currentModel.findInstances (metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task_input.kmd#AKM_Task_Input"), "", "")
for each gate in coll
   set collo = gate.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/template.kmd#AKM_Template"))
   copyTargets collo, gate, true
next
'metis.postponeGUIUpdates(false)
'metis.postponeGUIUpdates(true)
' MERGE ALL OUTPUT MESSAGE WITH THEIR DATA COUNTERPARTS
set coll = metis.currentModel.findInstances (metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task_output.kmd#AKM_Task_Output"), "", "")
for each gate in coll
   set collo = gate.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/part.kmd#AKM_ParameterPart"))
   copyTargets collo, gate, false
next
set coll = metis.currentModel.findInstances (metis.findType("http://xml.activeknowledgemodeling.com/task/objecttypes/task_output.kmd#AKM_Task_Output"), "", "")
for each gate in coll
  set collo = gate.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/template.kmd#AKM_Template"))
   copyTargets collo, gate, true
next
'metis.postponeGUIUpdates(false)
'end function

' UPDATES AN INPUT OUR OUPUT OBJECT WITH THE SPEC OF ITS DATA PARAMETER REPRESENTATION
' NAME, PARTS AND NAMESPACE RELATIONSHIPS ARE MOVED
' The new version workd recursively from the top of the hierarchy, first copying all children 
function copyTargets ( byref collection, byref gate, byval inline)
   dim syn, test, rel, obj
   for each test in gate.views
      set syn = test
   next 
   removeDuplicateTargets collection
   for each rel in collection
      if not (rel is Nothing) and IsObject(rel) then
      'if (obj is Nothing) or not isObject(obj) then
        'msgbox "Relationship has been deleted."
      'else
		set obj = rel.target
		if not (obj is Nothing) and IsObject(obj) then
			'msgbox gate.getNamedStringValue("description") & "-" & obj.getNamedStringValue("name")
			copy obj, gate, syn, rel, inline
		end if
      end if
   next
end function

function copy(byref source, byref parent, byref parentview, byref relationship, byval inline)
   'msgbox "Copying "&source.getNamedStringValue("name")& " to " &parent.getNamedStringValue("name") & " through relation "& relationship.type.name
   dim  nsyn, test, others, moreothers, obje, collo
   ' if the source is a direct atomic node, don't bother with copying it:
    if not (source.getNamedStringValue("dataType") = source.getNamedStringValue("externalID")) then
    
   ' 1st copy in all children of the source object
   if not isRecursive(source, parent) then 
		' test above prevents endless recusrion
		set collo = source.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/part.kmd#AKM_ParameterPart"))
		copyTargets collo, source, false
		set collo = source.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/template.kmd#AKM_Template"))
		copyTargets collo, source, true
	'else 
	   'msgbox "Did not copy children of "&source.getNamedStringValue("name")&":"& source.getNamedStringValue("dataType")& " into " &parent.getNamedStringValue("externalID")&" because of recursion."
	end if
   ' 2nd copy or relocate the object in question
      set others = source.getNeighbourRelationships(1, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/part.kmd#AKM_ParameterPart"))
      set moreothers = source.getNeighbourRelationships(1, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/template.kmd#AKM_Template"))
      if (others.count + moreothers.count) > 1 then 
           ' used multiple times, must copy the object, rather than relocate
           'msgbox "Number of relships for object "& obj.getNamedStringValue("name")& " is " & others.count
            if isObject(source) then
            'and not (isRecursive(source, source)) then
              call delete(relationship)
              copyTemplate source, parent, parentview, inline
            'elseif isObject(source) then
            '	  msgbox "Did not copy "&source.getNamedStringValue("name")& " into " &parent.getNamedStringValue("name")&" because of recursion."
			end if
      ElseIf inline then
                ' represents the same object
          if not (parent.type.name = "Parameter") then
              'msgbox parent.type.name & "not = Parameter"
              parent.setNamedStringValue "name", source.getNamedStringValue("name")
          end if
          'if not isEmpty(parentview) then
          createNamespaceRels source, parentview, parent
          'end if
          for each obje in source.parts
              obje.parent = parent
              if not isEmpty(parentview) then
				parentview.newObjectView obje
			  end if
          next
          call delete(source)
      else  
                ' used only once, relocate
          call delete(relationship)
          for each nsyn in source.views
             on error resume next
             metis.currentModel.currentModelView.deleteObjectView(nsyn)
             on error goto 0
          next 
          source.parent = parent
          if not isEmpty(parentview) then
              set nsyn = parentview.newObjectView(source)
              createNamespaceRels source, nsyn, null
          end if
      end if
      end if
end function

function isRecursive(byref child, byref parent)
    dim typ 
    typ = child.getNamedStringValue("dataType")
    if isNull(typ) or (len(typ) = 0) then
		isRecursive = false
    elseif (typ = parent.getNamedStringValue("externalID")) then
	   isRecursive = true
	elseif (parent.parent is Nothing) or isNull(parent.parent) or isEmpty(parent.parent) or not isObject(parent.parent) then 
	   isRecursive = false
	else
	   isRecursive = isRecursive(child, parent.parent)
	end if
end function

function copyTemplate(byval template, byval parent, byval parentview, byval inline) 
 dim newv, syn, newo, obje, esyn
 metis.currentModel.currentModelView.clearSelection
 'metis.currentModel.currentModelView.select(template.views)
 metis.currentModel.currentModelView.selection = template.views
 if metis.selection.count > 0 then
   'metis.currentModel.currentInstance = metis.currentModel.currentModelView.primarySelection.instance
   'metis.currentModel.currentModelView.currentInstanceView = metis.currentModel.currentModelView.primarySelection
   metis.runCommand "duplicate"
   set newv = metis.currentModel.currentModelView.primarySelection
   set newo = newv.instance
   if not inline then
		newo.parent = parent
		if not isEmpty(newv) then
			metis.currentModel.currentModelView.deleteObjectView(newv)
		end if
		if not isEmpty(parentview) then
			set newv = parentview.newObjectView(newo)
			'metis.currentModel.currentModelView.clearSelection
			'metis.currentModel.currentModelView.selection = newo.views
			'metis.runCommand "ensure-relationship-views"
		end if
		'remove additional relationships in to the cloned object
		for each newv in newo.getNeighbourRelationships(1, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/part.kmd#AKM_ParameterPart"))
			call delete(newv)
		next
		for each newv in newo.getNeighbourRelationships(1, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/template.kmd#AKM_Template"))
			call delete(newv)
		next
		set copyTemplate = newo
	else
	      if not (parent.type.name = "Parameter") then
             'msgbox parent.type.name & "not = Parameter"
             parent.setNamedStringValue "name", newo.getNamedStringValue("name")
          end if
	      for each syn in parent.views
             createNamespaceRels newo, syn, parent
          next
          for each obje in newo.parts
              obje.parent = parent
              for each esyn in obje.views
                  metis.currentModel.currentModelView.deleteObjectView(esyn)
              next
              if not isEmpty(parentView) then
				  parentview.newObjectView obje
			  end if
          next
          call delete(newo)	
	end if
 else 
	msgbox "Selection failed for object "&template.getNamedStringValue("name")
	set copyTemplate = template
 end if
end function

function createNamespaceRels(byval obj, byval syn, byval gate) 
 dim obje, nsyn, test
 for each obje in obj.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/default_namespace.kmd#AKM_Default_namespace_for_parameter"))
     if Not (isEmpty(gate) or isNull(gate)) then
       obje.origin = gate
     end if
     for each test in obje.target.views
       set nsyn = test
     next 
     if not (syn is Nothing or nsyn is nothing) then call metis.currentModel.currentModelView.newRelationshipView(obje, syn, nsyn)
 next
 for each obje in obj.getNeighbourRelationships(0, metis.findType("http://xml.activeknowledgemodeling.com/system/relationshiptypes/namespace.kmd#AKM_Namespace_Parameter"))
     if Not (isEmpty(gate) or isNull(gate)) then
        obje.origin = gate
     end if
     for each test in obje.target.views
        set nsyn = test
     next 
     if not (syn is Nothing or nsyn is nothing) then call metis.currentModel.currentModelView.newRelationshipView(obje, syn, nsyn)
 next
end function

function removeDuplicateTargets ( byref collection)
   dim syn, test, rel, obj, rel2
   
   for each rel in collection
      if (not (rel is Nothing)) or IsObject(rel) then
      'if (obj is Nothing) or not isObject(obj) then
        'msgbox "Relationship has been deleted."
      'else
      	set obj = rel.target
        if obj is nothing then
	        call delete(rel)
	    elseif rel.origin is nothing then
	        call delete(re2)
	    elseif IsObject(obj) then
			'msgbox gate.getNamedStringValue("description") & "-" & obj.getNamedStringValue("name")
			for each rel2 in collection
			    if rel2.target is nothing then
			        call delete(rel2)
			    elseif rel2.origin is nothing then
			        call delete(rel2)
			    elseif (rel2.target.uri = obj.uri) and (not (rel2.uri = rel.uri)) then
					'msgbox  "Delete duplicate relationship."
					'msgbox  rel.origin.getNamedStringValue("name") & "-" & rel.target.getNamedStringValue("name")
					call delete(rel2)
				end if  
			next
			if not (rel.origin is Nothing) then
			    'call metis.currentModel.deleteRelationship(rel)
			    for each rel2 in obj.getNeighbourRelationships(0,nothing)
			        if rel2.target.uri = rel.origin.uri then ' duplicate self reference, delete object
			            call delete(rel2.origin)
			        elseif rel2.origin.uri = rel2.target.uri then' self reference
			            call delete(rel2) 
			        end if
			    next
			end if
		end if
      end if
   next
end function

sub delete(o)
    if o.isRelationship() then
        call metis.currentModel.deleteRelationship(o)
    else 
        dim rel
        for each rel in o.neighbourRelationships
            call delete(rel)
        next
        call metis.currentModel.deleteObject(o)
    end if
end sub

' RETURN THE URL EQUIVALENT TO THE FILENAME
function getXMLUrl(byval str)
 dim  pos, sto
 pos = InStr(str, ":")
 if (pos >0) then
  sto = left(str, pos-1)
  str = "file:///"&Right(sto, 1)&"|/"&Right(str, len(str) - pos - 1)
 end if
 str = replace(str,"\", "/", 1, -1, 1)
 getXMLUrl = str
end function