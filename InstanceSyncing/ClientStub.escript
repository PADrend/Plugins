/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var T = new Type;
Std.Traits.addTrait(T, Std.module('LibUtilExt/Network/NetworkServiceTrait') ); //! \see NetworkServiceTrait

T.mcConnection @(private) := void;
T.onClose @(init) := MultiProcedure;		// called eventually when the internal connection is closed
T.openStatus @(private) := true;

T._constructor ::=  fn(_mcConnection){
	Std.Traits.requireTrait(_mcConnection,Std.module('LibUtilExt/Network/MultiChannelSenderTrait'));		//! \see MultiChannelSenderTrait
	Std.Traits.requireTrait(_mcConnection,Std.module('LibUtilExt/Network/MultiChannelReceiverTrait'));		//! \see MultiChannelReceiverTrait
	this.mcConnection = _mcConnection;
};

T.getMCConnection ::=	fn(){	return mcConnection;	};

//! \see NetworkServiceTrait
T.close @(override) ::= fn(){
	if(this.openStatus){
		this.openStatus = false;
		if(this.mcConnection.isOpen())
			this.mcConnection.close();
		this.onClose();
		this.onClose.clear();
	}
};

//! \see NetworkServiceTrait
T.isOpen @(override) ::= fn(){
	return this.openStatus;
};

//! \see NetworkServiceTrait
T.execute @(override) ::= fn(){
	if(this.mcConnection.isOpen()){
		this.mcConnection.execute();
	}else{
		this.close();
	}
};

return T;
