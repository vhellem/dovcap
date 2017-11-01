option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_Workspace


    ' Variant parameters
    Public Title                        ' String
    Public ClearMode                    ' String
    Public LayoutStrategy               ' String
    Public SymbolOpen                   ' String
    Public SymbolClosed                 ' String
    Public ViewStyle                    ' String
    Public MetamodelMethod              ' String
    Public DClickMethod                 ' String

    ' Context variables (public)
    Public currentModel
    Public currentModelView
    Public WorkspaceWindow

    ' Context variables (private)
    Private cObject
    Private aObject

    ' Types
    Private windowType                   ' IMetisType

    ' Methods
    Private removeMetamodelMethod        ' IMetisMethod
    Private removePartRules              ' IMetisMethod

    ' Layout strategies
    Private workspaceLayoutStrategy     ' IMetisInstance

    ' Others
    Private cvwArg                      ' CVW_ArgumentValue
    Private window                      ' CVW_Window

'-----------------------------------------------------------
    Public Property Get component           'IMetisObject
        set component = cObject
    End Property

    Public Property Set component(obj)
        if isEnabled(obj) then
            set cObject = obj
        end if
    End Property

'-----------------------------------------------------------
    Public Property Get configObject           'IMetisObject
        set configObject = aObject
    End Property

    Public Property Set configObject(obj)
        if isEnabled(obj) then
            set aObject = obj
        end if
    End Property

'-----------------------------------------------------------
    ' Build internal structures
    Public Sub build
        dim m
        
        ' Set variant parameters from configuring object - if given
        Title               = cvwArg.getConfiguredValue(component, "Name")
        Viewstyle           = cvwArg.getConfiguredValue(component, "Viewstyle")
        ClearMode           = cvwArg.getConfiguredValue(component, "ClearMode")
        LayoutStrategy      = cvwArg.getConfiguredValue(component, "LayoutStrategy")
        SymbolOpen          = cvwArg.getConfiguredValue(component, "SymbolOpen")
        SymbolClosed        = cvwArg.getConfiguredValue(component, "SymbolClosed")
        MetamodelMethod     = cvwArg.getConfiguredValue(component, "MetamodelMethod")
        DClickMethod        = cvwArg.getConfiguredValue(component, "DClickMethod")
        ' Set default values
        if Len(Title) = 0 then Title = "CVW_Workspace"
        ' Find workspace
        set m = getCVWmodel
        set WorkspaceWindow  = findInstanceView(m, windowType, "name", Title)
       
        ' Set argument dependent values
        if Len(LayoutStrategy) > 0 then
            if not LayoutStrategy = "akm:layout#AutoMatrix" then
                set workspaceLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)
            end if
        end if
    End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Only relevant if CVW_Workspace uses other components
    End Sub

'-----------------------------------------------------------
    Public Function execute             ' Return workspace objectview
        dim m, parentView
        dim method, strategy
        dim doLayout
'stop
        set execute = Nothing
        doLayout = false
        ' Find workspace
        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", Title)
        if not isEnabled(parentView) then
			exit function
        end if

        if ClearMode = "Clear" then
            call clearWorkspace
        end if
        if isEnabled(workspaceLayoutStrategy) then
            set parentView.layoutStrategy = workspaceLayoutStrategy
            doLayout = true
        elseif Len(LayoutStrategy) > 0 then
            if not LayoutStrategy = "akm:layout#AutoMatrix" then
                set workspaceLayoutStrategy = metis.findLayoutStrategy("http://xml.activeknowledgemodeling.com/akm/views/matrix_layouts.kmd#_002ash3011bccb0hs5tr")
                set parentView.layoutStrategy = workspaceLayoutStrategy
                call metis.doLayout(parentView)
                set workspaceLayoutStrategy = metis.findLayoutStrategy(LayoutStrategy)
                set parentView.layoutStrategy = workspaceLayoutStrategy
                doLayout = true
            end if
        end if
        if Len(Viewstyle) > 0 then
            call currentModelView.setViewStyle(Viewstyle)
        end if
        if Len(SymbolOpen) > 0 then
            parentView.openSymbol = SymbolOpen
        end if
        if Len(SymbolClosed) > 0 then
            parentView.closedSymbol = SymbolClosed
        end if
        if Len(MetamodelMethod) > 0 then
            set method = metis.findMethod(MetamodelMethod)
            if isEnabled(method) then
                currentModel.runMethod(method)
            end if
        end if
        if Len(DClickMethod) > 0 then
            set method = metis.findMethod(DClickMethod)
            if isEnabled(method) then
                currentModel.runMethod(method)
            end if
        end if
        if doLayout then
            call metis.doLayout(parentView)
            call layoutWorkarea
        end if
        set WorkspaceWindow = parentView
        set execute = parentView

    End Function

'-----------------------------------------------------------
    Private Sub clearWorkspace
        dim m, parentView
        dim childView, children

        call showRelationships("HideInter")
        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", Title)
        if not isEnabled(parentView) then
            exit sub
        end if
        set children = parentView.children
        for each childView in children
            call currentModel.deleteObject(childView.instance)
        next
        ' Remove virtual metamodels
        call currentModel.runMethod(removeMetamodelMethod)
        ' Remove added part rules
        call currentModel.runMethod(removePartRules)

    End Sub

'-----------------------------------------------------------
    Private Sub layoutWorkarea
        dim m, parentView
        dim workarea, workareas
        dim workwindow
        dim indx, geo

        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", Title)
        if not isEnabled(parentView) then
            exit sub
        end if
        set workareas = parentView.children
        for each workarea in workareas
            indx = workarea.children.count
            if indx > 0 then
                set workwindow = workarea.children(indx)
                if isValid(workwindow) then
                    set geo = workwindow.geometry
                    geo.x = geo.x + 10
                    set workwindow.geometry = geo
                    call metis.doLayout(workarea)
                end if
            end if
        next

    End Sub

