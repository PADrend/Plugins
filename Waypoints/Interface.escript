/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
**	[Plugin:Waypoints/Interface] Waypoints/Interface.escript
**
** The <public> parts of the Waypoints-Plugin.
**/


WaypointsPlugin.followPathBehavior := void;

/**
* Attaches or detaches the camera to the current
* path. The camera flies along the path using a MinSG.FollowPathBehaviour.
*
* @param attach [bool] If true, the camera is attached, otherwise it's detached.
*
* @see WaypointsPlugin.isCameraAttached
*/
WaypointsPlugin.attachCamera := fn(attach = true){
	// remove old behavior
	if(this.followPathBehavior){
		this.behaviourManager.removeBehaviour(this.followPathBehavior);
		this.followPathBehavior = void;
		this.cameraAttached = false;
	}
	if(attach){
		if(!this.curPath) // makes no sense without a path
			return;

		if(this.cameraAttached)
			return;

		// attach
		this.followPathBehavior = new MinSG.FollowPathBehaviour(this.curPath,PADrend.getDolly());
		this.followPathBehavior.setSpeed(this.cameraPause ? 0 : this.cameraSpeed);
		this.followPathBehavior.setPosition(this.flight_targetIndex,0);
		
		this.behaviourManager.registerBehaviour( this.followPathBehavior );
	} 
	this.cameraAttached = attach; // store current state

//	this.onAttachedChanged_exec();
	executeExtensions('Waypoints_PathAttachmentChanged', 'cam' );
};



/**
* Add path to the given container or the rootNode .
*
* @param path [MinSG.PathNode] The path to add
* @param activate [bool] If true, the path will be activated.
*
* @returns The path if successfully added, false otherwise.
*/
WaypointsPlugin.addPath := fn(path,[MinSG.GroupNode,void] container = void){
	if(!path || (!path ---|> MinSG.PathNode))
		return false;

	if(!container)
		container = PADrend.getRootNode();
	// add path to scene
	container.addChild(path);

	// tell all listeners that the path list has changed
	this.paths = void;
	executeExtensions('Waypoints_PathListChanged');

	return path;
};

/**
* Activates the given path or just deactivates the selected if no
* MinSG.PathNode is given.
*
* @param path [MinSG.PathNode] The path to be activated.
*/
WaypointsPlugin.activatePath := fn(path = void){
	if(path && !(path ---|> MinSG.PathNode)) // make sure only MinSG.PathNodes get activated
		path = void;

	if(this.curPath) {
		// make sure nothing fancy happens when changing the path while
		// camera is following the last path
		attachCamera(false);
		setCameraPause(true);
	}
	this.curPath := path;

	// updates right side of the GUI
	if(this.curPath && this.curPath.getWaypoints().count() > 0){
		this.setInsertIndex(getMaxTime()+1); // append at the end of the waypoint list
	} else {
		this.setInsertIndex(0);
	}

	//this.flyTo(0, 0.5); // fly to the first waypoint
	this.flight_targetIndex = 0;
	executeExtensions('Waypoints_SelectedWaypointChanged', this.flight_targetIndex );
	executeExtensions('Waypoints_PathChanged',this.curPath);
};

//! Attach path to a different container in the sceneGraph.
WaypointsPlugin.attachPath := fn(path, container){
	out("Attaching path ",path.toString()," to ",container,"...");
	if(container---|>MinSG.GroupNode){
		container.addChild(path);
		executeExtensions('Waypoints_PathListChanged');
		out("ok.\n");
	}else{
		out("failed.\n");
	}
};

// undoable action to change waypoint
WaypointsPlugin.changeWaypoint := fn(wp,timestamp,desc,srt = void){
	if(wp == void) {
		out("ERROR: no waypoint for changeWaypoint");
		return;
	}

	if(timestamp == void && desc == void && srt == void)
		return;

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
				this.old_srt = wp.getSRT();
				wp.setSRT(this.srt);
				if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
					WaypointsPlugin.updateScreenshots([wp]);
				}
			}

			if(this.desc != void){
				this.old_desc = WaypointsPlugin.getWaypointDescription(wp);
				WaypointsPlugin.setWaypointDescription(wp,this.desc);
			}

			executeExtensions('Waypoints_PathChanged', this.path );
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
				wp.setSRT(this.old_srt);
				if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
					WaypointsPlugin.updateScreenshots([wp]);
				}
			}

			if(this.old_desc != void){
				WaypointsPlugin.setWaypointDescription(wp,this.old_desc);
			}

			executeExtensions('Waypoints_PathChanged', this.path );
		}
	);
	cmd.old_timestamp := wp.getTime();
	cmd.old_desc := void;
	cmd.old_srt := void;
	cmd.srt := srt;
	cmd.timestamp := timestamp == cmd.old_timestamp ? void : timestamp;
	cmd.desc := desc;
	cmd.path := WaypointsPlugin.getCurrentPath();

	WaypointsPlugin.getCommandHistory().execute(cmd);
};

