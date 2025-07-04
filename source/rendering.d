import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.file;
import std.string;
import game;
import math;
import std.algorithm;
import client;



uint SampleTexture(float2 uv, TextureData tex)
{
	ulong x = cast(ulong)(abs(uv[0]%1.0f)*tex.width);
	ulong y = cast(ulong)((1.0f-abs(uv[1]%1.0f))*tex.height);
	
	return tex.pixels[x+y*tex.width];
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
		//LoadTexture("trippy_floor.bmp");
		//LoadTexture("tired_sky.bmp");
	}
	
	bool DrawCeilingFloor(Sector sector, bool floor, float3 cdir, float3 castpos, out uint col)
	{
		if(sector.deleted)
		{
			return false;
		}
		float2 rdir = float2([cdir[0],cdir[1]]);
		float cdot;
		if(floor)
		{
			cdot = ((sector.low-castpos[2])*height*0.05f)/cdir[2];
		}
		else
		{
			cdot = ((sector.high-castpos[2])*height*0.05f)/cdir[2];
		}
		float2 chit = rdir*cdot;
		
		bool fail = false;
		
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			float2 n = g.EdgeNormal(edge);
			float dist = n*(g.verts[edge.start]-float2([castpos[0],castpos[1]]))*0.05f*height;
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
		
		float2 uv = float2([chit[0]+castpos[0]*0.05f*height,chit[1]+castpos[1]*0.05f*height])*0.01f;
		if(sector.ceilingtex < texturedict.length)
		{
			col = SampleTexture(uv,texturedict[sector.ceilingtex]);
		}
		return true;
	}
	
	bool DrawWalls(Sector sector, float3 cdir, float3 castpos, out uint col)
	{
		bool ret = false;
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			
			
			float3 start = (float3([g.verts[edge.start][0],g.verts[edge.start][1],-edge.offset])-castpos)*0.05f;
			float3 end = (float3([g.verts[edge.end][0],g.verts[edge.end][1],-edge.offset])-castpos)*0.05f;
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
				if(!DrawCeilingFloor(g.sectors[edge.portal],cdir[2] < 0,cdir,castpos,col))
				{
					ret |= DrawWalls(g.sectors[edge.portal],cdir,castpos,col);
				}
			}
			else
			{
				float2 uv = float2([along/ndist,1.0f-alongy/edge.height]);
				if(edge.texture >= g.textures.length)
				{
					col = 0xffff00ff;
				}
				else
				{
					if(edge.texture >= texturedict.length)
					{
						col = 0xff00ff00;
					}
					else
					{
						col = SampleTexture(uv,texturedict[edge.texture]);
					}
				}
			}
			ret = true;
		}
		
		foreach(ei,entity; g.entities)
		{
			if(ei == viewent)
			{
				continue;
			}
			float3 entpos = entity.pos;
			entpos[2] += 1.3f;
			float3 up = entpos-castpos;
			float3 p = ~(up);
			float cu = (cdir*up);
			if(cu < 0.0f)
			{
				continue;
			}
			float closeness = up*up - cu*cu;
			if(closeness < 1.0f)
			{
				float fresnel = sqrt(1.0f-closeness);
				float3 normal = ~(cdir-p*fresnel*2);
				if(!DrawCeilingFloor(sector,normal[2] < 0,normal,entpos+normal,col))
				{
					DrawWalls(sector,normal,entpos+normal,col);
				}
				float light = normal[2];
				light *= 6.0f;
				if(light < 0.2f)
				{
					light = 0.0f;
				}
				else if(light < 0.3f)
				{
					
				}
				else
				{
					light += 0.2f;
				}
				light = clamp(light,0.0f,10.0f);
				float R = cast(ubyte)(col>>16)+20;
				float G = cast(ubyte)(col>>8)+20;
				float B = cast(ubyte)(col)+20;
				fresnel = closeness;
				fresnel = fresnel*fresnel*1.8f+0.3f;
				
				R = ((R*fresnel*(0.25f+entity.color[0])*0.75f)+light*(0.25f+entity.color[0])*0.75f*255);
				G = ((G*fresnel*(0.25f+entity.color[1])*0.75f)+light*(0.25f+entity.color[1])*0.75f*255);
				B = ((B*fresnel*(0.25f+entity.color[2])*0.75f)+light*(0.25f+entity.color[2])*0.75f*255);
				R = clamp(R,0,255);
				G = clamp(G,0,255);
				B = clamp(B,0,255);
				col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
				ret = true;
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
		
		if(g.entities.length <= viewent)
		{
			return;
		}
		
		
		
		float3 castpos = g.entities[viewent].pos;
		SDL_SetRenderDrawColor(renderer, cast(ubyte)(g.entities[viewent].color[0]*255), cast(ubyte)(g.entities[viewent].color[1]*255), cast(ubyte)(g.entities[viewent].color[2]*255), 255);
		DGUI_FillRect(renderer,-1,-1,width+2,height+2);
		castpos[2] += g.camheight;
		pix[] = 0;
		foreach(x; 0..width)
		{
			float nx = (cast(float)(width)/height-cast(float)(x)/width*cast(float)(width)/height*2)*0.5f;
			float snx = sin(nx);
			float cnx = cos(nx);
			
			
			
			
			if(g.sectors.length != 0)
			{
				foreach(y; 0..height)
				{
					float ny = (0.5f-cast(float)(y)/height);
					float sny = sin(ny);
					float cny = cos(ny);
					float2 rdir = (g.camdir*cnx + float2([g.camdir[1],-g.camdir[0]])*snx*(1.0/cny));
					float3 cdir = ~float3([rdir[0]*cny,rdir[1]*cny,sny]);
					ulong i = (x+y*320)*4;
					uint col = 0;
					if(DrawWalls(g.sectors[g.entities[viewent].cursector],cdir,castpos,col) || DrawCeilingFloor(g.sectors[g.entities[viewent].cursector],cdir[2] < 0,cdir,castpos,col))
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
			g.camrot += cast(float)(rx)/width;
		}
	}
}