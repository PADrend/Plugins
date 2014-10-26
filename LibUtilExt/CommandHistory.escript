/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
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
 **/


static Command = module('./Command');

/**
 * History of commands. Used to execute and undo
 * commands. Every plugin which wants to use
 * the history should create its own instance
 * of CommandHistory.
 */
var CommandHistory = new Type;

/**********************************************************************************
 *
 * Implemention of CommandHistory
 *
 **********************************************************************************/
CommandHistory.undoStack @(init,private) := Array;
CommandHistory.redoStack @(init,private) := Array;
CommandHistory.onUndoRedoChanged @(init) := Std.MultiProcedure;


/*!	[public]
	@return Top Command on the undo stack or void	*/
CommandHistory.getUndoTop ::=	fn(){		return this.undoStack.empty() ? void : this.undoStack.back();		};

/*!	[public]
	@return Top Command on the redo stack or void 	*/
CommandHistory.getRedoTop ::=	fn(){		return this.redoStack.empty() ? void : this.redoStack.back();		};


//!	@return Boolean True if there's something to undo
CommandHistory.canUndo ::=		fn(){		return !this.undoStack.empty();		};

//!	@return Boolean True if there's something to redo
CommandHistory.canRedo ::=		fn(){		return !this.redoStack.empty();		};

//!	Undo the latest action and add it to the redo-stack.
CommandHistory.undo ::= fn(){
	if(this.canUndo()){
		var cmd = this.undoStack.popBack();
		this.redoStack.pushBack(cmd);
		cmd.undo();
		this.onUndoRedoChanged();
		return cmd;
	}
	return false;
};

/*!	Redo the latest undone action and add it to the
	undo stack. This assumes a action can be undone
	again if it has been undone once.	*/
CommandHistory.redo ::= fn(){
	var cmd = this.redoStack.popBack();
	if(!cmd)
		return false;
	cmd.execute();
	if(cmd.canUndo()){
		this.undoStack.pushBack(cmd);
		this.onUndoRedoChanged();
	}
	return cmd;
};

/*!	Execute a given command <cmd> and add it to
	the undo-stack if it can be undone. 
	\note if the given command should not be executed locally, it is ignored. */
CommandHistory.execute ::= fn(Command cmd){
	if( (cmd.getFlags()&Command.FLAG_EXECUTE_LOCALLY)==0 )
		return;
	this.redoStack.clear();
	cmd.execute();
	if(cmd.canUndo()){
		this.undoStack.pushBack(cmd);
		this.onUndoRedoChanged();
	}
};

return CommandHistory;
