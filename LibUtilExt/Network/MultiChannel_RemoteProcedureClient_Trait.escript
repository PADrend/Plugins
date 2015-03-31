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

/*! Sets up a channel for RCP (client).
	\note requires the 'LibUtilExt/Network/MultiChannelSenderTrait' and the LibUtilExt/Network/NetworkServiceTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param MultiFunction rpcFunction		A (empty) function that is set up as rcp-proxy
	\param Callable serialize				(optional) serialization function	*/
var t = new Std.Traits.GenericTrait('MultiChannel_RemoteProcedureClient_Trait');
t.allowMultipleUses();

t.onInit += fn(connection,Number channelId, multiFun, serialize=fn(p){return toJSON(p,false);}){
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/MultiChannelSenderTrait'));		//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
	Std.Traits.requireTrait(connection, Std.module('LibUtilExt/Network/NetworkServiceTrait'));			//!	\see	LibUtilExt/Network/NetworkServiceTrait
	Std.Traits.requireTrait(multiFun,Traits.CallableTrait);												//!	\see	Std.Traits.CallableTrait

	multiFun += [connection,channelId,serialize]=>fn(connection,channelId,serialize, p...){
		if(!connection.isOpen())																	//!	\see	LibUtilExt/Network/NetworkServiceTrait
			return $REMOVE;
		connection.sendValue(channelId,serialize(p) );
	};
};
Util.Network.MultiChannel_RemoteProcedureClient_Trait := t;
return t;