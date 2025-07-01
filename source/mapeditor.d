import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import game;
import math;
import rendering;

class MapPreview : Panel
{
	
	long selected = -1;
	long selectededge = -1;

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
		
		
		
		foreach(i, edge; edges)
		{
			float2 start = verts[edge.start];
			float2 end = verts[edge.end];
			
			if(i == selectededge)
			{
				SDL_SetRenderDrawColor(renderer, 64, 127, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 127, 64, 255);
			}
			
			DGUI_DrawLine(renderer,cast(int)(start[0]+width/2),cast(int)(start[1]+height/2),cast(int)(end[0]+width/2),cast(int)(end[1]+height/2));
			
			
		}
		
		foreach(i, vert; verts)
		{
			if(i == selected)
			{
				SDL_SetRenderDrawColor(renderer, 96, 255, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2+1),cast(int)(vert[1]+height/2));
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2  ),cast(int)(vert[1]+height/2+1));
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2  ),cast(int)(vert[1]+height/2-1));
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2-1),cast(int)(vert[1]+height/2));
		}

	}
	
	override void MouseMove(int cx, int cy, int rx, int ry, uint button)
	{
		if(selected != -1)
		{
			if(button == 1)
			{
				verts[selected][0] = cx - width/2;
				verts[selected][1] = cy - height/2;
			}
		}
	}
	
	
	
	override void Click(int cx, int cy, int button, int action)
	{
		if(action == SDL_RELEASED)
		{
			return;
		}
		
		if(button == 1)
		{
			selected = -1;
			selectededge = -1;
			foreach(i, vert; verts)
			{
				float dist = (abs(vert[0]-(cx-width/2)) + abs(vert[1]-(cy-height/2)));
				if(dist < 8)
				{
					selected = i;
					return;
				}
			}
			
			foreach(i, edge; edges)
			{
				float2 start = verts[edge.start];
				float2 end = verts[edge.end];
				float lx = cx-width/2-start[0];
				float ly = cy-height/2-start[1];
				float endx = end[0]-start[0];
				float endy = end[1]-start[1];
				float endlen = sqrt(endx*endx+endy*endy);
				float normx = endx/endlen;
				float normy = endy/endlen;
				float forward = normx*lx + normy*ly;
				float side = abs(normx*ly - normy*lx);
				if(forward > 0 && forward < endlen && side < 5)
				{
					selectededge = i;
					return;
				}
			}
		}
		else if(button == 2)
		{
			if(selected == -1)
			{
				return;
			}
			verts[selected][0] = cx - width/2;
			verts[selected][1] = cy - height/2;
		}
		else if(button == 3)
		{
			if(selected == -1)
			{
				return;
			}
			foreach(i, vert; verts)
			{
				float dist = (abs(vert[0]-(cx-width/2)) + abs(vert[1]-(cy-height/2)));
				if(dist < 8)
				{
					edges ~= Edge(start:selected, end:i);
					break;
				}
			}
		}
	}
}

class Toolbar : Panel
{
	this(Panel p)
	{
		super(p);
		height = 100;
		width = 500;
	}
}

class MapEditor : Panel
{
	MapPreview preview;
	ViewportPanel viewport;
	Panel toolbar;
	
	this()
	{
		padding_top = 16;
		padding_bottom = 16;
		padding_left = 16;
		padding_right = 16;
		gap = 16;
		preview = new MapPreview(this);
		toolbar = new Toolbar(this);
		viewport = new ViewportPanel(this);
		new Button(toolbar, "Add Section", &AddSection);
		
	}
	
	void AddSection()
	{
		verts ~= float2([0.0f,0.0f]);
	}
}
