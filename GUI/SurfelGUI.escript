/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static NS = new Namespace;
static SurfelGenerator = Std.module("BlueSurfels/SurfelGenerator");
static Utils = Std.module("BlueSurfels/Utils");

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
		$bitmaps : [],
		$image : gui.createImage(new Util.Bitmap(256,256,Util.Bitmap.RGB)),
		$diffFactor : new Std.DataWrapper(10),
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
		GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
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
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "compute",
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
			
			var r = MinSG.BlueSurfels.getMinimalVertexDistances(surfels, count).min() * 0.5;
			var r_opt = MinSG.BlueSurfels.getMinimalVertexDistances(optSurfels, count).min() * 0.5;
			var r_max = (surface/(2*3.sqrt()*count)).sqrt();
			var quality = r/r_max;
			var relQuality = r/r_opt;
			
			var diff_max = config.diffFactor() * r_max;
			var bitmap = MinSG.BlueSurfels.differentialDomainAnalysis(surfels,diff_max,256,count,true);
			config.bitmaps = [bitmap];
			var avgBmp = Util.blendTogether(Util.Bitmap.RGB,config.bitmaps);
			config.image.updateData(avgBmp);
			
			var info = "";
			info += "Surface: " + surface + "\n";
			info += "Max. Radius: " + r_max + "\n";
			info += "Opt. Radius: " + r_opt + "\n";
			info += "Radius: " + r + "\n";
			info += "Quality: " + quality + "\n";
			info += "Rel. Quality: " + relQuality + "\n";
			config.infoWrapper(info);
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Average",
		GUI.ON_CLICK : [config] => fn(config) {
			var node = NodeEditor.getSelectedNode();
			if(!node) return;
			var surfels = Utils.locateSurfels(node);
			if(!surfels) return;
			var count = config.samples();
			var surface = Utils.computeTotalSurface(node);
						
			var r = MinSG.BlueSurfels.getMinimalVertexDistances(surfels, count).min() * 0.5;
			var r_max = (surface/(2*3.sqrt()*count)).sqrt();
			var quality = r/r_max;
			
			var diff_max = config.diffFactor() * r_max;
			var bitmap = MinSG.BlueSurfels.differentialDomainAnalysis(surfels,diff_max,256,count,true);
			config.bitmaps += bitmap;
			var avgBmp = Util.blendTogether(Util.Bitmap.RGB, config.bitmaps);
			config.image.updateData(avgBmp);
			
			var info = "";
			info += "Runs: " + config.bitmaps.count() + "\n";
			info += "Surface: " + surface + "\n";
			info += "Max. Radius: " + r_max + "\n";
			info += "Radius: " + r + "\n";
			info += "Quality: " + quality + "\n";
			config.infoWrapper(info);
		},
		GUI.SIZE :	[GUI.WIDTH_ABS, 100, 0],
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Clear",
		GUI.ON_CLICK : [config] => fn(config) {
			config.bitmaps.clear();
			config.image.updateData(new Util.Bitmap(256,256,Util.Bitmap.RGB));
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
	
	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Shrink surfel meshes",
		GUI.ON_CLICK : fn() {			
			var surfelNodes = MinSG.collectNodesReferencingAttribute(NodeEditor.getSelectedNode(), 'surfels');
			var set = new Std.Set;
			foreach(surfelNodes as var n) 
				set += n.findNodeAttribute('surfels');
			var i=0;
			foreach(set as var s) {
				Rendering.shrinkMesh(s, true);
				out("\r", ++i ,"/", set.count());
			}
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	return panel;
};

return NS;
