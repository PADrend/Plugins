/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Paul Justus
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2010-2011 Robert Gmyr
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor/StateConfig] NodeEditor/StatePanels.escript
 **
 **/

/*!	State	*/
NodeEditor.registerConfigPanelProvider(MinSG.State, fn(MinSG.State state, panel) {
	panel += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	NodeEditor.getString(state),
		GUI.FONT				:	GUI.FONT_ID_LARGE,
		GUI.COLOR				:	NodeEditor.STATE_COLOR
	};

	panel.nextRow(10);
	panel += '----';
	
	panel++;

	var refreshGroup = new GUI.RefreshGroup;

	panel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"StateId:",
		GUI.DATA_PROVIDER		:	[state] => fn(MinSG.State state) {
										var id = PADrend.getSceneManager().getNameOfRegisteredState(state);
										return id ? id : "";
									},
		GUI.ON_DATA_CHANGED		:	[state] => fn(MinSG.State state, data) {
										var id = data.trim();
										if(!id.empty()){
											outln("Registering state: ", id, " -> ", state);
											PADrend.getSceneManager().registerState(id, state);
										} else {
											id = PADrend.getSceneManager().getNameOfRegisteredState(state);
											outln("Unregister state: ", id);
											PADrend.getSceneManager().unregisterState(id);
										}
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup
	};
	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"refresh",
		GUI.ON_CLICK			:	refreshGroup -> refreshGroup.refresh
	};
	panel++;
	panel += {
    	GUI.TYPE : GUI.TYPE_BOOL,
    	GUI.LABEL : "is active",
    	GUI.DATA_VALUE : state.isActive(),
    	GUI.ON_DATA_CHANGED : [state] => fn(state,data){
			if(data) {
				state.activate();
			} else {
				state.deactivate();
			}
		}
    };
    panel += {
    	GUI.TYPE : GUI.TYPE_BOOL,
    	GUI.LABEL : "is temporary",
    	GUI.DATA_VALUE : state.isTempState(),
    	GUI.ON_DATA_CHANGED : state -> state.setTempState,
		GUI.TOOLTIP : "If enabled, the state is not saved."
    };
	{// rendering Layers
		panel++;
		var m = 1;
		for(var i=0;i<8;++i){
			var dataWrapper = new DataWrapper( state.testRenderingLayer(m) );
			dataWrapper.onDataChanged += [state,m] => fn(state,m,b){
				state.setRenderingLayers( state.getRenderingLayers().setBitMask(m,b) );
			};
			m*=2;

			panel += { 
				GUI.LABEL : ""+i+"    ",
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.TOOLTIP : "State is active on rendering layer #"+i,
				GUI.DATA_WRAPPER : dataWrapper
			};
		}
    }
});

// ----

//! AlphaTestState
NodeEditor.registerConfigPanelProvider(MinSG.AlphaTestState, fn(MinSG.AlphaTestState state, panel) {
	panel += "*AlphaTestState:*";
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_RADIO,
		GUI.OPTIONS			:	[
									[Rendering.Comparison.LESS, "LESS (alpha < ref)"],
									[Rendering.Comparison.LEQUAL, "LEQUAL (alpha <= ref)"],
									[Rendering.Comparison.EQUAL, "EQUAL (alpha == ref)"],
									[Rendering.Comparison.GEQUAL, "GEQUAL (alpha >= ref)"],
									[Rendering.Comparison.GREATER, "GREATER (alpha > ref)"],
									[Rendering.Comparison.NOTEQUAL, "NOTEQUAL (alpha != ref)"],
									[Rendering.Comparison.ALWAYS, "ALWAYS (true)"],
									[Rendering.Comparison.NEVER, "NEVER (false)"]
								],
		GUI.DATA_PROVIDER	:	state -> fn() {
									return getParameters().getMode();
								},
		GUI.ON_DATA_CHANGED	: 	state -> fn(newMode) {
									setParameters(getParameters().setMode(newMode));
								}
	};
	panel++;

	panel += {
		GUI.LABEL			:	"Reference Value",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[0.0, 1.0],
		GUI.RANGE_STEPS		:	100,
		GUI.DATA_PROVIDER	:	state -> fn() {
									return getParameters().getReferenceValue();
								},
		GUI.ON_DATA_CHANGED	:	state -> fn(newRefValue) {
									setParameters(getParameters().setReferenceValue(newRefValue));
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
});

// ----

/*!	AlgoSelector */
if(MinSG.isSet($MAR))
{
	NodeEditor.registerConfigPanelProvider( MinSG.MAR.AlgoSelector, fn(MinSG.MAR.AlgoSelector state, panel){
		panel += {
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.OPTIONS : [
				[MinSG.MAR.MultiAlgoGroupNode.Auto, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.Auto)],
				[MinSG.MAR.MultiAlgoGroupNode.ForceSurfels, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.ForceSurfels)],
				[MinSG.MAR.MultiAlgoGroupNode.BlueSurfels, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.BlueSurfels)],
				[MinSG.MAR.MultiAlgoGroupNode.ColorCubes, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.ColorCubes)],
				[MinSG.MAR.MultiAlgoGroupNode.SphericalSampling, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.SphericalSampling)],
				[MinSG.MAR.MultiAlgoGroupNode.CHCpp, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.CHCpp)],
				[MinSG.MAR.MultiAlgoGroupNode.CHCppAggressive, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.CHCppAggressive)],
				[MinSG.MAR.MultiAlgoGroupNode.BruteForce, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.BruteForce)],
				[MinSG.MAR.MultiAlgoGroupNode.ClassicLOD, MinSG.MAR.MultiAlgoGroupNode.algoIdToString(MinSG.MAR.MultiAlgoGroupNode.ClassicLOD)]
			],
			GUI.LABEL : "Mode",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(state->state.getRenderMode, state->state.setRenderMode)
		};
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.OPTIONS : [
				[MinSG.MAR.AlgoSelector.NEAREST, "Nearest"],
				[MinSG.MAR.AlgoSelector.MAX4, "Max 4"],
				[MinSG.MAR.AlgoSelector.BARY, "Bary"]
			],
			GUI.LABEL : "Interpolation",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(state->state.getInterpolationMode, state->state.setInterpolationMode)
		};
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.OPTIONS : [
				[MinSG.MAR.AlgoSelector.ABS, "Absolute"],
				[MinSG.MAR.AlgoSelector.REL, "Relative"],
				[MinSG.MAR.AlgoSelector.CYCLE, "Control Cycle"]
			],
			GUI.LABEL : "Regulation",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(state->state.getRegulationMode, state->state.setRegulationMode)
		};
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.RANGE : [5, 200],
			GUI.RANGE_STEPS : 195,
			GUI.LABEL : "Target Time",
			GUI.DATA_WRAPPER : DataWrapper.createFromFunctions(state->state.getTargetTime, state->state.setTargetTime)
		};
	});

	NodeEditor.registerConfigPanelProvider( MinSG.MAR.SurfelRenderer, fn(MinSG.MAR.SurfelRenderer state, panel){
		var dw = DataWrapper.createFromFunctions(state->state.getSurfelCountFactor, state->state.setSurfelCountFactor);
		panel += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Surfel Count Factor",
			GUI.RANGE : [-5,5],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 2,
			GUI.DATA_WRAPPER : dw
		};
		dw = DataWrapper.createFromFunctions(state->state.getSurfelSizeFactor, state->state.setSurfelSizeFactor);
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Surfel Size Factor",
			GUI.RANGE : [-5,5],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 2,
			GUI.DATA_WRAPPER : dw
		};
		dw = DataWrapper.createFromFunctions(state->state.getMaxAutoSurfelSize, state->state.setMaxAutoSurfelSize);
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "max auto surfel size",
			GUI.RANGE : [1,10],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : dw
		};
		dw = DataWrapper.createFromFunctions(state->state.getForceSurfels, state->state.setForceSurfels);
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Force Surfels",
			GUI.DATA_WRAPPER : dw
		};
	});
}

