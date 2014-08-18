/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/PostProcessingEffects.escript
 ** 2009-11 Urlaubsprojekt...
 **/

//!	PPEffectPlugin ---|> Plugin
GLOBALS.PPEffectPlugin := new Plugin({
			Plugin.NAME : "Effects_PPEffects",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Various post-processing effects",
			Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn, Ralf Petring",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : [],		
			Plugin.EXTENSION_POINTS : [ 
				/* [ext:Effects_PPEffects_querySearchPaths]
				 * Called to query the effect search paths.
				 * @param   array
				 * @result  void
				 */
				'Effects_PPEffects_querySearchPaths',
			
			]
});

static defaultEffect = Std.DataWrapper.createFromEntry( PADrend.configCache, 'Effects.ppEffectDefault',false);
static activeEffectFile = new Std.DataWrapper;
static activeEffect = new Std.DataWrapper;
static plugin = PPEffectPlugin;

PPEffectPlugin.init @(override) := fn(){
	
	Util.registerExtension('PADrend_Init',fn(){
		initMenus();
		if(defaultEffect())
			plugin.loadAndSetEffect(defaultEffect());
	});
	Util.registerExtension('Effects_PPEffects_querySearchPaths',fn(Array paths){
		paths += __DIR__+"/PPEffects";
	});
	
	static revoce = new MultiProcedure;
	activeEffect.onDataChanged += fn(effect){
		activeEffectFile( false ); // clear file name 
		revoce();
		if(effect){
			// use low priority to include other afterFrame-effects (like selected node's annotation)
			revoce += Util.registerExtensionRevocably('PADrend_AfterRenderingPass',	fn(PADrend.RenderingPass pass){ activeEffect() && activeEffect().endPass(pass);	},Extension.LOW_PRIORITY );
			revoce += Util.registerExtensionRevocably('PADrend_BeforeRenderingPass',fn(PADrend.RenderingPass pass){ activeEffect() && activeEffect().beginPass(pass);	});

			// use low priority to include other afterFrame-effects (like selected node's annotation)
			revoce += Util.registerExtensionRevocably('PADrend_AfterRendering',		fn(...){ activeEffect() && activeEffect().end();	},Extension.LOW_PRIORITY); 
			revoce += Util.registerExtensionRevocably('PADrend_BeforeRendering',	fn(...){ activeEffect() && activeEffect().begin();	});
		}
	};
	return true;
};

//! name -> filename
static scanEffectFiles = fn(){
	var files = new Map; 
	var effectFolders = [];
	Util.executeExtensions( 'Effects_PPEffects_querySearchPaths',effectFolders );
	foreach(effectFolders as var folder){
		foreach(Util.getFilesInDir( folder,['.escript']) as var file){
			var name = file.substr(file.rFind("/")+1);
			name = name.substr(0,name.rFind("."));
			if(name.beginsWith("_"))
				continue;
			if(file.beginsWith("file://"))
				file = file.substr(7);
			files[name] = file;
		}
	}
	return files;
};

static fillOptionWindow = fn( window, effect){
	window.destroyContents();
	if(effect){
		var c = effect.getOptionPanel();
		if(c.isA(GUI.Component))
			window += c;
		else{
			var panel = gui.create({
					GUI.TYPE : GUI.TYPE_PANEL,
					GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS,0,0]
			});
			foreach(gui.createComponents(c) as var entry){
				panel +=entry;
				panel++;
			}
			window += panel;
		}
	}
};

static initMenus = fn(){
	static optionWindow;
	
	static createOtionWindow = fn(effect){
		if(!optionWindow){
			optionWindow = gui.createWindow(400,200,"EffectOptions");
			optionWindow.setPosition(300,300);
			activeEffect.onDataChanged += [optionWindow] => fn(optionWindow, newEffect){
				if(optionWindow.isDestroyed())
					return $REMOVE;
				fillOptionWindow(optionWindow,newEffect);
			};

		}
		fillOptionWindow( optionWindow,effect );
		
		optionWindow.setEnabled(true);
	};

	gui.registerComponentProvider('Effects_MainMenu.postprocessing',{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "PP effects",
		GUI.MENU_WIDTH : 170,
		GUI.MENU : 'Effects_PPMenu'
	});
					
	gui.registerComponentProvider('Effects_PPMenu',this->fn(){
								
		var effects = scanEffectFiles();
		var m=[];

		m+="*PostProcessing*";

		m+={
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Options...",
			GUI.ON_CLICK : fn(){
				createOtionWindow(activeEffect());
			}
		};

		m+={
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Disable",
			GUI.ON_CLICK : fn() {
				PADrend.executeCommand(fn(){PPEffectPlugin.setEffect(false);});
			}
		};
		m+={
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Set as default",
			GUI.ON_CLICK : fn() {
				defaultEffect(activeEffectFile());
				gui.closeAllMenus();
			},
			GUI.TOOLTIP : "Sets the active effect as default effect.\nThe default effect is loaded when the program is started."
		};

		m+='----';
		foreach(effects as var name, var file){
			m+={
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : defaultEffect()==file ? name+" (default)" : name,
				GUI.ON_CLICK : [file] => fn(file) {
					PADrend.executeCommand( [file]=>fn(file){PPEffectPlugin.loadAndSetEffect(file); });
				},
				GUI.TOOLTIP : file
			};
		}
		return m;
	});

};


PPEffectPlugin.defaultEffect := defaultEffect; // alias for public access

PPEffectPlugin.setEffect := fn(newEffect){
	activeEffect( newEffect );
};

PPEffectPlugin.loadAndSetEffect := fn(filename){
	if(filename){
		setEffect( load(filename) );
		activeEffectFile(filename);
	}else{
		setEffect(void);
	}
};

return PPEffectPlugin;
