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

// -----------------------------------------------------------------------

/**
 * Generic command. Commands offers:
 * - execute: Store pre-state and execute some action
 * - undo: Undo all harm done by last execute-call
 * - getDescription: Description to display command in GUI-elements
 * - flags that indicate where the Command should be executed: locally, remotely (e.g. via MultiView) or both.
 */
static Command = new Type;

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
	return this.canUndo() ? this._doUndo() : void;
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

return Command;
