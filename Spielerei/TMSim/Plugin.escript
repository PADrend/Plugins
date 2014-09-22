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
 **	[Plugin:TMSim'] Spielerei/TMSim/Plugin.escript
 ** 2010-05 Claudius
 **/
declareNamespace($TMSim);
static Listener = Std.require('LibUtilExt/deprecated/Listener');

GLOBALS.TMSim:=new Plugin({
		Plugin.NAME : 'Spielerei_TMSim',
		Plugin.DESCRIPTION : "Example App: Trivial material flow simulator.",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "Claudius",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

/*!	---|> Plugin	*/
TMSim.init:=fn(){
     { // Register ExtensionPointHandler:
        registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('Spielerei.tmSim',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "TMSim",
				GUI.ON_CLICK : this->fn() {
					showWindow();
					if(!currentProject){
						currentProject=new TMSim.Project(graphPanel);
						var scene=currentProject.getSceneRootNode();
						PADrend.registerScene(scene);
						PADrend.selectScene(scene);
					}

				}
			});
		});
        registerExtension('PADrend_Init',this->this.ex_Init);
        registerExtension('PADrend_AfterFrame',this->ex_AfterFrame);
    }
    this.window:=void;
    this.graphPanel:=void;
    this.configPanelContainer:=void;
    this.statusLabel:=void;
	this.currentTool:=void;
	this.tools:=void;
	this.currentProject:=void;
	this.cachedGeometry:=new Map();

	Listener.TMSIM_TOOL_CHANGED:='tmsim_toolChanged';
	Listener.TMSIM_SELECTED_OBJECTS_CHANGED:='tmsim_selObjChanged';


    return true;
};

/*!	[ext:ex_Init]	*/
TMSim.ex_Init:=fn(){
	load(__DIR__+"/Project.escript");
	load(__DIR__+"/Object.escript");
	load(__DIR__+"/Token.escript");
	this.tools=load(__DIR__ + "/Tools.escript");
	setTool('select');
};

/*!	[ext:PADrend_AfterFrame]	*/
TMSim.ex_AfterFrame:=fn(...){
	if(currentProject){
		currentProject.onFrame();
	}
};

/*!	Set current tool. Parameter can be a Tool-Object, a Tool's name or void.
	\note Notifies Listener.TMSIM_TOOL_CHANGED */
TMSim.setTool:=fn(/*(String|Tool|void)*/ newTool){
	if(newTool ---|> String)
		newTool = tools[newTool];
	if(newTool==currentTool)
		return;
	if(currentTool)
		currentTool.disable();
	currentTool = newTool;
	if(newTool)
		newTool.enable();
	Listener.notify(Listener.TMSIM_TOOL_CHANGED,newTool);
};


TMSim.getCurrentProject:=fn(){
	return currentProject;
};


TMSim.findObjectAtLocalPos:=fn(pos){
	var c=graphPanel.findComponentAtLocalPos(pos);
	while( c && c!=graphPanel){
		if( c.getAttribute('obj')---|>TMSim.BaseObject)
			return c.obj;
		c=c.getParentComponent();
	}
	return void;
};


TMSim.getGeometry:=fn(filename){
	if(cachedGeometry[filename])
		return cachedGeometry[filename].clone();
	var gn=MinSG.loadModel("Data/model/"+filename,MinSG.MESH_AUTO_CENTER_BOTTOM);
	cachedGeometry[filename]=gn;
	return gn.clone();
};

/*! Select an Object. */
TMSim.selectObject:=fn( /*TMSim.BaseObject|void*/ obj){
	graphPanel.unmarkAll();
	if(obj ---|> TMSim.BaseObject){
		var c=obj.getGUIComponent();
		if(c)
			graphPanel.markChild(c);
	}
	graphPanel.markingChanged();
};

/*! Set the current config Panel. */
TMSim.setConfigPanel:=fn( /*void|GUI.Component*/ newConfigPanel){
	if(!configPanelContainer)
		return;
	this.configPanelContainer.clear();
	if(newConfigPanel---|>GUI.Component){
		newConfigPanel.setPosition(0,0);
		this.configPanelContainer.add(newConfigPanel);
	}
};

/*! Output a status message (single line) */
TMSim.statusMessage:=fn(message){
	if(statusLabel)
		statusLabel.setText(message);
	out("StatusMessage: ",message,"\n");
};


