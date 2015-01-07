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

 
/*! Scheduler 
	A Scheduler collects jobs and assigns them to free Workers.
	A master program instance can have multiple Schedulers. Each Scheduler has a unique id (or name).
	Each connected program instance (master and slaves) should create one WorkerSet for each Scheduler.
*/
var T = new Type;

T.myId := "";
T.jobCounter := 0;

T.freeWorkerIds := void;	// Array: workerIds
T.pendingJobs := void; 		// Array:  Job
T.activeJobs := void; 		// Map:  JobId -> Job
T.finishedJobs := void; 	// Map:  JobId -> Job
T.reschedulingTimeFactor := 1.5; // factor how much a job's maximal duration is changed when the job is rescheduled after a timeout.

//! (ctor) Scheduler
T._constructor ::= fn(String _schedulerId){
	myId = _schedulerId;
	freeWorkerIds = [];
	pendingJobs = [];
	activeJobs = new Map;
	finishedJobs = new Map;
	
	// if a new worker appeares...
	module('./JobScheduling').onWorkerAvailable += this->fn(workerId){
//		out("New Worker: [",workerId,"]\n");				
		// and is assigned to this scheduler -> store its id
		if(workerId.beginsWith(myId+"|")){

//			out("Scheduler got new Worker: [",workerId,"]\n");
			freeWorkerIds += workerId;
		}
	};
	
	// if a result gets available...
	module('./JobScheduling').onResultAvailable += this->fn(Map result){
		// and this scheduler is waiting for it -> process the result
		var jobId = result['jobId'];
		var job = activeJobs[jobId];
		if( !job )
			return;
		
		activeJobs.unset(jobId);
		finishedJobs[jobId] = job;
		job.result = result['result'];
	};	
};


/*!	Add a Job.
	@param workload A Serializable UserFunction or Delegate
	@param maxDuration The maximal time a job is executed until it is re-scheduled with an inreased max duration (using factor reschedulingTimeFactor)
		If the maxDuration is false, the job is never re-scheduled.
	@return the id of the job. This id can be used to later check and fetch a specific result.
	
	@note The workload function itself should not alter its calling object or its parameter objects.
		This could lead to undefined behavior, if a Job is re-scheduled on a master instance where the Job-object
		is never duplicated by the serialization process.
	@note A workload function may use 'yield' to subdivide the calculation into several steps.
	
	@example
		myScheduler.addJob( (fn(max){ 
			var sum=0;
			for(var i=0;i<max;++i){
				sum+=i;
				yield;
			}
			return sum;
		} ).bindLastParams( 20 ) );
*/
T.addJob ::= fn( workload, [Number,false] maxDuration = false ){
	var jobId = myId+":"+ (++jobCounter);
	pendingJobs += new (module('./Job'))( jobId,workload,maxDuration);
	
//	out("Scheduler.addJob: [",jobId,"]\n");
	return jobId;
};

//! Clear all jobs and results
T.clear ::= fn(){
	pendingJobs.clear();
	activeJobs.clear();
	finishedJobs.clear();
};

//! returns true iff the scheduler has any jobs (pending, active or finished but not fetched)
T.empty ::= fn(){
	return pendingJobs.empty() && activeJobs.empty() && finishedJobs.empty();
};

static Command = module('LibUtilExt/Command');

//! Should be called on every frame.
T.execute ::= fn(){
	var now = clock();

	while(!freeWorkerIds.empty() && !pendingJobs.empty()){
		var job = pendingJobs.popFront();
		activeJobs[job.getId()] = job;
		job.setStartingTime( now );

		var workerId = freeWorkerIds.popFront();
		
		// announce new job (locally and on client instances)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : (fn(jobId,workload,workerId){
				Std.require('JobScheduling/JobScheduling').onJobAvailable( {
					'jobId' : jobId,
					'workload' : workload,
					'workerId' : workerId
				});
			}).bindLastParams( job.getId(),job.getWorkload(),workerId ),
			Command.FLAGS : Command.FLAG_SEND_TO_SLAVES | Command.FLAG_EXECUTE_LOCALLY
		}));
	}

	var reschduledJobs = [];
	// sort out jobs with a timeout for rescheduling
	activeJobs.filter( (fn(jobId,job,now,reschduledJobs){
		var d  = job.getMaximalDuration();
		
		// the job has aduration limit and a timeout occured
		if(d && job.getStartingTime()+d < now){
			reschduledJobs += job;
			return false;
		}
		return true;
	}).bindLastParams(now,reschduledJobs) );
	
	foreach(reschduledJobs as var job){
		out("Job rescheduled after timeout: '", job.getId(),"' (after ",(now-job.getStartingTime()),"seconds)\n");
		job.setMaximalDuration( job.getMaximalDuration() * reschedulingTimeFactor);
		pendingJobs+=job;
	}
};

/*! Fetch (and remove) a result for a specific jobId.
	\note isResultAvailable(jobId) should be called to check if the result is available. */
T.fetchResult ::= fn(String jobId){
	var result = finishedJobs[jobId].getResult();
	finishedJobs.unset(jobId);
	return result;
};

/*! Fetch (and remove) all available results.
	@return A Map jobId -> result */
T.fetchResults ::= fn(){
	var results = new Map;
	foreach(finishedJobs as var jobId,var job)
		results[jobId] = job.getResult();
	finishedJobs.clear();
	return results;
};

T.getId ::= fn( ){ return myId; };
	
T.getInfo ::= fn(){
	return {
		'numPendingJobs' : pendingJobs.count(),
		'numActiveJobs' : activeJobs.count(),
		'numResults' : finishedJobs.count(),
		'numFreeWorkers' : freeWorkerIds.count()
	};
};

T.isResultAvailable ::= fn(String jobId){
	return finishedJobs[jobId];
};


return T;
// ------------------------------------------------------------------
