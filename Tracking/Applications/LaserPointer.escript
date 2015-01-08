/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010 Robert Gmyr
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static deviceRequirements = [Std.require('LibUtilExt/HID_Traits').Controller_Room6D_Trait];
static enabled = Std.DataWrapper.createFromEntry( systemConfig,'Tracking.Laser.intitiallyEnabled',false );
static deviceNames = Std.DataWrapper.createFromEntry(systemConfig,'Tracking.Laser.deviceNames', ["Flystick"]);

// ------------

static LaserState = new Type(MinSG.ScriptedState);
LaserState._printableName @(override) ::= "LaserPointer";
LaserState.name ::= "LaserPointer";

LaserState.roomSource := void;
LaserState.roomTarget := void;
LaserState.roomUpVector := void;

LaserState._constructor @(override) ::= fn(){
	this.setTempState( true );
	this.roomSource = new Geometry.Vec3(0,0,0);
	this.roomTarget = new Geometry.Vec3(0,10,0);
	this.roomUpVector = new Geometry.Vec3;
};
LaserState.doEnableState @(override) ::= fn(d*) {};

static BEAM_LENGTH = 4;
static POINT_SIZE = 20;


static COLOR_FULL = new Util.Color4f(0,1,0,0.2);
static COLOR_WEAK = new Util.Color4f(0,1,0,0.01);
static COLOR_POINT = new Util.Color4f(0,2,0,0.05);


LaserState.doDisableState @(override) ::= fn(d*) {
	if(this.roomSource&&this.roomTarget){

		static pointerNode;
		static beamNode;
		static TrackingTools;
		@(once){
			TrackingTools = module('../TrackingTools');
			{

				var mb = new Rendering.MeshBuilder;
				mb.color(COLOR_FULL);
				mb.position( [0,0,0] );
				mb.addVertex();
				mb.color(COLOR_WEAK);
				mb.position( [0,1,0] );
				mb.addVertex();
				mb.addVertex();
				var mesh = mb.buildMesh();
				mesh.setDrawLineStrip();
				mesh.setUseIndexData(false);
				beamNode = new MinSG.GeometryNode( mesh );
			}
			{
				var mb = new Rendering.MeshBuilder;
				mb.color(COLOR_POINT);
				mb.position([0,0,0]);
				mb.addVertex();
				var mesh = mb.buildMesh();
				mesh.setDrawPoints();
				mesh.setUseIndexData(false);
				pointerNode = new MinSG.GeometryNode( mesh );

			}
		}

		var p1 = TrackingTools.roomPosToWorldPos( this.roomSource );
		var p2 = TrackingTools.roomPosToWorldPos( this.roomTarget );
		var p3 = p1 + TrackingTools.roomDirToWorldDir(this.roomUpVector)*0.1;

		// -----------
		{	// update beamMesh
			var mesh = beamNode.getMesh();
			var pos = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
			var color = Rendering.ColorAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.COLOR);
			pos.setPosition(0,p1);
			pos.setPosition(2,p2);
			if(p1.distance(p2)>BEAM_LENGTH){
				pos.setPosition(1,p1+ (p2-p1).normalize()*BEAM_LENGTH );
				color.setColor(1, COLOR_WEAK);

			}else{
				pos.setPosition(1, p2);
				color.setColor(1,  new Util.Color4f(COLOR_FULL,COLOR_WEAK,p1.distance(p2)/BEAM_LENGTH) );
			}
			mesh._markAsChanged();
		}

//		pointerNode.setRelOrigin( p2 );
		pointerNode.setRelOrigin( p1+(p2-p1)*0.99 );


//		color.setColor(0, new Util.Color4f(0, 1, 0, 1));
//		color.setColor(1, new Util.Color4f(0, 1, 0, (1.0-p1.distance(p2)*0.1).clamp(0.2,1.0)  ));


		renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
		renderingContext.pushLine();
		renderingContext.pushPointParameters();


		renderingContext.pushAndSetLighting(false);
		renderingContext.setLineWidth(6.0);

		var blending=new Rendering.BlendingParameters;
		blending.enable();
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
		renderingContext.pushAndSetBlending(blending);
			renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);

				// draw beams
				renderingContext.setLineWidth(1.0);

				Rendering.drawVector( renderingContext, p1,p3, new Util.Color4f(0.0,0.0,1.0,0.07));	// up vector
