/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.upb.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
GLOBALS.CL := Rendering.CL;

static typeMap = {
	Util.TypeConstant.UINT8	  : "uchar",
	Util.TypeConstant.UINT16  : "ushort",
	Util.TypeConstant.UINT32  : "uint",
	Util.TypeConstant.UINT64  : "ulong",
	Util.TypeConstant.INT8    : "char",
	Util.TypeConstant.INT16	  : "short",
	Util.TypeConstant.INT32	  : "int",
	Util.TypeConstant.INT64	  : "long",
	Util.TypeConstant.FLOAT	  : "float",
	Util.TypeConstant.DOUBLE  : "double",
};

var T = new Type();
T._printableName @(override) := $Scanner;
T.context @(private) := void;
T.device @(private) := void;
T.queue @(private) := void;
T.program @(private) := void;
T.built @(private) := false;
T.stats @(private, init) := Map;

T.reduceKernel @(private) := void;
T.scanSmallKernel @(private) := void;
T.scanKernel @(private) := void;
T.sumsBuffer @(private) := void;

T.warpSizeMem @(private) := 1;
T.warpSizeSchedule @(private) := 1;
T.reduceWorkGroupSize @(private) := 128;
T.scanWorkGroupSize @(private) := 128;
T.scanWorkScale @(private) := 1;
T.scanBlocks @(private) := 128;
T.scanType @(private) := "int";
T.elementSize @(private) := Util.getNumBytes(Util.TypeConstant.INT32);

T.setWarpSizeMem ::= fn(value) { this.warpSizeMem = value; };
T.getWarpSizeMeme ::= fn() { return this.warpSizeMem; };

T.setWarpSizeSchedule ::= fn(value) { this.warpSizeSchedule = value; };
T.getWarpSizeSchedule ::= fn() { return this.warpSizeSchedule; };

T.setReduceWorkGroupSize ::= fn(value) { this.reduceWorkGroupSize = value; };
T.getReduceWorkGroupSize ::= fn() { return this.reduceWorkGroupSize; };

T.setScanWorkGroupSize ::= fn(value) { this.scanWorkGroupSize = value; };
T.getScanWorkGroupSize ::= fn() { return this.scanWorkGroupSize; };

T.setScanWorkScale ::= fn(value) { this.scanWorkScale = value; };
T.getScanWorkScale ::= fn() { return this.scanWorkScale; };

T.setScanBlocks ::= fn(value) { this.scanBlocks = value; };
T.getScanBlocks ::= fn() { return this.scanBlocks; };

T.getProfilingResults @(public) ::= fn(){
	return this.stats;
};

T.setType ::= fn(type, size=0) {
	this.scanType = typeMap[type];
	if(this.scanType) {
		this.elementSize = Util.getNumBytes(this.scanType);
	} else if(size>0) {		
		this.scanType = type;
		this.elementSize = size;
	} else {
		Runtime.exception("type has size 0!");
	}
};

T._constructor ::= fn(CL.Context _context, CL.Device _device, CL.CommandQueue _queue) {
	context = _context;
	device = _device;
	queue = _queue;
};

T.build ::= fn(options="") {;
	//var maxWorkGroupSize = device.getMaxWorkGroupSize();
	//var localMemElements = device.getLocalMemSize() / elementSize;
	//var maxBlocks = [2*maxWorkGroupSize, localMemElements].min();
	
	program = new CL.Program(context);
	
	program.addInclude(__DIR__ + "/../resources/kernel/");
	
	program.addDefine("WARP_SIZE_MEM", warpSizeMem);
	program.addDefine("WARP_SIZE_SCHEDULE", warpSizeSchedule);
	program.addDefine("REDUCE_WORK_GROUP_SIZE", reduceWorkGroupSize);
	program.addDefine("SCAN_WORK_GROUP_SIZE", scanWorkGroupSize);
	program.addDefine("SCAN_WORK_SCALE", scanWorkScale);
	program.addDefine("SCAN_BLOCKS", scanBlocks);
	program.addDefine("SCAN_T", scanType);
	
	program.attachFile(__DIR__ + "/../resources/kernel/scan.cl");
	
	built = program.build(device, options);
	
	if(built) {
		reduceKernel = new CL.Kernel(program, "reduce");
		scanSmallKernel = new CL.Kernel(program, "scanExclusiveSmall");
		scanKernel = new CL.Kernel(program, "scanExclusive");		
		sumsBuffer = new CL.Buffer(context, CL.READ_WRITE, elementSize * scanBlocks);
	} else {
		reduceKernel = void;
		scanSmallKernel = void;
		scanKernel = void;
		sumsBuffer = void;
	}
	return built;
};

T.scan ::= fn(CL.Buffer inBuffer, CL.Buffer outBuffer, elementCount, profiling=false) {	
	if(!built)
		Runtime.exception( "program was not build!");
	var timer = new Util.Timer();
		
	var roundUp = fn(x, y) { return ((x + y - 1) / y).floor() * y; };
	var tileSize = [reduceWorkGroupSize, scanWorkGroupSize].max();
	var blockSize = (roundUp(elementCount, tileSize * scanBlocks) / scanBlocks);
	var allBlocks = ((elementCount + blockSize - 1) / blockSize).floor();
	assert(allBlocks > 0 && allBlocks <= scanBlocks);
	assert((allBlocks - 1) * blockSize <= elementCount);
	assert(allBlocks * blockSize >= elementCount);
	
	assert(reduceKernel.setArg(0, sumsBuffer));
	assert(reduceKernel.setArg(1, inBuffer));
	assert(reduceKernel.setArg(2, blockSize, Util.TypeConstant.UINT32));
	var reduceEvent = new CL.Event();
	
	assert(scanSmallKernel.setArg(0, sumsBuffer));
	assert(scanSmallKernel.setArg(1, 0, Util.TypeConstant.INT32));
	var scanSmallEvent = new CL.Event();
	
	assert(scanKernel.setArg(0, inBuffer));
	assert(scanKernel.setArg(1, outBuffer));
	assert(scanKernel.setArg(2, sumsBuffer));
	assert(scanKernel.setArg(3, blockSize, Util.TypeConstant.UINT32));
	assert(scanKernel.setArg(4, elementCount, Util.TypeConstant.UINT32));
	var scanEvent = new CL.Event();
	
	assert(queue.execute(reduceKernel, [], [reduceWorkGroupSize * (allBlocks-1)], [reduceWorkGroupSize], [], reduceEvent));
	assert(queue.execute(scanSmallKernel, [], [scanBlocks/2], [scanBlocks/2], [reduceEvent], scanSmallEvent));
	assert(queue.execute(scanKernel, [], [scanWorkGroupSize * allBlocks], [scanWorkGroupSize], [scanSmallEvent], scanEvent));
	
	if(profiling) {
		scanEvent.wait();
		stats["t_reduce"] = reduceEvent.getProfilingMilliseconds();
		stats["t_scanSmall"] = scanSmallEvent.getProfilingMilliseconds();
		stats["t_scan"] = scanEvent.getProfilingMilliseconds();
		stats["t_scanTotal"] = timer.getMilliseconds();
	}
	return this;
};

return T;