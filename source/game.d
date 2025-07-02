import bindbc.sdl;
import math;
import std.math;
import std.stdio;

class Entity
{
	float[3] pos;
}


struct Edge
{
	ulong start;
	ulong end;
	float height;
	float offset;
	ulong texture;
}

struct Sector
{
	ulong[] edges;
	float high;
	float low;
	ulong floortex;
	ulong ceilingtex;
}

struct Texture
{
	char[64] name;
}

public float2[] verts;
public Edge[] edges;
public Sector[] sectors;
public Texture[] textures;

float2 EdgeNormal(Edge e)
{
	float2 diff = verts[e.end]-verts[e.start];
	return ~float2([diff[1],-diff[0]]);
}

float2 EdgeNormalVis(Edge e)
{
	float2 diff = verts[e.end]-verts[e.start];
	return float2([diff[1],-diff[0]]);
}

float2 campos = float2([0.0f,0.0f]);
float camposz = 0.0f;
float camheight = 1.8f;
float camrot = 0.0f;
float2 camdir = float2([0.0f,-1.0f]);
float2 camvel = float2([0.0f,0.0f]);
float camvelz = 0.0f;

void IN_Move(float speed)
{
	camvelz -= 0.01f;
	float2 veldir = camvel*(1.0f/speed);
	
	bool success = false;
	
	foreach(sector; sectors)
	{
		if(sector.low > camposz || sector.high < camposz)
		{
			continue;
		}
	
		float origspeed = speed;
		float2 origvel = camvel;
		bool failure = false;
		
		foreach(edgeindex; sector.edges)
		{
			Edge edge = edges[edgeindex];
			float2 start = verts[edge.start];
			
			float2 n = EdgeNormal(edge);
			float dot = ((campos*0.05f)*n) - (n*start*0.05f);
			
			if(dot < 0)
			{
				failure = true;
				break;
			}
			
			float walldot = (n*((start-campos)*0.05f))/(veldir*n);
			if(walldot < 0)
			{
				continue;
			}
			
			if(walldot <= speed)
			{
				speed = walldot;
				camvel = veldir*speed;
			}
		}
		
		if(failure)
		{
			speed = origspeed;
			camvel = origvel;
			continue;
		}
		
		
		if(camvelz+camheight > sector.high-camposz)
		{
			camvelz = sector.high-camposz-camheight;
		}
		if(camvelz < sector.low-camposz)
		{
			camvelz = sector.low-camposz;
		}
		success = true;
		
		break;
	}
	
	campos = campos + camvel;
	if(!success)
	{
		camvelz = 0;
	}
	camposz += camvelz;
}

void Tick()
{
	camdir = float2([sin(camrot),-cos(camrot)]);
	float speed = *camvel;
	if(speed > 0.001f)
	{
		IN_Move(speed);
	}
	else
	{
		IN_Move(0.001f);
	}
	
}