/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/***
 **    FileDialog
 **/
loadOnce(__DIR__+"/Factory_Components.escript");

GUI.FileDialog := new Type;
var T = GUI.FileDialog;

T._title @(private) := void;
T.currentFolder @(private) :=  void;
T.searchFilter @(private) := "";
T.endings @(private) := void;
T.dblClickTimer @(private) := 0;
T.onConfirm @(private) := void;

T.onDirectoryChanged @(init) := MultiProcedure;
T.onFilterChanged @(init) := MultiProcedure;
T.onTypesChanged @(init) := MultiProcedure;


// show only directories
T.folderSelector:=false;
T.initialFilename:=void;

// gui-elements
T.window @(private):= void;
T.dirInput @(private) := void;
T.fileInput@(private) := void;
T.filesBox@(private) := void;

// (optional)
T.optionPanel:=void;

// (static)
T.folderColor ::= new Util.Color4f( 0.3,0.3,1.0,1.0 );
T.zipFolderColor ::= new Util.Color4f( 1.0,0.3,1.0,1.0 );
T.dbfsFolderColor ::= new Util.Color4f( 0.6,0.1,0.6,1.0 );
T.folderCacheProvider ::= void; // ConfigManager|void
T.folderCacheEntry ::= "FileDialog.recentDirs"; 
T.folderCacheCount ::= 6;


//! (ctor)
T._constructor ::= fn(String title,String folder,[Array,void] _endings=void,_onConfirm=void){
    this._title = title;
    this.onConfirm = _onConfirm;

    this.updateDir(folder);
    this.updateEndings(_endings ? _endings : [""]);
};

//! (internal)
T.action @(private) ::= fn(){
    var filenames=getCurrentFiles();

    try{
        if(this.onConfirm){
			
			var param = filenames.implode(';');
			if(folderSelector){
				if(!Util.isDir(param))
					param = getFolder();
				if(!param.endsWith('/'))
					param+='/';
				if(param.beginsWith('file://'))
					param = param.substr(7);
			}
			
			this.onConfirm(param);
			
			// add folder to recent folders
			if(folderCacheProvider){
				var entries = folderCacheProvider.getValue(folderCacheEntry);
				entries.removeValue(this.getFolder());
				entries.pushFront(this.getFolder());
				while(entries.count()>folderCacheCount)
					entries.popBack();
				folderCacheProvider.setValue(folderCacheEntry,entries);
	
			}
//            out("Open ",filenames.implode(';'),"\n");
        }
    }catch(e){
        Runtime.warn(e);
    }
    this.window.setEnabled(false); // \todo cleanup!
};

//!	(public interface)
T.createOptionPanel ::= fn(width=200,height=240){
    this.optionPanel = gui.createPanel(width,height);
    this.optionPanel.onSelectionChanged := fn(filename){    };
    this.optionPanel.onDirChanged := fn(folder){    };
    
    // notify optionPanel when the directory has changed
    onDirectoryChanged +=  optionPanel->fn(folder){   	onDirChanged(folder);   };
    return this.optionPanel;
};


/*!	(public interface)
	Returns an array with all files currently in the fileInput field.	*/
T.getCurrentFiles ::= fn(){
    var filenames=this.fileInput.getData().split(';');
    var folder = getFolder();
    if(folder.length()>0)
        foreach(filenames as var key,var value){
        	if(value.contains("://")) // directory already given?
				filenames[key]=value;
			else
				filenames[key]=folder+'/'+value;
        }
	return filenames;
};

//!	(public interface)
T.getFolder ::= fn(){	return currentFolder;};

//!	(public interface)
T.getFilter ::= fn(){	return searchFilter;};

//!	(public interface)
T.getTypes ::= fn(){	return endings;};