// -----

//! BlendingState
NodeEditor.registerConfigPanelProvider(MinSG.BlendingState, fn(MinSG.BlendingState state, panel) {
	var equations = [
		[Rendering.BlendEquation.FUNC_ADD, "FUNC_ADD"],
		[Rendering.BlendEquation.FUNC_SUBTRACT, "FUNC_SUBTRACT"],
		[Rendering.BlendEquation.FUNC_REVERSE_SUBTRACT, "FUNC_REVERSE_SUBTRACT"]
	];
	var functions = [
		[Rendering.BlendFunc.ZERO, "ZERO"],
		[Rendering.BlendFunc.ONE, "ONE"],
		[Rendering.BlendFunc.SRC_COLOR, "SRC_COLOR"],
		[Rendering.BlendFunc.ONE_MINUS_SRC_COLOR, "ONE_MINUS_SRC_COLOR"],
		[Rendering.BlendFunc.SRC_ALPHA, "SRC_ALPHA"],
		[Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA, "ONE_MINUS_SRC_ALPHA"],
		[Rendering.BlendFunc.DST_ALPHA, "DST_ALPHA"],
		[Rendering.BlendFunc.ONE_MINUS_DST_ALPHA, "ONE_MINUS_DST_ALPHA"],
		[Rendering.BlendFunc.DST_COLOR, "DST_COLOR"],
		[Rendering.BlendFunc.ONE_MINUS_DST_COLOR, "ONE_MINUS_DST_COLOR"],
		[Rendering.BlendFunc.SRC_ALPHA_SATURATE, "SRC_ALPHA_SATURATE"],
		[Rendering.BlendFunc.CONSTANT_COLOR, "CONSTANT_COLOR"],
		[Rendering.BlendFunc.ONE_MINUS_CONSTANT_COLOR, "ONE_MINUS_CONSTANT_COLOR"],
		[Rendering.BlendFunc.CONSTANT_ALPHA, "CONSTANT_ALPHA"],
		[Rendering.BlendFunc.ONE_MINUS_CONSTANT_ALPHA, "ONE_MINUS_CONSTANT_ALPHA"]
	];

	var blendingParams = state.getParameters();
	var equalParams = 	blendingParams.getBlendEquationRGB() == blendingParams.getBlendEquationAlpha() &&
						blendingParams.getBlendFuncSrcRGB() == blendingParams.getBlendFuncSrcAlpha() &&
						blendingParams.getBlendFuncDstRGB() == blendingParams.getBlendFuncDstAlpha();

	var refreshGroup = new GUI.RefreshGroup;
	refreshGroup.separate := !equalParams;

	panel += {
		GUI.TYPE				:	GUI.TYPE_BOOL,
		GUI.LABEL				:	"Separate",
		GUI.TOOLTIP				:	"If checked, different RGB and Alpha values can be set.",
		GUI.DATA_OBJECT			:	refreshGroup,
		GUI.DATA_ATTRIBUTE		:	$separate
	};
	panel++;

	var separatePanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_ABS,4,2]
	});

	separatePanel.nextColumn();
	separatePanel += "RGB";
	separatePanel.nextColumn();
	separatePanel += "Alpha";
	separatePanel++;

	separatePanel += "Equation";
	separatePanel.nextColumn();
	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.OPTIONS				:	equations,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendEquationRGB();
									},
		GUI.ON_DATA_CHANGED		:	state -> (fn(newEquation, refreshGroup) {
										setParameters(getParameters().setBlendEquationRGB(newEquation));
										if(!refreshGroup.separate) {
											setParameters(getParameters().setBlendEquationAlpha(newEquation));
											refreshGroup.refresh();
										}
									}).bindLastParams(refreshGroup),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.WIDTH				:	200
	};
	separatePanel.nextColumn();
	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.OPTIONS				:	equations,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendEquationAlpha();
									},
		GUI.ON_DATA_CHANGED		:	state -> (fn(newEquation, refreshGroup) {
										setParameters(getParameters().setBlendEquationAlpha(newEquation));
										if(!refreshGroup.separate) {
											setParameters(getParameters().setBlendEquationRGB(newEquation));
											refreshGroup.refresh();
										}
									}).bindLastParams(refreshGroup),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.WIDTH				:	200
	};
	separatePanel++;

	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"Src Func",
		GUI.TOOLTIP				:	"Source function"
	};
	separatePanel.nextColumn();
	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.OPTIONS				:	functions,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendFuncSrcRGB();
									},
		GUI.ON_DATA_CHANGED		:	state -> (fn(newFunction, refreshGroup) {
										setParameters(getParameters().setBlendFuncSrcRGB(newFunction));
										if(!refreshGroup.separate) {
											setParameters(getParameters().setBlendFuncSrcAlpha(newFunction));
											refreshGroup.refresh();
										}
									}).bindLastParams(refreshGroup),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.WIDTH				:	200
	};
	separatePanel.nextColumn();
	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.OPTIONS				:	functions,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendFuncSrcAlpha();
									},
		GUI.ON_DATA_CHANGED		:	state -> (fn(newFunction, refreshGroup) {
										setParameters(getParameters().setBlendFuncSrcAlpha(newFunction));
										if(!refreshGroup.separate) {
											setParameters(getParameters().setBlendFuncSrcRGB(newFunction));
											refreshGroup.refresh();
										}
									}).bindLastParams(refreshGroup),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.WIDTH				:	200
	};
	separatePanel++;

	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	"Dst Func",
		GUI.TOOLTIP				:	"Destination function"
	};
	separatePanel.nextColumn();
	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.OPTIONS				:	functions,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendFuncDstRGB();
									},
		GUI.ON_DATA_CHANGED		:	state -> (fn(newFunction, refreshGroup) {
										setParameters(getParameters().setBlendFuncDstRGB(newFunction));
										if(!refreshGroup.separate) {
											setParameters(getParameters().setBlendFuncDstAlpha(newFunction));
											refreshGroup.refresh();
										}
									}).bindLastParams(refreshGroup),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.WIDTH				:	200
	};
	separatePanel.nextColumn();
	separatePanel += {
		GUI.TYPE				:	GUI.TYPE_SELECT,
		GUI.OPTIONS				:	functions,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendFuncDstAlpha();
									},
		GUI.ON_DATA_CHANGED		:	state -> (fn(newFunction, refreshGroup) {
										setParameters(getParameters().setBlendFuncDstAlpha(newFunction));
										if(!refreshGroup.separate) {
											setParameters(getParameters().setBlendFuncDstRGB(newFunction));
											refreshGroup.refresh();
										}
									}).bindLastParams(refreshGroup),
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.WIDTH				:	200
	};
	separatePanel++;

	panel += separatePanel;
	panel++;

	panel += {
		GUI.TYPE				:	GUI.TYPE_COLOR,
		GUI.LABEL				:	"Color",
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getBlendColor();
									},
		GUI.ON_DATA_CHANGED		:	state -> fn(newColor) {
										setParameters(getParameters().setBlendColor(newColor));
									}
	};

	panel += {
		GUI.TYPE				:	GUI.TYPE_BOOL,
		GUI.LABEL				:	"Depth mask",
		GUI.DATA_PROVIDER		:	state -> state.getBlendDepthMask,
		GUI.ON_DATA_CHANGED		:	state -> state.setBlendDepthMask
	};
});

