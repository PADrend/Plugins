/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2008-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:SceneAnalyzer] GASP/SceneAnalyzerGUI.escript
 ** GASP window.
 **/
static SceneAnalyzerGUI = new Namespace;

//GASP.defaultCombineExpressions:=[
//    "v[0]-v[1]",
//    "v.avg()",
//    "(v[0]-v[1]).abs()"];

static GASP = Std.module('SceneAnalyzer/GASP');
static GASPManager = Std.module('SceneAnalyzer/GlobalGASPManager');

static gaspPath = systemConfig.getValue('SceneAnalyzer.path',".");

SceneAnalyzerGUI.createWindow:=fn(posX,posY) {

	@(once){
		gui.register('SceneAnalyzer_Tabs.10_gasps',fn(){
			var page = gui.create({	GUI.TYPE : GUI.TYPE_PANEL	});
			createOverviewPanel(page);
			page.nextRow(20);
			createCreationPanel(page);
			return [{
					GUI.TYPE : GUI.TYPE_TAB,
					GUI.TAB_CONTENT : page,
					GUI.LABEL : "GASPs"
			}];
		});
		gui.register('SceneAnalyzer_Tabs.20_evaluator',fn(){
			return [{
					GUI.TYPE : GUI.TYPE_TAB,
					GUI.TAB_CONTENT : Util.requirePlugin('Evaluator').createConfigPanel(),
					GUI.LABEL : "Evaluator"
			}];
		});
		gui.register('SceneAnalyzer_Tabs.30_sampling',fn(){
			var page = gui.create({	GUI.TYPE : GUI.TYPE_PANEL	});
			createSamplingPanel(page);
			return [{
					GUI.TYPE : GUI.TYPE_TAB,
					GUI.TAB_CONTENT : page,
					GUI.LABEL : "Sampling"
			}];
		});		
		gui.register('SceneAnalyzer_Tabs.40_display',fn(){
			var page = gui.create({	GUI.TYPE : GUI.TYPE_PANEL	});
			createDisplayPanel(page);
			return [{
					GUI.TYPE : GUI.TYPE_TAB,
					GUI.TAB_CONTENT : page,
					GUI.LABEL : "Display"
			}];
		});
	}

	var window = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
//		GUI.FLAGS : GUI.ONE_TIME_WINDOW,
		GUI.LABEL : "Scene Analyzer"
	});

	Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/StorableRectTrait'),
						Std.DataWrapper.createFromEntry(PADrend.configCache, "SceneAnalyzer.winRect", [200,100,420,410]));

	var tabPanel = gui.create({
		GUI.TYPE:	GUI.TYPE_TABBED_PANEL,
		GUI.SIZE:	GUI.SIZE_MAXIMIZE
	});
	window += tabPanel;
	tabPanel.addTabs('SceneAnalyzer_Tabs');	
	
	tabPanel.setActiveTabIndex(0);
	return window;
};

// -------------------------------------------------------------------

