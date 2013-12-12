/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var importContext = PADrend.getSceneManager().createImportContext(MinSG.SceneManager.IMPORT_OPTION_USE_TEXTURE_REGISTRY | MinSG.SceneManager.IMPORT_OPTION_USE_MESH_REGISTRY);
var internalLoadScene =	[importContext] => fn(importContext, fileName) {
							var nodeArray = PADrend.getSceneManager().loadMinSGFile(importContext, fileName);
							var sceneRoot = void;
							if(!nodeArray) {
								outln("Could not load scene from file '", fileName, "'");
							} else if(nodeArray.count() > 1) {
								sceneRoot = new MinSG.ListNode;
								foreach(nodeArray as var node) {
									sceneRoot.addChild(node);
								}
								outln("Note: The MinSG file '", fileName ,"' contains more than one top level node. Adding a new top level ListNode.");
							} else if(nodeArray.size() == 1) {
								sceneRoot = nodeArray[0];
							}
							sceneRoot.name := fileName;
							return sceneRoot;
						};

var dialog = new GUI.FileDialog("Select Directory", "data/SVS/scene", [".minsg"], [internalLoadScene] => fn(internalLoadScene, fileName) {
	var directory = this.getFolder();
	showWaitingScreen();

	foreach(Util.getFilesInDir(directory, [".minsg"]) as var sceneFile) {
		// Check if the measurement output file already exists.
		if(Util.isFile(sceneFile.replace(".minsg", "-VisibleSetEvaluation-Samples-8192.tsv"))) {
			outln("Skipping: ", sceneFile);
			continue;
		}

		outln("Loading: ", sceneFile);
		var scene = internalLoadScene(sceneFile);
		PADrend.registerScene(scene);
		PADrend.selectScene(scene);

		// Search a node that has a sampling sphere by traversing the tree
		var samplingSphere = void;
		var svsNode = void;
		var nodes = [scene];
		while(!nodes.empty()) {
			var node = nodes.popBack();
			if(MinSG.SphericalSampling.hasSamplingSphere(node)) {
				svsNode = node;
				samplingSphere = MinSG.SphericalSampling.retrieveSamplingSphere(node);
				break;
			}
			nodes.append(MinSG.getChildNodes(node));
		}

		if(svsNode != scene) {
			outln("Warning: Scene root has no SamplingSphere.");
		}
		var resolution = 8192;
		SVS.measureVisibleSetQuality(svsNode, samplingSphere, resolution);
	}
});
dialog.init();
