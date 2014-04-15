/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 David Maicher
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010 Paul Justus
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeConfig] NodeEditor/NodePanels.escript
 **
 **/

/*!	Node */
NodeEditor.registerConfigPanelProvider( MinSG.Node, fn(node, panel){

    panel += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : NodeEditor.getString(node),
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.COLOR : NodeEditor.NODE_COLOR
    };

    panel.nextRow(10);
	panel += '----';

	var id = PADrend.getSceneManager().getNameOfRegisteredNode(node);
	panel++;
	panel+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "NodeId:",
		GUI.DATA_VALUE : id ? id : "",
		GUI.OPTIONS : [id ? id : ""],
		GUI.ON_DATA_CHANGED : node->fn(data){
			var newId = data.trim();			
			if(newId.empty()){
				var oldId = PADrend.getSceneManager().getNameOfRegisteredNode(this);
				if(oldId){
					out("Unregistering node '",oldId,"'\n");
					PADrend.getSceneManager().unregisterNode(oldId);
				}
			}else{
				out("Registering node with id '",newId,"'\n");
				PADrend.getSceneManager().registerNode(newId,this);
			}
		}
	};
    panel++;
    panel += {
    	GUI.TYPE : GUI.TYPE_BOOL,
    	GUI.LABEL : "is active",
    	GUI.DATA_VALUE : node.isActive(),
    	GUI.ON_DATA_CHANGED : [node] => fn(node,data){
			if(data) {
				node.activate();
			} else {
				node.deactivate();
			}
		}
    };
    panel += {
    	GUI.TYPE : GUI.TYPE_BOOL,
    	GUI.LABEL : "is temporary",
    	GUI.DATA_VALUE : node.isTempNode(),
    	GUI.ON_DATA_CHANGED : node -> node.setTempNode,
		GUI.TOOLTIP : "If enabled, the node is not saved."
    };
    panel += {
    	GUI.TYPE : GUI.TYPE_BOOL,
    	GUI.LABEL : "is semantic obj",
    	GUI.DATA_VALUE : MinSG.SemanticObjects.isSemanticObject(node),
    	GUI.ON_DATA_CHANGED : [node] => MinSG.SemanticObjects.markAsSemanticObject,
		GUI.TOOLTIP : "Mark to show if the node is a semantic object."
    };
    if(node.isInstance()){
		var inheritedTraits = MinSG.getLocalPersistentNodeTraitNames(node.getPrototype());
		if(!inheritedTraits.empty()){
			panel++;
			panel += "PersistentNodeTraits (inherited): "+inheritedTraits.implode(", ");
		}
    }
    var localTraits = MinSG.getLocalPersistentNodeTraitNames(node);
    if(!localTraits.empty()){
		panel++;
		panel += "PersistentNodeTraits (local): "+localTraits.implode(", ");
    }
	if(node.isInstance()){
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Prototype of " + NodeEditor.getString(node.getPrototype()),
			GUI.ON_CLICK : [node] => fn(node){	NodeEditor.selectNode(node.getPrototype());	},
			GUI.SIZE : [GUI.WIDTH_FILL_ABS,10,15],
			GUI.TOOLTIP : "Select prototype."
		};		
    }
});

// ----

