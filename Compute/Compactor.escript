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
T._printableName @(override) := $Compactor;

T.program @(private) := void;
T.initialized @(private) := false;

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
};

T.blockSize @(private) := 1024;
T.workGroupSize @(private) := 256;
T.setWorkGroupSize ::= fn(value) { reset(); this.workGroupSize = value; setMaxElements(this.maxElements); };

T.maxElements @(private) := 0;
T.setMaxElements ::= fn(value) { reset(); this.maxElements = roundUp(value, workGroupSize*4); };

T.bindingOffset @(private) := 0;
T.setBindingOffset ::= fn(value) { reset(); this.bindingOffset = value; };
T.tmpKeyBuffer @(private) := void;
T.histogramBuffer @(private) := void;
T.blockSumBuffer @(private) := void;

T.build ::= fn() {
	//outln("Building compaction shader.");
	blockSize = workGroupSize * 4;
	var blockCount = (maxElements/blockSize).ceil();
	var histogramBlocks = (blockCount / blockSize).ceil();

	var defines = {
		"WORK_GROUP_SIZE": workGroupSize,
		"KEY_TYPE": keyType,
		"IN_KEY_BINDING": this.bindingOffset + 0,
		"OUT_KEY_BINDING": this.bindingOffset + 1,
		"HISTOGRAM_BINDING": this.bindingOffset + 2,
		"BLOCK_SUM_BINDING": this.bindingOffset + 3,
	};
	program = Rendering.Shader.createComputeFromFile(__DIR__ + "/shader/compact.sfn", defines);
	// compile program
	renderingContext.pushAndSetShader(program);
	renderingContext.popShader();
		
	this.tmpKeyBuffer = (new Rendering.BufferObject).allocate(keySize * maxElements).clear();
	this.histogramBuffer = (new Rendering.BufferObject).allocate(4 * blockCount).clear();
	this.blockSumBuffer = (new Rendering.BufferObject).allocate(4+4 * blockCount).clear();
		
	initialized = true;
};

T.reset ::= fn() {
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

T.compact ::= fn(keyBuffer, elements, offset=0) {
	if(elements+offset > maxElements)
		setMaxElements(elements+offset);
	if(!initialized)
		build();
		
	var blockCount = (elements/blockSize).ceil();
	
	renderingContext.pushAndSetShader(program);
	bind(keyBuffer);
	
	program.setUniform(renderingContext,'elementRange', Rendering.Uniform.VEC2I, [new Geometry.Vec2(offset, offset+elements)]);
	program.setUniform(renderingContext,'blockCount', Rendering.Uniform.INT, [blockCount]);
		
	// local compact into tmpKeyBuffer
	renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["localCompact"]);
	renderingContext.dispatchCompute(blockCount);
	renderingContext.barrier();
	
	// scan histogram
	renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["scanHistogram"]);
	renderingContext.dispatchCompute(1);
	renderingContext.barrier();
		
	// global compact
	renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["compact"]); 
	renderingContext.dispatchCompute(blockCount);
	renderingContext.barrier();
		
	unbind();
	renderingContext.popShader();
	return this;
};

T.getCount ::= fn() {
	return blockSumBuffer.download(1, Util.TypeConstant.UINT32)[0];
};

return T;
