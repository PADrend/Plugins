/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 David Maicher
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeConfig] NodeEditor/BehaviourPanels.escript
 **
 **/
// ----

/*!	Creates a default panel.	*/
NodeEditor.registerConfigPanelProvider( MinSG.AbstractBehaviour, fn(MinSG.AbstractBehaviour b, panel){
	panel += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : NodeEditor.getString(b),
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.COLOR : NodeEditor.BEHAVIOUR_COLOR
    };
    panel++;
	panel+=" ";

});

// ----

/*!	FollowPathBehaviour	*/
if(GLOBALS.isSet($WaypointsPlugin) && MinSG.isSet($FollowPathBehaviour))
NodeEditor.registerConfigPanelProvider( MinSG.FollowPathBehaviour, fn(MinSG.FollowPathBehaviour b, panel){
    panel += "*FollowPathBehaviour:*";
    panel++;

	var pathSelector=gui.createDropdown(250,15);
	pathSelector.behaviour:=b;
	pathSelector.refresh:=fn(){
		var p=behaviour.getPath();
		clear();
		addOption( void," --- ");
		foreach(WaypointsPlugin.getRegisteredPaths() as var path ){
			addOption( path,NodeEditor.getString(path));
		}
		setData(p);
		onDataChanged(p);
	};
	pathSelector.onDataChanged = fn(data){
		behaviour.setPath(data);
	};
	panel+=pathSelector;
	panel++;
	var button=gui.createButton(100,15,"refresh");
	panel+=button;
	button.onClick=pathSelector->pathSelector.refresh;

	pathSelector.refresh();
});

// ----

/*!	KeyFrameAnimationBehaviour	*/
if(MinSG.isSet($KeyFrameAnimationBehaviour))
NodeEditor.registerConfigPanelProvider( MinSG.KeyFrameAnimationBehaviour, fn(MinSG.KeyFrameAnimationBehaviour b, panel){
    panel += "Active animation (name, startframe, endframe, fps):";
    panel++;

    panel.add(panel.chooseActiveAnim:=gui.createDropdown(180,15));
	panel.chooseActiveAnim.setTooltip("Choose active animation");
	panel.chooseActiveAnim.onDataChanged = fn(data){
		NodeEditor.getSelectedNode().setActiveAnimation(data);
	};

    var activeAnimationName = b.getNode().getActiveAnimationName();

	var mapIter = b.getNode().getAnimationData().getIterator();
	while(!mapIter.end()){
		var row = "'"+mapIter.key()+"'";
		var arrayIter = mapIter.value().getIterator();
		while(!arrayIter.end()){
			row += ", "+arrayIter.value();
			arrayIter.next();
		}

    	panel.chooseActiveAnim.addOption(mapIter.key(), row);

    	//set active
    	if(activeAnimationName == mapIter.key())
			panel.chooseActiveAnim.setData(mapIter.key());

    	mapIter.next();
	}

	panel++;
	panel += "";
	panel++;
	panel += "Animation speed:";
	panel++;
	panel.add(panel.speedFactorSlider:=gui.createSlider(100, 15, 0.0, 3.0, 50, GUI.SHOW_VALUE));
	panel.speedFactorSlider.setValue(b.getNode().getSpeedFactor());
	panel.speedFactorSlider.onDataChanged = fn(data){
		NodeEditor.getSelectedNode().setSpeedFactor(data);
	};

	panel++;
	panel += "";
	panel++;
	panel += "Animation mode:";
	panel++;

	panel.add(panel.chooseMode:=gui.createDropdown(180,15));
	panel.chooseMode.setTooltip("Choose animation mode");


	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Play",
		GUI.ON_CLICK : b->fn(){	setState(1);	}
	};
	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Loop",
		GUI.ON_CLICK : b->fn(){	setState(0);	}
	};
	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Stop",
		GUI.ON_CLICK : b->fn(){	setState(2);	}
	};
});

// -----------------------------------------------------



