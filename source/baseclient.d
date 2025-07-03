import std.socket;

class BaseClient
{
		
	UdpSocket serversocket;
	void Connect(ushort port)
	{
		serversocket = new UdpSocket();
		serversocket.blocking = false;
		serversocket.connect(new InternetAddress("192.168.1.30",port));
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