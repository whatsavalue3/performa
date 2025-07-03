import input;
import math;
import std.socket;
import std.stdio;
import game;
import std.math;
import std.algorithm;
import packet;
import baseclient;
import command;
import std.conv;
import dgui;
import mapeditor;

InputHandler inputHandler;

MapClient mc;

public Game g;

class CMD_Map : Command
{
	static string name = "connect";
	
	mixin RegisterCmd;
	
	override void Call(string[] args)
	{
		if(args.length == 1)
		{
			cl.Connect("127.0.0.1",2323);
			mc.Connect("127.0.0.1",2324);
		}
		else if(args.length == 2)
		{
			cl.Connect(args[1],2323);
			mc.Connect(args[1],2324);
		}
		else
		{
			cl.Connect(args[1],to!ushort(args[2]));
			mc.Connect(args[1],cast(ushort)(to!ushort(args[2])+1));
		}
		mainpanel = new MapEditor();
	}
}

ulong viewent = 0;

class MapClient : BaseClient
{
	override void Connect(string ip, ushort port)
	{
		super.Connect(ip, port);
		serversocket.send([0]);
	}

	override void HandlePacket(ubyte[] packet)
	{
		ubyte* data = packet.ptr;
		uint packettype = *cast(uint*)data;
		switch(packettype)
		{
			case 2:
				g.verts ~= float2([0.0f,0.0f]);
				break;
			case 3:
				Packet3SetVert pack = *cast(Packet3SetVert*)data;
				g.verts[pack.vertid] = pack.pos;
				break;
			case 4:
				Packet4AddEdge pack = *cast(Packet4AddEdge*)data;
				g.edges ~= pack.edge;
				break;
			case 5:
				g.sectors ~= Sector(edges:[],high:2f,low:-2f,floortex:0,ceilingtex:0);
				break;
			case 6:
				Packet6SetEdgeSector pack = *cast(Packet6SetEdgeSector*)data;
				g.sectors[pack.sector].edges ~= pack.edge;
				break;
			case 7:
				Packet7SetEdgePortal pack = *cast(Packet7SetEdgePortal*)data;
				g.edges[pack.edge].portal = pack.sector;
				break;
			case 8:
				Packet8ToggleVis pack = *cast(Packet8ToggleVis*)data;
				g.edges[pack.edge].hidden = pack.hidden;
				break;
			case 9:
				Packet9SectorHeight pack = *cast(Packet9SectorHeight*)data;
				g.sectors[pack.sector].low = pack.low;
				g.sectors[pack.sector].high = pack.high;
				break;
			case 10:
				Packet10EdgeHeight pack = *cast(Packet10EdgeHeight*)data;
				g.edges[pack.edge].height = pack.height;
				g.edges[pack.edge].offset = pack.offset;
				break;
			default:
				break;
		}
	}
	
	void SendPacket(PType)(PType pack)
	{
		serversocket.send([pack]);
	}
}

class Client : BaseClient
{
	override void Connect(string ip, ushort port)
	{
		super.Connect(ip, port);
		g = new Game();
		g.LoadMap();
		serversocket.send([0]);
	}

	override void HandlePacket(ubyte[] packet)
	{
		ubyte* data = packet.ptr;
		uint packettype = *cast(uint*)data;
		switch(packettype)
		{
			case 0:
				data += 4;
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
}

Client cl;

float color = 0.0f;

void Tick()
{
	cl.Tick();
	
	
	if(viewent >= g.entities.length)
	{
		return;
	}
	
	g.camdir = float2([sin(g.entities[viewent].rot),-cos(g.entities[viewent].rot)]);
	
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
	
	if(inputHandler.e > 0)
	{
		color += 0.05f;
	}
	if(inputHandler.q > 0)
	{
		color -= 0.05f;
	}
	accel = accel * 0.99f;
	
	Packet1CamVars camvars = Packet1CamVars(type:1,camrot:g.camrot,camvel:float3([accel[0],accel[1],accelz]),color:color);
	cl.serversocket.send([camvars]);
}


void SendPacket(PType)(PType pack)
{
	cl.serversocket.send([pack]);
}

void Exec(string text)
{
	string[] args = [""];
	foreach(c; text)
	{
		if(c == ' ')
		{
			args ~= "";
		}
		else
		{
			args[$-1] ~= c;
		}
	}
	if(args[0] !in commands)
	{
		writeln("invalid command");
		return;
	}
	commands[args[0]].Call(args);
}