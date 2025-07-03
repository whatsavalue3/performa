import std.socket;
import std.stdio;
import game;
import math;
import std.algorithm;
import std.math;
import packet;
import baseserver;

MapServer ms;
Server sv;
Game g;




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
	sockaddr[] clients;
	
	override ubyte[] ProcessPacket(uint packettype, ubyte* data, sockaddr fromi)
	{
		ubyte[] tosend;
		switch(packettype)
		{
			case 0:
				clients ~= fromi;
				break;
			case 2:
				g.verts ~= float2([0.0f,0.0f]);
				Packet2AddVert newpacket = Packet2AddVert();
				foreach(addr; clients)
				{
					listener.sendTo([newpacket],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 3:
				Packet3SetVert pack = *cast(Packet3SetVert*)data;
				g.verts[pack.vertid] = pack.pos;
				foreach(addr; clients)
				{
					listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 4:
				Packet4AddEdge pack = *cast(Packet4AddEdge*)data;
				g.edges ~= pack.edge;
				foreach(addr; clients)
				{
					listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 5:
				Packet5AddSector pack = *cast(Packet5AddSector*)data;
				g.sectors ~= Sector(edges:[],high:2f,low:-2f,floortex:0,ceilingtex:0);
				foreach(addr; clients)
				{
					listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 6:
				Packet6SetEdgeSector pack = *cast(Packet6SetEdgeSector*)data;
				g.sectors[pack.sector].edges ~= pack.edge;
				foreach(addr; clients)
				{
					listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 7:
				Packet7SetEdgePortal pack = *cast(Packet7SetEdgePortal*)data;
				g.edges[pack.edge].portal = pack.sector;
				foreach(addr; clients)
				{
					listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
				}
				break;
			case 8:
				Packet8ToggleVis pack = *cast(Packet8ToggleVis*)data;
				g.edges[pack.edge].hidden = pack.hidden;
				foreach(addr; clients)
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
	ulong[sockaddr] addrToEnt;

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