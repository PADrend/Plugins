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
 **	[Plugin:TMSim'] Spielerei/TMSim/TMSim.Project.escript
 ** 2010-05 Claudius
 ** TODO:
 **   - move creation of editorPanel here
 **   - move object types here?
 **/

declareNamespace($TMSim);

GLOBALS.TMSim.Project:=new Type();
TMSim.Project.sceneRootNode:=void;
TMSim.Project.objects:=void;
TMSim.Project.editorPanel:=void;
TMSim.Project.currentTime:=void;
TMSim.Project.lastFrameTime:=void;
TMSim.Project.activationQueue:=void;
TMSim.Project.behaviourManager:=void;
TMSim.Project.stepSize:=void;
TMSim.Project.running:=void;
TMSim.Project.objectTypes:=void;


/*! [ctor] */
TMSim.Project._constructor::=fn(GUI.EditorPanel ep){
	this.sceneRootNode = new MinSG.ListNode();
	this.sceneRootNode.name:="TMSim";
	this.objects=[];
	this.editorPanel=ep;
	this.currentTime=0;
	this.activationQueue=new PriorityQueue(fn(a,b){
        return a[0]<b[0];
    });

	this.stepSize=0.5;
	this.running=false;

    this.behaviourManager=new MinSG.BehaviourManager();
	reloadObjectTypes();
};


TMSim.Project.reloadObjectTypes::=fn(){
	var arr;
	try{
		arr=load(__DIR__ + "/Objects.escript");
	}catch(e){
		Runtime.log(Runtime.LOG_ERROR,e);
		return;
	}
	this.objectTypes=arr;

};


TMSim.Project.getSceneRootNode::=fn(){
	return sceneRootNode;
};


TMSim.Project.getBehaviourManager::=fn(){
	return behaviourManager;
};

/*! TODO!!! */
TMSim.Project.insertObject::=fn(TMSim.BaseObject obj){
	obj.init(this);
	this.objects+=obj;
	var component=obj.getGUIComponent();
	if(component ---|> GUI.Component){
		editorPanel.add(component);
	}
	var node=obj.getNode();
	if(node ---|> MinSG.Node){
		sceneRootNode.addChild(node);
	}
	obj.scheduleNow();

};

/*!	Create a new object of given type. */
TMSim.Project.createObject::=fn(TMSim.BaseObject objType){
	var obj=new objType();
	insertObject(obj);
	return obj;
};


TMSim.Project.removeObject::=fn(obj){
	objects.filter( obj->fn(c){return c!=this;});
};

/*!	Create a new connection between two ports if possible. */
TMSim.Project.createConnection::=fn(firstPort,secondPort){
	var result=firstPort.obj.canConnect(firstPort,secondPort);
	if(! (result===true) ){
		TMSim.statusMessage(result);
		return void;
	}
	result=secondPort.obj.canConnect(secondPort,firstPort);
	if(! (result===true) ){
		TMSim.statusMessage(result);
		return void;
	}
	var con=gui.createConnector();
	con.setFirstComponent(firstPort.guiComponent);
	con.firstPort:=firstPort;
	con.setSecondComponent(secondPort.guiComponent);
	con.secondPort:=secondPort;
	
	con.remove:=fn(){
		out("Remove connection.\n");
		firstPort.removeConnection(this);
		secondPort.removeConnection(this);
		getParentComponent().remove(this);
	};
	
	con.getOtherPort:=fn(onePort){
		return onePort == firstPort ? secondPort : firstPort;
	};
	editorPanel.add(con);
	firstPort.addConnection(con);
	secondPort.addConnection(con);
	return con;
};

// ------------------
// ---- Execution
/*! Called by Plugin on every frame */
TMSim.Project.onFrame::=fn(){
	var now=clock();
	if(!running){
		lastFrameTime=now;
		return;

	}
	var duration=now-lastFrameTime;
	if(duration<stepSize){
		behaviourManager.executeBehaviours( getTime() + duration/stepSize );
		return;
	}
	lastFrameTime=now;
//	out( getTime(), " " );
	step();
	behaviourManager.executeBehaviours( getTime() );
};


TMSim.Project.getTime::=fn(){
	return currentTime;
};


TMSim.Project.step::=fn(){
	currentTime++;
	while( var top=activationQueue.get() ){
		if(top[0]>currentTime)
			break;
		activationQueue.extract();
		top[1].execute();
	}
};


TMSim.Project.schedule::=fn(obj,relTime){
	activationQueue+=[getTime()+relTime,obj];
};


TMSim.Project.reset::=fn(){
	currentTime=0;
	foreach(objects as var o){
		o.reset();
		o.scheduleNow();
	}
};

