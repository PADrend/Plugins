/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static objectTraitRegistry = new Map; // displayableName -> trait
static objectTraitGUIRegistry = new Map; // traitName -> guiProvider(obj)
static objectTraitInfos = new Map; // traitName -> { ... }

var registry = new Namespace;

registry.registerTrait := fn(trait,String displayableName=""){
	if(displayableName.empty())
		displayableName = trait.getName();
	objectTraitRegistry[displayableName] = trait;
};

registry.registerTraitConfigGUI := fn(trait, provider ){
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait); //! \see Traits.CallableTrait
	objectTraitGUIRegistry[trait.getName()] = provider;
};

registry.scanTraitsInFolder := fn(String folder){
	foreach(Util.getFilesInDir( folder, ".info", true ) as var f){
		try{
			var info = parseJSON( Util.loadFile( f ) );
			var moduleId = info['moduleId'];
			if(!moduleId){
				Runtime.warn("ObjectRegistry.scanTraitsInFolder: No 'moduleId' in "+f);
				continue;
			}
			objectTraitInfos[moduleId] = info;
			foreach( info.get('aliases',[]) as var alias){
				module._setModuleAlias( alias,moduleId );
//				outln("Setting alias: ",alias,"->",moduleId);
			}
			
		}catch(e){
			Runtime.warn( e );
		}
	}
//	print_r(objectTraitInfos);
};

registry.getTraits := 		fn(){	return objectTraitRegistry.clone();	};
registry.getTraitInfos := 	fn(){	return objectTraitInfos.clone();	};
registry.getGUIProvider :=	fn(String traitName){	return objectTraitGUIRegistry[traitName];	};
registry.getTrait :=		fn(String traitName){	return objectTraitRegistry[traitName];	};

return registry;
