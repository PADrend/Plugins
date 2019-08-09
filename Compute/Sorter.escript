/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static roundUp = fn(x, y) { return ((x + y - 1) / y).floor() * y; };
static typeMap = {
	Util.TypeConstant.UINT8	  : void, // unsupported
	Util.TypeConstant.UINT16  : void, // unsupported
	Util.TypeConstant.UINT32  : "uint",
	Util.TypeConstant.UINT64  : "uint64_t",
	Util.TypeConstant.INT8    : void, // unsupported
	Util.TypeConstant.INT16	  : void, // unsupported
	Util.TypeConstant.INT32	  : "int",
	Util.TypeConstant.INT64	  : "int64_t",
	Util.TypeConstant.FLOAT	  : "float",
	Util.TypeConstant.DOUBLE  : "double",
};

var T = new Type();
T._printableName @(override) := $Sorter;

T.program @(private) := void;
T.initialized @(private) := false;
T.stats @(private, init) := Map;

T.keyType @(private) := "uint";
T.keySize @(private) := Util.getNumBytes(Util.TypeConstant.UINT32);
T.setKeyType ::= fn(type, size=0) {
	reset();
	this.keyType = typeMap[type];
	if(this.keyType) {
		this.keySize = Util.getNumBytes(type);
	} else if(size>0) {		
		this.keyType = type;
		this.keySize = size;
	} else {
		Runtime.exception("key type has size 0!");
	}
	this.setRadixRange(0,this.keySize*8);
};

T.bucketSize @(private) := 16;
T.blockSize @(private) := 1024;
T.workGroupSize @(private) := 256;
T.setWorkGroupSize ::= fn(value) { reset(); this.workGroupSize = value; setMaxElements(this.maxElements); };

T.maxElements @(private) := 0;
T.maxDigit @(private) := 32;
T.minDigit @(private) := 0;
T.radixRange @(private,init) := fn() { return new Geometry.Vec2(0,32); };
T.setMaxElements ::= fn(value) { reset(); this.maxElements = roundUp(value, workGroupSize*4); };
T.setRadixRange ::= fn(lower, upper) {
	this.radixRange = new Geometry.Vec2(roundUp(lower, 4), roundUp(upper, 4));	
};

T.sortAscending @(private) := true;
T.setSortAscending ::= fn(value) { reset(); this.sortAscending = value; };

T.bindingOffset @(private) := 0;
T.setBindingOffset ::= fn(value) { reset(); this.bindingOffset = value; };
T.tmpKeyBuffer @(private) := void;
T.histogramBuffer @(private) := void;
T.blockSumBuffer @(private) := void;

T.getProfilingResults @(public) ::= fn(){
	return this.stats;
};

T.build ::= fn() {
	//outln("Building sort shader.");
	blockSize = workGroupSize * 4;
	var blockCount = (maxElements/blockSize).ceil();
	var histogramBlocks = (blockCount * bucketSize / blockSize).ceil();

  var defines = {
    "WORK_GROUP_SIZE": workGroupSize,
    "KEY_TYPE": keyType,
	  "BLOCK_COUNT": blockCount,
	  "HIST_BLOCK_COUNT": histogramBlocks,
		"SORT_ASCENDING" : sortAscending ? 1 : 0,
    "IN_KEY_BINDING": this.bindingOffset + 0,
    "OUT_KEY_BINDING": this.bindingOffset + 1,
    "HISTOGRAM_BINDING": this.bindingOffset + 2,
    "BLOCK_SUM_BINDING": this.bindingOffset + 3,
    "IN_VALUE_BINDING": this.bindingOffset + 4,
    "OUT_VALUE_BINDING": this.bindingOffset + 5,
  };	
  program = Rendering.Shader.createComputeFromFile(__DIR__ + "/shader/radix_sort.sfn", defines);
  // compile program
  renderingContext.pushAndSetShader(program);
	renderingContext.popShader();
  	
	this.tmpKeyBuffer = (new Rendering.BufferObject).allocate(keySize * maxElements).clear();
	this.histogramBuffer = (new Rendering.BufferObject).allocate(4 * blockCount * bucketSize).clear();
	this.blockSumBuffer = (new Rendering.BufferObject).allocate(4 + 4 * roundUp(histogramBlocks,4)).clear();
		
  initialized = true;
};