/*!	(internal) Called by createWindow(...) */
static createOverviewPanel = fn(panel){
	panel+="----";
	panel++;
	panel+="*Globally Approximated Scene Properties (GASPs)*";
	panel++;

	//	----
	var toolbar=[];
	toolbar+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "load",
		GUI.ON_CLICK : fn(){
			GUI._openFileDialog("Load GASP",gaspPath, [".classification",".gasp"], fn(filename){
				if(filename.find(';')!==false){ // multiple files
					foreach(filename.split(';') as var f) thisFn(f);
					return;
				}
				out("Load GASP \"",filename,"\"...");
				var c=GASPManager.load(filename);
				GASPManager.selectGASP(c);
			});
		}
	};
	toolbar+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "save",
		GUI.ON_CLICK : fn(){
			var storeSamplePoints = new Std.DataWrapper(true);
			
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "Save GASP",
				GUI.DIR : gaspPath,
				GUI.FILENAME : GASPManager.getSelectedGASP().name(),
				GUI.ENDINGS : [".gasp"],
				GUI.ON_ACCEPT  : [storeSamplePoints]=>fn(storeSamplePoints,filename){
					GASPManager.save( GASPManager.getSelectedGASP(), filename, storeSamplePoints());
				},
				GUI.OPTIONS : [{
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.LABEL : 'Store sample points',
					GUI.DATA_WRAPPER : storeSamplePoints
				}]
			});	
		}
	};
	var data = new ExtObject({	$gasps:[], $combineExp:"c[0]+c[1]" });
	
	toolbar+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "combine",
		GUI.ON_CLICK : [data]=>fn(data){
			if(data.gasps.empty())
				return;
						out("\n---------------\n");
			print_r(data.gasps);
			print_r(data.combineExp);
			var combineFunction = eval("fn(Array c){return ("+data.combineExp+");};");
			out("#",combineFunction([1]),"\n");
			print_r(combineFunction);
						out("\n---------------\n");
			GASPManager.combineGASPs(data.gasps,combineFunction);
			
		}
	};
	toolbar += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.DATA_OBJECT : data,
		GUI.DATA_ATTRIBUTE : $combineExp
	};
	panel.add(gui.createToolbar(400,20,toolbar,80));

	//	----

	panel++;

	var list = gui.create({
		GUI.TYPE : GUI.TYPE_LIST,
		GUI.WIDTH : 400,
		GUI.HEIGHT : 120,
		GUI.ON_DATA_CHANGED : fn(data){
			if(!data.empty())
				GASPManager.selectGASP(data[0]);
		},
		GUI.DATA_OBJECT : data,
		GUI.DATA_ATTRIBUTE : $gasps
	});
	
	list.refresh := fn(Array gasps){
		this.clear();
		foreach(gasps as var gasp) {
			var tooltip = "";
			var attributes = gasp.getDescription();
			if(attributes) {
				foreach(attributes as var key, var value) {
					tooltip+=key+": "+value+"\n";
				}
			}

			this.addOption( gasp, 
			{
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.WIDTH : 400,
				GUI.HEIGHT : 18,
				GUI.TOOLTIP : tooltip,
				GUI.CONTENTS : [
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_WRAPPER : gasp.name
					},
					{
						GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
						GUI.LABEL : "X",
						GUI.FLAGS : GUI.FLAT_BUTTON,
						GUI.ICON : '#DestroySmall',
						GUI.WIDTH : 20,
						GUI.POSITION : [300,0],
						GUI.ON_CLICK : [gasp]=>fn(gasp){
								GASPManager.removeGASPs([gasp]);
						}
					},
					{
						GUI.TYPE : GUI.TYPE_MENU,
						GUI.LABEL : "Attr...",
						GUI.WIDTH : 50,
						GUI.POSITION : [335,0],
						GUI.MENU_WIDTH : 305,
						GUI.MENU : [gasp]=>getPropertyMenu
					}
				
				
				]
			});
		}
	};
	
	GASPManager.onGASPListChanged += list->list.refresh;
	GASPManager.onGASPChanged += list->fn(gasp){ setData([gasp]); };
	panel += list;
	list.refresh( GASPManager.getGASPs() );
	
	panel++;
};

/*!	(internal) Called by "Attr"-button in the gasp overview.*/
static getPropertyMenu = fn(GASP gasp){
	var list = gui.create({
		GUI.TYPE : GUI.TYPE_LIST,
		GUI.SIZE : [300,100]
	});
	
	// init entries
	fn(list,gasp){
		list.clear();

		var attributes = gasp.getDescription();
		if(attributes) {
			foreach(attributes as var key,var value){
				list += {
					GUI.TYPE : GUI.TYPE_TEXT,
					GUI.LABEL : key,
					GUI.DATA_VALUE : value,
					GUI.ON_DATA_CHANGED : [gasp,key]=>fn(gasp,key,newValue){
						gasp.applyDescription( {key:(newValue=="(REMOVE)"?void:newValue)} );
					},
					GUI.OPTIONS : [value,"(REMOVE)"],
					GUI.TOOLTIP : "Attribute: "+key+"\nNote: Enter (REMOVE) to remove the entry."
				};
			}
		}
		list += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.DATA_VALUE : "",
			GUI.ON_DATA_CHANGED : [gasp,list,thisFn]=>fn(gasp,list,refreshFun, newKey){
				newKey = newKey.trim();
				if(!newKey.empty()){
					gasp.applyDescription( {newKey:""} );
					refreshFun(list,gasp);
				}
			},
			GUI.TOOLTIP : "Enter new attribute's key."
		};
	} (list,gasp);
	
	return [
		"*"+gasp.name()+"*",
		'----',	
		list
	];


};

// -------------------------------------------------------------------

