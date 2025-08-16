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
import dguiw;
import mapeditor;
import std.file;
import std.string;

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
		DGUI_SetRoot(new MapEditor());
	}
}

struct TextureData
{
	uint width;
	uint height;
	uint* pixels;
}

public TextureData[] texturedict;

struct BMPHeader
{
	align(1):
	ubyte[10] padding;
	uint startOfImg;
}


bool LoadTexture(string name)
{
	if(!exists(name))
	{
		texturedict ~= TextureData();
		return false;
	}
	ubyte* data = cast(ubyte*)read(name).ptr;
	BMPHeader* bhdr = cast(BMPHeader*)data;
	
	texturedict ~= TextureData(width:*cast(uint*)(data+18),height:*cast(uint*)(data+22),pixels:cast(uint*)(data+bhdr.startOfImg));
	return true;
}

ulong AddTexture(string name)
{
	if(!LoadTexture(name))
	{
		return 0;
	}
	g.textures ~= Texture();
	g.textures[$-1].name[] = 0;
	g.textures[$-1].name[0..name.length] = name[];
	
	return g.textures.length-1;
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
				Packet2AddVert pack = *cast(Packet2AddVert*)data;
				g.verts ~= pack.pos;
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
			case 11:
				Packet11EdgeTexture pack = *cast(Packet11EdgeTexture*)data;
				bool success = false;
				foreach(i, texture; g.textures)
				{
					if(texture.name == pack.texture)
					{
						g.edges[pack.edge].texture = i;
						success = true;
						break;
					}
				}
				if(!success)
				{
					string texname = cast(string)fromStringz(pack.texture);
					
					g.edges[pack.edge].texture = AddTexture(texname);
				}
				break;
			case 14:
				Packet14SetEntityModel pack = *cast(Packet14SetEntityModel*)data;
				g.entities[pack.entity].model = pack.model;
				break;
			case 15:
				Packet15CreateModel pack = *cast(Packet15CreateModel*)data;
				g.models ~= Model(sectors:[]);
				break;
			case 16:
				Packet16AddToModel pack = *cast(Packet16AddToModel*)data;
				g.models[pack.model].sectors ~= pack.sector;
				break;
			case 17:
				Packet17SetEntityBehavior pack = *cast(Packet17SetEntityBehavior*)data;
				g.entities[pack.entity].behavior = pack.behavior;
				break;
			case 18:
				Packet18CreateAction pack = *cast(Packet18CreateAction*)data;
				g.actions ~= Action();
				break;
			case 22:
				Packet22CreateTrigger pack = *cast(Packet22CreateTrigger*)data;
				g.triggers ~= Trigger();
				break;
			case 23:
				Packet23AddToTrigger pack = *cast(Packet23AddToTrigger*)data;
				g.triggers[pack.trigger].action ~= 0;
				break;
			case 24:
				Packet24SetTriggerAction pack = *cast(Packet24SetTriggerAction*)data;
				g.triggers[pack.trigger].action[pack.actionindex] = pack.action;
				break;
			case 25:
				Packet25RemoveTriggerAction pack = *cast(Packet25RemoveTriggerAction*)data;
				g.triggers[pack.trigger].action = g.triggers[pack.trigger].action[0..pack.actionindex] ~ g.triggers[pack.trigger].action[pack.actionindex+1..$];
				break;
			case 26:
				Packet26SetEntityTrigger pack = *cast(Packet26SetEntityTrigger*)data;
				g.entities[pack.entity].trigger = pack.trigger;
				break;
			case 27:
				Packet27SetEdge pack = *cast(Packet27SetEdge*)data;
				g.edges[pack.edgeindex].start = pack.start;
				g.edges[pack.edgeindex].end = pack.end;
				break;
			case 28:
				Packet28AddTexture pack = *cast(Packet28AddTexture*)data;
				string texname = cast(string)fromStringz(pack.texture);
				AddTexture(texname);
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
				mc.HandlePacket(packet);
				break;
		}
	}
}

Client cl;

float color = 0.0f;
float saturation = 1.0f;
float value = 1.0f;

void Tick()
{
	cl.Tick();
	
	
	if(viewent >= g.entities.length)
	{
		return;
	}
	
	
	float camrot = g.entities[viewent].rot;
	float campitch = g.campitch;
	g.camforward = float3([sin(camrot)*cos(campitch),-cos(camrot)*cos(campitch),-sin(campitch)]);
	g.camright = float3([cos(camrot),sin(camrot),0.0f]);
	g.camup = float3([sin(camrot)*sin(campitch),-cos(camrot)*sin(campitch),cos(campitch)]);
	
	float3 accel = [0,0,0];
	
	if(inputHandler.forwards > 0)
	{
		accel = accel + g.camforward*0.01f;
	}
	if(inputHandler.backwards > 0)
	{
		accel = accel - g.camforward*0.01f;
	}
	float3 left = float3([g.camforward[1],-g.camforward[0],0.0f]);
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
		accel[2] += 0.02f;
	}
	
	if(inputHandler.e > 0)
	{
		color += 0.05f;
	}
	if(inputHandler.q > 0)
	{
		color -= 0.05f;
	}
	
	if(inputHandler.r > 0)
	{
		saturation += 0.05f;
	}
	if(inputHandler.f > 0)
	{
		saturation -= 0.05f;
	}
	if(inputHandler.t > 0)
	{
		value += 0.05f;
	}
	if(inputHandler.g > 0)
	{
		value -= 0.05f;
	}
	value = clamp(value,-1.0f,2.0f);
	saturation = clamp(saturation,-1.0f,2.0f);
	accel = accel * 0.99f;
	
	Packet1CamVars camvars = Packet1CamVars(type:1,camrot:g.camrot,camvel:accel,color:color,value:value,saturation:saturation,pressed:inputHandler.shift > 0);
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
