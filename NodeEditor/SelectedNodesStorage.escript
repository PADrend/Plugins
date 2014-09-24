/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

 static T = new Namespace;

 static storedSelections = new Map; // index -> [Node*]

 T.storeSelection := fn(Number index, Array selection){
	storedSelections[index] = selection;
	T.onSelectionChanged(index,selection);
 };

 T.getStoredSelection := fn(Number index){
	return storedSelections[index];
 };

T.deleteStoredSlection := fn(Number index){
	storedSelections.unset(index);
	T.onSelectionChanged(index, []);
};
T.onSelectionChanged := new Std.MultiProcedure; // fn(index, selection)

return T;
