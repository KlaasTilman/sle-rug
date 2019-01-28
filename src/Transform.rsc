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
	list[AQuestion] flattenedQuestions = [];
	for (AQuestion q <- f.questions) {
		flattenedQuestions += flattenQuestion(q, boolExpr(true));	
	}
	return form(f.name, flattenedQuestions, src=f.src); 
}

list[AQuestion] flattenQuestion(AQuestion q, AExpr booleanExpr) {
	list[AQuestion] flattening = [];
	switch (q) {
			case question(str stringName, str idName, AType typeName): 
				return flattening += ifStatement(booleanExpr, [q]);
			case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression):
				return flattening += ifStatement(booleanExpr, [q]);
			case ifStatement(AExpr expressionMain, list[AQuestion] questions): 
				{
					for (AQuestion q2 <- questions) {
						switch (q2) {
							case question(str stringName, str idName, AType typeName): 
								flattening += ifStatement(AND(booleanExpr, expressionMain), [q2]);
							case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression):
								flattening += ifStatement(AND(booleanExpr, expressionMain), [q2]);
							default: flattening += flattenQuestion(q2, AND(booleanExpr, expressionMain));
						}
					}
					return flattening;
				}	
			case ifElseStatement(AExpr expressionMain, list[AQuestion] questions, list[AQuestion] questions2): 
				{
					for (AQuestion q2 <- questions) {
						switch (q2) {
							case question(str stringName, str idName, AType typeName): 
								flattening += ifStatement(AND(booleanExpr, expressionMain), [q2]);
							case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression):
								flattening += ifStatement(AND(booleanExpr, expressionMain), [q2]);
							default: flattening += flattenQuestion(q2, AND(booleanExpr, expressionMain));
						}
					}
					for (AQuestion q2 <- questions2) {
						switch (q2) {
							case question(str stringName, str idName, AType typeName): 
								flattening += ifStatement(AND(booleanExpr, notExpr(expressionMain)), [q2]);
							case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression):
								flattening += ifStatement(AND(booleanExpr, notExpr(expressionMain)), [q2]);
							default: flattening += flattenQuestion(q2, AND(booleanExpr, notExpr(expressionMain)));
						}
					}
					return flattening;
				}	
		}	
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 * Bonus: do it on concrete syntax trees.
 */
 
 set[loc] getAllOccurences(Form f, loc useOrDef, UseDef useDef) {
 	set[loc] occurences = {};
 	// If it is empty, it is a definition
 	if (isEmpty(useDef[useOrDef])) {
 		// We add all uses
 		occurences += { use | <loc use, useOrDef> <- useDef};
 		if (!isEmpty(occurences)) {
 			loc firstUse = toList(occurences)[0];
 			// We add all definitions
 			occurences += { definitionToId(f, def) | <firstUse, loc def> <- useDef};
 		} else {
 			// No uses, we add the definition
 			occurences += definitionToId(f, useOrDef);
 		}
 	} else {
 		// The set is not empty so it is a use
 		
 		// We add all definitions
 		occurences += { definitionToId(f, def) | <useOrDef, loc def> <- useDef};
 		
 		loc firstDef = toList(useDef[useOrDef])[0];
 		// We add all uses
 		occurences += { use | <loc use, firstDef> <- useDef};
 	}
 	return occurences;
 } 
 
 loc definitionToId(Form f, loc def) {
 	for (/Question q := f) {
 		if (q@\loc == def) {
 			for (/Id i := q) {
 				return i@\loc;
 			}
 		}
 	}
 	return def;
 }
 
 Form rename(Form f, loc useOrDef, str newName, UseDef useDef) {
   
   // Try to parse the new name to see if it is valid
   try {
   	parse(#Id, newName);
   	} catch :
   	throw "Invalid new name";
   
   Id idNewName = parse(#Id, newName);
   
   for (/Id i := f) {
   		if (i == idNewName) {
   			throw "This name already exists";
   		}
   }
   
   	set[loc] occurences = getAllOccurences(f, useOrDef, useDef);	
	return visit(f) {
		case Id i => idNewName
		when i@\loc in occurences
	};
	
   return f; 
 } 
 
 
 

