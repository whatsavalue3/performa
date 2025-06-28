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
	
	final void InternalDraw(int x, int y)
	{
		if(hidden)
		{
			return;
		}
		PerformLayout();
		Draw(x + this.x, y + this.y);
		foreach(Panel child; children)
		{
			child.InternalDraw(x + offsetx + this.x, y + offsety + this.y);
		}
	}
	
	void DrawBackground(SDL_Renderer* renderer, int x, int y)
	{
		SDL_SetRenderDrawColor(renderer, 32, 32, 32, 255);
		SDL_RenderDrawRect(renderer, &SDL_Rect(x, y, width, height));
	}
	
	void Draw(SDL_Renderer* renderer, int x, int y)
	{
		DrawBackground(renderer, x, y);
		
		SDL_SetRenderDrawColor(renderer, 255,255,255,255);
		SDL_RenderDrawLine(renderer, x, y+1, x+width, y+1);
		SDL_RenderDrawLine(renderer, x+1, y, x+1, y+height);
		SDL_SetRenderDrawColor(renderer, 0,0,0,255);
		SDL_RenderDrawLine(renderer, x, y, x+width, y+height);
		SDL_RenderDrawLine(renderer, x+width, y, x+width, y+height);
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
	Panel[] children;
	Panel parent;
	bool hidden = false;
}

void DGUI_DrawText(int x, int y, string text, int limitwidth = 256)
{
	glRasterPos2i(x,y);
	int ln = 0;
	int curpos = 0;
	foreach(char c; text)
	{
		uint chr = cast(uint)c;
		chr = ((chr&1)<<1)+((chr&0xfe)<<5);
		if(c == '\n')
		{
			ln += 16;
			curpos = 0;
			glRasterPos2i(x,y+ln);
		}
		else
		{
			if(curpos+8 > limitwidth)
			{
				curpos = 0;
				ln += 16;
				glRasterPos2i(x,y+ln);
			}
			curpos += 8;
			glBitmap(16,16,0,0,8,0,(cast(GLubyte*)fontbuffer)+chr);
		}
	}
}

public Panel mainpanel;
public Panel focusedpanel;
public byte* fontbuffer;

void DGUI_CaptureFocus(Panel panel)
{
	focusedpanel = panel;
}

void DGUI_Draw(int x, int y, int width, int height)
{
	mainpanel.width = width;
	mainpanel.height = height;
	
	mainpanel.InternalDraw(x, y);
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
	if(focusedpanel != panel && action == GLFW_RELEASE)
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
