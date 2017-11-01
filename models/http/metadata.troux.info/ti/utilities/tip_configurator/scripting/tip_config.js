
//-------------------------
//TIP Configurator Utility
//
//Owner: Troux TSG
//
//Author: Dan Belville
//
//Updated By: Justin Turner Arthur, Evan Williams
//
//Updated Date: August, 2008
//
//Date: May, 2006
//
//Copyright (C) 2006 Troux Technologies. All rights reserved.
//
//SCRIPT PURPOSE:
//
//   Used to generate TIP configuration information from a Metis Model.  Currently the script generates
//   a TIP Type Constraints File and a Customer Configuration File used to define Navigators.
//
//GUIDE FOR USING THIS SCRIPT
//
//GUIDE FOR CONFIGURING THIS SCRIPT
//-------------------------


//-------------------------
//Initialize constants
//-------------------------
var PARAM_STR_CONTAINER_TYPE_URI = "metis:stdtypes#oid3";
var PARAM_BOL_GENERATE_SIDEBARS = false;
var PARAM_BOL_ADDITIONAL_PROPERTY_BOX = false;
var PARAM_BOL_RELATIONSHIP_BOX = false;

//-------------------------
//Call the main function that will execute the TIP Configuration script
//-------------------------

main();

//-------------------------
//Main function for script
//-------------------------
function main()
{
	//-------------------------
	//Declares an instance of the model, modelview and objects to add
	//-------------------------
	var ifModel = metis.currentModel;
	var ifModelView = ifModel.currentModelView;
	var objectsToAdd = null;
	
	//-------------------------
	//The relationship layout to use, is defined in the relationship XML method
	//-------------------------
	var relLayoutToUse = "";
	
	//-------------------------
	//Get global overrides from button properties if the user has edited them, else the defaults will be used
	//-------------------------
	
	overrideFromMetis("PARAM_BOL_GENERATE_SIDEBARS",PARAM_BOL_GENERATE_SIDEBARS, ifModel);
	overrideFromMetis("PARAM_BOL_ADDITIONAL_PROPERTY_BOX",PARAM_BOL_ADDITIONAL_PROPERTY_BOX, ifModel);
	overrideFromMetis("PARAM_BOL_RELATIONSHIP_BOX",PARAM_BOL_RELATIONSHIP_BOX, ifModel);
	overrideFromMetis("PARAM_STR_CONTAINER_TYPE_URI",PARAM_STR_CONTAINER_TYPE_URI, ifModel);
	
	//-------------------------
	//Get the layout string to append to the layout type. Default value is Layout, but may be specified by editing the
	//'Layout' property of the action button
	//-------------------------
	var layoutString = ifModel.currentInstance.getNamedValue("Layout").getString();

	//-------------------------
	//Popup showing that the TIP Portal Configurator has succesfully started
	//-------------------------
	shell.popup("Welcome to the Troux TIP Portal Configurator");

	//-------------------------
	//Unimplemented currently. The intended function is unknown so keeping here for reference.
	//-------------------------
	var objMetisProgressDialog = new ActiveXObject("Metis.ProgressBar." + metis.versionMajor + "." + metis.versionMinor);
	objMetisProgressDialog.title = "TIP Configuration Status Indicator";
	objMetisProgressDialog.interactive = true;
	objMetisProgressDialog.logVisible = true;
	objMetisProgressDialog.logExpanded = false;
	objMetisProgressDialog.setProgressStatus("Initializing");
	var progress = 1;
	
	//-------------------------
	//Build the container select dialog tree
	//-------------------------
	var ifDialog = new ActiveXObject("Metis.SelectDialog." + metis.versionMajor + "." + metis.versionMinor);
	ifDialog.title = "TIP Portal Configurator";
	ifDialog.heading = "Select containers used to configure TIP";
	ifDialog.singleSelect = false;
	ifDialog.columnLabel = true;
	ifDialog.columnURI = false;
	ifDialog.columnType = false;
	ifDialog.viewTree = true;
	
	//-------------------------
	//Get all instances with a view in the specified model view (filter on object type)
	//-------------------------
	var ifInstanceColl = metis.newInstanceList();
	ifInstanceColl = GetAllInstancesInModelViewRecursively(ifModelView.children, PARAM_STR_CONTAINER_TYPE_URI, ifInstanceColl);
	
	if(ifInstanceColl.count == 0)
	{
		shell.popup("No instances in current view");
		return;
	}
	
	//-------------------------
	//Add the container objects to the tree dialog and display the select dialog
	//-------------------------
	ifDialog.addData(ifInstanceColl);
	var ifSelectedColl = ifDialog.show();
	
	if(ifSelectedColl.count == 0)
	{
		shell.popup("No instances selected or cancel button pressed.\nExiting Tip Configurator.");
		return;
	}
	
	//-------------------------
	//Create the XMLDOM object and create the <configuration/> node as the top-level node
	//-------------------------
	var navigatorXmlDoc = new ActiveXObject("Microsoft.XMLDOM");
	navigatorXmlDoc.async = "false";
	navigatorXmlDoc.appendChild(navigatorXmlDoc.createElement("configuration"));
	
	//-------------------------
	//Prompts for a .log file to save error logging information
	//------------------------- 
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	shell.popup("Enter a filename to store tip generation logging information.");
	var logFileName = SelectFileFromDialog("Navigator Config Log File (*.log)");
	if(logFileName == null || logFileName == "")
	{
		return;
	}
	var logFile = fso.OpenTextFile(logFileName, 8, true);
	
	//-------------------------
	//Builds the XMLDOM into memory, parsing through components, subcomponents and relationships
	//-------------------------
	ExecuteBuildWidgetLayouts(navigatorXmlDoc, layoutString, ifSelectedColl);
	
	//-------------------------
	//Prompts for the user for where to save the output file as an .xml
	//-------------------------
	var XMLNavigatorSaveFile = new String;
	
	while(XMLNavigatorSaveFile.indexOf(".xml") != XMLNavigatorSaveFile.length - 4)
	{
		var path = new String;
		XMLNavigatorSaveFile = metis.getFileName("*.xml",0);
		if(XMLNavigatorSaveFile == null || XMLNavigatorSaveFile == "")
		{
			return;
		}
	}
	var indentOrigLen = 0;
	//formatXml(navigatorXmlDoc.documentElement, "  ")
	navigatorXmlDoc.save(XMLNavigatorSaveFile);
	
	//-------------------------
	//Close all open file streams and set their reference to null
	//-------------------------
	logFile.close();
	logFile = null;
	fso = null;
	
	//-------------------------
	//Inform the user that the script has finished
	//-------------------------
	shell.popup("Files Generated");
	
	//-------------------------
	//Set the container list to null for future runs of the script
	//-------------------------
	ifSelectedColl = null;
}

