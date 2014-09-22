/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Util/Command] Util/Command.escript
 **
 ** Implements Command-Pattern as found in GOF. CommandHistory
 ** stores a history of all executed commands.
 **
 ** Example: Use of generic command
 ** <code>
 **	var cmd = Command.create("Set global var", // description
 **		fn() { this.preValue := GLOBALS.someVar; GLOBALS.someVar := 3; }, // execute
 **		fn() { GLOBALS.someVar = this.preValue; } // undo
 **	);
 ** var myCommandHistory = new CommandHistory;
 ** GLOBALS.someVar := 4;
 ** out("Pre command: "+someVar+"\n");
 ** myCommandHistory.execute(cmd);
 ** out("After command: "+someVar+"\n");
 ** myCommandHistory.undo();
 ** out("After undo: "+someVar+"\n");
 ** </code>
 **
 ** @note Uses Listener.escript
 **/
static Listener = module('./deprecated/Listener');

/**
 * [public, event]
 * Executed when some do/undo/redo-action took place, changing
 * the next action to be undone/redone.
 *
 * @param sender The history where the change took place
 */
Listener.CMD_UNDO_REDO_CHANGED := 'cmd_UndoRedoChaged';

// -----------------------------------------------------------------------

/**
 * Generic command. Commands offers:
 * - execute: Store pre-state and execute some action
 * - undo: Undo all harm done by last execute-call
 * - getDescription: Description to display command in GUI-elements
 * - flags that indicate where the Command should be executed: locally, remotely (e.g. via MultiView) or both.
 */
GLOBALS.Command := new Type;
var Command = GLOBALS.Command;

Command.EXECUTE ::= $_doExecute;
Command.UNDO ::= $_doUndo;
Command.DESCRIPTION ::= $_description;
Command.FLAGS ::= $_flags;
Command.FLAG_EXECUTE_LOCALLY ::= 1;	// execute locally on the creating instance
Command.FLAG_SEND_TO_SLAVES ::= 2; // if the creating instance is a master, send the command to connected slaves
Command.FLAG_SEND_TO_MASTER ::= 4; // if the creating instance is a slave, send the command to its master

//! (static) factory
Command.create ::= fn(String desc, exec_func, undo_func = void,Number flags = FLAG_EXECUTE_LOCALLY){
	return new Command({
			Command.EXECUTE : exec_func,
			Command.UNDO : undo_func,
			Command.DESCRIPTION : desc,
			Command.FLAGS : flags,
	});
};


/*! (ctor)
	\example new Command(
				{	Command.EXECUTE : fn(){ ...},
					Command.UNDO : fn(){...} , 
					Command.FLAGS : Command.FLAG_SEND_TO_SLAVES }); // only execute on remote instances and not locally
	\note Per default, Commands are only executed locally
*/
//Command._constructor ::= fn(Map attribs = new Map) . (attribs){};

Command.execute ::= fn(){
	return this._doExecute();
};

Command.undo ::= fn(){
	return canUndo() ? this._doUndo() : void;
};

Command.canUndo ::= fn(){
	return this.isSet($_doUndo);
};

Command.getDescription ::= fn(){
	return this.isSet($_description) ? this._description : "";
};

//! \note if no flags are set explicitly, FLAG_EXECUTE_LOCALLY is returned.
Command.getFlags ::= fn(){
	return this.isSet($_flags) ? this._flags : FLAG_EXECUTE_LOCALLY;
};

//! ---o
Command._doExecute := fn(){
	Runtime.warn("Please implement.");
};

Command.setFlags ::= fn(Number f){
	this._flags := f;
};

// -----------------------------------------------------------------------


/**
 * History of commands. Used to execute and undo
 * commands. Every plugin which wants to use
 * the history should create its own instance
 * of CommandHistory.
 */
GLOBALS.CommandHistory := new Type;

/**********************************************************************************
 *
 * Implemention of CommandHistory
 *
 **********************************************************************************/
CommandHistory.undoStack := void;
CommandHistory.redoStack := void;

//! (ctor)
CommandHistory._constructor ::= fn(){
	this.undoStack = [];
	this.redoStack = [];
};

/*!	[public]
	@return Top Command on the undo stack or void	*/
CommandHistory.getUndoTop ::= fn(){
	if(undoStack.empty())
		return void;
	else {
		return undoStack.back();
	}
};

/*!	[public]
	@return Top Command on the redo stack or void 	*/
CommandHistory.getRedoTop ::= fn(){
	if(redoStack.empty())
		return void;
	else
		return redoStack.back();
};

//!	@return Boolean True if there's something to undo
CommandHistory.canUndo ::= fn(){
	return !undoStack.empty();
};

//!	@return Boolean True if there's something to redo
CommandHistory.canRedo ::= fn(){
	return !redoStack.empty();
};

//!	Undo the latest action and add it to the redo-stack.
CommandHistory.undo ::= fn(){
	if(canUndo()){
		var cmd = undoStack.popBack();
		redoStack.pushBack(cmd);
		cmd.undo();
		Listener.notify( Listener.CMD_UNDO_REDO_CHANGED, this);
		return cmd;
	}
	return false;
};

/*!	Redo the latest undone action and add it to the
	undo stack. This assumes a action can be undone
	again if it has been undone once.	*/
CommandHistory.redo ::= fn(){
	var cmd = redoStack.popBack();
	if(!cmd)
		return false;
	cmd.execute();
	if(cmd.canUndo()){
		undoStack.pushBack(cmd);
		Listener.notify( Listener.CMD_UNDO_REDO_CHANGED, this);
	}
	return cmd;
};

/*!	Execute a given command <cmd> and add it to
	the undo-stack if it can be undone. 
	\note if the given command should not be executed locally, it is ignored. */
CommandHistory.execute ::= fn(Command cmd){
	if( (cmd.getFlags()&Command.FLAG_EXECUTE_LOCALLY)==0 )
		return;
	redoStack.clear();
	cmd.execute();
	if(cmd.canUndo()){
		undoStack.pushBack(cmd);
		Listener.notify( Listener.CMD_UNDO_REDO_CHANGED, this);
	}
};

return Command;
