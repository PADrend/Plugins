/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*
	The TreeQueryLanguage is a simple XPath-like language to specify node sets in form of
	a string expression. It was developed to work for MinSG-trees, but its core may be used 
	for other tree data structures as well.
	This file contains the core features and should only be interesting if you want
	to extend the language, fix a bug or adapt it for other data structures.
	
	The parser converts a query-string into an executable syntax tree.
	A syntax tree consists of function calls, simple values (bool, string, number), 
	and variables ($foo).
	To see the structure of a syntax tree, you can use the syntax tree's toDbgString() function.
	Examples:
	'(2+(3))*2'
		---> *(+(2, 3), 2)
	'foo(1,2+40,foo("bar",100))
		---> foo(1, +(2, 40), foo(bar, 100))
	
	'test:exampleSet/(test:modFilter(2)|test:modFilter(3))/test:debugOutput/test:inc/test:debugOutput'
		---> /(/(/(/(test:exampleSet(), |(test:modFilter(2), test:modFilter(3))), test:debugOutput()), test:inc()), test:debugOutput())

	Unsupported prominent XPath-features are axes (axis::param) and predicates ([condition()]).
*/

static Set = Std.require('Std/Set');


// ---------------------------------------
// components of the syntax tree

static ValueExpression = new Type;
ValueExpression.value := void;
ValueExpression._constructor ::= fn(_value){this.value = _value;};
ValueExpression._call  ::= fn(caller,ctxt){
	return this.value;
};
ValueExpression.toDbgString ::= fn(){	return ""+this.value;};
	
//! \note Expects the variables to be stored in the ctxt's $variables member
static VarExpression = new Type;
VarExpression.name := void;
VarExpression._constructor ::= fn(_name){this.name = _name;};
VarExpression._call  ::= fn(caller,ctxt){
	if(!ctxt.variables.containsKey(this.name)){
		Runtime.exception("TreeQuery: Unknown variable '"+this.name+"'");
	}
	return ctxt.variables[ this.name ];
};
VarExpression.toDbgString ::= fn(){	return ""+this.name;};

//! \note Expects the functions to be stored in the ctxt's $functions member
static FnExpression = new Type;
FnExpression.fnName := void;
FnExpression.parameterQObjects := void;
FnExpression._constructor ::= fn(_fnName, parameters...){
	this.fnName = _fnName;
	this.parameterQObjects = parameters;
};
FnExpression._call  ::= fn(caller,ctxt,additionalValues...){
	var fun = ctxt.functions[this.fnName];
	if(!fun)
		Runtime.exception("TreeQuery: Unknown function '"+this.toDbgString()+"'");
	if(additionalValues.empty()){
		return fun(ctxt,parameterQObjects...);
	}else{
		// wrap values inside functions
		foreach(additionalValues as var idx,var value)
			additionalValues[idx] = [value] =>fn(value,ctxt){	return value; };
		return fun(ctxt,parameterQObjects...,additionalValues...);
	}
};
FnExpression.toDbgString ::= fn(){
	var arr = [];
	foreach(parameterQObjects as var pObj)
		arr+=pObj.toDbgString();
	return ""+this.fnName+"("+arr.implode(", ")+")";
};

// ---------------------------------------
// tokens

static T_UNKNOWN = false;
static T_OPERATOR = 0;
static T_IDENTIFIER = 1;
static T_OPENING_BRACKET = 2;
static T_CLOSING_BRACKET = 3;
static T_SIMPLE_TYPE = 4;
static T_VARIABLE = 5;

static Token = new Type;

Token.type := void;
Token.value := void;
Token._constructor ::= fn(_type,_value){
	this.type = _type;
	this.value = _value;
};

// ---------------------------------------
// parser

var T = new Type;
T.operatorInitials @(private,init) := Map;
T.operatorSet @(private,init) := Set;
T.operatorPrecedences @(private,init) := Map;
T.activeQuery @(private) := "";

