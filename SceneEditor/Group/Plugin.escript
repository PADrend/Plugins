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
 **	[Plugin:SceneEditor/Group]
 **
 ** Graphical tools to group the selected Node(s).
 **/
declareNamespace($SceneEditor,$Group);
//! ---|> Plugin
SceneEditor.Group.plugin := new Plugin({
    Plugin.NAME : 'SceneEditor/Group',
    Plugin.DESCRIPTION : 'Group the selected Node(s)',
    Plugin.AUTHORS : "Mouns, Claudius",
    Plugin.OWNER : "All",
    Plugin.LICENSE : "Mozilla Public License, v. 2.0",
    Plugin.REQUIRES : ['NodeEditor','PADrend'],
    Plugin.EXTENSION_POINTS : []
});

var plugin = SceneEditor.Group.plugin;

plugin.counter  :=void;
plugin.listEntries := new Map();
plugin.refreshGroup  := new GUI.RefreshGroup();
plugin.clicked  :=false;
plugin.key  :=new Map();
//plugin.groupNr :=DataWrapper.createFromValue( -1 );
plugin.init @(override) := fn(){
    registerExtension('PADrend_Init',this->fn(){
        this.counter = 0;
		gui.registerComponentProvider('SceneEditor_ToolsConfigTabs.Groups',this->createUITab);

	});
    registerExtension('PADrend_KeyPressed',this->this.ex_KeyPressed);

	return true;
};

//! [ext:PADrend_KeyPressed]
plugin.ex_KeyPressed :=fn(evt){
    if(evt.key == Util.UI.KEY_7){
        if(this.key.containsKey(7))
            NodeEditor.selectNodes(this.key[7].nodes);
    }else if(evt.key == Util.UI.KEY_8){
        if(this.key.containsKey(8))
            NodeEditor.selectNodes(this.key[8].nodes);
    }else if(evt.key == Util.UI.KEY_9){
        if(this.key.containsKey(9))
            NodeEditor.selectNodes(this.key[9].nodes);
    }

};

//! Internal
/**
*To update the entries of the grouplist.
*/
plugin.updateGroupList :=fn(list){
    list.clear();
    foreach(listEntries as var id, var metaNode){
        this.createGroupList(list,id,metaNode.getNodeAttribute("Groupname"));
    }
};

//! Internal
/**
*To create the entries of the grouplist.
*/
plugin.createGroupList :=fn( list, id, name){

        var dataWrap =new ExtObject({
            $groupNr : DataWrapper.createFromValue( -1 ),
            $name : DataWrapper.createFromValue( name ),
        });

       var container = gui.create({
            GUI.TYPE: GUI.TYPE_CONTAINER,
            GUI.LAYOUT :GUI.LAYOUT_TIGHT_FLOW,
            });
        container+=gui.create({
            GUI.TYPE : GUI.TYPE_LABEL,
            GUI.LABEL: dataWrap.name(),
            GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS,-220,-10],
            GUI.DATA_REFRESH_GROUP : this.refreshGroup,
        });
        container+=gui.create({
            GUI.TYPE : GUI.TYPE_BUTTON,
            GUI.LABEL: "H",
            GUI.TOOLTIP : "Hide/Show the group's Node(s).",
            GUI.FLAGS:GUI.FLAT_BUTTON,
            GUI.WIDTH : 40,
            GUI.ON_CLICK: (fn(list,id,plugin){
                    plugin.clicked = !plugin.clicked;
                    plugin.showHideNodes(plugin.listEntries[id].nodes, plugin.clicked);
                    this.setSwitch(plugin.clicked);
                    if(plugin.clicked)
                        this.setText("S");
                    else
                        this.setText("H");
                }).bindLastParams(list,id,this),


        });
        container+=gui.create({
            GUI.TYPE : GUI.TYPE_BUTTON,
            GUI.FLAGS:GUI.FLAT_BUTTON,
            GUI.LABEL: "Sel.Gr.",
            GUI.WIDTH : 50,
            GUI.ON_CLICK: (fn(list,id,plugin){
                    NodeEditor.selectNode(plugin.listEntries[id]);
                }).bindLastParams(list,id,this),
        });
        container+=gui.create({
            GUI.TYPE : GUI.TYPE_SELECT,
            GUI.WIDTH : 30,
            GUI.TOOLTIP: "To save the selected group with key 7,8 or 9",
            GUI.DATA_WRAPPER: dataWrap.groupNr,
            GUI.OPTIONS: [[7,"7"],[8,"8"],[9,"9"]],
            GUI.ON_DATA_CHANGED : (fn(data,list,dataWrap,id,plugin){
                    plugin.key[dataWrap.groupNr()] = plugin.listEntries[id];
                }).bindLastParams(list,dataWrap,id,this),

            GUI.DATA_REFRESH_GROUP : this.refreshGroup,
        });
        container+=gui.create({
            GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
            GUI.LABEL: "X",
            GUI.TOOLTIP : "Delete the group's entry.",
            GUI.REQUEST_MESSAGE : "Really delete the group?",
            GUI.FLAGS:GUI.FLAT_BUTTON,
            GUI.WIDTH : 40,
            GUI.ON_CLICK: (fn(list,dataWrap,id,plugin){
                plugin.listEntries.unset(id);
                NodeEditor.selectNode(void);
                plugin.updateGroupList(list);
                plugin.key.unset(dataWrap.groupNr());
                var metaNodes = MinSG.getChildNodes(PADrend.getSceneManager().getRegisteredNode("Group"));
                foreach(metaNodes as var metaNode){
                    if(metaNode.getNodeAttribute("ID")==id){
                        MinSG.destroy(metaNode);
                        return;
                    }
                }
            }).bindLastParams(list,dataWrap,id,this)
        });
        //More Operations
        container+=gui.create({
            GUI.TYPE  : GUI.TYPE_MENU,
            GUI.LABEL : "Ops",
            GUI.WIDTH : 40,
            GUI.MENU :[
                {
                    GUI.TYPE : GUI.TYPE_BUTTON,
                    GUI.WIDTH : 24,
                    GUI.LABEL : "Update",
                    GUI.ON_CLICK: this->(fn(list,id){
                        var nodes =this.listEntries[id].nodes.clone();
                        foreach(NodeEditor.getSelectedNodes() as var node){
                            nodes+=node;
                        }
                        this.listEntries[id].nodes.clear();
                        this.listEntries[id].nodes = nodes;
                        this.listEntries[id].setBB(MinSG.combineNodesWorldBBs(this.listEntries[id].nodes));

                    }).bindLastParams(list,id)
                },
                {
                    GUI.TYPE : GUI.TYPE_BUTTON,
                    GUI.WIDTH : 40,
                    GUI.LABEL : "Rename",
                    GUI.ON_CLICK: this->(fn(list,dataWrap,id){
                        list.setData(id);
                        var p=gui.createPopupWindow( 300,100,"Enter new name of the group!");
                        p.addOption({
                            GUI.TYPE : GUI.TYPE_TEXT,
                            GUI.LABEL : "Name",
                            GUI.DATA_WRAPPER:dataWrap.name,
                        });
                        p.addAction("Ok", (fn(list,dataWrap,id,this){
                                (((list.getContents()[0]).getData()[0]).getContents()[0]).setText(dataWrap.name());
                                this.listEntries[id].setNodeAttribute("Groupname",dataWrap.name());
                            }).bindLastParams(list,dataWrap,id,this)
                        );
                        p.addAction("Cancel");
                        p.init();

                    }).bindLastParams(list,dataWrap,id)
                },
                {
                    GUI.TYPE : GUI.TYPE_BUTTON,
                    GUI.WIDTH : 24,
                    GUI.LABEL : "Hide",
                    GUI.TOOLTIP: "Hide the selected node(s).",
                    GUI.ON_CLICK: this->(fn(list,id){
                        this.clicked = !this.clicked;
                        this.showHideNodes(this.listEntries[id].nodes, this.clicked);
                    }).bindLastParams(list,id)
                },
                {
                    GUI.TYPE : GUI.TYPE_BUTTON,
                    GUI.WIDTH : 24,
                    GUI.LABEL : "Show",
                    GUI.TOOLTIP: "Show the hidden node(s) of this group.",
                    GUI.ON_CLICK: this->(fn(list,id){
                        this.clicked = !this.clicked;
                        this.showHideNodes(this.listEntries[id].nodes, this.clicked);
                    }).bindLastParams(list,id)
                },
            ],

        });
        list+=[id,container];

    this.refreshGroup.refresh();
    return dataWrap.name();
};

