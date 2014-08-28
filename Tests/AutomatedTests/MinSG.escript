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
 **	[Plugin:Tests] Tests/AutomatedTests/MinSG.escript
 **/

loadOnce(__DIR__+"/../AutomatedTest.escript");

var tests = [];

// -----------------------------------------------------------------------------------------------

tests += new Tests.AutomatedTest( "[BUG20130903] MinSG BB bug.",fn(){
	var root = new MinSG.ListNode;
	
	
	var n1 = new MinSG.ListNode;
	root += n1;
	
	
	var box = new Geometry.Box(new Geometry.Vec3(10,100,1000),4,17,27);
	var mb = new Rendering.MeshBuilder;
	mb.addBox(box);
	
	var gn = new MinSG.GeometryNode(mb.buildMesh());
	n1 += gn;
	
	addResult( "a1", root.getBB() == box && n1.getBB() == box && gn.getBB() == box );
	
	var box2 = box.clone();
	
	box2.translate(new Geometry.Vec3(1,2,3));
	gn.moveRel(new Geometry.Vec3(1,2,3));

	addResult( "a2", root.getBB() == box2 && n1.getBB() == box2 && gn.getBB() == box );
	
});


// -----------------------------------------------------------------------------------------------

// the camera's frustum should be automatically updated using a transformation listener. 
tests += new Tests.AutomatedTest( "Automatic camera frustum update",fn(){
	var camera = new MinSG.CameraNode;
	var f1 = camera.getFrustum();
	camera.moveLocal(0,1,0);
	var f2 = camera.getFrustum();

//	out(f1.getPos(),f2.getPos());
	return f1.getPos()!=f2.getPos();
});
// -----------------------------------------------------------------------------------------------

// the camera's frustum should be automatically updated using a transformation listener. 
tests += new Tests.AutomatedTest( "MinSG: NodeAttributes",fn(){
	var n = new MinSG.ListNode;
	n.setNodeAttribute("a1",42);
	n.a2 := 27;
	n += new MinSG.ListNode;
	MinSG.getChildNodes(n)[0].setNodeAttribute("b1",100);
	MinSG.getChildNodes(n)[0].b2 := 1000;
	MinSG.getChildNodes(n)[0].setNodeAttribute("$cI$b3","foo");  // don't clone but copy to instances
	
	
	var nClone = n.clone();
	var nInstance = MinSG.Node.createInstance(n);
	nInstance.setNodeAttribute("a3",17);
	var nInstanceInstance = MinSG.Node.createInstance(nInstance);
	
	addResult( "a1",	n.getNodeAttribute("a1") == 42 && n.isSet($a2) && n.a2 == 27 );
	addResult( "a2",	nClone.getNodeAttribute("a1") == 42 &&	!nClone.isSet($a2) );
	addResult( "a3",	!nInstance.getNodeAttribute("a1") && nInstance.findNodeAttribute("a1") == 42 && !nInstance.isSet($a2) );
	addResult( "a4",	nInstanceInstance.getNodeAttribute("a3") == 17 );


	addResult( "b1",	MinSG.getChildNodes(n)[0].getNodeAttribute("b1") == 100 && 
						MinSG.getChildNodes(n)[0].b2 == 1000 && 
						MinSG.getChildNodes(n)[0].getNodeAttribute("$cI$b3") == "foo"  );
	addResult( "b2",	MinSG.getChildNodes(nClone)[0].getNodeAttribute("b1") == 100 && 
						!MinSG.getChildNodes(nClone)[0].isSet($b2) && 
						!MinSG.getChildNodes(nClone)[0].getNodeAttribute("$cI$b3") );
	addResult( "b3",	!MinSG.getChildNodes(nInstance)[0].getNodeAttribute("b1") && 
						!MinSG.getChildNodes(nInstance)[0].isSet($b2) && 
						MinSG.getChildNodes(nInstance)[0].getNodeAttribute("$cI$b3") == "foo" );
});

// -----------------------------------------------------------------------------------------------

