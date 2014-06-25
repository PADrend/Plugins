/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 David Maicher
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/BehaviourConfig/Plugin.escript
 ** Module for the NodeEditor: Shows and modifies the states attached to a node
 **/



var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor/BehaviourConfig',
		Plugin.DESCRIPTION : 'Shows and modifies the behaviours attached to a node.',
		Plugin.VERSION : 0.2,
		Plugin.REQUIRES : ['NodeEditor/GUI'],
		Plugin.EXTENSION_POINTS : [
		
			/* [ext:NodeEditor_QueryAvailableBehaviours]
			 * Add behaviourss to the list of availabe behaviourss.
			 * @param   Map of available behaviours
			 *          name -> Behaviour | function which returns a Behaviour
			 * @result  void
			 */
			'NodeEditor_QueryAvailableBehaviours'
		]
});


plugin.init @(override) := fn() {

	{ // init members
		loadOnce(__DIR__+"/BehaviourPanels.escript");
		this.availableBehaviours := new Map();
		this.availableBehaviours['KeyFrameAnimationBehaviour'] = fn(MinSG.KeyFrameAnimationNode n){ return new MinSG.KeyFrameAnimationBehaviour(n); };

		/* Particle System */
		if(MinSG.isSet($ParticleSystemNode)){
			this.availableBehaviours['ParticlePointEmitter'] = fn(MinSG.ParticleSystemNode n){ return new MinSG.ParticlePointEmitter(n); };
			this.availableBehaviours['ParticleBoxEmitter'] = fn(MinSG.ParticleSystemNode n){ return new MinSG.ParticleBoxEmitter(n); };
			this.availableBehaviours['ParticleGravityAffector'] = fn(MinSG.ParticleSystemNode n){ return new MinSG.ParticleGravityAffector(n); };
			this.availableBehaviours['ParticleReflectionAffector'] = fn(MinSG.ParticleSystemNode n){ return new MinSG.ParticleReflectionAffector(n); };
			this.availableBehaviours['ParticleFadeOutAffector'] = fn(MinSG.ParticleSystemNode n){ return new MinSG.ParticleFadeOutAffector(n); };
			this.availableBehaviours['ParticleAnimator'] = fn(MinSG.ParticleSystemNode n){ return new MinSG.ParticleAnimator(n); };
		} // particle system

		if(MinSG.isSet($FollowPathBehaviour)){
			this.availableBehaviours['FollowPath'] = fn(MinSG.Node n){ return new MinSG.FollowPathBehaviour(void, n); };
		} // follow path

	}

	{ // register at extension points
		registerExtension('NodeEditor_QueryAvailableBehaviours',this->fn(Map registry){ registry.merge(this.availableBehaviours); });
	}

	
	// ----------------------------------------------------------------------------------------------
	
	

	NodeEditor.addConfigTreeEntryProvider(MinSG.Node,fn( node,entry ){

		var behaviours = PADrend.getSceneManager().getBehaviourManager().getBehavioursByNode(node);
		var b = gui.create({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ICON : "#BehaviourSmall",
			GUI.ICON_COLOR : behaviours.empty() ? NodeEditor.BEHAVIOUR_COLOR_PASSIVE : NodeEditor.BEHAVIOUR_COLOR,
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.WIDTH : 15,
			GUI.TOOLTIP : "Show or refresh behaviours",
			GUI.COLOR : NodeEditor.STATE_COLOR,
			GUI.ON_CLICK : [entry]=>fn(entry){
				entry.createSubentry(new NodeEditor.BehavioursConfigurator(entry.getObject()),'behaviours');
			}
		});
		entry.addOption(b);	

	});


	NodeEditor.getIcon += [MinSG.AbstractBehaviour,fn(node){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#BehaviourSmall",
			GUI.ICON_COLOR : NodeEditor.BEHAVIOUR_COLOR
		};
	}];

	NodeEditor.addConfigTreeEntryProvider(MinSG.AbstractBehaviour,fn( behaviour,entry ){
		entry.setColor( NodeEditor.BEHAVIOUR_COLOR );
////		entry.addOption({
////			GUI.TYPE : GUI.TYPE_BOOL,
////			GUI.LABEL : "",
////			GUI.WIDTH : 15,
////			GUI.TOOLTIP : "Is this Behaviour active?",
////			GUI.DATA_PROVIDER : (fn(behaviour){	return behaviour.isActive();	}).bindLastParams(behaviour),
////			GUI.ON_DATA_CHANGED : (fn(data,behaviour){	if(data) { behaviour.activate(); } else { behaviour.deactivate(); }	}).bindLastParams(behaviour)
////		});
	//	entry.addMenuProvider(fn(entry,menu){
	//		menu['20_selection'] = [ '----' ,
	//			"TODO: Select all containing nodes"
	//		];
	//		menu['30_behaviour'] = [ '----' ,
	//			"TODO: Destroy behaviour",
	//			"TODO: Add to all selected nodes",
	//			"TODO: remove from all selected nodes",
	//		];
	//	});
	});
	// ------
	NodeEditor.BehavioursConfigurator := new Type();
	NodeEditor.BehavioursConfigurator._constructor ::= fn(MinSG.Node node){
		this._node := node;
	};
	NodeEditor.BehavioursConfigurator.getNode ::= fn(){	return _node;	};
	NodeEditor.BehavioursConfigurator.getBehaviours ::= fn(){	return PADrend.getSceneManager().getBehaviourManager().getBehavioursByNode(_node);	};

	NodeEditor.getIcon += [NodeEditor.BehavioursConfigurator,fn(configurator){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#BehaviourSmall",
			GUI.ICON_COLOR : configurator.getBehaviours().empty() ? NodeEditor.BEHAVIOUR_COLOR_PASSIVE : NodeEditor.BEHAVIOUR_COLOR,
		};
	}];

	NodeEditor.addConfigTreeEntryProvider(NodeEditor.BehavioursConfigurator,fn( configurator,entry ){
		var node = configurator.getNode();
		entry.setColor( NodeEditor.BEHAVIOUR_COLOR );
	//
		entry.setLabel("Behaviours");
		entry.addOption({
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.ICON : "#NewSmall",
			GUI.ICON_COLOR : NodeEditor.BEHAVIOUR_COLOR,
			GUI.TOOLTIP : "Add new behaviour",
			GUI.FLAGS : GUI.FLAT_BUTTON,

			GUI.WIDTH : 16,
			GUI.MENU : [entry]=>fn(entry){
				var behaviours = new Map();
				executeExtensions('NodeEditor_QueryAvailableBehaviours',behaviours);

				var menu = [];
				foreach(behaviours as var name,var behaviourFactory){
					menu += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : name,
						GUI.ON_CLICK : [entry,behaviourFactory]=>fn(entry,behaviourFactory){
							var node = entry.getObject().getNode();
							var behaviour;
							if(behaviourFactory ---|> MinSG.AbstractBehaviour){
								behaviour = behaviourFactory;
							}else {
								behaviour = behaviourFactory(node);
							}
							PADrend.getSceneManager().getBehaviourManager().registerBehaviour(behaviour);						
							entry.rebuild();
							entry.configure(behaviour);
						}
					};
				}
				return menu;
						
			}
		});
		var behaviours = configurator.getBehaviours();
		foreach(behaviours as var behaviour){
			var behaviourEntry = entry.createSubentry(behaviour);
			
			behaviourEntry.addOption({
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.ICON : "#RemoveSmall",
				GUI.ICON_COLOR : GUI.BLACK,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.WIDTH : 15,
				GUI.REQUEST_MESSAGE : "Remove behaviour from node?",
				GUI.ON_CLICK : [entry,behaviour]=>fn(entry,behaviour){
					PADrend.getSceneManager().getBehaviourManager().removeBehaviour(behaviour);
					entry.rebuild();
					entry.configure(void);
				},
				GUI.TOOLTIP : "Remove this behaviour from the node."
			});
			
		}
	});

	// ----------------------------------------------------------------------------------------------
	return true;
};


return plugin;
// --------------------------------------------------------------------------
