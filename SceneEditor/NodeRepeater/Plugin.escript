/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:SceneEditor/NodeRepeator]
 **/

declareNamespace($NodeRepeater);

//! ---|> Plugin
NodeRepeater.plugin := new Plugin({
		Plugin.NAME : 'SceneEditor/NodeRepeater',
		Plugin.DESCRIPTION : 'repeating node(s)',
		Plugin.AUTHORS : "Mouns",
		Plugin.OWNER : "All",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.REQUIRES : ['NodeEditor'],
		Plugin.EXTENSION_POINTS : []
});

var plugin = NodeRepeater.plugin;

plugin.windowEnabled @(private) := new Std.DataWrapper(false);
plugin.window @(private):= void;
plugin.iterations := [];

plugin.init @(override) := fn(){
    for(var i=0;i<3;++i){
        this.iterations += new ExtObject({
                $count : new Std.DataWrapper(0),
                $x : new Std.DataWrapper(0),
                $y: new Std.DataWrapper(0),
                $z : new Std.DataWrapper(0),
        });
    }

	windowEnabled.onDataChanged += this->fn(value){
		if(value){
			if(!window)
				showWindow();
		}else{
			if(window){
				var w = window;
				window = void;
				w.close();
			}
		}
	};

	module.on('PADrend/gui',this->fn(gui){
		gui.register('NodeEditor_TreeToolsMenu._10_nodeRepeater_showWindow',{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Node Repeater",
			GUI.TOOLTIP : "Show node repeater editor's.\nIt enables you to repeate the selected node(s)"+
			"\nin different directions and iterations.",
			GUI.ON_CLICK : this->fn(){	windowEnabled(!windowEnabled());	},
		});

	});
	return true;
};