tests += new Tests.AutomatedTest( "MinSG: tree observer",fn(){
	var added = [];
	var removed = [];
	var moved = [];

	var root = new MinSG.ListNode;
	Traits.addTrait(root,MinSG.NodeAddedObserverTrait, added->added.pushBack ); //! \see MinSG.NodeAddedObserverTrait
	Traits.addTrait(root,MinSG.TransformationObserverTrait, moved->moved.pushBack ); //! \see MinSG.TransformationObserverTrait
	Traits.addTrait(root,MinSG.NodeRemovedObserverTrait, [removed]=>fn(removed,parent,node){removed+=[parent,node,node.isDestroyed()];} ); //! \see MinSG.NodeRemovedObserverTrait

	var c1 = new MinSG.ListNode;
	root += c1;
	
	var g1 = new MinSG.GeometryNode;
	c1 += g1;

	var g2 = new MinSG.GeometryNode;
	c1 += g2;

	g2.moveLocal(new Geometry.Vec3(1,1,1));
	
	MinSG.destroy(g2);
	root -= c1;
	
	addResult( "Translation", moved == [g2] );
	addResult( "NodeAdded", added == [c1,g1,g2] );
	addResult( "NodeRemoved", removed == [ 
			[c1,g2,true ], // g2 has been removed from c1 and was destroyed
			[root,c1,false]] ); // c1 has been removed from root
//	print_r(removed);
});


// -----------------------------------------------------------------------------------------------

