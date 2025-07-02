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
	
	bool DrawCeilingFloor(Sector sector, bool floor, float2 rdir, float3 cdir, out uint col)
	{
		if(sector.deleted)
		{
			return false;
		}
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
	
	bool DrawWalls(Sector sector, long y, float2 rdir, out uint col)
	{
		bool ret = false;
		foreach(edgeindex; sector.edges)
		{
			Edge edge = edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			float2 start = (verts[edge.start]-campos)*0.05f;
			float2 end = (verts[edge.end]-campos)*0.05f;
			float2 diff = end-start;
			float ndist = sqrt(diff[0]*diff[0]+diff[1]*diff[1]);
			float2 n = float2([diff[1]/ndist,-diff[0]/ndist]);
			float wdist = sqrt(start[0]*start[0]+start[1]*start[1]);
			
			float2 wallv = float2([diff[0]/ndist,diff[1]/ndist]);
			
			float ndot = n*rdir;
			
			float walldot = ndot/(start*n);
			
			float along = (rdir*(1/walldot)-start)*wallv;
			
			
			if(along < 0 || along > ndist)
			{
				continue;
			}
			
			
			
			
			if(ndot > 0)
			{
				continue;
			}

			
			
			int wally = cast(int)(walldot * (edge.height) * height * 0.05f);
			
			
			int offset = cast(int)(walldot* (edge.offset+camposz+camheight) * height * 0.05f + height/2-wally);
			
			if((y < offset) || (y > wally+offset))
			{
				continue;
			}
			
			if(edge.hidden)
			{
				float3 cdir = ~float3([rdir[0],rdir[1],0.5f-cast(float)(y)/height]);
				if(!DrawCeilingFloor(sectors[edge.portal],y > height/2,rdir,cdir,col))
				{
					ret |= DrawWalls(sectors[edge.portal],y,rdir,col);
				}
			}
			else
			{
				float2 uv = float2([along/ndist,cast(float)(y-offset)/wally]);
				col = SampleTexture(uv,texturedict[fromStringz(textures[edge.texture].name)]);
			}
			ret = true;
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
					if(DrawCeilingFloor(sectors[cursector],false,rdir,cdir,col))
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
					if(DrawCeilingFloor(sectors[cursector],true,rdir,cdir,col))
					{
						ulong i = (x+y*320)*4;
						pix[i+1] = cast(ubyte)(col);
						pix[i+2] = cast(ubyte)(col>>8);
						pix[i+3] = cast(ubyte)(col>>16);
					}
				}
				foreach(y; 0..height)
				{
					ulong i = (x+y*320)*4;
					uint col = 0;
					if(DrawWalls(sectors[cursector],y,rdir,col))
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