/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibGUIExt] Factory_Dialogs.escript
 **/
loadOnce(__DIR__+"/Factory_Components.escript");

/*! 

	File dialog					Dialog for selecting files.
		GUI.TYPE :				GUI.TYPE_FILE_DIALOG 
		GUI.LABEL :				The dialog's title.
		GUI.ENDINGS :			(optional) An Array of file endings. e.g. [".txt",".json"]
		GUI.DIR : 				(optional) The initial folder. e.g. "./resources"
		GUI.FILENAME : 			(optional) The initial filename. e.g. "new.txt" 
									if a complete path is given, the DIR option is ignored: "./resources/new.txt" 
		GUI.ON_ACCEPT :			(optional) Function called when the selection in the dialog is confirmed.
									The parameter is a string with the selected filenames 
									imploded with ';'. The this object is the dialog itself, 
									so that this.getFolder() gets the current folder.
		GUI.ON_FILE_CHANGED :	(optional) callback: fn( Array )
		GUI.ON_FOLDER_CHANGED :	(optional) callback: fn( String )
		GUI.OPTIONS : 			(optional) Array of components. Each component is placed in a separate row.

	Folder dialog				Dialog for selecting a folder.
		GUI.TYPE :				GUI.TYPE_FOLDER_DIALOG 
		GUI.LABEL :				The dialog's title.
		GUI.ENDINGS :			(optional) An Array of file endings. e.g. [".txt",".json"]
		GUI.DIR : 				(optional) The initial folder. e.g. "./resources"
		GUI.ON_ACCEPT :			(optional) Function called when the selection in the dialog is confirmed.
									The parameter is a string with the selected folder.
		GUI.OPTIONS : 			(optional) Array of components. Each component is placed in a separate row.


	Popup dialog				General dialog containing input components
		GUI.TYPE :				GUI.TYPE_POPUP_DIALOG 
		GUI.LABEL :				The dialog's title.
		GUI.ACTIONS : 			[ ["text",function] , ["text",function,tooltip] ...]
									Array of Arrays with a text(button label) and a function for 
									that button. If the function returns true; the window is kept open.
									Otherwise, it is closed. Optionally, the third entry in the array
									can be a tooltip.
		GUI.OPTIONS : 			(optional) Array of components. Each component is placed in a separate row and its size is adjusted to fit one row.
			or
		GUI.CONTENTS : 			(optional) Array of components. Each component is placed in a separate row -- its size is NOT adjusted.
		GUI.SIZE : 				(optional) [width,height]
*/
GUI.GUI_Manager.createDialog ::= fn(Map description){

	var input = new ExtObject;
	input.description := description;
	input.title := description.get(GUI.LABEL,"Dialog");
	
	var result = new ExtObject;
	result.dialog := void;

	var factory =  _dialogFactories[description[GUI.TYPE]];
	if(!factory){
		Runtime.warn("Unkown dialog type '"+description[GUI.TYPE]+"'");
		return;
	}
	(this->_dialogFactories[description[GUI.TYPE]])(input,result);
	
	return result.dialog;
};

GUI.GUI_Manager.openDialog ::= fn(Map description){
	var d = createDialog(description);
	if(d)
		d.init();
};

					
GUI.GUI_Manager._dialogFactories ::= {
	GUI.TYPE_FILE_DIALOG : fn(input,result){
		var dir = input.description.get(GUI.DIR,".");
		var filename;
		if(input.description[GUI.FILENAME]){
			filename = input.description[GUI.FILENAME];
			var p = filename.rFind('/');
			if(p){
				dir = filename.substr( 0, p );
				filename = filename.substr(p+1);
			}
		}
		
		
		var d = new (Std.require('LibGUIExt/FileDialog'))( input.title,
						dir,
						input.description.get(GUI.ENDINGS,[""]),
						input.description.get(GUI.ON_ACCEPT,fn(files){print_r(files);}));
		if(filename)
			d.initialFilename = filename;
		
		// add option panel
		var options = input.description[GUI.OPTIONS];
		if(options){
			var entries = [];
			var panelWidth = 100;
			foreach(this.createComponents(options) as var option){
				var entry = this.createComponent(option);
				entries += entry;
				entry.layout();
				if(entry.getWidth()>panelWidth)
					panelWidth = entry.getWidth();
			}

			var optionPanel = d.createOptionPanel(panelWidth+20);
			foreach( entries as var entry){
				optionPanel += entry;
				optionPanel++;
			}
		}
		if( input.description[GUI.ON_FILES_CHANGED])
			d.onSelectionChanged += input.description[GUI.ON_FILES_CHANGED];
		if( input.description[GUI.ON_FOLDER_CHANGED])
			d.onFolderChanged += input.description[GUI.ON_FOLDER_CHANGED];
		result.dialog = d;
	},
	GUI.TYPE_FOLDER_DIALOG : fn(input,result){
		var desc2 = input.description.clone();
		desc2[GUI.TYPE] = GUI.TYPE_FILE_DIALOG;
		var d = this.createDialog(desc2);
		d.folderSelector=true;
		result.dialog = d;
	},
	GUI.TYPE_POPUP_DIALOG : fn(input,result){
		var size = input.description.get(GUI.SIZE,[300,50]);
		var d = this.createPopupWindow(size[0],size[1],input.title);
		foreach(input.description[GUI.ACTIONS] as var action){
			d.addAction( (action---|>Array ? action : [action])...);
		}
		var options = input.description[GUI.OPTIONS];
		if(options){
			if(options.isA(String))// for debugging
				d._componentId := options;
			foreach(this.createComponents(options) as var option)
				d.addOption(option,true);
		}
		var contents = input.description[GUI.CONTENTS];
		if(contents){
			if(contents.isA(String))// for debugging
				d._componentId := contents;
			foreach(this.createComponents(contents) as var option)
				d.addOption(option,false);
		}
		result.dialog = d;
	},
	
};

// --------------------------------------------------

