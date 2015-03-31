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
/****
 **	[Plugin:Tests] Tests/AutomatedTests/OpenCL.escript
 **/

if(!Rendering.isSet($CL))
	return [];

GLOBALS.CL := Rendering.CL;
static roundUp = fn(x, y) { return ((x + y - 1) / y).floor() * y; };

var AutomatedTest = Std.module('Tests/AutomatedTest');

var tests = [];

tests += new AutomatedTest("OpenCL: availability",fn(){
	var cpu_available = false;
	var gpu_available = false;
	var platforms = CL.Platform.get();
	outln("Available OpenCL Platforms:");
	foreach(platforms as var pf) {
		var devices = pf.getDevices();
		outln("  ",pf.getName(), " (", devices.size(), " Devices):");
		foreach(devices as var dev) {
			outln("    ",dev.getName());
			if(dev.getType() == CL.TYPE_CPU) {
				cpu_available = true;
			}
			if(dev.getType() == CL.TYPE_GPU) {
				gpu_available = true;
			}
		}
	}
	
	addResult("CPU available",cpu_available);
	addResult("GPU available",gpu_available);
});


tests += new AutomatedTest("OpenCL: PrefixSum (GPU)",fn(){
	static Scanner = Std.module('LibRenderingExt/CL/Scanner');
	
	{ // GPU
		var context = new CL.Context(CL.TYPE_GPU, false);
		var device = context.getDevices()[0];
		var queue = new CL.CommandQueue(context, device, false, true);
		
		var elements = 1024;
		var buffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.INT32);		
		var bufferAcc = new CL.BufferAccessor(buffer, queue);
		
		var prefixSums = [];
		var accumulator = 0;
		bufferAcc.begin();
		for(var i=0; i<elements; ++i) {
			var value = Rand.uniform(5,100).round();
			bufferAcc.write(value, Util.TypeConstant.INT32);
			prefixSums += accumulator;
			accumulator += value;
		}
		bufferAcc.end();
		
		var scanner = new Scanner(context, device, queue);
		var result = scanner.build();
		if(result) {
			scanner.scan(buffer, buffer, elements, true);
			queue.finish();
			bufferAcc.begin();
			var resultValues = bufferAcc.read(Util.TypeConstant.INT32, elements);
			bufferAcc.end();
			for(var i=0; i<elements; ++i) {
				result = result && (prefixSums[i] == resultValues[i]);
			}
			out("PrefixSum (GPU)");
			print_r(scanner.getProfilingResults());
			outln();
		}				
		addResult("Simple Test",result);
	}
});

tests += new AutomatedTest("OpenCL: PrefixSum (CPU)",fn(){
	static Scanner = Std.module('LibRenderingExt/CL/Scanner');	
	{ // CPU
		var context = new CL.Context(CL.TYPE_CPU, false);
		var device = context.getDevices()[0];
		var queue = new CL.CommandQueue(context, device, false, true);
		
		var elements = 1024;
		var buffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.INT32);		
		var bufferAcc = new CL.BufferAccessor(buffer, queue);
		
		var prefixSums = [];
		var accumulator = 0;
		bufferAcc.begin();
		for(var i=0; i<elements; ++i) {
			var value = Rand.uniform(5,100).round();
			bufferAcc.write(value, Util.TypeConstant.INT32);
			prefixSums += accumulator;
			accumulator += value;
		}
		bufferAcc.end();
		
		var scanner = new Scanner(context, device, queue);
		var result = scanner.build();
		if(result) {
			scanner.scan(buffer, buffer, elements, true);
			queue.finish();
			bufferAcc.begin();
			var resultValues = bufferAcc.read(Util.TypeConstant.INT32, elements);
			bufferAcc.end();
			for(var i=0; i<elements; ++i) {
				result = result && (prefixSums[i] == resultValues[i]);
			}
			out("PrefixSum (CPU)");
			print_r(scanner.getProfilingResults());
			outln();
		}				
		addResult("Simple Test",result);
	}
});


