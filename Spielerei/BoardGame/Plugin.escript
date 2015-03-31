/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/BoardGame/plugin.escript
 ** 2012-02 Programmier�bung
 **/

var plugin = new Plugin({
		Plugin.NAME : 'Spielerei/BoardGame',
		Plugin.DESCRIPTION : "Simple board games for practicing programming",
		Plugin.VERSION : 1.0,
		Plugin.REQUIRES : [],
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) :=fn(){
	module.on('PADrend/gui',this->fn(gui){
		gui.register('Spielerei.boardGames',[{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Board games",
			GUI.MENU : 'Spielerei_BoardGameMenu' 
		}]);
		
		gui.register('Spielerei_BoardGameMenu.imageViewer',fn(){
			var entries =[];
			foreach(Util.getFilesInDir(__DIR__+"/Games",['.escript']) as var file){
				entries += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : file.substr( file.rFind("/")+1 ),
					GUI.ON_CLICK : [file]=>fn(file){
						if(file.beginsWith("file://"))
							file = file.substr(7);
						load(file.substr(file)); // 
					}
				};
			}
			return entries;
		});
	});
    return true;
};


// ---------------------------------------------------------
return plugin;