/*!	(internal) Called by createWindow(...) */
static createCreationPanel = fn(panel){
	panel+="----";
	panel++;
	panel+="*Create a new gasp*";
	panel++;
	panel+="Bounding box:  cx,cy,cz,  width,height,depth";
	panel++;

	var config = new ExtObject({
		$bb : Std.DataWrapper.createFromEntry( PADrend.configCache,'SceneAnalyzer.bb',GASPManager.defaultBB.front() ),
		$scale : Std.DataWrapper.createFromEntry( PADrend.configCache,'Tools.ScreenShot.bbScale',1.0 ),
		$resolution : Std.DataWrapper.createFromEntry( PADrend.configCache,'SceneAnalyzer.resolution',GASPManager.defaultResolutions.front() ),
		$factor : Std.DataWrapper.createFromEntry( PADrend.configCache,'SceneAnalyzer.factor',32 ),
	});

	panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.DATA_WRAPPER : config.bb,
		GUI.WIDTH  :200,
		GUI.OPTIONS : GASPManager.defaultBB
	};


	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [0.0,3.0],
		GUI.RANGE_STEPS : 30,
		GUI.LABEL : "Scale",
		GUI.WIDTH  :150,
		GUI.DATA_WRAPPER : config.scale
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Set",
		GUI.WIDTH : 30,
		GUI.ON_CLICK : [config]=>fn(config){
			var bb = PADrend.getCurrentScene().getWorldBB();
			var center = bb.getCenter();
			var scale = config.scale();
			config.bb( ""+center.getX().round() + ", " + center.getY().round() + ", " + center.getZ().round() + ",    "
					+ scale * bb.getExtentX().ceil() + ", " + scale * bb.getExtentY().ceil() + ", " + scale * bb.getExtentZ().ceil());
		},
		GUI.TOOLTIP : "Set the bounding box to the scaled scene's bounding box."
	};

	panel++;

	panel+="Max resolution: x,y,z";
	panel++;

	panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.DATA_WRAPPER : config.resolution,
		GUI.WIDTH  :200,
		GUI.OPTIONS : GASPManager.defaultResolutions
	};


	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [1,64],
		GUI.RANGE_STEPS : 63,
		GUI.LABEL : "Factor",
		GUI.WIDTH  :150,
		GUI.DATA_WRAPPER : config.factor
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Set",
		GUI.WIDTH : 30,
		GUI.ON_CLICK : [config]=>fn(config){
			var a = parseJSON("["+config.bb()+"]");
			config.resolution("" + (a[3]*config.factor().floor()) + ","+ (a[4]*config.factor().floor()) + ","+ (a[5]*config.factor().floor()));
		},
		GUI.TOOLTIP : "Set the resolution according to the given bounding box."
	};

	panel++;
	panel += gui.createContainer(320,0);


	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "create",
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.WIDTH  : 60,
		GUI.HEIGHT : 25 ,
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 5,5],	
		GUI.ON_CLICK : [config]=>fn(config){
			var params = "("+config.bb()+"),"+config.resolution();
			var c=GASPManager.createGASP(params);
			GASPManager.registerGASP(c);
			GASPManager.selectGASP(c);
		}
	};


//        page.add(b=gui.createButton(75,15,"Info"));
//        b.onClick=fn(){
//            if(!GASPManager.getSelectedGASP())
//                return;
//            var c=GASPManager.getSelectedGASP();
//            out("\nMinValue:",c.getMinValue(),"\n");
//            out("MinValue:",c.getMaxValue(),"\n");
//            var avg=c.getAvgValue();
//            out("AvgValue:",avg,"\n\n");
//            out("Deviation:",c.getVariance(avg).sqrt(),"\n\n");
//			return true;
//        };
//

};

// -------------------------------------------------------------------
/*!	(internal) Called by createWindow(...) */
static createSamplingPanel = fn(panel){
	// sampler selector
	var dd=gui.createDropdown(150,15);
	panel+=dd;
	panel++;
	foreach(GASPManager.getCSamplerList() as var sampler){
		dd.addOption(sampler,sampler.getName());
	}
	dd.setData(GASPManager.getCSampler());
	dd.onDataChanged = fn(data){
		GASPManager.selectCSampler(getData());
	};
	GASPManager.selectedCSampler.onDataChanged += dd->fn(c){	setData(c);	};

	panel+="----";
	panel++;
	panel.samplerPanel:=void;
	panel.placeholder:=gui.createPlaceholder(1,1);
	panel+=panel.placeholder;
	panel.refresh:=fn(){
		if(samplerPanel){
			out(numChildren()," ",samplerPanel);
			remove(samplerPanel);
			out(numChildren()," ");
		}
		var s=GASPManager.getCSampler();
		if(s){
			out(numChildren()," ");
			this.samplerPanel=GASPManager.getCSampler().getConfigPanel();
			insertAfter(samplerPanel,placeholder);
			out(numChildren(),"\n");
		}
	};
	GASPManager.selectedCSampler.onDataChanged += panel->fn(...){	refresh();	};
	panel++;
	panel+="----";
	panel++;
	panel+=gui.createPlaceholder(-130);
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "sample...",
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.ON_CLICK : fn(){
			GASPManager.executeSampling();
		}
	};
	panel.refresh();
};

