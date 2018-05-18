/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2014-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
/****
 **	[Plugin:BlueSurfels] BlueSurfels/Plugin.escript
 **
 ** Experimental rendering technique.
 **/
 
var plugin = new Plugin({
		Plugin.NAME : 'BlueSurfels',
		Plugin.DESCRIPTION : "Experimental point rendering.",
		Plugin.VERSION : 0.2,
		Plugin.AUTHORS : "Claudius Jaehn, Sascha Brandt",
		Plugin.OWNER : "Claudius Jaehn",
		Plugin.LICENSE : "Proprietary", // this will change; but for now: Do not distribute!
		Plugin.REQUIRES : ['Effects'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn() {
	if(!MinSG.isSet($BlueSurfels)){
		Runtime.warn("BlueSurfels not available!");
		return false;
	}
	
//	loadOnce(__DIR__+"/SurfelGenerator.escript");
	Std.module( 'BlueSurfels/Utils' );
	
	Util.registerExtension('PADrend_Init',this->fn(){
		loadOnce(__DIR__+"/PointDebugRenderer.escript");
		loadOnce(__DIR__+"/SurfelRenderer.escript");
		loadOnce(__DIR__+"/SurfelRenderer2.escript");
		loadOnce(__DIR__+"/SurfelRenderer3.escript");
		loadOnce(__DIR__+"/StagedSurfelShader.escript");
		gui.register('PADrend_PluginsMenu.blueSurfels',{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "BlueSurfels...",
			GUI.ON_CLICK : this->openConfigWindow
		});
	});

	Util.registerExtension('Effects_PPEffects_querySearchPaths', fn(Array paths) {
		paths += __DIR__ + "/Effects/";
	});
  
	return true;
};

static getDirectionPresets = fn() {
	static presets;
	@(once){
		presets = new Map;

		foreach({ 
					"cube" : Rendering.createCube(),
					"tetrahderon" : Rendering.createTetrahedron(),
					"octrahedron" : Rendering.createOctahedron(),
					"icosahedron" : Rendering.createIcosahedron(),
					"dodecahedron" : Rendering.createDodecahedron(),
					"cube+down" : Rendering.createCube(),
				}	as var name, var mesh){
			var arr = [];
			var posAcc = Rendering.PositionAttributeAccessor.create(mesh);
			var numVertives = mesh.getVertexCount();
			for(var i = 0; i<numVertives; ++i){
				var dir = posAcc.getPosition(i).normalize();
				arr += dir;
			}
      if(name.endsWith("+down")) {
        arr += new Geometry.Vec3(0,-1,0);
      }
			presets[ name ] = arr;
		}
	}
	return presets;
};

plugin.openConfigWindow := fn(){

		
	var popup = gui.createPopupWindow( 380,480,"BlueSurfels" );
	var config = new ExtObject({
		$resolution : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.resolution',256),
		$maxAbsSurfels : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.maxAbsSurfels',10000),
		$medianDistCount : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.medianDistCount',1000),
		$samplesPerRound : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.samplesPerRound',160),
		$maxRelSurfels : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.maxRelSurfels',0.2),
		$useMaxRelSurfels : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.useMaxRelSurfels',true),
		$minimumComplexity : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.minimumComplexity',100000),
		$debugMode : new Std.DataWrapper(false),
		$smartMode : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.smartMode',false),
		$pureRandomStrategy : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.pureRandomStrategy',false),
		$traverseClosedNodes : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.traverseClosedNodes',false),
		$directionPresetName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.directionPresetName',"cube"),
		$minObjCount : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.minObjCount',64),
		$minOccFactor : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.minOccFactor',0.5),
	});
	var generatorFactory = [config] => fn(config){
    //Std._unregisterModule('BlueSurfels/SurfelGenerator');
		return (new (Std.module('BlueSurfels/SurfelGenerator')))
		//.setMaxAbsSurfels(config.maxAbsSurfels())
		.setMaxRelSurfels(config.maxRelSurfels())
		.setUseMaxRelSurfels(config.useMaxRelSurfels())
		.setDebugMode(config.debugMode())
		.setVerticalResolution(config.resolution())
		.setMinimumComplexity(config.minimumComplexity())
		//.setSmartMode(config.smartMode())
		//.setBenchmarkingEnabled(true)
    .setParameters(config.maxAbsSurfels(),config.medianDistCount(),config.samplesPerRound(),config.pureRandomStrategy(),false,true)
		.setTraverseClosedNodes(config.traverseClosedNodes())
    .setDirections(getDirectionPresets()[config.directionPresetName()])
		.setMinimumObjectCount(config.minObjCount())
		.setMinOcclusionFactor(config.minOccFactor());
	};
	
  var infoWrapper = new Std.DataWrapper("...");

	var updateInfo = [infoWrapper,popup]=>fn(infoWrapper,component,...){
		if(component.isDestroyed())
			return $REMOVE;
		var t = "";
		foreach(NodeEditor.getSelectedNodes() as var node){
			t += "Node:" + NodeEditor.getNodeString(node)+"\n";
			var surfels = MinSG.BlueSurfels.getLocalSurfels(node);
			if(surfels)
				t += "Surfels attached to node.\n";
			else{
				surfels = MinSG.BlueSurfels.locateSurfels(node);
				if(surfels){
					t += "Surfels attached to node's prototype.\n";
				}
			}
			if(surfels){
				t += "Num surfels: "+surfels.getVertexCount()+"\n";
				t += "Min. Dist.: "+node.findNodeAttribute('surfelMinDist')+"\n";
				t += "Median Dist.: "+node.findNodeAttribute('surfelMedianDist')+"\n";
			}
			t += "----\n";
		}
		infoWrapper(t);
	};
  popup.addOption({
    GUI.TYPE :	GUI.TYPE_SELECT,
    GUI.LABEL :	"Directions",
    GUI.OPTIONS :	{
      var dirOptions = [];
      foreach(getDirectionPresets() as var name, var dirs)
        dirOptions += [name , name+ " ("+dirs.count()+")"];
      dirOptions;
    },	
    GUI.DATA_WRAPPER : config.directionPresetName,
    GUI.SIZE :	[GUI.WIDTH_FILL_ABS, 10, 0]
  });
	popup.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [0,10],
		GUI.RANGE_STEPS : 10,
		GUI.RANGE_FN_BASE : 2,
		GUI.LABEL : "Resolution",
		GUI.TOOLTIP : "the resolution used for preprocessing",
		GUI.DATA_WRAPPER : config.resolution
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [1,1000],
		GUI.LABEL : "Samples per round",
		GUI.DATA_WRAPPER : config.samplesPerRound,
		GUI.TOOLTIP : "Samples per round",
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Max. abs. surfels",
		GUI.DATA_WRAPPER : config.maxAbsSurfels,
		GUI.TOOLTIP : "The absolute maximum for the number of created surfels",
		GUI.OPTIONS : [20000,10000,5000]
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "use max. rel. surfels",
		GUI.TOOLTIP : "This enables the following option",
		GUI.DATA_WRAPPER : config.useMaxRelSurfels,
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEPS : 100,
		GUI.LABEL : "Max. rel. surfels",
		GUI.TOOLTIP : "The relative maximum for the number of created surfels.\ndepends on the complexity of the processed subtree",
		GUI.DATA_WRAPPER : config.maxRelSurfels,
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Min. complexity",
		GUI.DATA_WRAPPER : config.minimumComplexity,
		GUI.TOOLTIP : "If a subtree has a complexity less than this,\nno surfels will be created",
		GUI.OPTIONS : [10000,100000,1000000]
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [1,1000],
    GUI.RANGE_STEP_SIZE : 1,
		GUI.LABEL : "Min. Object Count",
		GUI.DATA_WRAPPER : config.minObjCount,
		GUI.TOOLTIP : "Minimum number of surfel/geometry objects in subtree.",
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [0,1],
		GUI.LABEL : "Min. Occlusion",
		GUI.TOOLTIP : "Only generate surfels for inner nodes where at least this factor of the est. surface area is occluded.",
		GUI.DATA_WRAPPER : config.minOccFactor,
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Debug Mode",
		GUI.TOOLTIP : "enables displaying textures for debugging",
		GUI.DATA_WRAPPER : config.debugMode
	});
	/*popup.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Smart Mode",
		GUI.TOOLTIP : "enables automatic setting of some parameters (resolution & useMaxRelSurfels)",
		GUI.DATA_WRAPPER : config.smartMode
	});*/
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Pure random strategy",
		GUI.TOOLTIP : "Use pure random strategy.",
		GUI.DATA_WRAPPER : config.pureRandomStrategy,
	});
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Traverse closed nodes",
		GUI.TOOLTIP : "enables traversal of closed subtrees",
		GUI.DATA_WRAPPER : config.traverseClosedNodes
	});
	
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Replace selected nodes by surfels (debug).",
		GUI.ON_CLICK : [generatorFactory,updateInfo] => fn(generatorFactory,updateInfo){
			showWaitingScreen();
			out("Creating surfels ");
			var start = clock();
			var surfelGenerator = generatorFactory();
			foreach(NodeEditor.getSelectedNodes() as var node){
				var surfelInfo = surfelGenerator.createSurfelsForNode(node);
				var mesh = surfelInfo.mesh;
				if(!mesh)
					continue;
				//MinSG.BlueSurfels.attachSurfels(node,mesh);

				if(node.isA(MinSG.GeometryNode))
					node.setMesh(mesh);
				else{
					var newNode = new MinSG.GeometryNode(mesh);
					newNode.setRelTransformation(node.getRelTransformationMatrix());
					if(node == PADrend.getCurrentScene()){
						var scene = new MinSG.ListNode();
						scene += newNode;
						PADrend.registerScene(scene);
						PADrend.selectScene(scene);
					}else{
						node.getParent()+=newNode;
					}
				}
			}
			PADrend.message("Surfels created in "+(clock()-start)+"sec.");
			updateInfo();
		}
	});

	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create surfels for selected nodes.",
		GUI.ON_CLICK : [generatorFactory,updateInfo]=>fn(generatorFactory,updateInfo){
			showWaitingScreen();
			out("Creating surfels ");
			var start = clock();
			var surfelGenerator = generatorFactory();
			foreach(NodeEditor.getSelectedNodes() as var node){
				surfelGenerator.clearBenchmarkResults();
				var surfelInfo = surfelGenerator.createSurfelsForNode(node);
				var mesh = surfelInfo.mesh;
				if(mesh)
					MinSG.BlueSurfels.attachSurfels(node,surfelInfo);
				print_r(surfelGenerator.getBenchmarkResults());
				out(".");
			}
			PADrend.message("Surfels created in "+(clock()-start)+"sec.");
			updateInfo();
		}
	});
	
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Recursively update surfels for selected subtrees.",
		GUI.ON_CLICK : [generatorFactory,updateInfo]=>fn(generatorFactory,updateInfo){
			showWaitingScreen();
			out("Creating surfels (break with [esc]) ");
			var start = clock();
			var surfelGenerator = generatorFactory();
			foreach(NodeEditor.getSelectedNodes() as var node){
				var result = surfelGenerator.createSurfelsForTree(node);
				print_r(result);
			}
			PADrend.message("Surfels created in "+(clock()-start)+"sec.");
			updateInfo();
		}
	});
	
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Remove surfels from selected nodes.",
		GUI.ON_CLICK : [updateInfo]=>fn(updateInfo){
			var start = clock();
			var count = 0;
			foreach(NodeEditor.getSelectedNodes() as var node){
				if(MinSG.BlueSurfels.removeSurfels(node))
					++count;
			}
			PADrend.message(""+count+" Surfels removed.");
			updateInfo();
		}
	});

	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Remove surfels recursively.",
		GUI.ON_CLICK : [updateInfo]=>fn(updateInfo){
			var start = clock();
			var count = [0];
			foreach(NodeEditor.getSelectedNodes() as var node){
				node.traverse(count->fn(node){if(MinSG.BlueSurfels.removeSurfels(node))++this[0];} );
			}
			PADrend.message(""+count[0]+" Surfels removed.");
			updateInfo();
		}
	});
	
	popup.addOption({
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL 				:	"Export Surfel Meshes.",
		GUI.ON_CLICK			:	fn() {
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FOLDER_DIALOG,
				GUI.LABEL : "Export Surfel Meshes",
				GUI.DIR : ".",
				GUI.ON_ACCEPT  : fn(filename) {
					foreach(NodeEditor.getSelectedNodes() as var node)
						MinSG.BlueSurfels.saveSurfelsToMMF(node, new Util.FileName(filename));
				},
				
			});
		}
	});
	
	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Recursively compute median distances.",
		GUI.ON_CLICK : [generatorFactory,updateInfo]=>fn(generatorFactory,updateInfo){
			showWaitingScreen();
			out("Computing median distances (break with [esc]) ");
			var start = clock();
			foreach(NodeEditor.getSelectedNodes() as var node){        
				node.traverse(fn(node){          
          var surfels = MinSG.BlueSurfels.locateSurfels(node);
          if(surfels) {            
      			var d_1000 = MinSG.BlueSurfels.getMedianOfNthClosestNeighbours(surfels,1000,2);
            if(node.isInstance())
          		node = node.getPrototype();
            node.setNodeAttribute("surfelMedianDist", d_1000);
          }
        } );
			}
			PADrend.message("Median distances computing in "+(clock()-start)+"sec.");
			updateInfo();
		}
	});

	popup.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Compute Occlusion Factor.",
		GUI.ON_CLICK : [generatorFactory,updateInfo]=>fn(generatorFactory,updateInfo){
			showWaitingScreen();
			var surfelGenerator = generatorFactory();
			foreach(NodeEditor.getSelectedNodes() as var node){
				var occ = surfelGenerator.estOcclusionFactor(node);
				outln("Occlusion Factor: ", occ);
			}
			updateInfo();
		}
	});
	
	popup.addOption({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.DATA_WRAPPER : infoWrapper
	});
	
	Util.registerExtension('NodeEditor_OnNodesSelected', updateInfo);
	
	popup.addAction("Done.");
	popup.init();

	updateInfo();

};

// -------------------
return plugin;
// ------------------------------------------------------------------------------
