/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:TMSim'] Spielerei/TMSim/Token.escript
 ** 2010-05 Claudius
 **/

declareNamespace($TMSim);

//--------------------------------------

/*! TMSim.Token base class */
GLOBALS.TMSim.Token:=new Type();
var Token=TMSim.Token;

// ----------------------
// --- Main

Token.path @(private) :=void;
//Token.size:=void; // ???
//Token.color:=void; // ???
Token.name @(private) :="Token";
Token.project @(private) :=void;
Token.behaviour @(private) :=void;

/*! [ctor] */
Token._constructor::=fn(name){
	this.name=name;
};

Token.getName::=fn(){
	return name;
};


Token.init::=fn(TMSim.Project _project){
	this.project = _project;
	var n = getNode();
	if(n)
		project.getSceneRootNode().addChild(n);
};


Token.moveTo::=fn(Geometry.SRT absSrt,duration){
	if(behaviour){
		project.getBehaviourManager().removeBehaviour(behaviour);
		behaviour=void;
	}
	if(path){
		MinSG.destroy(path);
		path=void;
	}
	var start=getSRT();
	path=new MinSG.PathNode();
	path.setLooping(false);
	path.createWaypoint(start,project.getTime());
	
	var node = getNode();
	path.createWaypoint(absSrt,project.getTime()+duration);
//	out( project.getTime(),start.getTranslation(),"->", srt.getTranslation(),project.getTime()+duration," \n ");

	behaviour=new MinSG.FollowPathBehaviour(path,getNode());
	// get in sync with project time;
	behaviour.setPosition(project.getTime(),project.getTime());
	project.getSceneRootNode().addChild(path);

	project.getBehaviourManager().registerBehaviour(behaviour);
};


Token.makePhysical::=fn(){
	if(behaviour){
		project.getBehaviourManager().removeBehaviour(behaviour);
		behaviour=void;
	}
	behaviour=MinSG.__createSimplePhysics(getNode());
	project.getBehaviourManager().registerBehaviour(behaviour);
};


Token.getSRT::=fn(){
	return getNode().getSRT();
};


Token.setPosition::=fn(Geometry.SRT srt){
	getNode().setSRT(srt);
	out(".");
};


Token.destroy::=fn(){
	// remove 3d Component
	if(node)
		MinSG.destroy(node);
//	project.removeToken(this);
//	project=void;
//	object.removeToken(this);
	if(behaviour){
		project.getBehaviourManager().removeBehaviour(behaviour);
	}
	out("Token removed \n");
};

/*! Refresh 2d-component and 3d node.*/
Token.refresh::=fn(){
//	var c=getGUIComponent();
//	if(c)
//		c.refresh();
	var n=getNode();
	if(n)
		n.refresh();
};


// ----------------------
// --- 3D Object
Token.node:=void;


Token.getNode::=fn(){
	if(!node)
		node=createNode();
	return node;
};

/*! ---o */
Token.createNode:=fn(){
	var node = new MinSG.ListNode();
	node.name:=getName();
	node.token:=this;
	node.refresh:=fn(){
		this.name=token.getName();
	};

	var g = TMSim.getGeometry("TCube.ply");
	if(g){
		g.scale(0.1);
		node += g;
	}
	return node;
};
