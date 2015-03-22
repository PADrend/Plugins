/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
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
static CONFIG_PREFIX = 'NodeEditor_ObjConfig_';
 
static getBaseTypeEntries = fn( obj, baseType=void ){
	return	gui.createComponents( {	
		GUI.TYPE 		: 	GUI.TYPE_COMPONENTS, 
		GUI.PROVIDER	:	CONFIG_PREFIX + (baseType ? baseType : obj.getType().getBaseType()).toString(), 
		GUI.CONTEXT		:	obj 
	});
};

/*!	Node */
gui.register(CONFIG_PREFIX + MinSG.Node, fn(node){
	var entries = [];
	entries += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : NodeEditor.getString(node),
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.COLOR : NodeEditor.NODE_COLOR
	};

	entries += { GUI.TYPE : GUI.TYPE_NEXT_ROW, GUI.SPACING : 10};
	entries += '----';

	var id = PADrend.getSceneManager().getNameOfRegisteredNode(node);
	entries += GUI.NEXT_ROW;
	entries+={
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
	entries += GUI.NEXT_ROW;
	entries += {
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
	entries += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "is temporary",
		GUI.DATA_VALUE : node.isTempNode(),
		GUI.ON_DATA_CHANGED : node -> node.setTempNode,
		GUI.TOOLTIP : "If enabled, the node is not saved."
	};
	var SemanticObject = Std.require('LibMinSGExt/SemanticObject');
	entries += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "is semantic obj",
		GUI.DATA_VALUE : SemanticObject.isSemanticObject(node),
		GUI.ON_DATA_CHANGED : [node] => SemanticObject.markAsSemanticObject,
		GUI.TOOLTIP : "Mark to show if the node is a semantic object."
	};
	{// rendering Layers
		var accessibleLayers = 0xffff;
		for(var n=node.getParent();n;n=n.getParent() ){
			accessibleLayers &= n.getRenderingLayers();
		}
		
		entries += GUI.NEXT_ROW;
		var m = 1;
		for(var i=0;i<8;++i){
			var isAccessible = (accessibleLayers&m)>0;
			
			var dataWrapper = new DataWrapper( node.testRenderingLayer(m) );
			dataWrapper.onDataChanged += [node,m] => fn(node,m,b){
				node.setRenderingLayers( node.getRenderingLayers().setBitMask(m,b) );
			};
			m*=2;

			entries += { 
				GUI.LABEL : ""+(isAccessible ? i : "("+i+")")+"    ",
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.TOOLTIP : "Node is active on rendering layer #"+i+ (isAccessible ? "" :"\nNote: Path to does not provide this layer."),
				GUI.DATA_WRAPPER : dataWrapper
			};
		}
	}
	@(once) static PersistentNodeTrait = Std.require('LibMinSGExt/Traits/PersistentNodeTrait');
	
	if(node.isInstance()){
		var inheritedTraits = PersistentNodeTrait.getLocalPersistentNodeTraitNames(node.getPrototype());
		if(!inheritedTraits.empty()){
			entries += GUI.NEXT_ROW;
			entries += "PersistentNodeTraits (inherited): "+inheritedTraits.implode(", ");
		}
	}
	var localTraits = PersistentNodeTrait.getLocalPersistentNodeTraitNames(node);
	if(!localTraits.empty()){
		entries += GUI.NEXT_ROW;
		entries += "PersistentNodeTraits (local): "+localTraits.implode(", ");
	}
	if(node.isInstance()){
		entries += GUI.NEXT_ROW;
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Prototype of " + NodeEditor.getString(node.getPrototype()),
			GUI.ON_CLICK : [node] => fn(node){	NodeEditor.selectNode(node.getPrototype());	},
			GUI.SIZE : [GUI.WIDTH_FILL_ABS,10,15],
			GUI.TOOLTIP : "Select prototype."
		};		
	}
	entries += GUI.NEXT_ROW;
	entries += '----';
	entries += GUI.NEXT_ROW;
	return entries;
});