// ----

//! BudgetAnnotationState
NodeEditor.registerConfigPanelProvider(MinSG.BudgetAnnotationState, fn(MinSG.BudgetAnnotationState state, panel) {
	panel += "*BudgetAnnotationState*";
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.LABEL			:	"Attribute",
		GUI.TOOLTIP			:	"Name of the attribute that is stored in the nodes.",
		GUI.ON_DATA_CHANGED	:	state -> state.setAnnotationAttribute,
		GUI.DATA_PROVIDER	:	state -> state.getAnnotationAttribute,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Budget",
		GUI.TOOLTIP			:	"Initial budget that is distributed among the tree.",
		GUI.RANGE			:	[0, 1000],
		GUI.RANGE_STEPS		:	1000,
		GUI.ON_DATA_CHANGED	:	state -> state.setBudget,
		GUI.DATA_PROVIDER	:	state -> state.getBudget,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_SELECT,
		GUI.LABEL			:	"Distribution type",
		GUI.TOOLTIP			:	"Type of function to calculate the fractions of the budget.",
		GUI.OPTIONS			:	[
									[MinSG.BudgetAnnotationState.DISTRIBUTE_EVEN, "Even", "Even", "For a node with k child nodes, every child node receives a fraction of 1 / k of the budget."],
									[MinSG.BudgetAnnotationState.DISTRIBUTE_PROJECTED_SIZE, "Projected size", "Projected size", "Distribute the budget based on the projected size of the child nodes."],
									[MinSG.BudgetAnnotationState.DISTRIBUTE_PROJECTED_SIZE_AND_PRIMITIVE_COUNT, "Projected size and primitive count", "Projected size and primitive count", "Distribute the budget based on the projected size and the primitive count of the child nodes."],
									[MinSG.BudgetAnnotationState.DISTRIBUTE_DELETE, "Delete", "Delete", "Delete the attribute from all nodes."]
								],
		GUI.ON_DATA_CHANGED	:	state -> state.setDistributionType,
		GUI.DATA_PROVIDER	:	state -> state.getDistributionType,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
});

// -----

/*! CHCppRenderer */
NodeEditor.registerConfigPanelProvider(MinSG.CHCppRenderer, fn(MinSG.CHCppRenderer state, panel) {
	panel += "*CHC++ Renderer*";
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Culling",
		GUI.ON_CLICK		:	[state] => fn(MinSG.CHCppRenderer renderer) {
									renderer.setMode(MinSG.CHCppRenderer.MODE_CULLING);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.23, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Show Visible",
		GUI.ON_CLICK		:	[state] => fn(MinSG.CHCppRenderer renderer) {
									renderer.setMode(MinSG.CHCppRenderer.MODE_SHOW_VISIBLE);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.23, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Show Culled",
		GUI.ON_CLICK		:	[state] => fn(MinSG.CHCppRenderer renderer) {
									renderer.setMode(MinSG.CHCppRenderer.MODE_SHOW_CULLED);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.23, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Unconditioned",
		GUI.TOOLTIP			:	"Without exploiting temporal coherence.",
		GUI.ON_CLICK		:	[state] => fn(MinSG.CHCppRenderer renderer) {
									renderer.setMode(MinSG.CHCppRenderer.MODE_UNCONDITIONED);
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 20]
	};
	panel++;

	var visibilityThreshold = DataWrapper.createFromFunctions(	state -> state.getVisibilityThreshold,
																state -> state.setVisibilityThreshold);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"visibilityThreshold",
		GUI.RANGE			:	[0.0, 200.0],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	visibilityThreshold,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var maxPrevInvisNodesBatchSize = DataWrapper.createFromFunctions(	state -> state.getMaxPrevInvisNodesBatchSize,
																		state -> state.setMaxPrevInvisNodesBatchSize);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"maxPrevInvisNodesBatchSize",
		GUI.RANGE			:	[1.0, 200.0],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	maxPrevInvisNodesBatchSize,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var skippedFramesTillQuery = DataWrapper.createFromFunctions(	state -> state.getSkippedFramesTillQuery,
																	state -> state.setSkippedFramesTillQuery);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"skippedFramesTillQuery",
		GUI.RANGE			:	[0.0, 50.0],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	skippedFramesTillQuery,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var maxDepthForTightBoundingVolumes = DataWrapper.createFromFunctions(	state -> state.getMaxDepthForTightBoundingVolumes,
																			state -> state.setMaxDepthForTightBoundingVolumes);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"maxDepthForTightBoundingVolumes",
		GUI.RANGE			:	[0.0, 10.0],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	maxDepthForTightBoundingVolumes,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var maxAreaDerivationForTightBoundingVolumes = DataWrapper.createFromFunctions(	state -> state.getMaxAreaDerivationForTightBoundingVolumes,
																					state -> state.setMaxAreaDerivationForTightBoundingVolumes);
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"maxAreaDerivationForTightBoundingVolumes",
		GUI.RANGE			:	[0.0, 10.0],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	maxAreaDerivationForTightBoundingVolumes,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
});

// -----

//! ColorCubeRenderer
if(MinSG.isSet($ColorCubeRenderer))
NodeEditor.registerConfigPanelProvider(MinSG.ColorCubeRenderer, fn(MinSG.ColorCubeRenderer state, panel) {
	panel += "*Color Cube Renderer:*";
	panel++;
	panel+={
		GUI.LABEL			:	"Highlighting (debug)",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.ON_DATA_CHANGED	:	state -> state.setHighlightEnabled,
		GUI.DATA_PROVIDER	:	state -> state.isHighlightEnabled
	};
});

// ----

//! CullFaceState
NodeEditor.registerConfigPanelProvider( MinSG.CullFaceState, fn(MinSG.CullFaceState state, panel){
	panel += {
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.LABEL			:	"Enabled",
		GUI.DATA_PROVIDER	:	state -> state.getCullingEnabled,
		GUI.ON_DATA_CHANGED	: 	state -> state.setCullingEnabled
	};
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_RADIO,
		GUI.OPTIONS			:	[
									[Rendering.CULL_FRONT, "Cull FRONT-facing polygons."],
									[Rendering.CULL_BACK, "Cull BACK-facing polygons."],
									[Rendering.CULL_FRONT_AND_BACK, "Cull FRONT- and BACK-facing polygons."]
								],
		GUI.DATA_PROVIDER	:	state -> state.getCullMode,
		GUI.ON_DATA_CHANGED	: 	state -> state.setCullMode
	};
});

// ----

//! LODRenderer
NodeEditor.registerConfigPanelProvider( MinSG.LODRenderer, fn(MinSG.LODRenderer state, panel){
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE_FN_BASE	:	2,
		GUI.RANGE			:	[10,25],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.LABEL			:	"Min-Complexity",
		GUI.DATA_PROVIDER	:	state -> state.getMinComplexity,
		GUI.ON_DATA_CHANGED	: 	state -> state.setMinComplexity
	};
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE_FN_BASE	:	2,
		GUI.RANGE			:	[10,25],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.LABEL			:	"Max-Complexity",
		GUI.DATA_PROVIDER	:	state -> state.getMaxComplexity,
		GUI.ON_DATA_CHANGED	: 	state -> state.setMaxComplexity
	};
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE_FN_BASE	:	2,
		GUI.RANGE			:	[-5,5],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.LABEL			:	"Rel-Complexity",
		GUI.DATA_PROVIDER	:	state -> state.getRelComplexity,
		GUI.ON_DATA_CHANGED	: 	state -> state.setRelComplexity
	};
});

