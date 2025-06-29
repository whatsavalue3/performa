module dgui;
import std.stdio;
import std.algorithm;
import std.process;
import std.array;
import std.parallelism;
import std.string;
import std.conv;
import std.ascii;
import bindbc.sdl;

/*extern(C) nothrow @nogc
{
	alias pglBitmap = void function(GLsizei, GLsizei, GLfloat, GLfloat,GLfloat, GLfloat, GLubyte*);
}

public pglBitmap glBitmap;*/

class Panel
{
	this(Panel newparent)
	{
		newparent.children ~= this;
		parent = newparent;
	}
	this()
	{
		
	}
	
	~this()
	{
		if(parent is null)
		{
			return;
		}
		foreach(i, Panel child; parent.children)
		{
			if(child == this)
			{
				parent.children = parent.children.remove(i);
				return;
			}
		}
	}
	
	final void InternalDraw(SDL_Renderer* renderer, int x, int y)
	{
		if(hidden)
		{
			return;
		}
		PerformLayout();
		Draw(renderer, x + this.x, y + this.y);
		foreach(Panel child; children)
		{
			child.InternalDraw(renderer, x + offsetx + this.x, y + offsety + this.y);
		}
	}
	
	void DrawBackground(SDL_Renderer* renderer, int x, int y)
	{
		SDL_SetRenderDrawColor(renderer, 32, 32, 32, 255);
		auto r = SDL_Rect(x, y, width, height);
		SDL_RenderFillRect(renderer, &r);
	}
	
	void Draw(SDL_Renderer* renderer, int x, int y)
	{
		DrawBackground(renderer, x, y);

		foreach(inset; 0..border)
		{
			SDL_SetRenderDrawColor(renderer, 255,255,255,255);
			SDL_RenderDrawLine(renderer, x+border, y+inset, x+width-inset-1, y+inset);
			SDL_RenderDrawLine(renderer, x+inset, y, x+inset, y+height-inset-1);
			SDL_SetRenderDrawColor(renderer, 0,0,0,255);
			SDL_RenderDrawLine(renderer, x+inset, y+height-inset-1, x+width-border-1, y+height-inset-1);
			SDL_RenderDrawLine(renderer, x+width-inset-1, y+inset, x+width-inset-1, y+height-1);
		}
	}
	
	void PerformLayout()
	{
		
	}
	
	bool HasHit(int hx, int hy)
	{
		return hx >= 0 && hy >= 0 && hx < width && hy < height;
	}
	
	void Click(int cx, int cy, int button, int action)
	{
		
	}
	
	void ClickReleased(int cx, int cy, int button, Panel otherpanel)
	{
		
	}
	
	void Type(uint chr)
	{
	
	}
	
	void LayoutHorizontally(int offset = 0, bool stretch = false)
	{
		int curx = 0;
		foreach(Panel child; children)
		{
			child.x = curx;
			curx += child.width + offset;
		}
		if(stretch)
		{
			width = curx+offsetx;
		}
	}
	
	void LayoutVertically(int offset = 0, bool stretch = false)
	{
		int cury = 0;
		foreach(Panel child; children)
		{
			child.y = cury;
			cury += child.height+offset;
		}
		if(stretch)
		{
			height = cury+offsety;
		}
	}
	
	void Stretch()
	{
		int curx = 0;
		int cury = 0;
		foreach(Panel child; children)
		{
			curx = max(curx,child.x+child.width+child.offsetx);
			cury = max(cury,child.y+child.height+child.offsety);
		}
		width = curx+offsetx;
		height = cury+offsety;
	}
	
	void Center()
	{
		this.x = (this.parent.width-this.width)/2;
		this.y = (this.parent.height-this.height)/2;
	}
	
	void MoveToFront()
	{
		if(parent is null)
		{
			return;
		}
		foreach(i, Panel child; parent.children)
		{
			if(child == this)
			{
				parent.children = parent.children.remove(i);
				parent.children ~= this;
				return;
			}
		}
	}
	
	int x = 0;
	int y = 0;
	int offsetx = 0;
	int offsety = 0;
	int width = 16;
	int height = 16;
	int border = 4;
	Panel[] children;
	Panel parent;
	bool hidden = false;
}


public Panel mainpanel;
public Panel focusedpanel;
public byte* fontbuffer;

void DGUI_CaptureFocus(Panel panel)
{
	focusedpanel = panel;
}

void DGUI_Draw(SDL_Renderer* renderer)
{
	int width;
	int height;

	SDL_GetRendererOutputSize(renderer, &width, &height);

	mainpanel.width = width;
	mainpanel.height = height;
	
	mainpanel.InternalDraw(renderer, 0, 0);
}

bool DGUI_TraverseHitPanel(Panel panel, int x, int y, int button, int action)
{
	if(panel.hidden)
	{
		return false;
	}
	x -= panel.x;
	y -= panel.y;
	if(!panel.HasHit(x,y))
	{
		return false;
	}
	x -= panel.offsetx;
	y -= panel.offsety;
	foreach_reverse(Panel child; panel.children)
	{
		if(DGUI_TraverseHitPanel(child,x,y,button,action))
		{
			return true;
		}
	}
	if(focusedpanel != panel && action == 1)
	{
		focusedpanel.ClickReleased(x, y, button, panel);
	}
	else
	{
		DGUI_CaptureFocus(panel);
		panel.Click(x, y, button, action);
	}
	return true;
}

void DGUI_HandleMouse(int x, int y, int button, int action)
{
	DGUI_TraverseHitPanel(mainpanel,x,y,button,action);
}

void DGUI_HandleKey(uint chr)
{
	if(focusedpanel !is null)
	{
		focusedpanel.Type(chr);
	}
}


static this()
{
	auto fontfile = File("unifont2","rb");
	auto fontpixels = fontfile.rawRead(new byte[fontfile.size()]);
	fontfile.close();
	fontbuffer = fontpixels.ptr;
	
}