//!	(public interface)
T.init ::= fn(){
    var windowWidth=400;
    var optionPanelWidth=0;
    
    if(optionPanel---|> GUI.Component){
        optionPanelWidth = optionPanel.getWidth();

//        optionPanel.setPosition(width,0);
        windowWidth += optionPanelWidth;
		
		optionPanel.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(optionPanel.getWidth(),-5) );
    }

	/*
	
	/---------------------------------------------------------\
	|  
	|  NavBar
	|
	| --------------------------------------------
	| 
	|  Files
	|
	| --------------------------------------------
	| 
	|  file
	| 
	|  <ok> <cancel>                         fileTypes
	|
	\---------------------------------------------------------/
	
	*/

    window=gui.createWindow(windowWidth,240,_title,GUI.NO_CLOSE_BUTTON|GUI.NO_MINIMIZE_BUTTON|GUI.ALWAYS_ON_TOP); // GUI.NO_RESIZE_PANEL|
    window.setPosition(500-windowWidth*0.5,300);
    
    var panel = gui.createContainer(400,240);
	panel.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(-1-optionPanelWidth,-5) );    
    
    window += panel;

    if(optionPanel---|> GUI.Component){
        window+=optionPanel;
    }

    dirInput = gui.create({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.TOOLTIP : "Directory",
		GUI.ON_DATA_CHANGED : this->fn(data){
			var s=data.trim();
			if(s.endsWith('/')) s=s.substr(0,-1);
			this.updateDir(s);
		},
		GUI.OPTIONS : folderCacheProvider ? folderCacheProvider.getValue(folderCacheEntry,["."]) : void,
		GUI.POSITION : [	GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
								GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, 5,0],
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -10 ,15 ] 
	});
	
    panel += dirInput;

    //----

    filesBox=gui.createTreeView(380,140);

	filesBox.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_ABS|GUI.HEIGHT_FILL_ABS,
			new Geometry.Vec2(5,20),new Geometry.Vec2(-10,folderSelector ? 32 : 45) );
			
    filesBox.onDataChanged = this->fn(data){
        if(data.empty())
            return;

        var lastChangeTime=this.dblClickTimer;
        this.dblClickTimer=clock();

        var lastFile=this.fileInput.getData();
        var newFile=data.map(fn(key,label){
				return label.isSet($filename) ? label.filename : label.fullPath;
		}).implode(';');

        this.fileInput.setData(newFile);
        // Load on double-click!
        if(lastFile==newFile && (this.dblClickTimer-lastChangeTime) < 0.400){
			var filename=data[0].getAttribute($filename);
			if( filename ){
				this.action();
			} else {
				this.updateDir(data[0].fullPath);
			}
        }
        if(this.optionPanel){
            this.optionPanel.onSelectionChanged(newFile);
        }

		// add file size to tooltip for last selected component
		var label=data.back();
		if(label.getAttribute($filename)){
			var tebibyte = 2.pow(40);
			var gibibyte = 2.pow(30);
			var mebibyte = 2.pow(20);
			var kibibyte = 2.pow(10);
	        var fileSize = Util.fileSize(label.fullPath);
	        if(fileSize > tebibyte) {
	        	label.setTooltip("Size: " + fileSize / tebibyte + " TiB");
	        } else if(fileSize > gibibyte) {
	        	label.setTooltip("Size: " + fileSize / gibibyte + " GiB");
	        } else if(fileSize > mebibyte) {
	        	label.setTooltip("Size: " + fileSize / mebibyte + " MiB");
	        } else if(fileSize > kibibyte) {
	        	label.setTooltip("Size: " + fileSize / kibibyte + " KiB");
	        } else {
	        	label.setTooltip("Size: " + fileSize + " B");
	        }
		}

    };
    panel += filesBox;

    //----

    fileInput = gui.create({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.TOOLTIP : "File",
		GUI.DATA_VALUE : this.initialFilename ? this.initialFilename : "Neu"+getTypes()[0] ,
		GUI.FLAGS : GUI.BORDER,
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -25 ,15 ],
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 5,25]
	});
    fileInput.setEnabled(!this.folderSelector);
    panel += fileInput;


	// search filter
	if(!folderSelector){
		var filter=gui.create({
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "F",
			GUI.TOOLTIP : "Search filter (click to open).\nShow only those files which contain the given\nsearch string.\nNOTE: The string is case sensitive!",
			GUI.DATA_VALUE : filter ,
			GUI.WIDTH : 15,
			GUI.HEIGHT : 15,
			GUI.MENU : this->fn(){
				return [
					"*Search filter*",
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_VALUE : getFilter(),
						GUI.ON_DATA_CHANGED : this->fn(data){ updateFilter(data.trim()); }
					}
				];
			},
			GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 5,25]
		});
		
		panel+=filter;
    }
    
    //----

	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Confirm",
		GUI.TOOLTIP : _title,
		GUI.ON_CLICK : this->action,
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 5,5],
		GUI.SIZE : [GUI.WIDTH_REL|GUI.HEIGHT_ABS , 0.25 ,15 ]
		
	};
	
	panel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Cancel",
		GUI.ON_CLICK : this->fn(){
			this.window.setEnabled(false);
			// todo: Delete Window
		},
		GUI.POSITION : [GUI.POS_X_REL|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 0.3,5],
		GUI.SIZE : [GUI.WIDTH_REL|GUI.HEIGHT_ABS , 0.25 ,15 ]

	};
    //----
    panel += gui.createLabel(37,15,"");

    //----

    // type info label
	var typeInfo=gui.create({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.TOOLTIP : "File types (seperated by ',')\nLeave empty to see all files.",
		GUI.DATA_VALUE : getTypes().implode(", ") ,
		GUI.OPTIONS : [getTypes().implode(", "),""], // initial value and no filtering as option,  
		GUI.WIDTH : 130,
		GUI.HEIGHT : 15,
		GUI.ON_DATA_CHANGED : this->fn(data){
			var types=[];
			foreach(data.split(",") as var type)
				types += type.trim();
			if(types.empty()) types+=""; // empty string --> show all files
			updateEndings(types);
		},
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 5,5]
	});
	
	onTypesChanged += typeInfo->fn(types){   	setData(types.implode(", ")); 	};
	
    panel+=typeInfo;

    // fill file box
    refresh();
    
    // update the file box whenever the directory,the types or the filter is changed
    onDirectoryChanged += 	this->fn(folder){   	refresh();   };
    onTypesChanged += 		this->fn(folder){   	refresh();   };
    onFilterChanged +=		this->fn(folder){   	refresh();   };
    
    window.activate();
};



