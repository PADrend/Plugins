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
 **	[PADrend] Util/TaskScheduler.escript
 ** \note uses PriorityQueue.escript
 **/

GLOBALS.TaskScheduler := new Type;

TaskScheduler._printableName @(override) ::= $TaskScheduler;
TaskScheduler._tasks @(private) :=void;

//! (ctor)
TaskScheduler._constructor ::= fn( ){
	if(EScript.VERSION < 607){ // deprecated
		loadOnce(__DIR__+"/deprecated/PriorityQueue.escript");
		_tasks = new PriorityQueue( fn(a,b){return a[0] < b[0]; } );
	}else{
		_tasks = new (Std.require('Std/PriorityQueue'))( fn(a,b){return a[0] < b[0]; } );
	}
};

//! ---o
TaskScheduler.getCurrentTime ::= fn(){
	return clock();
};

/*! Plan a task in the given time in the future.
	- task must be an executable (e.g. a function or a delegate)
	- time may be 0, meaning that the task should be executed immediately
	- if the task-function returns a number, the task is re-planned by that time in the future
	- if the task-function yields and returnds a number, the task is re-planned by that time in the future
	\code
		// Example with rescheduling:
		// output a "ping" and the time since the last execution every second
		myTaskScheduler.plan( 1, "ping" -> fn(){
			out( this );
			// reschedule
			return 1.0;
		});
	\code
		// Example with rescheduling and yield:
		// output a "ping" twice every second for ten times
		myTaskScheduler.plan( 0.0, fn(){
			for(var i = 0;i<10;++i){
				yield 0.5;  // continue after 0.5 s
				out("ping");
			}
		});
*/
TaskScheduler.plan ::= fn( Number waitingTimeSecs, task,_yieldIterator = void){
	_tasks += [ getCurrentTime()+waitingTimeSecs,task,_yieldIterator ]; 
};

/*! Executes the tasks planned for until currentTime for timeSlot many seconds.
	- if timeSlotSecs is false, all pending tasks are executed.
	\return The number of executed tasks */
TaskScheduler.execute ::= fn( [false,Number] timeSlotSecs = false , [false,Number] now = false ){
	var counter = 0;
	if(!_tasks.empty()){
		var start = getCurrentTime();
		if(!now)
			now = getCurrentTime();
		while(! _tasks.empty() ){
			// check time slot
			if(timeSlotSecs && getCurrentTime()-start>timeSlotSecs)
				break;
			var task = _tasks.get();
			if( task[0]>now )
				break;
			_tasks.extract();

			try{
				var result;
				if(task[2]){ // yield iterator available?
					result = task[2].next();
				}else{ // normal task
					result = task[1]();
				}
				if(result---|>Number){
					plan(result,task[1]);
				}else if(result---|>YieldIterator && !result.end()){
					
					if(! (result.value()---|>Number) ){
						Runtime.warn("Yielded task has to return a number!");
					}else{
						plan(result.value(),task[1],result);
					}
				}
			}catch(e){
				Runtime.log(Runtime.LOG_ERROR,"TaskScheduler: Exception during execution of a task:\n"+e);
			}
			++counter;
		}
	}
	return counter;
};

return TaskScheduler;