option explicit


'-----------------------------------------------------------
'-----------------------------------------------------------
Class CC_Globals


    Private Sub Class_Initialize()
        dim ekaGlobals

        if not isEmpty(ccGlobalsInitialized) then exit Sub

        set ekaGlobals = new EKA_Globals
        
        ' Base types
        set GLOBAL_Type_CCFamily   = metis.findType("http://xml.chalmers.se/class/cc_family.kmd#CC_family")
        set GLOBAL_Type_CCObject   = metis.findType("http://xml.chalmers.se/class/cc_object.kmd#CC_object")
        set GLOBAL_Type_CCInstance = metis.findType("http://xml.chalmers.se/class/cc_instance.kmd#CC_instance")
        set GLOBAL_Type_CCProperty = metis.findType("http://xml.chalmers.se/class/cc_property.kmd#CC_property")
        set GLOBAL_Type_CCParameter = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#parameter")
        set GLOBAL_Type_CCParam    = metis.findType("http://xml.chalmers.se/class/cc_parameter.kmd#CC_parameter")
        set GLOBAL_Type_CCValue    = metis.findType("http://xml.chalmers.se/class/cc_value.kmd#CC_value")
        set GLOBAL_Type_CCHasProperty = metis.findType("http://xml.chalmers.se/class/cc_has_property.kmd#CC_has_property")
        ' Component structure types
        set GLOBAL_Type_CC     = metis.findType("http://xml.chalmers.se/class/configurable_component.kmd#configurable_component")
        set GLOBAL_Type_CS     = metis.findType("http://xml.chalmers.se/class/composition_set.kmd#composition_set")
        set GLOBAL_Type_CE     = metis.findType("http://xml.chalmers.se/class/composition_element.kmd#composition_element")
        set GLOBAL_Type_CR     = metis.findType("http://xml.chalmers.se/class/composition_request.kmd#composition_request")
        set GLOBAL_Type_hasCS  = metis.findType("http://xml.chalmers.se/class/is_composed_using.kmd#is_composed_using")
        set GLOBAL_Type_hasCE  = metis.findType("http://xml.chalmers.se/class/has_composition_element.kmd#has_composition_element")
        set GLOBAL_Type_hasCR  = metis.findType("http://xml.chalmers.se/class/has_composition_request.kmd#has_composition_request")
        set GLOBAL_Type_usesCC = metis.findType("http://xml.chalmers.se/class/uses_configurable_component.kmd#uses_configurable_component")
        ' Design rationale types
        set GLOBAL_Type_CO     = metis.findType("http://xml.chalmers.se/class/constraint.kmd#constraint")
        set GLOBAL_Type_DS     = metis.findType("http://xml.chalmers.se/class/design_solution.kmd#design_solution")
        set GLOBAL_Type_FR     = metis.findType("http://xml.chalmers.se/class/functional_requirement.kmd#functional_requirement")
        set GLOBAL_Type_explains      = metis.findType("http://xml.chalmers.se/class/is_explained_by.kmd#Is_explained_by")
        set GLOBAL_Type_hasDS         = metis.findType("http://xml.chalmers.se/class/has_design_solution.kmd#has_design_solution")
        set GLOBAL_Type_solves        = metis.findType("http://xml.chalmers.se/class/is_solved_by.kmd#is_solved_by")
        set GLOBAL_Type_requires      = metis.findType("http://xml.chalmers.se/class/requires_function.kmd#requires_function")
        set GLOBAL_Type_constrainedBy = metis.findType("http://xml.chalmers.se/class/is_constrained_by.kmd#Is_constrained_by")
        ' Parameter types
        set GLOBAL_Type_CP     = metis.findType("http://xml.chalmers.se/class/constraint_parameter.kmd#constraint_parameter")
        set GLOBAL_Type_CPR    = metis.findType("http://xml.chalmers.se/class/constraint_parameter.kmd#constraint_parameter_range")
        set GLOBAL_Type_DP     = metis.findType("http://xml.chalmers.se/class/design_parameter.kmd#design_parameter")
        set GLOBAL_Type_FP     = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter.kmd#functional_requirement_parameter")
        set GLOBAL_Type_PP     = metis.findType("http://xml.chalmers.se/class/performance_parameter.kmd#performance_parameter")
        set GLOBAL_Type_VP     = metis.findType("http://xml.chalmers.se/class/variant_parameter.kmd#variant_parameter")
        set GLOBAL_Type_VAR    = metis.findType("http://xml.chalmers.se/class/variant_value.kmd#variant_value")
        set GLOBAL_Type_hasCP  = metis.findType("http://xml.chalmers.se/class/has_constraint_parameter.kmd#has_constraint_parameter")
        set GLOBAL_Type_hasCPR = metis.findType("http://xml.chalmers.se/class/has_constraint_parameter.kmd#has_constraint_parameter_range")
        set GLOBAL_Type_hasDP  = metis.findType("http://xml.chalmers.se/class/has_design_parameter.kmd#has_design_parameter")
        set GLOBAL_Type_hasFP  = metis.findType("http://xml.chalmers.se/class/has_functional_requirement_parameter.kmd#has_functional_requirement_parameter")
        set GLOBAL_Type_hasPP  = metis.findType("http://xml.chalmers.se/class/has_performance_parameter.kmd#has_performance_parameter")
        set GLOBAL_Type_hasVP  = metis.findType("http://xml.chalmers.se/class/has_variant_parameter.kmd#has_variant_parameter")
        set GLOBAL_Type_constrains = metis.findType("http://xml.chalmers.se/class/constrains_parameter.kmd#constrains_parameter")
        ' Parameter value types
        set GLOBAL_Type_CPV    = metis.findType("http://xml.chalmers.se/class/constraint_parameter_value.kmd#constraint_parameter_value")
        set GLOBAL_Type_DPV    = metis.findType("http://xml.chalmers.se/class/design_parameter_value.kmd#design_parameter_value")
        set GLOBAL_Type_FPV    = metis.findType("http://xml.chalmers.se/class/functional_requirement_parameter_value.kmd#functional_requirement_parameter_value")
        set GLOBAL_Type_PPV    = metis.findType("http://xml.chalmers.se/class/performance_parameter_value.kmd#performance_parameter_value")
        set GLOBAL_Type_VPV    = metis.findType("http://xml.chalmers.se/class/variant_parameter_value.kmd#variant_parameter_value")
        set GLOBAL_Type_hasCPV = metis.findType("http://xml.chalmers.se/class/has_constraint_parameter_value.kmd#has_constraint_parameter_value")
        set GLOBAL_Type_hasDPV = metis.findType("http://xml.chalmers.se/class/has_design_parameter_value.kmd#has_design_parameter_value")
        set GLOBAL_Type_hasFPV = metis.findType("http://xml.chalmers.se/class/has_functional_requirement_parameter_value.kmd#has_functional_requirement_parameter_value")
        set GLOBAL_Type_hasPPV = metis.findType("http://xml.chalmers.se/class/has_performance_parameter_value.kmd#has_performance_parameter_value")
        set GLOBAL_Type_hasVPV = metis.findType("http://xml.chalmers.se/class/has_variant_parameter_value.kmd#has_variant_parameter_value")
        set GLOBAL_Type_hasVAR = metis.findType("http://xml.chalmers.se/class/has_variant_value.kmd#has_variant_value")
        set GLOBAL_Type_inclPV = metis.findType("http://xml.chalmers.se/class/includes_parameter_value.kmd#includes_parameter_value")
        set GLOBAL_Type_usesVAR  = metis.findType("http://xml.chalmers.se/class/uses_variant.kmd#uses_variant")
        set GLOBAL_Type_usesVAR2 = metis.findType("http://xml.chalmers.se/class/uses_variant.kmd#uses_variant2")
        set GLOBAL_Type_hasDef   = metis.findType("http://xml.chalmers.se/class/has_definition.kmd#has_definition")
        ' Rule types
        set GLOBAL_Type_Rule      = metis.findType("http://xml.chalmers.se/class/rule.kmd#rule")
        set GLOBAL_Type_Expr      = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#expression")
        set GLOBAL_Type_Action    = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#action")
        set GLOBAL_Type_Condition = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#condition")
        set GLOBAL_Type_inputTo1  = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to")
        set GLOBAL_Type_inputTo2  = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to_2")
        set GLOBAL_Type_inputTo3  = metis.findType("http://xml.chalmers.se/class/rule_condition.kmd#input_to_3")
        set GLOBAL_Type_outputTo  = metis.findType("http://xml.chalmers.se/class/rule_action.kmd#has_output")
        set GLOBAL_Type_inputToExpr1   = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#input_to")
        set GLOBAL_Type_inputToExpr2   = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#input_to_2")
        set GLOBAL_Type_outputFromExpr = metis.findType("http://xml.chalmers.se/class/rule_expression.kmd#output_to")
        set GLOBAL_Type_subjectOf = metis.findType("http://xml.chalmers.se/class/rule.kmd#subject_of_rule")
        set GLOBAL_Type_hasRule   = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_rule")
        set GLOBAL_Type_hasExpr   = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_expression")
        set GLOBAL_Type_ifThen    = metis.findType("http://xml.chalmers.se/class/rule.kmd#if_then")
        set GLOBAL_Type_hasAction = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_action")
        set GLOBAL_Type_hasCondition   = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_condition")
        set GLOBAL_Type_invokes        = metis.findType("http://xml.chalmers.se/class/rule.kmd#invokes_rule")
        set GLOBAL_Type_hasRuleContext = metis.findType("http://xml.chalmers.se/class/rule.kmd#has_rule_context")

        ' Configuration types
        set GLOBAL_Type_Product       = metis.findType("http://xml.activeknowledgemodeling.com/cppd/languages/productelement.kmd#ObjType_CPPD:ProductElement_UUID")
        set GLOBAL_Type_Part          = metis.findType("http://xml.chalmers.se/class/cc_product.kmd#CC_product")
        set GLOBAL_Type_Requirement   = metis.findType("http://xml.chalmers.se/class/cc_requirement.kmd#CC_requirement")
        set GLOBAL_Type_Specification = metis.findType("http://xml.chalmers.se/class/cc_specification.kmd#CC_specification")

        ' Model type(s)
        set GLOBAL_Type_CcModel     = GLOBAL_Type_EkaSpace
        set GLOBAL_Type_CcProject   = GLOBAL_Type_EkaProject
        set GLOBAL_CC_CurrentFamily = Nothing
        set GLOBAL_CC_CurrentComponentFamily = Nothing
        GLOBAL_CC_Debug = false

        ' Methods
        set GLOBAL_Method_RuleExecute = metis.findMethod("http://xml.chalmers.se/methods/rule_methods.kmd#evaluateRule")
        set GLOBAL_Method_ExprExecute = metis.findMethod("http://xml.chalmers.se/methods/rule_methods.kmd#evaluateExpression")

        ccGlobalsInitialized = true

    End Sub
    
End Class


