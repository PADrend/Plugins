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
 **	[Plugin:TMSim'] Spielerei/TMSim/Object.escript
 ** 2010-05 Claudius
 **/
declareNamespace($TMSim);

/*! TMSim.BaseObject base class */
TMSim.BaseObject := new Type();
var BaseObject = TMSim.BaseObject;

// ----------------------
// --- Main

BaseObject.name:=void;
BaseObject.project:=void;

/*! [ctor] */
BaseObject._constructor::=fn(){
};

BaseObject.init::=fn(TMSim.Project _project){
	this.project=_project;
};


BaseObject.getProject::=fn(){
	return this.project;
};


BaseObject.getName::=fn(){
	return this.name;
};


BaseObject.remove::=fn(){
	// remove 2d Component
	if(this.guiComponent){
		guiComponent.getParentComponent().remove(guiComponent);
		guiComponent=void;
	}
	// remove connections
	if(connectionPorts)
		foreach(connectionPorts as var port){
			foreach(port.connections as var c){
				c.remove();
			}
		}

	// remove 3d Component
	if(node)
		MinSG.destroy(node);
	project.removeObject(this);
	project=void;
	out("Object removed: ",getName(),"\n");
};

/*! Refresh 2d-component and 3d node.*/
BaseObject.refresh::=fn(){
	var c=getGUIComponent();
	if(c)
		c.refresh();
	var n=getNode();
	if(n)
		n.refresh();
};
// ----------------------
// --- Execution
BaseObject.notifyList:=void;
BaseObject.lastTime:=void;

/*! Add an object to the list of objects that are waiting for a change of this. */
BaseObject.addToNotifyList::=fn(obj){
	if(!notifyList)
		notifyList=[];
	if(!notifyList.contains(obj))
		notifyList+=obj;
};

/*! Should be called when ever this object is changed so that all waiting objects are
	executed. The list of waiting objects is cleared. */
BaseObject.notify::=fn(){
	if(notifyList){
		var l=notifyList;
		notifyList=[];
		foreach(l as var obj){
			obj.execute();
		}
	}
};

/*! Calls step(time since last step) once per simulation time step.*/
BaseObject.execute::=fn(){
	if(!project)
		return;
	var now=getProject().getTime();
	if( !lastTime || lastTime>now ){
		step(0);
	}else{
		step(now-lastTime);
	}
	lastTime=now;
};

/*! ---o */
BaseObject.step::=fn(duration){
	out("Step: ",getName(),"(",duration,")\n");
};


BaseObject.schedule::=fn(relTime){
	getProject().schedule(this,relTime.ceil());
};


BaseObject.scheduleNow::=fn(){ schedule(0); };


BaseObject.reset::=fn(){
	lastTime=void;
};

// ----------------------
// --- 2D GUI Component
BaseObject.guiComponent:=void;


BaseObject.getGUIComponent::=fn(){
	if(!this.guiComponent)
		guiComponent=createGUIComponent();
	return guiComponent;
};

/*! ---o
	The returned Component must have the following members:
	 - obj: The correspondig TMSim.BaseObject.
	 - refresh: A function updating the internal gui components.
	 - remove: A function calling remove on the TMSim.BaseObject. */
BaseObject.createGUIComponent:=fn(){


	var c=gui.createPanel(100,40,GUI.BORDER);
//	c.setPadding(0).setMargin(0);
	c.nameLabel:=gui.createLabel(100,15,"",GUI.AUTO_MAXIMIZE);
	c.nameLabel.setTextStyle(GUI.TEXT_ALIGN_CENTER|GUI.TEXT_ALIGN_MIDDLE);
	c.add(c.nameLabel);

	// (optional) status label
	this.statusText:="...";
	c.statusLabel:=gui.createLabel(100,15,statusText);
	c.statusLabel.setTextStyle(GUI.TEXT_ALIGN_CENTER);
	c.statusLabel.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM,
			new Geometry.Vec2(0,-2) );
	c.add(c.statusLabel);


	c.obj := this;
	c.refresh := fn(){
		this.nameLabel.setText(this.obj.getName());
		this.statusLabel.setText(this.obj.statusText);
	};
	c.remove := this->remove;
	c.refresh();
	return c;
};