//!	(public interface)
T.refresh := fn(){
    filesBox.clear();

	var folder = getFolder();

    dirInput.setData(folder);

    // add ".." entry
    if(folder.length()>1 && ! (folder.endsWith(".") || folder.endsWith("$")) ) {
        var label=gui.createLabel(300,20,">   [ .. ]");
        label.myFileDialog:=this;
        var path=folder.contains('/')?folder.substr(0,folder.rFind('/')):"";
        label.fullPath:=path;
        label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);

        if(path.beginsWith("zip"))
			label.setColor(zipFolderColor);
		else if(path.beginsWith("dbfs"))
			label.setColor(dbfsFolderColor);
		else
			label.setColor(folderColor);
        filesBox.add(label);
    }

	// leave dbfs or zip folder [..]
	if( (folder.beginsWith("dbfs://") || folder.beginsWith("zip://") ) && (folder.endsWith(".")|| folder.endsWith("$")) ){
        var label=gui.createLabel(300,20,">   [ .. ]");
        label.myFileDialog:=this;
        var path=folder.contains('/')?folder.substr(0,folder.rFind('/')):"";
        path="file://"+path.substr( path.find(":")+3 ); // strip "dbfs://"
        label.fullPath:=path;
        label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
        label.setColor(folderColor);
        filesBox.add(label);
    }

	// add directory entries
    var directories;
    try{
        directories=Util.dir(folder,Util.DIR_DIRECTORIES);

        if(!directories)
			directories=[];
    }catch(e){
        Runtime.warn(e);
        directories=[];
    }
    directories.sort();
    foreach(directories as var entry) {
    	// Isolate directory name.
    	var lastSlash = entry.length() - 1;
    	var secondLastSlash = entry.rFind('/', entry.length() - 2);
    	var length = lastSlash - secondLastSlash;
        var label = gui.createLabel(300, 17, ">   [ "
        				+ entry.substr(secondLastSlash + 1, length - 1) + " ]");

        label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
        label.myFileDialog := this;
        label.fullPath := entry;
        label.setColor( folderColor );
        filesBox.add(label);
    }

	// files
//	if(!this.folderSelector){
	{
		// support for db files
	    var dbFiles = Util.getFilesInDir(folder,['.dbfs']);
	    dbFiles.sort();
		foreach(dbFiles as var f){
	        var p=(f.contains('/') ? f.substr(f.rFind('/')+1) : f);
	        var label=gui.createLabel(300,15,
							">   [ "+p+" ]");
	//                if(font_small) label.setBitmapFont(font_small);
	        label.fullPath:="dbfs://"+folder+"/"+p+"$./";
	        label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
	        label.setColor( dbfsFolderColor );
	        filesBox.add(label);
	    }

    	// support for zip archives
    	var zipFiles = Util.getFilesInDir(folder, ['.zip']);
    	zipFiles.sort();
		foreach(zipFiles as var f) {
        	var p = (f.contains('/') ? f.substr(f.rFind('/') + 1) : f);
        	var label = gui.createLabel(300, 15, ">   [ " + p + " ]");
        	label.fullPath := "zip://" + folder + "/" + p + "$./";
        	label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
        	label.setColor( zipFolderColor );
        	filesBox.add(label);
    	}

	    var files = Util.getFilesInDir(folder,getTypes());
	    files.sort();
	    foreach(files as var f){
	        var filename=(f.contains('/') ? f.substr(f.rFind('/')+1) : f);

	    	if(!searchFilter.empty() && !filename.contains(searchFilter))
				continue;

	        var label=gui.createLabel(300,15,filename);
	        label.fullPath:=f;
	        label.filename:=filename;
	        label.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
	        filesBox.add(label);
	    }
	}

};

//! (internal)
T.updateDir @(private) ::= fn(newDir){

	// update directory selector
    if(newDir.beginsWith("file://")) // strip "file://"
		newDir=newDir.substr(7);
    if(newDir.endsWith("/")) // strip ending "/"
        newDir=newDir.substr(0,-1);
	if(newDir=="") // "" ---> "."
        newDir=".";

    if(currentFolder!=newDir){
		currentFolder=newDir;
		
		// notify listeners (e.g. call refresh() )
		onDirectoryChanged(newDir);
    }
};

//! (internal)
T.updateFilter @(private) ::= fn(String newFilter){
	searchFilter = newFilter;
	onFilterChanged(newFilter);
};

//! (internal)
T.updateEndings @(private) ::= fn(Array newTypes){
	endings = newTypes;
	onTypesChanged(newTypes);
};
// -------------------------------

// static heler function
GLOBALS.fileDialog:=fn(label,folder,ending,onConfirm){
    var dialog=new GUI.FileDialog(label,folder,(ending---|>Array)?ending:[ending],onConfirm);
    dialog.init();
    return;
};
