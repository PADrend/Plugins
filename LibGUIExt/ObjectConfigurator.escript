/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! A ObjectConfigurator allows the configuration of an hierarchical
	object structure using a combination of an optional TreeView with type based entries 
	and type based config panels. */
	
static TypeBasedHandler = Std.module('LibUtilExt/TypeBasedHandler');

var T = new Type;
T._fillTreeEntry @(init) := fn(){	return new TypeBasedHandler(true);	};
T._configPanelRegistry  @(init) := fn(){	return new TypeBasedHandler(true);	};

/*! Register a config panel factory for a given Type (Node, State or Behaviour).
	The factory method has to accept two parameters:
	 1. The GUI.Panel to which the config components should be added.
	 2. The object to configure.
	\example
		NodeEditor.addConfigPanelProvider(MinSG.GroupNode, fn(MinSG.GroupNode node, panel){
			panel += "The node has "+node.countChildren()+" many children";
		});
	\note
		There may be more than one handler registered for one type.
	\deprecated Use normal gui registries instead!
*/
T.addConfigPanelProvider ::= fn(Type type,fun){
	_configPanelRegistry += [type,fun];
};

/*! Register a config tree entry factory for a given Type (Node, State or Behaviour).
	The factory method has to accept two parameters:
	 1. The object to configure.
	 2. The GUI.TreeViewEntry to which the config components should be added.
	\example
		configurator.addEntryProvider(MinSG.GroupNode, fn(MinSG.GroupNode node, entry){
			entry.getBaseContainer() += "The node has "+node.countChildren()+" many children";
		});
	\note
		There may be more than one handler registered for one type.	
	\see See createConfigTreeEntry() for functions defined on the entry. */
T.addEntryProvider := fn(Type type,fun){
	_fillTreeEntry += [type,fun];
};


/*! Basic entry functions:
	- entry.configure(obj)			//!< show the config panel for 'obj'
	- entry.createSubentry(obj)		//!< add a subentry for 'obj'
	- entry.getBaseContainer()		//!< get the GUI.Container of the entry
	- entry.getObject()				//!< get the object for this entry
	- entry.rebuild()				//!< recreate this entry
	\note The isActiveEntry is set, if the entry is the only top-level entry.
			E.g. some subentries may be initially expanded then.	*/
T.createConfigTreeEntry ::= fn(obj,Bool isActiveEntry=false){

	var entry = gui.create({
		GUI.TYPE : GUI.TYPE_TREE_GROUP,
		GUI.OPTIONS : []
	});
	entry.isActiveEntry := isActiveEntry;
	entry._obj := obj;
	entry._configurator := this;
	
	entry.getObject := fn(){	return _obj;	};
	
	//! search the component tree up to the root and call doConfigure(obj) when found.
	entry.configure := fn(obj){
		for(var c=this;c;c=c.getParentComponent()){
			if(c.isSet($doConfigure)){
				c.doConfigure(obj);
				break;
			}
		}
	};
	/*! create a new subentry for the given object and add it to the entry. 
		If an optinal 'id' is given and the entry already has an subentry with the same id, 
		no new subentry is created, but the existing subentry is rebuild.*/
	entry.createSubentry := fn(obj,id = false){
		if(id){
			if(this.isSet($_subentries)){
				var old = _subentries[id];
				if(old && gui.isCurrentlyEnabled(old) ){
					old.rebuild();
					return;
				}
			}else{
				this._subentries := new Map();
			}
			var entry = _configurator.createConfigTreeEntry(obj);
			this += entry;
			this._subentries[id] = entry;
			return entry;
		}else{
			var entry = _configurator.createConfigTreeEntry(obj);
			this += entry;
			return entry;
		}
	};

	entry.rebuild := fn(){
		this.destroyContents();
		var baseContainer = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS, -10, 17],
			GUI.CONTENTS : []
		});		
		this._baseContainer := baseContainer;
		this.getBaseContainer := fn(){	return _baseContainer;	};

		this.setComponent(this.getBaseContainer());
		_configurator._fillTreeEntry(getObject(),this);

		if(getParentComponent())
			getParentComponent().layout();

	};

	entry.rebuild();
	return entry;
};


//! Create a config panel for the given object.
//! \deprecated Use normal gui registries instead!
T.createConfigPanel ::= fn(obj){
	var p = gui.create({
		GUI.TYPE : GUI.TYPE_PANEL,
		GUI.FLAGS : GUI.AUTO_LAYOUT,
		GUI.SIZE : [GUI.WIDTH_REL|GUI.HEIGHT_REL, 1, 1]
	});
	var handler = _configPanelRegistry.queryHandlerForType(obj.getType());
	while(!handler.empty()){
		var fun = handler.popBack();
		try{
			fun(obj,p);
		}catch(e){
			Runtime.warn(e);
		}
		if(!handler.empty()){
			p++;
			p+='----';
			p++;
		}
	}
	return p;
};


