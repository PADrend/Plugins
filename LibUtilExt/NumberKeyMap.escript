/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
/*! A map with sorted number keys.
	Read operations require O(log n) steps; !!!!Write operations are linear!!!!
*/
static T = new Type;

T._printableName ::= $SortedList;
T.data @(private,init) := Array;	// [ [number,value] ]


T._constructor ::= fn( [Map,Array,T,void] mixed = void){
	if(!mixed){ //default
	}else if(mixed.isA(Array)){
		foreach(mixed as var entry)
			this.insert(entry...);
	}else if(mixed.isA(T)){
		this.data = (mixed->fn(){return this.data.clone();})();
	}else{
		foreach(mixed as var key,var value)
			this.insert(key,value);
	}

};

T._set ::= fn( key, value ){ // t[ key ] = value
	this.insert(key,value);
	return value;
};

T.clone ::= 		fn(){	return new T(this);	};

T.getMaxEntry ::= 	fn(){	return this.data.empty() ? void : this.data.back().clone();		};
T.getMaxKey ::= 	fn(){	return this.data.empty() ? void : this.data.back().front();		};
T.getMinEntry ::= 	fn(){	return this.data.empty() ? void : this.data.front().clone();	};
T.getMinKey ::= 	fn(){	return this.data.empty() ? void : this.data.front().front();	};

T.insert ::= fn(Number key,value=true){
	var d = this.data;
	if(d.empty()||key>this.data.back().front()){
		d += [key,value];
	}else{
		[var left,var right] = getNeighborIndices(key);
		if(left==right){
			d[left] = [key,value];
		}else if(!right){
			d += [key,value];
		}else if(!left){
			d.pushFront( [key,value] );
		}else{
			var arr = d.slice(0,left+1);
			arr += [key,value];
			arr.append(d.slice(right));
			d.swap(arr);
		}
	}
	return this;
};

T.containsKey ::= fn(Number key){
	var i = getNextIndex(key);
	return i ? this.data[i].front()==key : false;
};
T._get ::= fn(Number key){	// t[ key ] -> value
	var i = getNextIndex(key);
	return i ? (this.data[i].front()==key? this.data[i].back() : void ) : void;
};

T.count ::= fn(){	return this.data.count();	};
T.empty ::= fn(){	return this.data.empty();	};
T.clear ::= fn(){	this.data.clear();	return this;	};


T.getNextIndex ::= fn(Number key){
	var d = this.data;
	var i = 0;
	for(var stepSize = (d.count()/2).floor();stepSize>=2;stepSize = (stepSize/2).floor()){
		var i2 = i+stepSize;
		if( i2<d.count() && key>d[i2].front() )
			i = i2;
	}
	for(;i<d.count();++i){
		if(d[i].front()>=key )
			return i;
	}
	return void;
};

T.getEntryByIndex ::= fn(Number index){
	return this.data[index].clone();
};

T.toArray ::= fn(){
	return this.data.clone();
};

T.toMap ::= fn(){
	var m = new Map;
	foreach(this.data as var entry)
		m[entry[0]] = entry[1];
	return m;
};

T.getNeighborIndices ::= fn(Number key){
	var d = this.data;
	if(d.empty()){
		return [void,void];
	}else if(key<=d.front().front()){
		return [ key == d.front().front() ? 0 : void,0];
	}else if(key>=d.back().front()){
		return [ d.count()-1, key == d.back().front() ? d.count()-1 : void];
	}else{
		var begin = 0;
		var end = d.count();
		while(end-begin>1){
			var i = ((end+begin)/2).floor();
//			outln(begin,"\t",end,"\t",i);
			if(d[i].front()==key)
				return [i,i];
			else if(key<d[i].front()){
				end = i;
			}else{
				begin = i;
			}
		}
		if(d[begin].front()==key)
			return [begin,begin];
		else if(end<d.count() && d[end].front()==key)
			return [end,end];
		else return [begin,end<d.count()?end:void];
	}
};
T.getNeighbors ::= fn(Number key){
	var n = this.getNeighborIndices(key);
	return [ n[0] ? this.getEntryByIndex(n[0]) : void, n[1] ? this.getEntryByIndex(n[1]) : void ];
};

