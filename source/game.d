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
	bool hidden;
	bool deleted;
}

struct Sector
{
	ulong[] edges;
	float high;
	float low;
	ulong floortex;
	ulong ceilingtex;
	bool deleted;
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
	
	foreach(clipi;0..3)
	{
		foreach(sector; sectors)
		{
			if(sector.deleted)
			{
				continue;
			}
			
			if(sector.low > camposz || sector.high < camposz)
			{
				continue;
			}

			float origspeed = speed;
			float2 origvel = camvel;
			float2 origdir = veldir;
			float2 origpos = campos;
			bool failure = false;
			
			foreach(edgeindex; sector.edges)
			{
				Edge edge = edges[edgeindex];
				
				if(edge.deleted)
				{
					continue;
				}
				
				float2 start = verts[edge.start];
				
				float2 n = EdgeNormal(edge);
				float dot = (campos*n) - (n*start);
				
				if(dot < -0.1f)
				{
					failure = true;
					break;
				}
				
				if(edge.height-edge.offset < camposz-0.1f)
				{
					continue;
				}
				
				if(-edge.offset > camposz)
				{
					continue;
				}
				
				if(edge.hidden)
				{
					continue;
				}
				
				float walldot = ((n*(start-campos)+0.02f)/(veldir*n));
				
				float distanceoutside = (start-campos)*n+0.05f;
				
				if(distanceoutside > 0)
				{
					campos = campos+n*distanceoutside;
				}
				
				
				
				if(walldot < 0.0f)
				{
					continue;
				}
				
				if(walldot <= speed)
				{
					//float ndot = ((campos+camvel)*n) - (n*start) + 0.05f;
					camvel = (veldir-n*(veldir*n))*speed;
					speed = *camvel;
					veldir = camvel*(1.0f/speed);
				}
			}
			
			if(failure)
			{
				speed = origspeed;
				camvel = origvel;
				veldir = origdir;
				campos = origpos;
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
		}
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