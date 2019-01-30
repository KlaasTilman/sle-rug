module Check

import AST;
import Resolve;
import Message; // see standard library
import Set;
import IO;
import Relation;


data Type
	= tint()
	| tbool()
	| tstr()
	| tunknown()
	;

// The type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {.-..}` ) 
TEnv collect(AForm f) {
	TEnv tenv = {};
	// Deep match
	for (/AQuestion q:=f) {
		switch (q) {
			case question(str stringName, str idName, AType typeName): 
				tenv+= {<q.src, idName, stringName, typeOfAType(typeName)>};
			case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): 
				tenv += {<q.src, idName, stringName, typeOfAType(typeName)>};
			default: ;
		} 
	}
  	return tenv; 
}

/* Find the Type of an AType */
Type typeOfAType(AType t) {
	switch (t) {
		case integer(): return tint();
		case string(): return tstr();
		case boolean(): return tbool();
		default: return tunknown();
	}
}

/* Check a form by using deep match to check all questions and expressions*/
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	messages={};
	// Using deep match to check all questions
	for (/AQuestion q:=f) {
		switch (q) {
			case question(str stringName, str idName, AType typeName): 
				messages+=check(q, tenv, useDef);
			case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): 
				messages+=check(q, tenv, useDef); 
			default: ;
		} 
	}
	
	// Using deep match to check all expressions
	for (/AExpr e:=f) {
		messages+=check(e, tenv, useDef);
	}
	return messages;
}
	
/* Check a question */
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	messages={};
	// Produce an error if there are declared questions with the same name but different types
	messages += {error("Declared question has the same name but different type", q.src) | size(tenv[_,q.idName, _]) > 1};
	
	// Duplicate labels should trigger a warning
  	messages += {warning("Duplicate label", q.src) | size((tenv<2,0>)[q.stringName]) > 1};
  	
  	// The declared type computed questions should match the type of the expression
	if(q has expression) {
  		messages += {error("The declared type does not match the type of the expression", q.src) | typeOf(q.expression, tenv, useDef) notin tenv[q.src]<2>};
  	}
  	
  	// Return all warnings and errors 
  	return messages; 
}

/* Check an expression */
// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
	set[Message] msgs = {};
	
	switch (e) {
		case ref(str x, src = loc u):
			msgs += { error("Undeclared variable", u) | useDef[u] == {} };
		case notExpr(AExpr expression, src = loc u):
			msgs += { error("Operator `!` expects boolean type", u) | typeOf(expression, tenv, useDef)==tbool() };
		case multiplicate(AExpr expression1, AExpr expression2, src = loc u): 
			msgs += { error("Operator `*` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case divide(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `/` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case add(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `+` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case subtract(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `-` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case greaterThanOrEqual(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `\>=` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case smallerThanOrEqual(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `\<=` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case smallerThan(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `\<` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case greaterThan(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `\>` expects two integer types", u) | !(typeOf(expression1, tenv, useDef)==tint() && typeOf(expression2, tenv, useDef)==tint())};
		case equals(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `=` expects equal types", u) | !(typeOf(expression1, tenv, useDef)==typeOf(expression2, tenv, useDef))};
		case notEquals(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `!=` expects equal types", u) | !(typeOf(expression1, tenv, useDef)==typeOf(expression2, tenv, useDef))};
		case AND(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `AND` expects two boolean types", u) | !(typeOf(expression1, tenv, useDef)==tbool() && typeOf(expression2, tenv, useDef)==tbool())};
		case OR(AExpr expression1, AExpr expression2, src = loc u):
			msgs += { error("Operator `OR` expects two boolean types", u) | !(typeOf(expression1, tenv, useDef)==tbool() && typeOf(expression2, tenv, useDef)==tbool())};
	}
	return msgs; 
}

/* Find the type of an AExpr */
Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
	switch (e) {
		case ref(str x, src = loc u):  
			if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
				return t;
      		}
		case boolExpr(bool boolValue): return tbool();
		case strExpr(str stringValue): return tstr();
		case intExpr(int intValue): return tint();
		case bracketExpr(AExpr expression): return typeOf(expression, tenv, useDef);
		case notExpr(AExpr expression): return tbool();
		case multiplicate(AExpr expression1, AExpr expression2): return tint();
		case divide(AExpr expression1, AExpr expression2): return tint();
		case add(AExpr expression1, AExpr expression2): return tint();
		case subtract(AExpr expression1, AExpr expression2): return tint();
		case greaterThanOrEqual(AExpr expression1, AExpr expression2): return tbool();
		case smallerThanOrEqual(AExpr expression1, AExpr expression2): return tbool();
		case smallerThan(AExpr expression1, AExpr expression2): return tbool();
		case greaterThan(AExpr expression1, AExpr expression2): return tbool();
		case equals(AExpr expression1, AExpr expression2): return tbool();
		case notEquals(AExpr expression1, AExpr expression2): return tbool();
		case AND(AExpr expression1, AExpr expression2): return tbool();
		case OR(AExpr expression1, AExpr expression2): return tbool();
		default: return tunknown();
	}
	return tunknown();
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

