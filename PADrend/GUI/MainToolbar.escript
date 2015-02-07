/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 David Maicher
 * Copyright (C) 2011 Lukas Kopecki
 * Copyright (C) 2009-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] PADrend/GUI_Toolbars.escript
 ** 2007-11-09
 **/

var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI/MainToolbar',
		Plugin.DESCRIPTION : "PADrend's main toolbar (enable with [F1]).",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

plugin.toolbarEnabled := void;
plugin.toolbar := void;

plugin.init @(override) := fn(){

	this.registerStdToolbarEntries();
	toolbarEnabled = DataWrapper.createFromConfig(PADrend.configCache,'PADrend.GUI.mainToolbarEnabled',true);
	toolbarEnabled.onDataChanged += this->fn(value){
		if(value){
			this.createToolbar();
		}else if(toolbar){
			var t = toolbar;
			toolbar = void;
			t.close();
			PADrend.message("The main toolbar is enabled by pressing [F1].");
		}
	};

	registerExtension( 'PADrend_KeyPressed',this->fn(evt){ // if the toolbar is closed and [F1] is pressed, re-create the toolbar.
		if(evt.key == Util.UI.KEY_F1 && !toolbarEnabled()) {
			toolbarEnabled(true);
			return true;
		}
		return false;
	});
	registerExtension( 'PADrend_Init',this->fn(){
		// show main toolbar
		out(("Creating main toolbar").fillUp(40));
		toolbarEnabled.forceRefresh();
		outln("ok.");
	
	},Extension.LOW_PRIORITY*2.0); // execute after all menus and tabs are registered

	return true;
};
 
 
//! Create the window containing the main toolbar
plugin.createToolbar := fn(){

	var entries = gui.createComponents('PADrend_MainToolbar');
	var width = entries.count()*22+10;

	this.toolbar = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.SIZE : [width,40],
		GUI.LABEL : "InteractionTools",
		GUI.FLAGS : GUI.HIDDEN_WINDOW | GUI.ONE_TIME_WINDOW,
		GUI.ON_WINDOW_CLOSED : this->fn(){		toolbarEnabled(false);	},
		GUI.POSITION : [0,-10],
		GUI.CONTENTS : [gui.createToolbar(width+20,20,entries)]
	});
	gui.windows['Toolbar'] = toolbar;
};