// ----

/*!	GroupNode	*/
gui.register(CONFIG_PREFIX + MinSG.GroupNode, fn(node){
	var entries = getBaseTypeEntries(node,MinSG.GroupNode.getBaseType());
	entries += "*GroupNode Info:*";

	entries += GUI.NEXT_ROW;
	var cb=gui.createCheckbox("is closed",node.isClosed());
	cb.node:=node;
	cb.onDataChanged = fn(data){
		node.setClosed(data);
	};
	entries += (cb);

	entries += GUI.NEXT_ROW;

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
			if(n.isA(MinSG.GeometryNode)){
				this.values.geonodes++;
				this.values.triangles += n.getTriangleCount();
				this.values.vertices += n.getVertexCount();
			}
			if(n.isA(MinSG.GroupNode))
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
	button.values := new ExtObject;
	button.resetValues();
	button.labels := new ExtObject;
	button.createLabels();

	entries += (button);
	entries += GUI.NEXT_ROW;

	entries += "Nodes:		 ";
	entries += GUI.NEXT_COLUMN;
	entries += (button.labels.nodes);
	entries += GUI.NEXT_ROW;

	entries += "GroupNodes:	";
	entries += GUI.NEXT_COLUMN;
	entries += (button.labels.groupnodes);
	entries += GUI.NEXT_ROW;

	entries += "GeometryNodes: ";
	entries += GUI.NEXT_COLUMN;
	entries += (button.labels.geonodes);
	entries += GUI.NEXT_ROW;

	entries += "Triangles:	 ";
	entries += GUI.NEXT_COLUMN;
	entries += button.labels.triangles;
	entries += GUI.NEXT_ROW;

	entries += "Vertices:	  ";
	entries += GUI.NEXT_COLUMN;
	entries += (button.labels.vertices);
	entries += GUI.NEXT_ROW;

	entries += "States:		";
	entries += GUI.NEXT_COLUMN;
	entries += (button.labels.states);
	entries += GUI.NEXT_ROW;

	entries += {
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
	entries += GUI.NEXT_ROW;
	return entries;
});

// ----

/*!	GeometryNode	*/
gui.register(CONFIG_PREFIX + MinSG.GeometryNode, fn(node){
	var entries = getBaseTypeEntries(node,MinSG.GeometryNode.getBaseType());

	entries += "*GeometryNode Info:*";
	entries += GUI.NEXT_ROW;
	entries += "Vertices: " + node.getVertexCount();
	entries += GUI.NEXT_ROW;
	entries += "Triangles: " + node.getTriangleCount();
	entries += GUI.NEXT_ROW;
	var mesh = node.getMesh();
	if(mesh) {
		entries+='----';
		entries += GUI.NEXT_ROW;
		entries += mesh.toString();
		entries += GUI.NEXT_ROW;

		
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
																		newVertexDesc.appendAttribute(attribute.getName(), attribute.getNumValues(), attribute.getDataType(),attribute.getNormalize());
																	}
																}
																Rendering.convertVertices(this[0], newVertexDesc);
															},
										GUI.WIDTH		:	50
									},
									{	GUI.TYPE		:	GUI.TYPE_NEXT_ROW	}
								];
		}
		
		entries += attributesPanel;
		entries += GUI.NEXT_ROW;
		entries += "Vertex Size: " + mesh.getVertexDescription().getVertexSize();
		entries += GUI.NEXT_ROW;
		entries += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Use indexData",
			GUI.DATA_PROVIDER : mesh -> mesh.isUsingIndexData,
			GUI.ON_DATA_CHANGED : mesh -> mesh.setUseIndexData
		};
		entries += GUI.NEXT_ROW;
	}

	entries += GUI.NEXT_ROW;
	entries+='----';
	entries += GUI.NEXT_ROW;
	// mesh file selector
	var data = new ExtObject({$filename : mesh?mesh.getFileName().toString() : "", $node : node });
	entries += {
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
	entries += GUI.NEXT_ROW;
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Reload mesh",
		GUI.ON_CLICK : data -> fn(){
			var filename = this.filename;
			if(!filename.empty()) {
				var path = PADrend.getSceneManager().locateFile(filename);
				PADrend.message("Load Mesh \"" + filename + "\" ("+path+")...");

				if(path){
					showWaitingScreen();
					var geoNode = MinSG.loadModel(path);
					if(geoNode.isA(MinSG.GeometryNode)) {
						var mesh = geoNode.getMesh();
						mesh.setFileName(filename);
						this.node.setMesh(mesh);
						outln("\nDone.");
						return;
					}
				}
				Runtime.warn("Could not load single mesh from " + filename);
				
			}
		},
		GUI.TOOLTIP		:	"Reload the GeometryNode's mesh from the given file."
	};
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Save mesh...",
		GUI.ON_CLICK : [data] => fn(data){
			var mesh = data.node.getMesh();
			if(!mesh){
				Runtime.warn("No Mesh available!");
				return;
			}
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "Filename for mesh export",
				GUI.ENDINGS : [".mmf",".ply"],
				GUI.FILENAME : (mesh.getFileName().getFile().empty() || mesh.getFileName().getEnding()!='mmf') ? "new.mmf" : mesh.getFileName().getFile(),
				GUI.DIR : mesh.getFileName().getDir().empty() ? PADrend.getDataPath() : mesh.getFileName().getDir(),
				GUI.ON_ACCEPT : [mesh]=>fn(mesh,filename) {
					outln("Exporting ",mesh,"->",filename);
					showWaitingScreen();
					Rendering.saveMesh(mesh,filename);
				}
			});
		},
		GUI.TOOLTIP		:	"Save the mesh as .mmf or .ply file."
	};
	
	entries += GUI.NEXT_ROW;
	return entries;
});

