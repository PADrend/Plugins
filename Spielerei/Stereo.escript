/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Effects] Effects/Stereo.escript
 ** 2009-11 Urlaubsprojekt...
 **/
 //! ---|> Plugin
var plugin = new Plugin({
		Plugin.NAME : ' Effects/Stereo',
		Plugin.DESCRIPTION : "Render in stereo mode.",
		Plugin.VERSION : 0.3,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "Claudius",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});

/*!	---|> Plugin	*/
plugin.init @(override) :=fn(){
	this.enabled := DataWrapper.createFromConfig(systemConfig,'Effects.Stereo.enabled',false);
	this.rOffset := DataWrapper.createFromConfig(systemConfig,'Effects.Stereo.rOffset',"0.06 0 0");

	registerExtension('PADrend_Init',this->fn(){
		gui.registerComponentProvider('Spielerei.stereo',[
			"*Stereo mode*",
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "SideBySide",
				GUI.DATA_WRAPPER : this.enabled
			},
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "rOffset",
				GUI.DATA_WRAPPER : this.rOffset
			},
			'----'
		]);

		// enabled
		this.enabled.onDataChanged += this->fn(b){
			if(b)
				registerExtension('PADrend_BeforeRendering',this->this.ex_BeforeRendering);
		};
		this.enabled.forceRefresh();
		
		// right eye offset
		this.rOffset.onDataChanged += fn(value){
			var values = [];
			foreach(value.split(" ") as var s){
				values+=parseJSON(s);
			}
			if(values.count()!=3 || !values[0]){
				values = [0,0,0];
			}
			PADrend.getDolly().setObserverOffset(values);
		};
		this.rOffset.forceRefresh();
	});
	
	return true;
};

//! [ext:PADrend_BeforeRendering]
plugin.ex_BeforeRendering:=fn(renderingPasses){
	if(!this.enabled())
		return $REMOVE;

	var defaultPassFound = false;
	var newPasses = [];
	var dolly = PADrend.getDolly();
	foreach(renderingPasses as var pass){
		
		// only modify the "default" pass
		if(pass.getId()!="default"){
			newPasses += pass;
			continue;
		}
		defaultPassFound = true;
		
		{ // left
			// extract camera from dolly without observerOffset
			dolly.setObserverOffsetEnabled(false);
			var originalCamera = dolly.getCamera();
			var camera = originalCamera.clone();
			camera.setMatrix( originalCamera.getWorldMatrix());
			camera.setViewport( originalCamera.getViewport().clone().setWidth(originalCamera.getViewport().getWidth()*0.5) );
			
			newPasses += new PADrend.RenderingPass(pass.getId()+"_left", pass.getRootNode(),camera,pass.getRenderingFlags(),pass.getClearColor());
		}

		{ // right
			// extract camera from dolly with observerOffset
			dolly.setObserverOffsetEnabled(true);
			var originalCamera = dolly.getCamera();
			var camera = originalCamera.clone();
			camera.setMatrix( originalCamera.getWorldMatrix());
			camera.setViewport( originalCamera.getViewport().clone().setWidth(originalCamera.getViewport().getWidth()*0.5).setX(originalCamera.getViewport().getWidth()*0.5) );
			dolly.setObserverOffsetEnabled(false);
			
			newPasses += new PADrend.RenderingPass(pass.getId()+"_right", pass.getRootNode(),camera,pass.getRenderingFlags(),pass.getClearColor());
		}
	}
	renderingPasses.swap(newPasses);
	
	if(!defaultPassFound){
		Runtime.warn("No 'default' rendering pass found.");
	}
};

// ---------------------------------------------------------
return plugin;
