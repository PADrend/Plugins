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
static T = new Type();

T.fileLocator @(private, init) := fn() { return (new Util.FileLocator).setSearchPaths([
      "./build/",
      "./bin/",
      "./lib/",
      "/usr/lib/",
      "/usr/local/lib/",
      "C:/Program Files (x86)/PADrendComplete/bin",
      "C:/Program Files (x86)/PADrendComplete/lib"
  ]);
};

T.osExtension @(private, init) := fn() {
  switch(getOS()) {
    case "WINDOWS":
      return ".dll";
    case "MAC OS":
      return ".dylib";
    case "LINUX":
    case "UNIX":
      return ".so";
    default:
      throw new Exception("Unknown Operating system!");
  };
};

T.addSearchPath ::= fn(path) {
  this.fileLocator.addSearchPath(path);
};

T.loadLibary ::= fn(name) {
  var fileName = name + osExtension;
  var lib = fileLocator.locateFile(fileName);
  if(!lib) {
    outln("Could not find library: ", fileName);
    return false;
  } 
  outln(lib.getPath());
  return Util.loadELibrary(lib.getPath());
};

return T;