//-------------------------
//Function that creates the XML for the component types and the relationships
//-------------------------
function ExecuteBuildWidgetLayouts(navigatorXmlDoc, layoutString, ifSelectedColl)
{
	//Variables
	var navigatorConfiguration, navigatorNavigator, navigatorName, navigatorMaxComponentsInList, navigatorCustomWidgetLayout;
	var ifInstance;
	var repositoryCheck, alreadyAdded, ifObjectInObjectsToAdd;
	var ifObjectSelected, ifPart, ifParts, ifObjectTypeUUID, objectToAdd, navigatorTypes, navigatorType;
	var ifInstanceName;
	var ifObjectTypeTitle, navigatorWidgetUI, navigatorLayouts, navigatorWidgetUIName, navigatorWidgetUILayoutConfig;
	var navigatorWidgetUIPropertyBoxes, navigatorWidgetUICommonProperties;
	var navigatorWidgetUIPropertiesName, navigatorWidgetUIPropertiesDescription, navigatorWidgetUIPropertiesObjectType, navigatorWidgetUIPropertiesAncestorPath, navigatorWidgetUIPropertiesAncestorPathWidgetConfig, navigatorWidgetUIProperties;
	var navigatorWidgetUIWidgetConfigSetting1, navigatorWidgetUIWidgetConfigSetting2, navigatorWidgetUIWidgetConfigSetting3;
	var navigatorWidgetUIPropertiesLastModification, navigatorWidgetUIPropertiesRootProperties;
	var relColl, ifRel, ifRelTypeUUID, isOrigin, relInfo;
	var relsToAdd, relToAdd, relRepositoryCheck, relAlreadyAdded, ifRelInRelsToAdd, navigatorWidgetUIPropertiesRelNames;
	var navigatorRelNamesSetting1, navigatorRelNamesSetting2, navigatorWidgetUICommonPropertiesBoxType;
	var navigatorRelNamesWidgetConfig, navigatorRelNamesWidgetConfigSetting1, navigatorRelNamesWidgetConfigSetting2;
	var navigatorRelNamesWidgetConfigSetting3, navigatorRelNamesWidgetConfigSetting4, navigatorRelNamesWidgetConfigSetting5;
	var navigatorWidgetUIPropertyBoxesLabelColumnWidth, navigatorWidgetUINameSetting1, navigatorWidgetUINameSetting2, navigatorWidgetUINameSetting3;
	var navigatorRelationshipSetting1, navigatorRelationshipSetting2, navigatorRelationshipSetting3, navigatorWidgetUIAddPropProperties;
	var navigatorAdditionalPropertiesSetting1, navigatorAdditionalPropertiesSetting2, navigatorAdditionalPropertiesSetting3;
	var navigatorWidgetUIRelationships, navigatorWidgetUIRelationshipProperties, navigatorWidgetUICommonPropsBoxType, navigatorWidgetUIAdditionalProperties;
	var objectParts, objectPart, objectPartUUID, navigatorWidgetUIPropertiesPartNames;
	var navigatorPartNamesWidgetConfig, navigatorPartNamesWidgetConfigSetting1, navigatorPartNamesWidgetConfigSetting3;
	var navigatorPartNamesWidgetConfigSetting4, navigatorPartNamesWidgetConfigSetting5, navigatorPartNamesSetting1, navigatorPartNamesSetting2;
	var collapseProperties, collapseRelationships;
	var objectToLayout;

	repositoryCheck = 0;
	alreadyAdded = 0;

	//Find the top level XML node and build the 'widgetUI' and 'layouts' nodes
	navigatorConfiguration = navigatorXmlDoc.getElementsByTagName("configuration").item(0);
	navigatorWidgetUI = navigatorXmlDoc.createElement("group");
	navigatorWidgetUI.setAttribute("name", "widgetUI");

	navigatorLayouts = navigatorXmlDoc.createElement("list");
	navigatorLayouts.setAttribute("name", "layouts");
	
	//Iterate through each view specified by the user
	for(var i = 1; i <= ifSelectedColl.count; i++)
	{
			
		//Replace spaces with underscores in the container name
		ifInstanceName = new String;
		ifInstanceName = ifSelectedColl(i).name;
		ifInstanceName = ifInstanceName.replace(" ", "_");
		objectsToAdd = metis.newInstanceList();
		
		ifParts = ifSelectedColl(i).parts;
		
		//Iterate through each component type in the current view
		for(var j = 1; j <= ifParts.count; j++)
		{
			if(ifParts(j).type.inherits(metis.findType("metis:mer#MerObjectProp")))
			{
				repositoryCheck = 2;
				repositoryCheck = ifParts(j).getNamedValue("dbms-admin.system-uploaded").getInteger();

				//Check that the component is actually commitable to the metaverse
				if (repositoryCheck != 2)
				{
					alreadyAdded = 0;
					
					//Iterate throught the current list of objects to be added
					for(var k = 1; k <= objectsToAdd.count; k++)
					{
						//Check if the current object type has been added or not
						if (ifParts(j).type.title == objectsToAdd(k).type.title)
						{
							alreadyAdded = 1;
							break;
						}
					}
					if (alreadyAdded == 0)
					{
						//Add the object to the list of objects to be included in the XML file
						if (ifParts(j).parent.type.uri == PARAM_STR_CONTAINER_TYPE_URI)
						{
							objectsToAdd.AddLast(ifParts(j));
						}
					}
				}
				//Check the subcomponents for unique object types and add them to the list if needed
				addObjects(ifParts(j));
			}
		}
		
		//Iterate through the list of objects to be added and build the XML file
		for(var j = 1; j <= objectsToAdd.count; j++)
		{
			relsToAdd = metis.newInstanceList();
			
			//Split the UUID from the uri
			var temp = new String;
			temp = objectsToAdd(j).type.uri;
			temp = temp.split("#", 2);
			ifObjectTypeUUID = temp[1];
			
			//Create the component type node	
			temp = objectsToAdd(j).type.title;
			temp = temp.replace(" ", "_");
			ifObjectTypeTitle = temp;
			navigatorWidgetUIName = addXMLNode(navigatorXmlDoc, navigatorLayouts, "group", new Array("name", "replace"), new Array(ifInstanceName + layoutString + ifObjectTypeTitle, "true"));
			navigatorWidgetUILayoutConfig = addXMLNode(navigatorXmlDoc, navigatorWidgetUIName, "group", new Array("name"), new Array("layoutConfig"));
			navigatorWidgetUIPropertyBoxes = addXMLNode(navigatorXmlDoc, navigatorWidgetUILayoutConfig, "list", new Array("name"), new Array("propertyBoxes"));
			navigatorWidgetUICommonProperties = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertyBoxes, "group", new Array("name"), new Array("commonProperties"));
			navigatorWidgetUIProperties = addXMLNode(navigatorXmlDoc, navigatorWidgetUICommonProperties, "list", new Array("name"), new Array("properties"));
			navigatorWidgetUIPropertiesName = addXMLNode(navigatorXmlDoc, navigatorWidgetUIProperties, "group", new Array("name"), new Array("name"));
			navigatorWidgetUIPropertiesDescription = addXMLNode(navigatorXmlDoc, navigatorWidgetUIProperties, "group", new Array("name"), new Array("description"));
			navigatorWidgetUIPropertiesObjectType = addXMLNode(navigatorXmlDoc, navigatorWidgetUIProperties, "group", new Array("name"), new Array("objectType"));
			navigatorWidgetUIPropertiesAncestorPath = addXMLNode(navigatorXmlDoc, navigatorWidgetUIProperties, "group", new Array("name"), new Array("ancestorPath"));
			navigatorWidgetUIPropertiesAncestorPathWidgetConfig = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesAncestorPath, "group", new Array("name"), new Array("widgetConfig"));
			navigatorWidgetUIWidgetConfigSetting1 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesAncestorPathWidgetConfig, "setting", new Array("name", "value"), new Array("drillthroughURL", "/do/widget/editComponent?layoutType=" + ifInstanceName + layoutString + "&mode=view"));
			navigatorWidgetUIWidgetConfigSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesAncestorPathWidgetConfig, "setting", new Array("name", "value"), new Array("rootText", "Top-level"));
			navigatorWidgetUIWidgetConfigSetting3 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesAncestorPathWidgetConfig, "setting", new Array("name", "value"), new Array("selfText", "This item"));
			navigatorWidgetUIPropertiesLastModification = addXMLNode(navigatorXmlDoc, navigatorWidgetUIProperties, "group", new Array("name"), new Array("lastModification"));
			navigatorWidgetUICommonPropsBoxType = addXMLNode(navigatorXmlDoc, navigatorWidgetUICommonProperties, "setting", new Array("name", "value"), new Array("boxType", "none"));
			navigatorWidgetUIAdditionalProperties = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertyBoxes, "group", new Array("name"), new Array("additionalProperties"));
			navigatorWidgetUIAddPropProperties = addXMLNode(navigatorXmlDoc, navigatorWidgetUIAdditionalProperties, "list", new Array("name"), new Array("properties"));
		    
		    //Create the list of properties nodes
			var propCol, prop;
			var uuid = new String;
			propCol = objectsToAdd(j).type.allProperties;
			for(var k = 1; k <= propCol.count; k++)
			{
				uuid = objectsToAdd(j).type.getPropertyUUID(propCol(k).name);
				if (uuid.length > 0)
				{
					addXMLNode(navigatorXmlDoc, navigatorWidgetUIAddPropProperties, "group", new Array("name"), new Array(uuid));
				}
			} 	

			collapseProperties = 0;
			var temp = new String;
			try 
			{
				temp = objectsToAdd(j).getNamedStringValue("comments");
			}
			catch(exception)
			{
				temp = "";
			}
			collapseProperties = temp.indexOf("collapseProperties");
			if (collapseProperties < 0)
			{
				navigatorAdditionalPropertiesSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIAdditionalProperties, "setting", new Array("name", "value"), new Array("boxType", "none"));
			}
			else
			{
				navigatorAdditionalPropertiesSetting1 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIAdditionalProperties, "setting", new Array("name", "value"), new Array("boxLabel", "Additional Properties"));
				navigatorAdditionalPropertiesSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIAdditionalProperties, "setting", new Array("name", "value"), new Array("boxType", "collapsible"));
				navigatorAdditionalPropertiesSetting3 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIAdditionalProperties, "setting", new Array("name", "value"), new Array("expanded", "false"));
			}
			
			navigatorWidgetUIRelationships = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertyBoxes, "group", new Array("name"), new Array("Relationships"));
			navigatorWidgetUIRelationshipProperties = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationships, "list", new Array("name"), new Array("properties"));		
			
			//Get the objects subcomponents and look through them for new component types
			objectParts = objectsToAdd(j).parts;
			var listComponents = metis.newInstanceList();
			addSubComponentsToXML(objectParts, navigatorWidgetUIRelationshipProperties, ifInstanceName, listComponents, navigatorXmlDoc, layoutString);	
			
			//Get the current component types relationships and all subcomponents of the same type's relationships
			relColl = objectsToAdd(j).neighbourRelationships;
			GetSubRelationships(relColl, objectsToAdd(j));
			
			//Loop through the relationships and throw out any duplicates
			for(var k = 1; k <= relColl.count; k++)
			{
				relRepositoryCheck = 2;
				relRepositoryCheck = relColl(k).getNamedValue("dbms-admin.system-uploaded").getInteger();
				if (relRepositoryCheck != 2) 
				{
					relAlreadyAdded = 0;
					for(var l = 1; l <= relsToAdd.count; l++)
					{
						if (relColl(k).type.title == relsToAdd(l).type.title)
						{
							relAlreadyAdded = 1;
							break;
						}
					}
					if (relAlreadyAdded == 0)
					{
						relsToAdd.AddLast(relColl(k));
					}
				}
			}
			
			//Add the relationship nodes
			addSubRelationshipsToXML(objectsToAdd(j), navigatorWidgetUIRelationshipProperties, ifInstanceName, relsToAdd, navigatorXmlDoc, layoutString);
			 
			collapseProperties = 0;
			var temp = new String;
			try 
			{
				temp = objectsToAdd(j).getNamedStringValue("comments");
			}
			catch(exception)
			{
				temp = "";
			}
			collapseRelationships = temp.indexOf("collapseRelationships");
			
			if (collapseRelationships < 0)
			{
				navigatorRelationshipSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationships, "setting", new Array("name", "value"), new Array("boxType", "none"));
			}
			else
			{
				navigatorRelationshipSetting1 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationships, "setting", new Array("name", "value"), new Array("boxLabel", "Parts and Relationships"));
				navigatorRelationshipSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationships, "setting", new Array("name", "value"), new Array("boxType", "collapsible"));
				navigatorRelationshipSetting3 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationships, "setting", new Array("name", "value"), new Array("expanded", "false"));
			}
					
			//Closing XML statements
			navigatorWidgetUIPropertyBoxesLabelColumnWidth = addXMLNode(navigatorXmlDoc, navigatorWidgetUILayoutConfig, "setting", new Array("name", "value"), new Array("labelColumnWidth", "0%"));
			navigatorWidgetUINameSetting1 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIName, "setting", new Array("name", "value"), new Array("objectType", ifObjectTypeUUID));
			navigatorWidgetUINameSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIName, "setting", new Array("name", "value"), new Array("layoutURL", "/widgets/boxedTwoColumnLayout.jsp"));
			navigatorWidgetUINameSetting3 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIName, "setting", new Array("name", "value"), new Array("layoutType", ifInstanceName + layoutString));
		}
		objectsToAdd =  null;
	}

	navigatorWidgetUI.appendChild(navigatorLayouts);
	navigatorConfiguration.appendChild(navigatorWidgetUI);
}