// ----

NodeEditor.registerConfigPanelProvider(MinSG.MaterialState, fn(MinSG.MaterialState state, panel) {
	panel += "*Material State:*";
	panel++;

	var refreshGroup = new GUI.RefreshGroup;


	panel += {
		GUI.TYPE				:	GUI.TYPE_COLOR,
		GUI.LABEL				:	"Ambient",
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getAmbient();
									},
		GUI.ON_DATA_CHANGED		:	state -> fn(newColor) {
										setParameters(getParameters().setAmbient(newColor));
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.48, 0]
	};
	panel += {
		GUI.TYPE				:	GUI.TYPE_COLOR,
		GUI.LABEL				:	"Diffuse",
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getDiffuse();
									},
		GUI.ON_DATA_CHANGED		:	state -> fn(newColor) {
										setParameters(getParameters().setDiffuse(newColor));
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	panel += {
		GUI.TYPE				:	GUI.TYPE_COLOR,
		GUI.LABEL				:	"Specular",
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getSpecular();
									},
		GUI.ON_DATA_CHANGED		:	state -> fn(newColor) {
										setParameters(getParameters().setSpecular(newColor));
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_REL, 0.48, 0]
	};
	var shininessPanel = gui.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_FLOW,
		GUI.FLAGS				:	GUI.RAISED_BORDER,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
	});
	panel += shininessPanel;

	shininessPanel += {
		GUI.TYPE				:	GUI.TYPE_RANGE,
		GUI.LABEL				:	"Shininess",
		GUI.RANGE				:	[0.0, 128.0],
		GUI.RANGE_STEPS			:	256,
		GUI.DATA_PROVIDER		:	state -> fn() {
										return getParameters().getShininess();
									},
		GUI.ON_DATA_CHANGED		:	state -> fn(newValue) {
										setParameters(getParameters().setShininess(newValue));
									},
		GUI.DATA_REFRESH_GROUP	:	refreshGroup,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	shininessPanel++;
	shininessPanel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Pre multiply alpha",
		GUI.ON_CLICK			:	state -> (fn(refreshGroup) {
										preMultiplyAlpha();
										refreshGroup.refresh();
									}).bindLastParams(refreshGroup),
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

});

// ----

