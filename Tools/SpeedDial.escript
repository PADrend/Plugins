/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools_SpeedDial] Tools/SpeedDial.escript
 ** 2010-02 Claudius
 **/


var plugin = new Plugin({
		Plugin.NAME : 'Tools_SpeedDial',
		Plugin.DESCRIPTION : "Quick access to preset-scripts (F3).",
		Plugin.VERSION : 2.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : ['PADrend','PADrend/GUI','PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : [ 

			/* [ext:Tools_SpeedDial_QueryFolders]
			 * @param   [String*]
			 * Called whenever the preset list is opened; allows adding searchpaths for 
			 * including additional preset-folder. 
			 */
			'Tools_SpeedDial_QueryFolders'
		]
});

/*! ---|> Plugin
	Plugin initialization.	*/
plugin.init @(override) := fn() {

	var presetPaths = Std.DataWrapper.createFromEntry(systemConfig,'Tools.SpeedDial.folders',[PADrend.getUserPath()+"presets/"]);
	
	{ // remove after 2014-06
		
		var oldPath = Std.DataWrapper.createFromEntry(systemConfig,'Tools.SpeedDial.folder',void);
		if(oldPath()){
			if(!presetPaths().contains(oldPath()))
				presetPaths( [oldPath()].append(presetPaths())  );
			oldPath(void);
		}
	}
	this.TAG_FOR_THE_UNTAGGED := " - UNTAGGED - ";

	this.mainWindowTags := Std.DataWrapper.createFromEntry(PADrend.configCache,'Tools.SpeedDial.mainWindowTags',[TAG_FOR_THE_UNTAGGED]);
	this.mainWindowTags.onDataChanged += this->fn(...){ this.showWindow(); };

	this.sceneToolTags := Std.DataWrapper.createFromEntry(PADrend.configCache,'Tools.SpeedDial.sceneToolTags',[TAG_FOR_THE_UNTAGGED]);

	// Register ExtensionPointHandler:
	Util.registerExtension('PADrend_KeyPressed',this->fn(evt) {
		if(evt.key == Util.UI.KEY_F3){
			if(!window || !window.isVisible()){
				showWindow();
				window.activate();
			}
			else {
				window.setEnabled(false);
			}
			return true;
		}else if(evt.key == Util.UI.KEY_ESCAPE && window && window.isVisible()){
			window.setEnabled(false);
			return true;
		}
		return false;
	});
	
	module.on('PADrend/gui',this->fn(gui){
		gui.register('PADrend_SceneToolMenu.presets',{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Presets",
			GUI.FLAGS : GUI.BACKGROUND,
			GUI.MENU_WIDTH : 200,
			GUI.MENU : this->fn(){
				@(once) static AdjustableBackgroundColorTrait = Std.module('LibGUIExt/Traits/AdjustableBackgroundColorTrait');
				var pMenu=[{
					GUI.TYPE : GUI.TYPE_MENU,
					GUI.LABEL : "Tags",
					GUI.MENU : [sceneToolTags] =>this->getTagFilterMenuEntries
				}];
				foreach(this.filterPresets(this.collectPresets(),this.sceneToolTags()) as var preset){
					var c = gui.create({
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : preset.name,
						GUI.FLAGS : GUI.BACKGROUND,
						GUI.ON_CLICK : [preset.path] => this->fn(path){
							this.loadPreset(path);
							gui.closeAllMenus();
						},
						GUI.TOOLTIP : preset.getFullDescription()
					},200,true);
					if(preset.bgColor)
						Std.Traits.addTrait(c, AdjustableBackgroundColorTrait,preset.bgColor);
					pMenu+=c;
				}
				return pMenu;
			}
		});
		gui.register('Tools_SpeedDial_MainConfigMenu.tagSelection', 
										[mainWindowTags] =>this->getTagFilterMenuEntries );
	});
	Util.registerExtension('Tools_SpeedDial_QueryFolders',[presetPaths] => fn(presetPaths, Array paths){
		paths.append(presetPaths());
	});
	Util.requirePlugin('PADrend/RemoteControl').registerFunctions({
		'SpeedDial.getPresetList' : this->fn( [String,void] tag=void){ // tag
			var presets = this.collectPresets();
			if(tag)
				presets = this.filterPresets(presets,[tag]);
			
			var presetNames = [];
			foreach(presets as var preset)
				presetNames+=preset.name;
			return presetNames;
		},
		'SpeedDial.executePreset' : this->fn(name){
			var presets = [];
			foreach(this.collectPresets() as var preset){
				if(preset.name == name){
					this.loadPreset(preset.path);
					return true;
				}
			}
			return false;
		}
	});

	this.window := false;
	this.panel := false;
	return true;
};