//-------------------------
//Function that adds a XML node to the XML Document
//-------------------------
function addXMLNode(navigatorXmlDoc, appendNode, type, names, values)
{
	var node = navigatorXmlDoc.createElement(type);
	for(var i = 0; i < names.length; i++)
	{
		node.setAttribute(names[i], values[i]);
	}
	appendNode.appendChild(node);
	return node;
}
//-------------------------
//Function to add a component or relationship to an existing array of components or relationships
//-------------------------
function addObjects(ifPart)
{
	var ifChild, ifPartChildren, repositoryCheck, alreadyAdded, ifObject;
	ifPartChildren = ifPart.parts;
	for (var i = 1; i <= ifPartChildren.count; i++)
	{
		repositoryCheck = 2;
		try
		{
			repositoryCheck = ifPartChildren(i).getNamedValue("dbms-admin.system-uploaded").getInteger();
		}
		catch(exception)
		{
		}
		if (repositoryCheck != 2)
		{
			alreadyAdded = 0;
			for (var j = 1; j <= objectsToAdd.count; j++)
			{
				if(ifPartChildren(i).type.title == objectsToAdd(j).type.title)
				{
						alreadyAdded = 1;
						break;
				}
			}
			if (alreadyAdded == 0)
			{
				objectsToAdd.AddLast(ifPartChildren(i));
			}
		}
		addObjects(ifPartChildren(i));
	}
}

