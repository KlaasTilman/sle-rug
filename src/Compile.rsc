module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

int counter = 0;

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
	//writeFile(f.src[extension="js"].top, form2js(f));
	writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
	HTML5Node htmlForm=form();
	for (AQuestion q <- f.questions) {
		htmlForm.kids+=[formMainQuestion2html(q)];
	}
	return htmlForm.kids+=[button("Submit", id("submitButton"))];
}

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

HTML5Node formMainQuestion2html(AQuestion q) {
	switch (q) {
		case question(str stringName, str idName, AType typeName): 
			return formQuestion2html(q);
  		case questionWithExpression(str stringName, str idName, AType typeName, AExpr expression): 
			return formComputedQuestion2html(q);
  		case ifStatement(AExpr expression, list[AQuestion] questions):
  		{ 
  			counter=counter+1;
  			HTML5Node ifHtml=div(id(counter));
  			for (AQuestion q <- questions) {
  				ifHtml.kids+= [formMainQuestion2html(q)];
  			}
  			return ifHtml;
  		}
  		case ifElseStatement(AExpr expression, list[AQuestion] questions, list[AQuestion] questions2): 
  		{
  			HTML5Node ifElseHtml=div();
  			counter=counter+1;
 
  			HTML5Node ifHtml=div(id(counter));
  			counter=counter+1;
  			HTML5Node elseHtml=div(id(counter));
  			for (AQuestion q <- questions) {
  				ifHtml.kids+= [formMainQuestion2html(q)];
  			}
  			for (AQuestion q <- questions2) {
  				elseHtml.kids+= [formMainQuestion2html(q)];
  			}
  			ifElseHtml.kids+=[ifHtml];
  			ifElseHtml.kids+=[elseHtml];
  			return ifElseHtml;
  		}
	}
}



str form2js(AForm f) {
	
	return "";
}