// ----

/*!	Light	*/
gui.register(CONFIG_PREFIX + MinSG.LightNode, fn(node){
	var entries = getBaseTypeEntries(node,MinSG.LightNode.getBaseType());

	var dummy = new ExtObject;
	dummy.node := node;

	entries += "*LightNode Info:*";

	entries += GUI.NEXT_ROW;

	dummy.type := gui.createRadioButtonSet();
	dummy.type.addOption(MinSG.LightNode.POINT, "Point Light");
	dummy.type.addOption(MinSG.LightNode.SPOT, "Spot Light");
	dummy.type.addOption(MinSG.LightNode.DIRECTIONAL, "Directional Light");
	dummy.type.onDataChanged = dummy->fn(data){if(disabled)return; node.setLightType(data); reset();};

	entries += dummy.type;
	entries += GUI.NEXT_ROW;

	dummy.ambient := gui.create({
		GUI.TYPE : GUI.TYPE_COLOR,
		GUI.SIZE :  [180,100],
		GUI.DATA_VALUE : node.getAmbientLightColor(),
		GUI.ON_DATA_CHANGED : dummy->fn(data){if(disabled)return; node.setAmbientLightColor(data); reset();},
		GUI.LABEL : "Ambient"
	});
	entries += dummy.ambient;
	entries += GUI.NEXT_COLUMN;

	dummy.diffuse := gui.create({
		GUI.TYPE : GUI.TYPE_COLOR,
		GUI.SIZE :  [180,100],
		GUI.DATA_VALUE : node.getDiffuseLightColor(),
		GUI.ON_DATA_CHANGED : dummy->fn(data){if(disabled)return; node.setDiffuseLightColor(data); reset();},
		GUI.LABEL : "Diffuse"
	});

	entries += dummy.diffuse;
	entries += GUI.NEXT_ROW;

	dummy.specular := gui.create({
		GUI.TYPE : GUI.TYPE_COLOR,
		GUI.SIZE :  [180,100],
		GUI.DATA_VALUE : node.getSpecularLightColor(),
		GUI.ON_DATA_CHANGED : dummy->fn(data){if(disabled)return; node.setSpecularLightColor(data); reset();},
		GUI.LABEL : "Specular"
	});

	entries += dummy.specular;
	entries += GUI.NEXT_COLUMN;

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

	entries += (attenuationPanel);
	entries += GUI.NEXT_ROW;

	var spotPanel = gui.createPanel(180, 80, GUI.AUTO_LAYOUT | GUI.LOWERED_BORDER);
	spotPanel.setMargin(1);
	entries += (spotPanel);

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

	return entries;
});