tests += new Tests.AutomatedTest( "MinSG: create/load/save scenes",fn(){

	var tmpDir = new Util.TemporaryDirectory("TestsMinSG");
	var filename = tmpDir.getPath()+"tmp_"+time().toIntStr();
	
	var randomPos;

	var sceneString = "";
	// create and save a scene
	{
		var sceneManager = new MinSG.SceneManager;
		var root = new MinSG.ListNode;
		root.setNodeAttribute("WurzelTag",true);
		sceneManager.registerNode("WurzelId",root);
		
		// add some transformed nodes (only use int values to ignore floating point issues)
		var parentNode = root;
		for(var i=0;i<4;++i){
			var n = new MinSG.ListNode();
			n.moveLocal(new Geometry.Vec3(Rand.equilikely(0,5),Rand.equilikely(0,5),Rand.equilikely(0,5)));
			n.rotateLocal_deg(Rand.equilikely(0,4)*90.0,new Geometry.Vec3(1,0,0));
			n.scale(Rand.equilikely(1,4));
			parentNode.addChild(n);
			parentNode = n;
			
			randomPos = n.getWorldOrigin();
			sceneManager.registerNode("lastRandomNode",n);
		}
		
		{ // add a prototype that is not directly stored in the scene and two instances
			var prototype = new MinSG.ListNode();
			prototype.addState( new MinSG.BlendingState());
			sceneManager.registerNode("prototype",prototype);
			var prototypeContainer = new MinSG.ListNode();
			root.addChild(prototypeContainer);
			sceneManager.registerNode("prototypeContainer",prototypeContainer);
			prototypeContainer.addChild(sceneManager.createInstance("prototype"));
			prototypeContainer.addChild(sceneManager.createInstance("prototype"));
		}
		{	// add temporary node (should NOT be saved)
			var tempNode = new MinSG.ListNode;
			tempNode.setTempNode(true);
			sceneManager.registerNode("tempNode",tempNode);
			root += tempNode;
			
		}
		
		{	// add some states
			var stateContainer = new MinSG.ListNode;
			root.addChild(stateContainer);
			
			// AlphaTestState
			var s = new MinSG.AlphaTestState;
			var alphaTestParams = s.getParameters();
			alphaTestParams.setMode(Rendering.Comparison.GREATER);
			alphaTestParams.setReferenceValue(0.27);
			s.setParameters(alphaTestParams);
			sceneManager.registerState("AlphaTestState",s);
			stateContainer.addState(s);
			
			// BlendingState
			s = new MinSG.BlendingState;
			s.setBlendEquation(Rendering.BlendEquation.FUNC_SUBTRACT);
			s.setBlendFuncSrc(Rendering.BlendFunc.ZERO);
			s.setBlendFuncDst(Rendering.BlendFunc.ONE);
			s.setBlendConstAlpha(0.17);
			s.setBlendDepthMask(false);
			sceneManager.registerState("BlendingState",s);
			stateContainer.addState(s);

			// BudgetAnnotationState
			{
				var bas = new MinSG.BudgetAnnotationState;
				bas.setAnnotationAttribute("FirstAttribute");
				bas.setBudget(123.456);
				bas.setDistributionType(MinSG.BudgetAnnotationState.DISTRIBUTE_PROJECTED_SIZE);
				sceneManager.registerState("BudgetAnnotationState1", bas);
				stateContainer.addState(bas);
			}
			{
				var bas = new MinSG.BudgetAnnotationState;
				bas.setAnnotationAttribute("SecondAttribute");
				bas.setBudget(987.654);
				bas.setDistributionType(MinSG.BudgetAnnotationState.DISTRIBUTE_EVEN);
				sceneManager.registerState("BudgetAnnotationState2", bas);
				stateContainer.addState(bas);
			}

			// INSERT MORE STATES HERE!
		}
		{	// add some nodes
			// INSERT MORE NODE TESTS HERE!
			
		}
		
		// save scene
		sceneManager.saveMinSGFile(filename + ".minsg",[root]);

		sceneString = sceneManager.saveMinSGString([root]);
		// cleanup
		MinSG.destroy(root);
	}

	// re-load scene, check properties and save again
	{
		var sceneManager = new MinSG.SceneManager();
		var root = sceneManager.loadScene(filename + ".minsg");
		var a = MinSG.collectNodesWithAttribute(root,"WurzelTag");
		addResult( "tag test", a.count()==1 && sceneManager.getRegisteredNode("WurzelId") == a[0]);
		
		// check transformations
		var pos = sceneManager.getRegisteredNode("lastRandomNode").getWorldOrigin();
		addResult( "transformations",  pos.getX().round(0.1) ~= randomPos.getX().round(0.1) && pos.getY().round(0.1) ~= randomPos.getY().round(0.1) && pos.getZ().round(0.1) ~= randomPos.getZ().round(0.1) );
		
		// check instances
		var prototypeContainer = sceneManager.getRegisteredNode("prototypeContainer");
		var instances=MinSG.getChildNodes(prototypeContainer);
		var state1 = instances[0].getStates()[0]; // should be a blending state
		var state2 = instances[1].getStates()[0]; // should be a blending state
		addResult( "node instancing", instances.count()==2 && state1==state2);
		
		// check missing tempNode
		addResult( "TempNode", !sceneManager.getRegisteredNode("tempNode"));
		
		// AlphaTestState
		var s = sceneManager.getRegisteredState("AlphaTestState");
		addResult( "AlphaTestState", s.getParameters().getMode() == Rendering.Comparison.GREATER && s.getParameters().getReferenceValue()~=0.27);
		
		// BlendingState
		s = sceneManager.getRegisteredState("BlendingState");
		addResult( "BlendingState", s.getBlendEquation() == Rendering.BlendEquation.FUNC_SUBTRACT && 
					s.getBlendFuncSrc()==Rendering.BlendFunc.ZERO && 
					s.getBlendFuncDst()==Rendering.BlendFunc.ONE && 
					s.getBlendConstAlpha()~=0.17 && !s.getBlendDepthMask());

		// BudgetAnnotationState
		s = sceneManager.getRegisteredState("BudgetAnnotationState1");
		addResult("BudgetAnnotationState 1/2", 
					s.getAnnotationAttribute() == "FirstAttribute" &&
					s.getBudget() == 123.456 && 
					s.getDistributionType() == MinSG.BudgetAnnotationState.DISTRIBUTE_PROJECTED_SIZE);
		s = sceneManager.getRegisteredState("BudgetAnnotationState2");
		addResult("BudgetAnnotationState 2/2", 
					s.getAnnotationAttribute() == "SecondAttribute" &&
					s.getBudget() == 987.654 && 
					s.getDistributionType() == MinSG.BudgetAnnotationState.DISTRIBUTE_EVEN);

		// save again
		sceneManager.saveMinSGFile(filename + "b.minsg",[root]);
		// cleanup
		MinSG.destroy(root);
	}
	addResult("identical files (save/load/save)", Util.loadFile(filename + ".minsg")==Util.loadFile(filename + "b.minsg"));

	// scene saving to/loading from string
	{
		addResult("save scene to string", !sceneString.empty());

		var importContext = PADrend.getSceneManager().createImportContext();
		var nodes = PADrend.getSceneManager().loadMinSGString(importContext, sceneString);
		addResult("load scene from string", nodes && !nodes.empty());

		var newSceneString = PADrend.getSceneManager().saveMinSGString(nodes);
		addResult("identical strings (save/load/save)", sceneString == newSceneString);
	}

});