//-------------------------
//Function that recursivly finds all instance of a metis container objects and appends the objects to an array
//-------------------------
function GetAllInstancesInModelViewRecursively(ifModelViewChildrenViews, sObjectTypeURI, ifInstanceColl)
{
	for(var i = 1; i <= ifModelViewChildrenViews.count; i++)
	{
   		if (ifModelViewChildrenViews(i).hasInstance)
   		{
   			var ifInstance = ifModelViewChildrenViews(i).instance;
   			
   			if (ifInstance.type.uri == sObjectTypeURI)
   			{
   				ifInstanceColl.addLast(ifInstance);
   			}
   		}
		GetAllInstancesInModelViewRecursively(ifModelViewChildrenViews(i).children, sObjectTypeURI, ifInstanceColl);
	}
	return ifInstanceColl;
}

//-------------------------
//Function that takes the existing XMLDOM and adds tabs, spaces and return statements for ease of read; Currently unimplemented
//-------------------------
function formatXml(objDom, strIndent)
{
	var objChild;
	var objNew;

	if (indentOrigLen == 0) 
	{
		tempstrIndent = new String;
		tempstrIndent = strIndent;
		indentOrigLen = tempstrIndent.length;
	}

	if (objDom.childNodes.length > 0)
	{
		for(var i = 1; i < objDom.childNodes.count; i++)
		{
			var temp = new String;
			temp = strIndent;
			temp = temp.substr(0, indentOrigLen);
			formatXml(objChild, strIndent + temp);
			if (objDom.nodeType == 1)
			{
				if (objDom.nodeName == "configName" )
				{
				}
				else
				{
					objNew = objDom.ownerDocument.createNode(3, "", "");
					objNew.nodeValue = "\r\n" + strIndent;
					objNew = objDom.insertBefore(objNew, objChild);
					objNew = null;
				}
			}
		}
		if (objDom.nodeType == 1)
		{
			if (objDom.nodeName == "configName")
			{
			}
			else
			{
				objNew = objDom.ownerDocument.createNode(3, "", "");
				var temp = new String;
				temp = strIndent;
				temp = temp.substr(0, temp.lenght - 1);
				objNew.nodeValue = "\r\n" + temp;
				objNew = objDom.appendChild(objNew);
				objNew = null;
			}
		}
	}
}

