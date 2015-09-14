/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static PathManagement = new Namespace;

static activePath = new Std.DataWrapper; // void || MinSG.PathNode

//! @return Get the currently active path.
PathManagement.getActivePath := fn(){
	return activePath();
};

/**
* Activates the given path or just deactivates the selected if no
* MinSG.PathNode is given.
*
* @param path [MinSG.PathNode] The path to be activated.
*/
PathManagement.activatePath := fn( [void,MinSG.PathNode] path = void){

	// make sure nothing fancy happens when changing the path while
	// camera is following the last path
	animation_active(false);

	activePath( path );
	if(!path)
		return;
	PathManagement.registerPath(path);

	// updates right side of the GUI
	if(path.getWaypoints().count() > 0){
		PathManagement.setInsertIndex(getMaxTime()+1); // append at the end of the waypoint list
	} else {
		PathManagement.setInsertIndex(0);
	}

	//PathManagement.flyTo(0, 0.5); // fly to the first waypoint
	Util.executeExtensions('Waypoints_SelectedWaypointChanged', 0 );
	Util.executeExtensions('Waypoints_PathChanged',activePath());
};

// -----------------------------------------------------
// Registered Paths

static registeredPaths = new Std.DataWrapper([]);

PathManagement.getRegisteredPaths := fn(){
	return registeredPaths().clone();
};

PathManagement.unregisterPath := fn(MinSG.PathNode n){
	var arr = registeredPaths().clone(); // trigger onDataChanged
	arr.removeValue(n);
	registeredPaths(arr);
};

PathManagement.registerPath := fn(MinSG.PathNode n){
	if(!registeredPaths().indexOf(n)){
		var arr = registeredPaths().clone(); // trigger onDataChanged
		arr += n;
		registeredPaths(arr);
	}
};

PathManagement.collectPaths := fn(MinSG.Node subtree = PADrend.getRootNode()){
	return subtree ? MinSG.collectNodes(subtree,MinSG.PathNode) : [];
};
PathManagement.scanForPathNodes := fn( MinSG.Node subtree){
	var arr = registeredPaths().clone();
	arr.filter( fn(p){ return !p.isDestroyed() && !p.hasParent();});
	foreach(MinSG.collectNodes(subtree,MinSG.PathNode) as var p)
		arr += p;
	registeredPaths(arr);
};

//! Create a new path, add it to scene and make it the selected path.
PathManagement.createPath := fn( [MinSG.GroupNode,void] container = void ){
	var path = new MinSG.PathNode;
	PADrend.getSceneManager().registerNode(path);
	path.name := "<created>";
	if(container)
		container += path;
	return path;
};

// -----------------------------
// visualize active path

static showPath = new Std.DataWrapper(false);
PathManagement.showPath := showPath;								// alias
showPath.onDataChanged += fn(Bool b){
	static revoce;
	if(revoce)
		revoce();
	else
		revoce = new Std.MultiProcedure;
	if(b){
		revoce += Util.registerExtensionRevocably('PADrend_AfterRenderingPass',fn(...){
			var path = activePath();
			if( path ){
				renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
				renderingContext.multMatrix_modelToCamera(path.getWorldTransformationMatrix());
				renderingContext.applyChanges();
				path.display(frameContext, MinSG.SHOW_META_OBJECTS);
				renderingContext.popMatrix_modelToCamera();
			}
		});
	}
};

// -----------------------------

static animation_currentTime = new Std.DataWrapper(0);
PathManagement.animation_currentTime := animation_currentTime;		// alias
static animation_speed = new Std.DataWrapper(1.0);
PathManagement.animation_speed := animation_speed;					// alias
static animation_active = new Std.DataWrapper(false);
PathManagement.animation_active := animation_active;				// alias
animation_active.onDataChanged += fn(Bool b){
	static handlerRegistered;
	if(b && !handlerRegistered){
		PADrend.planTask(0.0,fn(){
			if(!animation_active()){
				handlerRegistered = false;
				return;
			}
			if(activePath()){
				static lastClock;
				var now = PADrend.getSyncClock();
				if(!lastClock)
					lastClock = now;
				var deltaTime = (now-lastClock)*animation_speed();
				var timestamp = (animation_currentTime() + deltaTime) % activePath().getMaxTime();
				if( timestamp<0 ) timestamp += activePath().getMaxTime();
				animation_currentTime(timestamp);
				lastClock = now;
			}else{
				animation_currentTime(0);
			}
			return 0; // reschedule
		});
	}

};