plugin.stripExtension := fn(String name){
	return name.substr(0,name.rFind(".")); // strip extension
};

//! @return { file -> path }
plugin.getPresetFiles := fn(){
	var paths = [];
	executeExtensions('Tools_SpeedDial_QueryFolders',paths);
	var files = [];
	foreach(paths as var path){
		files.append(Util.getFilesInDir(path,['.escript','.minsg']));
	}
	var m = new Map;
	foreach(files as var filename){
		filename = filename.substr( filename.find("://")+3); // strip protocol
		var name = this.stripExtension(filename.substr(filename.rFind("/")+1));
		m[name] = filename;
	}
	return m;
};

plugin.createScreenshot := fn(path){
	var width=256;
	var height=256;

	// create fbo
	var fbo=new Rendering.FBO;

	renderingContext.pushAndSetFBO(fbo);
	var colorTexture=Rendering.createStdTexture(width,height,true);
	fbo.attachColorTexture(renderingContext,colorTexture);
	var depthTexture=Rendering.createDepthTexture(width,height);
	fbo.attachDepthTexture(renderingContext,depthTexture);
	out(fbo.getStatusMessage(renderingContext),"\n");

	frameContext.beginFrame();
	// set camera
	var tempCamera=new MinSG.CameraNode;
	tempCamera.setRelTransformation( PADrend.getActiveCamera().getWorldTransformationMatrix() );
	tempCamera.setViewport( new Geometry.Rect(0,0,width,height));
	tempCamera.applyVerticalAngle(90);
	frameContext.pushAndSetCamera(tempCamera);

	// render scene
	renderingContext.clearScreen(PADrend.getBGColor());
	PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());

	frameContext.endFrame();

	renderingContext.popFBO();
	// restore old camera
	frameContext.popCamera();

	// save image
	var imageFile = this.stripExtension(path) + ".png";
	PADrend.message("Exporting screenshot to "+imageFile);
	Rendering.saveTexture(renderingContext,colorTexture,imageFile);
};

plugin.Preset := new Type;
{
	var T = plugin.Preset;
	T.path := void;
	T.name := void;
	T.tags := void;
	T.description := void;
	T.bgColor := void;

	T._constructor ::= fn(_path,_name){
		this.path = _path;
		this.name = _name;
		if(IO.isFile(path+".info")){
			var config = new Std.JSONDataStore(true);
			config.init(this.path+".info");

			this.bgColor = Std.DataWrapper.createFromEntry( config,"bgColor", [0.5,0.5,0.5,0.5] );
			this.tags = Std.DataWrapper.createFromEntry( config,"tags", [] );

			// backward compatibility \todo remove after 2014-01
			var enabled = config.getValue('enabled');
			if(void!=enabled){
				config.unset('enabled');
				if(enabled == false && !this.tags().contains('disabled')){
					var tags = this.tags().clone();
					tags+='disabled';
					this.tags(tags);
				}
			}
			this.description := Std.DataWrapper.createFromEntry( config,"description", "" );
		}
	};
	T.hasTags ::= fn(){	return this.tags && !this.tags().empty();	};
	T.getFullDescription ::= fn(){
		var str = "Name: "+name+"\nPath: "+path;
		if(description && !description().empty())
			str += "\n"+description();
		if(hasTags())
			str += "\nTags: "+this.tags().implode(", ");
		return str;
	
	};
	T.getTags ::= fn(){
		return this.tags ? this.tags() : [];
	};
	
}