// ----

if(MinSG.isSet($ParticleSystemNode)){

/*!	ParticleSystemNode	*/
gui.register(CONFIG_PREFIX + MinSG.ParticleSystemNode, fn(node){
	var entries = getBaseTypeEntries(node,MinSG.ParticleSystemNode.getBaseType());

	entries += "*ParticleSystemNode Info:*";
	entries += GUI.NEXT_ROW;

	// create GUI
	// 1. create renderer selector
	var cb = gui.createDropdown(180, 15);
	cb.addOption(MinSG.ParticleSystemNode.POINT_RENDERER, "Point renderer");
	cb.addOption(MinSG.ParticleSystemNode.BILLBOARD_RENDERER, "Billboard renderer");
	cb.setData(node.getRendererType());
	cb.onDataChanged = [node]=>fn(node,data){
		node.setRenderer(data);
	};
	entries += cb;

	// 2. change max particles
	entries += { GUI.TYPE : GUI.TYPE_NEXT_ROW, GUI.SPACING : 5};
	{
		entries += "Max. particle count: ";
	}
	entries += GUI.NEXT_ROW;
	{
		var maxParticleSlider = gui.createExtSlider([100,16],[100,10000],200);
		entries += maxParticleSlider;
		maxParticles.setValue(node.getMaxParticleCount());
		maxParticles.onDataChanged = [node]=>fn(node,data){
			node.setMaxParticleCount(data);
		};
	}

	return entries;
});
}

/*!	MultiAlgoGroupNode	*/
if(MinSG.isSet($MAR))
	
	gui.register(CONFIG_PREFIX + MinSG.MAR.MultiAlgoGroupNode, fn(node){
		var entries = getBaseTypeEntries(node,MinSG.MultiAlgoGroupNode.getBaseType());

		entries += "*MultiAlgoGroupNode Info:*";
		entries += GUI.NEXT_ROW;
		
		entries += {
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
		
		return entries;
	});
// --------------------------------------------------------------------------

//!	PathNode
if(MinSG.isSet($PathNode)) {
	gui.register(CONFIG_PREFIX + MinSG.PathNode, fn(node){
		var entries = getBaseTypeEntries(node,MinSG.PathNode.getBaseType());

		entries += "*PathNode*";
		entries += GUI.NEXT_ROW;

		var displayWaypointsDataWrapper = DataWrapper.createFromFunctions(	node -> node.getMetaDisplayWaypoints,
																			node -> node.setMetaDisplayWaypoints);
		entries += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Display waypoints",
			GUI.TOOLTIP			:	"Enable/disable the display of the waypoints' meta objects",
			GUI.DATA_WRAPPER	:	displayWaypointsDataWrapper,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		entries += GUI.NEXT_ROW;

		var displayTimesDataWrapper = DataWrapper.createFromFunctions(	node -> node.getMetaDisplayTimes,
																		node -> node.setMetaDisplayTimes);
		entries += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Display times",
			GUI.TOOLTIP			:	"Enable/disable the display of the waypoints' time stamps",
			GUI.DATA_WRAPPER	:	displayTimesDataWrapper,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		entries += GUI.NEXT_ROW;

		return entries;
	});
}

return true;
