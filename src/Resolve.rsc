module Resolve

import AST;
import IO;
import Syntax;
import String;
/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

// the reference graph
alias UseDef = rel[loc use, loc def];

UseDef resolve(AForm f) = uses(f) o defs(f);

Use uses(AForm f) {
	Use use = {};
	for (/AExpr e := f) {
		switch (e) {
			case ref(str name): use+= {<e.src, e.name>};
			default: ;
		}
	}
	
  	return use; 
}



Def defs(AForm f) {
	Def def = {};
	for (/AQuestion q:=f) {
		// Possible with deep match
		switch (q) {
			case question(str stringName, str idName, AType typeName): def += { <q.idName, q.src>};
			case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): def += { <q.idName, q.src>};
			default: ;
		} 
	}
  	return def; 
}