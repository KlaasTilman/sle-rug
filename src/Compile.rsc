module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

int counter = 0;
int javascriptCounter = 0;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
	writeFile(f.src[extension="js"].top, form2js(f));
	writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

/* Convert a form to html by looping over all the questions */
HTML5Node form2html(AForm f) {
	HTML5Node htmlForm=form();
	htmlForm.kids+=[script(src("https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"))];
	htmlForm.kids+=[script(src(f.name+".js"))];
	for (AQuestion q <- f.questions) {
		htmlForm.kids+=[formMainQuestion2html(q)];
	}
	return htmlForm.kids+=[button("Submit", id("submitButton"))];
}

/* Convert a not yet computed question to html (so should be editable) */
HTML5Node formQuestion2html(AQuestion q) {
	HTML5Node htmlForm=form();
	switch (q.typeName) {
		case string(): htmlForm=div(q.stringName,input(\type("text"), name(q.idName)));
		case integer(): htmlForm=div(q.stringName,input(\type("numeric"), name(q.idName)));
		case boolean(): htmlForm=div(q.stringName,input(\type("checkbox"), name(q.idName)));
		default:;
	}
	return htmlForm;
}

/* Convert a question which is already computed to html (so should not be editable) */
HTML5Node formComputedQuestion2html(AQuestion q) {
	HTML5Node htmlForm=form();
	switch (q.typeName) {
		case string(): htmlForm=div(q.stringName,input(\type("text"), name(q.idName), readonly("")));
		case integer(): htmlForm=div(q.stringName,input(\type("numeric"), name(q.idName), readonly("")));
		case boolean(): htmlForm=div(q.stringName,input(\type("checkbox"), name(q.idName), readonly("")));
		default:;
	}
	return htmlForm;
}

/* Recursively convert all question to html by calling the corresponding functions */
HTML5Node formMainQuestion2html(AQuestion q) {
	switch (q) {
		case question(str stringName, str idName, AType typeName): 
			return formQuestion2html(q);
  		case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): 
			return formComputedQuestion2html(q);
  		case ifStatement(AExpr expression, list[AQuestion] questions):
  		{ 
  			// We increase the counter to be able hide and show questions
  			counter=counter+1;
  			HTML5Node ifHtml=div(id(counter));
  			// We loop over all the if-questions and convert them to html
  			for (AQuestion q <- questions) {
  				ifHtml.kids+= [formMainQuestion2html(q)];
  			}
  			return ifHtml;
  		}
  		case ifElseStatement(AExpr expression, list[AQuestion] questions, list[AQuestion] questions2): 
  		{
  			HTML5Node ifElseHtml=div();
			// We increase the counter to be able hide and show questions
  			counter=counter+1;
 
  			HTML5Node ifHtml=div(id(counter));
  			// We increase the counter to be able hide and show questions
  			counter=counter+1;
  			HTML5Node elseHtml=div(id(counter));
  			// We loop over all the if-questions and convert them to html
  			for (AQuestion q <- questions) {
  				ifHtml.kids+= [formMainQuestion2html(q)];
  			}
			// We loop over all the if-questions and convert them to html
  			for (AQuestion q <- questions2) {
  				elseHtml.kids+= [formMainQuestion2html(q)];
  			}
  			// We add both the if and else html and return everything
  			ifElseHtml.kids+=[ifHtml];
  			ifElseHtml.kids+=[elseHtml];
  			return ifElseHtml;
  		}
	}
}