static animation_attachedCamera = new Std.DataWrapper;
PathManagement.animation_attachedCamera := animation_attachedCamera;	// alias
PathManagement.animation_attachedCamera.onDataChanged += fn( [MinSG.Node,void] node){
	static revoce;
	if(revoce)
		revoce();
	else
		revoce = new Std.MultiProcedure;
	if(node){
		revoce += Std.addRevocably(PathManagement.animation_currentTime.onDataChanged, [node]=>fn(node,t){
			if(activePath())
				node.setRelTransformation(activePath().getWorldPosition ( t ));
		});
	}

};

// --------------------------------------------
// fly to

/**
* Fly to the waypoint/position at timestamp
*
* @param index [Number] Timestamp of the position to fly to
* @param flight_time [Number] Time in seconds to reach the target location
*/
static polynomPoints = [ new Geometry.Vec2(0,0),new Geometry.Vec2(0.3,0.2),new Geometry.Vec2(0.8,0.9),new Geometry.Vec2(1,1)];
PathManagement.flyTo := fn(Number timestamp,Number duration = 1.0){
	static activeFlightTask;
	PathManagement.animation_active(false);

	var path = activePath();
	if(!path)
		return;

	if(timestamp<0) // deal with minor overflows
		timestamp+=path.getMaxTime();
	else if(timestamp>path.getMaxTime())
		timestamp = 0;

	if(!activeFlightTask){
		activeFlightTask = new ExtObject;
		PADrend.planTask(0,fn(){
			var now = PADrend.getSyncClock();
			if( now>activeFlightTask.endClock ){
				animation_attachedCamera().setRelTransformation( activeFlightTask.endPoint );
				animation_currentTime( activeFlightTask.targetTimestamp);
				activeFlightTask = void;
				return;
			}else{
				var d = (now-activeFlightTask.startTime) / (activeFlightTask.endClock-activeFlightTask.startTime);
				d = Geometry.interpolate2dPolynom(polynomPoints,d).clamp(0,1);
				animation_attachedCamera().setRelTransformation(
							new Geometry.SRT(activeFlightTask.startPoint,activeFlightTask.endPoint,d));
				return 0; // reschedule
			}
		});

	}
	var now = PADrend.getSyncClock();
	activeFlightTask.startTime := now;
	activeFlightTask.startPoint := animation_attachedCamera().getRelTransformationSRT();
	activeFlightTask.endClock := now + duration;
	activeFlightTask.endPoint := path.getWorldPosition(timestamp);
	activeFlightTask.targetTimestamp := timestamp;
	Util.executeExtensions('Waypoints_SelectedWaypointChanged', timestamp );
};




/**
* Move the camera to the next waypoint over <duration> secs.
*/
PathManagement.flyToNextWaypoint := fn(Number duration = 2){
	if(!activePath()){
		PADrend.message("No active path.");
		return;
	}
	var wps = activePath().getWaypoints();
	var idx = 0;
	if( animation_currentTime() < wps[wps.count()-1].getTime()) {
		while(idx < wps.count() && wps[idx].getTime() <= animation_currentTime())
			++idx;
	}
	PathManagement.flyTo(wps[idx].getTime(),duration );
};

/**
* Move the camera to the previous waypoint over <time> secs.
* If no <time> is specified, the standard-time of the plugin is used
* (PathManagement.flight_time).
*/
PathManagement.flyToPrevWaypoint := fn(duration){
	if(!activePath()){
		PADrend.message("No active path.");
		return;
	}

	PathManagement.animation_active(false);

	// find previous Waypoint
	var wps = activePath().getWaypoints();
	var last = wps[0].getTime();
	if( animation_currentTime() <= last) {
		last = wps[wps.count()-1].getTime();
	} else {
		var idx = 1;
		while(idx < wps.count() && wps[idx].getTime() < animation_currentTime() ) {
			last = wps[idx].getTime();
			++idx;
		}
	}
	PathManagement.flyTo(last,duration);
};


