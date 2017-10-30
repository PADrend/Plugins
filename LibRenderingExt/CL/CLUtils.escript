/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017 Sascha Brandt <myeti@mail.upb.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static CL = Rendering.CL;
static CLUtils = new Namespace;

CLUtils.UInt := new Type();
CLUtils.UInt.value := 0;
CLUtils.UInt._constructor ::= fn(val=0) { this.value = val; }; 

CLUtils.LocalBuffer := new Type();
CLUtils.LocalBuffer.size := 0;
CLUtils.LocalBuffer._constructor ::= fn(s=0) { this.size = s; }; 

CLUtils.roundUp := fn(x, y) { return ((x + y - 1) / y).floor() * y; };

CLUtils.createSharedVBO := fn(context, Rendering.Mesh mesh) {
  //mesh._upload(); // ensure that data is on GPU
  var vbo = new Rendering.BufferObject(); // create temporary buffer object
  mesh._swapVertexBuffer(vbo); // swap valid vertex buffer object with empty buffer object
  var cl_vbo = new CL.Buffer(context, CL.READ_WRITE, vbo); // bind vertex buffer object to OpenCL buffer
  mesh._swapVertexBuffer(vbo); // swap back buffer objects	
  return cl_vbo;
};

CLUtils.createSharedIBO := fn(context, Rendering.Mesh mesh) {
  //mesh._upload(); // ensure that data is on GPU
  var ibo = new Rendering.BufferObject(); // create temporary buffer object
  mesh._swapIndexBuffer(ibo); // swap valid index buffer object with empty buffer object
  var cl_ibo = new CL.Buffer(context, CL.READ_WRITE, ibo); // bind index buffer object to OpenCL buffer
  mesh._swapIndexBuffer(ibo); // swap back buffer objects	
  return cl_ibo;
};

CLUtils.execute := fn(queue, program, workGroupSize, kernel, elements, glLock, params...) {
  if(!(kernel ---|> CL.Kernel))
    kernel = new CL.Kernel(program, kernel);
  var threadCount = CLUtils.roundUp(elements, workGroupSize);
  var event = new CL.Event();
  if(!glLock.empty())
    queue.acquireGLObjects(glLock);
  for(var i=0; i<params.count(); ++i) {
    if(params[i] ---|> Geometry.Vec3) 
      assert(kernel.setArg(i, params[i], Util.TypeConstant.FLOAT));
    else if(params[i] ---|> Number) 
      assert(kernel.setArg(i, params[i], Util.TypeConstant.FLOAT));
    else if(params[i] ---|> CLUtils.UInt)
      assert(kernel.setArg(i, params[i].value, Util.TypeConstant.UINT32));
    else if(params[i] ---|> CLUtils.LocalBuffer)
      assert(kernel.setArgSize(i, params[i].size));
    else
      assert(kernel.setArg(i, params[i]));
  } 
  assert(queue.execute(kernel, [], [threadCount], [workGroupSize], [], event));
  if(!glLock.empty())
    queue.releaseGLObjects(glLock);
  queue.barrier();
  return event;
};


CLUtils.executeSingle := fn(queue, program, kernel, glLock, params...) {
  return CLUtils.execute(queue, program, 1, kernel, 1, glLock, params...);
};

CLUtils.readBuffer := fn(queue, buffer, type, values=0, offset=0) {
  queue.finish();
  var acc = new CL.BufferAccessor(buffer, queue);
  acc.begin(CL.READ_ONLY);
  if(offset>0)
    acc.setCursor(offset*Util.getNumBytes(type));
  var result = acc.read(type, values);
  acc.end();
  return result;
};

CLUtils.readVec3Buffer := fn(queue, buffer, type, values=0) {
  queue.barrier();
  var acc = new CL.BufferAccessor(buffer, queue);
  acc.begin(CL.READ_ONLY);
  var result = acc.readVec3(type, values);
  acc.end();
  return result;
};

