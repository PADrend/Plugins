/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
//! \todo save scene listener!!!!!!!!!!!!!!!!


static TreeQuery = Std.require('LibMinSGExt/TreeQuery');
static queryRelNodes = fn(MinSG.Node source,String query){
	return TreeQuery.execute(query,PADrend.getSceneManager(),[source]).toArray();
};
static createRelativeNodeQuery = fn(MinSG.Node source,MinSG.Node target){
	return TreeQuery.createRelativeNodeQuery(PADrend.getSceneManager(),source,target);
};

// ------------------------------


static LinkEntry = new Type;
LinkEntry.role := "";
LinkEntry.query := "";
LinkEntry.nodes @(init) := Array;
LinkEntry.parameters @(init) := Array;
LinkEntry.serializeToArray ::= fn(){
	return [this.role,this.query,this.parameters...];
};
LinkEntry.initFromArray ::= fn(Array arr){
	this.role = arr[0];
	this.query = arr[1];
	for(var i=2;i<arr.count();++i)
		this.parameters += arr[i];
};

static storeEntries = fn(MinSG.Node node,Array entries){
	var arr = [];
	foreach(entries as var e)
		arr += e.serializeToArray();
	node.setNodeAttribute('LinkedNodes',toJSON(arr,false));
};

// ------------------------------

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/NodeLinkTrait');

trait.onInit += fn(MinSG.Node node){
	
	var entries = [];
	var attr = node.findNodeAttribute('LinkedNodes'); // Role,Query,Params*
	if(attr){
		foreach(parseJSON(attr) as var arr){
			var e = new LinkEntry;
			e.initFromArray(arr);
			e.nodes = queryRelNodes(node,e.query);
			entries += e;
		}
	}
	
	node.__linkedNodes @(private) := entries;  

	node.addLinkedNodes := fn(String role,String query,[Array,void] nodes=void){
		if(!nodes)
			nodes = queryRelNodes(this,query);
		foreach(this.__linkedNodes as var entry){
			if(entry.role==role&&entry.query==query){
				if(!entry.nodes.empty())
					this.onNodesUnlinked(role,entry.nodes,entry.parameters);
				entry.nodes = nodes.clone();
				break;
			}
		}else{
			var entry = new LinkEntry;
			entry.role = role;
			entry.query = query;
			entry.nodes = nodes.clone();
			this.__linkedNodes += entry;
		}
		storeEntries(this,this.__linkedNodes);
		if(!nodes.empty())
			this.onNodesLinked(role,nodes,[]); //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! parameters
	};
	node.accessLinkedNodes  := fn(){
		return this.__linkedNodes;
	};
	node.removeLinkedNodes := fn(String role,String query){
		this.__linkedNodes.filter( [role,query]=>this->fn(role,query, entry){
			if(entry.role==role&&entry.query==query){
				this.onNodesUnlinked(role,entry.nodes,entry.parameters);
			}else{
				return true;
			}
		});
		storeEntries(this,this.__linkedNodes);
	};
	node.getNodeLinks := fn(String role){ 
		var links = [];
		foreach(this.__linkedNodes as var entry)
			if(entry.role==role)
				links += [entry.nodes,entry.parameters];
		return links;
	};
	node.getLinkedNodes := fn(String role){ 
		var linkedNodes = [];
		foreach(this.__linkedNodes as var entry)
			if(entry.role==role)
				linkedNodes.append(entry.nodes);
		return linkedNodes;
	};
	node.onNodesLinked := new MultiProcedure; // role, nodes, parameters
	node.onNodesUnlinked := new MultiProcedure;  // role, nodes, parameters
	
	node.availableLinkRoleNames := ["link"];

	
	
};
trait.allowRemoval();



Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		var entries = [ "Linked Nodes",
			{
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Remove trait",
				GUI.LABEL : "-",
				GUI.WIDTH : 20,
				GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
					if(Traits.queryTrait(node,trait))
						Traits.removeTrait(node,trait);
					refreshCallback();
				}
			},		
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
		];
		foreach(node.accessLinkedNodes() as var linkEntry){
			var role = new Std.DataWrapper(linkEntry.role);
			var query = new Std.DataWrapper(linkEntry.query);
			var nodesFound = new Std.DataWrapper(linkEntry.nodes.count());
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.WIDTH : 60,
				GUI.DATA_WRAPPER : role,
				GUI.OPTIONS : [role()].append(node.availableLinkRoleNames)
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.WIDTH : 90,
				GUI.DATA_WRAPPER : query
			};			
			entries += { // locked!
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.WIDTH : 20,
				GUI.DATA_WRAPPER : nodesFound,
				GUI.TOOLTIP : "Number of linked nodes"
			};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.WIDTH : 20,
				GUI.LABEL : "Set",
				GUI.ON_CLICK : [node,linkEntry,role,query,nodesFound] => fn(node,linkEntry,role,query,nodesFound){
					node.removeLinkedNodes(linkEntry.role,linkEntry.query);
					var linkedNodes = queryRelNodes(node,query());
					nodesFound( linkedNodes.count() );
					node.addLinkedNodes(role(),query(),linkedNodes);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : ">",
				GUI.WIDTH : 20,
				GUI.MENU_PROVIDER : [node,linkEntry,refreshCallback] => fn(node,linkEntry,refreshCallback){
					var entries = [];
					entries += {
						GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
						GUI.LABEL : "Remove Link",
						GUI.ON_CLICK : [node,linkEntry,refreshCallback] => fn(node,linkEntry,refreshCallback){
							node.removeLinkedNodes(linkEntry.role,linkEntry.query);
							gui.closeAllMenus();
							refreshCallback();
						}
					};
					entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Select",
						GUI.ON_CLICK : [linkEntry] => fn(linkEntry){
							NodeEditor.selectNodes(linkEntry.nodes);
						}
					};
					entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Update from selection",
						GUI.ON_CLICK : [node,linkEntry,refreshCallback] => fn(node,linkEntry,refreshCallback){
							var target = NodeEditor.getSelectedNode();
							var query = createRelativeNodeQuery(node,target);
							if(!query){
								PADrend.message("Can't create relative node query!");
								return;
							}
							node.removeLinkedNodes(linkEntry.role,linkEntry.query);
							node.addLinkedNodes(linkEntry.role,query,[target] );
							gui.closeAllMenus();
							refreshCallback();
						}
					};
					
					
					return entries;
				}
			};	

			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		}
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
//			GUI.WIDTH : 20,
			GUI.LABEL : "Add link",
			GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
				var target = NodeEditor.getSelectedNode();
				if(!target){
					target = self;
				}
				var query = createRelativeNodeQuery(node,target);
				if(!query){
					PADrend.message("Can't create relative node query!");
					return;
				}
				
				node.addLinkedNodes("link",query,[target] );
				refreshCallback();
			}
		};
		
		return entries;
	});
});

return trait;