/* Convert a form to javascript */
str form2js(AForm f) {
	str javascriptForm="";
	javascriptForm += "$(document).ready(function(){\n";
	// Initialise all variables
	for (/AQuestion q:=f) {
		if (q has typeName && !(q has expression)) {
			switch (q.typeName) {
				case integer(): javascriptForm += "var "+q.idName+" = 0;\n";
				case boolean(): javascriptForm += "var "+q.idName+" = false;\n";
				case string(): javascriptForm += "var "+q.idName+" = \"\";\n";
			}
		}
	}
	// Compute all questions with an expression
	for (/AQuestion q:=f) {
		if (q has typeName && q has expression) {
			javascriptForm += "var "+q.idName+" = "+exprToJS(q.expression)+";\n";
			javascriptForm += "$(\"input[name=\'"+q.idName+"\']\").val("+q.idName+");\n";
		}
	}
	
	str showHide="";
	for (AQuestion q <- f.questions) {
		showHide += formMainJavascript(q);
	}
	
	javascriptForm += showHide;
	
	javascriptForm +="$(\'input\').change(function(){\n";
	
	// Make sure values change when input is changed
	for (/AQuestion q:=f) {
		if (q has typeName && !(q has expression)) {
			javascriptForm += q.idName + " = $(\"input[name=\'"+q.idName+"\']\").";
			switch (q.typeName) {
				case integer(): javascriptForm +="val();\n";
				case boolean(): javascriptForm += "prop(\'checked\');\n";
				case string(): javascriptForm += "val();\n";
			}
		}
	}
	
	// Make sure values are re-computed when input is changed
	for (/AQuestion q:=f) {
		if (q has typeName && q has expression) {
			javascriptForm += q.idName + " = " + exprToJS(q.expression) + ";\n";
			javascriptForm += "$(\"input[name=\'"+q.idName+"\']\").val("+q.idName+");\n";
		}
	}
	
	javascriptForm += showHide;
	
	javascriptForm += "});\n";

	javascriptForm += "});\n";
	return javascriptForm;
}

/* Convert a question to javascript */
str formMainJavascript(AQuestion q) {
	switch (q) {
		// Make sure certain questions are hidden/shown when the guard is true for the if-statement
  		case ifStatement(AExpr expression, list[AQuestion] questions):
  		{ 
  			javascriptCounter=javascriptCounter+1;
  			str ifJavascript=
  			"if ("+exprToJS(expression)+") {
  				$(\"#"+"<javascriptCounter>"+"\").show();
  			} else {
  				$(\"#"+"<javascriptCounter>"+"\").hide();
  			}\n";
  			for (AQuestion q <- questions) {
  				ifJavascript+= formMainJavascript(q);
  			}
  			return ifJavascript;
  		}
  		// Make sure certain questions are hidden/shown when guard is true for the if or else statement
  		case ifElseStatement(AExpr expression, list[AQuestion] questions, list[AQuestion] questions2): 
  		{
  			javascriptCounter=javascriptCounter+1;
  			str ifElseJavascript=
  			"if ("+exprToJS(expression)+") {
  				$(\"#"+"<javascriptCounter>"+"\").show();
  				$(\"#"+"<javascriptCounter+1>"+"\").hide();
  			} else {
  				$(\"#"+"<javascriptCounter>"+"\").hide();
  				$(\"#"+"<javascriptCounter+1>"+"\").show();
  			}\n";
  			javascriptCounter=javascriptCounter+1;
  			for (AQuestion q <- questions) {
  				ifElseJavascript+= formMainJavascript(q);
  			}
  			for (AQuestion q <- questions2) {
  				ifElseJavascript+= formMainJavascript(q);
  			}
  			return ifElseJavascript;
  		}
	}
	return "" ;
}

/* Convert an expression to javascript */
str exprToJS(AExpr e) {
	switch (e) {
		case ref(str x): return x;
		case boolExpr(bool boolValue): return "<boolValue>";
		case strExpr(str stringValue): return "<stringValue>";
		case intExpr(int intValue): return "<intValue>";
		case bracketExpr(AExpr expression): return "("+exprToJS(expression)+")";
		case notExpr(AExpr expression): return "!"+exprToJS(expression);
		case multiplicate(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "*" + exprToJS(expression2);
		case divide(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "/" + exprToJS(expression2);
		case add(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "+" + exprToJS(expression2);
		case subtract(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "-" + exprToJS(expression2);
		case greaterThanOrEqual(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "\>=" + exprToJS(expression2);
		case smallerThanOrEqual(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "\<=" + exprToJS(expression2);
		case smallerThan(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "\<" + exprToJS(expression2);
		case greaterThan(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "\>" + exprToJS(expression2);
		case equals(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "==" + exprToJS(expression2);
		case notEquals(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "!=" + exprToJS(expression2);
		case AND(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "&&" + exprToJS(expression2);
		case OR(AExpr expression1, AExpr expression2): return exprToJS(expression1) + "||" + exprToJS(expression2);
		default: throw "Unsupported expression <e>";
	}
}