//-------------------------
//Function that checks the calling actionButton to see if it has the defined parameter called the value of
//strParameterName and return that value if this is the case
//-------------------------
function overrideFromMetis(strParameterName, parameter, ifModel)
{
	var oProperty;
	var oPropvaluesCollection, oPropInstance;
	var PARAM_STR_CONFIG_CONTAINER;
	
	oPropvaluesCollection = ifModel.currentInstance.getNamedValue("variables").getCollection();

	for (var i = 1; i < oPropvaluesCollection.count; i++)
	{
		if (oPropvaluesCollection(i).getValue(oPropvaluesCollection(i).type.getProperty("variableName")).getString == strParameterName)
		{
			parameter = oPropvaluesCollection(i).getValue(oPropvaluesCollection(i).type.getProperty("variableValue")).getString;
			break;
		}
	}
}

//-------------------------
//Fucntion that create a metis fileselect dialog box with type filter szFilter
//-------------------------
function SelectFileFromDialog(szFilter)
{
	SelectFileFromDialog = metis.getFileName(szFilter,0);
	return SelectFileFromDialog;
}

//-------------------------
//Currently unimplemented becuase dosn't seem to be needed
//-------------------------
function resolveLayoutName(ifInstance)
{
   var ifInstanceParent = ifInstance.parent;
   for(var i = 1; i <= ifSelectedColl.count; i++)
   {
	   if (ifInstanceParent.uri == ifSelectedColl(i).uri)
	   {
			var temp = new String;
			temp = ifSelectedColl(i).name;
			relLayoutToUse = temp.replace(" ", "_");
			return;
       }
   }
   resolveLayoutName(ifInstanceParent);
}

