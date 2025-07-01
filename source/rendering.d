import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import game;
import math;

class ViewportPanel : Panel
{
	float2 pos;
	float2 dir;
	SDL_Texture* tex = null;
	ubyte[320*240*4] pix;
	
	
	this(Panel p)
	{
		super(p);
		width = 320;
		height = 240;
		
	}
	
	override void Draw(SDL_Renderer* renderer)
	{
		if(tex is null)
		{
			tex = SDL_CreateTexture(renderer,SDL_PIXELFORMAT_RGBA8888,SDL_TEXTUREACCESS_STREAMING,320,240);
		}
	
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		
		DGUI_FillRect(renderer, 0, 0, width, height);
		
		SDL_SetRenderDrawColor(renderer, 127, 127, 127, 255);
		
		dir = float2([0.0f,1.0f]);
		pos = float2([0.0f,0.0f]);
		pix[] = 0;
		foreach(x; 0..width)
		{
			float nx = 0.5f-((float)(x)/width);
			float2 rdir = ~(dir + float2([dir[1]*nx,-dir[0]*nx]));
			foreach(edge; edges)
			{
				float2 start = verts[edge.start]*0.05f-pos;
				float2 end = verts[edge.end]*0.05f-pos;
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

				
				
				int wally = cast(int)(walldot * edge.height);
				
				if(wally >= height)
				{
					continue;
				}
				
				float offset = edge.offset*walldot;
				
				foreach(y; 0..wally)
				{
					ulong ry = cast(ulong)(y+height/2-wally/2+offset);
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
}