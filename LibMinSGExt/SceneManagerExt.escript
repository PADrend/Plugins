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

var T = MinSG.SceneManagement.SceneManager;


// deprecated aliases. Remove after 2015-04!
MinSG.SceneManager := T;

T.IMPORT_OPTION_NONE ::= MinSG.SceneManagement.IMPORT_OPTION_NONE;
T.IMPORT_OPTION_REUSE_EXISTING_STATES ::= MinSG.SceneManagement.IMPORT_OPTION_REUSE_EXISTING_STATES;
T.IMPORT_OPTION_DAE_INVERT_TRANSPARENCY ::= MinSG.SceneManagement.IMPORT_OPTION_DAE_INVERT_TRANSPARENCY;
T.IMPORT_OPTION_USE_TEXTURE_REGISTRY ::= MinSG.SceneManagement.IMPORT_OPTION_USE_TEXTURE_REGISTRY;
T.IMPORT_OPTION_USE_MESH_HASHING_REGISTRY ::= MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_HASHING_REGISTRY;
T.IMPORT_OPTION_USE_MESH_REGISTRY ::= MinSG.SceneManagement.IMPORT_OPTION_USE_MESH_REGISTRY;
T.createImportContext ::= fn( p...){
	Runtime.warn( "sceneManager.createImportContext is deprecated!" );
	return MinSG.SceneManagement.createImportContext(this,p...);
};
T.loadCOLLADA ::= fn( p...){
	Runtime.warn( "sceneManager.loadCOLLADA is deprecated!" );
	return MinSG.SceneManagement.loadCOLLADA(this,p...);
};
T.loadMinSGFile ::= fn( p...){
	Runtime.warn( "sceneManager.loadMinSGFile is deprecated!" );
	return MinSG.SceneManagement.loadMinSGFile(this,p...);
};
T.saveMeshesInSubtreeAsPLY ::= fn( p...){
	Runtime.warn( "sceneManager.saveMeshesInSubtreeAsPLY is deprecated!" );
	return MinSG.SceneManagement.saveMeshesInSubtreeAsPLY(p...);
};
T.saveMeshesInSubtreeAsMMF ::= fn( p...){
	Runtime.warn( "sceneManager.saveMeshesInSubtreeAsMMF is deprecated!" );
	return MinSG.SceneManagement.saveMeshesInSubtreeAsMMF(p...);
};
T.saveMinSGFile ::= fn( p...){
	Runtime.warn( "sceneManager.saveMinSGFile is deprecated!" );
	return MinSG.SceneManagement.saveMinSGFile(this, p...);
};
T.saveMinSGString ::= fn( p...){
	Runtime.warn( "sceneManager.saveMinSGString is deprecated!" );
	return MinSG.SceneManagement.saveMinSGString(this, p...);
};
T.saveCOLLADA ::= fn( p...){
	Runtime.warn( "sceneManager.saveCOLLADA is deprecated!" );
	return MinSG.SceneManagement.saveCOLLADA(p...);
};

//------------------------

T.__searchPaths @(init,private) := Array; 
T.__workspaceRootPath @(private) := false; // String or false; The folder in which the current

T.addSearchPath ::= 		fn(String p){	if(!this.__searchPaths.contains(p)) this.__searchPaths += p; };
T.getWorkspaceRootPath ::= 	fn(){ return this.__workspaceRootPath;	};
T.setWorkspaceRootPath ::= 	fn([String,false] p){	this.__workspaceRootPath = p;	};

//! Node|false sceneManager.loadScene( filename of .minsg or .dae [, Number importOptions=0])
T.loadScene ::= fn(String filename, Number importOptions=0){
	var start = clock();
	var sceneRoot = void;
	if(filename.endsWith(".dae") || filename.endsWith(".DAE")) {
	    outln("Loading Collada: ",filename);

		sceneRoot = MinSG.SceneManagement.loadCOLLADA(this, filename, importOptions);
	} else {
	    Util.info("Loading MinSG: ",filename,"\n");
	    var importContext = MinSG.SceneManagement.createImportContext(this,importOptions);
    
	    var f = new Util.FileName( filename );
	    importContext.addSearchPath( f.getFSName() + "://" + f.getDir() );
	    
	    foreach(this.__searchPaths as var p)
			importContext.addSearchPath(p);
	    
    	var nodeArray = MinSG.SceneManagement.loadMinSGFile(importContext,filename);
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

T._getSearchPaths ::= fn(){
	var arr = [];
	if( this.__workspaceRootPath )
		arr += this.__workspaceRootPath;
	arr.append( this.__searchPaths );
	return arr;
};

T.locateFile ::= fn(String relFilename){
	return this.getFileLocator().locateFile(relFilename);
};

T.getFileLocator ::= fn(){
	var l = new Util.FileLocator;
	foreach(this._getSearchPaths() as var p)
		l.addSearchPath(p);
	return l;
};

return T;
