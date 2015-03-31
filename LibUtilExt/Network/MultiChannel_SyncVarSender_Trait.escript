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

/*! Extends a multi channel connection to send the content and updates of a DataWrapperContainer.
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait
	\note requires the LibUtilExt/Network/MultiChannelSenderTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param DataWrapperContainer syncVars	the synced values
	\param Callable serialize				(optional) serialization function	*/
var t = new Std.Traits.GenericTrait('MultiChannel_SyncVarSender_Trait');
t.allowMultipleUses();

t.onInit += fn(connection,Number channelId, DataWrapperContainer syncVars,serialize=fn(p){return toJSON(p,false);}){
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/NetworkServiceTrait'));		//!	\see	LibUtilExt/Network/NetworkServiceTrait
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelSenderTrait'));	//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
	Std.Traits.requireTrait(serialize,Traits.CallableTrait);										//!	\see	Std.Traits.CallableTrait
	
	var sender = [connection,channelId,serialize] => fn(connection,channelId,serialize, key,value){
		if(!connection.isOpen())																//!	\see	LibUtilExt/Network/NetworkServiceTrait
			return $REMOVE;
		connection.sendValue(channelId,key+"§"+serialize(value) );								//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
		outln("Send ["+channelId+"]" + key+" : "+serialize(value));
	};
	
	// wait for receiver to subscribe
	//! \see LibUtilExt/Network/MultiChannelReceiverTrait
	connection.setChannelHandler(channelId, [syncVars,sender] => fn(syncVars,sender, data){
		if(data!='subscribe'){
			Runtime.warn("MultiChannel_SyncVarSender_Trait received invalid data: '"+data+"'");
			return;
		}
		PADrend.message("Successfully subscribed! ");
		syncVars.onDataChanged += sender;

		// initial send
		foreach(syncVars.getValues() as var key,var value)
			sender(key,value);
		// return $REMOVE; // $REMOVE is ignored...
	});
};
Util.Network.MultiChannel_SyncVarSender_Trait := t;
return t;