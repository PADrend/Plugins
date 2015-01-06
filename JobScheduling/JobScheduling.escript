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
 **    JobScheduling
 **    Managing of distributed jobs.
 ** \todo
 **    - timeouts with automatic re-scheduling
 **/

static NS = new Namespace;
 
// called by a scheduler whenever a new job is available
NS.onJobAvailable := new Std.MultiProcedure; 		// parameter: { 'jobId':jobId, 'workerId': workerId, 'workload': workload]
NS.onResultAvailable := new Std.MultiProcedure; 	// parameter: { 'jobId':jobId, 'result':result }
NS.onWorkerAvailable := new Std.MultiProcedure;	// parameter: workerId


static activeSchedulers = new Map; // id -> ExtObject: .scheduler .numLocalWorker .numRemoteWorker
static activeWorkerSets = new Map; // id -> workerSet


//! (internal)
static init = fn(){
	@(once){
		outln("Init job scheduling...");
		Util.registerExtension('PADrend_AfterFrame',fn(){
			foreach(activeWorkerSets as var worker)
				worker.execute();
			foreach(activeSchedulers as var obj)
				obj.scheduler.execute();
		});
		//! periodically inform all running instances of the active Schedulers
		PADrend.planTask( 0.5, fn(){
			if(!activeSchedulers.empty())
				announceSchedulers();
				
	//		out(" bong ");
			
			return 2.0;
		});
	
	}
	return true;
};

//! (internal) periodically called on the master to inform all running instances (slaves&master) of the active Schedulers
static announceSchedulers = fn(){
	
	// collect info and init local workers
	var newWorkers = new Map;
	var remoteWorkerSetInfo = new Map; // schedulerId -> number of remote workers
	foreach(activeSchedulers as var schedulerId,var obj){
		remoteWorkerSetInfo[schedulerId] = obj.numRemoteWorker; 
		
		if(activeWorkerSets[schedulerId]){
			newWorkers[schedulerId] = activeWorkerSets[schedulerId];
		}else{
			newWorkers[schedulerId] = new (module('./WorkerSet'))(schedulerId,obj.numLocalWorker); // number of local workers
		}
	}
	activeWorkerSets.swap(newWorkers);
	
	static Command = Std.require('LibUtilExt/Command');
	// update slave-instances
	PADrend.executeCommand(new Command({
		Command.EXECUTE : [remoteWorkerSetInfo] => fn(workerSetInfo){
			if( !GLOBALS.isSet($JobScheduling) )
				return;
			Std.require('JobScheduling/JobScheduling').updateWorkerSets(workerSetInfo);
			
		},
		Command.FLAGS : Command.FLAG_SEND_TO_SLAVES // only send to slaves (slave instances also call this  method, but should not handle their own calls)
	}));
};

//! (internal) Called remotly on slave intances by the master.
NS.updateWorkerSets := fn(workerSetInfo){

	var newWorkers=new Map;
	foreach(workerSetInfo as var schedulerId,var numWorker){
		if(activeWorkerSets[schedulerId]){
			newWorkers[schedulerId] = activeWorkerSets[schedulerId];
		}else{
			newWorkers[schedulerId] = new (module('./WorkerSet'))(schedulerId,numWorker);
		}
	}
	activeWorkerSets.swap(newWorkers);
//	out("Local WorkerSets:\n");
//	print_r(activeWorkerSets);
};

//! Create a new scheduler with the given name (and possibly close a prior scheduler with the same name).
NS.initScheduler := fn(String schedulerId,numLocalWorker=1,numRemoteWorker=1){
	init();	
	if(activeSchedulers[schedulerId])
		NS.closeScheduler(schedulerId);
	
	out("Add new scheduler ",schedulerId,"\n");
	activeSchedulers[schedulerId] = new ExtObject({
			$scheduler : new (Std.require('JobScheduling/Scheduler'))(schedulerId),
			$numLocalWorker : numLocalWorker,
			$numRemoteWorker : numRemoteWorker
	});
	announceSchedulers();
};

//! Remove a scheduler with the given name (removes all jobs and pending results).
NS.closeScheduler := fn(String schedulerId){
	out("Remove scheduler ",schedulerId,"\n");

	activeSchedulers.unset(schedulerId);
	announceSchedulers();
};

/*! Add a job to a scheduler with the given name.
	@note The scheduler has to be initialized with initScheduler(name).
	@note See Scheduler.addJob(...) 
	@return a jobId which can be used for fetching the result for this specific job. */
NS.addJob := fn(String schedulerId,job,[Number,false] maxJobDuration=false){
	init();
	var scheduler = NS.getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.addJob(job,maxJobDuration);
};

//! Return array with some statistics on the current schedulers
NS.getInfo := fn(){
	var m = new Map;
	foreach(activeSchedulers as var name,var obj)
		m[name] = obj.scheduler.getInfo();
	return m;
};

NS.getScheduler := fn(String schedulerId){
	return activeSchedulers[schedulerId] ? activeSchedulers[schedulerId].scheduler : void;
};


/*! Fetch (and remove) a result for a specific jobId.
	\note isResultAvailable(schedulerId, jobId) should be called to check if the result is available. */
NS.fetchResult := fn(String schedulerId, String jobId){
	var scheduler = NS.getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.fetchResult(jobId);
};

/*! Fetch (and remove) all available results.
	@return A Map jobId -> result */
NS.fetchResults := fn(String schedulerId){
	var scheduler = NS.getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.fetchResults();
};

NS.isResultAvailable := fn(String schedulerId,String jobId){
	var scheduler = NS.getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.isResultAvailable(jobId);
};

NS.isSchedulerEmpty := fn(String schedulerId){
	var scheduler = NS.getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.empty();
};

NS.test := fn(schedulerId="testScheduler", numJobs=50){
	
	NS.initScheduler(schedulerId,1,5);
	
	// add some jobs
	var myJobIds=[];
	for(var i=0;i<numJobs;++i){

		myJobIds += NS.addJob( schedulerId, [i] => fn(nr){
			var someValue=0;
			for(var i=0;i<nr;++i){
				someValue+=10;
//				out(i,"(",this,")\n");
				yield;
			}
			out(" ###End Job ",nr,"\n");
			return someValue;
		},0.1 );
		
	}

	// every second, fetch the results, print some infos and close the scheduler when finished.
	PADrend.planTask( 1.0, 
		[schedulerId] => fn(schedulerId){
			print_r(NS.getInfo());

			var results = NS.fetchResults(schedulerId);
			if(results)
				print_r(results);
			if(NS.isSchedulerEmpty(schedulerId)){
				NS.closeScheduler(schedulerId);							
			}else{
				return 1; // replan
			}
		});
};


return NS;
// ------------------------------------------------------------------
