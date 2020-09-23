/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static NS = new Namespace;
static SurfelGenerator = Std.module("BlueSurfels/SurfelGenerator");
static Utils = Std.module("BlueSurfels/Utils");
static Plotter = Std.module("Tools/Plotter");
static NodePreviewImage = Std.module("Tools/NodePreviewImage");
static DataTable = Std.module("LibUtilExt/DataTable");

// -------------------------------------------------------------------

static samplerRegistry = new Map;  // samplerName -> sampler
static samplerGUIRegistry = new Map; // samplerName -> guiProvider(obj)

NS.registerSampler := fn(sampler, String displayableName=""){
	if(displayableName.empty())
		displayableName = sampler._printableName;
	samplerRegistry[displayableName] = sampler;
};

NS.registerSamplerGUI := fn(sampler, provider) {
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait);
	samplerGUIRegistry[sampler._printableName] = provider;
};

NS.getSamplers := fn() { return samplerRegistry.clone(); };
NS.getSampler := fn(samplerName){ return samplerRegistry[samplerName]; };
NS.createSampler := fn(samplerName){ return new (samplerRegistry[samplerName]); };
NS.getGUIProvider := fn(samplerName){ return samplerGUIRegistry[samplerName]; };

NS.createConfigWrapper := fn(name, defaultValue, callback=void) {
	var config = Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.' + name, defaultValue);
	if(callback) {
		config.onDataChanged += callback;
		config.forceRefresh();
	}
	return config;
};

// -------------------------------------------------------------------

NS.initGUI := fn(fui) {
	gui.register('BlueSurfels_Tabs.10_Blue_Surfels',[gui] => fn(gui){
		return [{
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.TAB_CONTENT : createSurfelPanel(gui),
				GUI.LABEL : "Sampling"
		}];
	});
	gui.register('BlueSurfels_Tabs.20_Info',[gui] => fn(gui){
		return [{
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.TAB_CONTENT : createInfoPanel(gui),
				GUI.LABEL : "Info"
		}];
	});
	gui.register('BlueSurfels_Tabs.30_Utils',[gui] => fn(gui){
		return [{
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.TAB_CONTENT : createAnalysisPanel(gui),
				GUI.LABEL : "Analysis"
		}];
	});
	gui.register('BlueSurfels_Tabs.40_Utils',[gui] => fn(gui){
		return [{
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.TAB_CONTENT : createUtilPanel(gui),
				GUI.LABEL : "Utils"
		}];
	});
	
	gui.register('PADrend_PluginsMenu.blueSurfels', {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Blue Surfels...",
		GUI.ON_CLICK : [gui] => NS.toggleWindow
	});
	
	Util.registerExtension('PADrend_KeyPressed' , fn(evt) {
		if(evt.key == Util.UI.KEY_F6) {
			NS.toggleWindow(gui);
			return true;
		}
		return false;
	});
};

// -------------------------------------------------------------------

NS.toggleWindow := fn(gui) {
	@(once) static surfelWindow;
	
	if(surfelWindow) {
		surfelWindow.toggleVisibility();
		if(surfelWindow.isVisible())
			surfelWindow.restoreLastTab();
		return;
	}
	
	surfelWindow = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.LABEL : "Blue Surfels"
	});

	Std.Traits.addTrait(surfelWindow, Std.module('LibGUIExt/Traits/StorableRectTrait'),
						Std.DataWrapper.createFromEntry(PADrend.configCache, "BlueSurfels.winRect", [200,100,420,410]));
	var lastTab = Std.DataWrapper.createFromEntry(PADrend.configCache, "BlueSurfels.tab", 0);
	
	var tabPanel = gui.create({
		GUI.TYPE : GUI.TYPE_TABBED_PANEL,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
	});
	surfelWindow += tabPanel;
	tabPanel.addTabs('BlueSurfels_Tabs');
	
	surfelWindow.onWindowClosed := [tabPanel, lastTab] => fn(tabPanel, lastTab) {
		lastTab(tabPanel.getActiveTabIndex());
	};
	surfelWindow.restoreLastTab := [tabPanel, lastTab] => fn(tabPanel, lastTab) {
		tabPanel.setActiveTabIndex(lastTab());
	};
	tabPanel.setActiveTabIndex(lastTab());
};

// -------------------------------------------------------------------

