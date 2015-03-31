/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] Measurement/SampleWaypoints.escript
 **  2010-02-16 - Benjamin Eikel - Function to sample at waypoints on path.
 **  2010-03-24 - Paul Justus - Sampling-progress-output moved to own escript-file.
 **  2011-09-02 - Benjamin Eikel - Rework of sampling process.
 **  2012-11-16 - Benjamin Eikel - Use data wrappers
 **  2013-01-10 - Benjamin Eikel - Update behaviours
 **/

MeasurementPlugin.samplePath := fn(	DataWrapper outputFileName, 
									DataWrapper pointIterations, 
									DataWrapper pathIterations, 
									DataWrapper stepSize) {
	var path = WaypointsPlugin.getActivePath();
	if(!path) {
		throw "Invalid camera path.";
	}

	var evaluator = Std.module('Evaluator/EvaluatorManager').getSelectedEvaluator();
	if(!evaluator) {
		throw "Invalid evaluator.";
	}
	// Check for new Evaluator interface.
	var newEvaluatorInterface =	evaluator.isSet($getExtendedResultDescription)
								&& evaluator.isSet($getExtendedResult);
	if(newEvaluatorInterface) {
		outln("Evaluator provides the extended result interface.");
	}

	outln("Measurement along a path: ", 
		pointIterations(), " point iterations, ", 
		pathIterations(), " path iterations, ",
		"step size ", stepSize(), ", ",
		"output file \"", outputFileName(), "\"");

	PADrend.getSceneManager().getBehaviourManager().executeBehaviours(0);

	var values = "Point\tValue\n";
	if(newEvaluatorInterface) {
		values = "Point\t" + evaluator.getExtendedResultDescription().implode("\t") + "\n";
	}

	frameContext.pushCamera();

	// Initialize a second camera for the measurements.
	var angle = evaluator.getCameraAngle();
	var rect = evaluator.measurementResolution;
	var measurementCamera = PADrend.getActiveCamera().clone();
	measurementCamera.setViewport(rect);
	measurementCamera.applyVerticalAngle(angle);

	// create TestProgressOutput-object with updateTimeInterval of 3 seconds
	var progressOutput = new Util.ProgressIndicator("Sampling waypoints", (path.getMaxTime() / stepSize()) * pathIterations(), 3);

	for(var pathIteration = 0; pathIteration < pathIterations(); ++pathIteration) {
		// Go along the path and measure with the current evaluator.
		for(var time = 0.0; time <= path.getMaxTime(); time += stepSize()) {
			PADrend.getSceneManager().getBehaviourManager().executeBehaviours(time);

			var srt = path.getPosition(time);

			measurementCamera.setRelTransformation(srt);
			frameContext.setCamera(measurementCamera);

			for(var iteration = 0; iteration < pointIterations(); ++iteration) {
				evaluator.beginMeasure();
				evaluator.measure(frameContext, PADrend.getCurrentScene(), rect);
				evaluator.endMeasure(frameContext);

				values += time.toString() + "\t";
				if(newEvaluatorInterface) {
					values += evaluator.getExtendedResult().implode("\t");
				} else {
					var results = evaluator.getResults();
					if(results.empty()) {
						throw "Empty results.";
					}
					// Convert the result to a string and append it to the output values.
					values += results.front().toString();
				}
				values += "\n";
			}

			PADrend.SystemUI.swapBuffers();

			// update progress output
			progressOutput.increment();
		}
	}

	frameContext.popCamera();

	// Output the results to the file.
	IO.filePutContents(outputFileName(), values);
};