/*! HOMRenderer */
NodeEditor.registerConfigPanelProvider( MinSG.HOMRenderer, fn(MinSG.HOMRenderer state, panel){
	panel += "*HOM (Hierarchical Occlusion Maps) Renderer:*";
	panel++;
	
	panel += {
		GUI.LABEL			:	"Minimum Occluder Size",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[0.0, 100.0],
		GUI.RANGE_STEPS		:	200,
		GUI.DATA_VALUE		:	state.getMinOccluderSize(),
		GUI.ON_DATA_CHANGED	:	state -> fn(data) {
									this.setMinOccluderSize(data);
									this.initOccluderDatabase();
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	
	panel += {
		GUI.LABEL			:	"Maximum Occluder Complexity",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[0.0, 200000.0],
		GUI.RANGE_STEPS		:	400,
		GUI.DATA_VALUE		:	state.getMaxOccluderComplexity(),
		GUI.ON_DATA_CHANGED	:	state -> fn(data) {
									this.setMaxOccluderComplexity(data);
									this.initOccluderDatabase();
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
		
	panel += {
		GUI.LABEL			:	"Maximum Occluder Depth",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[0.0, 200.0],
		GUI.RANGE_STEPS		:	400,
		GUI.DATA_VALUE		:	state.getMaxOccluderDepth(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.HOMRenderer.setMaxOccluderDepth,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	
	panel += {
		GUI.LABEL			:	"Triangle Limit",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[0.0, 200000.0],
		GUI.RANGE_STEPS		:	400,
		GUI.DATA_VALUE		:	state.getTriangleLimit(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.HOMRenderer.setTriangleLimit,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	
	panel += {
		GUI.LABEL			:	"HOM Pyramid Side Length",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[3, 11],
		GUI.RANGE_STEPS		:	8,
		GUI.RANGE_FN_BASE	:	2,
		GUI.DATA_VALUE		:	state.getSideLength(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.HOMRenderer.setSideLength,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	
	panel += {
		GUI.LABEL			:	"Show occluders only",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.DATA_VALUE		:	state.getShowOnlyOccluders(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.HOMRenderer.setShowOnlyOccluders
	};
	panel++;
	
	panel += {
		GUI.LABEL			:	"Show HOM pyramid",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.DATA_VALUE		:	state.getShowHOMPyramid(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.HOMRenderer.setShowHOMPyramid
	};
	panel++;
	
	panel += {
		GUI.LABEL			:	"Show culled geometry",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.DATA_VALUE		:	state.getShowCulledGeometry(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.HOMRenderer.setShowCulledGeometry
	};
});

// ----

/*! LightingState */
NodeEditor.registerConfigPanelProvider( MinSG.LightingState, fn(MinSG.LightingState state, panel){
	panel+= "*Lighting State:*";
	panel++;

	var dd = gui.createDropdown(300, 15);
	dd.state := state;
	dd.refresh := fn() {
		this.clear();
		var lightNodes = MinSG.collectLightNodes(PADrend.getRootNode());
		foreach(lightNodes as var light) {
			var option = this.addOption(light, NodeEditor.getString(light));
		}
		this.setData(this.state.getLight());
	};
	dd.onDataChanged = fn(data) {
		if(data) {
			this.state.setLight(getData());
		}
	};
	panel.add(dd);

	dd.refresh();

	var button = gui.createButton(40, 15, "Select");
	button.setTooltip("Select the current light node.");
	button.dd := dd;
	button.onClick = fn() {
		var node = this.dd.getData();
		if(node) {
			GLOBALS.NodeEditor.selectNode(node);
		}
	};
	panel.add(button);

	panel++;

	button = gui.createButton(300, 15, "Refresh");
	button.dd := dd;
	button.onClick = fn() {
		this.dd.refresh();
	};
	panel.add(button);
});

// ----

/*! NodeRendererState */
NodeEditor.registerConfigPanelProvider(MinSG.NodeRendererState, fn(MinSG.NodeRendererState state, panel) {
	panel += {
		GUI.LABEL			:	"SourceChannel",
		GUI.TYPE			:	GUI.TYPE_TEXT,
		GUI.ON_DATA_CHANGED	:	state -> state.setSourceChannel,
		GUI.DATA_PROVIDER	:	state -> state.getSourceChannel,
		GUI.OPTIONS			:	[MinSG.FrameContext.DEFAULT_CHANNEL, MinSG.FrameContext.APPROXIMATION_CHANNEL],
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
});

// -----

/*! OccRenderer */
NodeEditor.registerConfigPanelProvider(MinSG.OccRenderer, fn(MinSG.OccRenderer state, panel) {
	panel+= "*CHC Renderer*";
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Culling",
		GUI.ON_CLICK		:	[state] => fn(MinSG.OccRenderer renderer) {
									renderer.setMode(MinSG.OccRenderer.MODE_CULLING);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.18, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Show Visible",
		GUI.ON_CLICK		:	[state] => fn(MinSG.OccRenderer renderer) {
									renderer.setMode(MinSG.OccRenderer.MODE_SHOW_VISIBLE);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.18, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Show Culled",
		GUI.ON_CLICK		:	[state] => fn(MinSG.OccRenderer renderer) {
									renderer.setMode(MinSG.OccRenderer.MODE_SHOW_CULLED);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.18, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Opt Culling",
		GUI.ON_CLICK		:	[state] => fn(MinSG.OccRenderer renderer) {
									renderer.setMode(MinSG.OccRenderer.MODE_OPT_CULLING);
								},
		GUI.SIZE			:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 0.18, 20]
	};
	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Unconditioned",
		GUI.TOOLTIP			:	"Without exploiting temporal coherence.",
		GUI.ON_CLICK		:	[state] => fn(MinSG.OccRenderer renderer) {
									renderer.setMode(MinSG.OccRenderer.MODE_UNCONDITIONED);
								},
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 20]
	};
	panel++;
});

// ----

//! PolygonModeState
NodeEditor.registerConfigPanelProvider(MinSG.PolygonModeState, fn(MinSG.PolygonModeState state, panel) {
	panel += "*PolygonModeState:*";
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_RADIO,
		GUI.OPTIONS			:	[
									[Rendering.PolygonModeParameters.POINT, "POINT (raster polygons as points)"],
									[Rendering.PolygonModeParameters.LINE, "LINE (raster polygons as lines)"],
									[Rendering.PolygonModeParameters.FILL, "FILL (raster polygons as polygons)"]
								],
		GUI.DATA_PROVIDER	:	state -> fn() {
									return getParameters().getMode();
								},
		GUI.ON_DATA_CHANGED	: 	state -> fn(newMode) {
									setParameters(getParameters().setMode(newMode));
								}
	};
});

// ----

/*! ProjSizeFilterState */
NodeEditor.registerConfigPanelProvider( MinSG.ProjSizeFilterState, fn(MinSG.ProjSizeFilterState state, panel){
	panel+=	"Changes the rendering channel of nodes when their projected size is smaller \n"+
			"than the given value ( if they are far enough away).\n"+
			"Works best in combination with an approximation renderer (e.g. ColorCubeRenderer).\n";
	panel++;
	panel+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Maximum projection size",
		GUI.RANGE : [1,1000],
		GUI.ON_DATA_CHANGED : state->state.setMaximumProjSize,
		GUI.DATA_PROVIDER	:	state -> state.getMaximumProjSize,
		GUI.TOOLTIP : "This threshold determines the maximum size(surface) of projection rect for nodes rendered\n"+
					 "in the other channel.",
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	panel+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Minimum distance",
		GUI.RANGE : [0,500],
		GUI.ON_DATA_CHANGED : state->state.setMinimumDistance,
		GUI.DATA_PROVIDER	:	state -> state.getMinimumDistance,
		GUI.TOOLTIP : "This threshold determines the minimum distance to an object so that it may be rendered in the \n"+
					 "in the other channel.",
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	panel+={
		GUI.LABEL : "TargetChannel",
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.ON_DATA_CHANGED : state->state.setTargetChannel,
		GUI.DATA_PROVIDER	:	state -> state.getTargetChannel,
		GUI.OPTIONS :  	[ MinSG.FrameContext.DEFAULT_CHANNEL,MinSG.FrameContext.APPROXIMATION_CHANNEL ],
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
});

// -------
// shader


NodeEditor.Wrappers.ShaderObjectWrapper := new Type();
var ShaderObjectWrapper = NodeEditor.Wrappers.ShaderObjectWrapper;
ShaderObjectWrapper._constructor ::= fn(MinSG.ShaderState _shaderState,index){
	this.shaderState := _shaderState;
	this.index := index;
};

NodeEditor.addConfigTreeEntryProvider(MinSG.ShaderState,fn( obj,entry ){
	entry.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : "#RefreshSmall",
		GUI.TOOLTIP : "Re-create the shader",
		GUI.FLAGS : GUI.FLAT_BUTTON,
		GUI.WIDTH : 15,
		GUI.ON_CLICK : [entry] => fn(entry){
			PADrend.message("Recreate shader.");
			entry.getObject().recreateShader( PADrend.getSceneManager() ); 
			entry.rebuild();
		}
	});
	entry.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Progs",
		GUI.FLAGS : GUI.FLAT_BUTTON,
		GUI.WIDTH : 35,
		GUI.COLOR : GUI.WHITE,
		GUI.TOOLTIP : "Show shader objects",
		GUI.ON_CLICK : [entry] => fn(entry){
			entry.rebuild();
			var shaderState = entry.getObject(); 
			var programs = shaderState.getStateAttribute(MinSG.ShaderState.STATE_ATTR_SHADER_FILES);
			var index;
			foreach(programs as index,var program){
				entry.createSubentry(new NodeEditor.Wrappers.ShaderObjectWrapper(shaderState,index));
			}
			entry.createSubentry(new NodeEditor.Wrappers.ShaderObjectWrapper(shaderState,index+1));
		}
	});
	entry.addMenuProvider( fn(entry,Map menu){
		menu['10_importExport'] = [{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Export programs",
				GUI.ON_CLICK : entry->fn(){
					fileDialog("Save shader program list ",PADrend.getUserPath(),".shader",this->fn(filename){
						var shaderState = this.getObject();
						var s=toJSON(shaderState.getStateAttribute(MinSG.ShaderState.STATE_ATTR_SHADER_FILES));
						out("\n",s);
						PADrend.message("Exporting shader to ",filename);
						IO.filePutContents(filename,s);
					});
				}
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Import programs",
				GUI.ON_CLICK : entry->fn(){
					fileDialog("Import shader program list ",PADrend.getUserPath(),".shader",this->fn(filename){
						PADrend.message("Importing shader from ",filename);
						var data = parseJSON(IO.fileGetContents(filename));
						var shaderState = this.getObject();
						shaderState.setStateAttribute(MinSG.ShaderState.STATE_ATTR_SHADER_FILES,data);
						this.rebuild();
					});
				}
			}
		];
	});
});

NodeEditor.addConfigTreeEntryProvider(ShaderObjectWrapper,fn( obj,entry ){
	var shaderState = obj.shaderState;
	var getMetaData = [MinSG.ShaderState.STATE_ATTR_SHADER_FILES] => (shaderState->shaderState.getStateAttribute);
	var setMetaData = [MinSG.ShaderState.STATE_ATTR_SHADER_FILES] => (shaderState->shaderState.setStateAttribute);
	var index = obj.index;

	var programInfo = getMetaData()[index];
	if(!programInfo)
		programInfo={'file':"",'type':""};
	entry.setLabel("");
	
	entry.getBaseContainer()+={
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
		GUI.CONTENTS : [{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_VALUE : programInfo['type'],
				GUI.ON_DATA_CHANGED : [getMetaData,setMetaData,index] => fn(getMetaData,setMetaData,index, data){
					var metaData = getMetaData();
					if( index>=metaData.count() )
						metaData+={'file':"",'type':data};
					else
						metaData[index]['type'] = data;
					setMetaData(metaData);
				},
				GUI.OPTIONS : ["shader/glsl_vs","shader/glsl_fs","shader/glsl_gs"],
				GUI.SIZE : [GUI.WIDTH_ABS,100,0],
				GUI.TOOLTIP : "Shader program type"
			},
			{
				GUI.TYPE : GUI.TYPE_FILE,
				GUI.LABEL : false,
				GUI.DATA_VALUE : programInfo['file'],
				GUI.ON_DATA_CHANGED : [getMetaData,setMetaData,index] => fn(getMetaData,setMetaData,index, data){
					var metaData = getMetaData();
					if( index>=metaData.count() )
						metaData+={'file':data,'type':""};
					else
						metaData[index]['file'] = data;
					setMetaData(metaData);
				},
				GUI.OPTIONS : [programInfo['file']],
				GUI.SIZE : [GUI.WIDTH_FILL_ABS,160,0],
				GUI.ENDINGS : [".fs",".gs",".vs",".sfn"],
				GUI.TOOLTIP : "Shader program file.\nLeave empty to remove program from shader!"
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Edit",
				GUI.ON_CLICK : [getMetaData,index] => fn(getMetaData,index){
					var filename = getMetaData()[index]['file'];
					var fullPath = PADrend.getSceneManager().locateFile(filename);
					if(fullPath)
						Util.openOS(""+fullPath);
					else{
						Runtime.warn("ShaderFile not found: "+filename);
					}
				},
				GUI.WIDTH : 40,
				GUI.TOOLTIP : "Edit the file using the system's editor."
			}
		],
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
	};
								
});


gui.registerComponentProvider('NodeEditor_UniformEditor',fn(uniformContainer){
	var entries = [];

	var tv = gui.create({
		GUI.TYPE : GUI.TYPE_TREE,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS , 2 ,100 ]
	});
	entries+=tv;
	var	uniformInputList = [];

	tv.refresh := [uniformContainer,uniformInputList] => fn(uniformContainer,uniformInputList){
		this.clear();
		uniformInputList.clear();
		var uniforms = uniformContainer.getUniforms();
		uniforms+=new Rendering.Uniform('',Rendering.Uniform.FLOAT,[0]);
		foreach(uniforms as var uniform){
			var entry=gui.createContainer(400,20);
			this.add(entry);
			// name
			var nameTF=gui.createTextfield(100,15,uniform.getName());
			nameTF.onDataChanged := this->apply;
			nameTF.setPosition(0,2);
			entry.add(nameTF);

			var typeDD=gui.createDropdown(80,15);
			typeDD.setPosition( 100,2 );
			typeDD.addOption(Rendering.Uniform.BOOL,"BOOL");
			typeDD.addOption(Rendering.Uniform.INT,"INT");
			typeDD.addOption(Rendering.Uniform.FLOAT,"FLOAT");
			typeDD.addOption(Rendering.Uniform.VEC2F,"VEC2F");
			typeDD.addOption(Rendering.Uniform.VEC3F,"VEC3F");
			typeDD.addOption(Rendering.Uniform.VEC4F,"VEC4F");
			typeDD.addOption(Rendering.Uniform.VEC2I,"VEC2I");
			typeDD.addOption(Rendering.Uniform.VEC3I,"VEC3I");
			typeDD.addOption(Rendering.Uniform.VEC4I,"VEC4I");
			typeDD.addOption(Rendering.Uniform.VEC2B,"VEC2B");
			typeDD.addOption(Rendering.Uniform.VEC3B,"VEC3B");
			typeDD.addOption(Rendering.Uniform.VEC4B,"VEC4B");
			typeDD.addOption(Rendering.Uniform.MATRIX_2X2F,"MATRIX_2X2F");
			typeDD.addOption(Rendering.Uniform.MATRIX_3X3F,"MATRIX_3X3F");
			typeDD.addOption(Rendering.Uniform.MATRIX_4X4F,"MATRIX_4X4F");
			typeDD.setData(uniform.getType());
			typeDD.onDataChanged := this->apply;
			entry.add(typeDD);

			// data
			var dataTF=gui.createTextfield(150,15,toJSON(uniform.getData(),false));
			dataTF.onDataChanged := this->apply;
			dataTF.setPosition(180,2);
			entry.add(dataTF);

			uniformInputList+=[nameTF,typeDD,dataTF];

			var removeButton=gui.createButton(20,15,"-");
			entry.add(removeButton);
			removeButton.setPosition(350,2);
			removeButton.onClick = [nameTF,this] => fn(nameTF,tv){
				nameTF.setText("");
				tv.apply();
			};
		}
	};
	tv.apply := [uniformContainer,uniformInputList] => fn(uniformContainer,uniformInputList,...){
		out("Setting uniforms: \n");
		uniformContainer.removeUniforms();
		// add new uniforms
		foreach(uniformInputList as var entry){
			var name=entry[0].getData().trim();
			if(name=="")
				continue;
			var type=entry[1].getData();
			var data=parseJSON(entry[2].getData().trim());

			var u = new Rendering.Uniform(name,type,data);
//				out(entry.nameTF.getText().trim());
			out(">",u,"\n");
			uniformContainer.setUniform(u);
//			print_r(uniformContainer.getUniform(name).getData());
		}
		refresh();
		out("\n");
	};

	tv.refresh();

	entries += GUI.NEXT_ROW;
	
	entries += {
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Add uniform",
		GUI.TOOLTIP : "WARNING: Adding matrixes is buggy and may crash the program!",
		GUI.MENU_WIDTH : 250,
		GUI.MENU : [uniformContainer,tv] => fn(uniformContainer,treeView){
			// search for a shader state
			var shaderState;
			if(uniformContainer---|>MinSG.ShaderState){
				shaderState = uniformContainer;
			}else{
				var node = NodeEditor.getSelectedNode();
				while(node && !shaderState){
					var todo = node.getStates();
					while(!todo.empty()){
						var s = todo.popFront();
						if(s---|>MinSG.ShaderState){
							shaderState = s;
							break;
						}else if(s.isSet($getStates)){ // GroupState?
							todo.append(s.getStates());
						}
					}
					node = node.getParent();
				}
			}
			if(!shaderState)
				return [];	
		
			var entries = {
				GUI.TYPE : GUI.TYPE_TREE,
				GUI.OPTIONS : [],
				GUI.WIDTH : 250,
				GUI.HEIGHT : 200,							
			};
			foreach(shaderState.getShader().getActiveUniforms() as var uniform){
				// split uniform's name by '.' to identifiy the uniform struct-group 
				var s = uniform.getName();
				if(s.beginsWith("gl_")) //  create group for gl uniforms
					s="gl."+s;
				else if(s.beginsWith("sg_")) //  create group for sg uniforms
					s="sg."+s;
				var groupNames = s.split(".");
				var name = groupNames.popBack();
				
				var currentMap = entries;
				foreach(groupNames as var groupName){
					if(!currentMap[groupName]){
						currentMap[groupName] = {
							GUI.TYPE : GUI.TYPE_TREE_GROUP,
							GUI.OPTIONS : [groupName],
							GUI.FLAGS : GUI.COLLAPSED_ENTRY
						};
						currentMap[GUI.OPTIONS]+=currentMap[groupName];
					}
					currentMap = currentMap[groupName];
				}
				currentMap[GUI.OPTIONS] += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : name+" ("+uniform.getNumValues()+")",
					GUI.WIDTH : 180,
					GUI.ON_CLICK : (fn(uniformContainer,uniform,treeView){
						uniformContainer.setUniform(uniform);
						treeView.refresh();
					}).bindLastParams(uniformContainer,uniform,treeView)
		
				};
				
			}
			return [entries];
		}
	
	};


	return entries;
});


/*! ShaderState	*/
NodeEditor.registerConfigPanelProvider( MinSG.ShaderState, fn(MinSG.ShaderState state, panel){
	// -----------------------------------------------------------
	panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Shader preset",
		GUI.OPTIONS_PROVIDER : fn(){
			var entries = [""];
			foreach(PADrend.getSceneManager()._getSearchPaths() as var path){
				foreach(Util.getFilesInDir(path,[".shader"]) as var filename){
					entries += (new Util.FileName(filename)).getFile(); 
				}
			}
			return entries;
		},
		GUI.DATA_WRAPPER : state.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME,"")
	
	};
	panel++;
	// uniforms
	panel+="----";
	panel.nextRow(5);
	
	panel+={
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.LABEL : "Uniforms",
		GUI.COLLAPSED : false,
		GUI.CONTENTS : {
			GUI.TYPE : GUI.TYPE_COMPONENTS,
			GUI.PROVIDER : 'NodeEditor_UniformEditor',
			GUI.CONTEXT : state
		},
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_ABS , 10 ,5 ]
	};
	panel++;
	
		// TODO!!!!!!!!!!!!!!!!!!!!!!!!!!
		// attributes
});

// -------------

/*! ShaderUniformState	*/
NodeEditor.registerConfigPanelProvider( MinSG.ShaderUniformState, fn(MinSG.ShaderUniformState state, panel){
	panel+={
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.LABEL : "Uniforms",
		GUI.COLLAPSED : false,
		GUI.CONTENTS : {
			GUI.TYPE : GUI.TYPE_COMPONENTS,
			GUI.PROVIDER : 'NodeEditor_UniformEditor',
			GUI.CONTEXT : state
		},
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_CHILDREN_ABS , 10 ,5 ]
	};

});

// ----

/*! ShadowState	*/
NodeEditor.registerConfigPanelProvider( MinSG.ShadowState, fn(MinSG.ShadowState state, panel){
	panel += "*ShadowState:*";
	panel++;

	var dd = gui.createDropdown(300, 15);
	dd.state := state;
	dd.refresh := fn() {
		this.clear();
		var lightNodes = MinSG.collectLightNodes(PADrend.getRootNode());
		foreach(lightNodes as var light) {
			var option = this.addOption(light, NodeEditor.getString(light));
		}
		this.setData(this.state.getLight());
	};
	dd.onDataChanged = fn(data) {
		if(data) {
			this.state.setLight(data);
		}
	};
	panel.add(dd);

	dd.refresh();

	var button = gui.createButton(40, 15, "Select");
	button.setTooltip("Select the current light node.");
	button.dd := dd;
	button.onClick = fn() {
		var node = this.dd.getData();
		if(node) {
			GLOBALS.NodeEditor.selectNode(node);
		}
	};
	panel.add(button);

	panel++;

	button = gui.createButton(300, 15, "Refresh");
	button.dd := dd;
	button.onClick = fn() {
		this.dd.refresh();
	};
	panel.add(button);

	panel++;
});

// ----

/*! Texture	*/
NodeEditor.registerConfigPanelProvider(MinSG.TextureState, fn(MinSG.TextureState state, panel) {
	panel += "*Texture State:*";
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Texure unit:",
		GUI.RANGE			:	[0, 7],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	DataWrapper.createFromFunctions(state -> state.getTextureUnit, 
																state -> state.setTextureUnit),
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	var textureFile = DataWrapper.createFromValue("");
	if(state.hasTexture()) {
		textureFile(state.getTexture().getFileName().toString());
	}
	textureFile.onDataChanged += [state] => fn(MinSG.TextureState state, data) {
		if(state.hasTexture()) {
			state.getTexture().setFileName(new Util.FileName(data));
		}
	};

	var texture = state.getTexture();
	if(texture){
		panel += "*Texture info:*";
		panel++;
		panel += "File: "+ (texture.getFileName().toString().empty() ? "[embedded]" :  texture.getFileName().toString());
		panel++;
		panel += "Size: "+ texture.getWidth() + "*" +texture.getWidth() + "*"+texture.getNumLayers();
		panel++;
		panel += "HasMipmaps: "+ texture.getHasMipmaps() + " Linear min filtering:" +texture.getUseLinearMinFilter() + " Linear mag filter:"+texture.getUseLinearMagFilter();
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "(Re-) create mipmaps",
			GUI.ON_CLICK : [texture] => fn(texture){ texture.createMipmaps(renderingContext);}
//			GUI.ON_CLICK : texture -> texture.createMipmaps
		};
		panel += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Show",
			GUI.ON_CLICK : [texture] => Rendering.showDebugTexture,
			GUI.TOOLTIP : "Show the texture for 0.5 sek in the\n lower left corner of the screen."
		};
	}
	// store to file
	// show 
	// create mipmaps
	// auto create mipmaps
	// show / edit type 
	
	panel++;
//	panel += {// texture type
//		GUI.TYPE			:	GUI.TYPE_OPTION,
//		GUI.LABEL			:	"Texture file:",
//		GUI.DATA_WRAPPER	:	textureFile,
//		GUI.ENDINGS			:	[".bmp", ".jpg", ".jpeg", ".png", ".tif", ".tiff"],
//		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
//	};	
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_FILE,
		GUI.LABEL			:	"Texture file:",
		GUI.DATA_WRAPPER	:	textureFile,
		GUI.ENDINGS			:	[".bmp", ".jpg", ".jpeg", ".png", ".tif", ".tiff"],
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_BUTTON,
		GUI.LABEL			:	"Reload texture",
		GUI.ON_CLICK		:	[state, textureFile] => fn(MinSG.TextureState state,
														   DataWrapper textureFile) {
									var fileName = textureFile();
									if(!fileName.empty()) {
										var path = PADrend.getSceneManager().locateFile(fileName);
										out("Loading texture \"", fileName.toString(), "\" ("+path+")...");
										var texture = path ?  Rendering.createTextureFromFile(path) : void;
										if(texture) {
											texture.setFileName(fileName); // set original filename
											state.setTexture(texture);
											outln(" done (", texture, ").");
										} else {
											state.setTexture(void);
											outln(" failed.");
										}
									} else {
										outln("Removing texture.");
										state.setTexture(void);
									}
									
									//! \see RefreshableContainerTrait
									@(once) static  RefreshableContainerTrait = Std.require('LibGUIExt/Traits/RefreshableContainerTrait');
									RefreshableContainerTrait.refreshContainer( this );
								}
	};
	panel++;
});

