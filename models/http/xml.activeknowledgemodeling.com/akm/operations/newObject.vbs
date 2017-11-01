option explicit

public model, modelView
public workplaceType, rightpaneType, workareaType
public anyObjType, usesTypeType
dim menu, menuView
dim views, view, workplaceView, rightpaneView, workareaView
dim rightpane, workarea
dim newObj, newObjView
dim instViewList
dim onCreatedMethod, onCreatedMethodUri

dim InputString, InputArray, InputKind
dim InputWorkplaceType, InputRightpaneType, InputWorkareaType
dim InputAnyObjectType, InputUsesTypeType
dim InputModelType, InputObjectType, InputMetamodelMethod
dim InputOnCreateMethod
dim modelType, objectType, metamodelMethod

' Current variables
set model = metis.currentModel
set modelView = model.currentModelView

set menu  	 = model.currentInstance
set menuView = modelView.currentInstanceView

' Find content model
set model = getContentModel

'------------------------------------------------------------------------------------------------------------
' [1a] Setting global values
'------------------------------------------------------------------------------------------------------------
InputWorkplaceType    = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workplace_UUID"
InputRightpaneType    = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Rightpane_UUID"
InputWorkareaType     = "http://xml.activeknowledgemodeling.com/akm/languages/view_objects.kmd#UiType_AKM:Workarea_UUID"
InputUsesTypeType     = "http://xml.activeknowledgemodeling.com/akm/languages/view_relships.kmd#UiReltype_AKM:usesType_UUID"
InputAnyObjectType    = "metis:stdtypes#oid19"

'------------------------------------------------------------------------------------------------------------
' [1c] Parsing Input Variable
'------------------------------------------------------------------------------------------------------------
InputString 	 	  = menu.description     ' From action button
InputArray			  = Split(InputString, ";", -1, 1)
InputKind             = Split(InputArray(0), "=", -1, 1)(1)
InputOnCreateMethod   = Split(InputArray(1), "=", -1, 1)(1)

' Get types
set workplaceType     = metis.findType(InputWorkplaceType)
set rightPaneType     = metis.findType(InputRightpaneType)
set workareaType      = metis.findType(InputWorkareaType)
set anyObjType        = metis.findType(InputAnyObjectType)
set usesTypeType      = metis.findType(InputUsesTypeType)
set onCreatedMethod   = metis.findMethod(InputOnCreateMethod)

' Find workplace view
set views = modelView.children
for each view in views
    if view.hasInstance then
        if view.instance.type.uri = workplaceType.uri then
            set workplaceView = view
            exit for
        end if
    end if
next

' Find rightpane view
if isEnabled(workplaceView) then
    set views = workplaceView.children
    for each view in views
        if view.instance.type.uri = rightpaneType.uri then
            set rightpaneView = view
            set rightpane = rightpaneView.instance
        end if
    next
end if

' Find workarea view
if isEnabled(rightpaneView) then
    set views = rightpaneView.children
    for each view in views
        if view.instance.type.uri = workareaType.uri then
            set workareaView = view
            set workarea = workareaView.instance
        end if
    next
end if

'stop
' Find object type
set objectType = getObjectType(menu)
if isEnabled(objectType) then
    ' Create new object
    set newObj = model.newObject(objectType)
    if isEnabled(newObj) then
        ' Create objectview
		set newObjView = workareaView.newObjectView(newObj)
		newObjView.textScale = 0.5
'stop
        ' Set newObj to current
        set model.currentInstance = newObj
        set modelView.currentInstanceView = newObjView
        ' Call onCreated method
		if isEnabled(onCreatedMethod) then
            call model.runMethodOnInst(onCreatedMethod, newObj)
		end if
        ' Open properties dialog
        metis.runCommand "properties"
    end if
end if

function getObjectType(menu)
    dim objects, obj

    set getObjectType = Nothing
    ' Follow relationship usesType to find object of type
    set objects = menu.getNeighbourObjects(0, usesTypeType, anyObjType)
    for each obj in objects
         if isEnabled(obj) then
             set getObjectType = obj.type
             exit for
         end if
    next
end function

function getContentModel
    dim models, part, parts
    dim objects, obj, modelObj
    dim test
    set getContentModel = model
    set parts = model.parts
    for each part in parts
        if isEnabled(part) then
            if part.type.isConnectorType then
                set models = part.parts
                if models.count > 0 then
                    set modelObj = models(1)
                    set objects = modelObj.parts
                    for each obj in objects
                        if isEnabled(obj) then
                            set model = obj.ownerModel
                            exit for
                        end if
                    next
                end if
            end if
        end if
    next
    set getContentModel = model
end function

function isEnabled(inst)
    isEnabled = true
    if isEmpty(inst) then
        isEnabled = false
    elseif isNull(inst) then
        isEnabled = false
    elseif inst is Nothing then
        isEnabled = false
    elseif not inst.isValid then
        isEnabled = false
    end if
end function