TMSim.showWindow:=fn(){
	if(this.window){
		window.setEnabled(true);
		return;
	}
	var width=800;
	var height=800;
	window = gui.createWindow(width,height,"Example App: Trivial Material Flow Simulator");
	window.setPosition(20,20);

	// create toolbar
	var toolbar = gui.createToolbar(width-20,20,getToolbarEntries(),50);
	window.add(toolbar);

	// create editor panel
	graphPanel = gui.createEditorPanel();
	graphPanel.setExtLayout(
					GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
					GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,20),new Geometry.Vec2(-202,-36) );
	graphPanel.plugin:=this;
	/*!	---|> GUI.Component */
	graphPanel.onMouseButton := fn(buttonEvent){
		if(plugin.currentTool){
			return plugin.currentTool.onMouseButton(buttonEvent);
		}else{
//			out(" Button:",button," at ",pos," pressed:",pressed,"\n");
			return false;
		}
	};
	/*!	---|> GUI.Component */
	graphPanel.onKeyEvent := fn(keyEvent){
		if(!pressed)
			return true;
		if(keyEvent.key >= 273 && keyEvent.key<=276){
			if(PADrend.getEventContext().isCtrlPressed()){
				var d=new Geometry.Vec3();
				if(keyEvent.key==273) // up
					d.setZ(-1);
				else if(keyEvent.key==274) // down
					d.setZ(1);
				else if(keyEvent.key==276) // left
					d.setX(-1);
				else if(keyEvent.key==275) // right
					d.setX(1);
				foreach(getMarkedChildren() as var c){
					if(! (c.getAttribute('obj')---|>TMSim.BaseObject))
						continue;
					var n=c.obj.getNode();
					if(!n)
						continue;
					n.moveRel(d*0.5);
				}
			}else{
				var d=new Geometry.Vec2();
				if(keyEvent.key==273) // up
					d.setY(-1);
				else if(keyEvent.key==274) // down
					d.setY(1);
				else if(keyEvent.key==276) // left
					d.setX(-1);
				else if(keyEvent.key==275) // right
					d.setX(1);
				foreach(getMarkedChildren() as var c){
					c.setPosition(c.getPosition()+d*1.0);
				}
			}
		}else if(keyEvent.key==127){ // entf
			foreach(getMarkedChildren() as var c){
				c.remove();
			}
			unmarkAll();
		}else if(keyEvent.key==27){ // esc
			unselect();
		}else{
			out( "!Key pressed in graph panel:",keyEvent.key ,"\n");
		}
		return true;
	};
	/*!	---|> GUI.Component */
	graphPanel.onDataChanged = fn(data){
		// selection changed
		Listener.notify(Listener.TMSIM_SELECTED_OBJECTS_CHANGED,getData());
	};
	window.add(graphPanel);

	// create config panel
	configPanelContainer = gui.createPanel(200,height,GUI.RAISED_BORDER|GUI.AUTO_LAYOUT);
	configPanelContainer.setExtLayout(
					GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
					GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,20),new Geometry.Vec2(200,-36) );
	window.add(configPanelContainer);

	// create statusPanel
	var statusPanel = gui.createPanel(200,15,GUI.RAISED_BORDER);
	statusPanel.setTooltip("Status messages");
	statusPanel.setExtLayout(
					GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM|
					GUI.WIDTH_REL|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,0),new Geometry.Vec2(1.0,15) );
	window.add(statusPanel);
	statusLabel = gui.createLabel(100,15,"Welcome!");
	statusLabel.setExtLayout(
					GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
					GUI.WIDTH_REL|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,1),new Geometry.Vec2(1.0,15) );
	statusPanel.add(statusLabel);
};

/*! (internal) Used by showWindow	*/
TMSim.getToolbarEntries:=fn(){
	var toolbar=[];

    toolbar += {
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.LABEL : "Project",
        GUI.ON_CLICK : this->fn(){
			setTool( 'project' );
        },
        'onInit':fn(description){
        	Listener.add(Listener.TMSIM_TOOL_CHANGED,this->fn(evt,newTool){
				this.setSwitch( newTool && newTool.getName()=='project' );
			});
        },
        GUI.TOOLTIP : "Simulation and Project properties"
    };
    toolbar += {
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.LABEL : "Edit",
        GUI.ON_CLICK : this->fn(){
			setTool( 'edit' );
        },
        'onInit':fn(description){
        	Listener.add(Listener.TMSIM_TOOL_CHANGED,this->fn(evt,newTool){
				this.setSwitch( newTool && newTool.getName()=='edit' );
			});
        },
        GUI.TOOLTIP : "Select objects"
    };
    toolbar += {
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.LABEL : "Add",
        GUI.ON_CLICK : this->fn(){
			setTool( 'add' );
        },
        'onInit':fn(description){
        	Listener.add(Listener.TMSIM_TOOL_CHANGED,this->fn(evt,newTool){
				this.setSwitch( newTool && newTool.getName()=='add' );
			});
        },
        GUI.TOOLTIP : "Add Objects"
    };
    toolbar += {
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.LABEL : "Connect",
        GUI.ON_CLICK : this->fn(){
			setTool( 'connect' );
        },
        'onInit':fn(description){
        	Listener.add(Listener.TMSIM_TOOL_CHANGED,this->fn(evt,newTool){
				this.setSwitch( newTool && newTool.getName()=='connect' );
			});
        },
        GUI.TOOLTIP : "Add Objects"
    };
    return toolbar;
};

// ---------------------------------------------------------
return TMSim;