tests += new Tests.AutomatedTest( "MinSG: NodeQuery",fn(){
	Std._unregisterModule('LibMinSGExt/TreeQuery'); // force reload
	
	var TQuery = Std.require('LibMinSGExt/TreeQuery');
	var sm = new MinSG.SceneManager;
	
	{
		var ok = true;
		// primitive value
		ok &= TQuery.execute("5",sm) == 5;
		// function call with operator
		ok &= TQuery.execute("40+2",sm) == 42;
		// variable and comment
		ok &= TQuery.execute("(: variable :)'foo' + $dum",sm,void,{"dum":"bar"}) == "foobar";
		
		ok &= TQuery.execute("test:exampleSet",sm) == new Set([1,2,3,4,5,6]);
		ok &= TQuery.execute("(: external input :)test:inc",sm,[0,2,4]) == new Set([1,3,5]);
		ok &= TQuery.execute("(: parameter input :)test:inc(test:exampleSet)",sm) == new Set([2,3,4,5,6,7]);
		ok &= TQuery.execute("(: forwarded input :)test:exampleSet/test:inc",sm) == new Set([2,3,4,5,6,7]);
		ok &= TQuery.execute("test:exampleSet/test:modFilter($v)",sm,void,{"v":3}) == new Set([3,6]);
		ok &= TQuery.execute("test:exampleSet/(test:modFilter(2)|test:modFilter(3))",sm) == new Set([2,3,4,6]);
		
		
		var q = TQuery.parse("17");
		var ctxt = TQuery.createContext(sm);
		ok &= q(ctxt) == 17;
		
		addResult("generic queries",ok);
		
	}

	{	// MinSG.Node query
		
		var ok = true;
		
		var sceneManager = new MinSG.SceneManager;

		/*
					root
		         /         \
				l0(foo)     l1(bar)
							|
							l10
							| 
							g100
		
		*/


		var root = new MinSG.ListNode;
		outln("Root:",root);
		var l0 = new MinSG.ListNode;
		root += l0;
		var l1 = new MinSG.ListNode;
		root += l1;
		var l10 = new MinSG.ListNode;
		l1 += l10;
		var g100 = new MinSG.GeometryNode;
		l10 += g100;

		sm.registerNode('foo',l0);
		sm.registerNode('bar',l1);
		l10.setNodeAttribute('name',"dum");
		l1.setNodeAttribute('name',"di");
		
		var tagFunctions = Std.require('LibMinSGExt/NodeTagFunctions');
		tagFunctions.addTag(g100,"tag1");
		tagFunctions.addTag(l0,"tag1");
		
		ok &= TQuery.execute(".", sm, [root,l1] ) == new Set([root,l1]);
		ok &= TQuery.execute("/child", sm, [root,root]) == new Set([l0,l1]);
		ok &= TQuery.execute("/", sm, [l1])== new Set([root]);
		ok &= TQuery.execute("./ancestor", sm, [g100])== new Set([l10,l1,root]);
		ok &= TQuery.execute("ancestor-or-self", sm, [g100])== new Set([g100,l10,l1,root]);
		ok &= TQuery.execute("/MinSG:collectListNodes/MinSG:nAttrFilter('name')", sm, [root])== new Set([l10,l1]);
		ok &= TQuery.execute("MinSG:collectGeometryNodes", sm, [root])== new Set([g100]);
		ok &= TQuery.execute("MinSG:id('foo')", sm)== new Set([l0]);
		ok &= TQuery.execute("MinSG:id($foo)", sm,void,{"foo":"bar"})== new Set([l1]);
		ok &= TQuery.execute("(.)", sm, [root,l1] ) == new Set([root,l1]);
		ok &= TQuery.execute("./MinSG:collectRefId('foo')", sm, [root] ) == new Set([l0]);
		ok &= TQuery.execute("/MinSG:collectRefId('foo')", sm, [g100] ) == new Set([l0]);
		ok &= TQuery.execute("./../../..", sm, [g100] ) == new Set([root]);
		ok &= TQuery.execute("./MinSG:collectByTag('tag1')", sm, [root] ) == new Set([g100,l0]);
		
		// ----------------------
		// semantic objects
		var SemObjTools = Std.require('LibMinSGExt/SemanticObject');
		SemObjTools.markAsSemanticObject(root);
		SemObjTools.markAsSemanticObject(l1);
		ok &= TQuery.execute("./MinSG:containingSemObj", sm, [l10] ) == new Set([l1]);
		ok &= TQuery.execute("./MinSG:containingSemObj", sm, [l1] ) == new Set([root]);
		ok &= TQuery.execute("./MinSG:containingSemObj/MinSG:containingSemObj", sm, [g100] ) == new Set([root]);
		ok &= TQuery.execute("./MinSG:containingSemObj/MinSG:containingSemObj/MinSG:collectRefId('foo')", sm, [g100] ) == new Set([l0]);
		ok &= TQuery.execute("./MinSG:containingSemObj", sm, [g100] ) == new Set([l1]);

		
		// relative node queries
		foreach([ [l0,l0], [l1,l10],[g100,l10],[g100,l1],[g100,root],[g100,l0],[root,l0]
				 ] as var sourceTarget){
			var query = TQuery.createRelativeNodeQuery(sm, sourceTarget[0], sourceTarget[1]);
//			outln( "Query:", query );
			ok &= TQuery.execute(query,sm,[sourceTarget[0]]) == new Set([sourceTarget[1]]);
		}
		
		
		addResult("MinSG.TreeQuery" , ok);
		
	}
});

