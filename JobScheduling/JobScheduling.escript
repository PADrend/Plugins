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
 **    JobScheduling
 **    Managing of distributed jobs.
 ** \todo
 **    - timeouts with automatic re-scheduling
 **/
 
loadOnce("LibUtilExt/Command.escript");


//! Namespace
GLOBALS.JobScheduling := new Namespace();
 
//! static

// called by a scheduler whenever a new job is available
JobScheduling.onJobAvailable := new MultiProcedure(); 		// parameter: { 'jobId':jobId, 'workerId': workerId, 'workload': workload]
JobScheduling.onResultAvailable := new MultiProcedure(); 	// parameter: { 'jobId':jobId, 'result':result }
JobScheduling.onWorkerAvailable := new MultiProcedure();	// parameter: workerId

// ------------------------------------------------------------------
