/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2011 Sascha Brandt
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
declareNamespace($Tools);

Tools.ExportScenePlugin := new Plugin({
            Plugin.NAME : "Tools/ExportScene",
            Plugin.VERSION : "1.0",
            Plugin.DESCRIPTION : "Exporting Scenes to .minsg format",
            Plugin.AUTHORS : "rpetring",
            Plugin.OWNER : "All",
            Plugin.REQUIRES : ['NodeEditor']
});

var plugin = Tools.ExportScenePlugin;

/*! ---|> Plugin */
plugin.init @(override) := fn(){
    { // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.register('Tools_ToolsMenu.importExport',[ // group header
				"*Import / Export*"
			]);
			gui.register('Tools_ToolsMenu.importExport_export',{
				GUI.LABEL:"Export Scene",
				GUI.ON_CLICK:this->createWindow,
				GUI.TOOLTIP:"exports the whole content of a scene\n(including meshes & textures) to minsg format"
			});
		});
    }
    return true;
};

plugin.popup := void;


plugin.D3FACT := 0;
plugin.ALL_IN_ONE := 1;
plugin.LARGE_SCENE := 2;
plugin.HANDY := 3;

plugin.folder := new Util.FileName(PADrend.configCache.getValue("export_path", PADrend.getScenePath()));
plugin.type := PADrend.configCache.getValue("export_type", plugin.ALL_IN_ONE);
plugin.name := PADrend.configCache.getValue("export_name", "scene");
plugin.complete := PADrend.configCache.getValue("export_complete", true);

plugin.exporter := new Map();

plugin.createWindow:=fn(){

	if(popup && gui.isCurrentlyEnabled(popup))
		return;

    popup = gui.createPopupWindow( 400,300,"Export Scene");

    popup.addOption({
        GUI.TYPE : GUI.TYPE_SELECT,
        GUI.LABEL : "export",
        GUI.OPTIONS : [[true, "selected scene"],[false, "selected node"]],
        GUI.DATA_OBJECT:    this,
        GUI.DATA_ATTRIBUTE : $complete
    });
    popup.addOption({
        GUI.TYPE : GUI.TYPE_FILE,
        GUI.LABEL : "folder",
        GUI.ENDINGS:["folders"],
        GUI.ON_DATA_CHANGED : this->fn(data){this.folder = new Util.FileName(data);},
        GUI.DATA_VALUE: this.folder,
    });
    popup.addOption({
        GUI.TYPE : GUI.TYPE_TEXT,
        GUI.LABEL : "scene name",
        GUI.DATA_OBJECT:    this,
        GUI.DATA_ATTRIBUTE : $name
    });
    popup.addOption({
        GUI.TYPE : GUI.TYPE_SELECT,
        GUI.LABEL : "export type",
        GUI.OPTIONS : [
            [this.D3FACT, "d3fact", void, "stores all meshes and textures \nwith the minsg file in one folder"],
            [this.ALL_IN_ONE, "all in one", void, "all textures and meshes are \nembedded into the minsg file"],
            [this.LARGE_SCENE, "multiple zips", void, "creates a minsg file and \nstores textures and meshes in a \nsmall number of zip files"],
            [this.HANDY,"multiple folders", void, "creates a minsg file and \nstores all meshes and textures in a \nsmall number of folders"]
        ],
        GUI.DATA_OBJECT:    this,
        GUI.DATA_ATTRIBUTE : $type
    });

    popup.addAction( "Export", this->exportScene );
    popup.addAction( "Cancel" );
    popup.init();
};

plugin.exportScene := fn(){
    outln("+++ Scene Export +++");
    if(this.folder.getFSName() != "file"){
        Runtime.warn("scene export is not supported for this file system provider ("+this.folder.getFSName()+")");
    }
    else{
        outln("export:", complete ? "scene" : "node");
        outln("folder:", folder);
        outln("  name:", name);
        outln("  type:", type);
        showWaitingScreen();
        PADrend.configCache.setValue("export_path", folder);
        PADrend.configCache.setValue("export_type", type);
        PADrend.configCache.setValue("export_name", name);
        PADrend.configCache.setValue("export_complete", complete);
        if(!exporter[type])
            Runtime.warn("no exporter for this export type (the roof is on fire)");
        else{
            var scene = complete ? PADrend.getCurrentScene() : NodeEditor.getSelectedNode();
            var meshes = new Set;
            var textures = new Set;
            this.collectMeshesAndTextures(scene, meshes, textures);
            outln("saving meshes (",meshes.count(),") and textures (",textures.count(),")");
			var minsgFile = (this -> this.exporter[type])(folder, name, meshes, textures);
            outln("saving scene ", minsgFile);
            MinSG.SceneManagement.saveMinSGFile( PADrend.getSceneManager(),new Util.FileName(minsgFile),[scene]);
            out("...flush... this may realy take some more minutes\n");
            Util.flush(minsgFile);
            // Saving the file may alter its properties (e.g. name), so re-select it to provoce an update where necessary.
			executeExtensions('PADrend_OnSceneSelected',PADrend.getCurrentScene() );
        }
    }
    outln("--- Scene Export ---");
};

