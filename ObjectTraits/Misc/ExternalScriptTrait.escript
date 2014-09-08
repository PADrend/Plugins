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

/*! Adds the following public members:
	
 - initExternalScript()   	reload the referenced Script
 - externalScriptFile 		DataWrapper filename of external script (may be relative to the scene)
							The script should return an array of callbacks:
							[
							fn(node){...} on init
							fn(node){...} optional; on removal
							fn(node){...return entries} optional; return array of gui entries.
	\code
	// example for an external script
	static state = new MinSG.MaterialState;
	state.setTempState(true);

	return [
	fn(node){
		node += state;
		outln("Hello!");
	},fn(node){
		node -= state;
		outln("Bye!");
	},fn(node){
		return ["FOO!"];
	}
	];
	\endcode
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


trait.attributes.initExternalScript ::= fn(){
	this.unloadExternalScript();
	var file = this.externalScriptFile();
	if( !file.empty()){
		var locator = new Util.FileLocator;
		var scene = PADrend.getCurrentScene();
		if( scene.isSet($filename) && scene.filename )
			locator.addSearchPath( IO.dirname( scene.filename ) );
		locator.addSearchPath( "." );
		var file2 = locator.locateFile( file );
		if(!file2){
			Runtime.warn("ExternalScriptTrait: Script not found '"+file+"'");
			return;
		}
		var initAndRemove = load(file2.getPath());
		initAndRemove[0](this);
		this._removeExternalScript := initAndRemove[1];
		this._externalScriptGUIProvider := initAndRemove[2];
	}
};
trait.attributes.unloadExternalScript ::= fn(){
	if( this.isSet($_removeExternalScript) && this._removeExternalScript){
		var remover = this._removeExternalScript;
		this._removeExternalScript = void;
		remover(this);
	}
};

trait.onInit += fn(MinSG.Node node){
	node.externalScriptFile := node.getNodeAttributeWrapper('externalScriptFile', "" );
	PADrend.planTask( 0, node -> node.initExternalScript );
};

trait.allowRemoval();

trait.onRemove += fn(node){
	node.unloadExternalScript();
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		var entries = [
			{
				GUI.TYPE : GUI.TYPE_FILE,
				GUI.LABEL : "Filename",
				GUI.ENDINGS : [".escript"],
				GUI.DATA_WRAPPER : node.externalScriptFile,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
			}
		];
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Init",
				GUI.ON_CLICK : [node,refreshCallback]=>fn(node,refreshCallback){
					node.initExternalScript();
					refreshCallback();
				}
			};
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += '----';
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		if(node.isSet($_externalScriptGUIProvider) && node._externalScriptGUIProvider){
			entries.append( node._externalScriptGUIProvider(node) );
		}
		return entries;
	});
});

return trait;