CLUtils.readVec2Buffer := fn(queue, buffer, type, values=0) {
  queue.barrier();
  var acc = new CL.BufferAccessor(buffer, queue);
  acc.begin(CL.READ_ONLY);
  var result = acc.readVec2(type, values);
  acc.end();
  return result;
};

CLUtils.writeBuffer := fn(queue, buffer, type, values) {
  queue.barrier();
  var acc = new CL.BufferAccessor(buffer, queue);
  acc.begin(CL.WRITE_ONLY);
  acc.write(values, type);
  acc.end();
};

CLUtils.printBufferIndirect := fn(queue, name, idBuf, buffer, size, padding=3, offset=0) {
  var ids = CLUtils.readBuffer(queue, idBuf, Util.TypeConstant.UINT32, size, offset);
  var values = [];
  
  var acc = new CL.BufferAccessor(buffer, queue);
  acc.begin(CL.READ_ONLY);
  foreach(ids as var id) {
    if(id < 0xffffffff) {
      acc.setCursor(id*Util.getNumBytes(Util.TypeConstant.UINT32));
      values += acc.read(Util.TypeConstant.UINT32);
    }
  }
  acc.end();
  
  outln(name, ": [", values.map([padding]=>fn(padding,i,v){ return v < 0xffffffff ? v.format(0,false,padding,' ') : (" "*padding); }).implode(","), "]");
};

CLUtils.printBufferCompact := fn(queue, name, buffer, size, padding=3, offset=0) {
  var values = CLUtils.readBuffer(queue, buffer, Util.TypeConstant.UINT32, size, offset);
  var invCount = 0;
  var filtered = [];
  for(var i=0; i<values.count(); ++i) {
    if(values[i] < 0xffffffff) {
      if(i>0 && values[i-1] >= 0xffffffff) {
        filtered += invCount.format(0,false,padding-1,' ') + "X";
        invCount = 0;
      } 
      filtered += values[i].format(0,false,padding,' ');
    } else {
      ++invCount;
    }
  }
  if(invCount > 0)
    filtered += invCount.format(0,false,padding-1,' ') + "X";
  outln(name, ": [", filtered.implode(","), "]");
};

CLUtils.printBufferValid := fn(queue, name, buffer, size, padding=3, offset=0) {
  var values = CLUtils.readBuffer(queue, buffer, Util.TypeConstant.UINT32, size, offset);
  var keys = [];
  values.map([keys] => fn(keys,i,v) { if(v < 0xffffffff) keys += i; return v;});
  values.filter(fn(v) { return v < 0xffffffff; });
  outln(name, ": [", keys.map([padding]=>fn(padding,i,v){ return v.format(0,false,padding,' '); }).implode(","), "]");
  outln("".fillUp(name.length()), ": [", values.map([padding]=>fn(padding,i,v){ return v.format(0,false,padding,' '); }).implode(","), "]");
};

CLUtils.printBuffer := fn(queue, name, buffer, size, padding=3, offset=0) {
  var values = CLUtils.readBuffer(queue, buffer, Util.TypeConstant.UINT32, size, offset);
  outln(name, ": [", values.map([padding]=>fn(padding,i,v){ return v < 0xffffffff ? v.format(0,false,padding,' ') : (" "*padding); }).implode(","), "]");
};

CLUtils.printFloatBuffer := fn(queue, name, buffer, size, type=Util.TypeConstant.UINT32, padding=3) {
  var values = CLUtils.readBuffer(queue, buffer, Util.TypeConstant.FLOAT, size);
  outln(name, ": [", values.implode(","), "]");
};

CLUtils.printFloatBufferNonZero := fn(queue, name, buffer, size, type=Util.TypeConstant.UINT32, padding=3) {
  var values = CLUtils.readBuffer(queue, buffer, Util.TypeConstant.FLOAT, size);
  values.filter(fn(v) { return !(v ~= 0); });
  outln(name, ": [", values.implode(","), "]");
};

return CLUtils;