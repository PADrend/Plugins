/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static plugin = new Plugin({
		Plugin.NAME : 'Tools/MovemenConstraints',
		Plugin.DESCRIPTION : "Restrict movement of the camera.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []

});


static enabled = new Std.DataWrapper(false);
static height;
static restrictXRotation;
static restrictHeight;

plugin.init @(override) := fn(){
	var update = fn(...){	if(enabled()) applyConstraints( PADrend.getDolly() );	};

	enabled.onDataChanged += update;
	
	height = DataWrapper.createFromConfig( systemConfig,'Tools.MovementConstraints.height',0.0);
	height.onDataChanged += update;
		
	restrictXRotation = DataWrapper.createFromConfig( systemConfig,'Tools.MovementConstraints.restrictXRotation',true);
	restrictXRotation.onDataChanged += update;

	restrictHeight = DataWrapper.createFromConfig( systemConfig,'Tools.MovementConstraints.restrictHeight',true);
	restrictHeight.onDataChanged += update;

	registerExtension('PADrend_Init',fn(){
		gui.registerComponentProvider('Tools_ToolsMenu.movementContraints',[
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Movement constraints",
				GUI.MENU : 'Tools_MovementContraintsMenu'
			}
		]);

		gui.registerComponentProvider('Tools_MovementContraintsMenu.main',[
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Enabled",
				GUI.DATA_WRAPPER : enabled
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Restrict Height",
				GUI.DATA_WRAPPER : restrictHeight
			},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Height",
				GUI.DATA_WRAPPER : height
			},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "No X-Rotation",
				GUI.DATA_WRAPPER : restrictXRotation
			},
		]);

	});
	
	static clear = new Std.MultiProcedure;
	enabled.onDataChanged += fn(b){
		clear();
		if(b){
			var dolly = PADrend.getDolly();
			//! \see MinSG.TransformationObserverTrait
			Traits.assureTrait(dolly,Std.require('LibMinSGExt/Traits/TransformationObserverTrait'));
			
			clear += Std.addRevocably( dolly.onNodeTransformed, [dolly] => fn(dolly,node){
				static active;
				if(!active && dolly == node){
					active = true;
					try{
						applyConstraints(dolly);
					}catch(e){
						active = false;
						throw e;
					}
					active = false;
				}
			});
		}
	};
	
	return true;
};

static applyConstraints = fn(dolly){
	var srt = dolly.getRelTransformationSRT();
	var changed = false;
	if(restrictHeight()){
		if(! (srt.getTranslation().y()~=height() ) ){
			changed = true;
			srt.setTranslation( [srt.getTranslation().x(), height(),srt.getTranslation().z() ]); 
		}
	}
	if(restrictXRotation()){
		if(! (srt.getUpVector().y()~=1.0 ) ){
			changed = true;
			srt.setRotation( [srt.getDirVector().x(), 0,srt.getDirVector().z()] , [0,1,0] ); 
		}
	}
	if(changed)
		dolly.setRelTransformation(srt);
	
};

plugin.enabled := enabled;
return plugin;
// ----------------------------------------------------------------------------
