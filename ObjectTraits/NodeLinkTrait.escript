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

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/NodeLinkTrait');

trait.onInit += fn(MinSG.GeometryNode node){
////////////	var attr = node.getNodeAttribute('LinkedNodes');
	
	node.__linkedNodes @(private) := [ ]; //  [Role,Query,Node]
	

	static store = fn(node,entries){
//////////		node.setNodeAttribute('LinkedNodes',toJSON(entries,false));
	};

	node.addLinkedNode := fn(String role,String query, node){
		foreach(this.__linkedNodes as var entry){
			if(entry[0]==role&&entry[1]==query){
				entry[2]=node;
				break;
			}
		}else{
			this.__linkedNodes += [role,query,node];
		}
		store(this,this.__linkedNodes);
	};
	node.accessLinkedNodes  := fn(){
		return this.__linkedNodes;
	};
	node.removeLinkedNode := fn(String role,String query){
		this.__linkedNodes.filter([role,query]=>fn(role,query, entry){return entry[0]!=role||entry[1]!=query; });
		store(this,this.__linkedNodes);
	};
	node.getLinkedNodes := fn(String role){
		var nodes = [];
		foreach(this.__linkedNodes as var entry)
			if(entry[0]==role)
				nodes+=entry[2];
		return nodes;
	};
	
	
//	node.updateQueries := fn(MinSG.SceneManager sm){
//		
//	};
	
};
trait.allowRemoval();


static TreeQuery = Std.require('LibMinSGExt/TreeQuery');
static queryRelNode = fn(MinSG.Node source,String query){
	return TreeQuery.execute(query,PADrend.getSceneManager(),[source]);
};
static getRelativeNodeQuery = fn(MinSG.Node source,MinSG.Node target){
	return TreeQuery.createRelativeNodeQuery(PADrend.getSceneManager(),source,target);
};

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
			var role = new Std.DataWrapper(linkEntry[0]);
			var query = new Std.DataWrapper(linkEntry[1]);
			var nodeFound = new Std.DataWrapper(true&&linkEntry[2]);
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.WIDTH : 60,
				GUI.DATA_WRAPPER : role
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.WIDTH : 90,
				GUI.DATA_WRAPPER : query
			};			
			entries += { // locked!
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.WIDTH : 15,
				GUI.FLAGS : GUI.LOCKED,
				GUI.LABEL : "Ok",
				GUI.DATA_WRAPPER : nodeFound
			};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.WIDTH : 20,
				GUI.LABEL : "Set",
				GUI.ON_CLICK : [node,linkEntry,role,query,nodeFound] => fn(node,linkEntry,role,query,nodeFound){
					node.removeLinkedNode(linkEntry[0],linkEntry[1]);
					var linkedNodeSet = queryRelNode(node,query());
					nodeFound( linkedNodeSet.count()==1 );
					node.addLinkedNode(role(),query(),linkedNodeSet.toArray()[0]);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.LABEL : "-",
				GUI.WIDTH : 20,
				GUI.ON_CLICK : [node,linkEntry,refreshCallback] => fn(node,linkEntry,refreshCallback){
					node.removeLinkedNode(linkEntry[0],linkEntry[1]);
					refreshCallback();
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
					outln("No target selected!");
					return;
				}
				var query = getRelativeNodeQuery(node,target);
				if(!query){
					outln("Can't create relative node query!");
					return;
				}
				
				node.addLinkedNode("link",query,target );
				refreshCallback();
			}
		};
		
		return entries;
	});
});

return trait;

