/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/NodeConfig/Plugin.escript
 ** Module for the NodeEditor: Shows and modifies the parameters of a node
 **/

var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor/NodeConfig',
		Plugin.DESCRIPTION : 'Shows and modifies the parameters of a node.',
		Plugin.VERSION : 0.3,
		Plugin.REQUIRES : ['NodeEditor/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn() {

	Std.module( 'NodeEditor/NodeConfig/initNodePanels');

	
	{// init available nodes
		try{
			NodeEditor.nodeFactories.merge(load(__DIR__+"/AvailableNodes.escript"));
		}catch(e){
			Runtime.warn(e);
		}		
	}

	// -------------------------------------------------------------------------
	// NodeConfig

	NodeEditor.getIcon += [MinSG.Node,fn(node){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#NodeSmall",
			GUI.ICON_COLOR : NodeEditor.NODE_COLOR
		};
	}];

	NodeEditor.addConfigTreeEntryProvider(MinSG.Node,fn( node,entry ){
		
		//! \see AcceptDroppedStatesTrait
		@(once) static AcceptDroppedStatesTrait = Std.module('NodeEditor/GUI/AcceptDroppedStatesTrait');								
		Std.Traits.addTrait( entry._label, AcceptDroppedStatesTrait);
		entry._label.onStatesDropped += [node] => fn(node, source, Array states, actionType, evt){
			AcceptDroppedStatesTrait.transferDroppedStates( source, node, states, actionType); //! \see AcceptDroppedStatesTrait
			for(var c=this; c; c=c.getParentComponent()){
				if(c.isSet($rebuild)){
					c->c.rebuild();
					break;
				}
			}
		};
		
				
		entry.setColor( NodeEditor.NODE_COLOR );
		entry.addMenuProvider(fn(entry,menu){
			var node = entry.getObject();
			menu['00_entry'] = [{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Rebuild entry",
				GUI.ON_CLICK : entry->entry.rebuild
			}];
		
			// -------
			
			var selectionMenu = [ '----' ,{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Select this node",
				GUI.ON_CLICK : [entry.getObject()] => fn(node){	
					NodeEditor.selectNode(node);
					gui.closeAllMenus();
				}
			}];
			
			if(node.isInstance()){
				selectionMenu+={
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Select prototype '"+NodeEditor.getString(node.getPrototype())+"'",
					GUI.TOOLTIP : "Select the prototype from which this node is cloned from.",
					GUI.ON_CLICK : [node.getPrototype()] => fn(prototype){
						NodeEditor.selectNode(prototype);
						PADrend.message("Prototype selected: '"+prototype+"'");
					}
				};
			}else{
				selectionMenu+={
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Select instances of '"+NodeEditor.getString(node)+"'",
					GUI.TOOLTIP : "Select the instances of this node in the current scene.",
					GUI.ON_CLICK : [node] => fn(node){
						var instances = MinSG.collectInstances(PADrend.getCurrentScene(),node);
						NodeEditor.selectNodes(instances);
						PADrend.message("" + instances.count() + " instances selected.");
					}
				};
			}
			menu['20_selection'] = selectionMenu;
			
			// -------
			
			
			menu['90_misc'] = [ '----' ,

				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Fly to node",
					GUI.ON_CLICK : [node] => fn(node){
						var box = node.getWorldBB();
						var targetDir = (box.getCenter() - PADrend.getDolly().getWorldOrigin()).normalize();
						var target = new Geometry.SRT( box.getCenter() - targetDir * box.getExtentMax() * 1.0, -targetDir, PADrend.getWorldUpVector());
						PADrend.Navigation.flyTo(target);
					}
				}
			];
		});	
	});

	// -------------------------------------------------------------------------
	// Node attributes


	NodeEditor.Wrappers.AttributeWrapper := new Type();
	var AttributeWrapper = NodeEditor.Wrappers.AttributeWrapper;
	
	//! (ctor)
	AttributeWrapper._constructor ::= fn(_key,_value){	
		this.key := _key;	
		this.value := _value; 
	};
	AttributeWrapper.getKey ::= fn(){	return key;	};
	AttributeWrapper.getValue ::= fn(){	return value;	};

	NodeEditor.addConfigTreeEntryProvider(AttributeWrapper,fn( attrWrapper,entry ){
		var label = "" + attrWrapper.getKey() + " : ";
		var value = attrWrapper.getValue();
		if(value---|>Collection){
			label += value.getTypeName();
			foreach(value as var subKey,var subValue){
				entry.createSubentry(new (attrWrapper.getType())(subKey,subValue) );
			}
		}else{
			label += value.toDbgString();
		}
		entry.setLabel(label);
		
	});

	NodeEditor.addConfigTreeEntryProvider(MinSG.Node,fn( node,entry ){
		entry.addMenuProvider(fn(entry,menu){
			menu['90_showAttributes'] = [{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Show attributes",
				GUI.ON_CLICK : [entry] => fn(entry){
					entry.createSubentry( new NodeEditor.Wrappers.AttributeWrapper("Attributes",entry.getObject().getNodeAttributes()) , 'attributes' );
				}
			}];
		});
	});

	//----------------------------------------------
	// GroupNodeConfig

	NodeEditor.Wrappers.NodeChildrenWrapper := new Type();
	var NodeChildrenWrapper = NodeEditor.Wrappers.NodeChildrenWrapper;

	//! (ctor)
	NodeChildrenWrapper._constructor ::= fn(MinSG.Node node){	this._node := node;	};
	NodeChildrenWrapper.getNode ::= fn(){	return _node;	};

	NodeEditor.getIcon += [NodeChildrenWrapper,fn(nodeConfigurator){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#NodesSmall",
			GUI.ICON_COLOR : (nodeConfigurator.getNode().countChildren()>0) ? NodeEditor.NODE_COLOR : NodeEditor.NODE_COLOR_PASSIVE
		};
	}];

	NodeEditor.addConfigTreeEntryProvider(NodeChildrenWrapper,fn( configurator,entry ){
		var node = configurator.getNode();

		entry.setColor( NodeEditor.NODE_COLOR );
		
		entry.setLabel("Children");
		entry.addOption({
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.ICON : "#NewSmall",
			GUI.ICON_COLOR : NodeEditor.NODE_COLOR,
			GUI.WIDTH : 15,
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.TOOLTIP : "Create a new child",
			GUI.MENU : [entry] => fn(entry){
				var m = [];
				foreach(NodeEditor.nodeFactories as var name,var factory){
					m += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Create "+name,
						GUI.ON_CLICK :  [entry,name,factory] => fn(entry,name,factory){
							var node = entry.getObject().getNode();
							PADrend.message("Adding new "+name+" to "+NodeEditor.getString(node)+".");
							var n = factory();
							node.addChild(n);
							entry.rebuild();
						}
					};
				}
				return m;				
			}
		});
		var children = MinSG.getChildNodes(node);
		var limit = 25;
		if(children.count()<limit){
			foreach(children as var child){
				var childEntry = entry.createSubentry(child);
				childEntry.addOption({
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.ICON : "#DestroySmall",
					GUI.FLAGS : GUI.FLAT_BUTTON,
					GUI.ICON_COLOR : GUI.BLACK,			
					GUI.WIDTH : 15,
					GUI.REQUEST_MESSAGE : "Destroy this node?",
					GUI.ON_CLICK : [entry,child] => fn(entry,child){
						entry.getObject().getNode().removeChild(child);
						entry.rebuild();
					},
					GUI.TOOLTIP : "Destroy this child."
				});
			}
		}else{
			var i = 0;
			foreach(children.chunk(limit) as var part){
				entry.createSubentry(new NodeEditor.Wrappers.MultipleObjectsWrapper("ChildNodes "+i+"..."+ (i+part.count()-1),part));
				i+=part.count();
			}
		}
		
	});

	NodeEditor.getIcon += [MinSG.GroupNode,fn(node){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#GroupNodeSmall",
			GUI.ICON_COLOR : (node.countChildren()>0) ? NodeEditor.NODE_COLOR : NodeEditor.NODE_COLOR_PASSIVE
		};
	}];

	NodeEditor.addConfigTreeEntryProvider(MinSG.GroupNode,fn( obj,entry ){
		entry.addOption({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ICON : "#NodesSmall",
			GUI.ICON_COLOR : (obj.countChildren()>0) ? NodeEditor.NODE_COLOR: NodeEditor.NODE_COLOR_PASSIVE,
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.WIDTH : 15,
			GUI.TOOLTIP : "Show children",
			GUI.ON_CLICK : [entry] => fn(entry){
				entry.createSubentry(new NodeEditor.Wrappers.NodeChildrenWrapper(entry.getObject()),'children');
			}
		});	
	});
	// -------------------------------------------------------------------------
	return true;
};


return plugin;
// --------------------------------------------------------------------------
