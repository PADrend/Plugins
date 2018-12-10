/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017 Sascha Brandt
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static NS = new Namespace;
static SurfelGenerator = Std.module("BlueSurfels/SurfelGenerator");
static SamplerRegistry = Std.module("BlueSurfels/GUI/SamplerRegistry");
static ScannerRegistry = Std.module("BlueSurfels/Config/SurfaceScannerConfig");
static Utils = Std.module("BlueSurfels/Utils");
static progressBar = new (Std.module('Tools/ProgressBar'));

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
	gui.register('BlueSurfels_Tabs.99_Test',[gui] => fn(gui){
		return [{
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.TAB_CONTENT : createTestPanel(gui),
				GUI.LABEL : "Tests"
		}];
	});
	gui.register('PADrend_PluginsMenu.blueSurfels', {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Blue Surfels...",
		GUI.ON_CLICK : [gui] => blueSurfelsGUI.toggleWindow
	});
	Util.registerExtension('PADrend_KeyPressed' , fn(evt) {
		if(evt.key == Util.UI.KEY_F6) {
			blueSurfelsGUI.toggleWindow(gui);
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
	var scannerConfig = ScannerRegistry.getCachedConfig();
	var samplerConfig = SamplerRegistry.getCachedConfig();
	
	var generatorFactory = [scannerConfig,samplerConfig] => fn(scannerConfig,samplerConfig) {
		var sampler = (SamplerRegistry.getSampler(samplerConfig.samplerName()));
		SamplerRegistry.applyConfig(sampler, samplerConfig);
		var scanner = new (ScannerRegistry.getScanner(scannerConfig.scannerName()));
		ScannerRegistry.applyConfig(scanner, scannerConfig);
		return (new SurfelGenerator)
			.setSampler(sampler)
			.setScanner(scanner);
	};
	
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
		GUI.LABEL : "Scanner",
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.OPTIONS : {
      var options = [];
      foreach(ScannerRegistry.getScanners() as var key, var value)
        options += [key];
      options;
		},
    GUI.DATA_WRAPPER : scannerConfig.scannerName,
	};	
	panel++;
		
	var refreshScannerGUI = Std.DataWrapper.createFromFunctions([scannerConfig] => fn(scannerConfig) {
		var provider = ScannerRegistry.getGUIProvider(scannerConfig.scannerName());
		return provider ? provider(scannerConfig) : [];
	});	
	panel += {
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.CONTENTS : refreshScannerGUI,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
		GUI.LAYOUT : (new GUI.FlowLayouter()).setMargin(10),
		GUI.PROPERTIES : panelProperties,
		GUI.FLAGS : GUI.BACKGROUND ,
	};
	panel++;	
	scannerConfig.scannerName.onDataChanged += [refreshScannerGUI] => fn(refreshScannerGUI, ...) { refreshScannerGUI.forceRefresh(); };
		
	panel += "----";
	panel++;
	
	panel += {
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.LABEL : "Sampler",
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.OPTIONS : {
      var options = [];
      foreach(SamplerRegistry.getSamplers() as var key, var value)
        options += [key];
      options;
		},
    GUI.DATA_WRAPPER : samplerConfig.samplerName,
	};	
	panel++;	
		
	var refreshSamplerGUI = Std.DataWrapper.createFromFunctions([samplerConfig] => fn(samplerConfig) {
		var provider = SamplerRegistry.getGUIProvider(samplerConfig.samplerName());
		return provider ? provider(samplerConfig) : [];
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
	
	samplerConfig.samplerName.onDataChanged += [refreshSamplerGUI] => fn(refreshSamplerGUI, ...) { refreshSamplerGUI.forceRefresh(); };
	
	panel += "----";
	panel++;
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels for selected nodes",
		GUI.ON_CLICK : [generatorFactory] => fn(generatorFactory) {
			progressBar.setDescription("Blue Surfels");
			progressBar.setSize(500, 32);
			progressBar.setToScreenCenter();
			progressBar.setMaxValue(NodeEditor.getSelectedNodes().count());
			progressBar.update(0);
		
			var generator = generatorFactory();
			foreach(NodeEditor.getSelectedNodes() as var index, var node) {
				generator.createSurfelsForNode(node);
			  print_r(generator.getStatistics());
				
				if(Utils.handleUserEvents()) {
					break;
				}
				progressBar.update(index+1);
			}
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels for selected nodes (limited)",
		GUI.ON_CLICK : [generatorFactory] => fn(generatorFactory) {
			progressBar.setDescription("Blue Surfels");
			progressBar.setSize(500, 32);
			progressBar.setToScreenCenter();
			progressBar.setMaxValue(NodeEditor.getSelectedNodes().count());
			progressBar.update(0);
		
			var generator = generatorFactory();
			var todo = new Set;
			foreach(NodeEditor.getSelectedNodes() as var index, var node) {
				var proto = node.getPrototype() ? node.getPrototype() : node;
				todo += proto;
			}
			
			foreach(todo.toArray() as var index, var node) {
				generator.createSurfelsForNode(node, true);
			  print_r(generator.getStatistics());
				
				if(Utils.handleUserEvents()) {
					break;
				}
				progressBar.update(index+1);
			}
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels for all leaf nodes",
		GUI.ON_CLICK : [generatorFactory] => fn(generatorFactory) {
			var generator = generatorFactory();
			generator.createSurfelsForLeafNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Recreate surfels for all nodes",
		GUI.ON_CLICK : [generatorFactory] => fn(generatorFactory) {
			var generator = generatorFactory();
			generator.recreateSurfelsForAllNodes(NodeEditor.getSelectedNodes());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
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
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
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
				t += "Surface: "+node.findNodeAttribute('surfelPacking')+"\n";
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

static createTestPanel = fn(gui) {
	var panel = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT : GUI.LAYOUT_FLOW
	});
	
	panel += "*Test Scenes*";
	panel++;
	
	var TestScenes = Std.module("BlueSurfels/Config/TestScenes");
	foreach(TestScenes.getScenes() as var scene) {
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	scene.name,
			GUI.ON_CLICK : scene.generate,
			GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
		};
		panel++;
	}	
	
	panel += "*Test Sampling*";
	panel++;
	
	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Compute Surface Area",
		GUI.ON_CLICK : fn() {
			var node = NodeEditor.getSelectedNode();
			if(!node) return;
			var surface = 0;
			foreach(MinSG.collectGeoNodes(node) as var n) {
				var s = n.getWorldTransformationSRT().getScale();
				surface += Rendering.computeSurfaceArea(n.getMesh()) * s;
			}
			PADrend.message("Total Surface Area: " + surface);
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Scan Visible Surface",
		GUI.ON_CLICK : fn() {
			var scanner = new (Std.module("BlueSurfels/Scanners/RasterScanner"));
			scanner.setDebug(true);
			//scanner.setResolution(16);
			scanner.scanSurface(NodeEditor.getSelectedNode());
			print_r(scanner.getStatistics());
		},
		GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0],
	};
	panel++;
	
	panel += "*Other*";
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
