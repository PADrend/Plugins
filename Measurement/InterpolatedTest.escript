/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Paul Justus
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Measurement] Measurement/InterpolatedTest.escript
 **
 **  2010-03-14 - Paul Justus - created!
 **  2010-03-22 - Paul Justus - implemented testing of all registered scene-nodes. @see InterpolatedTest.execute()
 **  2010-03-23 - Paul Justus - recording of data has been changed : recording is using DataTable now.
 **                           - sampling progress output added (TestProgressOutput).
 **  2010-03-25 - Paul Justus - four attributes: frameduration, #rendered meshes, #rendered polygons and
 **                             #box tests are done in a single (second) run now
 **  2010-04-10 - Paul Justus - samling using BoxQualityEvaluator added (this measures: #objects classified
 **                             as visible, #visible objects, #triangles in classified as visible objects and
 **                             #triangles in visible objects)
 **  2010-04-14 - Paul Justus - static function for evaluating average size of GeometryNodes/VBOs added
 **
 **/

/**
 * [static] calculates average size of GeometryNodes/VBO (same as average count of triangles) in current scene
 * \return average number of triangles
 */
MeasurementPlugin.calculateAvgVBOSize := fn(scene=PADrend.getCurrentScene()) {
	if (scene == void)
		return 0;

	var totalTriangleCount = 0;

	// get all geometry nodes and calculate total number of triangles
	var geonodes = MinSG.collectGeoNodes(scene);
	foreach (geonodes as var geometrynode ) {
		totalTriangleCount += geometrynode.getTriangleCount();
	}

	return totalTriangleCount/geonodes.count();
};



/**
 * [static] calculates for a given path the average distance between two neighbouring waypoints
 * \param path
 * \return average distance
 */
MeasurementPlugin.calculateAvgDistance := fn(path) {
	if (!(path ---|> MinSG.PathNode)) {
		out("MeasurementPlugin: no path! select any path first!\n");
		return " 0.0";
	}
	var waypoints = path.getWaypoints();
	var sum = 0.0;
	for (var i=0; i<waypoints.count(); i++) {
		if (i+1 < waypoints.count()) {
			var difference = (waypoints[i+1].getRelTransformationSRT().getTranslation()) - (waypoints[i].getRelTransformationSRT().getTranslation());
			sum += difference.length();
		}
	}
	return " "+sum/waypoints.count();
};


MeasurementPlugin.InterpolatedTest := new Type();

/**
 * [ctor] create a new InterpolatedTest-object
 */
MeasurementPlugin.InterpolatedTest._constructor := fn(data) {
	if (data==void)
		data = new Map();

	this.frameContext := data['frameContext']?data['frameContext']:GLOBALS.frameContext;
	this.renderFlags := data['renderFlags']?data['renderFlags']:PADrend.getRenderingFlags();
	this.statistics := data['statistics']?data['statistics']:PADrend.frameStatistics;
	this.camera := data['camera,']?data['camera,']:GLOBALS.camera;
	this.path := data['path']?data['path']:WaypointsPlugin.getActivePath();

	// list of srts (extracted from waypoints of selected path)
	this.srts := [];

	// create BoxQualityEvaluator
	this.evaluator := new MinSG.BoxQualityEvaluator();

	// initialize a list of colors (there are only 12 colors set)
	this.colors := [];
	colors += "#004586";
	colors += "#dc2000";
	colors += "#ffd320";
	colors += "#578b1c";
	colors += "#6a001e";
	colors += "#83caff";
	colors += "#354a04";
	colors += "#b1cf00";
	colors += "#5a2585";
	colors += "#ff8b0e";
	colors += "#888888";
	colors += "#000000";
};

/**
 * calculates a list of SRTs according to selected stepdist between the neighbouring waypoints.
 * (if the distance between two neighbouring waypoints, is larger than stepdist, additional (interpolated)
 * SRTs are calculated to fill the gap)
 * \param stepdist : maximum distance between two  neighbouring waypoints/SRTs
 * \return true if interpolating was successful, otherwise false.
 */
MeasurementPlugin.InterpolatedTest.interpolateSRTs:=fn(stepdist) {
	if (! (path ---|> MinSG.PathNode) ) {
		out("MeasurementPlugin: no path! select any path first!\n");
		return false;
	}

	var waypoints = path.getWaypoints();
	if (waypoints.count() < 2) {
		out("MeasurementPlugin: invalid path: it should have at least two waypoints!\n");
		return false;
	}

	//add srt of the first waypoint into the list
	srts += waypoints[0].getRelTransformationSRT();

	//begin interpolating
	for (var i=1; i<waypoints.count(); i++) {
		//if stepdist is greater than zero do interpolating
		if (stepdist > 0.0) {
			//calculate distance between the current and the previous waypoints
			var diff_vec = waypoints[i].getRelTransformationSRT().getTranslation() - waypoints[i-1].getRelTransformationSRT().getTranslation();
			var length = diff_vec.length();
			var free = length;

			//insert additional srts if they fit onto the connection between neighbouring waypoints
			while (stepdist < free) {
				var ratio = (length-free)/length;
				var srt_new = new Geometry.SRT(waypoints[i-1].getRelTransformationSRT(), waypoints[i].getRelTransformationSRT(), ratio);
				srts += srt_new;
				free -= stepdist;
			}
		}
		srts += waypoints[i].getRelTransformationSRT();
	}
	return true;
};

/**
 * executes a test for selected scene (PADrend.getCurrentScene()) along selected path using MinSG.BoxQualityEvaluator.
 * \param scenename : text identifying current scene
 * \param data : map which data from evaluator will be exported to
 * \return true if test was successful, otherwise false.
 */
MeasurementPlugin.InterpolatedTest.executeBoxQualityEvaluator := fn(String scenename, Map boxes, Map objects, Map trianglesBoxes, Map trianglesObjects) {
	if (srts.count() <= 0) {
		out("MeasurementPlugin: current path has no waypoints!\n");
		return false;
	}

	var scene = PADrend.getCurrentScene();
	var measurementCamera = GLOBALS.camera.clone();

	// create an object that should output the progress status
	var progressOutput = new Util.ProgressIndicator("Recording " + scenename, srts.count(), 8);

	for (var frame=0; frame<srts.count(); frame++) {

		// check if process have to be aborted through ESC-key
		PADrend.getEventQueue().process();
		while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
			var evt = PADrend.getEventQueue().popEvent();
			if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed && (evt.key == Util.UI.KEY_ESCAPE || evt.key == Util.UI.KEY_SPACE)) {
				progressOutput.abort();
				return false;
			}
		}

		measurementCamera.setRelTransformation(srts[frame]);
		frameContext.setCamera(measurementCamera);

		evaluator.beginMeasure();
		evaluator.measure(frameContext, PADrend.getRootNode(), measurementCamera.getViewport());
		evaluator.endMeasure(frameContext);

		var results = evaluator.getResults();
		if(results.empty()) {
			out("MeasurementPlugin: list with results is empty!\n");
			return false;
		}

		if (results.count() < 4)
		{
			out("wrong number of results : ", results.count());
			return false;
		}

		// add data to the map
		boxes[frame]            = results[0].toString();
		objects[frame]          = results[1].toString();
		trianglesBoxes[frame]   = results[2].toString();
		trianglesObjects[frame] = results[3].toString();

		// update progress output
		progressOutput.increment();

		// Swap Buffers
		PADrend.SystemUI.swapBuffers();

	}

	return true;
};

