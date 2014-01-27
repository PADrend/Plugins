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


/***
 **   ---|> Plugin
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


//! ---|> Plugin
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
		gui.openDialog({
			GUI.TYPE :		GUI.TYPE_FILE_DIALOG,
			GUI.LABEL :		"Save scene",
			GUI.ENDINGS :	[".minsg", ".dae", ".DAE"],
			GUI.FILENAME : 	scene.isSet($filename) ? scene.filename : PADrend.getScenePath()+"/Neu.minsg",
			GUI.ON_ACCEPT : [scene] => fn(scene, filename){
						
				var save = [scene,filename] => fn(scene,filename){
					PADrend.message("Save scene \""+filename+"\"");
					if(filename.endsWith(".dae")||filename.endsWith(".DAE")) {
						PADrend.getSceneManager().saveCOLLADA(filename,PADrend.getRootNode());
					} else {
						PADrend.getSceneManager().saveMinSGFile(filename,[scene]);
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
	gui.registerComponentProvider('PADrend_FileMenu.10_scene',[
		{
			GUI.LABEL		:	"Load Scene ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, and read a scene from that file.\nSupported types: .minsg, .dae",
			GUI.ON_CLICK	:	fn() {
				var config = new ExtObject({
					$scale : DataWrapper.createFromValue(1.0),
					$importOptions : PADrend.configCache.getValue('PADrend.importOptions', 
											MinSG.SceneManager.IMPORT_OPTION_USE_TEXTURE_REGISTRY | 
											MinSG.SceneManager.IMPORT_OPTION_USE_MESH_REGISTRY)
				});
				var f=new GUI.FileDialog("Load Scene",PADrend.getScenePath(),[".minsg", ".dae", ".DAE"],
					[config] => fn(config,filename){
						// Collect flags.
						out("Load Scene \"",filename,"\"...");
						PADrend.message("Load scene \""+filename+"\"...");

						PADrend.configCache.setValue('PADrend.importOptions', config.importOptions);
						var node=PADrend.loadScene(filename, /*sceneNode,*/ config.importOptions);
						if(!node){
							PADrend.message("Loading scene '"+filename+"' failed.");
						}else{
							PADrend.message("Scene loaded '"+filename+"'");
							PADrend.selectScene(node);
								
							var scale=config.scale();
							if(scale!=1.0)
								node.scale(scale);
							
							addToRecentSceneList( filename );
						}

					}
				);
				//sceneLoadOptionPanel
				var optionPanel=f.createOptionPanel(250);
				optionPanel += "Options";
				optionPanel++;
				optionPanel += '----';
				optionPanel++;
				
				optionPanel += {
					GUI.TYPE			:	GUI.TYPE_NUMBER,
					GUI.LABEL			:	"Scale:",
					GUI.DATA_WRAPPER	:	config.scale,
					GUI.OPTIONS			:	[1.0,0.1,0.01,0.001],
					GUI.WIDTH			:	200,
				};
				optionPanel++;
				
				optionPanel += {
					GUI.LABEL			:	"Reuse exisiting states",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	config,
					GUI.DATA_ATTRIBUTE	:	$importOptions,
					GUI.DATA_BIT		:	MinSG.SceneManager.IMPORT_OPTION_REUSE_EXISTING_STATES
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"Cache textures in TextureRegistry",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	config,
					GUI.DATA_ATTRIBUTE	:	$importOptions,
					GUI.DATA_BIT		:	MinSG.SceneManager.IMPORT_OPTION_USE_TEXTURE_REGISTRY
				};
				optionPanel++;			
				optionPanel += {
					GUI.LABEL			:	"Cache meshes in MeshRegistry (file)",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	config,
					GUI.DATA_ATTRIBUTE	:	$importOptions,
					GUI.DATA_BIT		:	MinSG.SceneManager.IMPORT_OPTION_USE_MESH_REGISTRY,
					GUI.TOOLTIP : "If GeometryNodes use the same mesh file (during this import process), \nload and use the mesh only once."
					
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"Cache meshes in MeshRegistry (hash)",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	config,
					GUI.DATA_ATTRIBUTE	:	$importOptions,
					GUI.DATA_BIT		:	MinSG.SceneManager.IMPORT_OPTION_USE_MESH_HASHING_REGISTRY,
					GUI.TOOLTIP : "If GeometryNodes use the same mesh based on its structure (during this import process), \nload and use the mesh only once."
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"COLLADA: Invert transparency",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	config,
					GUI.DATA_ATTRIBUTE	:	$importOptions,
					GUI.DATA_BIT		:	MinSG.SceneManager.IMPORT_OPTION_DAE_INVERT_TRANSPARENCY,
					GUI.TOOLTIP : "Use this for scenes exported from 3dMax"
				};
				f.init();
			}

		},
		{
			GUI.TYPE		: 	GUI.TYPE_MENU,
			GUI.LABEL		:	"Recent scenes",
			GUI.MENU_PROVIDER : fn(){
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
									
		},
		{
			GUI.TYPE		:	GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL		:	"Save scene",
			GUI.ON_CLICK	:	fn() {
				var scene = PADrend.getCurrentScene();
				var filename = scene.isSet($filename) ? scene.filename : void;
				if(filename){
					PADrend.message("Save scene \""+filename+"\"");
					if(filename.endsWith(".dae")||filename.endsWith(".DAE")) {
						PADrend.getSceneManager().saveCOLLADA(filename,PADrend.getRootNode());
					} else {
						PADrend.getSceneManager().saveMinSGFile(filename,[scene]);
					}
					// Re-select it to provoke an update where necessary.
					executeExtensions('PADrend_OnSceneSelected',scene );
				}else{
					openSaveSceneDialog();
				}
			}
		},
		{
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Save scene as ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, and write the current scene into that file.\nSupported types: .minsg, .dae",
			GUI.ON_CLICK	:	openSaveSceneDialog
		}
	]);

	// meshes subgroup
	gui.registerComponentProvider('PADrend_FileMenu.20_meshes',[
		'----',
		{
			GUI.LABEL		:	"Load Mesh ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a file, read a mesh from that file, and add it to the current scene.\nSupported types: .mmf, .obj, .ply, .md2, .mvbo, .ngc",
			GUI.ON_CLICK	:	fn() {

				var f=new GUI.FileDialog("Load Mesh",PADrend.getDataPath(),[".obj",".ply",".mmf",".mvbo",".MVBO",".ngc", ".md2", ".MD2", ".xyz"],
					fn(filename){
						out("Load Mesh \"",filename,"\"...");
						PADrend.message("Load Mesh \""+filename+"\"...");
						showWaitingScreen();
						var start=clock();

						var n=MinSG.loadModel(filename, optionPanel.meshOptions);
						if(!n)
							return;
						PADrend.getCurrentScene().addChild(n);
						var id=optionPanel.idTF.getText().trim();
						if(id!=""){
							PADrend.getSceneManager().registerNode(id,n);
						}	out("\nDone. ",(clock()-start)," sek\n");

						out("\nDone. ",(clock()-start)," sek\n");
					}
				);
				//meshLoadOptionPanel
				var optionPanel=f.createOptionPanel();
				optionPanel += "Mesh options";
				optionPanel++;

				optionPanel.meshOptions:=0;
				optionPanel += {
					GUI.LABEL			:	"AUTO_CENTER",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	optionPanel,
					GUI.DATA_ATTRIBUTE	:	$meshOptions,
					GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"AUTO_CENTER_BOTTOM",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	optionPanel,
					GUI.DATA_ATTRIBUTE	:	$meshOptions,
					GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER_BOTTOM
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"AUTO_SCALE",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	optionPanel,
					GUI.DATA_ATTRIBUTE	:	$meshOptions,
					GUI.DATA_BIT		:	MinSG.MESH_AUTO_SCALE
				};
				optionPanel++;
				optionPanel += gui.createLabel("Node options");
				optionPanel++;
				optionPanel += gui.createLabel("Node id:");
				optionPanel += optionPanel.idTF:=gui.createTextfield(100,15,"");
				optionPanel.idTF.setTooltip("The created Node is registered at the \nsceneManager with this id.");
				optionPanel.onSelectionChanged=fn(file){
					idTF.setText(file);
				};
				f.init();
			}
		},
    
		{
			GUI.LABEL		:	"Load Meshes ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a directory, read all meshes from that directory, and add them to the current scene.\nSupported types: .mmf, .obj, .ply, .md2, .mvbo, .ngc",
			GUI.ON_CLICK	:	fn() {

				var f=new GUI.FileDialog("Load all Meshes in folder",PADrend.getDataPath(),[".mmf",".obj",".ply"], fn(filename){

					var folder = this.getFolder();
					out("Load Meshes \"",folder,"\"...");
					PADrend.message("Load Meshs \""+folder+"\"...");
					showWaitingScreen();
					var start=clock();
					var count=0;
					foreach(Util.getFilesInDir(folder,[".obj",".ply",".mmf",".mvbo",".MVBO",".ngc", ".md2", ".MD2", ".xyz"]) as var file){
						 var n=MinSG.loadModel(file, optionPanel.meshOptions);
						if(!n)
							continue;
						PADrend.getCurrentScene().addChild(n);
						if((count++ % 10)==0)
							out(".");
//						out(file);
					}
					out("\nDone. ",(clock()-start)," sek\n");
				});
				f.folderSelector = true;
				//meshLoadOptionPanel
				var optionPanel=f.createOptionPanel();
				optionPanel += "Mesh options";
				optionPanel++;

				optionPanel.meshOptions:=0;
				optionPanel += {
					GUI.LABEL			:	"AUTO_CENTER",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	optionPanel,
					GUI.DATA_ATTRIBUTE	:	$meshOptions,
					GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"AUTO_CENTER_BOTTOM",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	optionPanel,
					GUI.DATA_ATTRIBUTE	:	$meshOptions,
					GUI.DATA_BIT		:	MinSG.MESH_AUTO_CENTER_BOTTOM
				};
				optionPanel++;
				optionPanel += {
					GUI.LABEL			:	"AUTO_SCALE",
					GUI.TYPE			:	GUI.TYPE_BIT,
					GUI.DATA_OBJECT		:	optionPanel,
					GUI.DATA_ATTRIBUTE	:	$meshOptions,
					GUI.DATA_BIT		:	MinSG.MESH_AUTO_SCALE
				};
				optionPanel++;
				optionPanel += gui.createLabel("Node options");
				optionPanel++;

				f.init();
			}
		},
		{
			GUI.LABEL		:	"Save Meshes ...",
			GUI.TOOLTIP		:	"Show a dialog to choose a directory, and write all meshes that are used by the current scene into that directory.\nSupported types: .mmf, .ply",
			GUI.ON_CLICK	:	fn() {
				var f=new GUI.FileDialog("Export Meshes",PADrend.getDataPath(),[""],fn(filename){
					var folder=this.getFolder();//IO.dirname(filename);
					out("Exporting meshes to ",folder,"\n");
					showWaitingScreen();
					if(optionPanel.exportType.getValue()=='mmf'){
						PADrend.getSceneManager().saveMeshesInSubtreeAsMMF(
								PADrend.getCurrentScene(),
								folder,
								optionPanel.exportRegisteredCB.isChecked());
					} else{ //ply
						PADrend.getSceneManager().saveMeshesInSubtreeAsPLY(
								PADrend.getCurrentScene(),
								folder,
								optionPanel.exportRegisteredCB.isChecked());
					}
					Util.flush(folder);
				});
				f.folderSelector = true;
				//meshExportOptionPanel
				var optionPanel=f.createOptionPanel();

				optionPanel += gui.createLabel("Mesh export options");
				optionPanel.nextRow(5);
				optionPanel += gui.createLabel("Export to: ");
				optionPanel.dirLabel:=gui.createLabel(100,20,"dir...",GUI.LOWERED_BORDER);
				optionPanel.dirLabel.setTooltip("This is the directory the meshes will be exported to.");
				optionPanel +=  optionPanel.dirLabel ;
				optionPanel.onDirChanged=fn(dir){
					dirLabel.setText(dir);
				};
				optionPanel.nextRow(5);
				optionPanel += optionPanel.exportRegisteredCB:=gui.createCheckbox("Export already registered nodes",false);
				optionPanel++;

				optionPanel += optionPanel.exportType:=gui.createRadioButtonSet("Export format:");
				optionPanel.exportType.addOption('mmf');
				optionPanel.exportType.addOption('ply');
				optionPanel.exportType.setValue('mmf');
				optionPanel.nextRow(30);
				{
					var b=gui.createButton(150,20,"Create new DBFS file");
					b.setTooltip("Create a .dbfs container file with the name in the file name box.");
					optionPanel += b;
					b.onClick=f->fn(){
						var files=getCurrentFiles();
						if(files.empty())
							return;
						var dbFile=files[0];
						var pPos = dbFile.find("://");
						if(pPos)
							dbFile=dbFile.substr(pPos+3);
						dbFile="dbfs://"+dbFile;
						if(!dbFile.endsWith(".dbfs"))
							dbFile += ".dbfs";
						out("Creating file:",dbFile,"\n");
						Util.saveFile(dbFile+"$./info.txt","MinSG dbfs file container\n"+Util.createTimeStamp());
						Util.flush(dbFile);
						refresh();
					};
				}
				optionPanel.nextRow(5);
				{
					var b = gui.createButton(150, 20, "Create new ZIP file");
					b.setTooltip("Create a .zip archive cotainer file with the name in the file name box.");
					optionPanel += b;
					b.onClick = f -> fn() {
						var files=getCurrentFiles();
						if(files.empty()) {
							return;
						}
						var archiveFile = files[0];
						var pPos = archiveFile.find("://");
						if(pPos) {
							archiveFile = archiveFile.substr(pPos+3);
						}
						archiveFile = "zip://" + archiveFile;
						if(!archiveFile.endsWith(".zip")) {
							archiveFile += ".zip";
						}
						out("Creating file: ", archiveFile, "\n");
						Util.saveFile(archiveFile + "$./info.txt", "MinSG archive file container\n" + Util.createTimeStamp() + "\n");
						Util.flush(archiveFile);
						refresh();
					};
				}

				f.init();
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
				fileDialog("Load Script",".",[".escript"],
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
		var sceneRootOptions = ["new MinSG.ListNode()"];
		if(MinSG.isSet($LooseOctree)) {
			sceneRootOptions += "new MinSG.LooseOctree()";
		}
		if(MinSG.isSet($RTree)) {
			sceneRootOptions += "new MinSG.RTree(2, 50)";
		}
	
		var textField = gui.create({
			GUI.TYPE				:	GUI.TYPE_TEXT,
			GUI.OPTIONS				:	sceneRootOptions,
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.7, 0]
		});
		container += textField;

		container += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"New scene",
			GUI.ON_CLICK			:	(fn(textField) {
											PADrend.createNewSceneRoot(textField.getData());
										}).bindLastParams(textField),
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
				var a=[];
				if(scene.isSet($name) && scene.name!="") a += scene.name;
				if(scene.isSet($constructionString) && scene.constructionString!="") a += "[ "+scene.constructionString+" ]";
				if(scene.isSet($filename) && scene.filename!="") a += "[ "+scene.filename+" ]";
				entry.nameLabel.setText( a.implode(" : "));
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

	{
		var m = [];
		
		m += "*Rendering flags*";

		foreach( ['BOUNDING_BOXES','SHOW_META_OBJECTS','NO_GEOMETRY','NO_STATES','FRUSTUM_CULLING','USE_WORLD_MATRIX','SHOW_COORD_SYSTEM'] as var flagName){
			m += {
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : flagName,
				GUI.DATA_PROVIDER : (fn(flagName){
					return (PADrend.getRenderingFlags() & MinSG.getAttribute(flagName))>0;
				}).bindLastParams(flagName),
				GUI.ON_DATA_CHANGED : (fn(data, flagName){
					var mask = MinSG.getAttribute(flagName);
					PADrend.setRenderingFlags( (PADrend.getRenderingFlags()-(PADrend.getRenderingFlags()&mask))| (data?mask:0) );
					systemConfig.setValue('PADrend.Rendering.flags',PADrend.getRenderingFlags());
				}).bindLastParams(flagName),
			
			};
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
			GUI.DATA_PROVIDER : fn(){ return PADrend.EventLoop.GLErrorChecking; },
			GUI.ON_DATA_CHANGED : fn(d){
				PADrend.EventLoop.GLErrorChecking = d;
				systemConfig.setValue('PADrend.Rendering.GLErrorChecking', PADrend.EventLoop.GLErrorChecking);
				if(PADrend.EventLoop.GLErrorChecking) {
					Rendering.enableGLErrorChecking();
				} else {
					Rendering.disableGLErrorChecking();
				}
			}
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
		gui.registerComponentProvider('PADrend_RenderingSettings',m);
	}

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
