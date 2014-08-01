/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/StateConfig/Plugin.escript
 ** Module for the NodeEditor: Shows and modifies the states attached to a node
 **/

var plugin = new Plugin({
		Plugin.NAME : 'NodeEditor/StateConfig',
		Plugin.DESCRIPTION : 'Shows and modifies the states attached to a node.',
		Plugin.VERSION : 0.2,
		Plugin.REQUIRES : ['NodeEditor/GUI'],
		Plugin.EXTENSION_POINTS : [	
					
			/* [ext:NodeEditor_QueryAvailableStates]
			 * Add states to the list of availabe states.
			 * @param   Map of available states (e.g. rendering states)
			 *          name -> State | function which returns a State
			 * @result  void
			 */
			'NodeEditor_QueryAvailableStates'
		
		]
});


plugin.init @(override) := fn() {

	{ // init members
		loadOnce(__DIR__+"/StatePanels.escript");
	}

	// register extensions
	Util.registerExtension('NodeEditor_QueryAvailableStates',fn(a) {
		@(once) static availableStates = load(__DIR__+"/AvailableStates.escript"); // init available states (for "new"-button)
		a.merge(availableStates);
	});
	Util.registerExtension('PADrend_Init',this->registerMenus);


	//-----------------------------------------------------------------------------------------------------

	// add icons for some of the known States
	foreach( {	MinSG.State : "#StateSmall" ,

				MinSG.BlendingState : "#BlendingStateSmall",
				MinSG.CHCppRenderer : "#RenderingStateSmall",
				MinSG.GroupState : "#StatesSmall",
				MinSG.HOMRenderer : "#RenderingStateSmall",
				MinSG.LightingState : "#LightingStateSmall",
				MinSG.MaterialState : "#MaterialStateSmall",
				MinSG.OccludeeRenderer : "#RenderingStateSmall",
				MinSG.OccRenderer : "#RenderingStateSmall",
				MinSG.ProjSizeFilterState : "#RenderingStateSmall", 
				MinSG.RandomColorRenderer : "#RenderingStateSmall",
				MinSG.ShaderState : "#ShaderStateSmall",
				MinSG.StrangeExampleRenderer : "#RenderingStateSmall",
				MinSG.TextureState : "#TextureStateSmall",
				MinSG.TransparencyRenderer : "#RenderingStateSmall",
				MinSG.ShaderUniformState : "#UniformStateSmall"
			} as var type, var icon){
		
		NodeEditor.getIcon += [type, [icon] => fn(icon,obj){
			return {
				GUI.TYPE : GUI.TYPE_ICON,
				GUI.ICON : icon,
				GUI.ICON_COLOR : NodeEditor.STATE_COLOR
			};
		}];
	}
	
	
	
	//-----------------------------------------------------------------------------------------------------
	// State
	
	// Config tree entry for MinSG.State
	NodeEditor.addConfigTreeEntryProvider(MinSG.State,fn( state,entry ){
		{	// dragging
			var component = gui.create({
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.WIDTH : 15,
				GUI.HEIGHT : 15,
//				GUI.FLAGS : GUI.BORDER,
				GUI.DRAGGING_ENABLED : true,
				GUI.DRAGGING_MARKER : true,
				GUI.DRAGGING_CONNECTOR : true,
				GUI.TOOLTIP : "Drag to assign state to node. "
			});
			entry.getBaseContainer() += component;
			
			static getDroppingComponent = fn( x,y ){
				//! \see AcceptDroppedStatesTrait
				@(once) static AcceptDroppedStatesTrait = Std.require('NodeEditor/GUI/AcceptDroppedStatesTrait');
				for( var c = gui.getComponentAtPos(new Geometry.Vec2(x,y)); c; c=c.getParentComponent()){
					if(Traits.queryTrait(c,AcceptDroppedStatesTrait) )
						return c;
				}
				return void;
			};
			
			component.onDrag += fn(evt){
				this.getDraggingMarker().setEnabled(false);			//! \see GUI.DraggingMarkerTrait
				this.getDraggingConnector().setEnabled(false);		//! \see GUI.DraggingConnectorTrait

				var droppingComponent = getDroppingComponent(evt.x,evt.y);
		
				//! \see GUI.DraggingMarkerTrait
				this.getDraggingMarker().destroyContents();

				this.getDraggingConnector().clearProperties();
				
				if(droppingComponent){
					this.getDraggingMarker() += "->";
					this.getDraggingConnector().addProperty(
						new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
							gui._createSmoothConnectorShape( GUI.GREEN ,2)));
				}else if(!gui.getComponentAtPos(new Geometry.Vec2(evt.x,evt.y)).getParentComponent()) { // screen ?
					this.getDraggingConnector().addProperty(
						new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
							gui._createSmoothConnectorShape( new Util.Color4ub(0,0,255,255) ,2)));
				}else{
					this.getDraggingConnector().addProperty(
						new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
							gui._createSmoothConnectorShape( new Util.Color4ub(200,200,200,255) ,1)));
				}

				
				this.getDraggingMarker().setEnabled(true);			//! \see GUI.DraggingMarkerTrait
				this.getDraggingConnector().setEnabled(true);		//! \see GUI.DraggingConnectorTrait
				return false;
			};
			
			component.onDrop += [entry,state] => fn(entry,state,evt){
				// find the state container by traversing the entry tree
				var stateSource;
				for( var c = entry.getParentComponent(); c; c=c.getParentComponent() ){
					if(c.isSet($getObject) && c.getObject().isSet($getStates)){
						stateSource = c.getObject();
						break;
					}
				}
				var droppingComponent = getDroppingComponent(evt.x,evt.y);
				if(droppingComponent){
					droppingComponent.onStatesDropped(stateSource,[state], droppingComponent.defaultStateDropActions,evt ); 				//! \see AcceptDroppedStatesTrait
				}else  if(!gui.getComponentAtPos(new Geometry.Vec2(evt.x,evt.y)).getParentComponent()) { // screen ?
					var node = Util.requirePlugin('PADrend/Picking').pickNode( [evt.x,evt.y] );
					if(node){
						@(once) static AcceptDroppedStatesTrait = Std.require('NodeEditor/GUI/AcceptDroppedStatesTrait');					//! \see AcceptDroppedStatesTrait
						AcceptDroppedStatesTrait.transferDroppedStates( stateSource, node, [state] );
					}
				}
			};
		}
		
		entry.setColor( NodeEditor.STATE_COLOR );
		entry.addOption({
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "",
			GUI.WIDTH : 15,
			GUI.TOOLTIP : "Is this State active?",
			GUI.DATA_PROVIDER : [state] => fn(state){	return state.isActive();	},
			GUI.ON_DATA_CHANGED : [state] => fn(state,data){	if(data) { state.activate(); } else { state.deactivate(); }	}
		});
		entry.addMenuProvider(fn(entry,menu){
			var name = NodeEditor.getString(entry.getObject());
			menu['20_selection'] = [ '----' ,
				 {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Select nodes with this state",
					GUI.ON_CLICK : [entry.getObject()] => fn(state){	
						var nodes = MinSG.collectNodesWithState(PADrend.getCurrentScene(),state);
						NodeEditor.selectNodes(nodes);
						gui.closeAllMenus();
						PADrend.message("" + nodes.count() + " nodes selected.");
					},
					GUI.TOOLTIP : "Select all nodes in the current scene that\n use "+name+".",
				}
			];
			menu['30_state'] = [ '----' ,
			{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Add to all selected nodes",
					GUI.ON_CLICK : [entry.getObject()] => fn(state){
						var nodes = NodeEditor.getSelectedNodes();
						var counter = 0;
						foreach(nodes as var node){
							if(!node.getStates().contains(state)){
								++counter;
								node.addState(state);
							}
						}
						gui.closeAllMenus();
						PADrend.message("State added to "+counter+" nodes.");
					},
					GUI.TOOLTIP : "Add the state "+name+" \n to all selected nodes which do not already have the state.",
				},
				{
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.LABEL : "Remove from all selected nodes",
					GUI.ON_CLICK : [entry.getObject()] => fn(state){
						var nodes = NodeEditor.getSelectedNodes();
						var counter = 0;
						foreach(nodes as var node){
							if(node.getStates().contains(state)){
								++counter;
								node.removeState(state);
							}
						}
						gui.closeAllMenus();
						PADrend.message("State removed from "+counter+" nodes.");
					},
					GUI.TOOLTIP : "Remove the state "+name+"\n from all selected nodes.",
					GUI.REQUEST_MESSAGE : "??? Remove the state "+name+"\n from all selected nodes ???",
				},
				{
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.LABEL : "Remove from all nodes in the scene",
					GUI.ON_CLICK : [entry.getObject()] => fn(state){
						var nodes = MinSG.collectNodesWithState(PADrend.getCurrentScene(),state);
						var counter = nodes.count();
						foreach(nodes as var node){
							node.removeState(state);
						}
						gui.closeAllMenus();
						PADrend.message("State removed from "+counter+" nodes.");
					},
					GUI.TOOLTIP : "Remove the state "+name+"\n from all nodes in the scene.",
					GUI.REQUEST_MESSAGE : "??? Remove the state "+name+"\n from all nodes in the scene ???"
				}
			];
		});
	});
	
	// Add a 'States' button to each Node entry. The buttons opens an entry for a StatesContainerWrapper.
	// If the entry is active, the StatesContainerWrapper is created immediatly.
	NodeEditor.addConfigTreeEntryProvider(MinSG.Node,fn( obj,entry ){
		var b = gui.create({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ICON : "#StatesSmall",
			GUI.ICON_COLOR : obj.hasStates() ? NodeEditor.STATE_COLOR : NodeEditor.STATE_COLOR_PASSIVE,
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.WIDTH : 15,
			GUI.TOOLTIP : "Show or refresh states",
			GUI.COLOR : NodeEditor.STATE_COLOR,
			GUI.ON_CLICK : [entry]=>fn(entry){
				entry.createSubentry(new NodeEditor.Wrappers.StatesContainerWrapper(entry.getObject()),'states');
			}
		});
		entry.addOption(b);	
		if(entry.isActiveEntry)
			b.onClick();
	});

	// -------------------------------
	// GroupState
	NodeEditor.addConfigTreeEntryProvider(MinSG.GroupState,fn( obj,entry ){
		//! \see AcceptDroppedStatesTrait
		@(once) static AcceptDroppedStatesTrait = Std.require('NodeEditor/GUI/AcceptDroppedStatesTrait');								
		Traits.addTrait( entry._label, AcceptDroppedStatesTrait);
		entry._label.onStatesDropped += [obj] => fn(obj, source, Array states, actionType, evt){
			AcceptDroppedStatesTrait.transferDroppedStates( source, obj, states, actionType); //! \see AcceptDroppedStatesTrait
			for(var c=this; c; c=c.getParentComponent()){
				if(c.isSet($rebuild)){
					c->c.rebuild();
					break;
				}
			}
		};

	
		entry.addOption({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ICON : "#StatesSmall",
			GUI.ICON_COLOR : obj.hasStates() ? NodeEditor.STATE_COLOR : NodeEditor.STATE_COLOR_PASSIVE,
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.WIDTH : 15,
			GUI.TOOLTIP : "Show or refresh states",
			GUI.COLOR : NodeEditor.STATE_COLOR,
			GUI.ON_CLICK : [entry] => fn(entry){
				entry.createSubentry(new NodeEditor.Wrappers.StatesContainerWrapper(entry.getObject()),'states');
			}
		});	
	});

	// -------------------------------
	// Configuration wrapper for the collection of a node's (or groupState's) states 
	NodeEditor.Wrappers.StatesContainerWrapper := new Type();
	var StatesContainerWrapper = NodeEditor.Wrappers.StatesContainerWrapper;
	
	StatesContainerWrapper._constructor ::= fn([MinSG.Node,MinSG.GroupState] statesContainer){
		this._statesContainer := statesContainer;
	};
	StatesContainerWrapper.getStatesContainer ::= fn(){	return _statesContainer;	};

	NodeEditor.getIcon += [StatesContainerWrapper,fn(stateConfigurator){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#StatesSmall",
			GUI.ICON_COLOR : stateConfigurator.getStatesContainer().hasStates() ? NodeEditor.STATE_COLOR : NodeEditor.STATE_COLOR_PASSIVE
		};
	}];

	NodeEditor.addConfigTreeEntryProvider(StatesContainerWrapper,fn( wrapper,entry ){
		
		
		
		var statesContainer = wrapper.getStatesContainer();
		entry.setColor( NodeEditor.STATE_COLOR );

		entry.setLabel("States");
		entry.addOption({
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.ICON : "#NewSmall",
			GUI.ICON_COLOR : NodeEditor.STATE_COLOR,
			GUI.TOOLTIP : "Add new state",
			GUI.FLAGS : GUI.FLAT_BUTTON,

			GUI.WIDTH : 16,
			GUI.MENU_WIDTH : 200,
			GUI.MENU : [entry] => fn(entry){
				var states = new Map;
				executeExtensions('NodeEditor_QueryAvailableStates',states);

				var menu = [];
				foreach(states as var name,var stateFactory){
					menu += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : name,
						GUI.ON_CLICK : [entry,stateFactory] => fn(entry,stateFactory){
							var statesContainer = entry.getObject().getStatesContainer();
							var state = (stateFactory ---|> MinSG.State) ? stateFactory : stateFactory();
							statesContainer.addState(state);
							entry.rebuild();
							entry.configure(state);
						}
					};
				}
				return menu;
						
			}
		});
		entry.addOption({
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.ICON : "#AddSmall",
			GUI.ICON_COLOR : NodeEditor.STATE_COLOR,
			GUI.TOOLTIP : "Add existing state",
			GUI.WIDTH : 16,
			GUI.FLAGS : GUI.FLAT_BUTTON,

			GUI.MENU : [entry] => fn(entry){
				var stateNames = PADrend.getSceneManager().getNamesOfRegisteredStates();
				stateNames.sort();
				var list = gui.create({
					GUI.TYPE : GUI.TYPE_LIST,
					GUI.WIDTH : 190,
					GUI.HEIGHT : 200
				});
				foreach(stateNames as var name){
					list += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : name,
	//					GUI.TEXT_ALIGN_LEFT|GUI.TEXT_ALIGN_MIDDLE
						GUI.ON_CLICK : [entry,name] => fn(entry,name){
							var statesContainer = entry.getObject().getStatesContainer();
							var state = PADrend.getSceneManager().getRegisteredState(name);
							statesContainer.addState(state);
							entry.rebuild();
							entry.configure(state);
						}
					};
				}
				return [list];
						
			}
		});
		

		var switchStates = fn(entry,index1,index2){
			var statesContainer = entry.getObject().getStatesContainer();
			var states = statesContainer.getStates();
			statesContainer.removeStates();
			var t = states[index1];
			states[index1] = states[index2];
			states[index2] = t;
			foreach(states as var state)
				statesContainer.addState(state);
			entry.rebuild();
		};
		
		var typeName = statesContainer.getTypeName();
		var states = statesContainer.getStates();
		foreach(states as var index,var state){
			var stateEntry = entry.createSubentry(state);
			if(index>0){
				stateEntry.addOption({
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.ICON : "#UpSmall",
					GUI.ICON_COLOR : GUI.BLACK,
					GUI.FLAGS : GUI.FLAT_BUTTON,
					GUI.WIDTH : 15,
					GUI.ON_CLICK : [entry,index,index-1] => switchStates,
					GUI.TOOLTIP : "Move this state up in the state list."
				});
			}else{
				stateEntry.addOption({	GUI.TYPE:GUI.TYPE_CONTAINER , GUI.WIDTH : 15 }); // add placeholder
			}
			if(index<states.count()-1){
				stateEntry.addOption({
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.ICON : "#DownSmall",
					GUI.ICON_COLOR : GUI.BLACK,
					GUI.FLAGS : GUI.FLAT_BUTTON,
					GUI.WIDTH : 15,
					GUI.ON_CLICK : [entry,index,index+1] => switchStates,
					GUI.TOOLTIP : "Move this state down in the state list."
				});
			}else{
				stateEntry.addOption({	GUI.TYPE:GUI.TYPE_CONTAINER , GUI.WIDTH : 15 }); // add placeholder
			}
			stateEntry.addOption({
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.ICON : "#RemoveSmall",
				GUI.ICON_COLOR : GUI.BLACK,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.WIDTH : 15,
				GUI.REQUEST_MESSAGE : "?? Remove this state from this "+typeName+" ???",
				GUI.ON_CLICK : [entry,state] => fn(entry,state){
					entry.getObject().getStatesContainer().removeState(state);
					entry.rebuild();
					entry.configure(void);
				},
				GUI.TOOLTIP : "Remove this state from this "+typeName+"."
			});
		}
	});	
	
	// -------------------------------

    return true;
};