// -------------------------------------------------------------------
//! (internal)
static extractColorProfile = fn(Array valueWrappers,Array colorTextWrappers,dirCombineFunctionCode){
	
	var values = [];
	var colors = [];
	foreach(valueWrappers as var i, var valueWrapper){
		var ct = colorTextWrappers[i]();
		if( ct.empty()  )
			continue;
		var color;
		try {
			color=parseJSON(ct);
		}catch(e){
			out(e);
			continue;
		}
		if(valueWrapper().isA(Number) && color.isA(Array) ){
			values += valueWrapper();
			colors += color;
		}

	}
	var dirCombineFunction = dirCombineFunctionCode.empty() ? false : eval(dirCombineFunctionCode);
	return new ExtObject( { 
			$colors : colors, 
			$values : values, 
			$dirCombineFunction : dirCombineFunction} );
	
};

/*!	(internal) Called by createWindow(...) */
static createDisplayPanel = fn(panel){
	// --------------------------------
	// rendering flags

	panel+="----";
	panel++;
	panel+="*Flags*";
	panel++;

	var options={
		MinSG.BOUNDING_BOXES:"Show bounding boxes",
		MinSG.ValuatedRegionNode.NO_BLENDING:"No blending",
		MinSG.NO_GEOMETRY:"Hide"
	};

	foreach(options as var value,var text){
		panel+={
			GUI.TYPE : GUI.TYPE_BIT,
			GUI.DATA_BIT : value,
			GUI.LABEL : text,
			GUI.DATA_OBJECT : GASP,
			GUI.DATA_ATTRIBUTE : $gaspRenderingFlags
		};
		panel++;
	}
	panel+={
			GUI.TYPE : GUI.TYPE_BIT, 
			GUI.LABEL : "Hide Sample Points",
			GUI.DATA_BIT : MinSG.NO_GEOMETRY,
			GUI.DATA_OBJECT : GASP,
			GUI.DATA_ATTRIBUTE : $samplingPointRenderingFlags
	};
	panel+={
			GUI.TYPE : GUI.TYPE_BIT, 
			GUI.LABEL : "Hide delaunay 2d",
			GUI.DATA_BIT : MinSG.NO_GEOMETRY,
			GUI.DATA_OBJECT : GASP,
			GUI.DATA_ATTRIBUTE : $delaunay2dRenderingFlags
	};
	panel+={
			GUI.TYPE : GUI.TYPE_BIT, 
			GUI.LABEL : "Hide delaunay 3d",
			GUI.DATA_BIT : MinSG.NO_GEOMETRY,
			GUI.DATA_OBJECT : GASP,
			GUI.DATA_ATTRIBUTE : $delaunay3dRenderingFlags
	};
	panel++;
	// --------------------------------
	// colors

	panel+="----";
	panel++;
	panel+="*Color profile*";
	panel++;

//	panel += "Value | Color (RGBA) & [height] ";

	static colorValues = 		[	new Std.DataWrapper(0), new Std.DataWrapper(0.5), new Std.DataWrapper(1), new Std.DataWrapper(0), new Std.DataWrapper(0)];
	static colorColorStrings = [	new Std.DataWrapper("[0.0, 0.0, 1.0, 0.1,   1.0]"),new Std.DataWrapper("[0.0, 0.0, 0.0, 0.0,   1.0]"),new Std.DataWrapper("[1.0, 0.0, 0.0, 0.1,   1.0]"),
									new Std.DataWrapper("[0.0, 0.0, 0.0, 0.1,   1.0]"),new Std.DataWrapper("[0.0, 0.0, 0.0, 0.1,   1.0]")	];
	
	
	foreach( colorValues as var i,var colorValue){
		panel += {
			GUI.TYPE : GUI.TYPE_LABEL,
			GUI.LABEL : "["+i+"]",
			GUI.WIDTH : 40
		};
		panel += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.DATA_WRAPPER : colorValue,
			GUI.TOOLTIP : "Scene property value\nOptions show min and max values",
			GUI.SIZE : [GUI.WIDTH_FILL_REL, 0.3, 0],
			GUI.OPTIONS_PROVIDER : fn(){
				var options = [0];
				var c = GASPManager.getSelectedGASP();
				if(c){
					var min = c.getMinValue();
					var max = c.getMaxValue();
					for(var f=0;f<=1.001;f+=0.25)
						options += max*f + (1-f) * min;
				}
				return options;
			}
		};
		panel += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.DATA_WRAPPER : colorColorStrings[i],
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 10, 0],
			GUI.TOOLTIP : "[r,g,b,a,  height]",
			GUI.OPTIONS : [ "[0.0, 0.0, 0.0, 0.1,   1.0]", "[1.0, 0.0, 0.0, 0.1,   1.0]", "[1.0, 1.0, 0.0, 0.1,   1.0]",
							"[0.0, 1.0, 0.0, 0.1,   1.0]", "[0.0, 1.0, 1.0, 0.1,   1.0]", "[0.0, 0.0, 1.0, 0.1,   1.0]" , "[1.0, 0.0, 1.0, 0.1,   1.0]" ]
			
		};
		panel++;
	}

	panel += {
		GUI.TYPE : GUI.TYPE_MENU,
		
		GUI.LABEL : "Presets",
		GUI.MENU_PROVIDER : fn(){
			var entries = [];
			static loadColorProfile = fn(filename){
				foreach(parseJSON(Util.loadFile(filename)) as var i,var c)
					colorColorStrings[i](c);
			};
			foreach( Util.getFilesInDir(".",[".colors"]) as var f ){
				entries += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : f,
					GUI.ON_CLICK : [f]=>loadColorProfile
				};
			}
			
			return entries.append([
				'----',
				{   
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "load",
					GUI.ON_CLICK : fn() {
						GUI._openFileDialog("Load ColorProfile",gaspPath,".colors",loadColorProfile);
					}
				},
				{   
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "save",
					GUI.ON_CLICK : fn() {
						var save=fn(filename){
							var a=[];
							foreach(colorColorStrings as var s)
								a += s();
							IO.filePutContents(filename,toJSON(a));
						};
						GUI._openFileDialog("Save ColorProfile",gaspPath,".colors",save);
					}
				},

			]);
		},
		GUI.MENU_WIDTH:200
	};

	panel++;



	var dirCombineCode = Std.DataWrapper.createFromEntry(PADrend.configCache,'SceneAnalyzer.dirCombine',"" );
	panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "DirCombine-Function:",
		GUI.DATA_WRAPPER : dirCombineCode,
		GUI.OPTIONS : ["","fn(Array v){return v.max();};","fn(Array v){return v[0];};"]
	};
	panel++;

	
	panel+=gui.createPlaceholder(-440);
	
	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Delaunay 2D",
		GUI.TOOLTIP : "Create or update the visualization of the sampling points",
		GUI.ON_CLICK : [dirCombineCode] => SceneAnalyzerGUI->fn(dirCombineCode){
			var colorProfile = extractColorProfile( colorValues, colorColorStrings, dirCombineCode().trim() );
			GASPManager.getSelectedGASP().createDelaunay2d(colorProfile);
		}
	};	
	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Delaunay 3D",
		GUI.TOOLTIP : "Create or update the visualization of the sampling points",
		GUI.ON_CLICK : [dirCombineCode] => SceneAnalyzerGUI->fn(dirCombineCode){
			var colorProfile = extractColorProfile( colorValues, colorColorStrings, dirCombineCode().trim() );
			GASPManager.getSelectedGASP().createDelaunay3d(colorProfile);			
		}
	};	
	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Update samples",
		GUI.TOOLTIP : "Create or update the visualization of the sampling points",
		GUI.ON_CLICK : [dirCombineCode] => SceneAnalyzerGUI->fn(dirCombineCode){
			var colorProfile = extractColorProfile( colorValues, colorColorStrings, dirCombineCode().trim() );
			GASPManager.getSelectedGASP().updateSampleVisualization(colorProfile);			
		}
	};
	
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "colorize",
		GUI.FONT : GUI.FONT_ID_LARGE,
		GUI.ON_CLICK: [dirCombineCode] => SceneAnalyzerGUI->fn(dirCombineCode){
			var colorProfile = extractColorProfile( colorValues, colorColorStrings, dirCombineCode().trim() );

			var c = GASPManager.getSelectedGASP();
			if(!c)
				return;

			try{
				c.recalculateColors(c.rootNode,colorProfile );
			}catch(e){
				out(e);
			}
			out("done\n");
		}
	};

//	// TEMP!!!!!!!!!!!!!!!!!!!!!!!!!!! Needs
//	Listener.add(Listener.CSAMPLER_NEW_REGIONS,fn(evt,regions){
//		var c = GASPManager.getSelectedGASP();
//		try{
//			foreach(regions as var r){
//				c.recalculateColors(r, SceneAnalyzerGUI.colorValues, SceneAnalyzerGUI.colors,SceneAnalyzerGUI.colordirCombineFunction);
//			}
//		}catch(e){
//			out(e);
//		}
//	});
};

return SceneAnalyzerGUI;
//