T.initOperators ::= fn(Array _operators){
	foreach( _operators as var p,var op)
		this.operatorPrecedences[op] = p;
	this.operatorSet.merge(_operators);
	foreach(_operators as var w){
		var c = w[0];
		if(!this.operatorInitials[c])
			this.operatorInitials[c] = new Array;
		this.operatorInitials[c] += w;
	}
	foreach( this.operatorInitials as var arr) // longest operators first
		arr.sort( fn(a,b){return  a.length()>b.length();} );
};
//! split the @p str according to the parser's operators
T.tokenize ::= fn(String str){
	var len = str.length();
	var pos = 0;
	var accum = "";
	
	var tokens = [];
	while(pos<len){
		var c = str[pos];
		while(c==' '||c=='\t'){
			++pos;
			if(pos==len)
				break;
			c = str[pos];
		}
		if( c=='('){
			if( pos+1<len&&str[pos+1]==':'){ // comment
				if(!accum.empty()){
					tokens += new Token(T_UNKNOWN,accum);
					accum = "";
				}
				pos = str.find(':)',pos+2);
				if(!pos)
					break;
				pos+=2; // skip ')'
				continue;
			}
			tokens += new Token(T_OPENING_BRACKET,c);
			++pos;
			continue;
		}else if(c==')'){
			tokens += new Token(T_CLOSING_BRACKET,c);
			++pos;
			continue;
		}
		
		if( this.operatorInitials[c] ){ // try to read operator
			var op;
			// search for the longest, matching operator
			foreach(this.operatorInitials[c] as var possibleOperator){
				if(str.beginsWith(possibleOperator,pos)){
					op = possibleOperator;
					break;
				}
			}
			if(op){
				if(!accum.empty()){
					tokens += new Token(T_UNKNOWN,accum);
					accum = "";
				}
				tokens +=  new Token(T_OPERATOR,op);
				pos += op.length();
				continue;
			}
		}
		if( c=='"' || c=="'"){ // read string
			var ending = c;
			if(!accum.empty()){
				
				tokens += new Token(T_UNKNOWN,accum);
				accum = "";
			}
			++pos;
			for(; pos<len; ++pos){
				c = str[pos];
				if( c==ending ){
					++pos;
					break;
				}else if( c=='\\' && pos<len-1){
					++pos;
					accum += str[pos];
				}else{
					accum += c;
				}
			}
			tokens += new Token(T_SIMPLE_TYPE,accum);
			accum = "";
			continue;
		}else if(c>='0'&&c<='9'){ // read number
			accum = c;
			++pos;
			for(; pos<len; ++pos){
				c = str[pos];
				if(c=='.'){
					accum += c;
					++pos;
					for(; pos<len; ++pos){
						c = str[pos];
						if(c<'0'||c>'9')
							break;
						accum += c;
					}
					break;
				}
				if(c<'0'||c>'9')
					break;
				accum += c;
			}
			tokens += new Token(T_SIMPLE_TYPE,0+accum);
			accum = "";
			continue;
		}else{ // read identifier
			accum += c;
			++pos;

			for(; pos<len; ++pos){
				c = str[pos];
				// operator?
				if( this.operatorInitials[c] &&
						!((c>='a'&&c<='z') || (c>='A'&&c<='Z') || (c>='0'&&c<='9') || c=='-')) // special case: identifier may contain -
					break;
				// whitespace?
				if( c==' ' || c=='\t' || c=='\n' || c=='(' || c==')')
					break;
				accum += c;
			}
			tokens += new Token(T_UNKNOWN,accum);
			accum = "";
		}
	}
	if(!accum.empty())
		tokens += new Token(T_UNKNOWN,accum);
		
	foreach(tokens as var t){
		if(t.type == T_UNKNOWN){
			if(t.value == "true"){
				t.value = true;
				t.type = T_SIMPLE_TYPE;
			}else if(t.value == "false"){
				t.value = false;
				t.type = T_SIMPLE_TYPE;
			}else if(this.operatorSet.contains(t.value)){
				t.type = T_OPERATOR;
			}else if(t.value[0]=="$"){
				t.type = T_VARIABLE;
				t.value = t.value.substr(1);
			}else{
				t.type = T_IDENTIFIER;
			}
		}
		t._printableName := "["+ t.type + ":"+t.value+"]"; // debug
	}
	return tokens;

};
T.syntaxError @(private) := fn(msg){
	Runtime.exception("Syntax error in query ( #"+msg+" ): "+this.activeQuery);
};
T.getExpression @(private) ::= fn(tokens,Number first, Number last){
//		outln("Exp ",first,"-",last);
	if(last<first)
		this.syntaxError( __LINE__ );
	var t = tokens[first];
	if( t.type==T_OPENING_BRACKET && t.closingBracket==last ){ // surrounded in brackets
		return this.getExpression(tokens,first+1,last-1);
	}else if(first==last){	// function call OR single value
		if( t.type == T_SIMPLE_TYPE){
			return new ValueExpression(t.value);
		}else if( t.type == T_IDENTIFIER ){
			return new FnExpression(t.value);
		}else if( t.type == T_OPERATOR){
			return new FnExpression(t.value+"_isolated");
		}else if( t.type == T_VARIABLE){
			return new VarExpression(t.value);
		}else{
			this.syntaxError( __LINE__ );
		}
	}else{ // search dominant operator
		var opIndex = false;
		var opPrecedence = 10000000;
		for(var cursor=first;cursor<=last;){
			t = tokens[cursor];
			if(t.type==T_OPENING_BRACKET){
				cursor = t.closingBracket;
				continue;
			}else if(t.type==T_OPERATOR && this.operatorPrecedences[t.value]<=opPrecedence){
				opPrecedence = this.operatorPrecedences[t.value];
				opIndex = cursor;
			}
			++cursor;
		}
		if(opIndex){ // operator:  '4 + 3' --> +(4,3)
			var op = tokens[opIndex];
			if(opIndex==first){ // operator: '/foo' ---> /_prefix(foo)
				return new FnExpression(op.value+"_prefix",getExpression(tokens,first+1,last) );
			}else if(opIndex==last){ // operator: 'foo/' ---> /_postfix(foo)
				return new FnExpression(op.value+"_postfix",getExpression(tokens,first,last-1) );
			}else{
				return new FnExpression(op.value,
										getExpression(tokens,first,opIndex-1),
										getExpression(tokens,opIndex+1,last));
			}
		}
		// function call: foo(1,2,3)
		if(tokens[first].type == T_IDENTIFIER && 
				tokens[last].type == T_CLOSING_BRACKET && 
				tokens[last].openingBracket==first+1){
			var paramMarker = [first+1];
			for(var cursor = first+2;cursor<last;){
				t = tokens[cursor];
				if(t.type==T_OPENING_BRACKET){
					cursor = t.closingBracket;
					continue;
				}else if(t.type == T_OPERATOR && t.value==','){
					paramMarker+=cursor;
				}
				++cursor;
			}
			paramMarker += last;

			var params = [];
			var paramMarkerCount = paramMarker.count();
			if(paramMarkerCount>=2){
				for(var i=0;i<paramMarkerCount-1;++i)
					params += getExpression(tokens,paramMarker[i]+1,paramMarker[i+1]-1);
			}
			return new FnExpression(tokens[first].value, params...);
		}
		print_r(tokens);
		this.syntaxError( ""+first+"-"+last+"("+__LINE__+")" );

	}
};
T.parse ::= fn(String s){
	this.activeQuery = s; // stored for error messages
	
	// tokenize
	var tokens = this.tokenize(s);
//	print_r(tokens);

	{	// connect brackets
		var bracketStack = [];
		foreach(tokens as var index,var t){
			if(t.type == T_OPENING_BRACKET){
				bracketStack.pushBack( index );
			}else if(t.type == T_CLOSING_BRACKET){
				if( bracketStack.empty() )
					this.syntaxError("')'");
				var openingIndex = bracketStack.popBack();
				t.openingBracket := openingIndex;
				tokens[openingIndex].closingBracket := index;
			}
		}
		if( !bracketStack.empty() )
			this.syntaxError("unclosed ')'");
	}
	// build syntax tree
	return getExpression(tokens,0,tokens.count()-1);
};
var TreeQueryParser = T;


