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

/*! Extends a multi channel connection to receive the content and updates of a DataWrapperContainer.
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait
	\note requires the LibUtilExt/Network/MultiChannelSenderTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param DataWrapperContainer syncVars	the synced values
	\param Callable deserialize				(optional) deserialize function	*/
var t = new Std.Traits.GenericTrait('MultiChannel_SyncVarReceiver_Trait');
t.allowMultipleUses();

t.onInit += fn(connection,Number channelId, targetMap,deserialize=parseJSON){
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelReceiverTrait'));//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelSenderTrait'));	//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
	Std.Traits.requireTrait(deserialize,Traits.CallableTrait);										//!	\see	Std.Traits.CallableTrait
	
	//!	\see MultiChannelReceiverTrait
	connection.setChannelHandler(channelId,[channelId,targetMap,deserialize] => fn(channelId,targetMap,deserialize, data){
		var a = data.split("§",2);
		var key = a[0];
		var value = deserialize(a[1]);
		outln("Receive [",channelId,"] ",key," : ",value);
		targetMap.setValue(key,value,false);
	});
	connection.sendValue(channelId,'subscribe' );												//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
};
Util.Network.MultiChannel_SyncVarReceiver_Trait := t;
return t;