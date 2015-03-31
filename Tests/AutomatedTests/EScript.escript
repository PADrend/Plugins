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
var AutomatedTest = Std.module('Tests/AutomatedTest');

var tests = [];

tests += new AutomatedTest("EScript/Set",fn(){
	var s1 = new Set([4,5,1,3,4]);

	var s2 = new Set([1,3,4,7]);
	var s3 = s2.clone();
	s2+=5;
	s2-=7;
	
	var s4 = new Set(["foo","blub"]);
	var s5 = new Set(["foo","bar"]);
	
	var s6 = s4|s5;
	s4|=s5;
	
	
	addResult("Basics",s1==s2 && s1!=s3 && s1.count()==4 && s4==new Set(["foo","blub","bar"]) && s4==s6 && s5!=s6
			&& (s1 & new Set([3,4,9,"bla"])) == new Set([3,4])
			&& s1.getSubstracted(new Set([3,4,9,"bla"])) == new Set([1,5]));
	
	
	var sum=0;
	foreach(s1 as var value)
		sum+=value;
	
	// \todo s1.max() does not work because s1 internally is an ExtObject, altough it should be a Collection object (which doesn't work).
	
	addResult("Iterators", sum==1+3+4+5);

});



// ---------------------------------------------------------
return tests;
