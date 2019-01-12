module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

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
		if (q has stringName) {
			htmlForm=formQuestion2html(q, htmlForm);
		}
	}
	return htmlForm;
}

HTML5Node formQuestion2html(AQuestion q, HTML5Node htmlForm) {
	switch (q.typeName) {
		case integer(): htmlForm.kids+=[q.stringName,input(\type("password"), name("fname"))];
		case string(): htmlForm.kids+=[q.stringName, input("type=\"text\" name=\"fname\"")];
		case boolean(): htmlForm.kids+=[q.stringName, input("type=\"text\" name=\"fname\"")];
		default:;
	}
	return htmlForm;
}

str form2js(AForm f) {
	return "";
}