//! Returns an array of all found presets
plugin.collectPresets := fn(){
	var presets = [];
	foreach(this.getPresetFiles() as var name,var path){ //! { filename -> path }
		presets += new Preset(path,name);
	}
	return presets;
};


plugin.collectPresetsByTag := fn(Array tags){
	return filterPresets(this.collectPresets(),tags);
};

//! Returns an array of tags of all found presets
plugin.collectUsedTags := fn(){
	var tagSet = new Set; // collect used tags
	foreach(this.collectPresets() as var preset){
		if(preset.tags){
			foreach(preset.tags() as var tag)
				tagSet += tag;
		}
	}
	return tagSet.toArray();
};
plugin.filterPresets := fn(Array presets, Array tags){
	return presets.clone().filter( [new Set(tags)] => this->fn(vTagsSet, p){
		var tags = p.getTags();
		if(tags.empty()){
			return  vTagsSet.contains(this.TAG_FOR_THE_UNTAGGED);
		}else{
			foreach(tags as var tag){
				if(vTagsSet.contains(tag))
					return true;
			}
		}
		return false;
	});
};
plugin.getTagFilterMenuEntries := fn(DataWrapper selectedTags){
	var entries = [];
	entries += "Tags:";
	var usedTags = [TAG_FOR_THE_UNTAGGED].append(this.collectUsedTags());
	var vTags = selectedTags();
	foreach(usedTags as var tag){
		entries += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : tag,
			GUI.DATA_VALUE : vTags.contains(tag),
			GUI.ON_DATA_CHANGED : [selectedTags,tag] => this->fn(selectedTags,tag, b){
				var arr = selectedTags().clone();
				if(b){
					if(!arr.contains(tag)){
						arr += tag;
						selectedTags( arr );
					}
				}else if(arr.contains(tag)){
					arr.removeValue(tag);
					selectedTags( arr );
				}
			}
		};
	}
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Select all",
		GUI.ON_CLICK : [selectedTags] => this->fn(selectedTags){
			selectedTags([TAG_FOR_THE_UNTAGGED].append(this.collectUsedTags()));
			gui.closeAllMenus();
		}
	};
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Select none",
		GUI.ON_CLICK : [selectedTags] => this->fn(selectedTags){
			selectedTags([]);
			gui.closeAllMenus();
		}
	};
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Invert selection",
		GUI.ON_CLICK : [selectedTags] => this->fn(selectedTags){
			var all = new Set([TAG_FOR_THE_UNTAGGED].append(this.collectUsedTags()));
			var visible = new Set(selectedTags());
			selectedTags( (all.getSubstracted(visible)).toArray() );
			gui.closeAllMenus();
		}
	};
	return entries;
};


plugin.createPresetContextMenu := fn(preset){
	var entries = ["*"+preset.path+"*"];
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Edit...",
		GUI.ON_CLICK : [preset.path] => fn(path){	Util.openOS(path);	}
	};
	entries += {
		GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
		GUI.LABEL : "Create screenshot",
		GUI.ON_CLICK : [preset.path] => this->fn(path){
			createScreenshot(path);
			showWindow(); // update
		}
	};
	if(preset.description){
		entries += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Description",
			GUI.DATA_WRAPPER : preset.description
		};
		entries += '----';
		entries += {
			GUI.TYPE : GUI.TYPE_COLOR,
			GUI.LABEL : "Background color",
			GUI.DATA_WRAPPER : preset.bgColor
		};
		entries += '----';
		var tags = preset.tags().clone();
		tags += "";
		var usedTags = this.collectUsedTags();
		usedTags += "";
		foreach( tags as var tag){
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_VALUE : tag,
				GUI.ON_DATA_CHANGED : [preset,tag] => fn(preset,oldTag, newTag){
					var tags = preset.tags().clone();
					tags.removeValue(oldTag);
					newTag = newTag.trim();
					tags.removeValue(newTag);
					if(!newTag.empty())
						tags += newTag;
					 preset.tags(tags);
				},
				GUI.OPTIONS : usedTags
			};
		}
	}else{
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Create config",
			GUI.ON_CLICK : [preset] => this->fn(preset){
				IO.saveTextFile(preset.path+".info","{}");
				showWindow(); // update
			}
		};
	}
	return entries;
};

