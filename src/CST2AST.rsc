module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import IO;

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
  	case (Question)`<Str s> <Id i> : <Type t> = <Expr e>`: return question("<s>", "<i>", cst2ast(t), cst2ast(e));
  	case (Question)`if ( <Expr e> ) { <Question* qq> } else { <Question* qq2> }`: return question(cst2ast(e), [cst2ast(q) | Question q <- qq], [cst2ast(q) | Question q <- qq2]);
  	default: throw "Unhandled expression: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref("<x>", src=x@\loc);
    case (Expr)`<Bool b>`: return boolExpr(b);
    case (Expr)`<Str s>`: return strExpr("<s>");
    case (Expr)`<Int i>`: return intExpr(i);
    case (Expr)`(<Expr e>)`: return bracketExpr(e);
    case (Expr)`! <Expr e>`: return notExpr(e);
    case (Expr)`<Expr e> * <Expr e2>`: return multiplicate(e, e2);
    case (Expr)`<Expr e> / <Expr e2>`: return divide(e, e2);
    case (Expr)`<Expr e> + <Expr e2>`: return add(e, e2);
    case (Expr)`<Expr e> - <Expr e2>`: return subtract(e, e2);
    case (Expr)`<Expr e> \>= <Expr e2>`: return greaterThanOrEqual(e, e2);
    case (Expr)`<Expr e> \<= <Expr e2>`: return smallerThanOrEqual(e, e2);
    case (Expr)`<Expr e> \< <Expr e2>`: return smallerThan(e, e2);
    case (Expr)`<Expr e> \> <Expr e2>`: return greaterThan(e, e2);
    case (Expr)`<Expr e> == <Expr e2>`: return equals(e, e2);
    case (Expr)`<Expr e> != <Expr e2>`: return notEquals(e, e2);
    case (Expr)`<Expr e> && <Expr e2>`: return AND(e, e2);
    case (Expr)`<Expr e> || <Expr e2>`: return OR(e, e2);
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
