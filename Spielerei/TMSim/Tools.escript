/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:TMSim'] Spielerei/TMSim/Tools.escript
 ** 2010-05 Claudius
 **/

declareNamespace($TMSim);

var tools=new Map();

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/*! TMSim.Tool base class */
GLOBALS.TMSim.Tool:=new Type();
var t=TMSim.Tool;
t._constructor::=fn(name){
	this.name:=name;
};
t.plugin::=TMSim;
t.configPanel:=void;


t.getName::=fn(){
	return this.name;
};

/*! ---o Called by TMSim.setTool(...) on the newly selected tool. */
t.enable:=fn(){
	out("Tool enabled: ",getName(),"\n");
};

/*! ---o Called by TMSim.setTool(...) on the replaced tool. */
t.disable:=fn(){
	out("Tool disabled: ",getName(),"\n");
};

/*! ---o Called when user clicks inside the editor panel. */
t.onMouseButton := fn(buttonEvent){
	out(" Tool Button:",buttonEvent.button," at ",buttonEvent.x,",",buttonEvent.y," pressed:",buttonEvent.pressed,"\n");
	return false;
};

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/*! EditTool ---|> TMSim.Tool */
t=new TMSim.Tool('project');

/*! ---|> TMSim.Tool */
t.onMouseButton := fn(buttonEvent){
	// The editorPanel does everything we need - so nothing to do.
//	out(" Select Button:",button," at ",pos," pressed:",pressed,"\n");
	return false;
};
/*! ---|> TMSim.Tool */
t.enable := fn(){
	plugin.setConfigPanel( this.getConfigPanel() );
};

t.timeLabel:=void;


t.refresh:=fn(){
	if(timeLabel){
		timeLabel.setText(plugin.getCurrentProject().getTime());
	}
};

/*!	(internal) Used by enable() */
t.getConfigPanel:=fn(){
	if(configPanel){
		return configPanel;
	}
	configPanel = gui.createPanel(180,500,GUI.AUTO_MINIMIZE|GUI.AUTO_LAYOUT);

	// -----------------------
	var b = gui.createButton(50,20,"play");
	b.plugin:=plugin;
	b.refresh:=fn(){
		setSwitch(plugin.getCurrentProject().running);
	};
	b.onClick = fn(){
		plugin.getCurrentProject().running=!plugin.getCurrentProject().running;
		refresh();
	};
	b.refresh();
	configPanel.add(b);

	b = gui.createButton(50,20,"reset");
	b.onClick = this->fn(){
		plugin.getCurrentProject().reset();
		refresh();
	};
	configPanel.add(b);

	b = gui.createButton(50,20,"step");
	b.onClick = this->fn(){
		plugin.getCurrentProject().step();
		refresh();
	};
	configPanel.add(b);

	// -----------------------
	configPanel.nextRow();
	timeLabel = gui.createLabel(50,15,"..");
	configPanel.add(timeLabel);
	// -----------------------

	configPanel.nextRow();
	var s=gui.createExtSlider( [100,15],[0.01,1.0],99 );
	s.plugin:=plugin;
	s.refresh:=fn(){
		if(plugin.getCurrentProject())
			setData(plugin.getCurrentProject().stepSize);
	};
	s.onDataChanged = fn(data){
		if(plugin.getCurrentProject())
			plugin.getCurrentProject().stepSize=getData();
	};

	s.refresh();
	configPanel.add(gui.createLabel("Step size:"));
	configPanel.add(s);
	configPanel.add(gui.createLabel("seconds"));


	// --------------------------
	configPanel.nextRow();
	b = gui.createButton(150,20,"create default");
	b.onClick = this->fn(){
		var x=10;
		var x3d=-1;
		var p=plugin.getCurrentProject();
		var source=p.createObject(p.objectTypes["source"]);
		source.setGUIPosition(new Geometry.Vec2(x,10));
		source.setNodePosition(new Geometry.Vec3(x3d,0,0));

		var t1=p.createObject(p.objectTypes["transport"]);
		t1.setGUIPosition(new Geometry.Vec2(x+=120,10));
		t1.setNodePosition(new Geometry.Vec3(x3d+=2,0,0));

		var t2=p.createObject(p.objectTypes["transport"]);
		t2.setGUIPosition(new Geometry.Vec2(x+=120,10));
		t2.setNodePosition(new Geometry.Vec3(x3d+=2,0,0));

		var drain=p.createObject(p.objectTypes["drain"]);
		drain.setGUIPosition(new Geometry.Vec2(x+=120,10));
		drain.setNodePosition(new Geometry.Vec3(x3d+=2,0,0));

		p.createConnection(source.getPort("out"),t1.getPort("in"));
		p.createConnection(t1.getPort("out"),t2.getPort("in"));
		p.createConnection(t2.getPort("out"),drain.getPort("in"));
	};
	configPanel.add(b);

//			print_r(data);

	return configPanel;
};

