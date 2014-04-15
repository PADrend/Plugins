/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

// ------------------------------
// SceneManager extensions

var T = MinSG.SceneManager;

T._shaderSearchPaths @(init) := Array;

//! Node|false sceneManager.loadScene( filename of .minsg or .dae [, Number importOptions=0])
T.loadScene ::= fn(filename, Number importOptions=0){
	if(!filename)
		return false;
	var start=clock();
	var sceneRoot = void;
	if(filename.endsWith(".dae") || filename.endsWith(".DAE")) {
	    outln("Loading Collada: ",filename);

		sceneRoot = this.loadCOLLADA(filename, importOptions);
	} else {
	    Util.info("Loading MinSG: ",filename,"\n");
	    var importContext = this.createImportContext(importOptions);
	    foreach(this._shaderSearchPaths as var p)
			importContext.addShaderSearchPath(p);
	    
    	var nodeArray = this.loadMinSGFile(importContext,filename);
    	if(!nodeArray){
			Runtime.warn("Could not load scene from file '"+filename+"'");
    	}else if(nodeArray.count()>1){
			sceneRoot = new MinSG.ListNode;
			foreach(nodeArray as var node)
				sceneRoot += node;
			outln("Note: The MinSG-file ",filename," contains more than a single top level node. Adding a new toplevel ListNode.");
    	}else if(nodeArray.size()==1){
			sceneRoot=nodeArray[0];
    	}
	}
    if(!sceneRoot)
        return false;
    sceneRoot.filename := filename;
	Util.info("\nDone. ",(clock()-start)," sek\n");
	return sceneRoot;
};

return T;