/*! [LibMinSGExt]	TreeQueries
	XPath-like queries for referencing nodes in a tree. 
	
	
	Examples:
		var ctxt = Query.createContext(sceneManager);

		Query.parse(".")(ctxt,[root,n1] );
		Query.parse("/child")(ctxt,[root]);
		Query.parse("/")(ctxt,n1);
		Query.parse("./ancestor")(ctxt,n1);
		Query.parse("ancestor-or-self")(ctxt,n1);
		Query.parse("/MinSG:collectListNodes/MinSG:nAttrFilter('name')")(ctxt,root);
		Query.parse("MinSG:collectGeometryNodes")(ctxt,root);
		Query.parse("MinSG:id('foo')")(ctxt);
		Query.parse("MinSG:id('$foo')")(ctxt);
*/

// ---------------------------------------------------------------
// MinSG-specific part

static SemObjTools = Std.require('LibMinSGExt/SemanticObject');

// ----------------------------------------------------------------------------
//// Query functions:

//! (helper) if no input is given, extract it from the context
static getInput = fn(ctxt,input){
	return void==input ? ctxt.input : input(ctxt);
};


var fn_collectNodesByType = fn(_nodeType, ctxt,input=void){
	var output = new Set;
	foreach(getInput(ctxt,input) as var node){
		foreach(MinSG.collectNodes(node,_nodeType) as var n)
			output += n;
	}
	return output;
};