/*!	ParticleEmitter	*/
if(MinSG.isSet($ParticleEmitter))
NodeEditor.registerConfigPanelProvider( MinSG.ParticleEmitter, fn(MinSG.ParticleEmitter b, panel){
	panel += "*ParticleEmitter:*";
	panel++;

    {
    	panel += "Reference node: ";

	    var cb = gui.createDropdown(180, 15);
	    // collect all geometry- & list-nodes
	    cb.addOption(void, "(default)");
		var nodeNames=PADrend.getSceneManager().getNamesOfRegisteredNodes();
		foreach(nodeNames as var nodeName) {
			var p = PADrend.getSceneManager().getRegisteredNode(nodeName);
			cb.addOption(p, NodeEditor.getString(p));
		}

	    cb.setData(b.getSpawnNode());
	    cb.behave := b;
		cb.onDataChanged = fn(data){
			behave.setSpawnNode(data);
		};
	    panel.add(cb);
	    panel++;
	}
	panel.nextRow(5);
    {
    	panel += "Particles per second: ";
    }
    panel++;
	{
		panel.add(panel.ppsecond:=gui.createExtSlider([200,16],[0,500],200));
		panel.ppsecond.setValue(b.getParticlesPerSecond());
		panel.ppsecond.onDataChanged = b->fn(data){
			this.setParticlesPerSecond(data);
		};
	}
    panel.nextRow(5);
    {
    	panel += "Direction (x, y, z): ";
    }
    panel++;
	{
		var input=gui.createTextfield(100, 15, "");
		input.setText("["+b.getDirection().getX()+","+b.getDirection().getY()+","+b.getDirection().getZ()+"]");
		input.b := b;
		input.onDataChanged = fn(data){
			b.setDirection(new Geometry.Vec3(parseJSON(data)));
		};
		panel.add(input);

    	panel += "Variance angle (degree): ";
		panel.add(panel.dirVarAngle:=gui.createExtSlider([100,16],[0,360],200));
		panel.dirVarAngle.setValue(b.getDirectionVarianceAngle());
		panel.dirVarAngle.onDataChanged = b->fn(data){
			this.setDirectionVarianceAngle(data);
		};
	}
	panel.nextRow(5);
    {
    	panel += "Initial speed: ";
    	panel.nextColumn();
		panel.add(panel.minSpeed:=gui.createExtSlider([100,16],[0,50],200));
		panel.minSpeed.setValue(b.getMinSpeed());
		panel.minSpeed.onDataChanged = b->fn(data){
			this.setMinSpeed(data);
		};
    	panel.nextColumn();
    	panel += "to: ";
    	panel.nextColumn();
		panel.add(panel.maxSpeed:=gui.createExtSlider([100,16],[0,50],200));
		panel.maxSpeed.setValue(b.getMaxSpeed());
		panel.maxSpeed.onDataChanged = b->fn(data){
			this.setMaxSpeed(data);
		};
	}
	panel.nextRow(5);
    {
    	panel += "Life time: ";
    	panel.nextColumn();
		panel.add(panel.minLife:=gui.createExtSlider([100,16],[0,100],200));
		panel.minLife.setValue(b.getMinLife());
		panel.minLife.onDataChanged = b->fn(data){
			this.setMinLife(data);
		};
    	panel.nextColumn();
    	panel += "to: ";
    	panel.nextColumn();
		panel.add(panel.maxLife:=gui.createExtSlider([100,16],[0,100],200));
		panel.maxLife.setValue(b.getMaxLife());
		panel.maxLife.onDataChanged = b->fn(data){
			this.setMaxLife(data);
		};
	}
	panel.nextRow(5);
    {
    	panel += "Width: ";
    	panel.nextColumn();
		panel.add(panel.minWidth:=gui.createExtSlider([100,16],[0,200],200));
		panel.minWidth.setValue(b.getMinWidth());
		panel.minWidth.onDataChanged = b->fn(data){
			this.setMinWidth(data);
		};
    	panel.nextColumn();
    	panel += "to: ";
    	panel.nextColumn();
		panel.add(panel.maxWidth:=gui.createExtSlider([100,16],[0,200],200));
		panel.maxWidth.setValue(b.getMaxWidth());
		panel.maxWidth.onDataChanged = b->fn(data){
			this.setMaxWidth(data);
		};
	}
	panel.nextRow(5);
    {
    	panel += "Height: ";
    	panel.nextColumn();
		panel.add(panel.minHeight:=gui.createExtSlider([100,16],[0,200],200));
		panel.minHeight.setValue(b.getMinHeight());
		panel.minHeight.onDataChanged = b->fn(data){
			this.setMinHeight(data);
		};
    	panel.nextColumn();
    	panel += "to: ";
    	panel.nextColumn();
		panel.add(panel.maxHeight:=gui.createExtSlider([100,16],[0,200],200));
		panel.maxHeight.setValue(b.getMaxHeight());
		panel.maxHeight.onDataChanged = b->fn(data){
			this.setMaxHeight(data);
		};
	}
	panel.nextRow(5);
    {
    	panel += "Color (range): ";
    }
    panel++;

    panel+={
    	GUI.TYPE : GUI.TYPE_COLOR,
    	GUI.LABEL : "from",
    	GUI.DATA_VALUE : b.getMinColor(),
    	GUI.ON_DATA_CHANGED : b->b.setMinColor,
    	GUI.WIDTH : 150
    };

    panel+={
    	GUI.TYPE : GUI.TYPE_COLOR,
    	GUI.LABEL : "to",
    	GUI.DATA_VALUE : b.getMaxColor(),
    	GUI.ON_DATA_CHANGED : b->b.setMaxColor,
    	GUI.WIDTH : 150
    };
	
	panel++;
	
	panel += {
		GUI.LABEL : "Time Offset",
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.DATA_VALUE : b.getTimeOffset(),
		GUI.RANGE : [0.0, 60.0],
		GUI.RANGE_STEPS : 120,
		GUI.ON_DATA_CHANGED : b -> b.setTimeOffset
	};
});

// ----

