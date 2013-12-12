/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SVS);

loadOnce(__DIR__ + "/SphericalSamplePoint.escript");

//!	[static]
SVS.configureCameraUsingSamples := fn(MinSG.CameraNodeOrtho camera, Geometry.Sphere sphere, Geometry.Matrix4x4 worldMatrix, Array samples) {
	// Simply use first selected sample.
	var sample = void;
	foreach(samples as var potentialSample) {
		if(potentialSample.selected) {
			sample = potentialSample;
			break;
		}
	}
	if(!sample) {
		return;
	}
	
	MinSG.SVS.transformCamera(camera, sphere, worldMatrix, sample.getPosition());
};

//!	[static]
SVS.setUpCameraWindow := fn(plugin) {
	var windowCamera = MinSG.SVS.createSamplingCamera(plugin.sphere, plugin.node.getWorldMatrix(), 512);
	
	registerExtension('PADrend_AfterFrame', this -> (SVS.configureCameraUsingSamples).bindLastParams(windowCamera, plugin.sphere, plugin.node.getWorldMatrix(), plugin.samples));
	
	var window = gui.createWindow(300, 330, "SVS Camera", GUI.ONE_TIME_WINDOW);
	window.setPosition(0, 30);
	window += CameraWindowPlugin.createOptionPanel(windowCamera);
};
