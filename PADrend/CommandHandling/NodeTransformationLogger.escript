/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! Allow undo/redo-operations for moving nodes.
	Workflow:
		1. Create NodeTransformationLogger with the observed nodes.
		2. Move nodes.
		3. Apply transaction.

	\code
		var myNodes = ...
		var logger = new NodeTransformationLogger(myNodes);
		// move nodes around
		logger.apply();
	\endcode
*/

static T = new Type;

T.initialTransformations @(private,init) := Map;
T.nodes @(private) := Array;

T._constructor ::= fn(Array nodes_){
	this.nodes = nodes_.clone();
	this.init();
};

T.apply ::= fn([Map,void] relTransformations=void){
	@(once) static Command = Std.module('LibUtilExt/Command');
	
	if(!relTransformations){
		relTransformations = new Map;
		foreach( this.nodes as var node)
			relTransformations[node] = node.getRelTransformationSRT();
	}
	
	var cmd = new Command({
		Command.DESCRIPTION : "Transform nodes",
		Command.EXECUTE : [relTransformations]=>fn(relTransformations){
			foreach(relTransformations as var node, var t)
				node.setRelTransformation(t);
		},
		Command.UNDO : [initialTransformations]=>fn(relTransformations){
			foreach(relTransformations as var node, var t){
//				outln(t.getTranslation());
//				outln(node,"..",node.getRelOrigin());
				node.setRelTransformation(t);
//				outln(node,"..",node.getRelOrigin(),"\n");
			}
			outln("Undo...");
		},
		Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY|Command.FLAG_SEND_TO_SLAVES,
	});
	PADrend.executeCommand(cmd);
};

T.init ::= fn(){
	foreach(this.nodes as var node)
		this.initialTransformations[node] = node.getRelTransformationSRT();	
};

return T;