tools[t.getName()] = t;

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/*! EditTool ---|> TMSim.Tool */
t=new TMSim.Tool('edit');

/*! ---|> TMSim.Tool */
t.onMouseButton := fn(buttonEvent){
	// The editorPanel does everything we need - so nothing to do.
//	out(" Select Button:",button," at ",pos," pressed:",pressed,"\n");
	return false;
};
/*! ---|> TMSim.Tool */
t.enable := fn(){
	plugin.setConfigPanel( this.getConfigPanel() );
};

/*!	(internal) Used by enable() */
t.getConfigPanel:=fn(){
	if(configPanel){
		return configPanel;
	}
	configPanel = gui.createPanel(180,500,GUI.AUTO_MINIMIZE);

	Listener.add(Listener.TMSIM_SELECTED_OBJECTS_CHANGED,this->fn(evt,data){
		configPanel.clear();
		if(data.size()==1){
			if(!data[0].getAttribute('obj'))
				return;
			var obj=data[0].obj;
			var p=obj.getConfigPanel();
			if(p){
				p.setPosition(0,0);
				configPanel.add(p);
			}
			var node=obj.getNode();
			NodeEditor.selectNode(node);

		}else{
		}
//			print_r(data);
	});

	return configPanel;
};

tools[t.getName()] = t;

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/*! AddTool ---|> TMSim.Tool */
t=new TMSim.Tool('add');
t.selectedObjectType:=void;
t.componentTreeView:=void;

/*! ---|> TMSim.Tool */
t.onMouseButton := fn(buttonEvent){
	if(!buttonEvent.pressed)
		return false;
	else if(buttonEvent.button == Util.UI.MOUSE_BUTTON_RIGHT){
		plugin.setTool('edit');
		return true;
	}else if (buttonEvent.button != Util.UI.MOUSE_BUTTON_LEFT)
		return false;

	var pos = new Geometry.Vec2(buttonEvent.x, buttonEvent.y);
	var obj=plugin.findObjectAtLocalPos(pos);
	if(obj){
		plugin.selectObject(obj);
		plugin.setTool('edit');
		return true;
	}

	if(!selectedObjectType){
		plugin.statusMessage("Please select a object type.");
		return true;
	}
	var newObject=plugin.getCurrentProject().createObject(selectedObjectType.objType);
	newObject.setGUIPosition(pos);
	plugin.statusMessage("New object created: "+newObject.getName());

	plugin.selectObject(newObject);
};

/*! ---|> TMSim.Tool */
t.enable := fn(){
	plugin.setConfigPanel( this.getConfigPanel() );
};

/*! ---|> TMSim.Tool */
t.disable := fn(){
	plugin.setConfigPanel( void );
};

/*! (internal) Used by enable()	*/
t.getConfigPanel:=fn(){
	if(configPanel){
		return configPanel;
	}
	configPanel = gui.createPanel(200,500,GUI.AUTO_MINIMIZE|GUI.AUTO_LAYOUT);
	configPanel.add( gui.createLabel("Select Object type to add:"));
	configPanel.nextRow();
	componentTreeView=gui.createTreeView(160,300);
	configPanel.add(componentTreeView);

	componentTreeView.plugin:=plugin;
	componentTreeView.refresh:=fn(){
		clear();
		foreach( plugin.getCurrentProject().objectTypes as var type){
			var l=gui.createLabel(160,15,type.getName());
			l.objType:=type;
			add(l);
		}
	};
	componentTreeView.tool:=this;
	/*! ---|> GUI.Component */
	componentTreeView.onDataChanged = fn(data){
		var d=getData();
		tool.selectedObjectType = d.size()>0 ? d[0] : void;
	};
	componentTreeView.refresh();
	configPanel.nextRow();

	// -----

	var b=gui.createButton(150,15,"reload objects");
	b.onClick=this->fn(){
		plugin.getCurrentProject().reloadObjectTypes();
		componentTreeView.refresh();
	};
	configPanel.add(b);
	configPanel.nextRow();

	// -----

	b=gui.createButton(150,15,"edit objects");
	b.onClick=this->fn(){
		Util.openOS(__DIR__ + "/Objects.escript");
	};
	configPanel.add(b);
	configPanel.nextRow();

	return configPanel;
};


