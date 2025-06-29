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
	
	final void InternalDraw(SDL_Renderer* renderer)
	{
		if(hidden)
		{
			return;
		}
		PerformLayout();
		Draw(renderer);
		foreach(Panel child; children)
		{
			child.InternalDraw(renderer);
		}
	}
	
	void Draw(SDL_Renderer* renderer)
	{
		DGUI_DrawBeveledRect(renderer, x, y, width, height, border, invert_rect);
	}
	
	void PerformLayout()
	{
		PositionChildren();
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

	void FitWidth() {
		
	}

	void FitHeight() {
		
	}

	void PositionChildren() {
		int current_offset = border;
		if(vertical) {
			current_offset += padding_top;
		} else {
			current_offset += padding_left;
		}
		foreach(Panel child; children)
		{
			if(vertical) {
				child.x = border + padding_left;
				child.y = current_offset;
				current_offset += child.height;
			} else {
				child.x = current_offset;
				child.y = border + padding_top;
				current_offset += child.width;
			}
			current_offset += gap;
		}
	}
	
	void Stretch()
	{
		int curx = 0;
		int cury = 0;
		foreach(Panel child; children)
		{
			curx = max(curx,child.x+child.width);
			cury = max(cury,child.y+child.height);
		}
		width = curx;
		height = cury;
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
	int padding_top = 0;
	int padding_bottom = 0;
	int padding_left = 0;
	int padding_right = 0;
	int gap = 0;
	bool vertical = true;
	int width = 16;
	int height = 16;
	int border = 5;
	bool invert_rect = false;
	Panel[] children;
	Panel parent;
	bool hidden = false;
}

class Button : Panel
{
	this(Panel parent)
	{
		super(parent);
	}
	
	this(Panel parent, string origtext, void delegate() origcallback = null)
	{
		super(parent);
		text = origtext;
		callback = origcallback;
	}

	
	override void Click(int cx, int cy, int button, int action)
	{
		if(action == SDL_RELEASED)
		{
			invert_rect = false;
			state = false;
			if(callback !is null)
			{
				callback();
			}
		}
		else
		{
			invert_rect = true;
			state = true;
		}
	}
	bool state = false;
	void delegate() callback;
}

public Panel mainpanel;
public Panel focusedpanel;
public byte* fontbuffer;

void DGUI_DrawBeveledRect(SDL_Renderer* renderer, int x, int y, int width, int height, int border, bool invert = false) {
	SDL_SetRenderDrawColor(renderer, 32, 32, 32, 255);
	auto r = SDL_Rect(x, y, width, height);
	SDL_RenderFillRect(renderer, &r);


	border = min(border,min(width,height)/2);
	
	foreach(inset; 0..border)
	{
		ubyte w = cast(ubyte)((255-(32-255/border))/(inset+1)+(32-255/border));
		
		float bpoint = 32/border;
		float bplus = 32-32/(inset+1);
		float bmul = 32/(32-bpoint);
		
		ubyte b = cast(ubyte)(bplus*bmul);

		if(invert)
		{
			SDL_SetRenderDrawColor(renderer, b,b,b,255);
		}
		else
		{
			SDL_SetRenderDrawColor(renderer, w,w,w,255);
		}

		SDL_RenderDrawLine(renderer, x+inset, y+inset, x+width-inset-1, y+inset);
		SDL_RenderDrawLine(renderer, x+inset, y+inset, x+inset, y+height-inset-1);

		if(invert)
		{
			SDL_SetRenderDrawColor(renderer, w,w,w,255);
		}
		else
		{
			SDL_SetRenderDrawColor(renderer, b,b,b,255);
		}

		
		SDL_RenderDrawLine(renderer, x+inset, y+height-inset-1, x+width-inset-1, y+height-inset-1);
		SDL_RenderDrawLine(renderer, x+width-inset-1, y+inset, x+width-inset-1, y+height-inset-1);
	}
}

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
	
	mainpanel.InternalDraw(renderer);
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
	//x -= panel.offsetx;
	//y -= panel.offsety;
	foreach_reverse(Panel child; panel.children)
	{
		if(DGUI_TraverseHitPanel(child,x,y,button,action))
		{
			return true;
		}
	}
	if(focusedpanel != panel && action == SDL_RELEASED)
	{
		focusedpanel.ClickReleased(x, y, button, panel);
	}
	DGUI_CaptureFocus(panel);
	panel.Click(x, y, button, action);
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