/*!	ParticleBoxEmitter	*/
if(MinSG.isSet($ParticleBoxEmitter))
NodeEditor.registerConfigPanelProvider( MinSG.ParticleBoxEmitter, fn(MinSG.ParticleBoxEmitter b, panel){
    panel += "*ParticleBoxEmitter:*";
    panel++;

    // add min and max offset
    {
    	panel += "Bounds [center-x, y, z, width, height, depth]: ";
    }
    panel++;
	{
		var input=gui.createTextfield(250, 15, "");
		var center = b.getEmitBounds().getCenter();
		input.setText("["+
			center.getX()+","+center.getY()+","+
			center.getZ()+","+b.getEmitBounds().getExtentX()+","+
			b.getEmitBounds().getExtentY()+","+b.getEmitBounds().getExtentZ()+"]");
		input.b := b;
		input.onDataChanged = fn(data){
			var arr = parseJSON(data);
			b.setEmitBounds(new Geometry.Box(arr[0],arr[1],arr[2],arr[3],arr[4],arr[5]));
		};
		panel.add(input);
	}
});

// ----

/*!	ParticleGravityAffector	*/
if(MinSG.isSet($ParticleGravityAffector))
NodeEditor.registerConfigPanelProvider( MinSG.ParticleGravityAffector, fn(MinSG.ParticleGravityAffector b, panel){
    panel += "*ParticleGravityAffector:*";
    panel++;

    panel += "Gravity (x): ";
    panel++;
	panel.add(panel.gravitySliderX:=gui.createExtSlider([200,16],[-10,10],100));
	panel.gravitySliderX.setValue(b.getGravity().getX());
	panel.gravitySliderX.onDataChanged = b->fn(data){
		var gravity = this.getGravity();
		gravity.setX(data);
		this.setGravity(gravity);
	};
	panel.nextRow(5);

    panel += "Gravity (y): ";
    panel++;
	panel.add(panel.gravitySliderY:=gui.createExtSlider([200,16],[-10,10],100));
	panel.gravitySliderY.setValue(b.getGravity().getY());
	panel.gravitySliderY.onDataChanged = b->fn(data){
		var gravity = this.getGravity();
		gravity.setY(data);
		this.setGravity(gravity);
	};
	panel.nextRow(5);

    panel += "Gravity (z): ";
    panel++;
	panel.add(panel.gravitySliderZ:=gui.createExtSlider([200,16],[-10,10],100));
	panel.gravitySliderZ.setValue(b.getGravity().getZ());
	panel.gravitySliderZ.onDataChanged = b->fn(data){
		var gravity = this.getGravity();
		gravity.setZ(data);
		this.setGravity(gravity);
	};
});

/*!	ParticleReflectionAffector	*/
if(MinSG.isSet($ParticleReflectionAffector))
NodeEditor.registerConfigPanelProvider( MinSG.ParticleReflectionAffector, fn(MinSG.ParticleReflectionAffector b, panel){
    panel += "*ParticleReflectionAffector:*";
    panel++;

    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Reflectiveness",
		GUI.DATA_WRAPPER : Std.DataWrapper.createFromFunctions(b->b.getReflectiveness,b->b.setReflectiveness),
		GUI.RANGE : [0,1.0]		
    };
    panel++;

    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Adherence",
		GUI.DATA_WRAPPER : Std.DataWrapper.createFromFunctions(b->b.getAdherence,b->b.setAdherence),
		GUI.RANGE : [0,1.0]
    };

    panel++;
    
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Plane",
		GUI.DATA_WRAPPER : Std.DataWrapper.createFromFunctions( 
				[b] => fn(b){	return (b.getPlane().getNormal().toArray() += b.getPlane().getOffset()).implode(" ");	},
				[b] => fn(b,str){
					var arr = str.split(" ");
					b.setPlane( new Geometry.Plane( arr.slice(0,3), arr[3] ) );
				})
    };
    panel++;
    
});

// ----

/*!	ParticlePointEmitter	*/
if(MinSG.isSet($ParticlePointEmitter))
NodeEditor.registerConfigPanelProvider( MinSG.ParticlePointEmitter, fn(MinSG.ParticlePointEmitter b, panel){
    panel += "*ParticlePointEmitter:*";
    panel++;

    // add min and max offset
    {
    	panel += "Offset: ";
    	panel.nextColumn();
		panel.add(panel.minOffset:=gui.createExtSlider([100,16],[0,200],200));
		panel.minOffset.setValue(b.getMinOffset());
		panel.minOffset.onDataChanged = b->fn(data){
			this.setMinOffset(data);
		};
    	panel.nextColumn();
    	panel += "to: ";
    	panel.nextColumn();
		panel.add(panel.maxOffset:=gui.createExtSlider([100,16],[0,200],200));
		panel.maxOffset.setValue(b.getMaxOffset());
		panel.maxOffset.onDataChanged = b->fn(data){
			this.setMaxOffset(data);
		};
	}
});

return true;
// --------------------------------------------------------------------------
