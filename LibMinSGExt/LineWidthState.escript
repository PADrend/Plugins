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
var LineWidthState = new Type(MinSG.ScriptedState); 

LineWidthState._printableName @(override) ::= $LineWidthState;

LineWidthState.lineWidth @(init) := fn() {
	return new Std.DataWrapper(1.0);
};

LineWidthState.doEnableState @(override) ::= fn(d*) {
	renderingContext.pushAndSetLine(lineWidth());
};

LineWidthState.doDisableState @(override) ::= fn(d*) {
	renderingContext.popLine();
};

NodeEditor.registerConfigPanelProvider(LineWidthState, fn(state, panel) {
	panel += "*LineWidthState*";
	panel++;

	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Line width",
		GUI.RANGE			:	[1, 128],
		GUI.RANGE_STEP_SIZE	:	1,
		GUI.DATA_WRAPPER	:	state.lineWidth,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
});
return LineWidthState;
