module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestions] questions)
  ;

data AQuestion(loc src = |tmp:///|)
  = question(str string, str name, AType name)
  | question(str string, str name, AType name, AExpr expression)
  | question(AExpr expression, list[AQuestion] questions, list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | expression(str name)
  | expression(bool boolValue)
  | expression(str stringValue)
  | expression(num intValue)
  | expression(AExpr expression)
  | expression(AExpr expression1, AExpr expression2)
  ;

data AType(loc src = |tmp:///|);
