/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools] Tools/Avatar.escript
 ** 2010-08 rpetring ...
 **/

declareNamespace($Tools);
Tools.AvatarPlugin := new Plugin({
		Plugin.NAME : 'Tools_Avatar',
		Plugin.DESCRIPTION : "Avatar for Walkthrough",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Ralf Petring",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

var plugin = Tools.AvatarPlugin;

plugin.avatar := void;
plugin.size := void; // DataWrapper
plugin.behaviour := void;
plugin.enabled := false;

/*!	---|> Plugin */
plugin.init @(override) := fn(){
	Util.requirePlugin('Tools_JumpNRun', 1.0);
	 { // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->fn(){
			gui.register('Tools_ToolsMenu.avatar',[
				"*Avatar*",
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Enable",
					GUI.ON_CLICK : this->enable
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Disable",
					GUI.ON_CLICK : this->disable
				},
				'----'
			]);
		});
	}
	return true;
};

plugin.resize := fn(){
//
//	var dist = (PADrend.getDolly().getWorldOrigin() - GLOBALS.camera.getWorldOrigin()).length();
//	dist = dist * (GLOBALS.JumpNRunPlugin.size() / this.size()) - dist;
//	GLOBALS.camera.moveLocal(0, 0, dist);
//
//	this.size() = GLOBALS.JumpNRunPlugin.size();
//
	if(!enabled)
		return $REMOVE;
	// reimplement when MinSG.MESH_AUTO_CENTER_BOTTOM works
	this.avatar.resetRelTransformation();
	this.avatar.scale(1 / this.avatar.getWorldBB().getExtentY());
	this.avatar.scale(this.size());
	this.avatar.moveLocal(0, -this.avatar.getBB().getMaxY()*this.avatar.getRelScaling(), 0);
};

/*!	(public interface) */
plugin.enable:=fn(){

	if(enabled)
		return;
	
	size = Tools.JumpNRunPlugin.size;
//	size.onDataChanged += this->this.resize;
	
	enabled = true;

	if(!this.avatar){
		this.avatar := MinSG.loadModel(getBaseFolder()+"/resources/Avatar.MD2", MinSG.MESH_AUTO_CENTER_BOTTOM|MinSG.MESH_AUTO_SCALE, void);
		if((avatar.getBB().getExtentMax() - 1).abs() < 0.01 && avatar.getBB().getMinY().abs() < 0.01)
			out("MinSG.MESH_AUTO_CENTER_BOTTOM MinSG.MESH_AUTO_SCALE in MD2 are working, reimplement avatar plugin");
		var state = new MinSG.MaterialState();
		state.setAmbient(new Util.Color4f(0.0,0.44,0.6,1));
		state.setDiffuse(new Util.Color4f(0.86,0.48,0.65,1));
		state.setSpecular(new Util.Color4f(1,1,1,1));
		this.avatar.addState(state);
	}
	var camera = PADrend.getActiveCamera();

	camera.resetRelTransformation();
	camera.rotateLocal_deg(-30, 1,0,0);
	camera.moveLocal(0,0,this.size()*2);
	PADrend.getDolly().addChild(this.avatar);
	this.resize();

	if(this.avatar---|> MinSG.KeyFrameAnimationNode){
		this.behaviour = new MinSG.ScriptedNodeBehaviour(this.avatar);
		this.behaviour.lastTime := Util.Timer.now();
		this.behaviour.mode := 'run';
		this.behaviour.lastPos := PADrend.getDolly().getWorldOrigin();
		this.behaviour.doExecute = [this] => fn(plugin){
			var time = this.getCurrentTime();

			var pos = PADrend.getDolly().getWorldOrigin();
			var dist = (pos- this.lastPos).length();
			var duration = time-lastTime;
			if(duration ~= 0) {
				return;
			}
			var speed = dist/duration;
			var lastAnimation = this.getNode().getAnimationPosition();
			var newAnimation;
			if(mode=='run'){
				if( duration < 0.01 || speed > plugin.size() * 0.3){
					newAnimation = lastAnimation + dist / this.getNode().getWorldBB().getExtentX() / 4;
				}
				else{
					mode = 'stand';
					newAnimation = 0;
					this.getNode().setActiveAnimation(mode);
				}
			}
			else if (mode == 'stand'){
				if(speed > plugin.size() * 0.4){
					mode = 'run';
					newAnimation = 0;
					this.getNode().setActiveAnimation(mode);
				}
				else{
					newAnimation = lastAnimation + duration/4;
				}
			}

			this.getNode().setAnimationPosition(newAnimation);

			this.lastTime = time;
			this.lastPos = pos;
			return MinSG.AbstractBehaviour.CONTINUE;
		};
		PADrend.getSceneManager().getBehaviourManager().registerBehaviour(this.behaviour);
	}
	else{
		this.behaviour = new MinSG.ScriptedNodeBehaviour(avatar);
		this.behaviour.doExecute = fn(){

		};
	}

	PADrend.getCameraMover().setAction(Util.UI.EVENT_MOUSE_MOTION, 0, fn(evt){
		var dist = _camera.getRelPosition().length();
		_camera.setRelPosition(new Geometry.Vec3(0,0,0));
		_camera.rotateLocal_rad( evt.deltaY*0.01*(_invertYAxis?1:-1),new Geometry.Vec3(1,0,0));
		_dolly.rotateRel_rad(-evt.deltaX/100,new Geometry.Vec3(0,1,0));
		_camera.moveLocal(new Geometry.Vec3(0,0,dist));
	});

	Tools.JumpNRunPlugin.enable();
};

/*!	(public interface) */
plugin.disable:=fn(){

	if(!enabled)
		return;
	enabled = false;

	PADrend.getDolly().removeChild(this.avatar);
	PADrend.getActiveCamera().resetRelTransformation();
	PADrend.getCameraMover().initActions();
	if(this.behaviour){
		PADrend.getSceneManager().getBehaviourManager().removeBehaviour(this.behaviour);
		this.behaviour = void;
	}
	Tools.JumpNRunPlugin.disable();
};

return plugin;
// ----------------------------------------------------------------------------
