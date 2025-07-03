import std.socket;
import std.stdio;
import game;
import math;
import std.algorithm;
import std.math;
import packet;
import baseserver;


Server sv;
Game g;

ulong[sockaddr] addrToEnt;


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



float HueShift(float h)
{
	return clamp(abs(3.0f-abs(h%6.0f)-1.0f)-1,0,1);
}

class MapServer : BaseServer
{
	override ubyte[] ProcessPacket(uint packettype, ubyte* data, sockaddr fromi)
	{
		ubyte[] tosend;
		switch(packettype)
		{
			case 2:
				g.verts ~= float2([0.0f,0.0f]);
				foreach(addr, ent; addrToEnt)
				{
					Packet2AddVert newpacket = Packet2AddVert();
					listener.sendTo([newpacket],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 3:
				Packet3SetVert pack = *cast(Packet3SetVert*)data;
				g.verts[pack.vertid] = pack.pos;
				foreach(addr, ent; addrToEnt)
				{
					listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			default:
				break;
		}
		return tosend;
	}
}

class Server : BaseServer
{
	override ubyte[] ProcessPacket(uint packettype, ubyte* data, sockaddr fromi)
	{
		ubyte[] tosend;
		switch(packettype)
		{
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
		return tosend;
	}
	
	override void Tick()
	{
		super.Tick();
		g.Tick();
	}
}


void LoadMap()
{
	g = new Game();
	g.LoadMap();
}