/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tests] Tests/AutomatedTests/Util.escript
 **/

var AutomatedTest = Std.require('Tests/AutomatedTest');

var tests = [];

tests += new AutomatedTest("Example Test",fn(){
	addResult("Part 1",true);
	addResult("Part 2",true);
});

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/DestructionMonitor" , fn(){


//	addResult("Array.slice",
	var monitor = new Util.DestructionMonitor();
	
	{
		var o = new ExtObject({ m:monitor.createMarker("foo") }); 
		monitor.createMarker("instantlyReleased");
		var m = monitor.createMarker("localVar");
		
		addResult("a)", monitor.markersAvailable() && 
					monitor.getPendingMarkersCount()==2 && 
					monitor.extractMarkers() == ["instantlyReleased"] && 
					monitor.getPendingMarkersNames().count()==2 &&
					monitor.getPendingMarkersNames().contains("foo") &&
					monitor.getPendingMarkersNames().contains("localVar")
		);
					
					
					
	}
	var releasedMarkers = monitor.extractMarkers();
	addResult("b)", !monitor.markersAvailable() &&
				releasedMarkers.count() == 2 &&
				releasedMarkers.contains("foo") && 
				releasedMarkers.contains("localVar") &&
				monitor.getPendingMarkersNames().empty()
	);
});

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/Command" , fn(){
	static Command = Std.require('LibUtilExt/Command');
	static CommandHistory = Std.require('LibUtilExt/CommandHistory');
	var hist = new CommandHistory;
	
	var obj = new ExtObject( {$m1:1} );
	
	var MyCommand = new Type(Command);
	//! (ctor) ---|> Command
	MyCommand._constructor ::= fn(obj,summand) . ({
		$obj : obj,
		$summand : summand,
		Command.EXECUTE : fn(){ obj.m1+=summand; },
		Command.UNDO : fn(){ obj.m1-=summand; },
	}){	};
	
	var MyCommand_2 = new Type(Command); // not undoable!
	//! (ctor) ---|> Command		
	MyCommand_2._constructor ::= fn(obj,summand) . ({
		$obj : obj,
		$summand : summand,
		Command.EXECUTE : fn(){ obj.m1+=summand; }
	}){	};
	
	var MyCommand_3 = new Type(Command); // not executed locally --> never executed at all
	//! (ctor) ---|> Command		
	MyCommand_3._constructor ::= fn(obj,summand) . ({
		$obj : obj,
		$summand : summand,
		Command.EXECUTE : fn(){ obj.m1+=summand; },
		Command.FLAGS : 0
	}){	};
	
	hist.execute(new MyCommand(obj,4)); // +4
	hist.execute(new MyCommand(obj,17));// +17
	hist.execute(new MyCommand(obj,27));// +27
	hist.undo();// -27
	hist.execute(new MyCommand_2(obj,100));// +100
	hist.undo();// -17
	hist.redo();// +17
	hist.execute(new MyCommand(obj,3));// +3
	
	var c = new MyCommand_3(obj,1000); 
	var c2 = c.clone();
	c2.setFlags(Command.FLAG_EXECUTE_LOCALLY);

	hist.execute(c); // +0   (shouldn't do anything)
	hist.execute(c2); // +1000
	
	return obj.m1 == 1+4+17+27-27+100-17+17+3 +1000;
	
});
// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/DataWrapper" , fn(){

	{
		var sideLength = DataWrapper.createFromValue( 10 );
		var area = DataWrapper.createFromFunctions( (fn(sideLength){	return sideLength()*sideLength(); }).bindLastParams(sideLength),
														(fn(data,sideLength){	sideLength.set(data.sqrt());} ).bindLastParams(sideLength));
		
		// propagate changes of the sideLength to the area. sideLength and data are now directly connected.
		sideLength.onDataChanged += area->fn(data){refresh();};

		var result = true;
		// --------
		
		result &= (area() == 100);
		area(81);
		result &= (sideLength() == 9);
		sideLength(5);
		result &= (area() == 25);
		addResult("DataWrapper 1",result);
	}
	
	// --------
	
	{
		var a = new ExtObject({ $m : 3 });
		var wrapper = DataWrapper.createFromAttribute(a,$m);
		
		wrapper(wrapper()+20);
		a.m+=100;
		wrapper.refresh();
		
		addResult("DataWrapper 2",wrapper() == 123 );
	}
		
	// --------
	
	{
		var map = { 'm' : 3 };
		var wrapper = DataWrapper.createFromEntry(map,'m');
		wrapper(wrapper()+20);
		map['m'] += 100;

		var array = [0,3,17];
		var wrapper2 = DataWrapper.createFromEntry(array,1);

		wrapper2(wrapper2()+20);
		array[1] += 100;
		addResult("DataWrapper 3",
					wrapper() == 123 && map ==  { 'm' : 123 }
					&& wrapper2() == 123 && array==[0,123,17] );
	}
	
	// --------
	{
		var ok = true;
		
		var d1 = DataWrapper.createFromValue(1);
		var g = new DataWrapperContainer({ 
				$d2 : DataWrapper.createFromValue(2)
		});
		g.addDataWrapper($d1,d1);
		
		var log = [];
		g.onDataChanged += [log] => fn(log, key,value){
			log+=""+key+":"+value;
		};
		
		g.merge({
			$d3 : DataWrapper.createFromValue(3)
		});

		{
			var sum = 0;
			foreach(g.getValues() as var key,var value)
				sum += value;
			ok &= (sum == 6);
		}
		d1(10);
		g.assign({ $d2 : 100 });
		g.setValue($d3,1000);
		var d3 = g.getDataWrapper($d3);
		g.unset($d3);
		d3(2000); // this should NOT occur in the log!

		ok &= (log == [ "d3:3","d1:10","d2:100","d3:1000" ]);
		
		{	// test .getIterator()
			var m = new Map;
			foreach(g as var key,var value)
				m[key] = value;
			ok &= (m == { "d1":10, "d2":100 });
		}

		addResult("DataWrapperContainer 1",ok 
					&& g[$d1] == 10 && g[$d2] == 100 
					&& d3() == 2000 && g.getValue($d4,"foo") == "foo");
		g.destroy(); // always destroy a DataWrapperContainer to remove all circling dependecies.
	}

	// --------

	
	{	//Options
		var options = [0,2,4];
		var wrapper1 = DataWrapper.createFromValue(1).setOptions(options);
		var wrapper2 = DataWrapper.createFromValue(2);
		var wrapper3 = DataWrapper.createFromValue(3).setOptionsProvider( fn() { return [get(),get()*2,get()*3 ]; });
		
		options+="Should not influence wrapper1's options.";
		
		addResult("DataWrapperContainer 2",wrapper1.hasOptions() && !wrapper2.hasOptions()  && wrapper3.hasOptions() && 
					wrapper1.getOptions()==[0,2,4] && wrapper2.getOptions()==[] && wrapper3.getOptions()==[3,6,9] );
	}
	
});
// -----------------------------------------------------------------------------------------------
tests += new AutomatedTest( "Util/ExtensionPoint" , fn(){
	var ExtensionPoint = Std.require('LibUtilExt/ExtensionPoint');
	var extensionPoint = new ExtensionPoint;
	extensionPoint.registerExtension( fn(arr){ arr+="foo"; }, Extension.LOW_PRIORITY);
	var bar = fn(arr){ arr+="bar"; };
	extensionPoint += bar; // medium priority
	extensionPoint.registerExtension( fn(arr){ arr+="first"; }, Extension.HIGH_PRIORITY*2.0);
	
	var revoce = new Std.MultiProcedure;
	revoce += extensionPoint.registerExtensionRevocably( fn(arr){ arr+="opt"; }, Extension.HIGH_PRIORITY);
	
	var arr1 = [];
	extensionPoint(arr1);
	addResult("ExtensionPoint 1",arr1 == ["first","opt","bar","foo"]);

	
	extensionPoint -= bar;
	
	revoce();
	var arr2 = [];
	extensionPoint(arr2);
	addResult("ExtensionPoint 2",arr2 == ["first","foo"] && revoce.empty());
	
});
// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/EScript extensions" , fn(){
								
	addResult("Array.slice",
		[ 'a','b','c','d' ].slice(1,2) == ['b','c'] && // starting from #1, with length 2
		[ 'a','b','c','d' ].slice(0,-2) == ['a','b'] && // starting from #0, excluding the last 2 elements
		[ 'a','b','c','d' ].slice(3) == ['d'] && // starting from #3
		[ 'a','b','c','d' ].slice(4) == [] && // starting from #4
		[ 'a','b','c','d' ].slice(-3) == ['b','c','d'] &&// starting 3 elements back from the end
		[ 'a','b','c','d' ].slice(-10,1) == ['a'] );// starting 10 elements back from the end (clamped to 0), with length 1
		
		
	// MultiProcedure
	{
		var f = new Std.MultiProcedure;
		f+="this should not be there";
		f+=fn(result,a){result+=a; };
		f+=fn(result,a){result+=(a+1); };
		f+=10->fn(result,a){result+=(this*a); };
		f+=fn(result,a){result+=true; return MultiProcedure.REMOVE; };
	
		// remove the string
		f.filter(fn(fun){ return !(fun---|>String);});
		
		var fClone = f.clone();
		var result = [];
		var resultClone = [];
		var result2 = [];

		f(result,27);
		fClone(resultClone,27);
		f(result2,27);
		addResult("MultiProcedure 1",result == [27,28,270,true] && result == resultClone && result2 == [27,28,270] );
	}
	{
		
		var o = new ExtObject( {
				$f : new Std.MultiProcedure, 
				$m : 1
		});
		
		o.f += fn(){
			++m;
		};
		o.f();
		addResult("MultiProcedure 2", o.m == 2);
	}
	{	// recursive MultiProcedure-call
		var f = new MultiProcedure;
		var a = [0];
		f+=a -> ([f]=>fn(f,value){
			if(value>0) {
				this[0]+=value;
				f(value-1);
			}
		});
		
		f(10);
		addResult("MultiProcedure 3", a == [10+9+8+7+6+5+4+3+2+1]);
		
//	
	}


	{
		// bind
		var f = fn(a,b){
			var c = this ? this : 0;
			return a+b*10+c*100;
		};
	
		var f1 = f.bindLastParams(7);
		var f2 = f.bindFirstParams(7);
	
		addResult("UserFunction.bind (@deprecated)", f1(4) == 74 && f1.getBoundParams()[0] == 7
						&& f2(4) == 47 && f2.getBoundParams()[0] == 7 );
	}
	{
		// array bind
		var f = fn(a,b){
			var c = this ? this : 0;
			return a+b*10+c*100;
		};
	
	
		addResult("General parameter binding 2", ([7] => f)(4) == 47 );
//						&& f3(4) == 147 && f3.getBoundParams()[0] == 7 );
	}
});

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/Generated comparison functions" , fn(){
	var A = new Type();
	A.member := 0;
	A._constructor ::= fn(Number num){ this.member=num; };
	Traits.addTrait(A,Traits.DefaultComparisonOperatorsTrait,fn(b){return this.member<b.member;});
	
	var result = true;
	
	var a1 = new A(2);
	var a2 = new A(3);
	var a3 = new A(3);
	
	result &=  (a1<a2) && !(a2<a1) &&  (a1<=a2) && !(a2<=a1) && !(a1==a2) &&  (a1!=a2);
	result &= !(a3<a2) && !(a2<a3) &&  (a3<=a2) &&  (a2<=a3) &&  (a3==a2) && !(a3!=a2);
	
	// sub-types are also allowed for comparison
	//! B ---|> A
	var B = new Type(A);
	B._constructor ::= fn()@(super(3)){};
	var b = new B();
	
	result &= b>a1 && b==a3 && !(b<=a1);

	// other types are not allowed!
	var exceptionCaught = false;
	try{
		a1<5;
	}catch(e){
		exceptionCaught = true;
	}
	result &= exceptionCaught;

	return result;
});

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/Listener" , fn(){
	static Listener = Std.require('LibUtilExt/deprecated/Listener');
	var notifier = new Notifier;
	
	var obj =  new ExtObject;
	obj.a := 0;
	notifier.add( "_test" , obj->fn(type,data){
		a += data;
		if( type=="_test" && data == 5 )
			return false;
	});
	for(var i=0;i<10;++i)
		notifier.notify("_test",i);
	return obj.a ==  0+1+2+3+4+5;
});
// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/TypeBasedHandler" , fn(){
	var TypeBasedHandler = Std.require('LibUtilExt/TypeBasedHandler');
	
	var ObjectDescriber = new Type();
	
	ObjectDescriber._constructor ::= fn(String prefix){
		this.prefix := prefix;
	};
	ObjectDescriber.describe ::= new TypeBasedHandler(false); // one (non recursive) type handler for all instances

	ObjectDescriber.describe.addHandler(Object,fn(obj){		return prefix+"(generic object '"+obj.getTypeName()+"')";	});
	ObjectDescriber.describe.addHandler(Number,fn(Number s){	return prefix+"(Number "+s+")"; });
	ObjectDescriber.describe.addHandler(Collection,fn(Collection c){
		var s=prefix+"(Collection"; // use the prefix here to assure that we use the right object.
		foreach(c as var value){
			s+=" "+describe(value);
		}
		return s+")";
	});	
	ObjectDescriber.describe += [String,fn(String s){	return prefix+"(String '"+s+"')"; }];
	
	// -----
	
	ObjectDescriber.describe_r ::= new TypeBasedHandler(true); // one (recursive) type handler for all instances
	
	// first handler for 'Collection'
	ObjectDescriber.describe_r += [Collection,fn(Collection c, Array result){
		result += "Collection";
	}];	
	// second handler for 'Collection'
	ObjectDescriber.describe_r += [Collection,fn(Collection c, Array result){
		result += "Size:" +c.count();
	}];	
	ObjectDescriber.describe_r += [Array,fn(Array a, Array result){
		result += "Maximum:" +a.max();
	}];

		
	// -----
		
	var d = new ObjectDescriber("d");

	// -----
	
	addResult("Simple polymorphism (non recursive)",
		d.describe([1,2,3]) == "d(Collection d(Number 1) d(Number 2) d(Number 3))" &&
		d.describe("foo") == "d(String 'foo')" &&
		d.describe(4) == "d(Number 4)" &&
		d.describe(void) == "d(generic object 'Void')"
	);

	// -----

	var	r1=[];
	d.describe_r([1,2,3],r1);
	
	var r2=[];
	d.describe_r({1:"foo",2:"bar"},r2);

	addResult("Recursive handling",
		r1.implode(",") == "Collection,Size:3,Maximum:3" &&
		r2.implode(",") == "Collection,Size:2"
	);


	// -----
	var exceptionCaught = false;
	try{
		d.describe_r("foo");
	}catch(e){
		exceptionCaught = true;
	}
	addResult("Exception on unknown type",exceptionCaught);
});


// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Util/XML" , fn(){
	static XML_Utils = Std.require('LibUtilExt/XML_Utils');
	
	var tmpDir = new Util.TemporaryDirectory("TestsUtil");
	var filename1 = tmpDir.getPath()+"test1.xml";
	var filename2 = tmpDir.getPath()+"test2.xml";
	
	Util.saveFile(filename1,
		'<?xml version="1.0"?>\n'+
		'<scene>\n'+
		'<attribute name="tags" type="json" >  foo  </attribute>\n'+
		'<attribute name="thing" value="bar" />\n'+
		'</scene>',true
	);
	var m1 = XML_Utils.loadXML(filename1);
//	print_r(m1);
	
	// \todo Re-enable when #448 is fixed!
	addResult("loadXML", (m1 == {
		XML_Utils.XML_NAME : "scene",
		XML_Utils.XML_ATTRIBUTES : new Map(),
		XML_Utils.XML_CHILDREN : [{
			XML_Utils.XML_NAME : "attribute",
			XML_Utils.XML_ATTRIBUTES : {	"name" : "tags", "type" : "json" },
			XML_Utils.XML_DATA : "foo"
		},{
			XML_Utils.XML_NAME : "attribute",
			XML_Utils.XML_ATTRIBUTES : {	"name" : "thing", "value" : "bar" }
		}]
	}));
	
	XML_Utils.saveXML(filename2,m1);
	addResult("saveXML", XML_Utils.loadXML(filename2) == m1);
	
//	out(XML_Utils.generateXML(m));
//	return result;
});

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest("Util/UpdatableHeap", fn() {
	var heap = new Util.UpdatableHeap();
	var numElements = 1000;
	
	var elements = [];
	for(var key = 1; key <= numElements; ++key) {
		var element = heap.insert(key, key.toString());
		if(heap.size() != key) {
			return false;
		}
		if(element.getCost() != key) {
			return false;
		}
		if(element.data() != key.toString()) {
			return false;
		}
		elements += element;
	}
	
	for(var key = 1; key <= numElements; ++key) {
		heap.update(elements[key - 1], numElements - (key - 1));
		if(heap.size() != numElements) {
			return false;
		}
	}
	
	var keyControl = 1;
	while(heap.size() > 0) {
		var topElement = heap.top();
		if(topElement.getCost() != keyControl) {
			return false;
		}
		var dataControl = (numElements - (keyControl - 1)).toString();
		if(topElement.data() != dataControl) {
			return false;
		}
		heap.pop();
		++keyControl;
	}
	
	return true;
});


// ---------------------------------------------------------
return tests;
