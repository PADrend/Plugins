/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools] Tools/ConvertFolder.escript
 ** 2010-10 rpetring ...
 **/
var plugin = new Plugin({
            Plugin.NAME : "Tools/ImportScene",
            Plugin.VERSION : "1.0",
            Plugin.DESCRIPTION : "Conversion of Folders to MinSG Scenes",
            Plugin.AUTHORS : "rpetring",
            Plugin.OWNER : "All",
            Plugin.REQUIRES : ['NodeEditor']
});

plugin.convert := fn(){

    PADrend.configCache.setValue("import_default_directory", importDir);
    PADrend.configCache.setValue("import_reset_ambient_colors", resetAmbientColors);
    PADrend.configCache.setValue("import_invert_transparency", invertTransparency);
    PADrend.configCache.setValue("import_recursive", recursive);
    PADrend.configCache.setValue("import_first_file", first);
    PADrend.configCache.setValue("import_last_file", last);
    PADrend.configCache.setValue("import_addAlpha", addAlphaTest);
    PADrend.configCache.setValue("import_adddCullFace", addCullFace);
    PADrend.configCache.setValue("import_adCHCpp", addCHCpp);
    PADrend.configCache.setValue("import_addTransparency", addTransparency);
	PADrend.configCache.setValue("import_addPhong", addPhong);
	PADrend.configCache.setValue("import_fixTextures", fixTextures);
	PADrend.configCache.setValue("import_removeBlending", removeBlending);

	var scenes = import();
	
	var scene = new MinSG.ListNode();
	foreach(scenes as var s)
		scene.addChild(s);

    if(fixTextures)
        fixTextureErrors(scene);
	
	if(resetAmbientColors){
		out("resetting ambient colors ...\n");
		scene.traverseStates(fn (parent, state) {
			if(state ---|> MinSG.MaterialState){
				var diff = state.getDiffuse();
				state.setAmbient(new Util.Color4f(diff.r() * 0.5, diff.g() * 0.5, diff.b() * 0.5, diff.a()));
			}
		});
		
// 		out("resetting ambient colors ...\n");
// 		var nodes = MinSG.collectNodes(scene, MinSG.Node);
// 		foreach(nodes as var node){
// 			var states = node.getStates();
// 			foreach(states as var state){
// 				if(state ---|> MinSG.GroupState){
// 					var ss = state.getStates();
// 					foreach(ss as var s){
// 						if(s ---|> MinSG.MaterialState){
// 							var diff=s.getDiffuse();
// 							s.setAmbient(new Util.Color4f(diff.r() * 0.5, diff.g() * 0.5, diff.b() * 0.5, diff.a()));
// 							out("resetting ambient colors ...\n");
// 						}
// 					}
// 					if(state.getStates().count()==0)
// 						node.removeState(state);
// 				}
// 				else if(state ---|> MinSG.MaterialState){
// 					var diff=state.getDiffuse();
// 					state.setAmbient(new Util.Color4f(diff.r() * 0.5, diff.g() * 0.5, diff.b() * 0.5, diff.a()));
// 					out("resetting ambient colors ...\n");
// 				}
// 			}
// 		}
	}
	
	if(removeBlending){
		out("removing BlendingStates ...\n");
		scene.traverseStates(fn (parent, state) {
			if(state ---|> MinSG.BlendingState){
				parent.removeState(state);
			}
		});
// 		var nodes = MinSG.collectNodes(scene, MinSG.Node);
// 		foreach(nodes as var node){
// 			var states = node.getStates();
// 			foreach(states as var state){
// 				if(state ---|> MinSG.GroupState){
// 					var ss = state.getStates();
// 					foreach(ss as var s){
// 						if(s ---|> MinSG.BlendingState){
// 							state.removeState(s);
// 						}
// 					}
// 					if(state.getStates().count()==0)
// 						node.removeState(state);
// 				}
// 				else if(state ---|> MinSG.BlendingState){
// 					node.removeState(state);
// 				}
// 			}
// 		}
	}
	
	scene.name := "imported scene";
    if(addCullFace){
        var cull = new MinSG.CullFaceState();
        cull.setCullingEnabled(false);
        scene.addState(cull);
    }
	if(addAlphaTest) {
		var alphaTestState = new MinSG.AlphaTestState();
		var alphaTestParams = alphaTestState.getParameters();
		alphaTestParams.setMode(Rendering.Comparison.GREATER);
		alphaTestParams.setReferenceValue(0.1);
		alphaTestState.setParameters(alphaTestParams);
		scene.addState(alphaTestState);
	}
    MinSG.moveStatesIntoLeaves(scene);
    if(addPhong){
        var phong = new MinSG.ShaderState();
		var path = "resources/Shader/universal2/";
		var vs = [path+"universal.vs",path+"sgHelpers.sfn"];
		var fs = [path+"universal.fs",path+"sgHelpers.sfn"];
		foreach(["shading_phong","color_standard","texture","shadow_disabled","effect_disabled"] as var f){
			vs+=path+f+".sfn";
			fs+=path+f+".sfn";
		}
        MinSG.initShaderState(phong, vs,[],fs,Rendering.Shader.USE_UNIFORMS);
        scene.addState(phong);
    }
    if(addTransparency)
        scene.addState(new MinSG.TransparencyRenderer());
    if(addCHCpp)
        scene.addState(new MinSG.CHCppRenderer());

	GLOBALS.registerScene(scene);
	GLOBALS.selectScene(scene);
};