var fn_descendantOrSelf = fn(ctxt,input=void){
	var output = new Set;
	foreach(getInput(ctxt,input) as var node){
		foreach(MinSG.collectNodes(node) as var n)
			output += n;
	}
	return output;
};
var fn_parent = fn(ctxt,input=void){
	var output = new Set;
	foreach(getInput(ctxt,input) as var node){
		var p = node.getParent();
		if(p)
			output += p;
	}
	return output;
};
var fn_root = fn(ctxt,input=void){
	var output = new Set;
	foreach(getInput(ctxt,input) as var node){
		while(node.hasParent())
			node = node.getParent();
		output += node;
	}
	return output;
};
var fn_self = fn(ctxt){
	return ctxt.input.clone();
};
var fn_union = fn(ctxt,p1,p2,input=void){
	if(input){
		var inputValue = input(ctxt);
//		print_r(inputValue);
		return p1(ctxt,inputValue).merge( p2(ctxt,inputValue));
	}else{
		return p1(ctxt).merge( p2(ctxt) );
	}
};

static functionRegistry = {
	'+' : fn(ctxt,p1,p2){	return p1(ctxt) + p2(ctxt);	},
	'*' : fn(ctxt,p1,p2){	return p1(ctxt) * p2(ctxt);	},
	'-' : fn(ctxt,p1,p2){	return p1(ctxt) - p2(ctxt);	},
	'/' : fn(ctxt,p1,p2){	return p2(ctxt, p1(ctxt));	},
	'/_prefix' : fn(ctxt,rightSide,input=void){
		var output = new Set;
		foreach(getInput(ctxt,input) as var node){
			while(node.hasParent())
				node = node.getParent();
			output += node;
		}
		return rightSide(ctxt,output);
	},
	'/_isolated' : fn_root,
	'//' : fn_descendantOrSelf,
	'|' : fn_union,
	'.' : fn_self,
	'..' : fn_parent,
	'ancestor' : fn(ctxt,input=void){
		var output = new Set;
		foreach(getInput(ctxt,input) as var node){
			for(var n = node.getParent(); n; n = n.getParent())
				output += n;
		}
		return output;
	},
	'ancestor-or-self' : fn(ctxt,input=void){
		var output = new Set;
		foreach(getInput(ctxt,input) as var node){
			for(; node; node = node.getParent())
				output += node;
		}
		return output;
	},
	'child' : fn(ctxt,input=void){
		var output = new Set;
		foreach(getInput(ctxt,input) as var node){
			foreach(MinSG.getChildNodes(node) as var child){
				output += child;
			}
		}
		return output;
	},
	'descendant' : fn(ctxt,input=void){
		var output = new Set;
		foreach(getInput(ctxt,input) as var node){
			foreach(MinSG.collectNodes(node) as var n)
				if(n!=node)
					output += n;
		}
		return output;
	},
	'descendant-or-self' : fn_descendantOrSelf,
	'parent' : fn_parent,
	'root' : fn_root,
	'self' : fn_self,
	'test:exampleSet' : fn(ctxt){
		return new Set([1,2,3,4,5,6]);//.implode(",");
	},
	'test:modFilter' : fn(ctxt,p1, input){
		var result = new Set;
		var f = p1(ctxt);
		foreach(input(ctxt) as var value){
			if((value%f)==0)
				result += value;
		}
		return result;
	},
	'test:debugOutput' : fn(ctxt,input){
		var value = input(ctxt);
		if(value---|>Set){
			outln("(",value.toArray().implode(","),")");
		}else{
			outln(value);
		}
		return value;
	},
	// increase all values of the input set by one
	'test:inc' : fn(ctxt,input=void){
		var output = new Set;
		foreach( getInput(ctxt,input) as var value )
			output += value+1;
		return output;
	},
	'union' : fn_union,
	'MinSG:collectGeometryNodes' : [MinSG.GeometryNode] => fn_collectNodesByType,
	'MinSG:collectListNodes' : [MinSG.ListNode] => fn_collectNodesByType,
	'MinSG:collectCameraNodes' : [MinSG.CameraNode] => fn_collectNodesByType,
	'MinSG:commonSubtree' : fn(ctxt,input=void){
		var subtreeRoot;
		foreach(getInput(ctxt,input) as var node){
			if(!subtreeRoot){
				subtreeRoot = node;
			}else{
				subtreeRoot = MinSG.getRootOfCommonSubtree(subtreeRoot,node);
				if(!subtreeRoot) // no common subtree found!
					break;
			}
		}
		return subtreeRoot ? new Set([subtreeRoot]) : new Set;
	},
	'MinSG:containingSemObj' : fn(ctxt,input=void){
		var output = new Set;
		foreach(getInput(ctxt,input) as var node){
			var obj = SemObjTools.getContainingSemanticObject(node);
			if(obj)
				output += obj;
		}
		return output;
	},
	'MinSG:collectRefId' : fn(ctxt,pNodeId, input=void){
		// All nodes for which:
		//		id is in the subtree(s) OR an instance of node with id is in the subtree(s)
		var output = new Set;
		var originalNode = ctxt.sceneManager.getRegisteredNode(pNodeId(ctxt));
		if(originalNode){
			var inputNodes = getInput(ctxt,input);
			foreach(inputNodes as var subtree){
				if( MinSG.isInSubtree(originalNode,subtree) ){
					output += originalNode;
					break;
				}
			}
			foreach(inputNodes as var subtree)
				output.merge( MinSG.collectInstances(subtree,originalNode) );
		}
		return output;
	},
	'MinSG:id' : fn(ctxt,pId,input = void){ // input is ignored
		var output = new Set;
		var node = ctxt.sceneManager.getRegisteredNode( pId(ctxt) );
		if(node)
			output += node;
		return output;
	},
	'MinSG:nAttrFilter' : fn(ctxt, pAttrName, p1=void, p2=void){
		var output = new Set;
		var attrName = pAttrName(ctxt);
		var inputOrValue = p1 ? p1(ctxt) : void;
		
		// MinSG:nAttrFilter( 'attrName' , 'attrValue' [,  nodes])
		if(inputOrValue---|>String){
			foreach(getInput(ctxt,p2) as var node){
				if(inputOrValue==node.findNodeAttribute(attrName))
					output += node;
			}
		}// MinSG:nAttrFilter( 'attrName', [,  nodes])
		else{
			var input = inputOrValue ? inputOrValue : ctxt.input;
			foreach(input as var node){
				if(void!=node.findNodeAttribute(attrName))
					output += node;
			}
		}
		return output;
	},
};