tests += new AutomatedTest("OpenCL: Reduce (GPU)",fn(){
	static Reduce = Std.module('LibRenderingExt/CL/Reduce');	
	{ // GPU
		var context = new CL.Context(CL.TYPE_GPU);
		var device = context.getDevices()[0];
		var queue = new CL.CommandQueue(context, device, false, true);
		
		var elements = 1024;
		var buffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.FLOAT);			
		var output = new CL.Buffer(context, CL.READ_WRITE, 1, Util.TypeConstant.FLOAT);	
		var bufferAcc = new CL.BufferAccessor(buffer, queue);
		var outputAcc = new CL.BufferAccessor(output, queue);
		
		var sum = 0;
		var max = 0;
		var min = 9999;
		bufferAcc.begin();
		for(var i=0; i<elements; ++i) {
			var value = Rand.uniform(0,100);
			bufferAcc.write(value, Util.TypeConstant.FLOAT);
			sum += value;
			max = [max, value].max();
			min = [min, value].min();
		}
		bufferAcc.end();
		
		var reduce = new Reduce(context, device, queue);
		reduce.setType(Util.TypeConstant.FLOAT);
		
		{ // sum
			var result = reduce.build();
			if(result) {
				reduce.reduce(buffer, output, elements, 0, 0, true);
				queue.finish();
				outputAcc.begin();
				var resultValue = outputAcc.read(Util.TypeConstant.FLOAT);
				outputAcc.end();
				result = resultValue ~= sum;
				out("Sum (GPU)");
				print_r(reduce.getProfilingResults());
				outln();
			}
			addResult("Sum",result);
		}
		{ // max
			reduce.setReduceFn("max(v1,v2)");
			var result = reduce.build();
			if(result) {
				reduce.reduce(buffer, output, elements, 0, 0, true);
				queue.finish();
				outputAcc.begin();
				var resultValue = outputAcc.read(Util.TypeConstant.FLOAT);
				outputAcc.end();
				result = resultValue ~= max;
				out("Max (GPU)");
				print_r(reduce.getProfilingResults());
				outln();
			}				
			addResult("Max",result);
		}
		{ // min
			reduce.setReduceFn("min(v1,v2)");
			reduce.setIdentity("INFINITY");
			var result = reduce.build();
			if(result) {
				reduce.reduce(buffer, output, elements, 0, 0, true);
				queue.finish();
				outputAcc.begin();
				var resultValue = outputAcc.read(Util.TypeConstant.FLOAT);
				outputAcc.end();
				result = resultValue ~= min;
				out("Min (GPU)");
				print_r(reduce.getProfilingResults());
				outln();
			}				
			addResult("Min",result);
		}
	}
});

