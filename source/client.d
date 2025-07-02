import input;
import math;
import std.socket;
import std.stdio;
import game;

InputHandler inputHandler;
UdpSocket serversocket;
public Game g;

ulong viewent = 0;

void Connect(ushort port)
{
	g = new Game();
	serversocket = new UdpSocket();
	serversocket.blocking = false;
	serversocket.connect(new InternetAddress("192.168.1.30",port));
	uint[] hi = [0];
	serversocket.send(hi);
	g.LoadMap();
}

void HandlePacket(ubyte[] packet)
{
	ubyte* data = packet.ptr;
	uint packettype = *cast(uint*)data;
	data += 4;
	switch(packettype)
	{
		case 0:
			ulong entitiescount = *cast(ulong*)data;
			data += 8;
			g.entities = [];
			foreach(i;0..entitiescount)
			{
				g.entities ~= *(cast(Entity*)data);
				data += Entity.sizeof;
			}
			viewent = *cast(ulong*)data;
			break;
		default:
			break;
	}
}

struct Packet1CamVars
{
	uint type = 1;
	float camrot;
	float3 camvel;
};

void Tick()
{
	ubyte[2048] packet;
	auto packetLength = serversocket.receive(packet[]);
	if(packetLength != Socket.ERROR && packetLength > 0)
	{
		HandlePacket(packet);
	}
	
	float2 accel = [0,0];
	float accelz = 0;
	
	if(inputHandler.forwards > 0)
	{
		accel = accel + g.camdir*0.01f;
	}
	if(inputHandler.backwards > 0)
	{
		accel = accel - g.camdir*0.01f;
	}
	float2 left = float2([g.camdir[1],-g.camdir[0]]);
	if(inputHandler.left > 0)
	{
		accel = accel + left*0.01f;
	}
	if(inputHandler.right > 0)
	{
		accel = accel - left*0.01f;
	}
	
	if(inputHandler.jump > 0)
	{
		accelz += 0.02f;
	}
	accel = accel * 0.99f;
	
	Packet1CamVars camvars = Packet1CamVars(type:1,camrot:g.camrot,camvel:float3([accel[0],accel[1],accelz]));
	serversocket.send([camvars]);
}