/*!	GroupNode	*/
NodeEditor.registerConfigPanelProvider( MinSG.GroupNode, fn(node, panel){

    panel += "*GroupNode Info:*";

    panel++;
    var cb=gui.createCheckbox("is closed",node.isClosed());
    cb.node:=node;
    cb.onDataChanged = fn(data){
    	node.setClosed(data);
    };
    panel += (cb);

    panel++;

	var button = gui.createButton(150,20,"Count values in (sub)tree:");

	button.resetValues := fn(){
		this.values.nodes := 0;
		this.values.geonodes := 0;
		this.values.groupnodes := 0;
		this.values.triangles := 0;
		this.values.vertices := 0;
		this.values.states := 0;
	};

	button.createLabels := fn(){
		this.labels.nodes := gui.createLabel(this.values.nodes);
		this.labels.geonodes := gui.createLabel(this.values.geonodes);
		this.labels.groupnodes := gui.createLabel(this.values.groupnodes);
		this.labels.triangles := gui.createLabel(this.values.triangles);
		this.labels.vertices := gui.createLabel(this.values.vertices);
		this.labels.states := gui.createLabel(this.values.states);
	};

	button.calcValues := fn(){
		foreach(MinSG.collectNodes(node) as var n){
			this.values.nodes++;
			if(n ---|> MinSG.GeometryNode){
				this.values.geonodes++;
				this.values.triangles += n.getTriangleCount();
				this.values.vertices += n.getVertexCount();
			}
			if(n ---|> MinSG.GroupNode)
				this.values.groupnodes++;
			if(n.hasStates())
				this.values.states += n.getStates().count();
		}
	};

	button.updateLabels := fn(){
		this.labels.nodes.setText(this.values.nodes);
		this.labels.geonodes.setText(this.values.geonodes);
		this.labels.groupnodes.setText(this.values.groupnodes);
		this.labels.triangles.setText(this.values.triangles);
		this.labels.vertices.setText(this.values.vertices);
		this.labels.states.setText(this.values.states);
	};

	button.onClick = fn(){
		this.resetValues();
		this.calcValues();
		this.updateLabels();
	};

	button.node := node;
	button.values := new ExtObject();
	button.resetValues();
	button.labels := new ExtObject();
	button.createLabels();

    panel += (button);
    panel++;

    panel += "Nodes:         ";
	panel.nextColumn();
    panel += (button.labels.nodes);
    panel++;

    panel += "GroupNodes:    ";
	panel.nextColumn();
    panel += (button.labels.groupnodes);
    panel++;

    panel += "GeometryNodes: ";
	panel.nextColumn();
    panel += (button.labels.geonodes);
    panel++;

    panel += "Triangles:     ";
	panel.nextColumn();
    panel.add(button.labels.triangles);
    panel++;

    panel += "Vertices:      ";
	panel.nextColumn();
    panel += (button.labels.vertices);
	panel++;

    panel += "States:        ";
	panel.nextColumn();
    panel += (button.labels.states);
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Levels",
		GUI.TOOLTIP			:	"Output how many nodes are on which level of the scene graph.",
		GUI.ON_CLICK		:	[node] => fn(MinSG.GroupNode groupNode) {
									var levelCounts = MinSG.countNodesInLevels(groupNode);
									var firstLine = "Level:";
									var secondLine = "Count:";
									foreach(levelCounts as var level, var count) {
										firstLine += "\t" + level;
										secondLine += "\t" + count;
									}
									outln(firstLine, "\n", secondLine);
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
    return true;
});

// ----

/*!	GeometryNode	*/
NodeEditor.registerConfigPanelProvider( MinSG.GeometryNode, fn(node, panel){

	panel += "*GeometryNode Info:*";
	panel++;
	panel += "Vertices: " + node.getVertexCount();
	panel++;
	panel += "Triangles: " + node.getTriangleCount();
	panel++;
	var mesh = node.getMesh();
	if(mesh) {
		panel+='----';
		panel++;
		panel += mesh.toString();
		panel++;

		
		var attributesPanel = gui.create({
			GUI.TYPE		:	GUI.TYPE_CONTAINER,
			GUI.SIZE		:	GUI.SIZE_MINIMIZE,
			GUI.LAYOUT		:	GUI.LAYOUT_FLOW,
			
			GUI.CONTENTS	:	[
									"*VertexAttributes:*",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_ROW	},
									
									"Name",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									"Offset",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									"Number",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									"Type",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									"Size",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									"Action",
									{	GUI.TYPE		:	GUI.TYPE_NEXT_ROW	}
								]
		});
		
		foreach(mesh.getVertexDescription().getAttributes() as var attribute) {
			attributesPanel += [
									{
										GUI.TYPE		:	GUI.TYPE_LABEL,
										GUI.LABEL		:	attribute.getName()
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									{
										GUI.TYPE		:	GUI.TYPE_LABEL,
										GUI.LABEL		:	attribute.getOffset()
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									{
										GUI.TYPE		:	GUI.TYPE_LABEL,
										GUI.LABEL		:	attribute.getNumValues()
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									{
										GUI.TYPE		:	GUI.TYPE_LABEL,
										GUI.LABEL		:	Rendering.getGLTypeString(attribute.getDataType())
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									{
										GUI.TYPE		:	GUI.TYPE_LABEL,
										GUI.LABEL		:	attribute.getDataSize()
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_COLUMN	},
									{
										GUI.TYPE		:	GUI.TYPE_BUTTON,
										GUI.LABEL		:	"Remove",
										GUI.TOOLTIP		:	"Remove the VertexAttribute " + attribute.getName() + " from the VertexDescription\nand convert the vertices of the mesh.",
										GUI.ON_CLICK	:	[mesh, attribute] -> fn() {
																var newVertexDesc = new Rendering.VertexDescription();
																foreach(this[0].getVertexDescription().getAttributes() as var attribute) {
																	// Omit the attribute that is to be deleted.
																	if(attribute.getName() != this[1].getName()) {
																		newVertexDesc.appendAttribute(attribute.getName(), attribute.getNumValues(), attribute.getDataType());
																	}
																}
																Rendering.convertVertices(this[0], newVertexDesc);
															},
										GUI.WIDTH		:	50
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_ROW	}
								];
		}
		
		panel += attributesPanel;
		panel++;
		panel += "Vertex Size: " + mesh.getVertexDescription().getVertexSize();
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Use indexData",
			GUI.DATA_PROVIDER : mesh -> mesh.isUsingIndexData,
			GUI.ON_DATA_CHANGED : mesh -> mesh.setUseIndexData
		};
		panel++;
	}

	panel++;
	panel+='----';
	panel++;
	// mesh file selector
	var data = new ExtObject({$filename : mesh?mesh.getFileName().toString() : "", $node : node });
	panel += {
		GUI.TYPE : GUI.TYPE_FILE,
		GUI.LABEL : "Mesh's filename",
		GUI.ENDINGS : [".ply",".mmf"],
		GUI.DIR :  PADrend.getDataPath(),
		GUI.DATA_OBJECT : data,
		GUI.DATA_ATTRIBUTE : $filename,
		GUI.ON_DATA_CHANGED : node -> fn(filename){
			if(this.getMesh())
				this.getMesh().setFileName(filename);
		},
		GUI.TOOLTIP		:	"Leave empty to embed the mesh in minsg file."
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Reload mesh",
		GUI.ON_CLICK : data -> fn(){
			out("Load Mesh \"", this.filename, "\"...");
			PADrend.message("Load Mesh \"" + this.filename + "\"...");
			showWaitingScreen();

			var geoNode = MinSG.loadModel(this.filename);
			if(!(geoNode ---|> MinSG.GeometryNode)) {
				Runtime.warn("Could not load single mesh from " + this.filename);
				return;
			}
		
			this.node.setMesh(geoNode.getMesh());
			out("\nDone. \n");
		},
		GUI.TOOLTIP		:	"Reload the GeometryNode's mesh from the given file."
	};
	
	panel++;
	return true;
});

// ----

/*!	Light	*/
NodeEditor.registerConfigPanelProvider( MinSG.LightNode, fn(node, panel){

	var dummy = new ExtObject();
	dummy.node := node;

    panel += "*LightNode Info:*";

	panel++;

	dummy.type := gui.createRadioButtonSet();
	dummy.type.addOption(MinSG.LightNode.POINT, "Point Light");
	dummy.type.addOption(MinSG.LightNode.SPOT, "Spot Light");
	dummy.type.addOption(MinSG.LightNode.DIRECTIONAL, "Directional Light");
	dummy.type.onDataChanged = dummy->fn(data){if(disabled)return; node.setLightType(data); reset();};

	panel += dummy.type;
	panel++;

	dummy.ambient := gui.create({
		GUI.TYPE : GUI.TYPE_COLOR,
		GUI.SIZE :  [180,100],
		GUI.DATA_VALUE : node.getAmbientLightColor(),
		GUI.ON_DATA_CHANGED : dummy->fn(data){if(disabled)return; node.setAmbientLightColor(data); reset();},
		GUI.LABEL : "Ambient"
	});
	panel += dummy.ambient;
	panel.nextColumn();

	dummy.diffuse := gui.create({
		GUI.TYPE : GUI.TYPE_COLOR,
		GUI.SIZE :  [180,100],
		GUI.DATA_VALUE : node.getDiffuseLightColor(),
		GUI.ON_DATA_CHANGED : dummy->fn(data){if(disabled)return; node.setDiffuseLightColor(data); reset();},
		GUI.LABEL : "Diffuse"
	});

	panel += dummy.diffuse;
	panel++;

	dummy.specular := gui.create({
		GUI.TYPE : GUI.TYPE_COLOR,
		GUI.SIZE :  [180,100],
		GUI.DATA_VALUE : node.getSpecularLightColor(),
		GUI.ON_DATA_CHANGED : dummy->fn(data){if(disabled)return; node.setSpecularLightColor(data); reset();},
		GUI.LABEL : "Specular"
	});

	panel += dummy.specular;
	panel.nextColumn();

	var attenuationPanel = gui.createPanel(180, 100, GUI.AUTO_LAYOUT | GUI.LOWERED_BORDER);
	attenuationPanel.setMargin(1);

	attenuationPanel.add(gui.createLabel(180, 15, "Attenuation"));

	attenuationPanel++;

	dummy.constant := gui.createExtSlider([170, 15], [0, 8], 32);
	dummy.constant.setTooltip("Constant attenuation");
	dummy.constant.onDataChanged = dummy->fn(data) {if(disabled)return; node.setConstantAttenuation(data); reset();};

	attenuationPanel.add(dummy.constant);
	attenuationPanel++;

	dummy.linear := gui.createExtSlider([170, 15], [0, 4], 32);
	dummy.linear.setTooltip("Linear attenuation");
	dummy.linear.onDataChanged = dummy->fn(data) {if(disabled)return; node.setLinearAttenuation(data);	reset();};

	attenuationPanel.add(dummy.linear);
	attenuationPanel++;

	dummy.quadratic := gui.createExtSlider([170, 15], [0, 2], 32);
	dummy.quadratic.setTooltip("Quadratic attenuation");
	dummy.quadratic.onDataChanged = dummy->fn(data) {if(disabled)return; node.setQuadraticAttenuation(data); reset();};

	attenuationPanel.add(dummy.quadratic);

	panel += (attenuationPanel);
	panel++;

	var spotPanel = gui.createPanel(180, 80, GUI.AUTO_LAYOUT | GUI.LOWERED_BORDER);
	spotPanel.setMargin(1);
	panel += (spotPanel);

	spotPanel.add(gui.createLabel(180, 15, "Spot exponent:"));
	spotPanel++;
	dummy.exponent := gui.createExtSlider([170, 15], [0, 128], 128);
	dummy.exponent.onDataChanged = dummy->fn(data) {if(disabled)return; node.setExponent(data); reset();};

	spotPanel.add(dummy.exponent);
	spotPanel++;

	spotPanel.add(gui.createLabel(180, 15, "Spot cutoff angle:"));
	spotPanel++;
	dummy.cutoff := gui.createExtSlider([170, 15], [0, 90], 90);
	dummy.cutoff.onDataChanged = dummy->fn(data) {if(disabled)return; node.setCutoff(data); reset();};
	spotPanel.add(dummy.cutoff);

	dummy.disabled := false;
	dummy.reset := fn(){
		disabled = true;
		type.setData(node.getLightType());
		ambient.setData(node.getAmbientLightColor());
		diffuse.setData(node.getDiffuseLightColor());
		specular.setData(node.getSpecularLightColor());
		constant.setData(node.getConstantAttenuation());
		linear.setData(node.getLinearAttenuation());
		quadratic.setData(node.getQuadraticAttenuation());
		exponent.setData(node.getExponent());
		cutoff.setData(node.getCutoff());
		disabled = false;
	};
	dummy.reset();

	return true;
});

// ----

if(MinSG.isSet($ParticleSystemNode)){

/*!	ParticleSystemNode	*/
NodeEditor.registerConfigPanelProvider( MinSG.ParticleSystemNode, fn(node, panel){

    panel += "*ParticleSystemNode Info:*";
    panel++;

    // create GUI
    // 1. create renderer selector
    var cb = gui.createDropdown(180, 15);
    cb.addOption(MinSG.ParticleSystemNode.POINT_RENDERER, "Point renderer");
    cb.addOption(MinSG.ParticleSystemNode.BILLBOARD_RENDERER, "Billboard renderer");
    cb.setData(node.getRendererType());
    cb.node := node;
	cb.onDataChanged = fn(data){
		node.setRenderer(data);
	};
    panel += (cb);

    // 2. change max particles
    panel.nextRow(5);
    {
    	panel += "Max. particle count: ";
    }
    panel++;
	{
		panel += (panel.maxParticles:=gui.createExtSlider([100,16],[100,10000],200));
		panel.maxParticles.setValue(node.getMaxParticleCount());
		panel.maxParticles.node := node;
		panel.maxParticles.onDataChanged = fn(data){
			node.setMaxParticleCount(data);
		};
	}

    return true;
});
}

/*!	MultiAlgoGroupNode	*/
if(MinSG.isSet($MAR))
	
	NodeEditor.registerConfigPanelProvider( MinSG.MAR.MultiAlgoGroupNode, fn(node, panel){
		
		panel += "*MultiAlgoGroupNode Info:*";
		panel++;
		
		panel += {
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.LABEL : "Algorithm",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(node->node.getAlgorithm, node->node.setAlgorithm),
			GUI.OPTIONS : [
				[MinSG.MAR.MultiAlgoGroupNode.ForceSurfels, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.ForceSurfels)],
				[MinSG.MAR.MultiAlgoGroupNode.BlueSurfels, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.BlueSurfels)],
				[MinSG.MAR.MultiAlgoGroupNode.SphericalSampling, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.SphericalSampling)],
				[MinSG.MAR.MultiAlgoGroupNode.BruteForce, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.BruteForce)],
				[MinSG.MAR.MultiAlgoGroupNode.CHCpp, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.CHCpp)],
				[MinSG.MAR.MultiAlgoGroupNode.CHCppAggressive, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.CHCppAggressive)],
				[MinSG.MAR.MultiAlgoGroupNode.ColorCubes, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.ColorCubes)]
						  ]
		};
		
		return true;
	});
// --------------------------------------------------------------------------

//!	PathNode
if(MinSG.isSet($PathNode)) {
	NodeEditor.registerConfigPanelProvider(MinSG.PathNode, fn(node, panel) {
		panel += "*PathNode*";
		panel++;

		var displayWaypointsDataWrapper = DataWrapper.createFromFunctions(	node -> node.getMetaDisplayWaypoints,
																			node -> node.setMetaDisplayWaypoints);
		panel += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Display waypoints",
			GUI.TOOLTIP			:	"Enable/disable the display of the waypoints' meta objects",
			GUI.DATA_WRAPPER	:	displayWaypointsDataWrapper,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;

		var displayTimesDataWrapper = DataWrapper.createFromFunctions(	node -> node.getMetaDisplayTimes,
																		node -> node.setMetaDisplayTimes);
		panel += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Display times",
			GUI.TOOLTIP			:	"Enable/disable the display of the waypoints' time stamps",
			GUI.DATA_WRAPPER	:	displayTimesDataWrapper,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;

		return true;
	});
}
