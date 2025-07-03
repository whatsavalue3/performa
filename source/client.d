import input;
import math;
import std.socket;
import std.stdio;
import game;
import std.math;
import packet;
import baseclient;

InputHandler inputHandler;

public Game g;

ulong viewent = 0;

class Client : BaseClient
{
	override void Connect(ushort port)
	{
		super.Connect(port);
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
			case 2:
				g.verts ~= float2([0.0f,0.0f]);
				break;
			case 3:
				Packet3SetVert pack = *cast(Packet3SetVert*)data;
				g.verts[pack.vertid] = pack.pos;
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