// MinSG:baseId
// MinSG:collectInstancesOf
// MinSG:containingSObject
/* todo
	instancesOf( nodeId )
	instancesOfQuery( query )
	prototype
	original
	closedNodes
	containingSemObject
	withState( stateId )
	leafs
	states
	

*/
static createContext = fn(MinSG.SceneManager sm,input=void,[Map,void] variables=void){
	var ctxt = new ExtObject;
	ctxt.sceneManager := sm;
	ctxt.functions := functionRegistry;
	ctxt.variables := variables ? variables : new Map;
	ctxt.input := input ? new Set(input) : new Set;
	return ctxt;
};

static parse = {
	var minsgParser = new TreeQueryParser;
	minsgParser.initOperators([ // operators (only a subset is actually implemented)
		',',
		'for','some', 'every', 'if',
		'or',
		'and',
		'eq','ne','lt','gt','ge','=','!=','<','<=','>','>=','is','<<','>>',
		'to',
		'+','-',
		'*','div','idiv','mod',
		'union', '|',
		'intersect', 'except',
		'instance of',
		'treat',
		'castable',
		'cast',
		'?',
		'/','//',
		'[',']'
	]);
	minsgParser->minsgParser.parse;
};

//! @p Query string, @p sceneManager, @p (optional) input collection, @p (optional) variable map
static execute = fn(String query,params...){
	return parse(query)(createContext(params...));
};