/**
 * executes a test for the selected scene (PADrend.getCurrentScene()) scene along selected path two times, and records
 * frameduration, #rendered meshes, #rendered polygons and #box tests for every frame
 * \param scenename : text identifying current scene
 * \param maps with records ...
 */
MeasurementPlugin.InterpolatedTest.executeCurrentScene := fn(String scenename, Map framedur, Map meshes, Map polygons, Map boxtests) {
	if (srts.count() <= 0) {
		out("MeasurementPlugin: no waypoints!\n");
		return false;
	}
	var measurementCamera = camera.clone();
	var scene = PADrend.getCurrentScene();

	// create an object that should output the progress state.
	var progressOutput = new Util.ProgressIndicator("Recording " + scenename, srts.count()*2, 8);


	// 1. empty pass to reorganize meshes in memory
	for (var frame=0; frame < srts.count(); frame++) {

		// check if process have to be aborted through ESC-key
		PADrend.getEventQueue().process();
		while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
			var evt = PADrend.getEventQueue().popEvent();
			if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed && (evt.key == Util.UI.KEY_ESCAPE || evt.key == Util.UI.KEY_SPACE)) {
				progressOutput.abort();
				return false;
			}
		}

		measurementCamera.setRelTransformation(srts[frame]);
		frameContext.setCamera(measurementCamera);

		renderingContext.clearScreen(new Util.Color4f(0.2, 0.2, 0.2, 1));
		GLOBALS.renderingContext.finish();
		statistics.beginFrame(frame);

		//display rootNode
		PADrend.getRootNode().display(frameContext, PADrend.getRenderingFlags());

		// ---- End Frame
		GLOBALS.renderingContext.finish();
		statistics.endFrame();

		// update progress output
		progressOutput.increment();

		// ---- Swap Buffers
		PADrend.SystemUI.swapBuffers();
	}


	// 2. pass to do measuring
	statistics.reset();

	for (frame=0; frame < srts.count(); frame++) {

		// check if process have to be aborted through ESC-key
		PADrend.getEventQueue().process();
		while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
			var evt = PADrend.getEventQueue().popEvent();
			if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed && (evt.key == Util.UI.KEY_ESCAPE || evt.key == Util.UI.KEY_SPACE)) {
				progressOutput.abort();
				return false;
			}
		}

		measurementCamera.setRelTransformation(srts[frame]);
		frameContext.setCamera(measurementCamera);

		renderingContext.clearScreen(new Util.Color4f(0.2, 0.2, 0.2, 1));
		GLOBALS.renderingContext.finish();
		statistics.beginFrame(frame);

		//display rootNode
		PADrend.getRootNode().display(frameContext, PADrend.getRenderingFlags());

		// ---- End Frame
		GLOBALS.renderingContext.finish();
		statistics.endFrame();


		//get attributes
		framedur[frame] = statistics.getValue(statistics.getFrameDurationCounter());
		meshes[frame]   = statistics.getValue(statistics.getVBOCounter());
		polygons[frame] = statistics.getValue(statistics.getTrianglesCounter());
		boxtests[frame] = statistics.getValue(statistics.getOccTestCounter());

		// update progress output
		progressOutput.increment();

		// ---- Swap Buffers
		PADrend.SystemUI.swapBuffers();
	}
	return true; // successfully tested.

};