//! Adds a waypoint to the path so it gets cyclic.
WaypointsPlugin.closeLoop := fn(){
	if(!WaypointsPlugin.curPath)
		return;

	var wps = WaypointsPlugin.curPath.getWaypoints();
	if(wps.empty())
		return;

	WaypointsPlugin.createWaypoint(wps[0].getSRT(),wps[wps.count()-1].getTime()+1);
};

WaypointsPlugin.collectPaths := fn(subtree = PADrend.getRootNode()){
	return subtree ? MinSG.collectNodes(subtree,MinSG.PathNode) : [];
};

//! Create a new path, add it to scene and make it the selected path.
WaypointsPlugin.createPath := fn( [MinSG.GroupNode,void] container = void ){
	var path = new MinSG.PathNode();
	PADrend.getSceneManager().registerNode(path);
	path.name := "<created>";
	WaypointsPlugin.addPath(path,container);
	return path;
};

/**
* Add a waypoint at position <srt> and with timestamp <timestamp> to
* the selected path. If no timestamp is specified, the timestamp
* from the Textfield in the GUI is used (which is incremented by 1 every
* time a waypoint is added).
*/
WaypointsPlugin.createWaypoint := fn(Geometry.SRT srt, timestamp = void){
	if(!timestamp) {
		timestamp = this.insertIndex;
	}

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
			this.old_insertIndex := WaypointsPlugin.getInsertIndex();
			WaypointsPlugin.setInsertIndex(this.timestamp+1);

			var wp = this.path.getWaypoint(this.timestamp);

			if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
				WaypointsPlugin.updateScreenshots([wp]);
			}

			executeExtensions('Waypoints_PathChanged', this.path );
		},
		fn(){ // undo
			if(!this.path)
				return;

			// delete the created waypoint
			MinSG.destroy(this.path.getWaypoint(this.timestamp));
			WaypointsPlugin.setInsertIndex(this.old_insertIndex);
			this.timestamp = this.old_timestamp;

			executeExtensions('Waypoints_PathChanged', this.path );
		}
	);
	cmd.srt := srt;
	cmd.timestamp := timestamp;
	cmd.path := WaypointsPlugin.getCurrentPath();

	WaypointsPlugin.getCommandHistory().execute(cmd);
};

//! Add a waypoint to the selected path at the current position (SRT) of the camera.
WaypointsPlugin.createWaypointAtCam := fn(timestamp = void){
	WaypointsPlugin.createWaypoint(	WaypointsPlugin.getCurrentPath().getWorldMatrix().inverse() * PADrend.getDolly().getSRT(), timestamp);

};

/**
* Fly to the waypoint/position at timestamp 
*
* WARNING: The <path>-argument should be used with care - the GUI does not
* recognize, which path's waypoint was the target. So better activate the
* path before use of flyTo.
*
* @param index [Number] Timestamp of the position to fly to
* @param flight_time [Number] Time in seconds to reach the target location
* @param path [MinSG.PathNode] The path to use, if none is given, the selected path is used
*/
WaypointsPlugin.flyTo := fn(timestamp,flight_time = 1.0,path = void){
	WaypointsPlugin.setCameraPause(true);

	if(!path){
		if(!this.curPath)
			return;
		else
			path = this.curPath;
	}

	if(timestamp<0) // deal with minor overflows
		timestamp+=path.getMaxTime();
	else if(timestamp>path.getMaxTime())
			timestamp = 0;

	var now = PADrend.getSyncClock();
	this.flight_startTime = now;
	this.flight_startPoint = PADrend.getDolly().getSRT();
	this.flight_endTime = now+flight_time;
	this.flight_endPoint = path.getWorldPosition(timestamp);

	this.flight_targetIndex = timestamp;
	executeExtensions('Waypoints_SelectedWaypointChanged', this.flight_targetIndex );
};

/**
* Move the camera to the next waypoint over <time> secs.
* If no <time> is specified, the standard-time of the plugin is used
* (WaypointsPlugin.flight_time).
*/
WaypointsPlugin.flyToNextWaypoint := fn(time = void){
	if(!WaypointsPlugin.getCurrentPath()){
		PADrend.message("No active path.");
		return;
	}
	
	//if(WaypointsPlugin.isCameraAttached() && !WaypointsPlugin.isCameraPaused()){
		WaypointsPlugin.setCameraPause(true);
	//}

	var wps = WaypointsPlugin.getCurrentPath().getWaypoints();
	var idx = 0;
	if(flight_targetIndex < wps[wps.count()-1].getTime()) {
		while(idx < wps.count() && wps[idx].getTime() <= WaypointsPlugin.flight_targetIndex) {
			++idx;
		}
	}
	WaypointsPlugin.flyTo(wps[idx].getTime(),time ? time : WaypointsPlugin.flight_time);
};

