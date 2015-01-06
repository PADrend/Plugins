/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/UITools/UIToolManager.escript
 **/


/*! A ToolConfigurator wrapps a Tool-Object  and offers	activation and deactivation listeners for that tool.
	A ToolConfigurator is not created directly but only by calling UIToolManager.registerTool(...) */
static ToolConfigurator = new Type;
{
	var T = ToolConfigurator; 
	T._constructor ::= fn(_tool){	this.tool = _tool;	};
	T.onActivate @(private,init):= Std.MultiProcedure;
	T.onDeactivate @(private,init):= Std.MultiProcedure;
	T.tool @(private) := void;
	T.createConfigGUI := void;	//! ?????????????????????????

	T.getTool ::= fn(){	return tool;	};
	T.registerActivationListener ::= fn(listener){
		onActivate += listener;
		return this;
	};
	T.registerDeactivationListener ::= fn(listener){
		onDeactivate += listener;
		return this;
	};
}


/*! A UIToolManager manages a set of Tools (of arbitrary type), from which
	only one can be active at a time.	*/
var UIToolManager = new Type;

UIToolManager.activeToolConfigurator @(private) := void;
UIToolManager.registry @(private,init) := Map;
UIToolManager.activatingToolQueue @(private,init) := Array;

UIToolManager.accessToolConfigurator := fn(tool){
	var wrapper = registry[tool];
	if(!wrapper)
		Runtime.exception("Unknown tool '"+tool+"'");
	return wrapper;
};

UIToolManager.createToolConfiguratorGUI ::= fn(tool){	//! ?????????????????????????
	var wrapper = accessToolConfigurator(tool);
	return wrapper.createConfigGUI ? wrapper.createConfigGUI() : void;
};

UIToolManager.deactivateTool ::= fn(){	setActiveTool(void);	return this;	};

UIToolManager.getActiveTool ::= fn(){	return activeToolConfigurator ? activeToolConfigurator.getTool() : void;	};

UIToolManager.onActiveToolChanged @(init) := MultiProcedure;

UIToolManager.registerTool ::= fn(tool){
	var wrapper = registry[tool];
	if(wrapper)
		Runtime.warn("Exisiting tool is redefined '"+tool+"'");
	var configurator = new ToolConfigurator(tool);
	registry[tool] = configurator;
	return configurator;
};

/*! Set the new tool. The old tool is automatically deactivated.
	\note If during the deactivation, a new tool is set, it is nevertheless assured that an
		activated tool is always deactivated. (This is why the activationToolQueue is used.)
	\note If the new tool equals the current tool, it is deactivated and then enabled again.
		This makes things more robust and can be used for a refresh-operation.	*/
UIToolManager.setActiveTool ::= fn(tool){
	if(!activatingToolQueue.empty()){
		activatingToolQueue += tool;
		return this;
	}
	activatingToolQueue += tool;
	while(!activatingToolQueue.empty()){
		tool = activatingToolQueue.front();
		try{
			// deactivate old tool
			if(activeToolConfigurator){
				(activeToolConfigurator->fn(){ onDeactivate();})();
				activeToolConfigurator = void;
				onActiveToolChanged(void);
			}
			// activate new tool
			if(void!==tool){
				activeToolConfigurator = accessToolConfigurator(tool);
				(activeToolConfigurator->fn(){ onActivate();})();
				onActiveToolChanged(tool);
			}
		}catch(e){ // finally {...}
			activatingToolQueue.popFront();
			throw e;
		}
		activatingToolQueue.popFront();
	}
	return this;
};

//! ?????????????????????????
UIToolManager.setConfigPanelProvider ::= fn(tool,provider){
	accessToolConfigurator(tool).createConfigGUI = provider;
	return this;
};


return UIToolManager;