// --------------------------------------
// edit

static Command = Std.module('LibUtilExt/Command');
PathManagement.getCommandHistory:=fn(){
	@(once) static cmdHistory = new (Std.module('LibUtilExt/CommandHistory'));
	return cmdHistory;
};

// undoable action to change waypoint
PathManagement.updateWaypoint := fn(wp,[Number,void] timestamp,[String,void] desc,[Geometry.SRT,void] srt = void){

	var cmd = Command.create("Change waypoint at "+wp.getTime(),
		fn(){ // execute
			if(!this.path)
				return;

			var wp = this.path.getWaypoint(this.old_timestamp);
			if(!wp)
				return;

			if(this.timestamp != void){
				if(this.path.getWaypoint(this.timestamp) == void){
					// change waypoint
					wp.setTime(this.timestamp);
				} else {
					// TODO: show yes/no-dialog: overwrite waypoint
					// for now: just do nothing
					this.timestamp = this.old_timestamp;
				}
			}

			if(this.srt != void){
				this.old_srt = wp.getRelTransformationSRT();
				wp.setRelTransformation(this.srt);
				if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
					PathManagement.updateScreenshots([wp]);
				}
			}

			if(this.desc != void){
				this.old_desc = PathManagement.getWaypointDescription(wp);
				PathManagement.setWaypointDescription(wp,this.desc);
			}

			Util.executeExtensions('Waypoints_PathChanged', this.path );
		},
		fn(){ // undo
			if(!this.path)
				return;

			// undo changes
			var wp = this.path.getWaypoint(this.timestamp == void ? this.old_timestamp : this.timestamp);
			if(!wp)
				return;

			if(this.timestamp != void){
				if(this.path.getWaypoint(this.old_timestamp) == void){
					// change waypoint
					wp.setTime(this.old_timestamp);
				} else {
					// TODO: warning: could not undo! or yes/no-dialog (overwrite waypoint)
				}
			}

			if(this.old_srt != void){
				wp.setRelTransformation(this.old_srt);
				if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
					PathManagement.updateScreenshots([wp]);
				}
			}

			if(this.old_desc != void){
				PathManagement.setWaypointDescription(wp,this.old_desc);
			}

			Util.executeExtensions('Waypoints_PathChanged', this.path );
		}
	);
	cmd.old_timestamp := wp.getTime();
	cmd.old_desc := void;
	cmd.old_srt := void;
	cmd.srt := srt;
	cmd.timestamp := timestamp == cmd.old_timestamp ? void : timestamp;
	cmd.desc := desc;
	cmd.path := activePath();

	PathManagement.getCommandHistory().execute(cmd);
};

//! Adds a waypoint to the path so it gets cyclic.
PathManagement.closeLoop := fn(){
	if(activePath()){
		var wps = activePath().getWaypoints();
		if(!wps.empty())
			PathManagement.createWaypoint(wps[0].getRelTransformationSRT(),wps[wps.count()-1].getTime()+1);
	}
};


