/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2016 Sascha Brandt <myeti@mail.upb.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static CL = Rendering.CL;
static SIZEOF_INT = Util.getNumBytes(Util.TypeConstant.UINT32);

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
T._printableName @(override) := $Compact;
T.context @(private) := void;
T.device @(private) := void;
T.queue @(private) := void;
T.program @(private) := void;
T.built @(private) := false;
T.stats @(private, init) := Map;

T.countEltsKernel @(private) := void;
T.moveValidKernel @(private) := void;

T.compactWorkGroupSize @(private) := 128;
T.compactBlocks @(private) := 64;
T.compactType @(private) := "int";
T.elementSize @(private) := Util.getNumBytes(Util.TypeConstant.INT32);

T.numValidBuf @(private) := void;
T.numValidBufAcc @(private) := void;
T.blockCountsBuf @(private) := void;

//T.setWorkGroupSize ::= fn(value) { this.compactWorkGroupSize = value; };
T.getWorkGroupSize ::= fn() { return this.compactWorkGroupSize; };
//T.setBlocks ::= fn(value) { this.compactBlocks = value; };
//T.getBlocks ::= fn() { return this.compactBlocks; };

T.getProfilingResults @(public) ::= fn(){
	return this.stats;
};

T.getNumValids @(public) ::= fn() {
  if(!numValidBufAcc)
    return 0;
	queue.finish();
  numValidBufAcc.begin(CL.READ_ONLY);
  var numValids = numValidBufAcc.read(Util.TypeConstant.UINT32);
  numValidBufAcc.end();
  return numValids;
};

T.setType ::= fn(type, size=0) {
	this.compactType = typeMap[type];
	if(this.compactType) {
		this.elementSize = Util.getNumBytes(type);
	} else if(size>0) {		
		this.compactType = type;
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
	program = new CL.Program(context);
	
	program.addInclude(__DIR__ + "/../resources/kernel/");
	program.addDefine("COMPACT_T", compactType);
		
	program.attachFile(__DIR__ + "/../resources/kernel/compact.cl");
	
	built = program.build(device, options);
  compactBlocks = device.getMaxComputeUnits()*6;
	
	if(built) {
    countEltsKernel = new CL.Kernel(program, "countElts");
		moveValidKernel = new CL.Kernel(program, "moveValidElementsStaged");    
		numValidBuf = new CL.Buffer(context, CL.READ_WRITE, 1, Util.TypeConstant.UINT32);
		blockCountsBuf = new CL.Buffer(context, CL.READ_WRITE, compactBlocks, Util.TypeConstant.UINT32);
    numValidBufAcc = new CL.BufferAccessor(numValidBuf, queue);
  } else {
    countEltsKernel = void;
		moveValidKernel = void;    
		numValidBuf = void;
		blockCountsBuf = void;
    numValidBufAcc = void;
	}
	return built;
};

T.compact ::= fn(CL.Buffer inBuffer, CL.Buffer outBuffer, CL.Buffer validBuf, elements, profiling=false) {	
	if(!built)
		Runtime.exception( "program was not build!");
	var timer = new Util.Timer();
		
	var roundUp = fn(x, y) { return ((x + y - 1) / y).floor() * y; };
	var blockSize = (roundUp(elements, compactWorkGroupSize * compactBlocks) / compactBlocks).floor();
  
  // Phase 1: Calculate number of valid elements per thread block
  assert(countEltsKernel.setArg(0, blockCountsBuf));
  assert(countEltsKernel.setArg(1, validBuf));
  assert(countEltsKernel.setArg(2, elements, Util.TypeConstant.UINT32));
  assert(countEltsKernel.setArgSize(3, compactWorkGroupSize*SIZEOF_INT));
  
  var countEvent = new CL.Event();
	assert(queue.execute(countEltsKernel, [], [compactWorkGroupSize * compactBlocks], [compactWorkGroupSize], [], countEvent));

  // Phase 2/3: Move valid elements using SIMD compaction
  assert(moveValidKernel.setArg(0, inBuffer));
  assert(moveValidKernel.setArg(1, outBuffer));
  assert(moveValidKernel.setArg(2, validBuf));
  assert(moveValidKernel.setArg(3, blockCountsBuf));
  assert(moveValidKernel.setArg(4, elements, Util.TypeConstant.UINT32));
  assert(moveValidKernel.setArg(5, numValidBuf));
  assert(moveValidKernel.setArgSize(6, compactWorkGroupSize*elementSize));
  assert(moveValidKernel.setArgSize(7, compactWorkGroupSize*SIZEOF_INT));
  assert(moveValidKernel.setArgSize(8, compactWorkGroupSize*elementSize));
  	
	var compactEvent = new CL.Event();
	assert(queue.execute(moveValidKernel, [], [compactWorkGroupSize * compactBlocks], [compactWorkGroupSize], [], compactEvent));
	
	if(profiling) {
    countEvent.wait();
		compactEvent.wait();
		stats["t_count"] = countEvent.getProfilingMilliseconds();
		stats["t_compact"] = compactEvent.getProfilingMilliseconds();
		stats["t_compactTotal"] = timer.getMilliseconds();
	}
	return this;
};

return T;