BaseObject.setGUIPosition::=fn(Geometry.Vec2 pos){
	var c=getGUIComponent();
	if(c)
		c.setPosition(pos);
};

// ----------------------
// --- GUI Config Panel
BaseObject.configPanel:=void;


BaseObject.getConfigPanel::=fn(){
	if(!this.configPanel)
		configPanel=createConfigPanel();
	return configPanel;
};

/*! ---o */
BaseObject.createConfigPanel:=fn(){
	var p=gui.createPanel(100,100,GUI.AUTO_MINIMIZE|GUI.AUTO_LAYOUT);
	var tf=gui.createTextfield(130,15,getName());
	tf.obj:=this;
	tf.onDataChanged = fn(data){
		this.obj.name = getData();
		this.obj.refresh();
	};
	p.add(gui.createLabel("Name:"));
	p.add(tf);
	p.nextRow();
	return p;
};


// ----------------------
// --- Connections
BaseObject.connectionPorts:=void;


BaseObject.getPort::=fn(name){
	return connectionPorts ? connectionPorts[name] : void;
};

/*!	Description example:
	{ 	'pos' : 'east' ,
		'tooltip' : "outgoing port" ,
		'requiredInterface' : ['receiveToken'],
		'maxConnections' : 1
		'label' : "out" }
*/
BaseObject.createPort::=fn(name,Map desc=new Map()){
	var port=gui.createLabel(" "+desc.get('label',name)+" ",GUI.BORDER);
	// this identifies the gui component as representant for a port object
	port.connectionPort:=port;
	port.name:=name;
	port.obj:=this;
	port.guiComponent:=port;
	port.connections:=[];
	port.maxConnections:=desc['maxConnections'];
	port.requiredInterface:=desc['requiredInterface'].clone();
	
	port.addConnection:=fn(connection){
		connections+=connection;
		obj.scheduleNow();
	};
	
	port.removeConnection:=fn(connection){
		connections.filter(connection->fn(c){return c!=this;});
		obj.scheduleNow();
	};

	// tooltip
	if(desc.get('tooltip',void))
		port.setTooltip(desc['tooltip']);

	// setPosition
	var c=getGUIComponent();
	c.add(port);
	var pos=desc.get('pos','east');
	if(pos=='west'){
		port.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER,
			new Geometry.Vec2(0,0) );
	}else if(pos=='east'){
		port.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER,
			new Geometry.Vec2(0,0) );
	} // todo: north, south
	if(!connectionPorts)
		connectionPorts=new Map();
	connectionPorts[name]=port;

	return port;
};

/*! ---o
	Returns true if the two ports can be connected or a
	String why the connection is not possible. */
BaseObject.canConnect::=fn(myPort,otherPort){
	if(!myPort || ! otherPort){
		return "Incomplete";
	}else if(myPort.obj!=this){
		return "Not my port";
	}else if(myPort.obj==otherPort.obj){
		return "Can't create self connect";
	}else if(myPort.maxConnections && myPort.connections.size()>=myPort.maxConnections){
		return "Connection limit reached ("+myPort.maxConnections+")";
	}
	if(myPort.requiredInterface){
		foreach(myPort.requiredInterface as var fnName){
			if(! otherPort.getAttribute(fnName))
				return "Target does not comply the requiered interface ("+fnName+")";
		}
	}
	return true;
};

// ----------------------
// --- 3D Object
BaseObject.node:=void;


BaseObject.getNode::=fn(){
	if(!node)
		node=createNode();
	return node;
};

/*! ---o */
BaseObject.createNode:=fn(){
	var n=TMSim.getGeometry("TCube.ply");
	if(!n)
		return void;
	n.name:=getName();
	n.obj:=this;
	n.refresh:=fn(){
		this.name=obj.getName();
	};
	n.scale(0.5);
	return n;
};


BaseObject.setNodePosition:=fn(mixed){
	if(mixed---|>Geometry.SRT){
		getNode().setRelTransformation(mixed);
	}else if(mixed---|>Geometry.Vec3){
		getNode().setRelPosition(mixed);
	}else warn("wrong type");
};
// ----------------------
// --- Serialization

// ...
