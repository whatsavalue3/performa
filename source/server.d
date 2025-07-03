import std.socket;
import std.stdio;
import game;
import math;
import std.algorithm;
import std.math;

UdpSocket listener;
Socket[] clients;
Game g;

ulong[string] addrToEnt;

void Listen(ushort port)
{
	listener = new UdpSocket();
	listener.blocking = false;
	listener.bind(new InternetAddress("192.168.1.30",port));
}

ubyte[] SendFullUpdate(ulong entid)
{
	ubyte[] ret;
	ret ~= 0;
	ret ~= 0;
	ret ~= 0;
	ret ~= 0;
	ulong len = g.entities.length;
	ret ~= (cast(ubyte*)(&len))[0..8];
	foreach(entity; g.entities)
	{
		ret ~= (cast(ubyte*)(&entity))[0..Entity.sizeof];
	}
	ret ~= (cast(ubyte*)(&entid))[0..8];
	return ret;
}

struct Packet1CamVars
{
	uint type = 1;
	float camrot;
	float3 camvel;
	float color;
};

float HueShift(float h)
{
	return clamp(abs(3.0f-abs(h%6.0f)-1.0f)-1,0,1);
}

void Tick()
{
	try
	{
		clients ~= listener.accept();
		writeln("new");
	}
	catch(Exception e)
	{
		
	}
	
	try
	{
		Address from;
		ubyte[2048] packet;
		auto packetLength = listener.receiveFrom(packet[], from);
		while(packetLength != Socket.ERROR)
		{
			string fromi = from.toAddrString()~":"~from.toPortString();
			ubyte[] tosend;
			ubyte* data = packet.ptr;
			uint packettype = *cast(uint*)data;
			
			switch(packettype)
			{
				case Socket.ERROR:
					break;
				case 0:
					addrToEnt[fromi] = g.entities.length;
					g.entities ~= Entity(pos:float3([0.0f,0.0f,0.0f]));
					tosend = SendFullUpdate(addrToEnt[fromi]);
					break;
				case 1:
					Packet1CamVars camvar = *cast(Packet1CamVars*)data;
					g.entities[addrToEnt[fromi]].rot = camvar.camrot;
					g.entities[addrToEnt[fromi]].vel = g.entities[addrToEnt[fromi]].vel+camvar.camvel;
					float R = HueShift(camvar.color-1);
					float G = HueShift(camvar.color-3);
					float B = HueShift(camvar.color-6);
					g.entities[addrToEnt[fromi]].color = float3([R,G,B]);
					tosend = SendFullUpdate(addrToEnt[fromi]);
					break;
				default:
					break;
			}
			if(tosend.length > 0)
			{
				listener.sendTo(tosend,from);
			}
			packetLength = listener.receiveFrom(packet[], from);
		}
	}
	catch(Exception e)
	{
	
	}
	g.Tick();
}

void LoadMap()
{
	g = new Game();
	g.LoadMap();
}