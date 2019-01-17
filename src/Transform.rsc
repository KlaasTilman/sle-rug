module Transform

import Resolve;
import AST;
import IO;

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
 
 AForm rename(AForm f, loc useOrDef, str newName, UseDef useDef) {
   //println(useDef);
   println(useDef[useOrDef]);
   str oldName;
	for (/AQuestion q:=f) {
		// Set only contains all definitions
		if (q.src in useDef[useOrDef]) {
		
			q = question(q.stringName, newName, q.typeName);
			println(q.idName);
			oldName = q.idName;
			//q.idName = newName;
			println(q.idName);
		}
	}
	
	return visit(f) {
		case question(str stringName, str idName, AType typeName, src=loc u) => question(stringName, newName, typeName)
			when u in useDef[useOrDef]
	};
	

	
	for (/ref(oldName, src = loc u) := f) {
		println(u);
	}  
	println(f);
   return f; 
 } 
 
 
 