static createSurfelPanel = fn(gui) {	
	var samplerConfig = new ExtObject({
		$samplerName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.sampler','GreedyCluster'),
		$currentSampler : void,
	});
	samplerConfig.currentSampler = NS.createSampler(samplerConfig.samplerName());
		
	static panelProperties = [
		new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,gui._createRectShape(new Util.Color4ub(230,230,230,255),new Util.Color4ub(150,150,150,255),true))
	];
	
	var panel = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW
	});
	
	panel += "----";
	panel++;
		
	panel += {
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.LABEL : "Sampler",
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.OPTIONS : {
			var options = [];
			foreach(NS.getSamplers() as var key, var value)
				options += [key];
			options;
		},
		GUI.DATA_WRAPPER : samplerConfig.samplerName,
	};	
	panel++;	
		
	var refreshSamplerGUI = Std.DataWrapper.createFromFunctions([samplerConfig] => fn(config) {
		var provider = NS.getGUIProvider(config.samplerName());
		return provider ? provider(config.currentSampler) : [];
	});
	
	panel += {
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.CONTENTS : refreshSamplerGUI,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
		GUI.LAYOUT : (new GUI.FlowLayouter()).setMargin(10),
		GUI.PROPERTIES : panelProperties,
		GUI.FLAGS : GUI.BACKGROUND ,
	};
	panel++;
	
	samplerConfig.samplerName.onDataChanged += [samplerConfig, refreshSamplerGUI] => fn(config, refreshSamplerGUI, name) {
		config.currentSampler = NS.createSampler(config.samplerName());
		refreshSamplerGUI.forceRefresh(); 
	};
	//samplerConfig.samplerName.forceRefresh();
	
	panel += "----";
	panel++;
	
	// ------------------------------------
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels for selected nodes",
		GUI.ON_CLICK : [samplerConfig] => fn(config) {
			var statistics = SurfelGenerator.createSurfelsForNodes(NodeEditor.getSelectedNodes(), config.currentSampler);
			outln("\nSurfel Statistics (saved to ./surfel_stats.json): ");
			print_r(SurfelGenerator.accumulateStatistics(statistics));
			Util.saveFile("./surfel_stats.json", toJSON(statistics));
			// reselect nodes to trigger info update
			NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
		
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels Hierarchy",
		GUI.ON_CLICK : [samplerConfig] => fn(config) {
			var statistics = SurfelGenerator.createSurfelHierarchy(NodeEditor.getSelectedNodes(), config.currentSampler);
			outln("\nSurfel Statistics (saved to ./surfel_stats.json): ");
			print_r(SurfelGenerator.accumulateStatistics(statistics));
			Util.saveFile("./surfel_stats.json", toJSON(statistics));
			// reselect nodes to trigger info update
			NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
		
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels for all leaf nodes",
		GUI.ON_CLICK : [samplerConfig] => fn(config) {
			var statistics = SurfelGenerator.createSurfelsForLeafNodes(NodeEditor.getSelectedNodes(), config.currentSampler);
			outln("\nSurfel Statistics (saved to ./surfel_stats.json): ");
			print_r(SurfelGenerator.accumulateStatistics(statistics));
			Util.saveFile("./surfel_stats.json", toJSON(statistics));
			// reselect nodes to trigger info update
			NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Recreate surfels for all nodes",
		GUI.ON_CLICK : [samplerConfig] => fn(config) {
			var statistics = SurfelGenerator.recreateSurfelsForAllNodes(NodeEditor.getSelectedNodes(), config.currentSampler);
			outln("\nSurfel Statistics (saved to ./surfel_stats.json): ");
			print_r(SurfelGenerator.accumulateStatistics(statistics));
			Util.saveFile("./surfel_stats.json", toJSON(statistics));
			// reselect nodes to trigger info update
			NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += "----";
	panel++;
		
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Remove surfels from selected nodes",
		GUI.ON_CLICK : fn() {
			var count = 0;
			foreach(NodeEditor.getSelectedNodes() as var node){
				if(Utils.removeSurfels(node)) ++count;
			}
			PADrend.message(""+count+" Surfels removed.");
			// reselect nodes to trigger info update
			NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
		
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Remove surfels recursively",
		GUI.ON_CLICK : fn() {
			var count = [0];
			foreach(NodeEditor.getSelectedNodes() as var node){
				node.traverse(count->fn(node){if(Utils.removeSurfels(node))++this[0];} );
			}
			PADrend.message(""+count[0]+" Surfels removed.");
			// reselect nodes to trigger info update
			NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += "----";
	panel++;
	
	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL 				:	"Export Surfel Meshes.",
		GUI.ON_CLICK			:	fn() {
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FOLDER_DIALOG,
				GUI.LABEL : "Export Surfel Meshes",
				GUI.DIR : PADrend.getSceneManager().getWorkspaceRootPath(),
				GUI.ON_ACCEPT  : fn(filename) {
					foreach(NodeEditor.getSelectedNodes() as var node)
						Utils.saveSurfelsToMMF(node, new Util.FileName(filename));
				},
				
			});
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
		
	return panel;
};

// -------------------------------------------------------------------

static createInfoPanel = fn(gui) {
	var panel = gui.create({
		GUI.TYPE :	GUI.TYPE_CONTAINER,
		GUI.SIZE :	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT :	GUI.LAYOUT_FLOW
	});
	var infoWrapper = new Std.DataWrapper("");
				
	var updateInfo = [infoWrapper, panel]=>fn(infoWrapper, component, ...) {
		if(component.isDestroyed())
			return $REMOVE;
		var t = "";
		foreach(NodeEditor.getSelectedNodes() as var node){
			t += "Node:" + NodeEditor.getNodeString(node)+"\n";
			var surfels = Utils.getLocalSurfels(node);
			if(surfels)
				t += "Surfels attached to node.\n";
			else{
				surfels = Utils.locateSurfels(node);
				if(surfels){
					t += "Surfels attached to node's prototype.\n";
				}
			}
			if(surfels){
				t += "Num surfels: "+surfels.getVertexCount()+"\n";
				t += "Packing: "+node.findNodeAttribute('surfelPacking')+"\n";
			}
			t += "----\n";
		}
		infoWrapper(t);
	};
	
	panel += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.DATA_WRAPPER : infoWrapper,
	};
	panel++;
		
	Util.registerExtension('NodeEditor_OnNodesSelected', updateInfo);
	updateInfo();	
	
	return panel;
};

// -------------------------------------------------------------------

static createAnalysisPanel = fn(gui) {
	var panel = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW
	});
	
	var config = new ExtObject({
		$resolution : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.resolution', 1024),
		$directionPresetName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.directions', "cube"),
		$infoWrapper : new Std.DataWrapper(""),
		$samples : new Std.DataWrapper(1000),
		$image : gui.createImage(new Util.Bitmap(256,256,Util.Bitmap.RGB)),
		$meanImg : new NodePreviewImage(256, 128),
		$varImg : new NodePreviewImage(256, 128),
		$radData : void,
		$diffFactor : new Std.DataWrapper(10),
		$adaptive : new Std.DataWrapper(false),
		$geodesic : new Std.DataWrapper(true),
	});
		
	panel += "*Sampling Analysis*";
	panel++;
		
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Samples",
		GUI.RANGE : [1,5],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.RANGE_FN_BASE : 10,
		GUI.DATA_WRAPPER : config.samples,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 40, 0],
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Max",
		GUI.ON_CLICK : [config] => fn(config) {
			var node = NodeEditor.getSelectedNode();
			if(!node) return;
			var surfels = Utils.locateSurfels(node);
			if(!surfels) return;
			config.samples(surfels.getVertexCount());
		},
		GUI.SIZE : [GUI.WIDTH_ABS, 30, 0],
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Diff. Factor",
		GUI.RANGE : [1,100],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.DATA_WRAPPER : config.diffFactor,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Adaptive",
		GUI.DATA_WRAPPER : config.adaptive,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Geodesic",
		GUI.DATA_WRAPPER : config.geodesic,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "DDA",
		GUI.ON_CLICK : [config] => fn(config) {
			var node = NodeEditor.getSelectedNode();
			if(!node) return;
			var surfels = Utils.locateSurfels(node);
			if(!surfels) return;
			var count = config.samples();
			var surface = Utils.computeTotalSurface(node);
			
			var minDistances = MinSG.BlueSurfels.getMinimalVertexDistances(surfels, count, config.geodesic());
			var r_min = minDistances.min() * 0.5;
			var r_mean = minDistances.reduce(fn(sum,k,v){ return sum+v;},0) / count * 0.5;
			var r_max = (surface/(2*3.sqrt()*count)).sqrt();
			var quality = r_min/r_max;
			var quality_mean = r_mean/r_max;
			
			var diff_max = config.diffFactor() * r_max;
			var bitmap = MinSG.BlueSurfels.differentialDomainAnalysis(surfels,diff_max,256,count,config.geodesic(),config.adaptive());
			var radial = MinSG.BlueSurfels.getRadialMeanVariance(bitmap);
			Util.normalizeBitmap(bitmap);
			bitmap = Util.blendTogether(Util.Bitmap.RGB,[bitmap]);
			config.image.updateData(bitmap);
			
			var radialMean = new Map;
			var variance = new Map;
			foreach(radial as var i, var r) {
				var d = i / 256 * diff_max;
				radialMean[d] = r.mean;
				if(d >= r_min)
				variance[d] = (r.variance > 0) ? (10 * r.variance.log(10)) : 0;
			}
			
			var tmpData = new DataTable("d");
			tmpData.addDataRow("mean","",radialMean,"#00ff00");
			config.meanImg.setNode(Plotter.plot(tmpData));
			tmpData = new DataTable("d");
			tmpData.addDataRow("mean","",variance,"#ff0000");
			config.varImg.setNode(Plotter.plot(tmpData));
			
			config.radData = new DataTable("d");
			config.radData.addDataRow("mean","",radialMean,"#00ff00");
			config.radData.addDataRow("variance","",variance,"#ff0000");
			
			var info = "";
			info += "Surface: " + surface + "\n";
			info += "Opt. Radius: " + r_max + "\n";
			info += "Radius: " + r_min + "\n";
			info += "Mean Radius: " + r_mean + "\n";
			info += "Quality: " + quality + "\n";
			info += "Mean Quality: " + quality_mean + "\n";
			config.infoWrapper(info);
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Radius Stats",
		GUI.ON_CLICK : [config] => fn(config) {
			var node = NodeEditor.getSelectedNode();
			if(!node) return;
			var surfels = Utils.locateSurfels(node);
			if(!surfels) return;
			var count = config.samples();
			var directions = Utils.getDirectionPresets()[config.directionPresetName()];
			var surface = Utils.computeTotalSurface(node);
			
			var sampler = new (Std.module('BlueSurfels/Sampler/GreedyCluster'));
			sampler.setResolution(config.resolution());
			sampler.setDirections(directions);
			sampler.setTargetCount(count);
			sampler.setSeed(42);
			var optSurfels = sampler.sample(node);
			
			var r_min = MinSG.BlueSurfels.getMinimalVertexDistances(surfels, count, config.geodesic()).min() * 0.5;
			var r_ref = MinSG.BlueSurfels.getMinimalVertexDistances(optSurfels, count, config.geodesic()).min() * 0.5;
			var r_max = (surface/(2*3.sqrt()*count)).sqrt();
			var quality = r_min/r_max;
			var optQuality = r_ref/r_max;
			var relQuality = r_min/r_ref;
						
			var info = "";
			info += "Surface: " + surface + "\n";
			info += "Opt. Radius: " + r_max + "\n";
			info += "Ref. Radius: " + r_ref + "\n";
			info += "Radius: " + r_min + "\n";
			info += "Ref. Quality: " + optQuality + "\n";
			info += "Quality: " + quality + "\n";
			info += "Rel. Quality: " + relQuality + "\n";
			config.infoWrapper(info);
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Clear",
		GUI.ON_CLICK : [config] => fn(config) {
			config.image.updateData(new Util.Bitmap(256,256,Util.Bitmap.RGB));
			config.meanImg.clear();
			config.varImg.clear();
			config.radData = void;
			config.infoWrapper("");
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	};
	panel++;
	panel+="----";
	panel++;
	panel += config.image;
	//panel++;	
	panel += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.DATA_WRAPPER : config.infoWrapper,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
	};
	panel++;
	panel += config.meanImg.getImage();
	panel++;
	panel += config.varImg.getImage();
	panel++;
	
	Std.Traits.addTrait(config.image, Std.module('LibGUIExt/Traits/ContextMenuTrait'),300);
	config.image.contextMenuProvider += [{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Save image",
		GUI.ON_CLICK : [config.image] => fn(image) {
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "Save image",
				GUI.ENDINGS : [".png"],
				GUI.ON_ACCEPT : [image] => fn(image, filename) { 
					Util.saveBitmap(image.getImageData().getBitmap(), filename);
				}
			});
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Save Data",
		GUI.ON_CLICK : [config] => fn(config) {
			if(!config.radData)
				return;
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "Save Data",
				GUI.ENDINGS : [".csv"],
				GUI.ON_ACCEPT : [config] => fn(config, filename) {
					config.radData.exportCSV(filename, ",");
				}
			});
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	}];
	
	return panel;
};

// -------------------------------------------------------------------

static createUtilPanel = fn(gui) {
	var panel = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW
	});
	
	panel += "*Test Scenes*";
	panel++;
	
	var TestScenes = Std.module("BlueSurfels/Tools/TestScenes");
	foreach(TestScenes.getScenes() as var scene) {
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	scene.name,
			GUI.ON_CLICK : scene.generate,
			GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
		};
		panel++;
	}	
		
	panel += "*Utils*";
	panel++;	
	
	Util.executeExtensions('BlueSurfels_SurfelUtils', panel);
	
	return panel;
};

return NS;