T.reset ::= fn() {
	if(initialized)
		unbind();
  initialized = false;
};

T.bind @(private) ::= fn(keyBuffer) {
	renderingContext.bindBuffer(keyBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+0);
	renderingContext.bindBuffer(tmpKeyBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+1);
	renderingContext.bindBuffer(histogramBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+2);
	renderingContext.bindBuffer(blockSumBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+3);
};

T.unbind @(private) ::= fn() {
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 0);
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 1);
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 2);
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 3);
};

T.sort ::= fn(keyBuffer, elements, offset=0, profiling=false) {
	if(elements <= 0)
		return;
	if(elements+offset > maxElements)
		setMaxElements(elements+offset);
	if(!initialized)
    build();
		
	var timer = new Util.Timer();
	var range = new Geometry.Vec2(radixRange.x(), radixRange.x()+4);
	var radixBits = new Geometry.Vec2(4,4);
	var blockCount = (elements/blockSize).ceil();
	var histogramBlocks = (blockCount * bucketSize / blockSize).ceil();
	
  renderingContext.pushAndSetShader(program);
	bind(keyBuffer);
	
	program.setUniform(renderingContext,'elementRange', Rendering.Uniform.VEC2I, [new Geometry.Vec2(offset, offset+elements)]);
	program.setUniform(renderingContext,'blockCount', Rendering.Uniform.INT, [blockCount]);
	program.setUniform(renderingContext,'histBlockCount', Rendering.Uniform.INT, [histogramBlocks]);
	
	if(blockCount <= 1) {
		// sort locally on GPU
		program.setUniform(renderingContext,'radixRange', Rendering.Uniform.VEC2I, [radixRange]);
		renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["localSort"]);
		renderingContext.dispatchCompute(blockCount);
		renderingContext.barrier();
	} else {
		var round = 0;
		var maxRounds = ((radixRange.y()-radixRange.x())/4).ceil();
		for(; round < maxRounds; ++round) {
			program.setUniform(renderingContext,'radixRange', Rendering.Uniform.VEC2I, [range]);
			renderingContext.bindBuffer(keyBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+round%2);
			renderingContext.bindBuffer(tmpKeyBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+1-round%2);
			blockSumBuffer.clear();
			
			// local pre-sort
			renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["localSort"]);
			renderingContext.dispatchCompute(blockCount);
			renderingContext.barrier();
				
			// compute offsets
			renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["computeHistogramAndOffsets"]);
			renderingContext.dispatchCompute(blockCount);
			renderingContext.barrier();

			// scan histogram
			renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["scanHistogram"]);
			renderingContext.dispatchCompute(histogramBlocks);
			renderingContext.barrier();
			
			// scan block sums
			renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["scanBlock"]);
			renderingContext.dispatchCompute(1);
			renderingContext.barrier();
			
			// scatter
			renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["scatter"]); 
			renderingContext.dispatchCompute(blockCount);
			renderingContext.barrier();
			
			range += radixBits;
		}

		if(round%2 == 1) {
			keyBuffer.copy(tmpKeyBuffer, offset*keySize, offset*keySize, elements*keySize);
		}
	}
	
	unbind();
	renderingContext.popShader();
		
	if(profiling) {
    renderingContext.finish();
		stats["t_reduce"] = timer.getMilliseconds();
	}
	return this;
};

T.testOrder ::= fn(keyBuffer, elements, offset=0) {
	var blockCount = (elements/blockSize).ceil();
  renderingContext.pushAndSetShader(program);
	bind(keyBuffer);
	blockSumBuffer.clear();
	program.setUniform(renderingContext,'elementRange', Rendering.Uniform.VEC2I, [new Geometry.Vec2(offset, offset+elements)]);
	
	// test order
	renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["testOrder"]);
	renderingContext.dispatchCompute(blockCount);
	renderingContext.barrier();
	
	unbind();
	renderingContext.popShader();
	
	var notOrdered = blockSumBuffer.download(1, Util.TypeConstant.UINT32)[0];
	return notOrdered == 0;
};

return T;
