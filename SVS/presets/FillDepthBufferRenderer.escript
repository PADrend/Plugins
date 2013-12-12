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
var FillDepthBufferRenderer = new Type(MinSG.ScriptedState);
FillDepthBufferRenderer.doEnableState := fn(node, params) {
	deactivate();
	frameContext.displayNode(node, params);
	activate();
	frameContext.getStatistics().endFrame();
	frameContext.getStatistics().beginFrame();
	renderingContext.clearColor(PADrend.getBGColor());
	renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LEQUAL);
	return MinSG.STATE_OK;
};
FillDepthBufferRenderer.doDisableState := fn(node, params) {
	renderingContext.popDepthBuffer();
};

var node = NodeEditor.getSelectedNode();
if(node) {
	node.addState(new FillDepthBufferRenderer());
}