tools[t.getName()] = t;

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/*! ConnectTool ---|> TMSim.Tool */
t=new TMSim.Tool('connect');
t.firstPort:=void;
t.secondPort:=void;
t.statusMessage:=void;

/*! ---|> TMSim.Tool */
t.onMouseButton := fn(buttonEvent){
	if(!buttonEvent.pressed)
		return false;

	var pos = new Geometry.Vec2(buttonEvent.x, buttonEvent.y);
	if(buttonEvent.button == Util.UI.MOUSE_BUTTON_LEFT){
		var c=plugin.graphPanel.findComponentAtLocalPos(pos);
		if(!c.getAttribute('connectionPort'))
			return true;
		var port=c.connectionPort;
		if(!firstPort){
			firstPort=port;
			refreshConfigPanel();
		}else if(!secondPort){
			secondPort=port;
			if(plugin.getCurrentProject().createConnection(firstPort,secondPort))
				plugin.statusMessage("Connection created:"+
					firstPort.obj.getName()+" ["+firstPort.name+"] -> "+
					secondPort.obj.getName()+" ["+secondPort.name+"]");
			refreshConfigPanel();
		}else {
			reset();
			firstPort=port;
			refreshConfigPanel();
		}
		return true;
	}else if(buttonEvent.button == Util.UI.MOUSE_BUTTON_RIGHT){
		if(firstPort && !secondPort){
			reset();
		}else {
			plugin.setTool('edit');
		}
		return true;
	}else{
		out(" Connect Button:",buttonEvent.button," at ",pos," pressed:",buttonEvent.pressed,"\n");
	}
	return false;
};

/*! ---|> TMSim.Tool */
t.enable := fn(){
	reset();
	plugin.setConfigPanel( getConfigPanel() );
};

/*! ---|> TMSim.Tool */
t.disable := fn(){
	reset();
	plugin.setConfigPanel( void );
};


t.reset := fn(){
	firstPort=void;
	secondPort=void;
	statusMessage=void;
	refreshConfigPanel();
};

/*! (internal) Used by enable()	*/
t.getConfigPanel:=fn(){
	if(configPanel){
		return configPanel;
	}
	configPanel = gui.createPanel(200,500,GUI.AUTO_MINIMIZE|GUI.AUTO_LAYOUT);
	configPanel.add( gui.createLabel("Select two object ports:"));
	configPanel.nextRow(5);
	configPanel.portLabel_1:=gui.createLabel(100,15,"",GUI.LOWERED_BORDER);
	configPanel.add(configPanel.portLabel_1);
	configPanel.nextRow();
	configPanel.add( gui.createLabel("---->"));
	configPanel.nextRow();
	configPanel.portLabel_2:=gui.createLabel(100,15,"",GUI.LOWERED_BORDER);
	configPanel.add(configPanel.portLabel_2);
	configPanel.nextRow(5);
	configPanel.statusLabel:=gui.createLabel(180,15,"");
	configPanel.statusLabel.setTooltip("Status");
	configPanel.add(configPanel.statusLabel);
	configPanel.nextRow();
	return configPanel;
};


t.refreshConfigPanel :=fn(){
	var p=getConfigPanel();
	p.portLabel_1.setText( firstPort? ""+firstPort.obj.getName()+" ["+firstPort.name+"]" : "( ? )" );
	p.portLabel_2.setText( secondPort? ""+secondPort.obj.getName()+" ["+secondPort.name+"]" : "( ? )" );
	p.statusLabel.setText( statusMessage? statusMessage : "" );
};

tools[t.getName()] = t;

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

return tools;
