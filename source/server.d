import std.socket;
import std.stdio;
import game;
import math;
import std.algorithm;
import std.math;
import packet;
import baseserver;
import command;

MapServer ms;
Server sv;
Game g;

bool loadedmap = false;

class CMD_Map : Command
{
	static string name = "map";
	
	mixin RegisterCmd;
	
	override void Call(string[] args)
	{
		LoadMap();
		sv.Listen(2323);
		ms.Listen(2324);
	}
}

class CMD_NewMap : Command
{
	static string name = "newmap";
	
	mixin RegisterCmd;
	
	override void Call(string[] args)
	{
		g = new Game();
		g.ExecuteTrigger = &sv.ExecuteTrigger;
		sv.Listen(2323);
		ms.Listen(2324);
	}
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



float HueShift(float h)
{
	return clamp(abs(3.0f-abs(h%6.0f)-1.0f)-1.0f,0,1);
}

class MapServer : BaseServer
{
	sockaddr[] clients;
	
	override ubyte[] ProcessPacket(uint packettype, ubyte[] data, sockaddr fromi)
	{
		ubyte[] tosend;
		switch(packettype)
		{
			case 0:
				clients ~= fromi;
				break;
			case 2:
				mixin VerifySize!(Packet2AddVert, data);
				g.verts ~= pack.pos;
				SendToAll(pack);
				break;
			case 3:
				mixin VerifySize!(Packet3SetVert, data);
				g.verts[pack.vertid] = pack.pos;
				SendToAll(pack);
				break;
			case 4:
				mixin VerifySize!(Packet4AddEdge, data);
				g.edges ~= pack.edge;
				SendToAll(pack);
				break;
			case 5:
				mixin VerifySize!(Packet5AddSector, data);
				g.sectors ~= Sector(edges:[],high:2f,low:-2f,floortex:0,ceilingtex:0);
				SendToAll(pack);
				break;
			case 6:
				mixin VerifySize!(Packet6SetEdgeSector, data);
				g.sectors[pack.sector].edges ~= pack.edge;
				SendToAll(pack);
				break;
			case 7:
				mixin VerifySize!(Packet7SetEdgePortal, data);
				g.edges[pack.edge].portal = pack.sector;
				SendToAll(pack);
				break;
			case 8:
				mixin VerifySize!(Packet8ToggleVis, data);
				g.edges[pack.edge].hidden = pack.hidden;
				SendToAll(pack);
				break;
			case 9:
				mixin VerifySize!(Packet9SectorHeight, data);
				g.sectors[pack.sector].low = pack.low;
				g.sectors[pack.sector].high = pack.high;
				SendToAll(pack);
				break;
			case 10:
				mixin VerifySize!(Packet10EdgeHeight, data);
				g.edges[pack.edge].height = pack.height;
				g.edges[pack.edge].offset = pack.offset;
				SendToAll(pack);
				break;
			case 11:
				mixin VerifySize!(Packet11EdgeTexture, data);
				bool success = false;
				foreach(i, texture; g.textures)
				{
					if(texture.name == pack.texture)
					{
						g.edges[pack.edge].texture = i;
						success = true;
					}
				}
				if(!success)
				{
					g.edges[pack.edge].texture = g.textures.length;
				}
				SendToAll(pack);
				break;
			case 13:
				g.entities ~= Entity(pos:float3([0.0f,0.0f,0.0f]));
				break;
			case 14:
				mixin VerifySize!(Packet14SetEntityModel, data);
				g.entities[pack.entity].model = pack.model;
				SendToAll(pack);
				break;
			case 15:
				mixin VerifySize!(Packet15CreateModel, data);
				g.models ~= Model(sectors:[]);
				SendToAll(pack);
				break;
			case 16:
				mixin VerifySize!(Packet16AddToModel, data);
				g.models[pack.model].sectors ~= pack.sector;
				SendToAll(pack);
				break;
			case 17:
				mixin VerifySize!(Packet17SetEntityBehavior, data);
				g.entities[pack.entity].behavior = pack.behavior;
				SendToAll(pack);
				break;
			case 18:
				mixin VerifySize!(Packet18CreateAction, data);
				g.actions ~= Action();
				SendToAll(pack);
				break;
			case 22:
				mixin VerifySize!(Packet22CreateTrigger, data);
				g.triggers ~= Trigger();
				SendToAll(pack);
				break;
			case 23:
				mixin VerifySize!(Packet23AddToTrigger, data);
				g.triggers[pack.trigger].action ~= 0;
				SendToAll(pack);
				break;
			case 24:
				mixin VerifySize!(Packet24SetTriggerAction, data);
				g.triggers[pack.trigger].action[pack.actionindex] = pack.action;
				SendToAll(pack);
				break;
			case 25:
				mixin VerifySize!(Packet25RemoveTriggerAction, data);
				g.triggers[pack.trigger].action = g.triggers[pack.trigger].action[0..pack.actionindex] ~ g.triggers[pack.trigger].action[pack.actionindex+1..$];
				SendToAll(pack);
				break;
			case 26:
				mixin VerifySize!(Packet26SetEntityTrigger, data);
				g.entities[pack.entity].trigger = pack.trigger;
				SendToAll(pack);
				break;
			case 27:
				mixin VerifySize!(Packet27SetEdge, data);
				g.edges[pack.edgeindex].start = pack.start;
				g.edges[pack.edgeindex].end = pack.end;
				SendToAll(pack);
				break;
			default:
				break;
		}
		return tosend;
	}
	
