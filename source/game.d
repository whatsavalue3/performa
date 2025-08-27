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

struct Model
{
	ulong[] sectors;
}

struct Entity
{
	float3 pos = [0,0,0];
	float3 localpos = [0,0,0];
	float rot = 0;
	float3 vel = [0,0,0];
	ulong cursector = 0;
	float3 color = [0,0,0];
	long model = -1;
	long parent = -1;
	short health = 100;
	ushort behavior = 0;
	bool pressed = false;
	long trigger = -1;
	ulong flags = 0;
}

struct Action
{
	uint type;
	ulong arg1;
	union
	{
		ulong arg2_u;
		struct
		{
			float arg2_f;
			float arg3_f;
		}
	}
}

struct Trigger
{
	ulong[] action;
}

struct Face
{
	float3 normal;
	float distance;
	float3 tangent;
	float3 bitangent;
	ulong texture;
	ulong[] clipfaces;
}

struct Brush
{
	ulong sector;
	ulong[] faces;
}

struct ClipFace
{
	float2 normal;
	float distance;
}

class Game
{
	float2[] verts;
	Edge[] edges;
	Sector[] sectors;
	Texture[] textures;
	Entity[] entities;
	Model[] models;
	Action[] actions;
	Trigger[] triggers;
	Face[] faces;
	Brush[] brushes;
	ClipFace[] clipfaces;
	
