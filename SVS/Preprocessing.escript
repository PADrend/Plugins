/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SVS);

SVS.getDefaultSamplePositions := fn() {
	if(!thisFn.isSet($samples)) {
		thisFn.samples := [];
		var mesh = Rendering.createDodecahedron();
		var accessor = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
		for(var i = 0; accessor.checkRange(i); ++i) {
			thisFn.samples += accessor.getPosition(i);
		}
	}
	return thisFn.samples;
};

SVS.preprocessSubtree := fn(MinSG.SceneManager sceneManager, 
										  MinSG.FrameContext frameContext,
										  MinSG.GroupNode rootNode,
										  Array positions,
										  Number resolution,
										  Bool useExistingVisibilityResults,
										  Bool computeTightInnerBoundingSpheres) {
	var preprocessingContext = new MinSG.SphericalSampling.PreprocessingContext(sceneManager,
																				frameContext,
																				rootNode,
																				positions,
																				resolution,
																				useExistingVisibilityResults,
																				computeTightInnerBoundingSpheres);
	var numNodesOverall = preprocessingContext.getNumRemainingNodes();
	var numNodesFinished = 0;

	var overallTimer = new Util.Timer;
	var outputTimer = new Util.Timer;

	while(!preprocessingContext.isFinished()) {
		preprocessingContext.preprocessSingleNode();

		++numNodesFinished;
		
		if(outputTimer.getSeconds() > 5) {
			var remainingSeconds = overallTimer.getSeconds() / numNodesFinished * (numNodesOverall - numNodesFinished);
			outln(numNodesFinished, "/", numNodesOverall, " nodes finished (approximately ", remainingSeconds, " s remaining)");
			outputTimer.reset();
		}
	}
};

SVS.writePreprocessingInfoFile := fn(MinSG.Node rootNode,
												   Number resolution,
												   Bool useExistingVisibilityResults,
												   Bool computeTightInnerBoundingSpheres) {
	var timeStamp = Util.createTimeStamp();
	var info = {
		"Name"								:	rootNode.name,
		"RenderingResolution"				:	[
													renderingContext.getWindowWidth(),
													renderingContext.getWindowHeight()
												],
		"PreprocessingResolution"			:	[
													resolution,
													resolution
												],
		"useExistingVisibilityResults"		:	useExistingVisibilityResults,
		"computeTightInnerBoundingSpheres"	:	computeTightInnerBoundingSpheres,
		"Statistics"						:	MinSG.collectTreeStatistics(rootNode),
		"TimeStamp"							:	timeStamp
	};
	var options = "(" +
					(useExistingVisibilityResults ? "useVis" : "noUseVis") + "," +
					(computeTightInnerBoundingSpheres ? "tightInner" : "noTightInner") + "," +
					resolution + ")";
	var fileName = timeStamp + "_SVS_Preprocessing" + options + ".json";
	Util.saveFile(fileName, toJSON(info));
	return fileName;
};

SVS.multiplePreprocessingRuns := fn(MinSG.SceneManager sceneManager, 
												  MinSG.FrameContext frameContext,
												  MinSG.GroupNode rootNode,
												  Array positions,
												  Number minResolution,
												  Number maxResolution) {
	sceneManager.registerGeometryNodes(rootNode);
	
	for(var resolution = minResolution; resolution <= maxResolution; resolution *= 2) {
		foreach([false, true] as var useExistingVisibilityResults) {
			foreach([false, true] as var computeTightInnerBoundingSpheres) {
				// Create initial JSON file to get a time stamp before the preprocessing starts
				var infoFile = SVS.writePreprocessingInfoFile(rootNode,
																			resolution,
																			useExistingVisibilityResults,
																			computeTightInnerBoundingSpheres);
				outln("SVS: ", infoFile);

				var memoryBefore = Util.getAllocatedMemorySize();

				var timer = new Util.Timer;
				timer.reset();

				SVS.preprocessSubtree(sceneManager,
													frameContext,
													rootNode,
													positions,
													resolution,
													useExistingVisibilityResults,
													computeTightInnerBoundingSpheres);

				timer.stop();

				var memoryAfter = Util.getAllocatedMemorySize();

				// Add new information to JSON file
				var infoMap = parseJSON(Util.loadFile(infoFile));
				infoMap["RunningTime"] = timer.getSeconds();
				infoMap["RunningTimeUnit"] = "s";
				infoMap["MemoryConsumption"] = (memoryAfter - memoryBefore) / 1024 / 1024;
				infoMap["MemoryConsumptionUnit"] = "MiB";
				Util.saveFile(infoFile, toJSON(infoMap));

				// Save the scene with the same name as the info file (different extension)
				var sceneFile = infoFile.replace(".json", ".minsg");
				sceneManager.saveMinSGFile(new Util.FileName(sceneFile), [rootNode]);

				// Remove all results from the current scene
				foreach(MinSG.collectNodesWithAttribute(rootNode, "SamplingSphere") as var node) {
					node.unsetNodeAttribute("SamplingSphere");
				}
			}
		}
	}
};