plugin.fixTextureErrors := fn(scene){

	var nodes = MinSG.collectGeoNodes(scene);
	var count = 0;
	foreach(nodes as var node){
		var states = node.getStates();
		var texstates = [];
		var texunits = [0, 0, 0, 0, 0];
		var texcoords = [0, 0, 0, 0, 0];
		
		var m = new Map();
		foreach(states as var state){
			var first = true;
			if(state ---|> MinSG.TextureState){
				var name = state.getTexture().getFileName();
				if(name.toString() == "file://" || m.containsKey(name.toString())){
					if(first){
//					outln("found duplicated or invalid textures");
						first = false;
                    }
//					outln("removing duplicated or invalid texture: ", name.toString());
					node.removeState(state);
				}
				else{
					m[name.toString()] = true;
				}
			}
			else if (state ---|> MinSG.GroupState){
                var stst = state.getStates();
                foreach(stst as var st){
                    if(st ---|> MinSG.TextureState){
                        var name = st.getTexture().getFileName();
                        if(name.toString() == "file://" || m.containsKey(name.toString())){
                            if(first){
        //                  outln("found duplicated or invalid textures");
                                first = false;
                            }
        //                  outln("removing duplicated or invalid texture: ", name.toString());
                            state.removeState(st);
                        }
                        else{
                            m[name.toString()] = true;
                        }
                    }
                }
            }
		}
		states = node.getStates();
		
		foreach(states as var state){
			if(state ---|> MinSG.TextureState){
				texstates += state;
				texunits[state.getTextureUnit()]++;
			}
		}
		var vd = node.getMesh().getVertexDescription();
		if(vd.getAttribute(Rendering.VertexAttributeIds.TEXCOORD0)){
			texcoords[0]++;
		}
		if(vd.getAttribute(Rendering.VertexAttributeIds.TEXCOORD1)){
			texcoords[1]++;
		}
		if(vd.getAttribute(Rendering.VertexAttributeIds.TEXCOORD2)){
			texcoords[2]++;
		}
		if(vd.getAttribute(Rendering.VertexAttributeIds.TEXCOORD3)){
			texcoords[3]++;
		}
		if(vd.getAttribute(Rendering.VertexAttributeIds.TEXCOORD4)){
			texcoords[4]++;
		}
		
		if(texstates.count() > 0 && texcoords.max() == 0){
			outln("textures without coords, removing all textures from node.");
			foreach(texstates as var state)
				node.removeState(state);
			continue;
		}
		states = node.getStates();
		
		if(texstates.count() > 5){
			outln("more than five textures found, removing all textures except five from node.");
			while(texstates.count() > 5){
				var state = texstates.popBack();
				outln("removing:", state.getTexture().getFileName().toString() );
				node.removeState(state);
				texunits[state.getTextureUnit()]--;
			}
		}
		states = node.getStates();
		
		if(texunits.max() > 1){
			outln("textures with same units, changing units in state.");	
			var count = 0;
			foreach(texstates as var state){
				texunits[state.getTextureUnit()]--;
				state.setTextureUnit(count++);	
				texunits[state.getTextureUnit()]++;
			}		
		}
		
		if(texunits.sum() > texcoords.sum()){
		
			outln("to few texcoords, duplicating.");
			
			var src;
			if(texcoords[0] == 1)
				src = Rendering.VertexAttributeIds.TEXCOORD0;
			else if(texcoords[1] == 1)
				src = Rendering.VertexAttributeIds.TEXCOORD1;
			else if(texcoords[2] == 1)
				src = Rendering.VertexAttributeIds.TEXCOORD2;
			else if(texcoords[3] == 1)
				src = Rendering.VertexAttributeIds.TEXCOORD3;
			else if(texcoords[4] == 1)
				src = Rendering.VertexAttributeIds.TEXCOORD4;
			else
				outln(__FILE__,__LINE__, "Error in Texture configuration");
			
			if(texcoords[0] == 0)
				Rendering.copyVertexAttribute(node.getMesh(), src, Rendering.VertexAttributeIds.TEXCOORD0);
			if(texcoords[1] == 0)
				Rendering.copyVertexAttribute(node.getMesh(), src, Rendering.VertexAttributeIds.TEXCOORD1);
			if(texcoords[2] == 0)
				Rendering.copyVertexAttribute(node.getMesh(), src, Rendering.VertexAttributeIds.TEXCOORD2);
			if(texcoords[3] == 0)
				Rendering.copyVertexAttribute(node.getMesh(), src, Rendering.VertexAttributeIds.TEXCOORD3);
			if(texcoords[4] == 0)
				Rendering.copyVertexAttribute(node.getMesh(), src, Rendering.VertexAttributeIds.TEXCOORD4);
		}
	}
};

