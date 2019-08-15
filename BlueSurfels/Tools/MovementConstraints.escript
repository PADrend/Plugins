/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
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


static enabled;
static height;
static restrictXRotation;
static restrictHeight;
static config;

plugin.init @(override) := fn(){
	config = new (module('LibUtilExt/ConfigGroup'))(systemConfig,'Tools.MovementConstraints');
	
	enabled = Std.DataWrapper.createFromEntry(config,'enabled',false);
	 
	var update = fn(...){	if(enabled()) applyConstraints( PADrend.getDolly() );	};
	
	height = Std.DataWrapper.createFromEntry(config,'height',0.0);
	height.onDataChanged += update;
		
	restrictXRotation = Std.DataWrapper.createFromEntry(config,'restrictXRotation',true);
	restrictXRotation.onDataChanged += update;

	restrictHeight = Std.DataWrapper.createFromEntry(config,'restrictHeight',true);
	restrictHeight.onDataChanged += update;

	module.on('PADrend/gui',fn(gui){
		gui.register('Tools_ToolsMenu.movementContraints',[
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Movement constraints",
				GUI.MENU : 'Tools_MovementContraintsMenu'
			}
		]);

		gui.register('Tools_MovementContraintsMenu.main',[
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
			'----',
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Set as default",
				GUI.ON_CLICK : fn(){	config.save(); PADrend.message("Settings stored.");	}
			}
		]);

	});
	
	static clear = new Std.MultiProcedure;
	enabled.onDataChanged += fn(b){
		clear();
		if(b){
			var dolly = PADrend.getDolly();
			applyConstraints(dolly);
			//! \see MinSG.TransformationObserverTrait
			Std.Traits.assureTrait(dolly,Std.module('LibMinSGExt/Traits/TransformationObserverTrait'));
			
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
	PADrend.planTask( 0.1, fn(){ enabled.forceRefresh();} );
	
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
