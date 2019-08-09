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

T.localType @(private) := Util.TypeConstant.UINT32;
T.reduceType @(private) := "uint";
T.elementSize @(private) := Util.getNumBytes(Util.TypeConstant.UINT32);
T.setType ::= fn(type, size=0) {
	reset();
	this.reduceType = typeMap[type];
	this.localType = void;
	if(this.reduceType) {
		this.elementSize = Util.getNumBytes(type);
		this.localType = type;
	} else if(size>0) {		
		this.reduceType = type;
		this.elementSize = size;
	} else {
		Runtime.exception("type '" + reduceType + "' of size " + elementSize + " is not supported!");
	}
};

T.blockSize @(private) := 1024;
T.workGroupSize @(private) := 256;
T.setWorkGroupSize ::= fn(value) { reset(); this.workGroupSize = value; };

T.reduceFn @(private) := "max(a,b)";
T.reduceIdentity @(private) := "0";
T.setReduceFn ::= fn(fun, id) {	reset(); this.reduceFn = fun; this.reduceIdentity = id;};

T.blockBuffer @(private) := void;
T.accumBuffer @(private) := void;
T.bindingOffset @(private) := 0;
T.setBindingOffset ::= fn(value) { reset(); this.bindingOffset = value; };

T.build ::= fn() {
	//outln("Building reduction shader.");
  var defines = {
    "REDUCE_WORK_GROUP_SIZE": workGroupSize,
    "REDUCE_T": reduceType,
    "REDUCE_FN(a,b)": reduceFn,
    "REDUCE_IDENTITY": reduceIdentity,
    "STANDALONE" : 1,
    "VALUE_BINDING": this.bindingOffset + 0,
    "BLOCK_BINDING": this.bindingOffset + 1,
  };
  program = Rendering.Shader.createComputeFromFile(__DIR__ + "/shader/reduce.sfn", defines);
  // compile program
  renderingContext.pushAndSetShader(program);
	renderingContext.popShader();
  
	this.blockBuffer = (new Rendering.BufferObject).allocate(elementSize * workGroupSize).clear();
	this.accumBuffer = (new Rendering.BufferObject).allocate(elementSize).clear();
  initialized = true;
};

T.reset ::= fn() {
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 0);
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 1);
  initialized = false;
};

T.reduce ::= fn(valueBuffer, elements, offset=0) {
	if(!initialized)
    build();
	if(elements == 0)
		return this;
	
	// set parameters
  var reduceBlocks = [(elements/(workGroupSize*4)).ceil(), workGroupSize].min();
	var blockSize = (roundUp(elements, workGroupSize * reduceBlocks) / reduceBlocks).floor();
	program.setUniform(renderingContext,'elementRange', Rendering.Uniform.VEC2I, [new Geometry.Vec2(offset, offset+elements)]);
  program.setUniform(renderingContext,'blockSize', Rendering.Uniform.INT, [blockSize]);
	
	// bind
  renderingContext.pushAndSetShader(program);
	renderingContext.bindBuffer(valueBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+0);
	renderingContext.bindBuffer(blockBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+1);
  
	// reduce elements
  renderingContext.dispatchCompute(reduceBlocks);
	renderingContext.barrier();
	
	// bind
	renderingContext.bindBuffer(blockBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+0);
	renderingContext.bindBuffer(accumBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset+1);
	
	// update parameters
	program.setUniform(renderingContext,'elementRange', Rendering.Uniform.VEC2I, [new Geometry.Vec2(0, reduceBlocks)]);
  program.setUniform(renderingContext,'blockSize', Rendering.Uniform.INT, [workGroupSize]);
	
	// reduce block
  renderingContext.dispatchCompute(1);
	renderingContext.barrier();
	
	// unbind
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 0);
	renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, this.bindingOffset + 1);
	renderingContext.popShader();
		
	return this;
};

T.getValue ::= fn(type=localType, offset=0) {
	if(type)
		return accumBuffer.download(1, type, offset)[0];
	else
		Runtime.exception("Cannot download element of type: " + reduceType);
};

return T;