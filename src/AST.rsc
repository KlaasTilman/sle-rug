module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;

data AQuestion(loc src = |tmp:///|)
  = question(str stringName, str idName, AType typeName)
  | questionWithExpression(str stringName, str idName, AType typeName, AExpr expression)
  | ifStatement(AExpr expression, list[AQuestion] questions, list[AQuestion] questions)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(str name)
  | boolExpr(bool boolValue)
  | strExpr(str stringValue)
  | intExpr(int intValue)
  | bracketExpr(AExpr expression)
  | notExpr(AExpr expression)
  | multiplicate(AExpr expression1, AExpr expression2)
  | divide(AExpr expression1, AExpr expression2)
  | add(AExpr expression1, AExpr expression2)
  | subtract(AExpr expression1, AExpr expression2)
  | greaterThanOrEqual(AExpr expression1, AExpr expression2)
  | smallerThanOrEqual(AExpr expression1, AExpr expression2)
  | smallerThan(AExpr expression1, AExpr expression2)
  | greaterThan(AExpr expression1, AExpr expression2)
  | equals(AExpr expression1, AExpr expression2)
  | notEquals(AExpr expression1, AExpr expression2)
  | AND(AExpr expression1, AExpr expression2)
  | OR(AExpr expression1, AExpr expression2)
  ;

data AType(loc src = |tmp:///|)
	= integer()
	| string()
	| boolean()
;
