import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import game;
import math;

uint SampleTexture(float2 uv, uint[] pixels, uint width, uint height)
{
	ulong x = cast(ulong)((uv[0]%1.0f)*width);
	ulong y = cast(ulong)((uv[1]%1.0f)*height);
	
	return pixels[x+y*width];
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
			float nx = 1.0f-cast(float)(x)/width*2;
			float2 rdir = ~(camdir + float2([camdir[1]*nx,-camdir[0]*nx]));
			
			
			
			foreach(y; 0..height/2)
			{
				foreach(sector; sectors)
				{
					float3 cdir = ~float3([rdir[0],rdir[1],0.5f-cast(float)(y)/height]);
					float cdot = (sector.high*height*0.05f)/cdir[2];
					float2 chit = rdir*cdot;
					
					bool fail = false;
					
					foreach(edgeindex; sector.edges)
					{
						Edge edge = edges[edgeindex];
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
						continue;
					}
					
					ulong i = (x+y*320)*4;
					pix[i+1] = cast(ubyte)(chit[0]+campos[0]*0.05f*height);
					pix[i+2] = cast(ubyte)(chit[1]+campos[1]*0.05f*height);
					pix[i+3] = 0;
				}
			}
			
			foreach(y; height/2..height)
			{
				foreach(sector; sectors)
				{
					float3 cdir = ~float3([rdir[0],rdir[1],0.5f-cast(float)(y)/height]);
					float cdot = (sector.low*height*0.05f)/cdir[2];
					float2 chit = rdir*cdot;
					
					bool fail = false;
					
					foreach(edgeindex; sector.edges)
					{
						Edge edge = edges[edgeindex];
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
						continue;
					}
					
					ulong i = (x+y*320)*4;
					pix[i+1] = cast(ubyte)(chit[0]+campos[0]*0.05f*height);
					pix[i+2] = cast(ubyte)(chit[1]+campos[1]*0.05f*height);
					pix[i+3] = 0;
				}
			}
			
			foreach(edge; edges)
			{
				float2 start = (verts[edge.start]-campos)*0.05f;
				float2 end = (verts[edge.end]-campos)*0.05f;
				float2 diff = end-start;
				float ndist = sqrt(diff[0]*diff[0]+diff[1]*diff[1]);
				float2 n = float2([diff[1]/ndist,-diff[0]/ndist]);
				float wdist = sqrt(start[0]*start[0]+start[1]*start[1]);
				
				float2 wallv = float2([diff[0]/ndist,diff[1]/ndist]);
				
				float walldot = (n*rdir)/(start*n);
				
				float along = (rdir*(1/walldot)-start)*wallv;
				
				
				if(along < 0 || along > ndist)
				{
					continue;
				}
				
				
				
				
				if(walldot < 0)
				{
					continue;
				}

				
				
				int wally = cast(int)(walldot * edge.height * height * 0.05f);
				
				if(wally >= height)
				{
					continue;
				}
				
				int offset = cast(int)(walldot* edge.offset* height * 0.05f + height/2-wally);
				
				foreach(y; 0..wally)
				{
					ulong ry = cast(ulong)(y+offset);
					if(ry < 0 || ry >= 240)
					{
						continue;
					}
					ulong i = (x+ry*320)*4;
					pix[i+1] = cast(ubyte)(along*255/ndist);
					pix[i+2] = cast(ubyte)(y*255/wally);
					pix[i+3] = 127;
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