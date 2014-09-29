/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 20143 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
var plugin = new Plugin({
	Plugin.NAME : 'SceneEditor/GroupStorage',
	Plugin.DESCRIPTION : "Store of nodes groups",
	Plugin.VERSION : 1.0,
	Plugin.REQUIRES : [],
	Plugin.AUTHORS : "Mouns",
	Plugin.OWNER : "Claudius, Mouns",
	Plugin.EXTENSION_POINTS : []
});

static selectedNodesStorage = Std.require('NodeEditor/SelectedNodesStorage');

plugin.init := fn() {
	registerExtension('PADrend_Init', this->registerGUIComponents );
	return true;
};

plugin.registerGUIComponents := fn(){
	// update , store new nodes
	// plugin menu
	gui.registerComponentProvider('PADrend_ToolsToolbar.transform3_GroupStorage', fn(){
		var panel = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 35, 35],
			GUI.LAYOUT : GUI.LAYOUT_FLOW
		});
		for(var index = 1; index< 10; index++){
			var label;
			if(selectedNodesStorage.getStoredSelection(index))
				label = index;
			else
				label = "";
			var button = gui.create({
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : label,
				GUI.SIZE: [10,10],
				GUI.FLAGS : GUI.AUTO_LAYOUT|GUI.BORDER,
				GUI.TOOLTIP: "Store selected node(s) in [1..9] tiles.",
				GUI.ON_CLICK: [index] => fn(index){
					var selection = selectedNodesStorage.getStoredSelection(index);
					if(!selection){
						var selectedNodes = NodeEditor.getSelectedNodes().clone();
						if(selectedNodes.size() > 0){
							selectedNodesStorage.storeSelection(index, selectedNodes);
							outln("GUI Storing current selection at #",index);
						}
						else
							outln("No selected node(s)");
					}else{
						if(selection == NodeEditor.getSelectedNodes()){
							NodeEditor.jumpToSelection();
						} else {
							if(PADrend.getEventContext().isShiftPressed())
								NodeEditor.addSelectedNodes(selection);
							else{
								NodeEditor.selectNodes(selection);
							}
						}
					}

				},
				GUI.CONTEXT_MENU_PROVIDER : [index] => fn(index){
                    return [
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Update",
							GUI.ON_CLICK : [index] => fn(index){
								var selectedNodes = NodeEditor.getSelectedNodes().clone();
								if(selectedNodes.size() > 0){
									selectedNodesStorage.storeSelection(index, selectedNodes);
									outln("GUI Storing current selection at #",index);
								}
								else
									outln("No selected node(s)");
								}
						},
						{
							GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
							GUI.LABEL : "Clear",
							GUI.REQUEST_MESSAGE : "Remove behaviour from node?",
							GUI.ON_CLICK : [index] => fn(index){
								selectedNodesStorage.deleteStoredSlection(index);
								outln("GUI cleared current selection at #",index);
							}
						}

                    ];
                }
			});
			panel += button;
			index ==3 | index ==6 ? panel++ : void ;
			selectedNodesStorage.onSelectionChanged += [index, button]=>fn(buttonId, button, index, selection){
				if(button.isDestroyed())
					return;
				if(buttonId == index){
					if(this.getStoredSelection(index))
						button.setText(""+index);
					else
						button.setText("");
				}

			};
		};
		return [panel];
	});

};

return plugin;
