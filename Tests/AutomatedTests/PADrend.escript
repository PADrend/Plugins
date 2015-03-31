/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tests] Tests/AutomatedTests/PADrend.escript
 **/

var AutomatedTest = Std.module('Tests/AutomatedTest');

var tests = [];

// -----------------------------------------------------------------------------------------------

// extended Object Serialization tests
tests += new AutomatedTest( "PADrend ObjectSerialization" , fn(){
	static Command = Std.module('LibUtilExt/Command');
	// function with bound params
	var f1 = [10,1]=>fn(b,c,a){	return a*b-c; };
	var s_f1 = PADrend.serialize( f1);
	var f2 = PADrend.deserialize( s_f1);
//		out(s_f1);

	// Command serialization
	var c1 = new Command({
			Command.EXECUTE : fn(){ return m1; }, 
			Command.UNDO : fn(){ return -m1; }, 
			$m1 : 1 });
	var s_c1 = PADrend.serialize(c1);
	var c2 = PADrend.deserialize(s_c1);
	
	return (true 
		&& f2(5) == 49
		&& c2.execute() == 1 && c2.undo() == -1
	);
});

// -----------------------------------------------------------------------------------------------
return tests;
