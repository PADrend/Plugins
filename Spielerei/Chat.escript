/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 * Simple Network Chat Client/Server System for network testing.
 * 2009-10-23
 */
static ChatServer = new Type;

ChatServer.window := void;
ChatServer.tcpServer := void;
ChatServer.connections := void;
ChatServer.connectionLabel := void;
ChatServer.messageLabel := void;
ChatServer.messageTF := void;

ChatServer.init := fn(){
    this.connections = [];
    this.createWindow();
    registerExtension('PADrend_AfterRendering',this->this.ex_AfterRendering);
};

ChatServer.createWindow := fn(){
    var width=300;
    var height=100;
    this.window = gui.createWindow(width,height,"ChatServer");
    this.window.setPosition(400,400);
    var panel = gui.createPanel(width,height,GUI.AUTO_LAYOUT);
    window.add(panel);

    var portTextField = gui.createTextfield(40,15,"12345");
    portTextField.setTooltip("TCP-Port to listen on");
    panel.add(portTextField);
    {
        var button = gui.createButton(40,15,"Create");
        button.setTooltip("Create TCP server");

        button.portTF := portTextField;
        button.chatServer := this;
        button.onClick = fn(){
            chatServer.createServer(new Number(portTF.getText()));};
        panel.add(button);
    }
    {
        var button = gui.createButton(40,15,"Close");
        button.setTooltip("Close Server");
        button.chatServer := this;
        button.onClick = fn(){
            chatServer.close();
        };
        panel.add(button);
    }
    connectionLabel = gui.createLabel(30,15,"...");
    connectionLabel.setTooltip("Number of connected clients");
    panel.add(connectionLabel);
    panel.nextRow();
    messageLabel = gui.createLabel(width,30,"...");
    messageLabel.setTooltip("Last message received");
    panel.add(messageLabel);
    panel.nextRow();

    messageTF = gui.createTextfield(width-20,15,"");

    messageTF.setTooltip("Message to send to all clients");
    messageTF.chatServer := this;
    messageTF.onDataChanged = fn(data){
        chatServer.broadcast(data);
        setText("");
    };
    panel.add(messageTF);
};

ChatServer.createServer := fn(Number port){
    if(tcpServer){
        tcpServer.close();
        tcpServer=void;
    }
    tcpServer=Network.TCPServer.create(port);
};

ChatServer.close := fn(){
    if(!tcpServer)  return;

    tcpServer.close();
    tcpServer=void;
    foreach( connections as var c){
        c.close();
    }
    connections.filter(fn(connection){return connection.isOpen();});
    connectionLabel.setText("...");
};

ChatServer.ex_AfterRendering := fn(...){
    if(!tcpServer)
        return;
    var newConnection=tcpServer.getIncomingConnection();
    if(newConnection){
        connections+=newConnection;
    }
    connections.filter(fn(connection){return connection.isOpen();});
    connectionLabel.setText(connections.count());

    foreach(connections as var c){
        var s=c.receiveString('\n');
        if(!s)continue;
        messageLabel.setText(s.substr(0,-1));
        out("(ChatServer) Received:",s.substr(0,-1),"\n");
    }
};

ChatServer.broadcast := fn(text){
    out("(ChatServer) Boradcast: ",text,"\n");
    foreach(connections as var c){
        c.sendString(text,'\n');
    }
};
// -----------------------------------------------------------------

static ChatClient = new Type;

ChatClient.window := void;
ChatClient.connection := void;
ChatClient.connectionLabel := void;
ChatClient.messageLabel := void;
ChatClient.messageTF := void;

ChatClient.init := fn(){
//    this.connection := void;
    this.createWindow();
    registerExtension('PADrend_AfterRendering',this->this.ex_AfterRendering);
};

ChatClient.createWindow := fn(){
    var width=300;
    var height=150;
    this.window = gui.createWindow(width,height,"ChatClient");
    this.window.setPosition(400,550);
    var panel = gui.createPanel(width,height,GUI.AUTO_LAYOUT);
    window.add(panel);

    var hostTextField = gui.createTextfield(100,15,"localhost");
    panel.add(hostTextField);
    var portTextField = gui.createTextfield(40,15,"12345");
    panel.add(portTextField);
    {
        var button = gui.createButton(40,15,"connect");
        button.portTF := portTextField;
        button.hostTF := hostTextField;
        button.chatClient := this;
        button.onClick = fn(){
            chatClient.connect(hostTF.getText(),new Number(portTF.getText()));};
        panel.add(button);
    }
    {
        var button = gui.createButton(40,15,"Close");
        button.chatClient := this;
        button.onClick = fn(){
            chatClient.close();
        };
        panel.add(button);
    }
    connectionLabel = gui.createLabel(30,15,"...");
    panel.add(connectionLabel);
    panel.nextRow();
    messageLabel = gui.createLabel(width,30,"...");
    panel.add(messageLabel);
    panel.nextRow();

    messageTF = gui.createTextfield(width-20,15,"");
    messageTF.chatClient := this;
    messageTF.onDataChanged = fn(data){
        chatClient.sendText(data);
        setText("");
    };
    panel.add(messageTF);
};

ChatClient.connect := fn(String host,Number port){
    if(connection){
        connection.close();
        connection=void;
    }
    connection=Network.TCPConnection.connect(host,port);
};

ChatClient.close := fn(){
    if(!connection)  return;

    connection.close();
    connection=void;
    connectionLabel.setText("...");
};

ChatClient.ex_AfterRendering := fn(...){
    if(!connection)
        return;
    if(!connection.isOpen()){
        close();
        return;
    }
    connectionLabel.setText("OK");
    var s=connection.receiveString('\n');
    if(!s)return;
    messageLabel.setText(s.substr(0,-1));
    out("(ChatClient) Received:",s.substr(0,-1),"\n");
};

ChatClient.sendText := fn(text){
    if(!connection) return;
    out("(ChatClient) Send: ",text,"\n");
    connection.sendString(text,'\n');
};

var NS = new Namespace;
NS.Server := ChatServer;
NS.Client := ChatClient;
return NS;

// -----------------------------------------------------------------
