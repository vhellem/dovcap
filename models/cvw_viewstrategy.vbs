option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CVW_ViewStrategy

    Public  title

    ' Parameters
    Public SpecificationModel            ' String
    Public noHierarchyRules              ' Integer
    Public hierarchyRules()              ' Collection of CVW_RelRule

    ' Context variables
    Private model
    Private modelView
    Private cObject                      ' Component object   - IMetisInstance
    Private aObject                      ' Configuring object - IMetisInstance

    ' Types
    Private anyObjectType                ' IMetisType
    Private isTopType                    ' IMetisType
    Private hasValueType                 ' IMetisType
    Private hasValueConstraintType       ' IMetisType
    Private hasViewStrategyType          ' IMetisType

    ' Others
    Private noRelTypes                   ' Integer
    Private relTypeList()                ' Collection of relationship types
    Private cvwArg                       ' CVW_ArgumentValue

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
    Public Sub build(strategyCont)
        dim indx
        dim strategies
        dim contUri, specObject
        dim obj1, obj2, rel, rels
        dim relDir
        dim type1, type2, relType
        dim cvwRule

        ' Build code
        indx = 1
        ' Find view strategy specification
        if isEnabled(strategyCont) then
            ' Find view strategies
            set strategies = strategyCont.getNeighbourObjects(0, isTopType, anyObjectType)
            for each obj1 in strategies
                if isEnabled(obj1) then
                    call buildRelRules(obj1, hierarchyRules, noHierarchyRules, relTypeList, noRelTypes)
                end if
            next
        end if
    End Sub

'-----------------------------------------------------------
    ' Configure used components
    Public Sub configure
        ' Only relevant if CVW_ViewStrategy uses other components
    End Sub

'-----------------------------------------------------------
    ' Do what the component is built for - return result
    Public Function execute
        dim Something

        set execute = Nothing
        ' The code
        set execute = Something
    End Function

'-----------------------------------------------------------
    Private Sub Class_Initialize()
        set model     = metis.currentModel
        set modelView = model.currentModelView
        set cObject   = model.currentInstance
        set aObject   = model.currentInstance
        set cvwArg    = new CVW_ArgumentValue
        noHierarchyRules  = 0
        ReDim hierarchyRules(noHierarchyRules)

        set anyObjectType          = metis.findType("metis:stdtypes#oid1")
        set isTopType              = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:isTop_UUID")
        set hasValueType           = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/cvw_relships.kmd#RelType_CVW:hasValue_UUID")
        set hasValueConstraintType = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasValueConstraint_UUID")
        set hasViewStrategyType    = metis.findType("http://xml.activeknowledgemodeling.com/cvw/languages/spec_relships.kmd#RelType_CVW:hasViewStrategy_UUID")

        noRelTypes = 3
        ReDim Preserve relTypeList(noRelTypes)
        set relTypeList(1) = isTopType
        set relTypeList(2) = hasValueType
        set relTypeList(3) = hasValueConstraintType
    End Sub

'-----------------------------------------------------------
    Private Sub Class_Terminate()
        set cvwArg = Nothing
    End Sub

End Class


