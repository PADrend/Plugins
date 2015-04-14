/****
 **	[Plugin:Tests] Tests/AutomatedTests/Network.escript
 **/

var AutomatedTest = Std.require('Tests/AutomatedTest');

var tests = [];

tests += new AutomatedTest("TCP Network Test",fn(){
	var services = new (Std.require('LibUtilExt/Network/ServiceBundle'));

	try{
		var tcpServer = new (Std.require('LibUtilExt/Network/ExtTCPServer'))(54321);
		services += tcpServer;

		static ExtTCPConnection = Std.require('LibUtilExt/Network/ExtTCPConnection');
		static MultiChannelTCPConnectionTrait = Std.require('LibUtilExt/Network/MultiChannelTCPConnectionTrait');
		
		tcpServer.onConnect += [services] => this->fn(services, ExtTCPConnection newConnection){
			// setup multi channel connection
			//! \see MultiChannelTCPConnectionTrait
			Traits.addTrait(newConnection, MultiChannelTCPConnectionTrait); 
			services += newConnection;
		};
		// client 
		var clientConnection = ExtTCPConnection.connect("127.0.0.1",54321);
		services += clientConnection;
		
		//! \see MultiChannelTCPConnectionTrait	
		Traits.addTrait(clientConnection, MultiChannelTCPConnectionTrait);

		services.close();

	}catch(e){
		services.close();
		services.execute();
		throw(e);
	}

	// todo!!!!!!!!!!!!!!!!!!!
	return true;
//	addResult("Part 1",true);
//	addResult("Part 2",true);
	
});

// -----------------------------------------------------------------------------------------------
tests += new AutomatedTest("UDP Network Test",fn(){
	{
		var services = new (Std.require('LibUtilExt/Network/ServiceBundle'));
	
		try{
			var ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
			var UDPAutoRegisterTrait = Std.require('LibUtilExt/Network/UDPAutoRegisterTrait');
			var UDPMultiChannelReceiverTrait = Std.require('LibUtilExt/Network/UDPMultiChannelReceiverTrait');
	
			var udpSender = new ExtUDPSocket(54321);
			services += udpSender;
			
			Traits.addTrait(udpSender, Std.require('LibUtilExt/Network/UDPAutoTargetResponderTrait'));	//!		\see UDPAutoTargetResponderTrait
	//		Traits.addTrait(udpSender, Std.require('LibUtilExt/Network/UDPMultiChannelSenderTrait'));	//!		\see UDPMultiChannelSenderTrait
			
			for(var i=0;i<5;++i){
				var udpReceiver = new ExtUDPSocket;
				Traits.addTrait(udpReceiver,UDPAutoRegisterTrait,"127.0.0.1",54321);	//! \see UDPAutoRegisterTrait
	//			Traits.addTrait(udpReceiver,UDPMultiChannelReceiverTrait);				//! \see UDPMultiChannelReceiverTrait
				services += udpReceiver;
	
	//			udpReceiver.setChannelHandler(0x01,[i]=>fn(nr, value){				outln("Received: ",nr,":",value);			});
				udpReceiver.onDataReceived += [i]=>fn(nr, data){				outln("Received: ",nr,":[",data.host+":"+data.port,":",data.data,"]");			};
				
			}
		
	
			var t = Util.Timer.now()+1;
			
			while(Util.Timer.now()<t){		
	//			udpSender.sendValue(0x01,"foo");
				udpSender.sendString("foo");
				Util.sleep(100);
	
				services.execute();
			}
	
	
			services.close();
	
		}catch(e){
			services.close();
			services.execute();
			throw(e);
		}	
		addResult("Part 1",true);
	}
	
	{
		var services = new (Std.require('LibUtilExt/Network/ServiceBundle'));
	
		try{
			var ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
			var UDPAutoRegisterTrait = Std.require('LibUtilExt/Network/UDPAutoRegisterTrait');
			var UDPMultiChannelReceiverTrait = Std.require('LibUtilExt/Network/UDPMultiChannelReceiverTrait');
	
			var udpSender = new ExtUDPSocket(0);
			services += udpSender;
			
			Traits.addTrait(udpSender, Std.require('LibUtilExt/Network/UDPAutoTargetResponderTrait'));	//!		\see UDPAutoTargetResponderTrait
	//		Traits.addTrait(udpSender, Std.require('LibUtilExt/Network/UDPMultiChannelSenderTrait'));	//!		\see UDPMultiChannelSenderTrait
			
			for(var i=0;i<5;++i){
				var udpReceiver = new ExtUDPSocket;
				Traits.addTrait(udpReceiver,UDPAutoRegisterTrait,"127.0.0.1",udpSender.getSocket().getPort());	//! \see UDPAutoRegisterTrait
	//			Traits.addTrait(udpReceiver,UDPMultiChannelReceiverTrait);				//! \see UDPMultiChannelReceiverTrait
				services += udpReceiver;
	
	//			udpReceiver.setChannelHandler(0x01,[i]=>fn(nr, value){				outln("Received: ",nr,":",value);			});
				udpReceiver.onDataReceived += [i]=>fn(nr, data){				outln("Received: ",nr,":[",data.host+":"+data.port,":",data.data,"]");			};
				
			}
		
	
			var t = Util.Timer.now()+1;
			
			while(Util.Timer.now()<t){		
	//			udpSender.sendValue(0x01,"foo");
				udpSender.sendString("foo");
				Util.sleep(100);
	
				services.execute();
			}
	
	
			services.close();
	
		}catch(e){
			services.close();
			services.execute();
			throw(e);
		}	
		addResult("Part 2",true);
	}

	// todo!!!!!!!!!!!!!!!!!!!
	return true;	
});


// ---------------------------------------------------------
return tests;