/**
* Move the camera to the previous waypoint over <time> secs.
* If no <time> is specified, the standard-time of the plugin is used
* (WaypointsPlugin.flight_time).
*/
WaypointsPlugin.flyToPrevWaypoint := fn(time = void){
	if(!WaypointsPlugin.getCurrentPath()){
		PADrend.message("No active path.");
		return;
	}
	
	//if(WaypointsPlugin.isCameraAttached() && !WaypointsPlugin.isCameraPaused()){
		WaypointsPlugin.setCameraPause(true);
	//}

	// find previous Waypoint
	var wps = WaypointsPlugin.getCurrentPath().getWaypoints();
	var last = wps[0].getTime();
	if(WaypointsPlugin.flight_targetIndex <= last) {
		last = wps[wps.count()-1].getTime();
	} else {
		var idx = 1;
		while(idx < wps.count() && wps[idx].getTime() < WaypointsPlugin.flight_targetIndex) {
			last = wps[idx].getTime();
			++idx;
		}
	}
	WaypointsPlugin.flyTo(last,time ? time : WaypointsPlugin.flight_time);
};

WaypointsPlugin.getCameraSpeed := fn(){
	return this.cameraSpeed;
};

//! @return Get the currently active path.
WaypointsPlugin.getCurrentPath := fn(){
	return WaypointsPlugin.curPath;
};


WaypointsPlugin.getInsertIndex := fn(){
	return this.insertIndex;
};

//! @return The timestamp of the last waypoint
WaypointsPlugin.getMaxTime := fn(){
	return WaypointsPlugin.curPath ? WaypointsPlugin.curPath.getMaxTime() : 0;
};

/**
* Gets a list of all path-nodes this plugin knows of.
* The result is buffered until the WP_PATH_LIST_CHANGED-event
* is triggered.
*
* @return [Array of MinSG.PathNode] All paths
*/
WaypointsPlugin.getPaths := fn(){
	if(this.paths)
		return this.paths;
	return this.collectPaths();
};



//! @return [bool] true if the camera is currently attached to the path, false otherwise
WaypointsPlugin.isCameraAttached := fn(){
	return WaypointsPlugin.cameraAttached;
};

//! @return [int] The index of the waypoint which was activated (by flying to it) last.
WaypointsPlugin.getSelectedWaypoint := fn(){
	return WaypointsPlugin.flight_targetIndex;
};

WaypointsPlugin.isCameraPause := fn(){
	return this.cameraPause;
};

WaypointsPlugin.isShowPath := fn(){
	return this.showPath;
};


//!	Remove last waypoint.
WaypointsPlugin.removeLastWaypoint := fn(){
	if(!WaypointsPlugin.curPath)
		return;

	var wps = WaypointsPlugin.curPath.getWaypoints();
	WaypointsPlugin.removeWaypoint(wps[wps.count()-1]);
};

WaypointsPlugin.removeWaypoint := fn(wp){
	if(wp){
		var cmd = Command.create("Remove waypoint",
			fn(){ // execute
				this.srt := void;
				var wp = this.path.getWaypoint(this.timestamp);
				if(!wp)
					return;

				this.srt := wp.getSRT();
				this.desc := WaypointsPlugin.getWaypointDescription(wp);
				MinSG.destroy(wp);

				executeExtensions('Waypoints_PathChanged', this.path );
			},
			fn(){ // undo
				if(this.srt==void)
					return;

				this.path.createWaypoint(this.srt, this.timestamp);
				var wp = this.path.getWaypoint(this.timestamp);
				WaypointsPlugin.setWaypointDescription(wp,this.desc);

				wp = this.path.getWaypoint(this.timestamp);

				if(this.path.isSet($enableShotUpdates) && this.path.enableShotUpdates){
					WaypointsPlugin.updateScreenshots([wp]);
				}

				executeExtensions('Waypoints_PathChanged', this.path );
			}
		);
		cmd.path := wp.getPath();
		cmd.timestamp := wp.getTime();
		WaypointsPlugin.getCommandHistory().execute(cmd);
	}
};

WaypointsPlugin.setCameraPause := fn(pause){
	if(this.cameraPause==pause)
		return;

	this.cameraPause = pause;
	if(this.cameraAttached){
		if(!pause){
			this.followPathBehavior.setPosition(this.flight_targetIndex,0);
		}
		this.followPathBehavior.setSpeed(this.cameraPause ? 0 : this.cameraSpeed);
		this.flight_targetIndex := this.getCameraTimestamp();
		executeExtensions('Waypoints_SelectedWaypointChanged', this.flight_targetIndex );
	}
	executeExtensions('Waypoints_PathAttachmentChanged', 'cam' );
};

