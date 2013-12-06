/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] Util/PriorityQueue.escript
 **
 **/

GLOBALS.PriorityQueue := new Type;
PriorityQueue._printableName @(override) ::= $PriorityQueue;

PriorityQueue.compare @(private) := void;
PriorityQueue.arr @(private,init) := Array;

/*! (ctor) */
PriorityQueue._constructor ::= fn( compareFunction = (fn(a,b){return a<b;}) ){
	compare = compareFunction;
};

PriorityQueue.add ::= fn(e){
	arr.pushBack(e);
	var i = count()-1;
	while(i>0){
		var p=( (i+1)/2).floor()-1;
		if( compare(e,arr[p])){
			var t = arr[p];
			arr[p]=e;
			arr[i]=t;
		}else{
			break;
		}
		i = p;
	}
};
PriorityQueue."+=" ::= PriorityQueue.add;
PriorityQueue.count ::= fn(){
	return arr.count();
};
PriorityQueue.empty ::= fn(){
	return arr.empty();
};
PriorityQueue.clear ::= fn(){
	return arr.clear();
};
PriorityQueue.get ::= fn(){
	return arr.empty() ? void : arr[0];
};
PriorityQueue.extract ::= fn(){
	var size = arr.count();
	if(size>1){
		var min = arr[0];
		arr[0]=arr.popBack();
		heapify(0);
		return min;
	} else if(size==1) {
		var min = arr[0];
		arr.popBack();
		return min;
	} else return void;
};
PriorityQueue.heapify ::= fn(i){
	var left = ((i+1)*2)-1;
	var size = arr.count();
	if(left<size){
		var minI = i;
		var right = left+1;

		if( compare(arr[left],arr[minI]) )
			minI = left;
		if(right<size && compare(arr[right],arr[minI]))
			minI = right;
		if(minI!=i){
//			swap(i,minI);
			var tmp = arr[i];
			arr[i] = arr[minI];
			arr[minI] = tmp;
			heapify(minI);
		}
	}
};