'-----------------------------------------------------------
    Public Sub showRelationships(mode)
        dim m, parentView
        dim workarea, workareas
        dim workwindow, workwindows(), noWorkwindows
        dim model, models(), noModels
        dim relship, relships, relshipView, relshipViews
        dim origin, originView, originViews
        dim target, targetView, targetViews
        dim originWin, targetWin
        dim inter, show, hide
        dim indx, i, j

        ' Initialize
        set m = getCVWmodel
        set parentView = findInstanceView(m, windowType, "name", Title)
        if not isEnabled(parentView) then
            exit sub
        end if
        noModels = 0
        noWorkwindows = 0
        set workareas = parentView.children
        for each workarea in workareas
            indx = workarea.children.count
            if indx > 0 then
                noWorkwindows = noWorkwindows + 1
                ReDim Preserve workwindows(noWorkwindows)
                set workwindows(noWorkwindows) = workarea.children(indx)
                set model = contentModel(workwindows(noWorkwindows))
                if isValid(model) then
                    call addModelToList(model, models, noModels)
                end if
            end if
        next
        ' Create the relationship views
        for i = 1 to noModels
            set relships = models(i).relationships
            for each relship in relships
                set origin = relship.origin
                set originViews = currentModelView.findInstanceViews(origin)
                set target = relship.target
                set targetViews = currentModelView.findInstanceViews(target)
                for each originView in originViews
                    for j = 1 to noWorkwindows
						set originWin = Nothing
                        if isInView(originView, workwindows(j)) then
                            set originWin = workwindows(j)
                            exit for
                        end if
                    next
                    if isValid(originWin) then
						for each targetView in targetViews
                    		set targetWin = Nothing
							for j = 1 to noWorkwindows
								if isInView(targetView, workwindows(j)) then
									set targetWin = workwindows(j)
									exit for
								end if
							next
							if isValid(targetWin) then
								inter = false
								show  = false
								hide = false
								if originWin.uri <> targetWin.uri then inter = true
								select case mode
									case "ShowAll"      show = true
									case "ShowInter"    if inter then show = true
									case "ShowIntra"    if not inter then show = true
									case "HideAll"      hide = true
									case "HideInter"    if inter then hide = true
									case "HideIntra"    if not inter then hide = true
								end select
								if show then
									set relshipView = currentModelView.newRelationshipView(relship, originView, targetView)
								elseif hide then
									set relshipViews = relship.views
									for each relshipView in relshipViews 
										if relshipView.origin.uri = originView.uri and relshipView.target.uri = targetView.uri then
											currentModelView.deleteRelationshipView(relshipView)
										end if
									next
								end if
							end if
						next
					end if
                next
            next
        next
    End Sub

'-----------------------------------------------------------
    Sub addModelToList(m, list, byref noList)
        dim model
        dim indx, found

        found = false
        for indx = 1 to noList
            set model = list(indx)
            if isValid(model) then
                if m.uri = model.uri then
                    found = true
                    exit for
                end if
            end if
        next
        if not found then
            noList = noList + 1
            ReDim Preserve list(noList)
            set list(noList) = m
        end if
    End Sub

'-----------------------------------------------------------
    Private Function contentModel(workwindow)           'IMetisObject
    on error resume next
        dim context

        ' Find ContentModel
        set contentModel = currentModel
        set context = new EKA_Context
        set context.currentModel        = currentModel
        set context.currentModelView    = currentModelView
        set context.currentInstance     = workwindow.instance
        set context.currentInstanceView = workwindow
        if isValid(context) then
            set contentModel = context.contentModel
        end if

        if not isEnabled (contentModel) then
			dim x, y
			for each x in currentmodel.views ' find model view called content ...
				if (instr(1, x.title, "content", 1) >0) or (instr(1, x.title, "main", 1) >0) or (instr(1, x.title, "data", 1) >0) then
					for each y in x.children ' find child which is submodel
						if y.instance.type.uri = "metis:stdtypes#oid125" then
							set contentModel = y.instance.parts(1).ownerModel
							set contentModel = y.instance.parts(1).parts(1).ownerModel
							exit function
						end if
					next
				end if
			next
        end if
        if not isEnabled (contentModel) then
			set contentModel = currentmodel
		end if
		
    End Function

'-----------------------------------------------------------
    Public Sub Class_Initialize()
        dim m
        set currentModel     = metis.currentModel
        set currentModelView = currentModel.currentModelView
        set cObject          = currentModel.currentInstance
        set aObject          = currentModel.currentInstance
        ' Types
        set windowType       = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/view_objects.kmd#UiType_CVW:Workarea_UUID")
        ' Methods
        set removeMetamodelMethod = metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/spec_methods.kmd#removeVirtualMetamodels")
        set removePartRules       = metis.findMethod("http://xml.activeknowledgemodeling.com/cvw/operations/spec_methods.kmd#removePartRules")
        ' CVW objects
        set window           = new CVW_Window
        set cvwArg           = new CVW_ArgumentValue
        ' Variant parameters
        Title                = "CVW_Workspace"
        Viewstyle            = ""
        ClearMode            = ""
        LayoutStrategy       = ""
        SymbolOpen           = ""
        SymbolClosed         = ""
        MetamodelMethod      = ""
        DClickMethod         = ""

    End Sub

'-----------------------------------------------------------
    Public Sub Class_Terminate()
        set window = Nothing
        set cvwArg = Nothing
    End Sub

End Class