tests += new AutomatedTest("OpenCL: Reduce (CPU)",fn(){
	static Reduce = Std.module('LibRenderingExt/CL/Reduce');
	{ // CPU
		var context = new CL.Context(CL.TYPE_CPU);
		var device = context.getDevices()[0];
		var queue = new CL.CommandQueue(context, device, false, true);
		
		var elements = 1024;
		var buffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.FLOAT);			
		var output = new CL.Buffer(context, CL.READ_WRITE, 1, Util.TypeConstant.FLOAT);	
		var bufferAcc = new CL.BufferAccessor(buffer, queue);
		var outputAcc = new CL.BufferAccessor(output, queue);
		
		var sum = 0;
		var max = 0;
		var min = 9999;
		bufferAcc.begin();
		for(var i=0; i<elements; ++i) {
			var value = Rand.uniform(0,100);
			bufferAcc.write(value, Util.TypeConstant.FLOAT);
			sum += value;
			max = [max, value].max();
			min = [min, value].min();
		}
		bufferAcc.end();
				
		var reduce = new Reduce(context, device, queue);
		reduce.setType(Util.TypeConstant.FLOAT);
		
		{ // sum
			var result = reduce.build();
			if(result) {
				reduce.reduce(buffer, output, elements, 0, 0, true);
				queue.finish();
				outputAcc.begin();
				var resultValue = outputAcc.read(Util.TypeConstant.FLOAT);
				outputAcc.end();
				result = resultValue ~= sum;
				out("Sum (CPU)");
				print_r(reduce.getProfilingResults());
				outln();
			}
			addResult("Sum",result);
		}
		{ // max
			reduce.setReduceFn("max(v1,v2)");
			var result = reduce.build();
			if(result) {
				reduce.reduce(buffer, output, elements, 0, 0, true);
				queue.finish();
				outputAcc.begin();
				var resultValue = outputAcc.read(Util.TypeConstant.FLOAT);
				outputAcc.end();
				result = resultValue ~= max;
				out("Max (CPU)");
				print_r(reduce.getProfilingResults());
				outln();
			}				
			addResult("Max",result);
		}
		{ // min
			reduce.setReduceFn("min(v1,v2)");
			reduce.setIdentity("INFINITY");
			var result = reduce.build();
			if(result) {
				reduce.reduce(buffer, output, elements, 0, 0, true);
				queue.finish();
				outputAcc.begin();
				var resultValue = outputAcc.read(Util.TypeConstant.FLOAT);
				outputAcc.end();
				result = resultValue ~= min;
				out("Min (CPU)");
				print_r(reduce.getProfilingResults());
				outln();
			}				
			addResult("Min",result);
		}
	}
});