/**
 * records frameduration, #rendered meshes, #rendered polygons and #box test for all registed
 * scene-nodes. The recorded data for every attribute will be then exported to a single CSV-file.
 * \param fileprefix : is used as prefix for the filenames
 *
 */
MeasurementPlugin.InterpolatedTest.executeAllScenes := fn(String fileprefix) {
	var DataTable = (Std.require('LibUtilExt/DataTable'));
	var scenes = PADrend.getSceneList();

	var frame_durations = new DataTable("frame");
	var rendered_meshes = new DataTable("frame");
	var rendered_polygons = new DataTable("frame");
	var box_tests = new DataTable("frame");

	// get data for each scene and add it to corresponding DataTables
	for (var i=0; i<scenes.count(); i++) {
		if (scenes[i] == void)
			continue;

		// select the scene
		PADrend.selectScene(scenes[i]);

		// calculate average vbo-size for current scene
		//var avgVBOSize = MeasurementPlugin.calculateAvgVBOSize().ceil();

		var framedur = new Map();
		var meshes   = new Map();
		var polygons = new Map();
		var boxtests = new Map();

		// get and adjust scenename
		var scenename = scenes[i].constructionString;
		if (scenename == "")
			scenename = scenes[i].name;
		if (scenename.beginsWith("new ")) //eliminate "new " if necessary
			scenename = scenename.substr(4);
		//scenename = scenename+" avg("+avgVBOSize+")";

		// select color
		var color = "#000000"; //default
		if (i<colors.count()) color = colors[i];

		// execute test for current scene
		var result = executeCurrentScene(scenename, framedur, meshes, polygons, boxtests);
		if (!result) break;

		//add data to dataTables
		frame_durations.addDataRow(scenename ,"y", framedur, color );
		rendered_meshes.addDataRow(scenename ,"y", meshes, color );
		rendered_polygons.addDataRow(scenename ,"y", polygons, color );
		box_tests.addDataRow(scenename ,"y", boxtests, color );
	}

	// export data to CSV/SVG-files
	frame_durations.exportCSV(fileprefix + "_frame_duration.csv");
	frame_durations.exportSVG(fileprefix + "_frame_duration.svg");
	rendered_meshes.exportCSV(fileprefix + "_rendered_objects.csv");
	rendered_meshes.exportSVG(fileprefix + "_rendered_objects.svg");
	rendered_polygons.exportCSV(fileprefix + "_rendered_polygons.csv");
	rendered_polygons.exportSVG(fileprefix + "_rendered_polygons.svg");
	box_tests.exportCSV(fileprefix + "_box_tests.csv");
	box_tests.exportSVG(fileprefix + "_box_tests.svg");
};


