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
/***
 **    JobScheduling/Job.escript
 **/
 
loadOnce(__DIR__+"/JobScheduling.escript");

/*! Job */
JobScheduling.Job := new Type();
var Job = JobScheduling.Job;

Job.workload := void;
Job.jobId := "";
Job.result := void;
Job.finished := false;
Job.iterator := void; // YieldIterator
Job.startingTime := void; // void or Number
Job.maximalDuration := false; // false or Number

//! (ctor) Job
Job._constructor ::= fn(String _jobId, _workload, [Number,false] _maximalDuration = false){
	workload = _workload;
	jobId = _jobId;
	maximalDuration = _maximalDuration;
};

Job.execute ::= fn(){
	try{
		var obj = iterator? iterator.next() : workload();
		if( obj ---|> YieldIterator ){
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

Job.getId 				::= fn(){	return jobId;	};
Job.getMaximalDuration	::= fn(){	return maximalDuration;	};
Job.getResult			::= fn(){	return result;	};
Job.getWorkload			::= fn(){	return workload;	};
Job.getStartingTime		::= fn(){	return startingTime;	};
Job.isFinished			::= fn(){	return finished;	};
Job.setStartingTime		::= fn(t){	startingTime = t;	};
Job.setMaximalDuration	::= fn([Number,false] t){	maximalDuration = t;	};


// ------------------------------------------------------------------
