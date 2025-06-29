import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;

struct Edge
{
	ulong start;
	ulong end;
}

class MapPreview : Panel
{
	SDL_Point[] verts;
	Edge[] edges;
	ulong selected = 0;

	this(Panel p)
	{
		super(p);
		width = 320;
		height = 240;
	}
	
	override void Draw(SDL_Renderer* renderer, int x, int y)
	{
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		auto r = SDL_Rect(x, y, width, height);
		SDL_RenderFillRect(renderer, &r);
		
		SDL_SetRenderDrawColor(renderer, 255, 127, 64, 255);
		
		foreach(i, edge; edges)
		{
			SDL_Point start = verts[edge.start];
			SDL_Point end = verts[edge.end];
			SDL_RenderDrawLine(renderer,start.x+x+width/2,start.y+y+height/2,end.x+x+width/2,end.y+y+height/2);
		}
		
		foreach(i, vert;verts)
		{
			if(i == selected)
			{
				SDL_SetRenderDrawColor(renderer, 96, 255, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			SDL_RenderDrawPoint(renderer,vert.x+x+width/2,vert.y+y+height/2);
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
			foreach(i, vert; verts)
			{
				int dist = (abs(vert.x-(cx-width/2)) + abs(vert.y-(cy-height/2)));
				if(dist < 8)
				{
					selected = i;
					break;
				}
			}
		}
		else if(button == 2)
		{
			verts[selected].x = cx - width/2;
			verts[selected].y = cy - height/2;
		}
		else if(button == 3)
		{
			foreach(i, vert; verts)
			{
				int dist = (abs(vert.x-(cx-width/2)) + abs(vert.y-(cy-height/2)));
				if(dist < 8)
				{
					edges ~= Edge(start:selected, end:i);
					break;
				}
			}
		}
	}
}

class MapEditor : Panel
{
	MapPreview preview;
	Panel[] toolbar;
	
	this()
	{
		toolbar ~= new Button(this, "Add Section", &AddSection);
		preview = new MapPreview(this);
		
	}
	
	override void PerformLayout()
	{
		preview.x = 16;
		preview.y = 16;
		preview.width = 320;
		preview.height = 240;
	}
	
	void AddSection()
	{
		preview.verts ~= SDL_Point(x:0,y:0);
	}
}