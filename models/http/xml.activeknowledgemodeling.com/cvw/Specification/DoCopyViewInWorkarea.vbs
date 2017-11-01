'option explicit
'[0] ----------------------------------------------------------
dim model, modelView, inst, instView
dim cvwWin, workarea, workareaTitle
dim winType, buttonType

dim cvwStatusBar
dim  instParentView, winName
dim argObj, argVal, InputContainerType, InputContainerName

dim contextMode, modelName, viewstyle

'[1] ----------------------------------------------------------
set model = metis.currentModel
set inst = model.currentInstance
set modelView = model.currentModelView
set instView = modelView.currentInstanceView

'[2] ------INPUT ARGUMENTS----------------------------------------------------

set argObj          = new CVW_ArgumentValue


' - specific input -----------------------------------
contextMode         = argObj.getArgumentValue(inst, "ContextMode")
modelName           = argObj.getArgumentValue(inst, "ModelName")
inputContainerType  = argObj.getArgumentValue(inst, "InputContainerType")
InputContainerName  = argObj.getArgumentValue(inst, "InputContainerName")
viewstyle           = argObj.getArgumentValue(inst, "Viewstyle")

'[3] ----------------------------------------------------------
set winType     = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
set buttonType  = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/action_objects.kmd#ObjType_CVW:Button_UUID")
set cvwWin      = new CVW_Window

'[4] --------- MAIN -------------------------------------------------------------------
'[4a] ---------  Get Menu View  ------------------------------------------------
 set instParentView = cvwWin.getInstView(winType ,"name","CVW_Workspace")
 winName =  inst.title
 
 dim cvwWorkarea 

set cvwWorkarea = new CVW_Workarea

'stop
if Len(inst.title) > 0 then
    workareaTitle = inst.title
else
    workareaTitle = "New window"
end if
call cvwWorkarea.build(workareaTitle, "CVW_WinToolbar", true)

if isValid(cvwWorkarea) then
    if Len(viewstyle) > 0 then
        call modelView.setViewStyle(viewstyle)
    end if

    call copyViewInWorkarea(contextMode, model, modelName, modelView, cvwWorkarea.objectView.children(2) ,InputContainerType, InputContainerName)

    call cvwWorkarea.doParentLayout
    modelView.clearSelection

  end if

'-----------------------------------------------------------------------------------------------------

 sub copyViewInWorkarea(contextMode, model, modelName, CurrentModelView, WorkArea, InputContainerType, InputContainerName)
    '[a] ------------------
    Dim   modelContainer, topContainer, topContainerType
    '[b]-------------------------------
    set contentModel  = getInstanceModel(model, contextMode, modelName)
    set topContainerType = metis.findType(InputContainerType)
    if not isEnabled(contentModel) or not isEnabled(topContainerType) then
        exit sub
    end if

    set instance = metis.findInstance(contentModel.uri)
    if instance.type.uri = topContainerType.uri then
        if instance.name = InputContainerName then
            set topContainer = instance
        end if
    end if

    set topContainer = findContainer(contentModel, topContainerType, InputContainerName)

    '[c]-------------------------------
    if isEnabled(topContainer) then
        currentModelView.currentInstanceView = topContainer.views(1)
        Call metis.runCommand("copy")
        currentModelView.currentInstanceView = WorkArea
        Call metis.runCommand("paste-structure")
        'Call metis.runCommand("paste-synchronized-view")
        'Call metis.runCommand("paste-auto-virtual-synchronized-view")
    end if
end sub

function findContainer(parent, contType, contName)
    dim container, containers
    dim foundContainer

    set findContainer = Nothing
    set foundContainer = Nothing
    set containers = parent.parts
    for each container in containers
        if container.type.uri = contType.uri then
            if container.name = contName then
                set foundContainer = container
                exit for
            else 
                set foundContainer = findContainer(container, contType, contName)
            end if
        end if
    next
    if isEnabled(foundContainer) then
        set findContainer = foundContainer
    end if
end function


