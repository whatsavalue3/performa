import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.file;
import std.string;
import game;
import math;


struct TextureData
{
	uint width;
	uint height;
	uint* pixels;
}

TextureData[string] texturedict;

uint SampleTexture(float2 uv, TextureData tex)
{
	ulong x = cast(ulong)(abs(uv[0]%1.0f)*tex.width);
	ulong y = cast(ulong)((1.0f-abs(uv[1]%1.0f))*tex.height);
	
	return tex.pixels[x+y*tex.width];
}

struct BMPHeader
{
	align(1):
	ubyte[10] padding;
	uint startOfImg;
}

ulong LoadTexture(string name)
{
	ubyte* data = cast(ubyte*)read(name).ptr;
	BMPHeader* bhdr = cast(BMPHeader*)data;

	writeln(bhdr.startOfImg);

	texturedict[name] = TextureData(width:*cast(uint*)(data+18),height:*cast(uint*)(data+22),pixels:cast(uint*)(data+bhdr.startOfImg));
	textures ~= Texture();
	textures[$-1].name[] = name[];
	return textures.length-1;
}

class ViewportPanel : Panel
{
	
	SDL_Texture* tex = null;
	ubyte[320*240*4] pix;
	
	ulong time = 0;
	
	this(Panel p)
	{
		super(p);
		width = 320;
		height = 240;
		LoadTexture("trippy_floor.bmp");
		LoadTexture("tired_sky.bmp");
	}
	
	bool DrawCeilingFloor(Sector sector, bool floor, float3 cdir, out uint col)
	{
		if(sector.deleted)
		{
			return false;
		}
		float2 rdir = float2([cdir[0],cdir[1]]);
		float cdot;
		if(floor)
		{
			cdot = ((sector.low-camposz-camheight)*height*0.05f)/cdir[2];
		}
		else
		{
			cdot = ((sector.high-camposz-camheight)*height*0.05f)/cdir[2];
		}
		float2 chit = rdir*cdot;
		
		bool fail = false;
		
		foreach(edgeindex; sector.edges)
		{
			Edge edge = edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			float2 n = EdgeNormal(edge);
			float dist = n*(verts[edge.start]-campos)*0.05f*height;
			float score = chit*n - dist;
			if(score < 0)
			{
				fail = true;
				break;
			}
		}
		if(fail)
		{
			return false;
		}
		
		float2 uv = float2([chit[0]+campos[0]*0.05f*height,chit[1]+campos[1]*0.05f*height])*0.01f;
		col = SampleTexture(uv,texturedict[fromStringz(textures[sector.ceilingtex].name)]);
		return true;
	}
	