	void IN_Move(ref Entity ent)
	{
		if(ent.parent != -1)
		{
			ent.pos = entities[ent.parent].pos+ent.localpos;
			ent.cursector = entities[ent.parent].cursector;
			return;
		}
		
		ent.vel[2] -= 0.01f;
		float speed = *ent.vel;
		float3 veldir = ent.vel*(1.0f/speed);
		
		
		bool success = false;
		bool bounced = true;
		
		while(bounced)
		{
			bounced = false;
			//foreach(sectorindex, sector; sectors)
			{
				ulong sectorindex = ent.cursector;
				if(sectorindex >= sectors.length)
				{
					break;
				}
				Sector sector = sectors[sectorindex];
				if(sector.deleted)
				{
					continue;
				}
				
				if(sector.low > ent.pos[2] || sector.high < ent.pos[2]+camheight)
				{
					continue;
				}
				

				//ent.cursector = sectorindex;
				
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
					
					
					if(edge.height-edge.offset < ent.pos[2]-0.01f)
					{
						continue;
					}
					
					if(-edge.offset > ent.pos[2])
					{
						continue;
					}
					
					
					
					float walldot = (-dot/(veldir*n));
					
					if(walldot < 0.0f)
					{
						goto checkinbounds;
						continue;
					}
					
					if(walldot <= speed)
					{
						bounced = true;
						if(edge.hidden)
						{
							ent.pos = ent.pos + ent.vel;
							ent.cursector = edge.portal;
							break;
						}
						
						ent.vel = (veldir-n*(veldir*n))*speed;
						speed = *ent.vel;
						veldir = ent.vel*(1.0f/speed);
						
						
						
					}
					
					checkinbounds:
					
					float3 nextpos = ent.pos+ent.vel;
					float ndot = (nextpos*n) - (n*start);
					if(ndot < 0)
					{
						ent.pos = ent.pos-n*(ndot-0.001f);
						//ent.vel = ent.vel-n*(n*ent.vel);
					}
					
					
				}
				
				
				if(ent.vel[2]+camheight >= sector.high-ent.pos[2])
				{
					//ent.vel[2] = sector.high-ent.pos[2]-camheight;
					ent.vel[2] = 0.0f;
					ent.pos[2] = sector.high-camheight;
				}
				if(ent.vel[2] <= sector.low-ent.pos[2])
				{
					ent.vel[2] = 0.0f;
					ent.vel[1] *= 0.95f;
					ent.vel[0] *= 0.95f;
					ent.pos[2] = sector.low;
				}
				success = true;
				break;
			}
		}
		
		
		if(!success)
		{
			ent.vel = 0;
			//ent.cursector = -1;
			if(ent.cursector < sectors.length)
			{
				Sector sector = sectors[ent.cursector];
				if(ent.pos[2]+camheight >= sector.high)
				{
					ent.pos[2] = sector.high-camheight;
				}
				else if(ent.pos[2] <= sector.low)
				{
					ent.pos[2] = sector.low;
				}
			}
		}
		else
		{
			ent.pos = ent.pos + ent.vel;
		}
	}
	
	void Player_Think(ulong playerindex, ref Entity ent)
	{
		if(ent.pressed)
		{
			foreach(i, ref other; entities)
			{
				if(other.behavior != 1)
				{
					continue;
				}
				if(*(other.pos-ent.pos) < 1)
				{
					if(entities[ent.parent].parent == i)
					{
						continue;
					}
					other.parent = playerindex;
					other.localpos = [0.0f,0.0f,2.1f];
				}
			}
		}
	}
	
	void Item_Think(ref Entity ent)
	{
		if(ent.parent == -1)
		{
			return;
		}
		Entity other = entities[ent.parent];
		if(other.behavior != 0)
		{
			return;
		}
		if(!other.pressed)
		{
			ent.localpos = [0.0f,0.0f,0.0f];
			ent.vel = other.vel+float3([sin(other.rot)*0.1f,-cos(other.rot)*0.1f,0.1f]);
			ent.parent = -1;
		}
	}
	
	void Trigger_Think(ulong entindex, ref Entity ent)
	{
		bool success = false;
		foreach(i, ref other; entities)
		{
			if(!((1<<other.behavior)&(ent.flags)))
			{
				continue;
			}
			if(*(other.pos-ent.pos) < 1)
			{
				if(!ent.pressed)
				{
					if(ent.trigger != -1)
					{
						ExecuteTrigger(ent.trigger);
					}
				}
				success = true;
				ent.pressed = true;
			}
		}
		if(!success)
		{
			ent.pressed = false;
		}
	}

	void Tick()
	{
		camforward = float3([sin(camrot)*cos(campitch),-cos(camrot)*cos(campitch),-sin(campitch)]);
		camright = float3([cos(camrot),sin(camrot),0.0f]);
		camup = float3([sin(camrot)*sin(campitch),cos(camrot)*sin(campitch),-cos(campitch)]);
		foreach(i, ref entity; entities)
		{
			IN_Move(entity);
			switch(entity.behavior)
			{
				case 0:
					Player_Think(i, entity);
					break;
				case 1:
					Item_Think(entity);
					break;
				case 2:
					Trigger_Think(i, entity);
					break;
				default:
					break;
			}
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
	
		
	void LoadMap(string mapname)
	{
		File* mapfile = new File(mapname,"rb");
		ulong[5] lengths = mapfile.rawRead(new ulong[5]);
		
		
		verts = mapfile.rawRead(new float2[lengths[0]]);
		edges = mapfile.rawRead(new Edge[lengths[1]]);
		SaveSector[] savesectors = mapfile.rawRead(new SaveSector[lengths[2]]);
		textures = mapfile.rawRead(new Texture[lengths[3]]);
		SaveModel[] savemodels = mapfile.rawRead(new SaveModel[lengths[4]]);
		
		sectors = [];
		foreach(savesector; savesectors)
		{
			ulong[] edgeindices;
			foreach(i;savesector.edgestart..savesector.edgestart+savesector.edgecount)
			{
				edgeindices ~= i;
			}
			
			sectors ~= Sector(
				edges:edgeindices,
				high:savesector.high,
				low:savesector.low,
				ceilingtex:savesector.ceilingtex,
				floortex:savesector.floortex);
		}
		
		models = [];
		
		foreach(savemodel; savemodels)
		{
			Model model;
			foreach(i;savemodel.sectorstart..savemodel.sectorstart+savemodel.sectorcount)
			{
				model.sectors ~= i;
			}
			models ~= model;
		}
		mapfile.close();
	}
	
	void LoadModel(string mapname)
	{
		File* mapfile = new File(mapname,"rb");
		ulong[5] lengths = mapfile.rawRead(new ulong[5]);
		
		
		auto mapverts = mapfile.rawRead(new float2[lengths[0]]);
		auto mapedges = mapfile.rawRead(new Edge[lengths[1]]);
		SaveSector[] savesectors = mapfile.rawRead(new SaveSector[lengths[2]]);
		auto maptextures = mapfile.rawRead(new Texture[lengths[3]]);
		SaveModel[] savemodels = mapfile.rawRead(new SaveModel[lengths[4]]);
		
		foreach(ref mapedge; mapedges)
		{
			mapedge.start += verts.length;
			mapedge.end += verts.length;
			mapedge.portal += sectors.length;
			mapedge.texture += textures.length;
		}
		
		Model model;
		
		foreach(savesector; savesectors)
		{
			ulong[] edgeindices;
			foreach(i;savesector.edgestart..savesector.edgestart+savesector.edgecount)
			{
				edgeindices ~= i+edges.length;
			}
			
			model.sectors ~= sectors.length;
			sectors ~= Sector(
				edges:edgeindices,
				high:savesector.high,
				low:savesector.low,
				ceilingtex:savesector.ceilingtex+textures.length,
				floortex:savesector.floortex+textures.length);
		}
		
		verts ~= mapverts;
		edges ~= mapedges;
		textures ~= maptextures;
		models ~= model;
		mapfile.close();
	}
	
	void delegate(ulong) ExecuteTrigger;

	float2 campos = float2([0.0f,0.0f]);
	float camposz = 0.0f;
	float camheight = 1.8f;
	float camrot = 0.0f;
	float campitch = 0.0f;
	float3 camup = float3([0.0f,0.0f,-1.0f]);
	float3 camforward = float3([0.0f,-1.0f,0.0f]);
	float3 camright = float3([1.0f,0.0f,0.0f]);
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

struct SaveModel
{
	ulong sectorstart;
	ulong sectorcount;
}