plugin.import := fn(){

	var scenes = [];

	out("open input folder... " + importDir + " may take a while...\n");
    var files=Util.dir(importDir, Util.DIR_FILES | (recursive?Util.DIR_RECURSIVE:0) );
	files.filter( fn(name){ return name.endsWith(".minsg") || name.endsWith(".obj") || name.endsWith(".ply") || name.endsWith(".mmf") || name.endsWith(".dae") || name.endsWith(".DAE"); });
	files.sort();
	
	out("found ",files.count(), " files\n");
	
	var flags =	  MinSG.SceneManager.IMPORT_OPTION_USE_TEXTURE_REGISTRY
				| MinSG.SceneManager.IMPORT_OPTION_USE_MESH_REGISTRY
				| MinSG.SceneManager.IMPORT_OPTION_USE_MESH_HASHING_REGISTRY;
	if(invertTransparency)
		flags |= MinSG.SceneManager.IMPORT_OPTION_DAE_INVERT_TRANSPARENCY;
	var context = PADrend.getSceneManager().createImportContext(flags);

	var x = 0;
	foreach(files as var file) {
			
		x++;
		if(x<first) continue;
		if(x>last) break;
		
		var pos = file.rFind(".");
		var ext = file.substr(pos);
		out ("\rLoading(", x, "/", files.count(), ") ", file);

		var loadedScene = void;
		try {
			if(ext == ".dae" || ext == ".DAE"){
				loadedScene = PADrend.getSceneManager().loadCOLLADA(context, file);
			}
			else if(ext == ".minsg")
				loadedScene = PADrend.getSceneManager().loadMinSG(context, file);
			else
				loadedScene = MinSG.loadModel(file);
		} catch (e) {
			Runtime.log(Runtime.LOG_ERROR,e);
			continue;
		}

		if(loadedScene ---|> MinSG.Node){
			scenes += loadedScene;
		}
	}
	return scenes;
};

// gui options
plugin.importDir := PADrend.configCache.getValue("import_default_directory", PADrend.getScenePath());
plugin.first := PADrend.configCache.getValue("import_first_file",1);
plugin.last := PADrend.configCache.getValue("import_last_file",(2).pow(20));
plugin.resetAmbientColors := PADrend.configCache.getValue("import_reset_ambient_colors", false);
plugin.invertTransparency := PADrend.configCache.getValue("import_invert_transparency", false);
plugin.recursive := PADrend.configCache.getValue("import_recursive", false);
plugin.addAlphaTest := PADrend.configCache.getValue("import_addAlpha", false);
plugin.addCullFace := PADrend.configCache.getValue("import_adddCullFace", false);
plugin.addCHCpp := PADrend.configCache.getValue("import_addCHCpp", true);
plugin.addTransparency := PADrend.configCache.getValue("import_addTransparency", true);
plugin.addPhong := PADrend.configCache.getValue("import_addPhong", true);
plugin.fixTextures := PADrend.configCache.getValue("import_fixTextures", true);
plugin.removeBlending := PADrend.configCache.getValue("import_removeBlending", true);