plugin.collectMeshesAndTextures := fn(MinSG.Node scene, Set meshes, Set textures){
    var nodes = MinSG.collectNodes(scene);
    foreach(nodes as var node){
        if(node.isA(MinSG.GeometryNode) && node.getMesh()){
            var mesh = node.getMesh();
            mesh.setFileName(new Util.FileName());
            meshes += mesh;
        }
        if(MinSG.isSet($BlueSurfels)){
			var surfels = Std.module("BlueSurfels/Utils").locateSurfels(node);
			if(surfels){
				surfels.setFileName(new Util.FileName());
				meshes += surfels;
			}
		}
		{ /// LOD Meshes
			if(node.isA(MinSG.GeometryNode)){
				var gaList = void;
				if(node.isInstance()){
					gaList = node.getPrototype().getNodeAttribute('lodMeshes');
				}
				else{
					gaList = node.getNodeAttribute('lodMeshes');
				}
				if(gaList){
					foreach(gaList as var lod){
						lod.setFileName(new Util.FileName());
						meshes += lod;
					}
				}
			}
		}
        var states = node.getStates();
        while(!states.empty()){
            var state = states.popBack();
            if(state ---|> MinSG.TextureState && state.getTexture()){
                var texture = state.getTexture();
                texture.setFileName(new Util.FileName());
                textures += texture;
            }
            else if(state ---|> MinSG.GroupState){
                states.append(state.getStates());
            }
        }
    }
};

plugin.fillLeft := fn(Number i){
    return "0" * ( 7 - (i).log(10).floor() ) + i;
};

plugin.exporter[plugin.ALL_IN_ONE] = fn(Util.FileName folder, String name, Set meshes, Set textures){
    foreach(meshes as var mesh)
        mesh.setFileName(new Util.FileName());
    foreach(textures as var texture){
        texture.setFileName(new Util.FileName());
    }
    return folder.toString()+name+".minsg";
};

plugin.exporter[plugin.D3FACT] = fn(Util.FileName folder, String name, Set meshes, Set textures){

    var prefix = folder.toString() + name + "/";
    Util.createDir(prefix);

    var index = 0;
    foreach(meshes as var mesh){
        var filename = new Util.FileName(prefix + "mesh_" + fillLeft(++index) + ".mmf");
        mesh.setFileName(filename);
        Rendering.saveMesh(mesh, filename);
    }

    index = 0;
    foreach(textures as var texture){
        var filename = new Util.FileName(prefix + "texture_" + fillLeft(++index) + ".png");
        texture.setFileName(filename);
        Rendering.saveTexture(renderingContext, texture, filename);
    }
    
    {
    	// create a screenshot of the scene with the current camera and save it together with the scene
		PADrend.renderScene( PADrend.getRootNode(), PADrend.getActiveCamera(), PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers() );
	    var filename = new Util.FileName(prefix + name + ".png");
		var texture = Rendering.createTextureFromScreen();
		Rendering.saveTexture(renderingContext, texture, filename);
	}
	
	Util.flush("file://");
    return prefix + name + ".minsg";
};


plugin.exporter[plugin.LARGE_SCENE] = fn(Util.FileName folder, String name, Set meshes, Set textures){

    var maxFilesInZip = (2).pow(16) - 1000; // has to be smaller than 2^16, zip library does not support more files in a single zip
    var maxDataInZip = (2).pow(30); // 1 GB, leads to zip files ~< 500 MB

    var prefix = "zip://" + folder.getDir() + name;
    var postfix = ".zip$./";

    var availableMemory = maxDataInZip;
    var zipCount = 0;
    var counter = maxFilesInZip;
    foreach(meshes as var mesh){

        var size = mesh.getVertexCount() * mesh.getVertexDescription().getVertexSize();
        size += mesh.getIndexCount() * 4; // TODO and till done don't use out of core!!!

        if(counter >= maxFilesInZip || availableMemory < size){
            availableMemory = maxDataInZip;
            counter = 0;
			zipCount++;
			Util.flush("zip://");
        }
        availableMemory -= size;
        counter++;

        var filename = prefix + "_meshes_" + zipCount + postfix + fillLeft(counter) + ".mmf";
        mesh.setFileName(filename);
        Rendering.saveMesh(mesh, filename);
    }

    availableMemory = maxDataInZip;
    zipCount = 0;
    counter = maxFilesInZip;
    foreach(textures as var texture){

        var size = texture.getDataSize();

         if(counter >= maxFilesInZip || availableMemory < size){
            availableMemory = maxDataInZip;
            counter = 0;
			zipCount++;
			Util.flush("zip://");
        }
        availableMemory -= size;
        counter++;

        var filename = prefix + "_textures_" + zipCount + postfix + fillLeft(counter) + ".png";
        texture.setFileName(filename);
        Rendering.saveTexture(renderingContext, texture, filename);
    }
    
    Util.flush("zip://");
    return "file://" + folder.getDir() + name + ".minsg";
};

plugin.exporter[plugin.HANDY] = fn(Util.FileName folder, String name, Set meshes, Set textures){

    var maxFilesInFolder = 10000;

    var prefix = "file://" + folder.getDir() + name;
    var postfix = "/";

    var folderCount = 0;
    var counter = maxFilesInFolder;
    foreach(meshes as var mesh){

        if(counter >= maxFilesInFolder){
            counter = 0;
			folderCount++;
			Util.flush("file://");
            Util.createDir(prefix + "_meshes_" + folderCount + postfix);
        }
        counter++;

        var filename = prefix + "_meshes_" + folderCount + postfix + fillLeft(counter) + ".mmf";
        mesh.setFileName(filename);
        Rendering.saveMesh(mesh, filename);
    }

    folderCount = 0;
    counter = maxFilesInFolder;
    foreach(textures as var texture){

        if(counter >= maxFilesInFolder){
            counter = 0;
			folderCount++;
			Util.flush("file://");
            Util.createDir(prefix + "_textures_" + folderCount + postfix);
        }
        counter++;

        var filename = prefix + "_textures_" + folderCount + postfix + fillLeft(counter) + ".png";
        outln(filename);
        texture.setFileName(filename);
        Rendering.saveTexture(renderingContext, texture, filename);
    }
    
    Util.flush("file://");
    return "file://" + folder.getDir() + name + ".minsg";
};

return plugin;