plugin.registerMenus := fn() {	
	
	gui.registerComponentProvider('PADrend_SceneToolMenu.states',fn(){
		var nodes = NodeEditor.getSelectedNodes();
		if(nodes.count()!=1)
			return [];
		return [
			{
				GUI.LABEL : "States",
				GUI.MENU_WIDTH : 100,
				GUI.MENU : 'NodeEditor_StatesMenu',
				GUI.MENU_CONTEXT : nodes.front(),
			}
		];
	});

	gui.registerComponentProvider('NodeEditor_StatesMenu',fn(MinSG.Node node){
							
		var entries = [];
		foreach(node.getStates() as var state){
			var c = gui.createContainer(120,15);
			var name = NodeEditor.getString(state);
			c.setTooltip(name);
			c+=gui.createLabel(80,15,name.substr(0,10)+"...");

			var b = gui.createButton(20,15,"X");
			b.setPosition(80,0);
			c+=b;
			b.node := node;
			b.state := state;
			b.onClick = fn(){
				node.removeState(state);
				NodeEditor.refreshSelectedNodes(); // refresh the gui
				gui.closeAllMenus();
			};

			b = gui.createButton(20,15,">>");
			b.setPosition(100,0);
			c+=b;
			b.state := state;
			b.plugin := this;
			b.onClick = fn(){
				var menu = gui.createMenu();
				var container = gui.createPanel(350,200,GUI.AUTO_LAYOUT);
				container += NodeEditor.createConfigPanel(state);
				menu+=container;
				menu.open(getAbsPosition()+new Geometry.Vec2(-350,0));
			};
			entries+=c;
		}
		entries+="----";
		var button = gui.createButton(39,16,"New");
		button.setButtonShape(GUI.BUTTON_SHAPE_BOTTOM_LEFT);
		button.setTooltip("Add a new state to the current node.");
		button.onClick = fn(){
			var states = new Map();
			executeExtensions('NodeEditor_QueryAvailableStates',states);
			var menu = gui.createMenu();
			foreach(states as var name,var stateExpr){
					var button = gui.createButton(150,15,name,GUI.FLAT_BUTTON);
					button.setTextStyle(GUI.TEXT_ALIGN_LEFT|GUI.TEXT_ALIGN_MIDDLE);
					button.stateExpr := stateExpr;
					button.menu := menu;
					button.onClick = fn(){
						menu.setEnabled(false);
						var state;
						if(stateExpr ---|> MinSG.State){
							state = stateExpr;
						}else {
							try{
								state = stateExpr();
							}catch(e){
								out(e);
								return;
							}
						}
						foreach(NodeEditor.getSelectedNodes() as var node){
							node.addState(state);
						}
						NodeEditor.refreshSelectedNodes(); // refresh the gui
					};
					menu.add(button);
			};
			menu.open(getAbsPosition()+new Geometry.Vec2(0,getHeight()));
		};
		entries+=button;
		return entries;
	});
};


return plugin;
// ---------------------------------------------------------------------------------------------