// (internal) Only call if it known that @p source is in the subtree of @p ancestor
static createQueryToAncestor = fn(MinSG.Node source, MinSG.Node ancestor){
//	if(!ancestor.hasParent()){
//		return "root";
//	}else 
	if(SemObjTools.isSemanticObject(ancestor)){
		var i = 1;
		for( var n = SemObjTools.getContainingSemanticObject(source);n!=ancestor;n=SemObjTools.getContainingSemanticObject(n)){
			if(!n)
				return false;
			++i;
		}
		return "."+ "/MinSG:containingSemObj"*i;
	}else{
		var i = 1;
		for(var n = source.getParent(); n!=ancestor; n=n.getParent()){
			if(!n)
				return false;
			++i;
		}
		return "."+ "/.."*i;
	}
};

//collectRefId(sm)  id is in the subtree Or an instance of the node is in the subtree

static createRelativeNodeQuery = fn(MinSG.SceneManager sm, MinSG.Node source, MinSG.Node target){
	if(source == target)
		return "self";
	if(target.getParent()==source && source.countChildren() == 1)
		return "child";
	if(MinSG.isInSubtree(source,target)) // source lies in target's subtree
		return createQueryToAncestor(source,target);

	var commonRoot = MinSG.isInSubtree(target, source) ? source : void;
	if(!commonRoot){
		commonRoot = SemObjTools.getCommonSemanticObject(source,target);
		if(!commonRoot){
			commonRoot = MinSG.getRootOfCommonSubtree(source,target);
			if(!commonRoot){
				return false;
			}
		}
	}

	var query = (source == commonRoot) ? "." : createQueryToAncestor(source,commonRoot);
	if(!query)
		return false;
	var id = sm.getNameOfRegisteredNode(target);
	if(id){ // connects by id?
		query += "/MinSG:collectRefId('" + id + "')";
	} // only child of a parent with id?
	else if(target.hasParent() && (id = sm.getNameOfRegisteredNode(target.getParent())) &&
				target.getParent().countChildren() == 1){
		query += "/MinSG:collectRefId('" + id + "')/child"; 
	} // target is only instance of a prototype in the subtree
	else if(target.isInstance()&&sm.getNameOfRegisteredNode(target.getPrototype())&&MinSG.collectInstances(commonRoot,target.getPrototype()).count()==1)  {
		query += "/MinSG:collectRefId('" + sm.getNameOfRegisteredNode(target.getPrototype()) + "')";
	}else{
		return false;
	}
	
//	outln("Query? ",query);
	var testResult = execute(query,sm,[source]);
	if( testResult---|>Set && testResult.toArray() == [target] )
		return query;
//	outln("Invalid results:", testResult.toArray().implode(",") );
	return false;
};

var TreeQueryTools = new Namespace;
TreeQueryTools.parse := parse;
TreeQueryTools.execute := execute;
TreeQueryTools.createContext := createContext;
TreeQueryTools.createRelativeNodeQuery := createRelativeNodeQuery;

return TreeQueryTools;
