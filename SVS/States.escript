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

SVS.registerStates := fn() {
	registerExtension('NodeEditor_QueryAvailableStates', fn(states) {
		states.set("[ext] SVS BudgetRenderer", fn() { return new MinSG.SVS.BudgetRenderer; });
		states.set("[ext] SVS GeometryNodeCollector", fn() { return new MinSG.SVS.GeometryNodeCollector; });
		states.set("[ext] SVS Renderer", fn() { return new MinSG.SVS.Renderer; });
		states.set("[ext] SVS SphereVisualizationRenderer", fn() { return new MinSG.SVS.SphereVisualizationRenderer; });
	});
	NodeEditor.registerConfigPanelProvider(MinSG.SVS.Renderer, fn(MinSG.SVS.Renderer state, panel) {
		panel += "*SVS Renderer*";
		panel++;
		panel += {
			GUI.TYPE			:	GUI.TYPE_SELECT,
			GUI.LABEL			:	"Interpolation",
			GUI.TOOLTIP			:	"The interpolation method that is used to generate results for queries between spherical sample points.",
			GUI.OPTIONS			:	[
										[MinSG.SVS.INTERPOLATION_NEAREST, "Nearest"],
										[MinSG.SVS.INTERPOLATION_MAX3, "Max3"],
										[MinSG.SVS.INTERPOLATION_MAXALL, "MaxAll"],
										[MinSG.SVS.INTERPOLATION_WEIGHTED3, "Weighted3"]
									],
			GUI.DATA_PROVIDER	:	state -> state.getInterpolationMethod,
			GUI.ON_DATA_CHANGED	:	state -> state.setInterpolationMethod,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Sphere occlusion tests",
			GUI.TOOLTIP			:	"Perform an occlusion test before displaying a sphere.",
			GUI.DATA_PROVIDER	:	state -> state.isSphereOcclusionTestEnabled,
			GUI.ON_DATA_CHANGED	:	(fn(state, data) {
										if(data) {
											state.enableSphereOcclusionTest();
										} else {
											state.disableSphereOcclusionTest();
										}
									}).bindFirstParams(state),
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		panel += {
			GUI.TYPE			:	GUI.TYPE_BOOL,
			GUI.LABEL			:	"Geometry occlusion tests",
			GUI.TOOLTIP			:	"Perform an occlusion test before displaying geometry stored in the visibility information of a sphere.",
			GUI.DATA_PROVIDER	:	state -> state.isGeometryOcclusionTestEnabled,
			GUI.ON_DATA_CHANGED	:	(fn(state, data) {
										if(data) {
											state.enableGeometryOcclusionTest();
										} else {
											state.disableGeometryOcclusionTest();
										}
									}).bindFirstParams(state),
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
	});
	NodeEditor.registerConfigPanelProvider(MinSG.SVS.BudgetRenderer, fn(MinSG.SVS.BudgetRenderer state, panel) {
		panel += "*SVS BudgetRenderer*";
		panel++;

		panel += {
			GUI.TYPE			:	GUI.TYPE_RANGE,
			GUI.LABEL			:	"Budget",
			GUI.TOOLTIP			:	"Overall triangle budget.",
			GUI.RANGE			:	[500000, 100000000],
			GUI.RANGE_STEP_SIZE	:	500000,
			GUI.ON_DATA_CHANGED	:	state -> state.setBudget,
			GUI.DATA_PROVIDER	:	state -> state.getBudget,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
	});
};
