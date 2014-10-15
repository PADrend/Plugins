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
/****
 **	[Plugin:NodeEditor] JobScheduling/Plugin.escript
 **
 ** Plugin for distributing jobs over multiple instances.
 ** Execute JobScheduling.plugin.test() for an example.
 **/
 
loadOnce(__DIR__+"/JobScheduling.escript");


/***
 **  ---|> Plugin
 **/
JobScheduling.plugin := new Plugin({
		Plugin.NAME : 'JobScheduling',
		Plugin.DESCRIPTION : 'Distributed job scheduling using MultiView.',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/EventLoop','PADrend/CommandHandling','ClientServer'],
		Plugin.EXTENSION_POINTS : [ ]
});
var plugin = JobScheduling.plugin;

// -------------------

plugin.activeSchedulers := new Map(); // id -> ExtObject: .scheduler .numLocalWorker .numRemoteWorker
plugin.activeWorkerSets := new Map(); // id -> workerSet

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init:=fn() {
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_AfterFrame',this->this.ex_FrameEnding);
    }
	
	//! periodically inform all running instances of the active Schedulers
	PADrend.planTask( 0.5, this->fn(){
		if(!activeSchedulers.empty())
			announceSchedulers();
			
//		out(" bong ");
		
		return 2.0;
	});

	loadOnce(__DIR__+"/Scheduler.escript");
	loadOnce(__DIR__+"/WorkerSet.escript");
	loadOnce(__DIR__+"/Job.escript");

	return true;
};


//! [ext:ex_FrameEnding]
plugin.ex_FrameEnding := fn(){
	foreach(activeWorkerSets as var worker){
		worker.execute();
	}
	foreach(activeSchedulers as var obj){
		obj.scheduler.execute();
	}
};

//! (internal) periodically called on the master to inform all running instances (slaves&master) of the active Schedulers
plugin.announceSchedulers := fn(){
	
	// collect info and init local workers
	var newWorkers=new Map();
	var remoteWorkerSetInfo = new Map(); // schedulerId -> number of remote workers
	foreach(activeSchedulers as var schedulerId,var obj){
		remoteWorkerSetInfo[schedulerId] = obj.numRemoteWorker; 
		
		if(activeWorkerSets[schedulerId]){
			newWorkers[schedulerId] = activeWorkerSets[schedulerId];
		}else{
			newWorkers[schedulerId] = new JobScheduling.WorkerSet(schedulerId,obj.numLocalWorker); // number of local workers
		}
	}
	activeWorkerSets.swap(newWorkers);
	
	static Command = Std.require('LibUtilExt/Command');
	// update slave-instances
	PADrend.executeCommand(new Command({
		Command.EXECUTE : (fn(workerSetInfo){
			if( !GLOBALS.isSet($JobScheduling) )
				return;
			JobScheduling.plugin.updateWorkerSets(workerSetInfo);
			
		}).bindLastParams( remoteWorkerSetInfo ),
		Command.FLAGS : Command.FLAG_SEND_TO_SLAVES // only send to slaves (slave instances also call this  method, but should not handle their own calls)
	}));
};

//! (internal) Called remotly on slave intances by the master.
plugin.updateWorkerSets := fn(workerSetInfo){

	var newWorkers=new Map();
	foreach(workerSetInfo as var schedulerId,var numWorker){
		if(activeWorkerSets[schedulerId]){
			newWorkers[schedulerId] = activeWorkerSets[schedulerId];
		}else{
			newWorkers[schedulerId] = new JobScheduling.WorkerSet(schedulerId,numWorker);
		}
	}
	activeWorkerSets.swap(newWorkers);
//	out("Local WorkerSets:\n");
//	print_r(activeWorkerSets);
};

