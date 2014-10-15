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
 **    JobScheduling/WorkerSet.escript
 **/
 
loadOnce(__DIR__+"/JobScheduling.escript");
loadOnce(__DIR__+"/Job.escript");

// ------------------------------------------------------------------

/*! WorkerSet 
	For each Scheduler on the master instance, there should be one WorkerSet-Object 
	on each instance (master and slaves). The WorkerSet knows its Scheduler by its id.
	Each worker can create and sustain several workers (internally only represented by ids).
*/
JobScheduling.WorkerSet := new Type();
var WorkerSet = JobScheduling.WorkerSet;

WorkerSet.schedulerId := ""; 
WorkerSet.capacity := 0; 
WorkerSet.activeJobs := void;  // Arry: Job
WorkerSet.availableWorkers := void;  // Map: { id -> true }

//! (static)
WorkerSet.workerCounter ::= Rand.equilikely(0,10000)*10; 

//! (ctor) WorkerSet
WorkerSet._constructor ::= fn(String _schedulerId,Number _capacity){
	schedulerId = _schedulerId;
	capacity = _capacity;
	activeJobs = [];
	availableWorkers = new Map();
	
	
	// a new job appeared...
	JobScheduling.onJobAvailable += this->fn(data){
		var workerId = data['workerId'];
		// and it is assigned to this WorkerSet -> accept it
		if(availableWorkers[workerId]){
			// worker no longer available
			availableWorkers.unset(workerId);
			
			// job is active
			activeJobs+=new JobScheduling.Job(data['jobId'],data['workload']);
		}
	};
	static Command = Std.require('LibUtilExt/Command');
	for(var i=0;i<capacity;++i){
		var workerId = createWorkerId();
		availableWorkers[workerId] = true;
		
		// announce available worker (locally and on server instance)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : (fn(workerId){
				JobScheduling.onWorkerAvailable( workerId );
			}).bindLastParams(workerId),
			Command.FLAGS : Command.FLAG_SEND_TO_MASTER | Command.FLAG_EXECUTE_LOCALLY
		}));
		
	}

	out("WorkerSet created. \n");	
};

//! (internal)
WorkerSet.createWorkerId ::= fn(){
	return schedulerId + "|" + (++workerCounter);
};

/*! Execute all active jobs.
	If a job has finished, its result is announced.
	If new worker are available, their ids are announced (normally, this also happens each time a job has finished). */
WorkerSet.execute ::= fn(){
	if(activeJobs.empty())
		return;
	
	// execute active jobs
	foreach(activeJobs as var job)
		job.execute();
	
	
	// sort out finished jobs (in a second step to improve robustness in a concurrent setting)
	var newJobs = [];
	var finishedJobs = [];
	foreach(activeJobs as var job){
		if(job.finished){
			finishedJobs += job;
		}else{
			newJobs += job;
		}
	}
	activeJobs.swap(newJobs);
	
	// send results
	foreach(finishedJobs as var job){
	
		// announce available result (locally and on server instance)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : (fn(jobId,jobResult){
				JobScheduling.onResultAvailable( { 
						'jobId':jobId,
						'result':jobResult 
				});
			}).bindLastParams(job.getId(),job.getResult()),
			Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY | Command.FLAG_SEND_TO_MASTER
		}));
	}
	
	// announce new workers
	for(var i=availableWorkers.count() ;i<capacity;++i){
		var workerId = createWorkerId();
		availableWorkers[workerId] = true;
		
		// announce available worker (locally and on server instance)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : (fn(workerId){
				JobScheduling.onWorkerAvailable( workerId );
			}).bindLastParams(workerId),
			Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY | Command.FLAG_SEND_TO_MASTER
		}));
	}
};

// ------------------------------------------------------------------
