option explicit

    ' CC declarations
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
    Public GLOBAL_Type_ifThen ' ifThen, inherits trigger
    Public GLOBAL_Type_hasAction ' points to task
    Public GLOBAL_Type_hasCondition ' points to condition

    ' Methods
    Public GLOBAL_Method_RuleExecute
    Public GLOBAL_Method_ExprExecute