//! Create a new scheduler with the given name (and possibly close a prior scheduler with the same name).
plugin.initScheduler := fn(String schedulerId,numLocalWorker=1,numRemoteWorker=1){
	
	if(activeSchedulers[schedulerId]){
		closeScheduler(schedulerId);
	}
	
	out("Add new scheduler ",schedulerId,"\n");
	activeSchedulers[schedulerId] = new ExtObject({
			$scheduler : new JobScheduling.Scheduler(schedulerId),
			$numLocalWorker : numLocalWorker,
			$numRemoteWorker : numRemoteWorker
	});
	announceSchedulers();
};

//! Remove a scheduler with the given name (removes all jobs and pending results).
plugin.closeScheduler := fn(String schedulerId){
	out("Remove scheduler ",schedulerId,"\n");

	activeSchedulers.unset(schedulerId);
	announceSchedulers();
};

/*! Add a job to a scheduler with the given name.
	@note The scheduler has to be initialized with initScheduler(name).
	@note See Scheduler.addJob(...) 
	@return a jobId which can be used for fetching the result for this specific job. */
plugin.addJob := fn(String schedulerId,job,[Number,false] maxJobDuration=false){
	var scheduler = getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.addJob(job,maxJobDuration);
};

//! Return array with some statistics on the current schedulers
plugin.getInfo := fn(){
	var m = new Map();
	foreach(activeSchedulers as var name,var obj)
		m[name] = obj.scheduler.getInfo();
	return m;
};

plugin.getScheduler := fn(String schedulerId){
	return activeSchedulers[schedulerId] ? activeSchedulers[schedulerId].scheduler : void;
};

plugin.test := fn(schedulerId="testScheduler", numJobs=50){
	
	initScheduler(schedulerId,1,5);
	
	// add some jobs
	var myJobIds=[];
	for(var i=0;i<numJobs;++i){

		myJobIds += addJob( schedulerId, (fn(nr){
			var someValue=0;
			for(var i=0;i<nr;++i){
				someValue+=10;
//				out(i,"(",this,")\n");
				yield;
			}
			out(" ###End Job ",nr,"\n");
			return someValue;
		}).bindLastParams(i),0.1 );
		
	}

	// every second, fetch the results, print some infos and close the scheduler when finished.
	PADrend.planTask( 1.0, 
		(fn(schedulerId){
			print_r(JobScheduling.plugin.getInfo());

			var results=JobScheduling.fetchResults(schedulerId);
			if(results){
				print_r(results);
			}
			if(JobScheduling.isSchedulerEmpty(schedulerId)){
				JobScheduling.closeScheduler(schedulerId);							
			}else{
				return 1; // replan
			}
		}).bindLastParams(schedulerId));
};


/*! Fetch (and remove) a result for a specific jobId.
	\note isResultAvailable(schedulerId, jobId) should be called to check if the result is available. */
plugin.fetchResult := fn(String schedulerId, String jobId){
	var scheduler = getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.fetchResult(jobId);
};

/*! Fetch (and remove) all available results.
	@return A Map jobId -> result */
plugin.fetchResults := fn(String schedulerId){
	var scheduler = getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.fetchResults();
};

plugin.isResultAvailable := fn(String schedulerId,String jobId){
	var scheduler = getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.isResultAvailable(jobId);
};

plugin.isSchedulerEmpty := fn(String schedulerId){
	var scheduler = getScheduler(schedulerId);
	if(!scheduler){
		Runtime.warn("No scheduler '"+schedulerId+"'");
		return void;
	}
	return scheduler.empty();
};

// ----------------------
// shortcuts

JobScheduling.addJob := plugin->plugin.addJob;
JobScheduling.closeScheduler := plugin->plugin.closeScheduler;
JobScheduling.fetchResult := plugin->plugin.fetchResult;
JobScheduling.fetchResults := plugin->plugin.fetchResults;
JobScheduling.initScheduler := plugin->plugin.initScheduler;
JobScheduling.isResultAvailable := plugin->plugin.isResultAvailable;
JobScheduling.isSchedulerEmpty := plugin->plugin.isSchedulerEmpty;

return JobScheduling.plugin;
// ------------------------------------------------------------------------------