//				beamNode.display(frameContext);

				renderingContext.setPointParameters( new Rendering.PointParameters(POINT_SIZE*0.5) );
				pointerNode.display(frameContext);
				renderingContext.setPointParameters( new Rendering.PointParameters(POINT_SIZE*0.25) );
				pointerNode.display(frameContext);


			renderingContext.popDepthBuffer();
			renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LESS);

				renderingContext.applyChanges();

				// draw beams
				for(var i=1;i<=4.0;++i){
					renderingContext.setLineWidth(i);
//					renderingContext.setLineWidth(4.0);
					Rendering.drawVector( renderingContext, p1,p3, new Util.Color4f(0.0,0.0,1.0,0.07));// up vector
//					beamNode.display(frameContext);
				}

				for(var i=1;i<=POINT_SIZE;++i){
					renderingContext.setPointParameters( new Rendering.PointParameters(i) );
					pointerNode.display(frameContext);

				}
			renderingContext.popDepthBuffer();

		renderingContext.popBlending();


		renderingContext.popPointParameters();
		renderingContext.popLine();
		renderingContext.popLighting();
		renderingContext.popMatrix_modelToCamera();

	}
};

// -----------------

static laserRenderer;

static rpc = Util.requirePlugin('PADrend/RemoteControl');
rpc.registerFunction('Tracking.LaserApp.set',fn(Array roomSource,Array roomTarget,Array roomUpVector){
	if(!laserRenderer){
		laserRenderer = new LaserState;
		PADrend.getRootNode() += laserRenderer;
	}
	laserRenderer.roomSource = new Geometry.Vec3(roomSource);
	laserRenderer.roomTarget = new Geometry.Vec3(roomTarget);
	laserRenderer.roomUpVector = new Geometry.Vec3(roomUpVector);
});

rpc.registerFunction('Tracking.LaserApp.disable',fn(){
	if(laserRenderer){
		PADrend.getRootNode().removeState(laserRenderer);
		laserRenderer = void;
	}
});

rpc.registerFunction('Tracking.LaserApp.setMode',fn(mode){

	enabled (mode =="true" ? true : false);

});

static positionHandler = fn(roomSRTOrVoid){
	if(roomSRTOrVoid---|>Geometry.SRT){
		@(once) static TrackingTools = module('../TrackingTools');

		var worldSRT = TrackingTools.roomSRTToWorldSRT(roomSRTOrVoid);
		var worldSource = worldSRT.getTranslation();
		var worldTarget = TrackingTools.querySceneIntersection( new Geometry.Segment3( worldSource, worldSource+worldSRT.getDirVector()*10000 ));

		rpc.broadcast('Tracking.LaserApp.set',
						TrackingTools.worldPosToRoomPos(worldSource).toArray(),
						TrackingTools.worldPosToRoomPos(worldTarget).toArray(),
						TrackingTools.worldDirToRoomDir(worldSRT.getUpVector()).toArray());
	}else{
		rpc.broadcast('Tracking.LaserApp.disable' );
	}

};

static myDeviceHandler = new (module('../DeviceHandler'))(enabled, deviceNames);
myDeviceHandler.onDeviceEnabled += fn(device){
//	outln("Laser enabled.");
	device.onRoomTransformationChanged += positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */
};
myDeviceHandler.onDeviceDisabled += fn(device){
	positionHandler(void);
	device.onRoomTransformationChanged -= positionHandler; /*! \see HID_Traits.Controller_Room6D_Trait */
};
myDeviceHandler.refresh();

gui.registerComponentProvider('Tracking_applications.flystickLaserPointer',fn(){
	return [{
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.COLLAPSED : true,
		GUI.HEADER : [{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL :"LaserPointer",
			GUI.DATA_WRAPPER : enabled
		}],
		GUI.CONTENTS : fn(){
			var options = [];
			foreach( PADrend.HID.queryPossibleDeviceNames(deviceRequirements...) as var deviceName)
				options += [deviceName,deviceName];
			return [{
				GUI.TYPE : GUI.TYPE_LIST,
				GUI.LABEL : "Device",
				GUI.DATA_WRAPPER : deviceNames,
				GUI.OPTIONS : options,
				GUI.HEIGHT : options.count() * 15+3,
				GUI.TOOLTIP : "Used devices. Hold [ctrl] to select multiple devices."
			}];
		}
	}];
});

return true;
