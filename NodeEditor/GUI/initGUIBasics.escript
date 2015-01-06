/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/GUI/GUI_Basics.escript
 ** 
 **  - color definitions
 **  - NodeEditor.Wrappers.MultipleObjectsWrapper
 **/
 
module('./initGUIRegistries');
declareNamespace($NodeEditor);

// ----------------------------------------------------------------

//! @name Color definitions
// @{

NodeEditor.BEHAVIOUR_COLOR := new Util.Color4ub(172,0,17,255);
NodeEditor.BEHAVIOUR_COLOR_PASSIVE := new Util.Color4ub(140,128,128,255);

NodeEditor.NODE_COLOR := new Util.Color4ub(0,37,79,255);
NodeEditor.NODE_COLOR_PASSIVE := new Util.Color4ub(128,128,160,255);

NodeEditor.STATE_COLOR := new Util.Color4ub(0,121,21,255);
NodeEditor.STATE_COLOR_PASSIVE := new Util.Color4ub(128,160,128,255);
//	@}


// --------------------------------------------------------------------------------------------------------------

/*! @name Config Wrappers
	A config wrapper is a Type that is created to allow the configuration of the wrapped objects. These wrappers
	should not provide any active functionality; the configuration of the objects is done by the corresponding
	ConfigTreeEntries or ConfigPanels for these Types.
*/
//	@{
declareNamespace($NodeEditor,$Wrappers);


{	/*! MultipleObjectsWrapper 
		The MultipleObjectsWrapper can be used if an entry has too many children. Then these children can be 
		put into one or multiple MultipleObjectsWrappers. Then the entries for the objects are only created if 
		the button on the MultipleObjectsWrapper-TreeViewConfigEntry is activated.	*/

	NodeEditor.Wrappers.MultipleObjectsWrapper := new Type();
	var MultipleObjectsWrapper = NodeEditor.Wrappers.MultipleObjectsWrapper;
	//! (ctor)
	MultipleObjectsWrapper._constructor ::= fn(_label,Array _objects){
		this.label := _label;
		this.objects := _objects;
	};
	MultipleObjectsWrapper.getLabel ::= fn(){	return label;	};
	MultipleObjectsWrapper.getObjects ::= fn(){	return objects;	};

	NodeEditor.addConfigTreeEntryProvider(MultipleObjectsWrapper,fn(objWrapper,entry){
		entry.setLabel(objWrapper.getLabel());
		entry.addOption({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Open...",
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.ON_CLICK : [objWrapper,entry]=>fn(objWrapper,entry){
				foreach(objWrapper.getObjects() as var obj)
					entry.createSubentry(obj);
				this.setEnabled(false);
			}
		});
	});
}
//	@}


return true;