static insertIndex = 0;
/**
* Add a waypoint at position <srt> and with timestamp <timestamp> to
* the selected path. If no timestamp is specified, the timestamp
* from the Textfield in the GUI is used (which is incremented by 1 every
* time a waypoint is added).
*/
PathManagement.createWaypoint := fn(Geometry.SRT srt, timestamp = void){
	if(!timestamp)
		timestamp = insertIndex;

	var cmd = Command.create("Add waypoint",
		fn(){ // execute
			if(!this.path)
				return;
			// is there a waypoint at <timestamp>?
			// then pathnode changes the timestamp of the newly
			// created to maxTime+1.
			this.old_timestamp := this.timestamp;
			if(this.path.getWaypoint(this.timestamp))
				this.timestamp = this.path.getMaxTime();

			this.path.createWaypoint(this.srt,this.timestamp);
			this.old_insertIndex := PathManagement.getInsertIndex();
			PathManagement.setInsertIndex(this.timestamp+1);

			var wp = this.path.getWaypoint(this.timestamp);

			if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates)
				PathManagement.updateScreenshots([wp]);

			Util.executeExtensions('Waypoints_PathChanged', this.path );
		},
		fn(){ // undo
			if(!this.path)
				return;

			// delete the created waypoint
			MinSG.destroy(this.path.getWaypoint(this.timestamp));
			PathManagement.setInsertIndex(this.old_insertIndex);
			this.timestamp = this.old_timestamp;

			Util.executeExtensions('Waypoints_PathChanged', this.path );
		}
	);
	cmd.srt := srt;
	cmd.timestamp := timestamp;
	cmd.path := activePath();

	PathManagement.getCommandHistory().execute(cmd);
};

//! Add a waypoint to the selected path at the current position (SRT) of the camera.
PathManagement.createWaypointAtCam := fn(timestamp = void){
	PathManagement.createWaypoint(	activePath().getWorldToLocalMatrix() * animation_attachedCamera().getRelTransformationSRT(), timestamp);
};


PathManagement.getInsertIndex := fn(){
	return insertIndex;
};

//! @return The timestamp of the last waypoint
PathManagement.getMaxTime := fn(){
	return activePath() ? activePath().getMaxTime() : 0;
};

//!	Remove last waypoint.
PathManagement.removeLastWaypoint := fn(){
	if(activePath()){
		var wps = activePath().getWaypoints();
		PathManagement.removeWaypoint(wps[wps.count()-1]);
	}
};

PathManagement.removeWaypoint := fn(wp){
	if(wp){
		var cmd = Command.create("Remove waypoint",
			fn(){ // execute
				this.srt := void;
				var wp = this.path.getWaypoint(this.timestamp);
				if(!wp)
					return;

				this.srt := wp.getRelTransformationSRT();
				this.desc := PathManagement.getWaypointDescription(wp);
				MinSG.destroy(wp);

				Util.executeExtensions('Waypoints_PathChanged', this.path );
			},
			fn(){ // undo
				if(!this.srt)
					return;

				this.path.createWaypoint(this.srt, this.timestamp);
				var wp = this.path.getWaypoint(this.timestamp);
				PathManagement.setWaypointDescription(wp,this.desc);

				wp = this.path.getWaypoint(this.timestamp);

				if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
					PathManagement.updateScreenshots([wp]);
				}

				Util.executeExtensions('Waypoints_PathChanged', this.path );
			}
		);
		cmd.path := wp.getPath();
		cmd.timestamp := wp.getTime();
		PathManagement.getCommandHistory().execute(cmd);
	}
};


//! Sets the timestamp where the next waypoint should be added.
PathManagement.setInsertIndex := fn(newIndex){
	insertIndex = newIndex;
};

PathManagement.setTimecodesToIndices := fn() {
	var path = activePath();
	if(path) {
		var wps = path.getWaypoints();
		if(!wps || wps.empty())
			return;

		// set times to a nonexisting area to prevent duplicate times
		foreach(wps as var index, var wp)
			wp.setTime(index * 0.001);

		var t = 0;
		// set new times
		foreach(wps as var wp)
			wp.setTime(t++);

		Util.executeExtensions('Waypoints_PathChanged', path);
	}
};