static MyIterator = new Type;
MyIterator._constructor ::= fn(data){
	this.data := data;
	this.i := 0;
};
MyIterator.key ::= fn(){
	if(this.i<this.data.count()){
		return this.data[this.i].front();
	}else return void;
};
MyIterator.value ::= fn(){
	if(this.i<this.data.count()){
		return this.data[this.i].back();
	}else return void;
};
MyIterator.end ::= fn(){	return this.i>=this.data.count();	};

MyIterator.next ::= fn(){	++this.i;	};
MyIterator.reset ::= fn(){	this.i = 0;	};


T.getIterator ::= fn(){
	return new MyIterator(this.data);
};

// (internal) must always return true. Used for testing.
T._isSorted ::= fn(){
	if(!this.empty()){
		var max;
		foreach(this.data as var entry){
			if(!max || entry.front()>max){
				max = entry.front();
			}else{
				return false;
			}
		}
	}
	return true;
};

// static
T._test ::= fn(Number iterations = 1000){
	var ok = true;

	var t = new T;
	ok &= t.empty();
	t.insert( 1 );
	ok &= !t.empty();
	t[10] = true;
	t[7] = "foo";
	t.insert( 5 );
	t.insert( 9 );
	ok &= t.count() == 5;
	var t2 = t.clone();
	ok &= t2.count() == 5;
	t2.clear();
	ok &= t2.empty();

	ok &= t.getMaxKey() == 10;
	ok &= t.getMinKey() == 1;
	ok &= t.containsKey(7) && !t.containsKey(7.1);
	ok &= t[7] === "foo";
	ok &= t.getNeighbors(5.4) == [ [5,true], [7,"foo"] ];
	ok &= t.getNeighbors(5) == [ [5,true], [5,true] ];
	ok &= t.getNeighbors(-1) == [ void, [1,true] ];
	ok &= t.getNeighbors(100) == [ [10,true], void ];

	var s = "";
	foreach(t as var key,var value){
		s+=""+key+","+value+";";
	}
	ok&= s==="1,true;5,true;7,foo;9,true;10,true;";

//	var timer = new Util.Timer;
	for(var i=0;i<iterations;++i){
		t.insert( Rand.equilikely(0,20) );
		t.insert( Rand.uniform(0,20) );

	}
//	outln(timer.getSeconds());

	ok &= t._isSorted();

	//print_r( t.toArray());

	for(var i = 0;i<iterations;++i){
		var v =  (i%2)==0 ?  Rand.equilikely(-2,22) : Rand.uniform(-2,22);
		
		var next = t.getNextIndex(v);
		
		if(next){
			if( t.getEntryByIndex(next).front()<v )
				ok &= false;
			if(next>0 && t.getEntryByIndex(next-1).front()>=v )
				ok &= false;
	//		outln( v,"\t",t.getEntryByIndex(next).front());
		}else{
			if( t.getMaxKey()>=v )
				ok &= false;
		}
	}
	
	var t3 = new T( [ [17,"bar"], [42] ] );
	ok &= t3[17] == "bar" && t3[42];

	var t4 = new T( { 17:"bar", 42:true} );
	ok &= t4[17] == "bar" && t4[42];

	return ok;

};

// -----------------------------------------------------------------------------
//outln( T._test(1000) );

//var t = new T;
//
//t[4.75] = 7;
//t[5.15] = 8;
//
//foreach(t as var key,var value){
//	outln(key,"\t",value);
//
//}
//
//print_r(t.getNeighbors(5));
//print_r(t.getNeighbors(6));

return T;