//-------------------------
//Function that recursivly traverses the subcomponents of a given component and add subcomponent relationships where needed.
//The function will only add one relationship for each component type.
//-------------------------
function addSubComponentsToXML(objectParts, navigatorWidgetUIRelationshipProperties, ifInstanceName, listComponents, navigatorXmlDoc, layoutString)
{
	var objectPart, objectPartUUID, navigatorWidgetUIPropertiesPartNames, isAdded;
	var navigatorPartNamesWidgetConfig, navigatorPartNamesWidgetConfigSetting1, navigatorPartNamesWidgetConfigSetting3;
	var navigatorPartNamesWidgetConfigSetting4, navigatorPartNamesWidgetConfigSetting5, navigatorPartNamesSetting1, navigatorPartNamesSetting2;
	
	//Loop through each subcomponent
	for (var i = 1; i <= objectParts.count; i++)
	{
		isAdded = 0;
		
		//Check to see if this subcomponent has been added before
		for (var j = 1; j <= listComponents.count; j++)
		{
			if (listComponents(j).type.name == objectParts(i).type.name)
			{
				isAdded = 1;
			}
		}
		if (isAdded != 1)
		{
		
			//Construct the subcomponent relationship XML
			var temp = new String;
			temp = objectParts(i).type.uri;
			temp = temp.split("#", 2);
			objectPartUUID = temp[1];
			
			navigatorWidgetUIPropertiesPartNames = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationshipProperties, "group", new Array("name"), new Array(objectPartUUID + ":0"));
			navigatorPartNamesWidgetConfig = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesPartNames, "group", new Array("name"), new Array("widgetConfig"));
			navigatorPartNamesWidgetConfigSetting1 = addXMLNode(navigatorXmlDoc, navigatorPartNamesWidgetConfig, "setting", new Array("name", "value"), new Array("drillthroughURL", "/do/widget/editComponent?layoutType=" + ifInstanceName + layoutString + "&mode=view"));
			navigatorPartNamesWidgetConfigSetting2 = addXMLNode(navigatorXmlDoc, navigatorPartNamesWidgetConfig, "setting", new Array("name", "value"), new Array("allowDeleteComponent", "true"));
			navigatorPartNamesWidgetConfigSetting3 = addXMLNode(navigatorXmlDoc, navigatorPartNamesWidgetConfig, "setting", new Array("name", "value"), new Array("componentEditorPopupURL", "/do/widget/editObjectPopup?layoutType=widgetGenericPropertiesOnly"));
			navigatorPartNamesWidgetConfigSetting4 = addXMLNode(navigatorXmlDoc, navigatorPartNamesWidgetConfig, "setting", new Array("name", "value"), new Array("allowCreate", "true"));
			navigatorPartNamesSetting1 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesPartNames, "setting", new Array("name", "value"), new Array("widget", "componentList"));
			navigatorPartNamesSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesPartNames, "setting", new Array("name", "value"), new Array("labelPosition", "above"));
			
			listComponents.AddLast(objectParts(i));
		}
		var childParts = objectParts(i).parts;
		
		//Call this method on each of the subcomponents of the current component
        for(var j = 1; j <= childParts.count; j++)
        {
			addSubComponentsToXML(childParts, navigatorWidgetUIRelationshipProperties, ifInstanceName, listComponents, navigatorXmlDoc, layoutString);
		    break;
		}
	}
}