//GUI.
plugin.showWindow := fn(){
	window = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.FLAGS : GUI.ONE_TIME_WINDOW,
		GUI.LABEL : "Node Repeater",
        GUI.TOOLTIP : "This tool enables you to repeate the selected node(s)"+
			"\nin different directions and iterations.",
		GUI.ON_WINDOW_CLOSED : this->fn(){
			windowEnabled(false);
		}
	});

	var panel =gui.create({
		GUI.TYPE:	GUI.TYPE_PANEL,
		GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
		GUI.SIZE:	GUI.SIZE_MAXIMIZE
	});

    foreach(this.iterations as var iteration){
        foreach([["Count.:",iteration.count],["X:",iteration.x], ["Y:",iteration.y], ["Z:",iteration.z]]	as var arr){
            var comp=gui.create({
                GUI.TYPE : GUI.TYPE_NUMBER,
                GUI.WIDTH : 70,
                GUI.LABEL: arr[0],
                GUI.DATA_WRAPPER: arr[1],
            });
            panel+=comp;
            Traits.addTrait(comp,NodeRepeater.AcceptsDataSettingTrait,arr[1]);
            panel.nextColumn(6);
        }
        panel += GUI.NEXT_ROW;
    }
	panel += GUI.NEXT_ROW;
	panel += '----';
	panel += GUI.NEXT_ROW;
    panel.nextRow(6);
    var container =gui.create({
        GUI.TYPE:	GUI.TYPE_CONTAINER,
        GUI.LAYOUT : GUI.LAYOUT_TIGHT_FLOW,
        GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS,-140,10],
	});
    panel+={
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.WIDTH : 60,
        GUI.LABEL:"World Dim.",
        GUI.TOOLTIP: "To estimate the world dimension 'Dx, Dy, Dz' of the selected node(s)"+
        "\n-You can drag and drop the values in the entries field!",
        GUI.ON_CLICK :[container]=>this->fn(container){
            container.destroyContents();
            var bb = MinSG.combineNodesWorldBBs(NodeEditor.getSelectedNodes());
            var bbData = [["Dx=:", bb.getExtentX()], ["Dy= ", bb.getExtentY()], ["Dz= ",bb.getExtentZ()] ];
            foreach(bbData as var data){
                var comp= gui.create({
                    GUI.TYPE : GUI.TYPE_NUMBER,
                    GUI.WIDTH : 70,
                    GUI.LABEL : data[0],
                    GUI.DATA_VALUE: data[1],
                    GUI.FLAGS : GUI.LOCKED,
                    GUI.DRAGGING_ENABLED : true,
                    GUI.DRAGGING_MARKER : true,
                    GUI.TOOLTIP: "you can drag and drop it in the entries field!",
                    });
                    comp.onDrop := [data]=>fn(data,evt){
                        for(var c = (gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] )));c;c=c.getParentComponent()){
                            if(Traits.queryTrait(c,NodeRepeater.AcceptsDataSettingTrait)){
                                c.data(data[1]); //! \see AcceptsDataSettingTrait
                                return;
                            }
                        }
                    };
                container.nextColumn(4);
                container+=comp;
                container.nextColumn(6);
            }
        },
    };
    panel+=container;
    panel += GUI.NEXT_ROW;
    panel.nextRow(4);
    panel+={
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.WIDTH : 50,
        GUI.LABEL:"Create",
        GUI.ON_CLICK : [container]=>this->fn(container){
        	static Command = Std.module('LibUtilExt/Command');
            var nodes = NodeEditor.getSelectedNodes();
            PADrend.executeCommand({
                Command.DESCRIPTION : "Node Repeat",
                Command.EXECUTE : [nodes,container]=>this->fn(nodes,container){
                    var scene = PADrend.getCurrentScene();
                    foreach(nodes as var node){
                        NodeEditor.selectNode(node);
                        foreach(this.iterations as var iteration){
                            var selectedNodes = NodeEditor.getSelectedNodes();
                            if(iteration.count()==0)
                                break;
                            this.repeatNode(selectedNodes, iteration, scene);
                        }
                    }
                    foreach(this.iterations as var iteration){
                        iteration.count(0); iteration.x(0); iteration.y(0); iteration.z(0);
                    }
                    container.destroyContents();
                },

                Command.UNDO : [nodes]=>this->fn(nodes){
                    NodeEditor.unselectNodes(nodes);
                    var nodes_ = NodeEditor.getSelectedNodes();
                    foreach(nodes_ as var node){
                        MinSG.destroy(node);
                    }
                }

            });
        },
    };
    panel.nextColumn(30);
    panel+={
        GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
        GUI.WIDTH : 100,
        GUI.LABEL:"Reset all params.",
        GUI.TOOLTIP: "To reset all parameters",
        GUI.REQUEST_MESSAGE : "Really reset all parameters?",
        GUI.ON_CLICK :this->fn(){
            foreach(this.iterations as var iteration){
                iteration.count(0); iteration.x(0); iteration.y(0); iteration.z(0);
            }
        }
    };
	window += panel;
	Std.Traits.addTrait(window, Std.module('LibGUIExt/Traits/StorableRectTrait'), 
							Std.DataWrapper.createFromEntry(PADrend.configCache, "Node_Repeator.winRect", [200,100,240,100]));
};

plugin.repeatNode :=fn(Array nodes,ExtObject iteration,MinSG.GroupNode scene){
    var nodesToSelect = [];
    foreach(nodes as var node){
        nodesToSelect+=node;
        var worldTranslation = new Geometry.Vec3(iteration.x(),iteration.y(),iteration.z());
        for(var i =0; i<iteration.count();++i){
            var newNode = node.clone();
            scene+=newNode;
            newNode.setRelTransformation(node.getWorldTransformationMatrix());
            newNode.moveLocal(newNode.worldDirToLocalDir(worldTranslation*(i+1)));
            nodesToSelect+=newNode;
        }
    }
   NodeEditor.selectNodes(nodesToSelect);
};

NodeRepeater.AcceptsDataSettingTrait := new Traits.GenericTrait("NodeRepeator.AcceptsDataSettingTrait");
NodeRepeater.AcceptsDataSettingTrait.onInit += fn(GUI.Component c,DataWrapper data){
    c.data := data;
};

return plugin;