plugin.registerStdToolbarEntries := fn() {

	// ----------------------------------------------------------------------------------
    // File...
    gui.registerComponentProvider('PADrend_MainToolbar.00_file',{
		GUI.TYPE		:	GUI.TYPE_MENU,
		GUI.LABEL		:	"File",
		GUI.ICON		:	"#FileSmall",
		GUI.ICON_COLOR	:	GUI.BLACK,
		GUI.MENU		:	'PADrend_FileMenu'
	});
	
	static addToRecentSceneList = fn(filename){
		var fileList = Std.DataWrapper.createFromEntry( PADrend.configCache, 'PADrend.recentScenes',[] );
		var arr = [filename].append(fileList().removeValue(filename));
		if(arr.count()>10)
			arr = arr.slice(0,10);
			fileList( arr );
//						fileList( [filename].append(arr fileList(.removeValue("filename")).slice(0,10) );
	};
	static getRecentSceneList = fn(){
		return PADrend.configCache.get('PADrend.recentScenes',[] );
	};
	static openSaveSceneDialog = fn() {
		var scene = PADrend.getCurrentScene();
		
		var filename = scene.isSet($filename) ? 
								scene.filename : 
								PADrend.getScenePath()+"/"+Std.require('LibMinSGExt/NodeMetaInfo').queryMetaInfo_Title(scene,"New")+".minsg";

		gui.openDialog({
			GUI.TYPE :		GUI.TYPE_FILE_DIALOG,
			GUI.LABEL :		"Save scene",
			GUI.ENDINGS :	[".minsg", ".dae", ".DAE"],
			GUI.FILENAME : 	filename,
			GUI.ON_ACCEPT : [scene] => fn(scene, filename){
						
				var save = [scene,filename] => fn(scene,filename){
					showWaitingScreen();
					PADrend.message("Save scene \""+filename+"\"");
					if(filename.endsWith(".dae")||filename.endsWith(".DAE")) {
						MinSG.SceneManagement.saveCOLLADA(filename,PADrend.getRootNode());
					} else {
						MinSG.SceneManagement.saveMinSGFile( PADrend.getSceneManager(),filename,[scene]);
					}
					scene.filename :=  filename;
					addToRecentSceneList(filename);

					// Saving the file may alter its properties (e.g. name), so re-select it to provoke an update where necessary.
					executeExtensions('PADrend_OnSceneSelected',scene );
				};
				
				if(Util.isFile(filename)){
					gui.openDialog({
						GUI.TYPE :				GUI.TYPE_POPUP_DIALOG ,
						GUI.LABEL :				"Overwrite?",
						GUI.ACTIONS : 			[ ["overwrite",save] , ["cancel"]],
						GUI.OPTIONS : 			["The file '"+filename+"' exists."],
						GUI.SIZE : 		 		[320,80]
					});
				}else{
					save();
				}
			}
		});
	};

	// scenes subgroup
	gui.registerComponentProvider('PADrend_FileMenu.10_scene',fn(){
		var entries = [
		{
			GUI.LABEL		:	"Load Scene ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, and read a scene from that file.\nSupported types: .minsg, .dae",
			GUI.ON_CLICK	:	fn() {
				var config = new ExtObject({
					$scale : DataWrapper.createFromValue(1.0),
					$importOptions : PADrend.configCache.getValue('PADrend.importOptions', 
											MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY | 
											MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY),
					$sceneManager : new Std.DataWrapper(void)
				});
				gui.openDialog({
					GUI.TYPE : GUI.TYPE_FILE_DIALOG,
					GUI.LABEL : "Load Scene ...",
					GUI.DIR : PADrend.getScenePath(),
					GUI.ENDINGS : [".minsg", ".dae", ".DAE"],
					GUI.ON_ACCEPT  : [config] => fn(config,filename){
						// Collect flags.
						out("Load Scene \"",filename,"\"...");
						PADrend.message("Load scene \""+filename+"\"...");

						PADrend.configCache.setValue('PADrend.importOptions', config.importOptions);
						var node=PADrend.loadScene(filename, /*sceneNode,*/ config.importOptions, config.sceneManager());
						if(!node){
							PADrend.message("Loading scene '"+filename+"' failed.");
						}else{
							PADrend.message("Scene loaded '"+filename+"'");
							PADrend.selectScene(node);
								
							var scale = config.scale();
							if(scale!=1.0)
								node.scale(scale);
							
							addToRecentSceneList( filename );
						}

					},
					GUI.OPTIONS : [
						"Options",
						'----',
						{
							GUI.TYPE			:	GUI.TYPE_NUMBER,
							GUI.LABEL			:	"Scale:",
							GUI.DATA_WRAPPER	:	config.scale,
							GUI.OPTIONS			:	[1.0,0.1,0.01,0.001],
							GUI.SIZE			:	[GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,15,15],
						},
						{
							GUI.LABEL			:	"Reuse exisiting states",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$importOptions,
							GUI.DATA_BIT		:	MinSG.SceneManagement.IMPORT_OPTION_REUSE_EXISTING_STATES
						},
						{
							GUI.LABEL			:	"Cache textures in TextureRegistry",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$importOptions,
							GUI.DATA_BIT		:	MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY
						},
						{
							GUI.LABEL			:	"Cache meshes in MeshRegistry (file)",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$importOptions,
							GUI.DATA_BIT		:	MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY,
							GUI.TOOLTIP : "If GeometryNodes use the same mesh file (during this import process), \nload and use the mesh only once."
							
						},
						{
							GUI.LABEL			:	"Cache meshes in MeshRegistry (hash)",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$importOptions,
							GUI.DATA_BIT		:	MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_HASHING_REGISTRY,
							GUI.TOOLTIP : "If GeometryNodes use the same mesh based on its structure (during this import process), \nload and use the mesh only once."
						},
						{
							GUI.LABEL			:	"COLLADA: Invert transparency",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$importOptions,
							GUI.DATA_BIT		:	MinSG.SceneManagement.IMPORT_OPTION_DAE_INVERT_TRANSPARENCY,
							GUI.TOOLTIP : "Use this for scenes exported from 3dMax"
						},
						{
							GUI.LABEL			:	"ID-Namspace",
							GUI.TYPE			:	GUI.TYPE_SELECT,
							GUI.SIZE			:	[GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,15,15],
							GUI.DATA_WRAPPER	:	config.sceneManager,
							GUI.OPTIONS_PROVIDER : fn(){
								var options = [ ];
								foreach( PADrend.SceneManagement.getNamedMapOfAvaiableSceneManagers() as var sceneManager,var name)
									options += [sceneManager,name];
								options += [true,"create new namespace"];
								return options;
							},
							GUI.TOOLTIP : "Use existing id-namespace or create a new one.\nNode and State ids are unique in a namespace and are \n lost when Nodes are transferred into another namespace."
						},
					]
				});
			}

		},
		{
			GUI.TYPE		: 	GUI.TYPE_MENU,
			GUI.LABEL		:	"Recent scenes",
			GUI.MENU : fn(){
				var entries = [];
				foreach( getRecentSceneList() as var filename)
					entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : (new Util.FileName(filename)).getFile(),
						GUI.ON_CLICK : [filename] => fn(filename){
							var n = PADrend.loadScene(filename,  PADrend.configCache['PADrend.importOptions']);
							if(n){
								PADrend.selectScene(n);
								addToRecentSceneList(filename);
							}
						},
						GUI.TOOLTIP : filename
					};
				return entries;
			}
									
		}];
		if(PADrend.getCurrentScene().isSet($filename)){
			entries += {
				GUI.TYPE		:	GUI.TYPE_CRITICAL_BUTTON,
				GUI.LABEL		:	"Save scene",
				GUI.ON_CLICK	:	fn() {
					var scene = PADrend.getCurrentScene();
					var filename = scene.isSet($filename) ? scene.filename : void;
					if(filename){
						showWaitingScreen();
						PADrend.message("Save scene \""+filename+"\"");
						if(filename.endsWith(".dae")||filename.endsWith(".DAE")) {
							MinSG.SceneManagement.saveCOLLADA(filename,PADrend.getRootNode());
						} else {
							MinSG.SceneManagement.saveMinSGFile( PADrend.getSceneManager(),filename,[scene]);
						}
						// Re-select it to provoke an update where necessary.
						executeExtensions('PADrend_OnSceneSelected',scene );
					}else{
						openSaveSceneDialog();
					}
				},
				GUI.TOOLTIP : "Save scene as "+ PADrend.getCurrentScene().filename
			};
		}
		entries +={
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Save scene as ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, and write the current scene into that file.\nSupported types: .minsg, .dae",
			GUI.ON_CLICK	:	openSaveSceneDialog
		};
		return entries;
		}
	);

	// meshes subgroup
	gui.registerComponentProvider('PADrend_FileMenu.20_meshes',[
		'----',
		{
			GUI.LABEL		:	"Load Mesh ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, read a mesh from that file, and add it to the current scene.\nSupported types: .mmf, .obj, .ply, .md2, .mvbo, .ngc",
			GUI.ON_CLICK	:	fn() {
				var config = new ExtObject;
				config.meshOptions := 0;
				config.id := new Std.DataWrapper("");
				
				gui.openDialog({
					GUI.TYPE : GUI.TYPE_FILE_DIALOG,
					GUI.LABEL : "Load Mesh",
					GUI.DIR : PADrend.getDataPath(),
					GUI.ENDINGS : [".obj",".ply",".mmf",".mvbo",".MVBO",".ngc", ".md2", ".MD2", ".xyz"],
					GUI.ON_ACCEPT  : [config] => fn(config,filename){
						out("Load Mesh \"",filename,"\"...");
						PADrend.message("Load Mesh \""+filename+"\"...");
						showWaitingScreen();
						var start = clock();

						var n = MinSG.loadModel(filename, config.meshOptions);
						if(!n)
							return;
						PADrend.getCurrentScene().addChild(n);
						var id = config.id().trim();
						if(id.empty()){
							PADrend.getSceneManager().registerNode(id,n);
						}	out("\nDone. ",(clock()-start)," sek\n");

						out("\nDone. ",(clock()-start)," sek\n");
					},
					GUI.ON_FILES_CHANGED : [config.id] => fn( id, arr ){
						id( arr.empty() ? "" : arr.front() );
					},
					GUI.OPTIONS : [
						"*Mesh options*",
						{
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.LABEL			:	"AUTO_CENTER",
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$meshOptions,
							GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER
						},						
						{
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.LABEL			:	"AUTO_CENTER_BOTTOM",
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$meshOptions,
							GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER_BOTTOM
						},
						{
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.LABEL			:	"AUTO_SCALE",
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$meshOptions,
							GUI.DATA_BIT		:	MinSG.MESH_AUTO_SCALE
						},
						"*Node options*",
						{
							GUI.TYPE			:	GUI.TYPE_TEXT,
							GUI.LABEL			:	"Node id",
							GUI.DATA_WRAPPER	:	config.id,
							GUI.TOOLTIP			:	"The created Node is registered at the \nsceneManager with this id."
						}
						
					]
				});
			}
		},
    
		{
			GUI.LABEL		:	"Load Meshes ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a directory, read all meshes from that directory, and add them to the current scene.\nSupported types: .mmf, .obj, .ply, .md2, .mvbo, .ngc",
			GUI.ON_CLICK	:	fn() {
				var config = new ExtObject;
				config.meshOptions := 0;

				gui.openDialog({
					GUI.TYPE : GUI.TYPE_FOLDER_DIALOG,
					GUI.LABEL : "Load all Meshes in folder",
					GUI.DIR : PADrend.getDataPath(),
					GUI.ENDINGS : [".obj",".ply",".mmf",".mvbo",".MVBO",".ngc", ".md2", ".MD2", ".xyz"],
					GUI.ON_ACCEPT : [config] => fn(config, folder){
						out("Load Meshes \"",folder,"\"...");
						PADrend.message("Load Meshs \""+folder+"\"...");
						showWaitingScreen();
						var start=clock();
						var count=0;
						foreach(Util.getFilesInDir(folder,[".obj",".ply",".mmf",".mvbo",".MVBO",".ngc", ".md2", ".MD2", ".xyz"]) as var file){
							 var n=MinSG.loadModel(file, config.meshOptions);
							if(!n)
								continue;
							PADrend.getCurrentScene().addChild(n);
							if((count++ % 10)==0)
								out(".");
	//						out(file);
						}
						out("\nDone. ",(clock()-start)," sek\n");
					},
					GUI.OPTIONS : [
						"Mesh options",
						{
							GUI.LABEL			:	"AUTO_CENTER",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$meshOptions,
							GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER
						},
						{
							GUI.LABEL			:	"AUTO_CENTER_BOTTOM",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$meshOptions,
							GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER_BOTTOM
						},
						{
							GUI.LABEL			:	"AUTO_SCALE",
							GUI.TYPE			:	GUI.TYPE_BIT,
							GUI.DATA_OBJECT		:	config,
							GUI.DATA_ATTRIBUTE	:	$meshOptions,
							GUI.DATA_BIT		:	MinSG.MESH_AUTO_SCALE
						}
					]
				});
			}
		},
		{
			GUI.LABEL		:	"Save Meshes ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a directory, and write all meshes that are used by the current scene into that directory.\nSupported types: .mmf, .ply",
			GUI.ON_CLICK	:	fn() {
				var exportRegisteredCB = new Std.DataWrapper(false);
				var exportFormat = new Std.DataWrapper("mmf");
				var currentFolder = new Std.DataWrapper;
				var dbfsName = new Std.DataWrapper("new.dbfs");
				var zipName = new Std.DataWrapper("new.zip");
				currentFolder.onDataChanged += [dbfsName] => fn(dbfsName,folder){	dbfsName(folder+"/new.dbfs");	};
				currentFolder.onDataChanged += [zipName] => fn(zipName,folder){	zipName(folder+"/new.zip");	};
				currentFolder(PADrend.getDataPath());

				gui.openDialog({
					GUI.TYPE : GUI.TYPE_FOLDER_DIALOG,
					GUI.LABEL : "Export all Meshes to ...",
					GUI.DIR : PADrend.getDataPath(),
					GUI.ON_ACCEPT : [exportRegisteredCB,exportFormat] => fn(exportRegisteredCB,exportFormat, folder){
												
						outln("Exporting meshes to ",folder);
						showWaitingScreen();
						if(exportFormat()=='mmf'){
							MinSG.SceneManagement.saveMeshesInSubtreeAsMMF(
									PADrend.getCurrentScene(),
									folder,
									exportRegisteredCB());
						} else{ //ply
							MinSG.SceneManagement.saveMeshesInSubtreeAsPLY(
									PADrend.getCurrentScene(),
									folder,
									exportRegisteredCB());
						}
						Util.flush(folder);
					},
					GUI.ON_FOLDER_CHANGED : [currentFolder]=>fn(currentFolder,folder){	currentFolder(folder);	},
					GUI.OPTIONS : [
						"*Mesh export options*",
						{
							GUI.LABEL			:	"Export already registered nodes",
							GUI.TYPE			:	GUI.TYPE_BOOL,
							GUI.DATA_WRAPPER	:	exportRegisteredCB
						},
						{
							GUI.TYPE 			: 	GUI.TYPE_SELECT,
							GUI.LABEL			:	"Export format:",
							GUI.DATA_WRAPPER	: 	exportFormat,
							GUI.OPTIONS			:	[ ['mmf',"mmf - MinSG mesh format"],['ply',"ply - Standord PLY"]]

						},
						'----',
						"*Create new dbfs-container*",
						{
							GUI.TYPE 			: 	GUI.TYPE_TEXT,
							GUI.Label			:	"Filename",
							GUI.DATA_WRAPPER	: 	dbfsName

						},
						{
							GUI.TYPE			:	GUI.TYPE_BUTTON,
							GUI.LABEL			:	"Create",
							GUI.TOOLTIP			:	"Create a .dbfs container file with the name in the file name box.\n\n   !!!Re-enter this folder to refresh!!! ",
							GUI.ON_CLICK		:	[dbfsName]=>fn(dbfsName){
								var archiveName = dbfsName();
								var pPos = archiveName.find("://");
								if(pPos)
									archiveName=archiveName.substr(pPos+3);
								archiveName="dbfs://"+archiveName;
								if(!archiveName.endsWith(".dbfs"))
									archiveName += ".dbfs";
								out("Creating file:",archiveName,"\n");
								Util.saveFile(archiveName+"$./info.txt","MinSG dbfs file container\n"+Util.createTimeStamp());
								Util.flush(archiveName);
//								refresh();
							},

						},
						'----',
						"*Create new zip-container*",
						{
							GUI.TYPE 			: 	GUI.TYPE_TEXT,
							GUI.Label			:	"Filename",
							GUI.DATA_WRAPPER	: 	zipName

						},
						{
							GUI.TYPE			:	GUI.TYPE_BUTTON,
							GUI.LABEL			:	"Create",
							GUI.TOOLTIP			:	"Create a .zip container file with the name in the file name box\n\n   !!!Re-enter this folder to refresh!! ",
							GUI.ON_CLICK		:	[zipName]=>fn(zipName){
								var archiveName = zipName();
								var pPos = archiveName.find("://");
								if(pPos)
									archiveName = archiveName.substr(pPos+3);
								archiveName= "zip://"+archiveName;
								if(!archiveName.endsWith(".zip"))
									archiveName += ".zip";
								out("Creating file:",archiveName,"\n");
								Util.saveFile(archiveName+"$./info.txt","MinSG zip file container\n"+Util.createTimeStamp());
								Util.flush(archiveName);
//								refresh();
							}
						}
					]
				});
			}
		}
	]);

	// scripts subgroup
	gui.registerComponentProvider('PADrend_FileMenu.30_scripts',[
		'----',
		{
			GUI.LABEL		:	"Load Script ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, and load that file and execute it.\nSupported types: .escript",
			GUI.ON_CLICK	:	fn() {
				GUI._openFileDialog("Load Script",".",[".escript"],
					fn(filename){
						PADrend.message("Load Script \""+filename+"\"...");
						out("\n");
						try{
							load(filename);
						}catch(e){
							Runtime.log(Runtime.LOG_ERROR,e);
						}
						out("\n");
					}
				);
			}
		}
	]);
		
	// exit subgroup
	gui.registerComponentProvider('PADrend_FileMenu.90_exit',[
		'----',
		{
			GUI.TYPE		:	GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL		:	"Restart",
			GUI.TOOLTIP		:	"Restart PADrend",
			GUI.ON_CLICK	:	fn() { PADrend.restart(); }
		},
		{
			GUI.TYPE		:	GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL		:	"Exit",
			GUI.TOOLTIP		:	"Close PADrend.",
			GUI.ON_CLICK	:	fn() { PADrend.quit(); }
		}
	]);
	
	// ----------------------------------------------------------------------------------
    // Scenes-Menu
    gui.registerComponentProvider('PADrend_MainToolbar.10_scene',{
        GUI.TYPE : GUI.TYPE_MENU,
        GUI.LABEL : "Scenes",
        GUI.MENU : 'PADrend_ScenesMenu',
        GUI.MENU_WIDTH : 500,
        GUI.ICON : "#ScenesSmall",
        GUI.ICON_COLOR : GUI.BLACK
    });

	gui.registerComponentProvider('PADrend_ScenesMenu',fn(){
		var sceneMenu = [];

		sceneMenu += "*Create new scene root*";
		var container = gui.create({
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 40],
			GUI.LAYOUT				:	GUI.LAYOUT_FLOW
		});

		// SceneNode options
		var sceneRootOptions = ["new MinSG.ListNode"];
		if(MinSG.isSet($LooseOctree)) {
			sceneRootOptions += "new MinSG.LooseOctree";
		}
		if(MinSG.isSet($RTree)) {
			sceneRootOptions += "new MinSG.RTree(2, 50)";
		}
	
		var constructionString = new Std.DataWrapper("new MinSG.ListNode");
		container += {
			GUI.TYPE				:	GUI.TYPE_TEXT,
			GUI.OPTIONS				:	sceneRootOptions,
			GUI.DATA_WRAPPER		:	constructionString,
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.7, 0]
		};

		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"New scene",
			GUI.ON_CLICK			:[constructionString]=> fn(constructionString) {
											PADrend.createNewSceneRoot(constructionString());
										},
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 0, 0]
		};
		sceneMenu += container;

		sceneMenu += "*Current scenes*";

		container = gui.create({
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 130],
			GUI.LAYOUT				:	GUI.LAYOUT_FLOW
		});

		var sceneListView = gui.create({
			GUI.TYPE				:	GUI.TYPE_TREE,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 0, 25]
		});
		sceneListView.rebuild := fn(Array sceneList ) {
			this.clear();
			foreach(sceneList as var scene) {
				var entry = gui.create({
					GUI.TYPE				:	GUI.TYPE_CONTAINER,
					GUI.SIZE 				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 15],
					GUI.FLAGS				:	GUI.BORDER
				});
				entry.scene := scene;
				this += entry;
				
//				entry += "#"+index+" ";
				{
					var label = gui.createLabel(60, 15, "" );		// text is set on update()
					label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
					entry += label;
					entry.selectLabel:=label;
				}
				{
					var label = gui.create( {
						GUI.TYPE : GUI.TYPE_LABEL,
						GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 15, 15],
						GUI.LABEL : "...",				// text is set on update()
						GUI.POSITION : [60,0]
					});
					entry += label;
					entry.nameLabel:=label;
				}
				entry += {
					GUI.TYPE : GUI.TYPE_MENU,
					GUI.ICON : "#DownSmall",
					GUI.MENU : 'PADrend_SceneConfigMenu',
					GUI.MENU_CONTEXT : scene,
					GUI.MENU_WIDTH : 200,
					GUI.SIZE : [15,15],
					GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 1,1],
					GUI.FLAGS : GUI.FLAT_BUTTON
				};
			}
			update();
		};
		sceneListView.onDataChanged = fn(data) {
			var selected = getMarkedComponents();
			var scene = void;
			if(!selected.empty()) {
				scene = selected[0].scene;
			}
			PADrend.selectScene(scene);
			update();
			return true;
		};
		sceneListView.update := fn(p...) {
			var NodeMetaInfo = Std.require('LibMinSGExt/NodeMetaInfo');
			var selected = getMarkedComponents();
			var acticeScene=PADrend.getCurrentScene();
			foreach(getContents() as var index,var entry){
				entry = entry.getFirstChild();
				var scene=entry.scene;
				if(acticeScene==scene){
					entry.selectLabel.setText("-[ #"+index+" ]- ");
				}else{
					entry.selectLabel.setText("   #"+index+"    ");
				}
				var parts = [];
				parts += NodeMetaInfo.queryMetaInfo_Title(scene,"");
				if(scene.isSet($filename) && scene.filename!="") parts += "[ "+scene.filename+" ]";
				parts += "ID-Namspace: " + PADrend.SceneManagement.getNamedMapOfAvaiableSceneManagers()[ PADrend.SceneManagement.getSceneManager(scene) ];
				
				entry.nameLabel.setText( parts.implode(" : "));
				entry.nameLabel.setTooltip( "" + 
					"Title: "+NodeMetaInfo.queryMetaInfo_Title(scene,"?") + "\n"+
					"Author: "+NodeMetaInfo.queryMetaInfo_Author(scene,"?") + "\n"+
					"CreationDate: "+NodeMetaInfo.queryMetaInfo_CreationDate(scene,"?") + "\n"+
					"License: "+NodeMetaInfo.queryMetaInfo_License(scene,"?") + "\n"+
					"Note: "+NodeMetaInfo.queryMetaInfo_Note(scene,"") 
				);
			}
		};

		registerExtension('PADrend_OnSceneListChanged',sceneListView->fn(sceneList){
			if(isDestroyed())
				return Extension.REMOVE_EXTENSION;
			rebuild(sceneList);
		});
							
		registerExtension('PADrend_OnSceneSelected',sceneListView->fn(p...){
			if(isDestroyed())
				return Extension.REMOVE_EXTENSION;
			update();
		});

		sceneListView.rebuild( PADrend.SceneManagement.getSceneList());

		container += sceneListView;
		container++;

		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Clone scenes",
			GUI.ON_CLICK			:	sceneListView -> fn() {
											foreach(getMarkedComponents() as var entry) {
												var newScene = entry.scene.clone();
												PADrend.registerScene(newScene);
											}
										},
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.18, 0]
		};
		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Delete scenes",
			GUI.ON_CLICK			:	sceneListView -> fn() {
											foreach(getMarkedComponents() as var entry) {
												PADrend.deleteScene(entry.scene);
											}
										},
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.18, 0]
		};
		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Merge scenes",
			GUI.TOOLTIP				:	"The scene roots of the selected scenes are added to the scene root of the current scene.\nHint: To select multiple scenes hold [ctrl].",
			GUI.ON_CLICK			:	sceneListView -> fn() {
											var scenes = [];
											foreach(getMarkedComponents() as var entry) {
												scenes += entry.scene;
											}
											PADrend.mergeScenes(PADrend.getCurrentScene(), scenes);
										},
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.18, 0]
		};
		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Move children",
			GUI.TOOLTIP				:	"Add all direct child nodes of the selected scenes to the scene root of the first scene.\nHint: To select multiple scenes hold [ctrl].",
			GUI.ON_CLICK			:	sceneListView -> fn() {
											var scenes=[];
											foreach(getMarkedComponents() as var entry) {
												scenes += entry.scene;
											}
											var root = scenes.popFront();
											foreach(scenes as var s) {
												foreach(MinSG.getChildNodes(s) as var node) {
													root.addChild(node);
													out(".");
												}
											}
										},
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.18, 0]
		};
		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Move closed nodes",
			GUI.TOOLTIP				:	"Add all closed nodes of the selected scenes to the scene root of the first scene.\nHint: To select multiple scenes hold [ctrl].",
			GUI.ON_CLICK			:	sceneListView -> fn() {
											var scenes=[];
											foreach(getMarkedComponents() as var entry) {
												scenes += entry.scene;
											}
											var root = scenes.popFront();
											foreach(scenes as var s) {
												MinSG.moveTransformationsIntoClosedNodes(s);
												var closedNodes = MinSG.collectClosedNodes(s);
												foreach(closedNodes as var node) {
													root.addChild(node);
													out(".");
												}
											}
										},
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 0, 0]
		};

		sceneMenu += container;
		return sceneMenu;
	});
	
	gui.registerComponentProvider('PADrend_SceneConfigMenu.00_main',fn(scene){
		var entries = [];
		entries += "*" + scene + "*";
		return entries;
	});
	
	gui.registerComponentProvider('PADrend_SceneConfigMenu.05_sceneMetaData',fn(scene){
		var NodeMetaInfo = Std.require('LibMinSGExt/NodeMetaInfo');
		var entries = [];
		entries += '----';
		entries += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Title",
			GUI.DATA_WRAPPER : NodeMetaInfo.accessMetaInfo_Title(scene)
		};
		entries += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Author",
			GUI.DATA_WRAPPER : NodeMetaInfo.accessMetaInfo_Author(scene)
		};
		var d = getDate();
		entries += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Creation date",
			GUI.DATA_WRAPPER : NodeMetaInfo.accessMetaInfo_CreationDate(scene),
			GUI.OPTIONS :  ["" + d["year"] + "-"+ d["mon"] + "-" + d["mday"] ]
		};
		entries += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "License",
			GUI.DATA_WRAPPER : NodeMetaInfo.accessMetaInfo_License(scene),
			GUI.OPTIONS :  ["free","internal use","RESTRICTED" ]
		};
		entries += {
			GUI.TYPE : GUI.TYPE_MULTILINE_TEXT,
			GUI.LABEL : "Note",
			GUI.DATA_WRAPPER : NodeMetaInfo.accessMetaInfo_Note(scene),
			GUI.HEIGHT : 100
		};
		return entries;
	});


	gui.registerComponentProvider('PADrend_SceneConfigMenu.10_coordinateSystem',fn(scene){
		var entries = [];
		entries +='----';
		entries += {
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.LABEL : "Coord. sys.",
			GUI.OPTIONS : [ ["Y","Y-Up (default)" ],["Z","Z-Up" ]],
			GUI.DATA_VALUE : PADrend.isSceneCoordinateSystem_YUp(scene) ? "Y" : (PADrend.isSceneCoordinateSystem_ZUp(scene) ? "Z" : "?"),
			GUI.ON_DATA_CHANGED :  [scene]=>fn(scene, system){
				if(system=="Y"){
					PADrend.markSceneCoordinateSystem_YUp(scene);
				}else if(system=="Z"){
					PADrend.markSceneCoordinateSystem_ZUp(scene);
				}else{
					assert(false);
				}
			},
			GUI.TOOLTIP : "Note: This does NOT rotate the scene!\nIt sets the scene's coordinate system -- the\n rotation must be performed manually."
		};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "(Helper) Rotate scene around X-Axis",
			GUI.ON_CLICK : [scene] => fn(scene){	scene.rotateAroundWorldAxis_deg(90,new Geometry.Line3(new Geometry.Vec3(0,0,0),new Geometry.Vec3(1,0,0)));	}
		
		};
		return entries;
	});

 // ----------------------------------------------------------------------------------

	gui.registerComponentProvider('PADrend_MainToolbar.20_plugins',{
		GUI.TYPE		:	GUI.TYPE_MENU,
		GUI.LABEL		:	"Plugins",
		GUI.MENU		:	'PADrend_PluginsMenu',
		GUI.ICON		:	"#PluginsSmall",
		GUI.ICON_COLOR	:	GUI.BLACK,
	});
 // ----------------------------------------------------------------------------------
    // Config-Menu

	gui.registerComponentProvider('PADrend_MainToolbar.30_config',{
		GUI.TYPE		:	GUI.TYPE_MENU,
		GUI.LABEL		:	"Config",
		GUI.ICON		:	"#SettingsSmall",
		GUI.ICON_COLOR	:	GUI.BLACK,
		GUI.MENU		:	'PADrend_ConfigMenu',
		GUI.MENU_WIDTH	:	150
	});
    
	// ------------------------
	// Config-Menu.10_renderingSettingsp

	gui.registerComponentProvider('PADrend_ConfigMenu.10_renderingGroup',[{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Rendering settings",
		GUI.MENU : 'PADrend_RenderingSettings',
		GUI.MENU_WIDTH : 150
	}]);

	gui.registerComponentProvider('PADrend_RenderingSettings',fn(){
		var m = [];
		
		m += "*Rendering flags*";

		foreach( ['BOUNDING_BOXES','SHOW_META_OBJECTS','NO_GEOMETRY','NO_STATES','FRUSTUM_CULLING','USE_WORLD_MATRIX','SHOW_COORD_SYSTEM'] as var flagName){
			m += {
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : flagName,
				GUI.DATA_PROVIDER : [flagName] => fn(flagName){
					return (PADrend.getRenderingFlags() & MinSG.getAttribute(flagName))>0;
				},
				GUI.ON_DATA_CHANGED : [flagName] => fn(flagName, data){
					var mask = MinSG.getAttribute(flagName);
					PADrend.setRenderingFlags( (PADrend.getRenderingFlags()-(PADrend.getRenderingFlags()&mask))| (data?mask:0) );
					systemConfig.setValue('PADrend.Rendering.flags',PADrend.getRenderingFlags());
				},
			
			};
		}

		{// rendering Layers
			static eventLoop = Util.requirePlugin('PADrend/EventLoop');

			m += "Rendering layer:";

			var container = gui.create({
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
				GUI.WIDTH : 200
			});
			var mask = 1;
			
			for(var i=0;i<8;++i){
				var dataWrapper = new DataWrapper( (eventLoop.getRenderingLayers()&mask)>0);
				dataWrapper.onDataChanged += [mask] => fn(mask,b){
					eventLoop.setRenderingLayers(eventLoop.getRenderingLayers().setBitMask(mask,b) );
				};
				mask*=2;

				container += { 
					GUI.LABEL : "",
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.TOOLTIP : "Activate rendering layer #"+i,
					GUI.DATA_WRAPPER : dataWrapper
				};
			}
			m+=container;
		}		
		m += "*Eventloop flags*";
		m += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "waitForGlFinish",
			GUI.DATA_PROVIDER : fn(){ return PADrend.EventLoop.waitForGlFinish; },
			GUI.ON_DATA_CHANGED : fn(d){
				PADrend.EventLoop.waitForGlFinish = d;
				systemConfig.setValue('PADrend.Rendering.waitForGlFinish',d);
			}
		};
		m += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "GL Error Checking",
			GUI.DATA_WRAPPER : PADrend.EventLoop.glErrorChecking
		};
		m += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"GL Debug Output",
			GUI.TOOLTIP			:	"Enable debug output, if the OpenGL extension GL_ARB_debug_output is supported.",
			GUI.DATA_PROVIDER	:	fn() { return systemConfig.getValue('PADrend.Rendering.GLDebugOutput', false); },
			GUI.ON_DATA_CHANGED	:	fn(data) {
										systemConfig.setValue('PADrend.Rendering.GLDebugOutput', data);
										if(data) {
											Rendering.enableDebugOutput();
										} else {
											Rendering.disableDebugOutput();
										}
									}
		};
		m += "*Background color*";
		m += {
			GUI.TYPE : GUI.TYPE_COLOR,
			GUI.LABEL : "Color",
			GUI.DATA_PROVIDER : fn(){ return PADrend.EventLoop.getBGColor(); },
			GUI.ON_DATA_CHANGED : fn(data){
				PADrend.setBGColor(data);
			},
			GUI.TOOLTIP : "Adjust the background color."
			
		};
		return m;
	});

	// ------------------------
	// // Config-Menu.20_navigationGroup
	
	gui.registerComponentProvider('PADrend_ConfigMenu.20_navigationGroup',['----',{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Navigation",
		GUI.MENU : 'PADrend_NavigationConfigMenu',
		GUI.MENU_WIDTH : 150
	}]);
	
	gui.registerComponentProvider('PADrend_NavigationConfigMenu.10_main',[
		"*Navigation settings*",
		{
			GUI.TYPE : 	GUI.TYPE_BOOL,
			GUI.LABEL : "Invert Mouse-Y Axis",
			GUI.DATA_PROVIDER : fn(){ return PADrend.getCameraMover().getInvertYAxis();},
			GUI.ON_DATA_CHANGED : fn(data){
				PADrend.getCameraMover().setInvertYAxis(data);
				systemConfig.setValue('PADrend.Input.invertMouse',data);
			}
		},
		{
			GUI.TYPE : 	GUI.TYPE_BOOL,
			GUI.LABEL : "Smooth Mouse rotation",
			GUI.DATA_PROVIDER : fn(){ return PADrend.getCameraMover().smoothMouse;},
			GUI.ON_DATA_CHANGED : fn(data){
				PADrend.getCameraMover().smoothMouse = data;
				PADrend.configCache.setValue('PADrend.Input.smoothMouse',data);
			}
		},
		"Movement speed",
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [-3,10],
			GUI.RANGE_STEPS : 50,
			GUI.RANGE_FN_BASE : 2,
			GUI.DATA_PROVIDER : fn(){ return PADrend.getCameraMover().getSpeed();},
			GUI.ON_DATA_CHANGED : fn(data){
				PADrend.getCameraMover().setSpeed(data);
			},
			GUI.TOOLTIP : "NOTE: This value is not saved to the config!"
		},
		"Rotation speed for [q],[e]",
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0.0,3.0],
			GUI.RANGE_STEPS : 300,
			GUI.DATA_PROVIDER : fn(){ return PADrend.getCameraMover().getDiscreteRotationSpeed();	},
			GUI.ON_DATA_CHANGED : fn(data){	PADrend.getCameraMover().setDiscreteRotationSpeed(data);	},
			GUI.TOOLTIP : "NOTE: This value is not saved to the config!"
		}
	]);
	gui.registerComponentProvider('PADrend_NavigationConfigMenu.20_joystick',fn(){	return [
		'----',
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Joystick support(req. restart)",
			GUI.DATA_WRAPPER : PADrend.Navigation.joystickSupport
		},
		"Joystick rotation",
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [0.1,5],
			GUI.DATA_PROVIDER : fn(){ return PADrend.getCameraMover().joypad_rotationFactor;	},
			GUI.ON_DATA_CHANGED : fn(data){
				PADrend.getCameraMover().joypad_rotationFactor = data;
				systemConfig.setValue('PADrend.Input.rotationFactor',data);
			},
			GUI.TOOLTIP : "Factor"
		},
		{
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.LABEL : "Rot. exp.",
			GUI.OPTIONS : [ [1,"1"], [2,"2"], [4,"4"], [8,"8"] ],
			GUI.DATA_PROVIDER : fn(){ return PADrend.getCameraMover().joypad_rotationExponent;	},
			GUI.ON_DATA_CHANGED : fn(data){
				PADrend.getCameraMover().joypad_rotationExponent = data;
				systemConfig.setValue('PADrend.Input.rotationExponent',data);
			},
			GUI.TOOLTIP : "Exponent used for calculatin the rotation."
		}
	];});
	gui.registerComponentProvider('PADrend_NavigationConfigMenu.30_HIDDevices',[{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.MENU : 'PADrend_HID_Menu',
		GUI.LABEL : "HID Devices"
	}]);
	gui.registerComponentProvider('PADrend_HID_Menu.00_main',fn(){
		var entries = [];
		foreach( PADrend.HID.getDevices() as var deviceName, var device ){
			entries += deviceName;
		}
		return entries;
	});
	
	
	// ------------------------
	// gui settings
	gui.registerComponentProvider('PADrend_ConfigMenu.25_gui',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "GUI",
			GUI.MENU : 'PADrend_GUIConfigMenu',
			GUI.MENU_WIDTH : 150
		}
	]);
	
	gui.registerComponentProvider('PADrend_GUIConfigMenu.m_resetWindows',[
		{
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Move all windows in sight",
			GUI.ON_CLICK	:	fn(){
				var root = this;
				while(root.getParentComponent()) 
					root = root.getParentComponent();
				var ww = renderingContext.getWindowWidth();
				var wh = renderingContext.getWindowHeight();
				foreach(root.getContents() as var c){
					if(c.getPosition().x() > ww-5 ||c.getPosition().y()>wh-5 ){
						c.setPosition( [ww-c.getWidth(),c.getPosition().x()  ].min(),[wh-c.getHeight(),c.getPosition().y()].min() );
						outln("Window ",c," moved.");
					}
				}
			},
			GUI.TOOLTIP		:	"Move windows that lie outside \nthe screen into the screen."
		}

	]);


	// ------------------------
	// Plugins
	gui.registerComponentProvider('PADrend_ConfigMenu.26_plugins',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Plugins",
			GUI.MENU : 'PADrend_PluginSelectionMenu',
			GUI.MENU_WIDTH : 150
		}
	]);
	
	gui.registerComponentProvider('PADrend_PluginSelectionMenu.main',fn(){
		var entries = [];
		entries += "*Plugins*";
		
		var plugins = systemConfig.getValue('PADrend.plugins');

		outln("\n\nScanning for Plugin files...");
		
		var pluginFolders = PADrend.pluginFolders();
		// filter old Plugins
		var pluginsToRemove=[];
		foreach(plugins as var name,var enabled){
			if(!Util.locatePlugin(name,pluginFolders)){
				if(enabled){
					outln("Invalid enabled plugin found: ",name);
				}else{
					outln("Invalid plugin found and removed: ",name);
					pluginsToRemove+=name;
				}
			}
		}
		foreach(pluginsToRemove as var n)
			plugins.unset(n);

		var directories = [];
		foreach(pluginFolders as var folder) {
			if(Util.isDir(folder)) {
				directories.append(Util.dir(folder, Util.DIR_DIRECTORIES));
			}
		}
		
		foreach(directories as var fullPath){
			var parts = fullPath.split("/");
			var posiblePluginName = parts[parts.size()-2];
			if(!Util.locatePlugin(posiblePluginName,pluginFolders))
				continue;
			if(void!==plugins[posiblePluginName])
				continue;
			plugins[posiblePluginName]=false;
			outln("Plugin:",posiblePluginName," found.");
		}
		systemConfig.setValue('PADrend.plugins',plugins);
	
		foreach(plugins as var name,var enabled){
			var plugin = queryPlugin(name);
			var parts = [{
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.LABEL : name+ (plugin ? "*" :""),
						GUI.DATA_VALUE : enabled,
						GUI.ON_DATA_CHANGED : [name]=>fn(name,value){
							systemConfig.setValue('PADrend.plugins.'+name,value);
						},
						GUI.TOOLTIP : plugin ? "(ACTIVE)\n"+plugin.getDescription() : name
			}];
			if(!plugin){
				parts += {
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.ICON : "#AddSmall",
					GUI.FLAGS : GUI.FLAT_BUTTON,
					GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
						GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, 15,4],
					GUI.SIZE : [15,10],
					GUI.TOOLTIP : "Try to load the '"+name+"' plugin now.",
					GUI.ON_CLICK : [name] => fn(name){
						PADrend.message("LOAD...");
						gui.closeAllMenus();
						Util.loadPlugins([name],true, PADrend.pluginFolders() );
						executeExtensions('PADrend_Init');
					},
					GUI.REQUEST_MESSAGE : "This may fail!"
				};
			}else if(Traits.queryTrait(plugin,Util.ReloadablePluginTrait)) {
				parts += {
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.ICON : "#RefreshSmall",
					GUI.FLAGS : GUI.FLAT_BUTTON,
					GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
						GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, 15,4],
					GUI.SIZE : [15,10],
					GUI.TOOLTIP : "Try to reload the '"+name+"' plugin.",
					GUI.ON_CLICK : [plugin,name] => fn(plugin,name){
						PADrend.message("Reloading '"+name+"'");
						Util.reloadPlugin(plugin);
						executeExtensions('PADrend_Init');
					},
					GUI.REQUEST_MESSAGE : "This may fail!"
				};
			}
			
			entries += {
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_REL ,4,1.0 ],
				GUI.CONTENTS : parts,
			};
		}
		entries += '----';
		entries += 	{
			GUI.LABEL		:	"Save configuration",
			GUI.TOOLTIP		:	"Write configuration to \"" + systemConfig.getFilename() + "\".",
			GUI.ON_CLICK	:	fn() {
									systemConfig.save();
									PADrend.message("Configuration successfully written to \"" + systemConfig.getFilename() + "\".");
								}
		};
		return entries;
	
	});
	
	// ------------------------
	// misc settings
	gui.registerComponentProvider('PADrend_ConfigMenu.30_misc',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Misc.",
			GUI.MENU : 'PADrend_MiscConfigMenu',
			GUI.MENU_WIDTH : 150
		}
	]);
	
	gui.registerComponentProvider('PADrend_MiscConfigMenu.debugInfo',[
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Debug information output",
			GUI.DATA_PROVIDER : fn(){return systemConfig.getValue('PADrend.enableInfoOutput');},
			GUI.ON_DATA_CHANGED : fn(data){
				if(data) {
					Util.enableInfo();
				} else {
					Util.disableInfo();
				}
				systemConfig.setValue('PADrend.enableInfoOutput',data);
			}
		}
	]);


	// ------------------------
	// config file group
	gui.registerComponentProvider('PADrend_ConfigMenu.90_config',[
		'----',
		{
			GUI.LABEL		:	"Save configuration",
			GUI.TOOLTIP		:	"Write configuration to \"" + systemConfig.getFilename() + "\".",
			GUI.ON_CLICK	:	fn() {
									systemConfig.save();
									PADrend.message("Configuration successfully written to \"" + systemConfig.getFilename() + "\".");
								}
		},
		{
			GUI.LABEL		:	"Edit configuration ...",
			GUI.TOOLTIP		:	"Open \"" + systemConfig.getFilename() + "\" in a text editor.",
			GUI.ON_CLICK	:	fn() { Util.openOS(systemConfig.getFilename()); }
		}
	]);


	// ------------------
};

return plugin;
// ----------------------------------------------------