	bool DrawWalls(Sector sector, float3 cdir, float3 castpos, out uint col)
	{
		//
		bool ret = false;
		foreach(edgeindex; sector.edges)
		{
			Edge edge = edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			
			
			float3 start = (float3([verts[edge.start][0],verts[edge.start][1],-edge.offset])-castpos)*0.05f;
			float3 end = (float3([verts[edge.end][0],verts[edge.end][1],-edge.offset])-castpos)*0.05f;
			float3 diff = end-start;
			float ndist = sqrt(diff[0]*diff[0]+diff[1]*diff[1]);
			float3 n = float3([diff[1]/ndist,-diff[0]/ndist, 0.0f]);
			float wdist = sqrt(start[0]*start[0]+start[1]*start[1]);
			
			float3 wallv = float3([diff[0]/ndist,diff[1]/ndist,0.0f]);
			
			float ndot = n*cdir;
			
			float walldot = ndot/(start*n);
			
			float3 proj = (cdir*(1/walldot)-start);
			
			float along = proj*wallv;
			float alongy = proj[2]/0.05f;
			
			
			
			if(along < 0 || along > ndist)
			{
				continue;
			}
			
			
			
			
			if(ndot > 0)
			{
				continue;
			}

			
			
			//int wally = cast(int)(walldot * (edge.height) * 0.05f);
			
			
			//int offset = cast(int)(walldot* (edge.offset+camposz+camheight) * 0.05f - wally);
			
			if((alongy < 0) || (alongy > edge.height))
			{
				continue;
			}
			
			if(edge.hidden)
			{
				if(!DrawCeilingFloor(sectors[edge.portal],cdir[2] < 0,cdir,col))
				{
					ret |= DrawWalls(sectors[edge.portal],cdir,castpos,col);
				}
			}
			else
			{
				float2 uv = float2([along/ndist,1.0f-alongy/edge.height]);
				col = SampleTexture(uv,texturedict[fromStringz(textures[edge.texture].name)]);
			}
			ret = true;
		}
		
		foreach(entity; entities)
		{
			float3 up = entity.pos-castpos;
			float3 p = ~(up);
			float closeness = (cdir*p)^^0.5f;
			float th = 1.0f-1.0f/(*up);
			if(closeness > th)
			{
				float3 normal = ~(cdir*(1.0-closeness)*(*up)-p);
				if(!DrawCeilingFloor(sector,normal[2] < 0,normal,col))
				{
					DrawWalls(sector,normal,entity.pos+normal,col);
				}
				ret = true;
				/*
				ubyte r = cast(ubyte)(normal[0]*127+127);
				ubyte g = cast(ubyte)(normal[1]*127+127);
				ubyte b = cast(ubyte)(normal[2]*127+127);
				col = r | (g << 8) | (b << 16);
				ret = true;
				*/
			}
		}
		return ret;
	}
	
	
	override void Draw(SDL_Renderer* renderer)
	{
		this.time++;
		if(tex is null)
		{
			tex = SDL_CreateTexture(renderer,SDL_PIXELFORMAT_RGBA8888,SDL_TEXTUREACCESS_STREAMING,320,240);
		}
	
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		
		DGUI_FillRect(renderer, 0, 0, width, height);
		
		SDL_SetRenderDrawColor(renderer, 127, 127, 127, 255);
		
		pix[] = 0;
		foreach(x; 0..width)
		{
			float nx = cast(float)(width)/height-cast(float)(x)/width*cast(float)(width)/height*2;
			float2 rdir = ~(camdir + float2([camdir[1]*nx,-camdir[0]*nx]));
			
			
			
			if(sectors.length != 0)
			{
				foreach(y; 0..height/2)
				{
					float3 cdir = ~float3([rdir[0],rdir[1],0.5f-cast(float)(y)/height]);
					uint col = 0;
					if(DrawCeilingFloor(sectors[cursector],false,cdir,col))
					{
						ulong i = (x+y*320)*4;
						pix[i+1] = cast(ubyte)(col);
						pix[i+2] = cast(ubyte)(col>>8);
						pix[i+3] = cast(ubyte)(col>>16);
					}
				}
				
				foreach(y; height/2..height)
				{
					float3 cdir = ~float3([rdir[0],rdir[1],0.5f-cast(float)(y)/height]);
					uint col = 0;
					if(DrawCeilingFloor(sectors[cursector],true,cdir,col))
					{
						ulong i = (x+y*320)*4;
						pix[i+1] = cast(ubyte)(col);
						pix[i+2] = cast(ubyte)(col>>8);
						pix[i+3] = cast(ubyte)(col>>16);
					}
				}
				foreach(y; 0..height)
				{
					float3 cdir = ~float3([rdir[0],rdir[1],0.5f-cast(float)(y)/height]);
					ulong i = (x+y*320)*4;
					uint col = 0;
					if(DrawWalls(sectors[cursector],cdir,float3([campos[0],campos[1],camposz+camheight]),col))
					{
						pix[i+1] = cast(ubyte)(col);
						pix[i+2] = cast(ubyte)(col>>8);
						pix[i+3] = cast(ubyte)(col>>16);
					}
				}
			}
			
			
		}
		auto rec = SDL_Rect(0, 0, 320, 240);
		SDL_UpdateTexture(tex,&rec,pix.ptr,320*4);
		DGUI_RenderCopy(renderer,tex,0,0,width,height);
	}
	
	override void MouseMove(int cx, int cy, int rx, int ry, uint button)
	{
		if(button == 1)
		{
			camrot += cast(float)(rx)/width;
		}
	}
}