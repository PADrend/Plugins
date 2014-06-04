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

var registry = new Namespace;

registry.registerTrait := fn(trait,String displayableName=""){
	assert( trait---|> MinSG.PersistentNodeTrait );
	if(displayableName.empty())
		displayableName = trait.getName();
	objectTraitRegistry[displayableName] = trait;
};

registry.registerTraitConfigGUI := fn(trait, provider ){
	assert( trait---|> MinSG.PersistentNodeTrait );
	Std.Traits.requireTrait(provider, Std.Traits.CallableTrait); //! \see Traits.CallableTrait
	objectTraitGUIRegistry[trait.getName()] = provider;
};

registry.getTraits := 		fn(){	return objectTraitRegistry.clone();	};
registry.getGUIProvider :=	fn(String traitName){	return objectTraitGUIRegistry[traitName];	};
registry.getTrait :=		fn(String traitName){	return objectTraitRegistry[traitName];	};

return registry;