/*!	Configure the given GUI.Container to be able to show a type based configuration panel for objects.
	\example
		var myConfigPanelContainer = gui.createContainer(...);
		myConfigurator.initConfigPanel(myConfigPanelContainer);
		//...

		// show the configuration panel for myObject inside the panel.
		myConfigurator.update(myObject).
	\deprecated Use normal gui registries instead!
*/
T.initConfigPanel ::= fn(GUI.Container configPanelContainer, [String,void] _panelProviderPrefix){

	configPanelContainer.__configuredObject := void;	
	
	configPanelContainer.update := [this,_panelProviderPrefix] => fn(configurator,_panelProviderPrefix, obj){
		this.destroyContents();
		this.__configuredObject = obj;
		
		if( _panelProviderPrefix){
			var p = gui.create({
				GUI.TYPE : GUI.TYPE_PANEL,
				GUI.FLAGS : GUI.AUTO_LAYOUT,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS, 1, 1]
			});

			var entries;
			if( gui.hasRegisteredComponentProvider( _panelProviderPrefix+obj.toString() )){
				entries = gui.createComponents( 
					{
						GUI.TYPE		:	GUI.TYPE_COMPONENTS,
						GUI.PROVIDER	:	_panelProviderPrefix+obj.toString(),
						GUI.CONTEXT		:	obj
					}
				);
			}else{
				
				for( var t=obj.getType(); t; t=t.getBaseType()){
					var id = _panelProviderPrefix + t.toString();
					if( gui.hasRegisteredComponentProvider( id ) ){
						entries = gui.createComponents( {
								GUI.TYPE		:	GUI.TYPE_COMPONENTS,
								GUI.PROVIDER	:	id,
								GUI.CONTEXT		:	obj
						});
						break;
					}
					
				}
			}
			if(entries)
				foreach( entries as var c)
					p += c;

			if(void!==obj){	//! \deprecated 
				var handler = configurator._configPanelRegistry.queryHandlerForType(obj.getType());
				while(!handler.empty()){
					var fun = handler.popBack();
					try{
						fun(obj,p);
					}catch(e){
						Runtime.warn(e);
					}
					if(!handler.empty()){
						p++;
						p+='----';
						p++;
					}
				}
			}
			this += p;

		}else if(void!==obj){ //! \deprecated 
//			this += configurator.createConfigPanel(obj);
		}
		
	};
	//! \see RefreshableContainerTrait
	@(once) static  RefreshableContainerTrait = module('./Traits/RefreshableContainerTrait');
	Std.Traits.addTrait( configPanelContainer, RefreshableContainerTrait );
	configPanelContainer.refresh @(override) := fn(){
		var scrollPosBackup;
		if(this.getFirstChild().isSet($getScrollPos))
			scrollPosBackup = this.getFirstChild().getScrollPos();
		this.update( this.__configuredObject );
		if(scrollPosBackup&&this.getFirstChild().isSet($scrollTo)){
			this.layout();
			this.getFirstChild().scrollTo(scrollPosBackup);
		}
	};
};

/*!	Configure the given GUI.TreeView to show configuration entries for objects.
	\example

		var myConfigTreeView = gui.createTreeView(...);
		myConfigurator.initTreeView(myConfigTreeView);
		//...

		// show the entries for several objects.
		myConfigurator.update( [myObject1,myObject2,myObject3] ).
*/
T.initTreeView ::= fn(GUI.TreeView treeView){

	
	/*! ---o
		This function is called when an entry is selected or by calling 'configure(data)' of an entry.	*/
	treeView.doConfigure := fn(data){
		// show additional config options - if you like.
	};
	
	treeView.update := [this] => fn(configurator, Array elements){
		this.destroyContents();
		var firstEntry;
		var entryIsActive = (elements.count() == 1);
		foreach(elements as var element){
			var entry = configurator.createConfigTreeEntry(element, entryIsActive);
			this += entry;
			if(!firstEntry) firstEntry=entry;
		}
		this.layout(); // this avoids a flickering that occurs for one frame until the components' positions are adjusted.
		
		if(elements.empty()){ // if no entry is present, clear the attached config panel(s) (if available)
			this.doConfigure(void);
		}else {
			this.doConfigure(elements.front());
		}
	};


	// when a entry is selected ---> show additional config options (by using doConfigure)
	treeView.addDataChangedListener( treeView->fn(data){
		if(data.empty()){
			doConfigure(void);
		}else{
			var entry = data.back().getParentComponent();
			doConfigure(entry.getObject());
		}
	});
	
};

/*!	Configure the given GUI.TreeView to show configuration entries for objects.
	For the selected entry, a config panel is shown on the configPanelContainer.
	\example

		var myConfigTreeView = gui.createTreeView(...);
		var myConfigPanelContainer = gui.createContainer(...);
		myConfigurator.initTreeViewConfigPanelCombo(myConfigTreeView,myConfigPanelContainer);
		//...

		// show the entries for several objects.
		myConfigurator.update( [myObject1,myObject2,myObject3] ).
*/
T.initTreeViewConfigPanelCombo ::= fn(GUI.TreeView treeView, GUI.Container configPanelContainer, [String,void] _panelProviderPrefix = void){
	initConfigPanel(configPanelContainer,_panelProviderPrefix);
	initTreeView(treeView);
	
	//! Whenever an object is selected for configuration in the tree view, a corresponding config panel is shown in the configPanelContainer
	treeView.doConfigure := [configPanelContainer] => fn(configPanelContainer, data){
		configPanelContainer.update(data);
	};
};
 
GUI.ObjectConfigurator := T; //! \deprecated alias
return T;
// --------------------------------------------------------------------------------------------------
