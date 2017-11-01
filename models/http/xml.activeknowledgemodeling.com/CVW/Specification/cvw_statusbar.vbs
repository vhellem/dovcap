option explicit

class CVW_StatusBar
'[1] ------------------------------------------------------------
 Public Sub topMenuStatus (instView)
  dim topMenuObject, inst

  set inst = instView.instance 
  For each topMenuObject in instView.parent.children 
    if topMenuObject.title = inst.title THEN  
      topMenuObject.open
    else
      topMenuObject.close
    end if
   next

 end sub

'[2] ------------------------------------------------------------
Public  sub populateStatusBars(instView)
 '[a]-------------------------------
 Dim  InputContainerName, InputContainerType
 Dim  titleBarType, titleBar, titleBarString  
 '[b]-------------------------------
 InputContainerName = "CVW_NavigationHome"
 InputContainerType = "metis:stdtypes#oid3"
 '[c]-------------------------------
  set titleBarType  = metis.findType("http://metadata.troux.info/meaf/objecttypes/general_object.kmd#CompType_MEAF:GeneralObject_UUID")
 set titleBar  = model.findInstances(titleBarType, "comments" ,"CVW_TitleBar")
   ' --- Updater Navigation Bar 
   titleBarString = "> " & instView.title
   titleBar.item(1).setNamedStringValue "name", titleBarString  
 end sub



end class

