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
T._printableName @(override) := $Reduce;
T.context @(private) := void;
T.device @(private) := void;
T.queue @(private) := void;
T.program @(private) := void;
T.built @(private) := false;
T.stats @(private, init) := Map;

T.reduceKernel @(private) := void;

T.reduceWorkGroupSize @(private) := 128;
T.reduceBlocks @(private) := 64;
T.reduceType @(private) := "int";
T.elementSize @(private) := Util.getNumBytes(Util.TypeConstant.INT32);
T.reduceFn @(private) := "v1 + v2";
T.reduceIdentity @(private) := "0";

T.sumsBuffer @(private) := void;
T.wgcBuffer @(private) := void;

T.setWorkGroupSize ::= fn(value) { this.reduceWorkGroupSize = value; };
T.getWorkGroupSize ::= fn() { return this.reduceWorkGroupSize; };
T.setBlocks ::= fn(value) { this.reduceBlocks = value; };
T.getBlocks ::= fn() { return this.reduceBlocks; };

T.getProfilingResults @(public) ::= fn(){
	return this.stats;
};

T.setReduceFn ::= fn(fun) {
	this.reduceFn = fun;
};

T.setType ::= fn(type, size=0) {
	this.reduceType = typeMap[type];
	if(this.reduceType) {
		this.elementSize = Util.getNumBytes(type);
	} else if(size>0) {		
		this.reduceType = type;
		this.elementSize = size;
	} else {
		Runtime.exception("type has size 0!");
	}
};

T.setIdentity ::= fn(id) {
	this.reduceIdentity = id;
};


T._constructor ::= fn(CL.Context _context, CL.Device _device, CL.CommandQueue _queue) {
	context = _context;
	device = _device;
	queue = _queue;
};

T.build ::= fn(options="") {;
	program = new CL.Program(context);
	
	program.addInclude(__DIR__ + "/../resources/kernel/");
	
	program.addDefine("REDUCE_WORK_GROUP_SIZE", reduceWorkGroupSize);
	program.addDefine("REDUCE_BLOCKS", reduceBlocks);
	program.addDefine("REDUCE_T", reduceType);
	//program.addDefine("REDUCE_FN(v1,v2)", reduceFn); // works apparently only for GPUs 
	program.addDefine("REDUCE_IDENTITY", reduceIdentity);
	
	program.attachSource("#define REDUCE_FN(v1,v2) " + reduceFn);
	program.attachFile(__DIR__ + "/../resources/kernel/reduce.cl");
	
	built = program.build(device, options);
	
	if(built) {
		reduceKernel = new CL.Kernel(program, "reduce");
		sumsBuffer = new CL.Buffer(context, CL.READ_WRITE, elementSize * reduceBlocks);
		wgcBuffer = new CL.Buffer(context, CL.READ_WRITE, 1, Util.TypeConstant.UINT32);
		var acc = new CL.BufferAccessor(wgcBuffer, queue);
		acc.begin();
		acc.write(reduceBlocks, Util.TypeConstant.UINT32);
		acc.end();
	} else {
		reduceKernel = void;
		sumsBuffer = void;
		wgcBuffer = void;
	}
	return built;
};

T.reduce ::= fn(CL.Buffer inBuffer, CL.Buffer outBuffer, elements, first=0, outPosition=0, profiling=false) {	
	if(!built)
		Runtime.exception( "program was not build!");
	var timer = new Util.Timer();
		
	var roundUp = fn(x, y) { return ((x + y - 1) / y).floor() * y; };
	var blockSize = (roundUp(elements, reduceWorkGroupSize * reduceBlocks) / reduceBlocks).floor();
			
	assert(reduceKernel.setArg(0, wgcBuffer));
	assert(reduceKernel.setArg(1, outBuffer));
	assert(reduceKernel.setArg(2, outPosition, Util.TypeConstant.UINT32));
	assert(reduceKernel.setArg(3, inBuffer));
	assert(reduceKernel.setArg(4, first, Util.TypeConstant.UINT32));
	assert(reduceKernel.setArg(5, elements, Util.TypeConstant.UINT32));
	assert(reduceKernel.setArg(6, sumsBuffer));
	assert(reduceKernel.setArg(7, blockSize, Util.TypeConstant.UINT32));
	
	var reduceEvent = new CL.Event();
	assert(queue.execute(reduceKernel, [], [reduceWorkGroupSize * reduceBlocks], [reduceWorkGroupSize], [], reduceEvent));
	
	if(profiling) {
		reduceEvent.wait();
		stats["t_reduce"] = reduceEvent.getProfilingMilliseconds();
		stats["t_reduceTotal"] = timer.getMilliseconds();
	}
	return this;
};

return T;