// -----------------------------------------------------------------------------------------------

tests += new Tests.AutomatedTest( "LibMinSGExt/NodeTagFunctions",fn(){
	Std._unregisterModule('LibMinSGExt/NodeTagFunctions'); // force reload
	

	var tagFunctions = Std.require('LibMinSGExt/NodeTagFunctions');
	// instance
	var sm = new MinSG.SceneManager;
	var root = new MinSG.ListNode;
	tagFunctions.addTag(root,"root");
	
	var n1 = new MinSG.GeometryNode;
	root += n1;
	sm.registerNode('n1',n1);
	tagFunctions.addTag(n1,"tag1");
	tagFunctions.addTag(n1,"tag2");
	
	var i1 = sm.createInstance("n1");
	root += i1;
	tagFunctions.addTag(i1,"tag3");
	
	var ok = true;
	var nodesToTags = tagFunctions.collectTaggedNodes(root);
	ok &= nodesToTags[root] == ["root"];
	ok &= nodesToTags[n1].sort() == ["tag1","tag2"];
	ok &= nodesToTags[i1].sort() == ["tag1","tag2","tag3"];
	
	var nodes = tagFunctions.collectNodesByTag(root,"tag1");
	ok &= nodes.contains(n1) && nodes.contains(i1);
	
	ok &= tagFunctions.getLocalTags(i1) == ["tag3"];
	
	tagFunctions.removeLocalTag(n1,"tag1");
	ok &= tagFunctions.getTags(n1) == ["tag2"] && tagFunctions.getTags(i1).sort() == ["tag2","tag3"];

	tagFunctions.clearLocalTags(n1);
	ok &= tagFunctions.getTags(n1) == [] && tagFunctions.getTags(i1).sort() == ["tag3"];

	return ok;
});
// -----------------------------------------------------------------------------------------------

tests += new Tests.AutomatedTest( "MinSG: Persistent node traits",fn(){
	var root = new MinSG.ListNode;
	declareNamespace($MinSG,$_Test);
	
	var traitName = 'MinSG/_Test/PersistentNodeTestTrait';
	var t = new MinSG.PersistentNodeTrait(traitName);
	Std._unregisterModule(traitName);
	Std._registerModule(traitName,t);
	
	t.initCounter := 0;
	
	t.attributes.foo @(init) := fn(){	return "bar";	};
	t.attributes.m0 := 0;
	t.onInit += fn(node){
		node.m1 := 2;
		++node.m0;
		
		++this.initCounter;
	};
	var n1 = new MinSG.ListNode;
	Traits.addTrait(n1,t); // manually add to n1 (normal trait behavior)

	root += n1;
	var n2 = MinSG.Node.createInstance(n1); // trait is not yet initialized
	root += n2;

	MinSG.initPersistentNodeTraits(root); // trait of n1 is not touched; n2 is initialized.

	return	t.initCounter == 2 && 
			n1.foo == "bar" && n1.m0 == 1 && n1.m1 == 2 &&
			n2.foo == "bar" && n2.m0 == 1 && n2.m1 == 2 &&
			MinSG.getLocalPersistentNodeTraitNames(n1) == [t.getName()] &&
			MinSG.getLocalPersistentNodeTraitNames(n2) == [] && MinSG.getPersistentNodeTraitNames(n2) == [t.getName()] &&
			true;
			
});

// -----------------------------------------------------------------------------------------------

return tests;