/**
 * records data using MinSG.BoxQualityEvaluator for all registered scenes ...
 * \param fileprefix
 */
MeasurementPlugin.InterpolatedTest.executeAllScenesWithBQEvaluator := fn(String fileprefix) {
	var DataTable = (Std.require('LibUtilExt/DataTable'));
	
	var scenes = PADrend.getSceneList();

	var objectsCAsVisible = new DataTable("frame");
	var objectsVisible    = new DataTable("frame");
	var trianglesInCAsVO = new DataTable("frame");
	var trianglesInVisO  = new DataTable("frame");

	for (var i=0; i<scenes.count(); i++) {
		if (scenes[i] == void)
			continue;

		PADrend.selectScene(scenes[i]);

		// calculate average vbo-size for current scene
		//var avgVBOSize = MeasurementPlugin.calculateAvgVBOSize().ceil();

		// create the maps
		var boxes        = new Map();
		var objects      = new Map();
		var trianglesInB = new Map();
		var trianglesInO = new Map();

		// adjust scenename
		var scenename = scenes[i].constructionString;
		if (scenename == "")
			scenename = scenes[i].name;
		if (scenename.beginsWith("new "))
			scenename = scenename.substr(4);
		//scenename = scenename+" avg("+avgVBOSize+")";

		// select color
		var color = "#000000"; //default
		if (i<colors.count()) color = colors[i];

		// execute test for current scene
		var successful = executeBoxQualityEvaluator(scenename, boxes, objects, trianglesInB, trianglesInO);
		if (!successful) break;

		//add data to dataTables
		objectsCAsVisible.addDataRow(scenename ,"y", boxes, color);
		objectsVisible.addDataRow(scenename ,"y", objects, color);
		trianglesInCAsVO.addDataRow(scenename ,"y", trianglesInB, color);
		trianglesInVisO.addDataRow(scenename ,"y", trianglesInO, color);
	}

	// export data to CSV/SVG-files
	objectsCAsVisible.exportCSV(fileprefix + "_as_vis_classified_obj.csv");
	objectsCAsVisible.exportSVG(fileprefix + "_as_vis_classified_obj.svg");
	objectsVisible.exportCSV(fileprefix + "_visible_obj.csv");
	objectsVisible.exportSVG(fileprefix + "_visible_obj.svg");
	trianglesInCAsVO.exportCSV(fileprefix + "_triangles_in_as_vc_obj.csv");
	trianglesInCAsVO.exportSVG(fileprefix + "_triangles_in_as_vc_obj.svg");
	trianglesInVisO.exportCSV(fileprefix + "_triangles_in_vis_obj.csv");
	trianglesInVisO.exportSVG(fileprefix + "_triangles_in_vis_obj.svg");

};
