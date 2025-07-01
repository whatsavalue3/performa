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

	this(Panel p)
	{
		super(p);
		width = 320;
		height = 240;
	}
	
	override void Draw(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		
		DGUI_FillRect(renderer, 0, 0, width, height);
		
		SDL_SetRenderDrawColor(renderer, 127, 127, 127, 255);
		
		dir = float2([0.0f,1.0f]);
		pos = float2([0.0f,0.0f]);
		
		foreach(x; 0..width)
		{
			float nx = 1.0f-((float)(x)/width)*2.0f;
			float2 rdir = ~(dir + float2([dir[1]*nx,-dir[0]*nx]));
			foreach(edge; edges)
			{
				float2 start = verts[edge.start]-pos;
				float2 end = verts[edge.end]-pos;
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
				
				//float dot = (rdir*n)*height/2;
				
				
				
				if(walldot < 0)
				{
					continue;
				}
				walldot *= height;
				
				DGUI_DrawLine(renderer,x,height/2-cast(int)walldot,x,height/2+cast(int)walldot);
			}
		}
	}
}