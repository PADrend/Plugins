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

/*! Define relative locations for a node.
	The following members are added to the given Node:
			
	- node.namedLocations 	DataWrapper( { name -> time,SRT|Vec3 } )
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


trait.onInit += fn(MinSG.Node node){
	node.animationSpeed :=  node.getNodeAttributeWrapper('animationSpeed', 1.0 );
	// name -> 'x y z' | 'xpos ypos ... xdir ydir ... xup ..'
	var serializedLocations =  node.getNodeAttributeWrapper('locations', "{}" );  

	var namedLocations = new DataWrapper;
	
	{ // init existing key frames
		var m = new Map; // name -> SRT | Vec3
		foreach( parseJSON(serializedLocations()) as var name, var locationString){
			var parts = locationString.split(' ');
			var location;
			if(parts.count()==3){
				location = new Geometry.Vec3( parts[0],parts[1],parts[2] );
			}else if(parts.count()==10){
				var pos =  new Geometry.Vec3( parts[0],parts[1],parts[2] );
				var dir =  new Geometry.Vec3( parts[3],parts[4],parts[5] );
				var up =  new Geometry.Vec3( parts[6],parts[7],parts[8] );
				location = new Geometry.SRT(pos,dir,up, parts[9]);
			}else{
				Runtime.warn("NamedLocationTrait: unknown location format:"+s);
			}
			m[""+name] = location;
		}
		namedLocations( m );
	}
	namedLocations.onDataChanged := [serializedLocations] => fn(serializedLocations, m){
		var m2 = new Map;
		foreach(m as var name,var location){
			var parts = [];
			if(location---|>Geometry.Vec3)
				parts.append(location.toArray());
			else if(location---|>Geometry.SRT){
				parts.append(location.getTranslation().toArray());
				parts.append(location.getDirVector().toArray());
				parts.append(location.getUpVector().toArray());
				parts += location.getScale();
			}
			m2[name] = parts.implode(" ");
		}
		serializedLocations( toJSON(m2,false) );
		outln(serializedLocations());
	};
	node.namedLocations := namedLocations;

};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		var entries = [];
		
		foreach(node.namedLocations() as var name, var location){
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_VALUE : name,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.ON_DATA_CHANGED : [refreshCallback,node.namedLocations,name] => fn(refreshCallback,namedLocations,name,newName){
					var m = namedLocations().clone();
					var location = m[name];
					m.unset( name );
					m[newName] = location;
					namedLocations(m);
					refreshCallback();
				}
			};
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.LABEL : "Update",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [node,node.namedLocations,name] => fn(node,namedLocations,name){
					var m = namedLocations().clone();
					m[name] = node.getRelTransformationSRT();
					namedLocations(m);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.WIDTH : 40,
				GUI.LABEL : "Apply",
				GUI.ON_CLICK : [node,node.namedLocations,name] => fn(node,namedLocations,name){
					node.setRelTransformation(namedLocations()[name]);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.LABEL : "Delete",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [refreshCallback,node.namedLocations,name] => fn(refreshCallback,namedLocations,name){
					var m = namedLocations().clone();
					m.unset(name);
					namedLocations(m);
					refreshCallback();
				}
			};
		}
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Store location",
			GUI.WIDTH : 120,
			GUI.ON_CLICK : [refreshCallback,node,node.namedLocations] => fn(refreshCallback,node,namedLocations){
				var m = namedLocations().clone();
				var i=m.count();
				while( m["#"+i] )
					++i;
				m["#"+i] = node.getRelTransformationSRT();
				namedLocations(m);
				refreshCallback();
			}
		};
		
		return entries;
	});
});

return trait;