// ----

/*! TransparencyRenderer	*/
NodeEditor.registerConfigPanelProvider( MinSG.TransparencyRenderer, fn(MinSG.TransparencyRenderer state, panel){
	panel+= "*Tansparency Renderer:*";
	panel++;

	var cb = gui.createCheckbox("Use premultiplied alpha", state.getUsePremultipliedAlpha());
	cb.setTooltip("If checked, a blending equation for premultiplied-alpha colors is used.");
    cb.state := state;
    cb.onDataChanged = fn(data) {
    	this.state.setUsePremultipliedAlpha(data);
    };
    panel.add(cb);
});
// ----

//! TreeVisualization
if(MinSG.isSet($TreeVisualization))
NodeEditor.registerConfigPanelProvider( MinSG.TreeVisualization, fn(MinSG.TreeVisualization state, panel){
	panel += "*Tree Visualization*";
	
	panel++;
	
	panel += {
		GUI.LABEL			:	"Draw depth",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.RANGE			:	[0, 64],
		GUI.RANGE_STEPS		:	64,
		GUI.ON_DATA_CHANGED	:	state -> state.setDrawDepth,
		GUI.DATA_PROVIDER	:	state -> state.getDrawDepth,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
	
	panel++;
	
	panel += {
		GUI.LABEL			:	"Show splitting planes",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.ON_DATA_CHANGED	:	state -> state.setShowSplittingPlanes,
		GUI.DATA_PROVIDER	:	state -> state.getShowSplittingPlanes,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
	
	panel++;
	
	panel += {
		GUI.LABEL			:	"Show bounding boxes",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.ON_DATA_CHANGED	:	state -> state.setShowBoundingBoxes,
		GUI.DATA_PROVIDER	:	state -> state.getShowBoundingBoxes,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
	
	panel++;
	
	panel += {
		GUI.LABEL			:	"Show lines",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.ON_DATA_CHANGED	:	state -> state.setShowLines,
		GUI.DATA_PROVIDER	:	state -> state.getShowLines,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
});

// ----

/*! TwinPartitionsRenderer	*/
if(MinSG.isSet($TwinPartitionsRenderer))
NodeEditor.registerConfigPanelProvider( MinSG.TwinPartitionsRenderer, fn(MinSG.TwinPartitionsRenderer state, panel){
	panel += "*Twin Partitions Renderer:*";
	panel++;
	panel += {
		GUI.LABEL			:	"Maximum runtime [k-triangles]",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.DATA_VALUE		:	state.getMaximumRuntime() / 1000,
		GUI.RANGE			:	[0.1, 5],
		GUI.RANGE_STEPS		:	400,
		GUI.RANGE_FN_BASE	:	10,
		GUI.ON_DATA_CHANGED	:	state -> fn(data) {
									this.setMaximumRuntime(data * 1000);
								},
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
	panel++;
	panel += {
		GUI.LABEL			:	"Display Textured Depth Meshes",
		GUI.TYPE			:	GUI.TYPE_BOOL,
		GUI.DATA_VALUE		:	state.getDrawTexturedDepthMeshes(),
		GUI.ON_DATA_CHANGED	:	state -> MinSG.TwinPartitionsRenderer.setDrawTexturedDepthMeshes,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
	panel++;
	panel += {
		GUI.LABEL			:	"Polygon Offset Factor",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.DATA_VALUE		:	state.getPolygonOffsetFactor(),
		GUI.RANGE			:	[0.5, 2.0],
		GUI.RANGE_STEPS		:	15,
		GUI.ON_DATA_CHANGED	:	state -> MinSG.TwinPartitionsRenderer.setPolygonOffsetFactor,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
	panel++;
	panel += {
		GUI.LABEL			:	"Polygon Offset Units",
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.DATA_VALUE		:	state.getPolygonOffsetUnits(),
		GUI.RANGE			:	[0.5, 10.0],
		GUI.RANGE_STEPS		:	19,
		GUI.ON_DATA_CHANGED	:	state -> MinSG.TwinPartitionsRenderer.setPolygonOffsetUnits,
		GUI.SIZE			:	[GUI.WIDTH_ABS, -30, 0]
	};
});

// -----------------------------------------------------------


// --------------------------------------------------------------------------
