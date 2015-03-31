/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! Sets up a channel for RCP (server).
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param function							the function to be called
	\param Callable deserialize				(optional) deserialize function	*/
var t = new Std.Traits.GenericTrait('MultiChannel_RemoteProcedureServer_Trait');
t.allowMultipleUses();

t.onInit += fn(connection,Number channelId, fun, deserialize=parseJSON){
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
	Std.Traits.requireTrait(fun,Traits.CallableTrait);													//!	\see	Std.Traits.CallableTrait
	
	//!	\see LibUtilExt/Network/MultiChannelReceiverTrait
	connection.setChannelHandler(channelId, [fun,deserialize] => fn(fun,deserialize, data){
		fun(deserialize(data)...);
	});
};
Util.Network.MultiChannel_RemoteProcedureServer_Trait := t;
return t;