//-------------------------
//Function that inspects the subcomponents of a given top-level component and adds their relationships
//-------------------------
function addSubRelationshipsToXML(objectToAdd, navigatorWidgetUIRelationshipProperties, ifInstanceName, relsToAdd, navigatorXmlDoc, layoutString)
{
	var relToAdd, isOrigin, objectToLayout, relLayoutToUse, ifRelTypeUUID, relInfo;
	var navigatorRelNamesSetting1, navigatorRelNamesSetting2, navigatorWidgetUICommonPropertiesBoxType, navigatorWidgetUIPropertiesRelNames;
	var navigatorRelNamesWidgetConfig, navigatorRelNamesWidgetConfigSetting1, navigatorRelNamesWidgetConfigSetting2;
	var navigatorRelNamesWidgetConfigSetting3, navigatorRelNamesWidgetConfigSetting4, navigatorRelNamesWidgetConfigSetting5;

	//Loop through each relationship type on the given component type
	for(var i = 1; i <= relsToAdd.count; i++)
	{
		//Determine if the relationship for this component type is the origin or the the target
	    if (relsToAdd(i).origin.type.title == objectToAdd.type.title)
	    {
			isOrigin = ":0";
			objectToLayout = relsToAdd(i).target;
			relLayoutToUse = ifInstanceName;
			//resolveLayoutName(objectToLayout);
		}
	    else
	    {
			isOrigin = ":1";
			objectToLayout = relsToAdd(i).origin;
			relLayoutToUse = ifInstanceName;
			//resolveLayoutName(objectToLayout);
	    }
	    
	    //Construct the relationship XML
	    var temp = new String;
		temp = relsToAdd(i).type.uri;
		temp = temp.split("#", 2);
		ifRelTypeUUID = temp[1];
		
		navigatorWidgetUIPropertiesRelNames = addXMLNode(navigatorXmlDoc, navigatorWidgetUIRelationshipProperties, "group", new Array("name"), new Array(ifRelTypeUUID + isOrigin));
		navigatorRelNamesWidgetConfig = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesRelNames, "group", new Array("name"), new Array("widgetConfig"));
		navigatorRelNamesWidgetConfigSetting1 = addXMLNode(navigatorXmlDoc, navigatorRelNamesWidgetConfig, "setting", new Array("name", "value"), new Array("drillthroughURL", "/do/widget/editComponent?layoutType=" + relLayoutToUse + layoutString + "&mode=view"));
		navigatorRelNamesWidgetConfigSetting2 = addXMLNode(navigatorXmlDoc, navigatorRelNamesWidgetConfig, "setting", new Array("name", "value"), new Array("relationshipEditorPopupURL", "/do/widget/editObjectPopup?layoutType=widgetGenericPropertiesOnly"));
		navigatorRelNamesWidgetConfigSetting3 = addXMLNode(navigatorXmlDoc, navigatorRelNamesWidgetConfig, "setting", new Array("name", "value"), new Array("allowDeleteComponent", "true"));
		navigatorRelNamesWidgetConfigSetting4 = addXMLNode(navigatorXmlDoc, navigatorRelNamesWidgetConfig, "setting", new Array("name", "value"), new Array("componentEditorPopupURL", "/do/widget/editObjectPopup?layoutType=widgetGenericPropertiesOnly"));
		navigatorRelNamesWidgetConfigSetting5 = addXMLNode(navigatorXmlDoc, navigatorRelNamesWidgetConfig, "setting", new Array("name", "value"), new Array("allowCreate", "true"));
		navigatorRelNamesSetting1 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesRelNames, "setting", new Array("name", "value"), new Array("widget", "componentList"));
		navigatorRelNamesSetting2 = addXMLNode(navigatorXmlDoc, navigatorWidgetUIPropertiesRelNames, "setting", new Array("name", "value"), new Array("labelPosition", "above"));
	}
}

//-------------------------
//Function that recursivly traverses the components of a given top-level component and adds unique relationships to
//the list of relationships to be added for that component in the addSubReltaionshipstoXML method
//-------------------------
function GetSubRelationships(relColl, objectToAdd)
{
    for(var i = 1; i <= objectToAdd.parts.count; i++)
    {
		for (var j = 1; j <= objectToAdd.parts(i).neighbourRelationships.count; j++)
		{
			relColl.addLast(objectToAdd.parts(i).neighbourRelationships(j));
		}
	}
	var childParts = objectToAdd.parts;
    for (var i = 1; i <= childParts.count; i++)
    {
		GetSubRelationships(relColl, childParts(i));
	}
	return relColl;
}