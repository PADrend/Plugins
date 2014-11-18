/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tests] Tests/AutomatedTests/ObjectSerialization.escript
 **/

var AutomatedTest = Std.require('Tests/AutomatedTest');

var tests = [];

// ---

// basic Object Serialization
tests += new AutomatedTest( "LibUtilExt/ObjectSerialization" , fn(){
	loadOnce("LibUtilExt/CommonSerializers.escript");
	
	{
		var ok = true;
		var ctxt = new ObjectSerialization.Context;
		foreach( ["foo", 2,	void,false,true,[1,2,3],{"a":[1,2,3],"b":false},$ident,
				new Geometry.Vec3(1,2,3),new Geometry.Box(new Geometry.Vec3(-1,0,127),1,2,3)
				] as var obj ){
			var s = ctxt.serialize( obj );
			var obj2 = ctxt.createFromString( s );
			if(! (obj==obj2)  ){
				Runtime.warn("Error in serialization of "+obj.toString());
				ok=false;
			}
		}
		var a=new ExtObject( {$foo:"bar",$bla:[1,2,3]});
		var b=new ExtObject( {$a1:a , $a2:a });
		// using the same context, the original objects should be returned if they are tracked.
		var serialB = ctxt.serialize( b );
		var b2 = ctxt.createFromString( serialB );
		if( b2!=b || b2.a1!=b2.a2 || a!=b2.a1){
			Runtime.warn("Error in serialization of ExtObject");
			ok=false;
		}
		var ctxt2 = new ObjectSerialization.Context;
		// using different contexts, new objects should be created -- even if they are tracked.
		var b3 = ctxt2.createFromString( serialB );
		if( b3==b || b3.a1!=b3.a2 || a==b3.a1){
			Runtime.warn("Error in serialization of ExtObject using different contexts");
			ok=false;
		}
		addResult("ObjectSerialization 1",ok);
	}
	// hierarchical objects
	{
		var ok = true;
		var c = new ExtObject;
		var p = new ExtObject( {$child:c });
		c.myParent := p;
		
		var ctxt = new ObjectSerialization.Context;
		var serialP = ctxt.serialize(p);

		var ctxt2 = new ObjectSerialization.Context;
		var p2 = ctxt2.createFromString(serialP);
		if(! p2.child.myParent==p2 ){
			Runtime.warn("Error in serialization of hierarchical ExtObjects");
			ok=false;
		}
		addResult("ObjectSerialization 2",ok);
	}

	//  example from the header
	{
		var ok = true;
		var mySerializedObject;
		{
			var dataObject = new ExtObject( { $data : 1 } );
			var someObject = new ExtObject( { $pos : new Geometry.Vec3(1,0,0) ,$data1 : dataObject, $data2 : dataObject } );
		
			var ctxt = new ObjectSerialization.Context;
			mySerializedObject = ctxt.serialize(someObject);
		}

		{
			var ctxt = new ObjectSerialization.Context;
			var someObject = ctxt.createFromString(mySerializedObject);
			
			if(! ( someObject.pos---|> Geometry.Vec3 && someObject.data1 == someObject.data2)){
				Runtime.warn("Error in example");
				ok=false;
			}
		}
		addResult("ObjectSerialization 3",ok);
	}

	// UserFunction and Delagate serialization
	{
		var ok = true;
		var f1=fn(){	return 1;	};
		var d1=[2]->fn(a){	return this[0]+a;	};
		var fWithMembers = fn(){return thisFn.m1; };
		fWithMembers.m1 := "foo";
		fWithMembers.__ignored := "bar";
		
		var s_f1 = (new ObjectSerialization.Context).serialize(f1);
		var s_d1 = (new ObjectSerialization.Context).serialize(d1);
		var s_fWithMembers1 = (new ObjectSerialization.Context).serialize(fWithMembers);

		var f2 = (new ObjectSerialization.Context).createFromString(s_f1);
		var d2 = (new ObjectSerialization.Context).createFromString(s_d1);
		var fWithMembers2 = (new ObjectSerialization.Context).createFromString(s_fWithMembers1);
	
		if(! ( f1() == f2() 
				&& d1(3) == d2(3)
				&& fWithMembers2() == "foo") && !fWithMembers2.isSet($__ignored)){
			Runtime.warn("Error in example");
			ok=false;
		}
		addResult("ObjectSerialization 4",ok);
	}

	// use several TypeRegistries for the same Type
	{
		var ok = true;
		var STest = new Type;
		STest.foo := 0;
		STest._constructor ::= fn( _foo){ foo = _foo;};
		
		var reg1 = new ObjectSerialization.TypeRegistry(ObjectSerialization.defaultRegistry);
		var reg2 = new ObjectSerialization.TypeRegistry(reg1); // use reg1 as base registry. 
		var reg3 = new ObjectSerialization.TypeRegistry(ObjectSerialization.defaultRegistry); 

		reg1.registerType(STest,"STest")
				.addDescriber(fn(ctxt,obj,Map d){	d['foo'] = obj.foo;	})
				.setFactory(fn(ctxt,Type actualType,Map d){		return new actualType(d['foo']);	});

		reg2.registerType(STest,"STest")
				.enableIdentityTracking()
				.addDescriber(fn(ctxt,obj,Map d){	d['bar'] = obj.foo;	})
				.setFactory(fn(ctxt,Type actualType,Map d){		return new actualType(d['bar']);	});

		reg3.registerType(STest,"STest")
				.initFrom(reg1.getTypeHandler(STest)) // copy everything from reg1
				.addDescriber(fn(ctxt,obj,Map d){	d['test'] = 42;	}) // add some data
				.addInitializer(fn(ctxt,obj,Map d){	obj.test := d['test'];	}) ;

		var s1=new STest(17);
		
		var ctxt1 = new ObjectSerialization.Context(reg1);
		var desc1 = ctxt1.createDescription(s1);

		var ctxt2 = new ObjectSerialization.Context(reg2);
		var desc2 = ctxt2.createDescription(s1);
		
		var desc3 = (new ObjectSerialization.Context(reg3)).createDescription(s1);

		var restore1 = ctxt1.createObject(desc1);
		var restore2 = ctxt2.createObject(desc2);
		var restore3 = (new ObjectSerialization.Context(reg3)).createObject(desc3);
	
		if( !(desc1=={"##TYPE##":"STest","foo":17} && // no tracking, member foo stored in 'foo'
				restore1 != s1 && // no tracking inside the context ---> a new object is created
				restore1.foo == 17 &&
				restore1 ---|> STest &&
				desc2["##ID##"] && desc2["bar"]==17 && // tracking,  member foo stored in 'bar'
				restore2 == s1 && // tracking inside the context ---> so the object itself is returned
				restore2 ---|> STest &&
				desc3=={"##TYPE##":"STest","foo":17,"test":42} && // like desc1 + additional data
				restore3.test == 42 && restore3.foo == 17 && // like desc1 + additional data
				!ObjectSerialization.defaultRegistry.getTypeHandler("STest"))){ // original defaultRegistry is not altered
			print_r(desc1);
			print_r(desc2);
			print_r(desc3);
			Runtime.warn("Error in example");
			ok=false;
		}
		addResult("ObjectSerialization 5",ok);
//		out(ctxt2.createObject(desc2));
	}
	/*{// ------------------------------------------------------------------------------ EXPERIMENTAL
		static Context = ObjectSerialization.Context;
		static TraitHandler;
		{
			var T = TraitHandler = new Type;
			T._printableName @(override) ::= $TraitHandler;

			T.trait @(private) := void;
			T.traitName @(private) := "";

			//! (ctor)
			T._constructor ::= 	fn(Std.Traits.Trait _trait,[String,void] _name=void){
				this.trait = _trait;
				this.traitName = _name ? _name:_trait.getName();
			};
			//! ---o
			T.describeTrait ::= fn(Context ctxt,obj,Map description){	Runtime.exception("This method is not implemented.");	};	//Std.ABSTRACT_METHOD();
			//! ---o
			T.initTrait ::= 		fn(Context ctxt,obj,Map description){	Runtime.exception("This method is not implemented.");	};//Std.ABSTRACT_METHOD();
			T.getHandledTrait ::= 			fn(){	return this.trait;};
			T.getHandledTraitName ::= 		fn(){	return this.traitName;};
		}

		// ------------
		static GenericTraitHandler;
		//! GenericTraitHandler ---|> TraitHandler
		{
			var T = GenericTraitHandler = new Type(TraitHandler);
			T._printableName @(override) ::= $GenericTraitHandler;


			T.addInitializer ::=			fn(fun){	doInitializeTrait += fun;	return this;	};
			T.addDescriber ::=				fn(fun){	doDescribeTrait += fun;		return this;	};

			//! ---|> TypeHandler
			T.describeTrait @(override) ::= fn(Context ctxt,obj, Map description){
				Std.Traits.assureTrait( obj, this.trait);
				var arr = description['##TRAITS##'];
				if(!arr){
					arr = [];
					description['##TRAITS##'] = arr;
				}
				arr += this.traitName;
				this.doDescribeTrait(ctxt,obj,description);
				return description;
			};

			//! ---|> TypeHandler
			T.initTrait @(override) ::= 		fn(Context ctxt,obj,Map description){
				Std.Traits.assureTrait( obj, this.trait);
				this.doInitializeTrait(ctxt,obj,description);
				return obj;
			};

			T.doInitializeTrait @(private,init) := Std.MultiProcedure;
			T.doDescribeTrait @(private,init) := Std.MultiProcedure;


			T.getDescribers  ::= 			fn(){	return this.doDescribeTrait;	};
			T.getInitializers  ::= 			fn(){	return this.doInitializeTrait;	};
		}
	
		{ // extend TypeRegistry
			static T = ObjectSerialization.TypeRegistry;
//			T.registeredTraits @(init,private) := Map; // registeredName -> Trait
			
			T.registerTrait ::= fn(Std.Traits.Trait trait, [void,String] traitName=void){
				if(!this.isSet($registeredTraits))
					this.registeredTraits := new Map; // TEMP!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				var handler = new GenericTraitHandler(trait,traitName);
				this.registerTraitHandler(handler);
				return handler;
			};
			//! (internal)
			T.registerTraitHandler ::= fn(TraitHandler traitHandler){
				this.registeredTraits[ traitHandler.getHandledTraitName() ] = traitHandler;
				this.registeredTraits[ traitHandler.getHandledTrait().toString() ] = traitHandler;
		//		outln("Registering: ",traitHandler.getHandledTypeName()," : ",traitHandler.getHandledType().toString()," : ",traitHandler);
			};

			T.getTraitHandler ::= fn([String,Std.Traits.Trait] nameOrTrait){
				if(!this.isSet($registeredTraits))
					this.registeredTraits := new Map; // TEMP!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				var handler = this.registeredTraits[nameOrTrait];
				return (!handler && this.baseRegistry) ? this.baseRegistry.getTraitHandler(nameOrTrait) : handler;
			};
		}
		{// extend Context
			var T = ObjectSerialization.Context;
			static original = T.createDescription;
			
			T.createDescription ::= fn(obj){
				var d = (this->original)(obj);
				var traits = Std.Traits.queryTraits(obj);
//				print_r(traits);
				foreach(traits as var trait){
					var handler = this.typeRegistry.getTraitHandler( trait );
					if(handler)
						handler.describeTrait(this,obj,d);
				}
				return d;
			};

			static originalCreate = T.createObject;
			T.createObject ::= fn(description){
				var obj = (this->originalCreate)(description);
				if(description.isA(Map)&& description['##TRAITS##'] ){
					foreach( description['##TRAITS##'] as var traitId){
						outln("Adding ",traitId," to ",obj);
						this.typeRegistry.getTraitHandler(traitId).initTrait(this,obj,description);// handle not found!!!!!!!!!!!!!!!!!!!!
					}
				}
				return obj;
			};
		}
	//---------
		var STest = new Type;
		STest.foo := 0;
		STest._constructor ::= fn( _foo){ this.foo = _foo;};

		var t = new Std.Traits.GenericTrait( 'TestTrait' );
		t.attributes.bar @(init) := Array;
		
		var reg = new ObjectSerialization.TypeRegistry(ObjectSerialization.defaultRegistry);
		reg.registerType(STest,"STest")
				.addDescriber(fn(ctxt,obj,Map d){	d['foo'] = obj.foo;	})
				.setFactory(fn(ctxt,Type actualType,Map d){		return new actualType(d['foo']);	});

		reg.registerTrait(t)
				.addDescriber(fn(ctxt,obj,Map d){		d['testTrait_bar'] = obj.bar;	})
				.addInitializer(fn(ctxt,obj,Map d){		obj.bar.append( ctxt.createObject(d['testTrait_bar']));	});

		var obj1 = new STest("FOO");
		Std.Traits.addTrait(obj1,t);
		obj1.bar += "BAR";

		var ctxt = new ObjectSerialization.Context(reg);
		var s = ctxt.createDescription(obj1) ;
		print_r( ctxt.createDescription(obj1) );
		
		var obj2 = ctxt.createObject(s);
		print_r(obj2,obj2.foo,obj2.bar);
	}*/
});

// ---------------------------------------------------------
return tests;
