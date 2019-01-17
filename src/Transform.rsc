module Transform

import Resolve;
import AST;
import IO;
import ParseTree;
import Syntax;
import Set;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; if (a) { if (b) { q1: "" int; } q2: "" int; }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (a && b) q1: "" int;
 *     if (a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return f; 
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 * Bonus: do it on concrete syntax trees.
 */
 
 set[loc] getAllOccurences(loc useOrDef, UseDef useDef) {
 	set[loc] occurences = {};
 	// If it is empty, it is a definition
 	if (isEmpty(useDef[useOrDef])) {
 		occurences += { use | <loc use, useOrDef> <- useDef};
 		loc firstUse = toList(occurences)[0];
 		occurences += { def | <firstUse, loc def> <- useDef};
 	} else {
 	// The set is not empty so it is a use
 		occurences += { def | <useOrDef, loc def> <- useDef};
 		occurences += useOrDef;
 	}
 	return occurences;
 } 
 
 AForm rename(AForm f, loc useOrDef, str newName, UseDef useDef) {
   
   // Try to parse the new name to see if it is valid
   try {
   	parse(#Id, newName);
   	} catch :
   	return f;
   	
   // Check if the name already exists
   for (/AQuestion q <- f) {
   		switch (q) {
   			case question(str stringName, newName, AType typeName): {
   				println("NAME ALREADY EXISTS");
   				return f;
   			}
   			case questionWithExpression(str stringName, newName, AType typeName, AExpr expression): {
				println("NAME ALREADY EXISTS2");
				return f;
			}
   		}
   }
   
   	set[loc] occurences = getAllOccurences(useOrDef, useDef);	
	return visit(f) {
		case question(str stringName, str idName, AType typeName, src=loc u) => question(stringName, newName, typeName, src=u)
			when u in occurences
		case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression, src=loc v) => questionWithExpression(stringName, newName, typeName, expression, src=v)
			when v in occurences
		case ref(str name, src=loc w) => ref(newName, src=w)
			when w in occurences
	};
   return f; 
 } 
 
 
 

