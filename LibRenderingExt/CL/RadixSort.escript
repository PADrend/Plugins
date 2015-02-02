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

static roundUp = fn(x, y) { return ((x + y - 1) / y).floor() * y; };

var T = new Type();
T._printableName @(override) := $Reduce;
T.context @(private) := void;
T.device @(private) := void;
T.queue @(private) := void;
T.program @(private) := void;
T.built @(private) := false;
T.stats @(private, init) := Map;

T.reduceKernel @(private) := void;
T.scanKernel @(private) := void;
T.scatterKernel @(private) := void;

T.warpSizeMem @(private) := 1;
T.warpSizeSchedule @(private) := 1;
T.reduceWorkGroupSize @(private) := 128;
T.scanWorkGroupSize @(private) := 128;
T.scatterWorkGroupSize @(private) := 128;
T.scatterWorkScale @(private) := 1;
T.scatterSlice @(private) := 32;
T.scanBlocks @(private) := 128;
T.radix @(private) := 1;
T.radixBits @(private) := 4;

T.keyType @(private) := "uint";
T.valueType @(private) := "uint";
T.keySize @(private) := Util.getNumBytes(Util.TypeConstant.UINT32);
T.valueSize @(private) := 0;//Util.getNumBytes(Util.TypeConstant.UINT32);

T.histogram @(private) := void;

T.setWarpSizeMem ::= fn(value) { this.warpSizeMem = value; };
T.getWarpSizeMeme ::= fn() { return this.warpSizeMem; };

T.setWarpSizeSchedule ::= fn(value) { this.warpSizeSchedule = value; };
T.getWarpSizeSchedule ::= fn() { return this.warpSizeSchedule; };

T.setReduceWorkGroupSize ::= fn(value) { this.reduceWorkGroupSize = value; };
T.getReduceWorkGroupSize ::= fn() { return this.reduceWorkGroupSize; };

T.setScanWorkGroupSize ::= fn(value) { this.scanWorkGroupSize = value; };
T.getScanWorkGroupSize ::= fn() { return this.scanWorkGroupSize; };

T.setScatterWorkGroupSize ::= fn(value) { this.scatterWorkGroupSize = value; };
T.getScatterWorkGroupSize ::= fn() { return this.scatterWorkGroupSize; };

T.setScatterWorkScale ::= fn(value) { this.scatterWorkScale = value; };
T.getScatterWorkScale ::= fn() { return this.scatterWorkScale; };

T.setScatterSlice ::= fn(value) { this.scatterSlice = value; };
T.getScatterSlice ::= fn() { return this.scatterSlice; };

T.setScanBlocks ::= fn(value) { this.scanBlocks = value; };
T.getScanBlocks ::= fn() { return this.scanBlocks; };

T.setRadixBits ::= fn(value) { this.radixBits = value; };
T.getRadixBits ::= fn() { return this.radixBits; };

T.getRadix ::= fn() { return this.radix; };

T.getProfilingResults @(public) ::= fn(){
	return this.stats;
};

T.setKeyType ::= fn(type, size=0) {
	this.keyType = typeMap[type];
	if(this.keyType) {
		this.keySize = Util.getNumBytes(this.keyType);
	} else if(size>0) {		
		this.keyType = type;
		this.keySize = size;
	} else {
		Runtime.exception("key type has size 0!");
	}
};

