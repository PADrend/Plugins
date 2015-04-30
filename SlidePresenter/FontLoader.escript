/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

 
 // EXPERIMENTAL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 
// ---------------------------

//! \todo  cache folder
	
////////	gui.setCacheFolderProvider( fn(){
////////		var folder = PADrend.getUserPath()+"/.cache";
////////		if(!Util.isDir(folder)){
////////			outln("Creating cache folder '"+folder+"'...");
////////			Util.createDir(folder);
////////		}
////////		return folder;
////////	});
////////	

static getCacheFolder = fn(){
	var p = PADrend.getUserPath()+"/.cache";
	if(! Util.isDir(p)){
		Util.createDir(p);
	}
	return p;
};



static gui = Std.module('PADrend/gui');

var fontContainer = getCacheFolder()+"/dejavu-fonts-ttf-2.34.zip";
if(!Util.isFile(fontContainer)){
	var url = "http://heanet.dl.sourceforge.net/project/dejavu/dejavu/2.34/dejavu-fonts-ttf-2.34.zip";
	outln("Donwloading ",url,"...");
	var content = Util.loadFile(url);
	Util.saveFile(fontContainer, content);
	outln("Stored in ",fontContainer,"(", (content.dataSize()/1024).round(),"kb)");

//		if(Util.isFile(fontFile)){
}
if(Util.isFile(fontContainer)){
	foreach(["DejaVuSans.ttf","DejaVuSans-Bold.ttf",] as var file){
		var target = getCacheFolder()+"/"+file;
		outln("Checking "+target);
		if(!Util.isFile(target)){
			var fontFile = "zip://"+fontContainer+"$dejavu-fonts-ttf-2.34/ttf/"+file;
			outln("Extract '"+file+"'...");
			var content = Util.loadFile(fontFile);
			Util.saveFile(target, content);
		}
//			outln("Stored in ",fontContainer,"(", (content.dataSize()/1024).round(),"kb)");
	}
	
	
}

static  chars = "◼ !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyzäöüßÄÖÜ{|}~";

var FontCreator = new ExtObject;
FontCreator.createNormalFont := fn(Number size){
	return GUI.BitmapFont.createFont(getCacheFolder()+"/DejaVuSans.ttf",size, chars);
};
FontCreator.createBoldFont := fn(Number size){
	return GUI.BitmapFont.createFont(getCacheFolder()+"/DejaVuSans-Bold.ttf",size, chars);
};
return FontCreator;
