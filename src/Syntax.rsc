module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = "if" "(" Expr ")" "{" Question "}" 
  | String Id ":" Type
  | String Id ":" Type "=" Expr
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  	| Bool
  	| String
  	| Int
  	| "(" Expr ")"
  	| "!" Expr
  	> left ( multiplication: Expr "*" Expr
  	       | division: Expr "/" Expr)
  	> left ( addition: Expr "+" Expr
  	       | subtraction: Expr "-" Expr)
  	> non-assoc ( greaterThanOrEqual: Expr "\>=" Expr  
		        | smallerThanOrEqual: Expr "\<=" Expr 
		        | smallerThan: "\<" Expr 
		        | greaterThan: "\>" Expr 
	            )
	> left ( equals: Expr "==" Expr
  	       | notEquals: Expr "!=" Expr)
  	> left AND: Expr "&&" Expr
  	> left OR: Expr "||" Expr
  	;
  
syntax Type
   = integer:"integer" 
   | string :"string" 
   | boolean:"boolean"
   ;  
  
lexical Str = "\"" ![\"]*  "\"";

lexical Int 
  = "-"?[0-9]+;

lexical Bool = ("True" | "False");