tests += new AutomatedTest("OpenCL: Sort (GPU)",fn(){
	var RadixSort = Std.module('LibRenderingExt/CL/RadixSort');
	
	{ // GPU
		var context = new CL.Context(CL.TYPE_GPU, false);
		var device = context.getDevices()[0];
		var queue = new CL.CommandQueue(context, device, false, true);
		
		{ // Reduce
			var elements = 1024;
			var sorter = new RadixSort(context, device, queue);
			var result = sorter.build();
			if(result) {			
				var inBuffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.INT32);		
				var inBufferAcc = new CL.BufferAccessor(inBuffer, queue);				
				var tileSize = sorter.getScatterWorkGroupSize() * sorter.getScatterWorkScale();
				var radix = sorter.getRadix();
				var firstBit = 5;
				var len = ((elements + sorter.getScanBlocks() - 1) / sorter.getScanBlocks()).floor();
				len = roundUp(len, tileSize);
				var blocks = sorter.getBlocks(elements, len);
				var histogram = [];
				for(var i=0; i<elements; ++i)
					histogram[i] = 0;
				inBufferAcc.begin();
				for(var i=0; i<elements; ++i) {
					var value = Rand.uniform(0,1000).round();
					inBufferAcc.write(value, Util.TypeConstant.INT32);
					var bucket = (value / 2.pow(firstBit)).floor() % radix; 
					histogram[(radix * (i/len).floor()).floor() + bucket]++;
				}
				inBufferAcc.end();
				var outBuffer = new CL.Buffer(context, CL.READ_WRITE, radix*blocks, Util.TypeConstant.UINT32);	
				var outBufferAcc = new CL.BufferAccessor(outBuffer, queue);
				sorter.reduce(outBuffer, inBuffer, len, elements, firstBit, []);
				queue.finish();				
				outBufferAcc.begin();
				var resultValues = outBufferAcc.read(Util.TypeConstant.UINT32, radix*blocks);
				outBufferAcc.end();				
				for(var i=0; i<radix*blocks; ++i) {
					result = result && (resultValues[i] == histogram[i]);
				}
			}
			addResult("Reduce (GPU)",result);
		}
		
		{ // Scan
			var sorter = new RadixSort(context, device, queue);
			var result = sorter.build();
			if(result) {	
				var blocks = 32;		
				var radix = sorter.getRadix();
				var size = radix * sorter.getScanBlocks();
				
				var histogram = new CL.Buffer(context, CL.READ_WRITE, size, Util.TypeConstant.UINT32);		
				var histogramAcc = new CL.BufferAccessor(histogram, queue);
				
				var host = [];
				histogramAcc.begin();
				for(var i=0; i<size; ++i) {
					host[i] = Rand.uniform(1,1000).round();
					histogramAcc.write(host[i], Util.TypeConstant.UINT32);
				}
				histogramAcc.end();
				
				var sum = 0;
				for(var i=0; i < radix * blocks; ++i) {
					var digit = (i/blocks).floor();
					var block = i % blocks;
					var addr = block * radix + digit;
					var next = host[addr];
					host[addr] = sum;
					sum += next;
				}
				
				sorter.scan(histogram, blocks, []);
				queue.finish();				
				histogramAcc.begin();
				var resultValues = histogramAcc.read(Util.TypeConstant.UINT32, radix*blocks);
				histogramAcc.end();				
				for(var i=0; i<radix*blocks; ++i) {
					result = result && (resultValues[i] == host[i]);
				}
			}
			addResult("Scan (GPU)",result);
		}
		
		{ // Scatter
			var elements = 1024;
			var sorter = new RadixSort(context, device, queue);
			sorter.setKeyType(Util.TypeConstant.UINT16);
			var result = sorter.build();
			if(result) {				
				var tileSize = sorter.getScatterWorkGroupSize() * sorter.getScatterWorkScale();
				var radix = sorter.getRadix();
				var firstBit = 5;
				
				var len = ((elements + sorter.getScanBlocks() - 1) / sorter.getScanBlocks()).floor();
				len = roundUp(len, tileSize);
				var blocks = sorter.getBlocks(elements, len);				
				var hostKeys = [];
				var offsets = [];
				var hostOrder = [];
				for(var i=0; i<elements; ++i) {
					hostKeys[i] = Rand.uniform(0,1000).round();
					hostOrder[i] = i;
				}
				for(var i=0; i<blocks*radix; ++i) 
					offsets[i] = 0;
				for(var i=0; i<blocks; ++i) {
					for(var j=i*len; j < [(i+1)*len, elements].min(); ++j) {
						var bits = (hostKeys[j] / 2.pow(firstBit)).floor() & (radix-1);
						offsets[i*radix+bits]++;
					}
				}
				var lastOffset = 0;
				for(var r=0; r<radix; ++r) {				
					for(var i=0; i<blocks; ++i) { 
						var next = offsets[i*radix+r];
						offsets[i*radix+r] = lastOffset;
						lastOffset += next;
					}
				}
				
				var inKeys = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.UINT16);		
				var inKeysAcc = new CL.BufferAccessor(inKeys, queue);	
				var outKeys = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.UINT16);		
				var outKeysAcc = new CL.BufferAccessor(outKeys, queue);	
				var histogram = new CL.Buffer(context, CL.READ_WRITE, blocks*radix, Util.TypeConstant.UINT32);		
				var histogramAcc = new CL.BufferAccessor(histogram, queue);					
				
				inKeysAcc.begin();
				inKeysAcc.write(hostKeys, Util.TypeConstant.UINT16);
				inKeysAcc.end();				
				histogramAcc.begin();
				histogramAcc.write(offsets, Util.TypeConstant.UINT32);
				histogramAcc.end();		
				
				hostOrder.sort([hostKeys, firstBit, radix] => fn(keys, firstBit, radix, a, b) {
					var ea = (keys[a] / 2.pow(firstBit)).floor() & (radix - 1);
					var eb = (keys[b] / 2.pow(firstBit)).floor() & (radix - 1);
					return ea < eb || (ea == eb && a < b);
				});
				
				var sortedKeys = [];
				for(var i=0; i<elements; ++i) 
					sortedKeys += hostKeys[hostOrder[i]];
				
				sorter.scatter(outKeys, void, inKeys, void, histogram, len, elements, firstBit, []);
				queue.finish();		
						
				outKeysAcc.begin();
				var resultKeys = outKeysAcc.read(Util.TypeConstant.UINT16, elements);
				outKeysAcc.end();				
				for(var i=0; i<elements; ++i) {
					result = result && (resultKeys[i] == sortedKeys[i]);
				}
			}
			addResult("Scatter (GPU)",result);
		}

		{ // Sort
			var elements = 1024;
			var buffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.INT32);		
			var bufferAcc = new CL.BufferAccessor(buffer, queue);
			
			var values = [];
			bufferAcc.begin();
			for(var i=0; i<elements; ++i) {
				var value = Rand.uniform(0,100).round();
				bufferAcc.write(value, Util.TypeConstant.INT32);
				values += value;
			}
			bufferAcc.end();
			values.sort();
			
			var sorter = new RadixSort(context, device, queue);
			var result = sorter.build();
			if(result) {
				sorter.sort(buffer, void, elements, 0, true);
				queue.finish();
				bufferAcc.begin();
				var resultValues = bufferAcc.read(Util.TypeConstant.INT32, elements);
				bufferAcc.end();
				for(var i=0; i<elements; ++i) {
					result = result && (values[i] == resultValues[i]);
				}
				out("RadixSort (GPU, Keys only)");
				print_r(sorter.getProfilingResults());
			}				
			addResult("RadixSort (GPU, Keys only)",result);
		}

		{ // Sort		
			var elements = 1024;			
			var sorter = new RadixSort(context, device, queue);
			sorter.setValueType("float4", 4*Util.getNumBytes(Util.TypeConstant.FLOAT));
			var result = sorter.build();
			if(result) {			
				var keysBuffer = new CL.Buffer(context, CL.READ_WRITE, elements, Util.TypeConstant.INT32);		
				var keysBufferAcc = new CL.BufferAccessor(keysBuffer, queue);
				var valuesBuffer = new CL.Buffer(context, CL.READ_WRITE, elements*4, Util.TypeConstant.FLOAT);		
				var valuesBufferAcc = new CL.BufferAccessor(valuesBuffer, queue);
				
				var keyValues = [];
				keysBufferAcc.begin();
				valuesBufferAcc.begin();
				for(var i=0; i<elements; ++i) {
					var key = Rand.uniform(0,100000).round();
					var value = new Geometry.Vec4(Rand.uniform(0,1), Rand.uniform(0,1), Rand.uniform(0,1), Rand.uniform(0,1));
					keysBufferAcc.write(key, Util.TypeConstant.INT32);
					valuesBufferAcc.write(value);
					keyValues += [key, value, i];
				}
				valuesBufferAcc.end();
				keysBufferAcc.end();
				keyValues.sort(fn(a, b) {
					return a[0] < b[0] || (a[0] == b[0] && a[2] < b[2]);
				});
				
				sorter.sort(keysBuffer, valuesBuffer, elements, 0, true);
				queue.finish();
				keysBufferAcc.begin();
				valuesBufferAcc.begin();
				outln();
				for(var i=0; i<elements; ++i) {
					var key = keysBufferAcc.read(Util.TypeConstant.INT32);
					var value = valuesBufferAcc.readVec4();
					var orig = keyValues[i];				
					result = result && (orig[0] == key && orig[1].x() ~= value.x() && orig[1].y() ~= value.y() && orig[1].z() ~= value.z() && orig[1].w() ~= value.w());
				}
				valuesBufferAcc.end();
				keysBufferAcc.end();
				out("RadixSort (GPU, Keys+Values)");
				print_r(sorter.getProfilingResults());
			}				
			addResult("RadixSort (GPU, Keys+Values)",result);
		}
	}
});

return tests;