PathManagement.setTimecodesByDistance := fn(MinSG.PathNode path, Number speed, includeDir=true) {
	//var path = activePath();
	if(path) {
		var wps = path.getWaypoints();
		if(!wps || wps.empty()) {
			return;
		}
		// set times to a nonexisting area to prevent duplicate times
		foreach(wps as var time, var wp)
			wp.setTime(time * 0.001);

		if(speed <= 0.0)
			speed = 1.0;

		var lastTime = 0.0;
		wps[0].setTime(0.0);

		for(var i = 1; i < wps.count(); ++i) {
			// distance from last to this position
			var lastSRT = wps[i-1].getRelTransformationSRT();
			var curSRT = wps[i].getRelTransformationSRT();

			var distance = (curSRT.getTranslation()-lastSRT.getTranslation()).length();
				
			if(includeDir) {
				distance += (1-curSRT.getUpVector().dot(lastSRT.getUpVector()))
					+(1-curSRT.getDirVector().dot(lastSRT.getDirVector()));
			}

			lastTime += distance / speed;
			wps[i].setTime(lastTime);
		}
		Util.executeExtensions('Waypoints_PathChanged', path);
	}
};



/**
* Update screenshot for all waypoints in array <wps>. If no waypoints are given,
* all waypoints are updated.
*/
PathManagement.updateScreenshots := fn(wps = void){
	var path = activePath();
	if(!path)
		return;

	if(!wps)
		wps = path.getWaypoints();

	var oldViewport = camera.getViewport();
	var oldSRT = animation_attachedCamera().getRelTransformationSRT();

	//var tmpFileName = "./waypointsShotTMPFile.bmp";

	//var wps = path.getWaypoints();
	camera.setViewport(new Geometry.Rect(0,0,120,90));
	foreach(wps as var wp){
		animation_attachedCamera().setRelTransformation(path.getWorldPosition ( wp.getTime() ));

		// -------------------
		// ---- Render Scene
		frameContext.beginFrame();
		frameContext.setCamera(camera);
		renderingContext.clearScreen(PADrend.getBGColor());
		PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());

		var tex = Rendering.createTextureFromScreen();

		// make icon from texture
		var bitmap = Rendering.createBitmapFromTexture(renderingContext,tex);
		var img = gui.createImage(bitmap);
		var icon = gui.createIcon(img, new Geometry.Rect(0,0,120,90));

		wp.shotIcon := icon;

		PADrend.SystemUI.swapBuffers();
	}
	animation_attachedCamera().setRelTransformation(oldSRT);
	camera.setViewport(oldViewport);

	Util.executeExtensions('Waypoints_PathChanged', activePath() );

	path.enableShotUpdates := true;
};


// ---------------------------------------------------------------------------------------------------

/****
**	[Plugin:Waypoints/Persistence] Waypoints/Persistence.escript
**
** Saving and loading data for the Waypoints-Plugin.
**/

/**
* Save the path <path> to file <filename>. If no path is specified,
* the selected path is saved.
*
* @param filename [String] The file to store the path in.
* @param path [MinSG.PathNode] The path to store (if not the selected)
*/
PathManagement.savePath := fn(filename,path = void){
	outln("Save Path to \"",filename,"\"...");
	path = path ? path : activePath();
	if (!path) {
		outln("\aNo path found!");
		return;
	}
	outln( MinSG.SceneManagement.saveMinSGFile( PADrend.getSceneManager(),filename,[path]) ? "ok" : "failed");
};

/**
* Load a path from <filename>, add it to the scene and activate it.
*
* @param filename [String] The file to load from
*
* @return The loaded path
*/
PathManagement.loadPath := fn(filename){
	var nodeArray = MinSG.SceneManagement.loadMinSGFile( PADrend.getSceneManager(), filename);

	if (! nodeArray )
		Runtime.exception("PathManagement.loadPath: Could not load file '"+filename+"'");

	var path = nodeArray[0];
	if(path){
		path.name := filename;
		var id = PADrend.getSceneManager().getNameOfRegisteredNode(path);
		if(!id)
			PADrend.getSceneManager().registerNode(path);
	}
	PathManagement.activatePath(path);
	return path;
};
//---------------------------------------
PathManagement.getWaypointDescription := fn(wp, String default=""){
	var desc = wp.getNodeAttribute('desc');
	return desc ? desc : default;
};

PathManagement.setWaypointDescription := fn(wp,String desc){
	if(desc=="")
		wp.unsetNodeAttribute('desc');
	else
		wp.setNodeAttribute('desc',desc);
};
//---------------------------------------


return PathManagement;
