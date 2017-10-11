option explicit

    Public RuleGlobalsInitialized

    ' Rule types
    Public GLOBAL_Type_Rule ' EKA rule, generic
    Public GLOBAL_Type_Expr ' Rule (script)
    public GLOBAL_Type_Script ' Script
    Public GLOBAL_Type_Action ' Task
    Public GLOBAL_Type_Condition ' condition
    Public GLOBAL_Type_inputTo1 ' has input
    Public GLOBAL_Type_inputTo2 ' has input
    Public GLOBAL_Type_inputTo3 ' has input
    Public GLOBAL_Type_outputTo ' has output
    Public GLOBAL_Type_inputToExpr1 ' has input
    Public GLOBAL_Type_inputToExpr2 ' has input
    Public GLOBAL_Type_outputFromExpr  ' has output
    Public GLOBAL_Type_hasExpr ' works on 
    Public GLOBAL_Type_hasRule ' works on
    Public GLOBAL_Type_subjectOf 
    Public GLOBAL_Type_ifThen ' ifThen, inherits trigger
    Public GLOBAL_Type_hasAction ' points to task
    Public GLOBAL_Type_hasCondition ' points to condition

    ' Methods
    Public GLOBAL_Method_RuleExecute
    Public GLOBAL_Method_ExprExecute


'-----------------------------------------------------------
'-----------------------------------------------------------
Class Rule_Globals


    Private Sub Class_Initialize()
        dim ekaGlobals

        if RuleGlobalsInitialized then exit Sub

        set ekaGlobals = new EKA_Globals

        ' Rule types
        set GLOBAL_Type_Rule      = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_rule.kmd#ekaRule")
        set GLOBAL_Type_Expr      = metis.findType("http://xml.activeknowledgemodeling.com/rule/languages/rule_expression.kmd#expression")
        set GLOBAL_Type_Script		= metis.findType("http://xml.activeknowledgemodeling.com/rule/languages/script.kmd#Script")
        set GLOBAL_Type_Action    = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_task.kmd#ekaTask")
        set GLOBAL_Type_Condition = metis.findType("http://xml.activeknowledgemodeling.com/rule/languages/rule_condition.kmd#condition")
      
        set GLOBAL_Type_inputTo1  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/has_parameter.kmd#Has_input")
        set GLOBAL_Type_inputTo2  = GLOBAL_Type_inputTo1
        set GLOBAL_Type_inputTo3  = GLOBAL_Type_inputTo1
        set GLOBAL_Type_outputTo  = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/has_parameter.kmd#Has_output")
        set GLOBAL_Type_inputToExpr1   = GLOBAL_Type_inputTo1
        set GLOBAL_Type_inputToExpr2   = GLOBAL_Type_inputTo1
        set GLOBAL_Type_outputFromExpr = GLOBAL_Type_outputTo

        set GLOBAL_Type_hasRule   = metis.findType("http://xml.activeknowledgemodeling.com/eka/languages/eka_relships.kmd#works_on")
        set GLOBAL_Type_subjectOf = GLOBAL_Type_hasRule
        set GLOBAL_Type_hasExpr   = GLOBAL_Type_hasRule
        
        set GLOBAL_Type_ifThen    = metis.findType("http://xml.activeknowledgemodeling.com/rule/languages/rule.kmd#if_then")
        set GLOBAL_Type_hasAction = metis.findType("http://xml.activeknowledgemodeling.com/rule/languages/rule.kmd#has_action")
        set GLOBAL_Type_hasCondition = metis.findType("http://xml.activeknowledgemodeling.com/rule/languages/rule.kmd#has_condition")

        ' Methods
        set GLOBAL_Method_RuleExecute = metis.findMethod("http://xml.activeknowledgemodeling.com/rule/operations/rule_methods.kmd#evaluateRule")
        set GLOBAL_Method_ExprExecute = metis.findMethod("http://xml.activeknowledgemodeling.com/rule/operations/rule_methods.kmd#evaluateExpression")

        RuleGlobalsInitialized = true

    End Sub
    
End Class


