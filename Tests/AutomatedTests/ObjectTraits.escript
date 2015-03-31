/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var AutomatedTest = Std.module('Tests/AutomatedTest');

var tests = [];

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "ObjectTraits",fn(){
	
	var sceneManager = new (Std.module('LibMinSGExt/SceneManagerExt'));
	
	// create scene-root with separate sceneManager.
	var sceneRoot = new MinSG.ListNode;
	Std.Traits.assureTrait(sceneRoot,Std.module('LibMinSGExt/Traits/SceneMarkerTrait') );
	sceneRoot.sceneData.sceneManager := sceneManager; //! \see SceneMarkerTrait
	
	{	// LinearNodeRepeaterTrait
		
		static ok = true;
	
		// add node to repeat
		var myMesh = { // dummy mesh
			var mb = new Rendering.MeshBuilder;
			mb.addBox( new Geometry.Box(0,0,0,1,1,1) );
			mb.buildMesh();
		};
		var myObjectNode = new MinSG.GeometryNode(myMesh);
		sceneRoot += myObjectNode;
		myObjectNode.moveLocal(7, 42.5, -1);
		sceneManager.registerNode("myObject",myObjectNode);
		// add persistent trait to node
		var traitCounter = new Std.DataWrapper(0);
		var traitName = "Tests/MyTestTrait";
		var myDummyPersistentNodeTrait = new (Std.module('LibMinSGExt/Traits/PersistentNodeTrait'))(traitName);
		Std._unregisterModule(traitName);
		Std._registerModule(traitName,myDummyPersistentNodeTrait);
		myDummyPersistentNodeTrait.attributes.myTraitAttribute := "foo";
		myDummyPersistentNodeTrait.attributes.nr := -1;
		myDummyPersistentNodeTrait.onInit += [traitCounter]=>fn(traitCounter, MinSG.Node node){
			node.nr = traitCounter();
			traitCounter( traitCounter()+1 );
		};
		Std.Traits.addTrait( myObjectNode, myDummyPersistentNodeTrait);
		ok &= traitCounter() == 1; // check number of times the trait has been applied.
		
		// add container node to scene
		var repeaterContainerNode = new MinSG.ListNode;
		sceneRoot += repeaterContainerNode;
		// add repeater trait to container
		Std.Traits.addTrait(repeaterContainerNode, Std.module('ObjectTraits/Misc/LinearNodeRepeaterTrait') );
		
		var linkOk = new Std.DataWrapper(false);
		//!\ see NodeLinkTrait
		repeaterContainerNode.onNodesLinked += [linkOk,myObjectNode]=>fn(linkOk,myObjectNode,role,nodes){
			if(myObjectNode == nodes[0] && 'repeaterSource'==role)
				linkOk(true);
			else 
				Runtime.warn("Error in NodeLink.");
		};
		
		repeaterContainerNode.addLinkedNodes( 'repeaterSource',"./../MinSG:collectRefId('myObject')");
		ok &= linkOk(); // check if correct node was linked

		repeaterContainerNode.linearRepeater_displacement("0 0.5 1");
		repeaterContainerNode.linearRepeater_count(5); // should trigger the creation process
		
		ok &= MinSG.getChildNodes(repeaterContainerNode).count() == 5;
		ok &= traitCounter() == 5+1; // check number of times the trait has been applied.

		foreach(  MinSG.getChildNodes(repeaterContainerNode) as var index, var n){
			ok &= (n.getWorldOrigin() -  myObjectNode.getWorldOrigin()).distance([0, (index+1)*0.5,(index+1)])<0.001; // check displacement
			ok &= n.getMesh() == myMesh; // check node content
			ok &= "foo" == n.myTraitAttribute; // check trait
		}
		
		addResult("LinearNodeRepeaterTrait",ok);

	}

	return true;
});

return tests;
