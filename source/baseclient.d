import std.socket;

class BaseClient
{
		
	UdpSocket serversocket;
	void Connect(string ip, ushort port)
	{
		serversocket = new UdpSocket();
		serversocket.blocking = false;
		serversocket.connect(new InternetAddress(ip,port));
	}
	
	void HandlePacket(ubyte[] packet)
	{
		
	}
	
	void Tick()
	{
		ubyte[2048] packet;
		auto packetLength = serversocket.receive(packet[]);
		while(packetLength != Socket.ERROR && packetLength > 0)
		{
			HandlePacket(packet);
			packetLength = serversocket.receive(packet[]);
		}
	}
}