plugin.popup := void;

plugin.createWindow := fn(){

	popup = gui.createPopupWindow(400, 300, "Import Scene");

	popup += {
		GUI.LABEL:"Import folder (or file):",
		GUI.TYPE:GUI.TYPE_FILE,
        GUI.ENDINGS:["folders"],
		GUI.DATA_OBJECT:this,
		GUI.DATA_ATTRIBUTE:$importDir,
        GUI.TOOLTIP:"the selected import folder."
	};
	popup += {
		GUI.LABEL:"First",
		GUI.TYPE:GUI.TYPE_RANGE,
		GUI.RANGE:[0,20],
		GUI.RANGE_STEPS:20,
		GUI.RANGE_FN_BASE:2,
		GUI.DATA_OBJECT:this,
		GUI.DATA_ATTRIBUTE:$first,
        GUI.TOOLTIP:"files with index smaller first are ignored during import. \nusefull for testing if complete import takes to long."
	};
	popup += {
		GUI.LABEL:"Last",
		GUI.TYPE:GUI.TYPE_RANGE,
		GUI.RANGE:[0,20],
		GUI.RANGE_STEPS:20,
		GUI.RANGE_FN_BASE:2,
		GUI.DATA_OBJECT:this,
		GUI.DATA_ATTRIBUTE:$last,
        GUI.TOOLTIP:"files with index greater last are ignored during import. \nusefull for testing if complete import takes to long."
	};
	popup += {
		GUI.LABEL:"reset ambient colors",
		GUI.TYPE:GUI.TYPE_BOOL,
		GUI.DATA_OBJECT:this,
		GUI.DATA_ATTRIBUTE:$resetAmbientColors,
		GUI.TOOLTIP:"sets all ambient values to 0.5 times the diffuse value."
	};
	popup += {
		GUI.LABEL:"invert transparency (collada)",
		GUI.TYPE:GUI.TYPE_BOOL,
		GUI.DATA_OBJECT:this,
		GUI.DATA_ATTRIBUTE:$invertTransparency,
        GUI.TOOLTIP:"should be enabled when importing 3ds Max files."
	};
    popup += {
        GUI.LABEL:"recurse into subdirectories",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$recursive,
        GUI.TOOLTIP:"when enabled, the import folder is recursively searched for scene & model files."
    };
    popup += {
        GUI.LABEL:"fix texture errors",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$fixTextures,
        GUI.TOOLTIP:"when enabled, several problems with textures from collada files are fixed."
    };
    popup += {
        GUI.LABEL:"add CHC++ Renderer",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$addCHCpp,
        GUI.TOOLTIP:"add a CHC++ renderer to the created scene?"
    };
    popup += {
        GUI.LABEL:"add transparency renderer",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$addTransparency,
        GUI.TOOLTIP:"add a transparency renderer to the created scene?"
    };
    popup += {
        GUI.LABEL:"add cull face state",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$addCullFace,
        GUI.TOOLTIP:"add a cull face state to the created scene?"
    };
    popup += {
        GUI.LABEL:"add phong shader",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$addPhong,
        GUI.TOOLTIP:"add a phong shader to the created scene?"
    };
    popup += {
        GUI.LABEL:"add alpha test state",
        GUI.TYPE:GUI.TYPE_BOOL,
        GUI.DATA_OBJECT:this,
        GUI.DATA_ATTRIBUTE:$addAlphaTest,
        GUI.TOOLTIP:"add a alpha test state to the created scene?"
	};
	popup += {
		GUI.LABEL:"remove blending states",
		GUI.TYPE:GUI.TYPE_BOOL,
		GUI.DATA_OBJECT:this,
		GUI.DATA_ATTRIBUTE:$removeBlending,
		GUI.TOOLTIP:"remove all blending states from the scene?"
	};
    popup.addAction( "Convert", this->convert);
    popup.addAction( "Cancel" );
    popup.init();
};

/*!	---|> Plugin */
plugin.init @(override) := fn(){
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('Tools_ToolsMenu.importExport_import',{
				GUI.LABEL:"Import Scene",
				GUI.ON_CLICK:this->fn() {
					if(!popup || !gui.isCurrentlyEnabled(popup))
						createWindow();
				},
				GUI.TOOLTIP:"imports all scenes and meshes in a directory to a single scene"
			});
		});
    }
	return true;
};


return plugin;

