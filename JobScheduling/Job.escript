/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/***
 **    JobScheduling/Job.escript
 **/
 
var T = new Type;

T.workload := void;
T.jobId := "";
T.result := void;
T.finished := false;
T.iterator := void; // YieldIterator
T.startingTime := void; // void or Number
T.maximalDuration := false; // false or Number

//! (ctor) Job
T._constructor ::= fn(String _jobId, _workload, [Number,false] _maximalDuration = false){
	workload = _workload;
	jobId = _jobId;
	maximalDuration = _maximalDuration;
};

T.execute ::= fn(){
	try{
		var obj = iterator? iterator.next() : workload();
		if( obj.isA(YieldIterator) ){
			iterator = obj;
			if(iterator.end()){
				result = iterator.value();
				finished = true;
			}
			return;
		}else{
			result = obj;
		}
	}catch(e){
		Runtime.warn(e);
	}
	finished = true;
};

T.getId 				::= fn(){	return jobId;	};
T.getMaximalDuration	::= fn(){	return maximalDuration;	};
T.getResult				::= fn(){	return result;	};
T.getWorkload			::= fn(){	return workload;	};
T.getStartingTime		::= fn(){	return startingTime;	};
T.isFinished			::= fn(){	return finished;	};
T.setStartingTime		::= fn(t){	startingTime = t;	};
T.setMaximalDuration	::= fn([Number,false] t){	maximalDuration = t;	};

return T;
// ------------------------------------------------------------------
