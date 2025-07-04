import bindbc.sdl;
import math;
import std.math;
import std.stdio;


struct Edge
{
	ulong start;
	ulong end;
	float height;
	float offset;
	ulong texture;
	bool hidden;
	bool deleted;
	ulong portal;
}

struct Sector
{
	ulong[] edges;
	float high;
	float low;
	ulong floortex;
	ulong ceilingtex;
	bool deleted;
	bool hidden;
}

struct Texture
{
	char[64] name;
}

struct Entity
{
	float3 pos = [0,0,0];
	float rot = 0;
	float3 vel = [0,0,0];
	ulong cursector = 0;
	float3 color = [0,0,0];
}

class Game
{
	float2[] verts;
	Edge[] edges;
	Sector[] sectors;
	Texture[] textures;
	Entity[] entities;
	
	void IN_Move(ref Entity ent)
	{
		ent.vel[2] -= 0.01f;
		float speed = *ent.vel;
		float3 veldir = ent.vel*(1.0f/speed);
		
		bool success = false;
		
		foreach(clipi;0..3)
		{
			foreach(sectorindex, sector; sectors)
			{
				if(sector.deleted)
				{
					continue;
				}
				
				if(sector.low > ent.pos[2] || sector.high < ent.pos[2])
				{
					continue;
				}

				float origspeed = speed;
				float3 origvel = ent.vel;
				float3 origdir = veldir;
				float3 origpos = ent.pos;
				bool failure = false;
				
				foreach(edgeindex; sector.edges)
				{
					Edge edge = edges[edgeindex];
					
					if(edge.deleted)
					{
						continue;
					}
					
					float3 start = float3([verts[edge.start][0],verts[edge.start][1],0.0f]);
					
					float2 en = EdgeNormal(edge);
					float3 n = float3([en[0],en[1],0.0f]);
					float dot = (ent.pos*n) - (n*start);
					
					if(dot < -0.05f)
					{
						failure = true;
						break;
					}
					
					if(edge.height-edge.offset < ent.pos[2]-0.01f)
					{
						continue;
					}
					
					if(-edge.offset > ent.pos[2])
					{
						continue;
					}
					
					if(edge.hidden)
					{
						continue;
					}
					
					float walldot = ((n*(start-ent.pos)+0.02f)/(veldir*n));
					
					float distanceoutside = (start-ent.pos)*n+0.05f;
					
					if(distanceoutside > 0)
					{
						ent.pos = ent.pos+n*distanceoutside;
					}
					
					
					
					if(walldot < 0.0f)
					{
						continue;
					}
					
					if(walldot <= speed)
					{
						ent.vel = (veldir-n*(veldir*n))*speed;
						speed = *ent.vel;
						veldir = ent.vel*(1.0f/speed);
					}
				}
				
				if(failure)
				{
					speed = origspeed;
					ent.vel = origvel;
					veldir = origdir;
					ent.pos = origpos;
					continue;
				}
				
				
				if(ent.vel[2]+camheight > sector.high-ent.pos[2])
				{
					ent.vel[2] = sector.high-ent.pos[2]-camheight;
				}
				if(ent.vel[2] < sector.low-ent.pos[2])
				{
					ent.vel[2] = sector.low-ent.pos[2];
					ent.vel[1] *= 0.97f;
					ent.vel[0] *= 0.97f;
				}
				success = true;
				ent.cursector = sectorindex;

			}
		}
		
		
		if(!success)
		{
			ent.vel = 0;
			ent.cursector = 0;
		}
		else
		{
			ent.pos = ent.pos + ent.vel;
		}
	}
	

	void Tick()
	{
		camdir = float2([sin(camrot),-cos(camrot)]);
		foreach(ref entity; entities)
		{
			IN_Move(entity);
		}
	}
	
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
	
		
	void LoadMap()
	{
		File* mapfile = new File("map.mp","rb");
		ulong[4] lengths = mapfile.rawRead(new ulong[4]);
		
		
		verts = mapfile.rawRead(new float2[lengths[0]]);
		edges = mapfile.rawRead(new Edge[lengths[1]]);
		SaveSector[] savesectors = mapfile.rawRead(new SaveSector[lengths[2]]);
		textures = mapfile.rawRead(new Texture[lengths[3]]);
		
		
		sectors = [];
		foreach(savesector; savesectors)
		{
			ulong[] edgeindices;
			foreach(i;savesector.edgestart..savesector.edgestart+savesector.edgecount)
			{
				edges[i].deleted = false;
				edgeindices ~= i;
			}
			
			sectors ~= Sector(
				edges:edgeindices,
				high:savesector.high,
				low:savesector.low,
				ceilingtex:savesector.ceilingtex,
				floortex:savesector.floortex);
		}
		mapfile.close();
	}

	float2 campos = float2([0.0f,0.0f]);
	float camposz = 0.0f;
	float camheight = 1.8f;
	float camrot = 0.0f;
	float2 camdir = float2([0.0f,-1.0f]);
	float2 camvel = float2([0.0f,0.0f]);
	float camvelz = 0.0f;
	ulong cursector = 0;

}





struct SaveSector
{
	ulong edgestart;
	ulong edgecount;
	float high;
	float low;
	ulong floortex;
	ulong ceilingtex;
	bool deleted;
}