	void SendToAll(PacketT)(PacketT pack)
	{
		foreach(addr; clients)
		{
			listener.sendTo([pack],new InternetAddress(cast(sockaddr_in)addr));
		}
	}
}



class Server : BaseServer
{
	ulong[sockaddr] addrToEnt;
	
	void SendMap(InternetAddress addr)
	{
		foreach(vert; g.verts)
		{
			listener.sendTo([Packet2AddVert(pos:vert)],addr);
		}
		foreach(edge; g.edges)
		{
			listener.sendTo([Packet4AddEdge(edge:edge)],addr);
		}
		foreach(i, sector; g.sectors)
		{
			listener.sendTo([Packet5AddSector()],addr);
			listener.sendTo([Packet9SectorHeight(sector:i,low:sector.low,high:sector.high)],addr);
			foreach(edgeindex; sector.edges)
			{
				listener.sendTo([Packet6SetEdgeSector(sector:i,edge:edgeindex)],addr);
			}
		}
		foreach(texture; g.textures)
		{
			listener.sendTo([Packet28AddTexture(texture:texture.name)],addr);
		}
	}
	
	void ExecuteTrigger(ulong trigger)
	{
		ulong[] actions = g.triggers[trigger].action;
		sockaddr fromi;
		foreach(actionindex; actions)
		{
			Action action = g.actions[actionindex];
			ubyte[] data = cast(ubyte[])(cast(void[])[action]);
			ms.ProcessPacket(action.type,data,fromi);
		}
	}

	override ubyte[] ProcessPacket(uint packettype, ubyte[] packet, sockaddr fromi)
	{
		if(fromi !in addrToEnt && packettype != 0)
		{
			return [];
		}
		ubyte[] tosend;
		switch(packettype)
		{
			case 0:
				addrToEnt[fromi] = g.entities.length;
				g.entities ~= Entity(pos:float3([0.0f,0.0f,0.0f]));
				this.SendMap(new InternetAddress(cast(sockaddr_in)fromi));
				tosend = SendFullUpdate(addrToEnt[fromi]);
				break;
			case 1:
				mixin VerifySize!(Packet1CamVars, packet);
				
				g.entities[addrToEnt[fromi]].rot = pack.camrot;
				g.entities[addrToEnt[fromi]].vel = g.entities[addrToEnt[fromi]].vel+pack.camvel;
				float R = HueShift(abs(pack.color+6-1));
				float G = HueShift(abs(pack.color+6-3));
				float B = HueShift(abs(pack.color+6-5));
				g.entities[addrToEnt[fromi]].color = (float3([R,G,B])*pack.saturation+float3([1.0f-pack.saturation,1.0f-pack.saturation,1.0f-pack.saturation]))*pack.value;
				g.entities[addrToEnt[fromi]].pressed = pack.pressed;
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
	loadedmap = true;
	g = new Game();
	g.LoadMap("map.mp");
}