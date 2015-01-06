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
/*! WorkerSet 
	For each Scheduler on the master instance, there should be one WorkerSet-Object 
	on each instance (master and slaves). The WorkerSet knows its Scheduler by its id.
	Each worker can create and sustain several workers (internally only represented by ids).
*/
var T = new Type;

T.schedulerId := ""; 
T.capacity := 0; 
T.activeJobs := void;  // Arry: Job
T.availableWorkers := void;  // Map: { id -> true }

//! (static)
T.workerCounter ::= Rand.equilikely(0,10000)*10; 

//! (ctor) WorkerSet
T._constructor ::= fn(String _schedulerId,Number _capacity){
	schedulerId = _schedulerId;
	capacity = _capacity;
	activeJobs = [];
	availableWorkers = new Map();
	
	
	// a new job appeared...
	module('./JobScheduling').onJobAvailable += this->fn(data){
		var workerId = data['workerId'];
		// and it is assigned to this WorkerSet -> accept it
		if(availableWorkers[workerId]){
			// worker no longer available
			availableWorkers.unset(workerId);
			
			// job is active
			activeJobs+=new module('./Job')(data['jobId'],data['workload']);
		}
	};
	static Command = Std.require('LibUtilExt/Command');
	for(var i=0;i<capacity;++i){
		var workerId = createWorkerId();
		availableWorkers[workerId] = true;
		
		// announce available worker (locally and on server instance)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : [workerId]=>fn(workerId){	Std.require('JobScheduling/JobScheduling').onWorkerAvailable( workerId ); },
			Command.FLAGS : Command.FLAG_SEND_TO_MASTER | Command.FLAG_EXECUTE_LOCALLY
		}));
		
	}

	out("WorkerSet created. \n");	
};

//! (internal)
T.createWorkerId ::= fn(){
	return schedulerId + "|" + (++workerCounter);
};

/*! Execute all active jobs.
	If a job has finished, its result is announced.
	If new worker are available, their ids are announced (normally, this also happens each time a job has finished). */
T.execute ::= fn(){
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
	
	static Command = Std.require('LibUtilExt/Command');
	// send results
	foreach(finishedJobs as var job){
	
		// announce available result (locally and on server instance)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : [job.getId(),job.getResult()] => fn(jobId,jobResult){
					Std.require('JobScheduling/JobScheduling').onResultAvailable( { 
						'jobId':jobId,
						'result':jobResult 
				});
			},
			Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY | Command.FLAG_SEND_TO_MASTER
		}));
	}
	
	// announce new workers
	for(var i=availableWorkers.count() ;i<capacity;++i){
		var workerId = createWorkerId();
		availableWorkers[workerId] = true;
		
		// announce available worker (locally and on server instance)
		PADrend.executeCommand(new Command({
			Command.EXECUTE : [workerId] => fn(workerId){	Std.require('JobScheduling/JobScheduling').onWorkerAvailable( workerId );	},
			Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY | Command.FLAG_SEND_TO_MASTER
		}));
	}
};

return T;