plugin.showWindow:=fn(){
	@(once) static AdjustableBackgroundColorTrait = Std.module('LibGUIExt/Traits/AdjustableBackgroundColorTrait');

	// create/resize window
	var width=[renderingContext.getWindowWidth(),1024].min();
	var height=[renderingContext.getWindowHeight(),1024].min()-20;
	if(!this.window){
		this.window = gui.createWindow( width,height,"SpeedDial");
		this.panel = gui.create({
			GUI.TYPE : GUI.TYPE_PANEL,
			GUI.SIZE : GUI.SIZE_MAXIMIZE,
			GUI.CONTEXT_MENU_WIDTH : 300,
			GUI.CONTEXT_MENU_PROVIDER : 'Tools_SpeedDial_MainConfigMenu'
		});
		panel.enableAutoBreak();
		window.add(panel);
	}else{
		this.window.setWidth(width);
		this.window.setHeight(height);
		panel.destroyContents();
//		outln("destroyContents");
	}

	window.setPosition(0,20);

	var activePresets = this.filterPresets(this.collectPresets(),this.mainWindowTags());

	// add buttons
	var buttonCount = [activePresets.count(),1].max();
	var columns = buttonCount.sqrt().ceil();
	var rows = (buttonCount/columns).ceil();
	var bWidth=(width/columns)-20 ;
	var bHeight=(height/rows)-20 ;
	var maxIconWidth = bWidth - 5;
	var maxIconHeight = bHeight - 5;

	foreach( activePresets as var preset){
		if(preset.hasTags()){
			preset.tags.onDataChanged += this->fn(newValue){
				this.showWindow();
			};
		}
		var b = gui.create({
			GUI.TYPE 		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	preset.name + (preset.hasTags() ? "\n["+preset.getTags().implode(", ") + "] " : ""),
			GUI.HEIGHT		:	bHeight,
			GUI.WIDTH		:	bWidth,
			GUI.FLAGS		:	preset.bgColor ? (GUI.BACKGROUND | GUI.FLAT_BUTTON) : 0,
			GUI.ON_CLICK	:	[preset.path] => this->loadPreset,
			GUI.TOOLTIP		:	preset.getFullDescription(),
			GUI.CONTEXT_MENU_WIDTH : 250,
			GUI.CONTEXT_MENU_PROVIDER : [preset] => this->createPresetContextMenu
		});
		if(preset.bgColor){
			//! \see AdjustableBackgroundColorTrait
			Std.Traits.addTrait( b, AdjustableBackgroundColorTrait, preset.bgColor);
		}
		
		panel += b;

		// add icon
		foreach([".bmp",".png"] as var ending){
			var f = preset.path.replaceAll({".escript":ending,".minsg":ending});
			if(!Util.isFile(f))
				continue;
			var image=gui.loadImage(f);
			image.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER,
				new Geometry.Vec2(0,0) );

			// Maximize the diagonal of the image and keep the aspect ratio.
			var iWidth = image.getImageWidth();
			var iHeight = image.getImageHeight();
			// Intersection of straight line with vertical plane.
			var iconHeight = maxIconWidth * iHeight / iWidth;
			if(iconHeight <= maxIconHeight) {
				image.setWidth(maxIconWidth);
				image.setHeight(iconHeight);
			} else {
				// Intersection of straight line with horizontal plane.
				var iconWidth = maxIconHeight * iWidth / iHeight;
				image.setWidth(iconWidth);
				image.setHeight(maxIconHeight);
			}
			b+=image;
			break;
		}
	}
	window.setEnabled(true);
};

plugin.loadPreset:=fn(filename){
	if(window)
		window.setEnabled(false);
	PADrend.message("Preset: '"+filename+"'");
	try {
		if(filename.endsWith('.escript')){
			load(filename);
		}else{
			var s = PADrend.loadScene(filename);
			PADrend.selectScene(s);
		}
	} catch(e) {
		Runtime.log(Runtime.LOG_ERROR,e);
	}
};

return plugin;
// ------------------------------------------------------------------------------
