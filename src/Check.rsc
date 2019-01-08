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

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {.-..}` ) 
TEnv collect(AForm f) {
	TEnv tenv = {};
	for (/AQuestion q:=f) {
		switch (q) {
			case question(str stringName, str idName, AType typeName): tenv+={<q.src, idName, stringName, typeOfAType(typeName)>};
			case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): tenv += {<q.src, idName, stringName, typeOfAType(typeName)>};
			default: ;
		} 
	}
  	return tenv; 
}

Type typeOfAType(AType t) {
	switch (t) {
		case integer(): return tint();
		case string(): return tstr();
		case boolean(): return tbool();
		default: return tunknown();
	}
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
	messages={};
	for (/AQuestion q:=f) {
		switch (q) {
			case question(str stringName, str idName, AType typeName): messages+=check(q, tenv, useDef);
			case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): messages+=check(q, tenv, useDef);
			default: ;
		} 
	}
	return messages;
}
	

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
	//println(tenv<1>);
	println(tenv[_,q.idName,_]);
	messages={};
	messages += {error("Declared question has the same name but different type", q.src) | size(tenv[_,q.idName,_]) > 1};
  	return messages; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };

    // etc.
  }
  
  return msg; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
   	// Maybe useful for better deep matching !!!!!!!!!!!!!!!!!
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    // etc.
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
 
 