T.setValueType ::= fn(type, size=0) {
	this.valueType = typeMap[type];
	if(this.valueType) {
		this.valueSize = Util.getNumBytes(this.valueType);
	} else if(type && size>0) {		
		this.valueType = type;
		this.valueSize = size;
	} else {
		this.valueType = void;
		this.valueSize = 0;
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

T.getBlockSize ::= fn(elements) {
	var tileSize = [reduceWorkGroupSize, scatterWorkScale * scatterWorkGroupSize].max();
	return ((elements + tileSize * scanBlocks - 1) / (tileSize * scanBlocks)).floor() * tileSize;
};

T.getBlocks ::= fn(elements, len) {
	var slicesPerWorkGroup = scatterWorkGroupSize / scatterSlice;
	var blocks = roundUp((elements + len - 1) / len, slicesPerWorkGroup);
	assert(blocks <= scanBlocks);
	return blocks;
};

T.build ::= fn(options="") {
	radix = 2.pow(radixBits);
	scatterSlice = [warpSizeSchedule, radix].max();

	program = new CL.Program(context);
	
	program.addInclude(__DIR__ + "/../resources/kernel/");
	
	program.addDefine("WARP_SIZE_MEM", warpSizeMem);
	program.addDefine("WARP_SIZE_SCHEDULE", warpSizeSchedule);
	program.addDefine("REDUCE_WORK_GROUP_SIZE", reduceWorkGroupSize);
	program.addDefine("SCAN_WORK_GROUP_SIZE", scanWorkGroupSize);
	program.addDefine("SCATTER_WORK_GROUP_SIZE", scatterWorkGroupSize);
	program.addDefine("SCATTER_WORK_SCALE", scatterWorkScale);
	program.addDefine("SCATTER_SLICE", scatterSlice);
	program.addDefine("SCAN_BLOCKS", scanBlocks);
	program.addDefine("RADIX_BITS", radixBits);
	program.addDefine("KEY_T", keyType);
	if(valueSize>0)
		program.addDefine("VALUE_T", valueType);
	
	var upsweepStmts = [];
	var downsweepStmts = [];
	var stops = [1,radix];
	if(scatterSlice > radix)
		stops += scatterSlice;
	stops += scatterSlice * radix;
	
	for(var i = stops.size()-2; i >= 0; --i) {
		var from = stops[i+1];
		var to = stops[i];
		if(to >= scatterSlice) {
			var toStr = to.toIntStr();
			var fromStr = from.toIntStr();
			upsweepStmts += "upsweepMulti(wg->hist.level1.i, wg->hist.level2.c + "
                                   + toStr + ", " + fromStr + ", " + toStr + ", lid);";
			downsweepStmts += "downsweepMulti(wg->hist.level1.i, wg->hist.level2.c + "
                                   + toStr + ", " + fromStr + ", " + toStr + ", lid);";
		} else {
			while(from >= to*4) {
				var toStr = (from/4).toIntStr();
				var fromStr = from.toIntStr();
				var forceZero = (from == 4);
				upsweepStmts += "upsweep4(wg->hist.level2.i + " + toStr + ", wg->hist.level2.c + "
                                       + toStr + ", " + toStr + ", lid, SCATTER_SLICE);";
				downsweepStmts += "downsweep4(wg->hist.level2.i + " + toStr + ", wg->hist.level2.c + "
                                       + toStr + ", " + toStr + ", lid, SCATTER_SLICE, "
                                       + (forceZero ? "true" : "false") + ");";
				from /= 4;
			}
			if(from == to*2) {
				var toStr = (from/2).toIntStr();
				var fromStr = from.toIntStr();
				var forceZero = (from == 2);
				upsweepStmts += "upsweep2(wg->hist.level2.s + " + toStr + ", wg->hist.level2.c + "
                                       + toStr + ", " + toStr + ", lid, SCATTER_SLICE);";
				downsweepStmts += "downsweep2(wg->hist.level2.s + " + toStr + ", wg->hist.level2.c + "
                                       + toStr + ", " + toStr + ", lid, SCATTER_SLICE, "
                                       + (forceZero ? "true" : "false") + ");";
			}
		}
	}
	downsweepStmts.reverse();
	
	program.attachSource("#define UPSWEEP() do { " + upsweepStmts.implode(" ") + " } while (0)\n");
	program.attachSource("#define DOWNSWEEP() do { " + downsweepStmts.implode(" ") +  " } while (0)\n");

	program.attachFile(__DIR__ + "/../resources/kernel/radixsort.cl");
	
	built = program.build(device, options);
	
	if(built) {
		reduceKernel = new CL.Kernel(program, "radixsortReduce");
		scanKernel = new CL.Kernel(program, "radixsortScan");
		scatterKernel = new CL.Kernel(program, "radixsortScatter");
		histogram = new CL.Buffer(context, CL.READ_WRITE, scanBlocks * radix, Util.TypeConstant.UINT32);
	} else {
		reduceKernel = void;
		scanKernel = void;
		scatterKernel = void;		
		histogram = void;
	}
	return built;
};

T.sort ::= fn(CL.Buffer keys, [CL.Buffer,void] values, elements, maxBits=0, profiling=false) {	
	if(!built)
		Runtime.exception( "program was not build!");
	if(elements <= 0)
		Runtime.exception( "elements is zero");
	if(maxBits <= 0)
		maxBits = 8 * keySize;
	else if(maxBits > 8 * keySize)
		Runtime.exception( "maxBits is too large");
	var timer = new Util.Timer();
	
	// TODO: allocate temporary buffers earlier
	var tmpKeys = new CL.Buffer(context, CL.READ_WRITE, elements*keySize);
	var tmpValues;
	if(valueSize > 0)
		tmpValues = new CL.Buffer(context, CL.READ_WRITE, elements*valueSize);
			
	var next;
	var waitFor = [];
	var curKeys = keys;
	var curValues = values;
	var nextKeys = tmpKeys;
	var nextValues = tmpValues;
	var blockSize = getBlockSize(elements);
	var blocks = getBlocks(elements,blockSize);
	assert(blocks <= scanBlocks);
	
	var tmp;
	for(var firstBit = 0; firstBit < maxBits; firstBit += radixBits) {
		next = reduce(histogram, curKeys, blockSize, elements, firstBit, waitFor);
		waitFor = [next];
		next = scan(histogram, blocks, waitFor);
		waitFor = [next];
		next = scatter(nextKeys, nextValues, curKeys, curValues, histogram, blockSize, elements, firstBit, waitFor);
		waitFor = [next];
		tmp = nextKeys; nextKeys = curKeys; curKeys = tmp; // swap
		tmp = nextValues; nextValues = curValues; curValues = tmp; // swap
	}
	if(curKeys != keys) {
		// Odd number of ping-pongs, so we have to copy back again.
		var copyKeysEvent = new CL.Event();
		queue.copyBuffer(curKeys, nextKeys, 0, 0, elements * keySize, waitFor, copyKeysEvent);
		waitFor = [copyKeysEvent];
		if(valueSize > 0) {
			var copyValuesEvent = new CL.Event();
			queue.copyBuffer(curKeys, nextKeys, 0, 0, elements * keySize, waitFor, copyValuesEvent);
			waitFor = [copyValuesEvent];
		}
	}
	
	if(profiling) {
		waitFor[0].wait();
		stats["t_sortTotal"] = timer.getMilliseconds();
	}
	return this;
};

T.reduce ::= fn(CL.Buffer outBuffer, CL.Buffer inBuffer, len, elements, firstBit, waitFor) {	
	assert(reduceKernel.setArg(0, outBuffer));
	assert(reduceKernel.setArg(1, inBuffer));
	assert(reduceKernel.setArg(2, len, Util.TypeConstant.UINT32));
	assert(reduceKernel.setArg(3, elements, Util.TypeConstant.UINT32));
	assert(reduceKernel.setArg(4, firstBit, Util.TypeConstant.UINT32));
	var blocks = getBlocks(elements,len);
	var reduceEvent = new CL.Event();
	assert(queue.execute(reduceKernel, [], [reduceWorkGroupSize*blocks], [reduceWorkGroupSize], waitFor, reduceEvent));
	return reduceEvent;
};

T.scan ::= fn(CL.Buffer histogram_, blocks, waitFor) {	
	assert(scanKernel.setArg(0, histogram_));
	assert(scanKernel.setArg(1, blocks, Util.TypeConstant.UINT32));
	var scanEvent = new CL.Event();
	assert(queue.execute(scanKernel, [], [scanWorkGroupSize], [scanWorkGroupSize], waitFor, scanEvent));
	return scanEvent;
};

T.scatter ::= fn(CL.Buffer outKeys, [CL.Buffer,void] outValues, CL.Buffer inKeys, [CL.Buffer,void] inValues, CL.Buffer histogram_, len, elements, firstBit, waitFor) {	
	assert(scatterKernel.setArg(0, outKeys));
	assert(scatterKernel.setArg(1, inKeys));
	assert(scatterKernel.setArg(2, histogram_));
	assert(scatterKernel.setArg(3, len, Util.TypeConstant.UINT32));
	assert(scatterKernel.setArg(4, elements, Util.TypeConstant.UINT32));
	assert(scatterKernel.setArg(5, firstBit, Util.TypeConstant.UINT32));
	if(valueSize>0) {
		assert(scatterKernel.setArg(6, outValues));
		assert(scatterKernel.setArg(7, inValues));
	}
	var blocks = getBlocks(elements,len);
	var slicesPerWorkGroup = scatterWorkGroupSize / scatterSlice;
	assert(blocks % slicesPerWorkGroup == 0);
	var workGroups = blocks / slicesPerWorkGroup;
	var scatterEvent = new CL.Event();
	assert(queue.execute(scatterKernel, [], [scatterWorkGroupSize * workGroups], [scatterWorkGroupSize], waitFor, scatterEvent));
	return scatterEvent;
};

return T;