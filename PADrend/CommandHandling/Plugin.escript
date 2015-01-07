/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/CommandHandling/Plugin.escript
 **
 **/

static Command = Std.require('LibUtilExt/Command');

/***
 **   ---|> Plugin
 **/
PADrend.CommandHandling := new Plugin({
		Plugin.NAME : 'PADrend/CommandHandling',
		Plugin.DESCRIPTION : "Handling of commands with undo/redo support",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','PADrend/Serialization'],
		Plugin.EXTENSION_POINTS : [

			/* [ext:PADrend_CommandHandling_OnExecution]
			 * @param   Command
			 * @result  true if handled or filtered
			 */
			['PADrend_CommandHandling_OnExecution',ExtensionPoint.CHAINED],

			/* [ext:PADrend_CommandHandling_OnUndo]
			 * @param   Command
			 * @result  true if handled or filtered
			 */
			['PADrend_CommandHandling_OnUndo',ExtensionPoint.CHAINED]

		]
});

// -------------------

static _commandHistory;

PADrend.CommandHandling.init @(override) := fn(){

	_commandHistory = new (Std.require('LibUtilExt/CommandHistory'));
	Util.registerExtension('PADrend_KeyPressed',this->ex_KeyPressed);
	Util.registerExtension('PADrend_Init',this->ex_Init);
	
	return true;
};

//! [ext:PADrend_Init]
PADrend.CommandHandling.ex_Init := fn(){

	PADrend.Serialization.registerType( Command, "Command" )
		.initFrom( PADrend.Serialization.getTypeHandler(ExtObject) ); // use default description generation from ExtObject: just store all attributes
};

//! [ext:PADrend_KeyPressed]
PADrend.CommandHandling.ex_KeyPressed := fn(evt){
	if(evt.key == Util.UI.KEY_Z && PADrend.getEventContext().isCtrlPressed()) {
		if(PADrend.getEventContext().isShiftPressed()) {
			this.redoCommand(); // [Ctrl] + [Shift] + [z]   Redo
		} else {
			this.undoCommand(); // [Ctrl] + [z]             Undo
		}
		return Extension.BREAK;
	}
	return Extension.CONTINUE;
};

/*! @param cmd Command-object, a Command-description Map or a UserFunction (or Delegate)
	\note If a UserFunction or a Delegate is given, a Command-Object is created which should be executed both: locally and remotely
*/
PADrend.CommandHandling.executeCommand := fn(cmd){ //[Command,Map,UserFunction,Delegate,...]
	if(cmd---|>Command){
	}else if(cmd---|>Map){
		cmd =new Command(cmd);
	}else {  
		cmd = new Command({ 
			Command.EXECUTE : cmd,
			Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY|Command.FLAG_SEND_TO_SLAVES });
	}
	
	//! [ext:PADrend_CommandHandling_OnExecution]
	if(!executeExtensions('PADrend_CommandHandling_OnExecution',cmd)){
		_commandHistory.execute(cmd);
	}
};

PADrend.CommandHandling.executeRemoteCommand := fn(cmd){
	PADrend.CommandHandling.executeCommand( new Command({ 	Command.EXECUTE : cmd,	Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }) );	
};


PADrend.CommandHandling.redoCommand := fn(){
	var cmd = _commandHistory.getRedoTop();
	if(!cmd){
		PADrend.message("Nothing to be redone.");
		return false;
	}
	//! [ext:PADrend_CommandHandling_OnExecution]
	if(!executeExtensions('PADrend_CommandHandling_OnExecution',cmd)){
		var cmd2 = _commandHistory.redo(); // cmd should be cmd2, but who knows...
		if(cmd2){
			PADrend.message("Redo: "+cmd2.getDescription());
		}
	}
	return true;
};

PADrend.CommandHandling.undoCommand := fn(){
	var cmd = _commandHistory.getUndoTop();
	if(!cmd){
		PADrend.message("Nothing to be undone.");
		return false;
	}
	//! [ext:PADrend_CommandHandling_OnUndo]
	if(!executeExtensions('PADrend_CommandHandling_OnUndo',cmd)){
		var cmd2 = _commandHistory.undo(); // cmd should be cmd2, but who knows...
		if(cmd2){
			PADrend.message("Undo: "+cmd2.getDescription());
		}
	}
	return true;	
};

// --------------------
// Aliases

PADrend.executeCommand := PADrend.CommandHandling -> PADrend.CommandHandling.executeCommand;
PADrend.redoCommand := PADrend.CommandHandling -> PADrend.CommandHandling.redoCommand;
PADrend.undoCommand := PADrend.CommandHandling -> PADrend.CommandHandling.undoCommand;

// --------------------


return PADrend.CommandHandling;
// ------------------------------------------------------------------------------
