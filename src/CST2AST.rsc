module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import IO;
import Boolean;


/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) = cst2ast(sf.top);

AForm cst2ast(f:(Form)`form <Id i> { <Question* qq> }`)
	= form("<i>", [cst2ast(q) | Question q <- qq], src=f@\loc);

AQuestion cst2ast(Question q) {
  switch (q) {
  	case (Question)`<Str s> <Id i> : <Type t>`: return question("<s>", "<i>", cst2ast(t));
  	case (Question)`<Str s> <Id i> : <Type t> = <Expr e>`: return questionWithExpression("<s>", "<i>", cst2ast(t), cst2ast(e));
  	case (Question)`if ( <Expr e> ) { <Question* qq> }`: return ifStatement(cst2ast(e), [cst2ast(q) | Question q <- qq]);
  	case (Question)`if ( <Expr e> ) { <Question* qq> } else { <Question* pp> }`: return ifElseStatement(cst2ast(e), [cst2ast(q) | Question q <- qq], [cst2ast(p) | Question p <- pp]);
  	default: throw "Unhandled expression: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Bool b>`: return boolExpr(fromString("<b>"));
    case (Expr)`<Str s>`: return strExpr("<s>");
    case (Expr)`<Int i>`: return intExpr(toInt("<i>"));
    case (Expr)`(<Expr e>)`: return bracketExpr(cst2ast(e));
    case (Expr)`! <Expr e>`: return notExpr(cst2ast(e));
    case (Expr)`<Expr e> * <Expr e2>`: return multiplicate(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> / <Expr e2>`: return divide(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> + <Expr e2>`: return add(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> - <Expr e2>`: return subtract(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> \>= <Expr e2>`: return greaterThanOrEqual(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> \<= <Expr e2>`: return smallerThanOrEqual(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> \< <Expr e2>`: return smallerThan(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> \> <Expr e2>`: return greaterThan(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> == <Expr e2>`: return equals(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> != <Expr e2>`: return notEquals(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> && <Expr e2>`: return AND(cst2ast(e), cst2ast(e2));
    case (Expr)`<Expr e> || <Expr e2>`: return OR(cst2ast(e), cst2ast(e2));
    // etc.
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch (t) {
    case (Type)`integer`: return integer();
    case (Type)`string`: return string();
    case (Type)`boolean`: return boolean();
    // etc.
    default: throw "Unhandled expression: <t>";
  }
}