WaypointsPlugin.setCameraSpeed := fn(speed){
	this.cameraSpeed = speed;
	if(this.cameraAttached){
		this.followPathBehavior.setSpeed(this.cameraPause ? 0 : this.cameraSpeed);
	}
	executeExtensions('Waypoints_PathAttachmentChanged', 'cam' );
};

//! Sets the timestamp where the next waypoint should be added.
WaypointsPlugin.setInsertIndex := fn(newIndex){
	this.insertIndex = newIndex;
};


WaypointsPlugin.setShowPath := fn(showPath){
	this.showPath = showPath ? true : false;
};

WaypointsPlugin.setTimecodesToIndices := fn() {
	var path = WaypointsPlugin.getCurrentPath();
	if(!path) {
		return;
	}
	var wps = path.getWaypoints();
	if(!wps || wps.empty()) {
		return;
	}
	// set times to a nonexisting area to prevent duplicate times
	foreach(wps as var time, var wp) {
		wp.setTime(time * 0.001);
	}
	var t = 0;
	// set new times
	foreach(wps as var wp) {
		wp.setTime(t++);
	}
	executeExtensions('Waypoints_PathChanged', path);
};

WaypointsPlugin.setTimecodesByDistance := fn(MinSG.PathNode path, Number speed) {
	var path = WaypointsPlugin.getCurrentPath();
	if(!path) {
		return;
	}
	var wps = path.getWaypoints();
	if(!wps || wps.empty()) {
		return;
	}
	// set times to a nonexisting area to prevent duplicate times
	foreach(wps as var time, var wp) {
		wp.setTime(time * 0.001);
	}

	if(speed <= 0.0) {
		speed = 1.0;
	}

	var lastTime = 0.0;
	wps[0].setTime(0.0);

	// TODO: what happens when a waypoint would get "overwritten"
	// example: <0>, <1>, <2>, <3> were the original timecodes
	// physical distance between <0> and <1> is 2. so now timecode of <1>
	// would be set to <2>. and we got (temporarily) 2 waypoints with the same
	// timecode.
	for(var i = 1; i < wps.count(); ++i) {
		// distance from last to this position
		var lastSRT = wps[i-1].getSRT();
		var curSRT = wps[i].getSRT();

		var distance = curSRT.getUpVector().dot(lastSRT.getUpVector())//.length()
			+curSRT.getDirVector().dot(lastSRT.getDirVector())//.length()
			+(curSRT.getTranslation()-lastSRT.getTranslation()).length();

		lastTime += distance / speed;
		wps[i].setTime(lastTime);
	}
	executeExtensions('Waypoints_PathChanged', path);
};



/**
* Update screenshot for all waypoints in array <wps>. If no waypoints are given,
* all waypoints are updated.
*/
WaypointsPlugin.updateScreenshots := fn(wps = void){
	var path = this.curPath;
	if(!path)
		return;

	if(!wps) {
		wps = path.getWaypoints();
	}

	var oldViewport = camera.getViewport();
	var oldSRT = PADrend.getDolly().getSRT();

	//var tmpFileName = "./waypointsShotTMPFile.bmp";

	//var wps = path.getWaypoints();
	camera.setViewport(new Geometry.Rect(0,0,120,90));
	foreach(wps as var wp){
		PADrend.getDolly().setSRT(path.getWorldPosition ( wp.getTime() ));

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
	PADrend.getDolly().setSRT(oldSRT);
	camera.setViewport(oldViewport);

	executeExtensions('Waypoints_PathChanged', WaypointsPlugin.getCurrentPath() );

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
WaypointsPlugin.savePath := fn(filename,path = void){
	out("Save Path to \"",filename,"\"...");
	path = path ? path : this.curPath;
	if (!path) {
		out("\aNo path found!\n");
		return;
	}
	out( PADrend.getSceneManager().saveMinSGFile(filename,[path]) ? "ok\n" : "failed\n");
};

/**
* Load a path from <filename>, add it to the scene and activate it.
*
* @param filename [String] The file to load from
*
* @return The loaded path
*/
WaypointsPlugin.loadPath := fn(filename){
	try{
		var nodeArray = PADrend.getSceneManager().loadMinSGFile(filename);

		if (! nodeArray ) {
			return false;
		}
		var path = nodeArray[0];
		if(path){
			path.name := filename;
			var id = PADrend.getSceneManager().getNameOfRegisteredNode(path);
			if(!id)
				PADrend.getSceneManager().registerNode(path);
		}

		WaypointsPlugin.addPath(path);
		WaypointsPlugin.activatePath(path);
		return path;
	}catch(e){
		Runtime.warn(e);
		return false;
	}
	return false;
};