//! Internal

plugin.createUITab :=fn(){

    var panel =gui.create({
        GUI.TYPE:	GUI.TYPE_PANEL,
    });

    var list = gui.create({
        GUI.TYPE : GUI.TYPE_LIST,
        GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS , 10 ,10 ],
        GUI.ON_DATA_CHANGED : (fn(data,plugin){
            if(plugin.listEntries.containsKey(data[0])){
                if(PADrend.getEventContext().isShiftPressed())
                    NodeEditor.addSelectedNodes(plugin.listEntries[data[0]].nodes);
                else
                    NodeEditor.selectNodes(plugin.listEntries[data[0]].nodes);
            }
        }).bindLastParams(this),
        GUI.DATA_REFRESH_GROUP : this.refreshGroup,
    });

    panel +={
        GUI.TYPE : GUI.TYPE_BUTTON,
        GUI.LABEL : "Create",
        GUI.TOOLTIP : "Create new group for the selected Node(s).",
        GUI.ON_CLICK : (fn(list,plugin){
            if(!NodeEditor.getSelectedNodes().empty()){
                plugin.counter++;
                var name = plugin.createGroupList(list,plugin.counter,"Group "+plugin.counter);
                plugin.createGroup(plugin.counter, name);
            }else {outln("No selected Node(s)!");}
            }).bindLastParams(list,this)
    };
    panel++;
    panel+=list;
	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : panel,
		GUI.LABEL : "Groups",

	};

};

plugin.createGroup :=fn(id, groupName){
    var metaNode = new MinSG.GenericMetaNode();
    metaNode.setNodeAttribute("Groupname",groupName);
    metaNode.setNodeAttribute("ID",id);
    metaNode.nodes :=  NodeEditor.getSelectedNodes();
    metaNode.setBB(MinSG.combineNodesWorldBBs(metaNode.nodes));
    if(PADrend.getSceneManager().getRegisteredNode("Group")==void){
        var listNode = new MinSG.ListNode();
        PADrend.getSceneManager().registerNode("Group",listNode);
        PADrend.getCurrentScene().addChild(listNode);
    }
    PADrend.getSceneManager().getRegisteredNode("Group").addChild(metaNode);
    this.listEntries[id]=metaNode;

};

plugin.showHideNodes :=fn(Array selectedNodes, mode){
    foreach(selectedNodes as var node){
        if(mode)
            node.deactivate();
        else
            node.activate();
    }
};

return plugin;
