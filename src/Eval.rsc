module Eval

import AST;
import Resolve;
import IO;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
	VEnv venv = ();
	for (/AQuestion q:=f) {
		if (q has typeName) {
			switch (q.typeName) {
				case integer(): venv += (q.idName:vint(0));
				case boolean(): venv += (q.idName:vbool(false));
				case string(): venv += (q.idName:vstr(""));
			}
		}
	}
	return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	for (/AQuestion q:=f) {
		venv+=eval(q, inp, venv);
	}
	return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  VEnv venvQuestion=();
  switch (q) {
  	case question(str stringName, str idName, AType typeName):
  		if (stringName == inp.question) {
  			return venv[idName]=inp.\value;
  		}
  	case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): 
  		return venv[idName]= eval(expression, venv);
  	case ifStatement(AExpr expression, list[AQuestion] questions): 
  		if (eval(expression, venv).b) {
  			for (AQuestion q0 <- questions) {
  				venvQuestion+=eval(q0, inp, venv);
  			}
  			return venvQuestion;
  		}
  	case ifElseStatement(AExpr expression, list[AQuestion] questions, list[AQuestion] questions2):
  		if (eval(expression, venv).b) {
  			for (AQuestion q1 <- questions) {
  				venvQuestion+=eval(q1, inp, venv);
  			}
  		} else {
  			for (AQuestion q2 <- questions2) {
  				venvQuestion+=eval(q2, inp, venv);
  			}
  		}
  }
  return venvQuestion; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(str x): return venv[x];
    case boolExpr(bool boolValue): return vbool(boolValue);
	case strExpr(str stringValue): return vstr(stringValue);
	case intExpr(int intValue): return vint(intValue);
    case bracketExpr(AExpr expression): return eval(expression, venv);
	case notExpr(AExpr expression): return vbool(!eval(expression, venv).b);
	case multiplicate(AExpr expression1, AExpr expression2): return vint(eval(expression1, venv).n * eval(expression2, venv).n);
	case divide(AExpr expression1, AExpr expression2): return vint(eval(expression1, venv).n / eval(expression2, venv).n);
	case add(AExpr expression1, AExpr expression2): return vint(eval(expression1, venv).n + eval(expression2, venv).n);
	case subtract(AExpr expression1, AExpr expression2): return vint(eval(expression1, venv).n - eval(expression2, venv).n);
	case greaterThanOrEqual(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv).n >= eval(expression2, venv).n);
	case smallerThanOrEqual(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv).n <= eval(expression2, venv).n);
	case smallerThan(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv).n > eval(expression2, venv).n);
	case greaterThan(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv).n < eval(expression2, venv).n);
	case equals(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv) == eval(expression2, venv));
	case notEquals(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv) != eval(expression2, venv));
	case AND(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv).b && eval(expression2, venv).b);
	case OR(AExpr expression1, AExpr expression2): return vbool(eval(expression1, venv).b || eval(expression2, venv).b);
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
}