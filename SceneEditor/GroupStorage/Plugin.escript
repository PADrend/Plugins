/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
var plugin = new Plugin({
	Plugin.NAME : 'SceneEditor/GroupStorage',
	Plugin.DESCRIPTION : "Store of nodes groups",
	Plugin.VERSION : 1.1,
	Plugin.REQUIRES : [],
	Plugin.AUTHORS : "Mouns",
	Plugin.OWNER : "Claudius, Mouns",
	Plugin.EXTENSION_POINTS : []
});

static selectedNodesStorage = Std.require('NodeEditor/SelectedNodesStorage');

plugin.init @(override) := fn() {
	module.on('PADrend/gui', registerGUIComponents );
	return true;
};

static registerGUIComponents = fn(gui){
	static Style = module('PADrend/GUI/Style');
	static COLOR_PASSIVE = Style.TOOLBAR_ICON_COLOR;
	static COLOR_ACTIVE = new Util.Color4f(0.0,0.0,0.6,1.0);
	static ACTIVE_BG_SHAPE = new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
											gui._createRectShape(new Util.Color4f(0.6,0.6,0.6,0.9),new Util.Color4ub(0.6,0.6,0.6,0.9),true));
	
	gui.register('PADrend_ToolsToolbar.10_storedSelections', [gui]=>fn(gui){
		var panel = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : [GUI.WIDTH_ABS | GUI.HEIGHT_ABS, 25, 25],
			GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
		});
		panel += { GUI.TYPE : GUI.TYPE_NEXT_ROW,GUI.SPACING : 2 };
		for(var index = 1; index< 10; index++){

			var button = gui.create({
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.PRESET : './toolIcon',
				GUI.LABEL : index,
				GUI.SIZE: [8,8],
//				GUI.COLOR : COLOR_PASSIVE,
//				GUI.FLAGS : GUI.FLAT_BUTTON,
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
						"*Selection #"+index+" ("+selectedNodesStorage.getStoredSelection(index).count()+ " Node/s)*",
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "Store selection #"+index,
							GUI.ON_CLICK : [index] => fn(index){
								var selectedNodes = NodeEditor.getSelectedNodes().clone();
								if(selectedNodes.size() > 0){
									selectedNodesStorage.storeSelection(index, selectedNodes);
									outln("GUI Storing current selection at #",index);
								}
								else
									outln("No selected node(s)");
							},
							GUI.TOOLTIP : "[CTRL]+["+index+"]"
						},
						(selectedNodesStorage.getStoredSelection(index).empty() ? [] : 
							[{
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.LABEL : "Clear",
								GUI.ON_CLICK : [index] => fn(index){
									selectedNodesStorage.deleteStoredSlection(index);
									outln("GUI cleared current selection at #",index);
								}
							}])...

					];
				}
			});
			panel += button;
			if(index ==3 || index ==6) panel++;
			var updateButton = [index, button]=>fn(buttonId, button, index, selection){
				if(button.isDestroyed())
					return $REMOVE;
				if(buttonId == index){
					button.clearLocalProperties();
					if( selection && !selection.empty()){

						foreach(module('PADrend/GUI/Style').TOOLBAR_ACTIVE_BUTTON_PROPERTIES as var p)
							button.addProperty(p);

//						button.setColor( COLOR_ACTIVE );
//						button.addLocalProperty(ACTIVE_BG_SHAPE);
//						button.setFlag(GUI.BACKGROUND,true);
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
						foreach(module('PADrend/GUI/Style').TOOLBAR_ACTIVE_BUTTON_PROPERTIES as var p)
							button.removeProperty(p);

//						button.setFlag(GUI.BACKGROUND,false);
//						button.setColor( COLOR_PASSIVE );
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
