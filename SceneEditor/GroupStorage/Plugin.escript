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

static COLOR_PASSIVE = new Util.Color4f(0.5,0.5,0.5,1.0);
static COLOR_ACTIVE = new Util.Color4f(0.2,0.2,1.0,1.0);

plugin.registerGUIComponents := fn(){
	gui.registerComponentProvider('PADrend_ToolsToolbar.30_selectionStorage', fn(){
		var panel = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 25, 25],
			GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
		});
		panel += { GUI.TYPE : GUI.TYPE_NEXT_ROW,GUI.SPACING : 2 };
		for(var index = 1; index< 10; index++){

			var button = gui.create({
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : index,
				GUI.SIZE: [8,8],
				GUI.COLOR : COLOR_PASSIVE,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.FONT : GUI.FONT_ID_SYSTEM,
				GUI.ON_CLICK: [index] => fn(index){
					var selection = selectedNodesStorage.getStoredSelection(index);
					if(selection.empty()){
						var selectedNodes = NodeEditor.getSelectedNodes().clone();
						selectedNodesStorage.storeSelection(index, selectedNodes);
						PADrend.message("Storing selected nodes at #",index);
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
							GUI.LABEL : "[CTRL]+["+index+"] Update stored selection",
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
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Clear stored selection",
							GUI.ON_CLICK : [index] => fn(index){
								selectedNodesStorage.deleteStoredSlection(index);
								outln("GUI cleared current selection at #",index);
							}
						}

					];
				}
			});
			panel += button;
			if(index ==3 || index ==6) panel++;
			var updateButton = [index, button]=>fn(buttonId, button, index, selection){
				if(button.isDestroyed())
					return $REMOVE;
				if(buttonId == index){
					if( selection && !selection.empty()){
						button.setColor( COLOR_ACTIVE );
						var t = "["+index+"] Select/goTo stored nodes ("+selection.count()+"):";
						foreach(selection as var i,var n){
							if(i>10){
								t += "\n... ";
								break;
							}
							t += "\n"+NodeEditor.getNodeString(n);
						}
						button.setTooltip(t);
					}
					else{
						button.setColor( COLOR_PASSIVE );
						button.setTooltip( "[CTRL]+["+index+"] Update stored selection.");
						
					}
				}

			};
			selectedNodesStorage.onSelectionChanged += updateButton;
			updateButton( index,selectedNodesStorage.getStoredSelection(index) );
		};
		return [panel];
	});

};

return plugin;
