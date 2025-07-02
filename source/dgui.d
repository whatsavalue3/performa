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
		tx += this.x;
		ty += this.y;
		Draw(renderer);
		foreach(Panel child; children)
		{
			child.InternalDraw(renderer);
		}
		tx -= this.x;
		ty -= this.y;
	}
	
	void Draw(SDL_Renderer* renderer)
	{
		DGUI_DrawBeveledRect(renderer, 0, 0, width, height, border, invert_rect);
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
	
	void MouseMove(int cx, int cy, int rx, int ry, uint button)
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

	override void Draw(SDL_Renderer* renderer)
	{
		super.Draw(renderer);
		DGUI_DrawText(renderer, x, y, text);
	}

	string text;
}

public Panel mainpanel;
public Panel focusedpanel;
public byte* fontbuffer;

int tx = 0;
int ty = 0;

void DGUI_DrawBeveledRect(SDL_Renderer* renderer, int x, int y, int width, int height, int border, bool invert = false) {
	SDL_SetRenderDrawColor(renderer, 32, 32, 32, 255);
	x += tx;
	y += ty;
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

void DGUI_FillRect(SDL_Renderer* renderer, int x, int y, int w, int h)
{
	auto r = SDL_Rect(x+tx, y+ty, w, h);
	SDL_RenderFillRect(renderer,&r);
}

void DGUI_RenderCopy(SDL_Renderer* renderer, SDL_Texture* tex, int x, int y, int w, int h)
{
	auto src = SDL_Rect(0, 0, w, h);
	auto dst = SDL_Rect(x+tx, y+ty, w, h);
	SDL_RenderCopy(renderer,tex,&src,&dst);
}


void DGUI_DrawLine(SDL_Renderer* renderer, int x1, int y1, int x2, int y2)
{
	SDL_RenderDrawLine(renderer, x1+tx, y1+ty, x2+tx, y2+ty);
}

void DGUI_DrawPoint(SDL_Renderer* renderer, int x, int y)
{
	SDL_RenderDrawPoint(renderer, x+tx, y+ty);
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

void DGUI_MouseMove(int x, int y, int rx, int ry, uint button)
{
	if(focusedpanel !is null)
	{
		Panel parent = focusedpanel;
		while(parent !is null)
		{
			x -= parent.x;
			y -= parent.y;
			parent = parent.parent;
		}
		focusedpanel.MouseMove(x,y,rx,ry,button);
	}
}

void DGUI_HandleKey(uint chr)
{
	if(focusedpanel !is null)
	{
		focusedpanel.Type(chr);
	}
}

int character_width = 16;
int character_height = 16;
int character_advance = 8;

void DGUI_DrawText(SDL_Renderer* renderer, int x, int y, string text)
{
	SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
	int x_offset = x;
	int y_offset = y;
	foreach(int character; text)
	{
		ulong gy = 4095-((character>>8)<<4);
		ulong gx = ((character&0xff)<<4) - 16;
		ulong get_from = (gx+gy*4096)/8;
		
		foreach(int r; 0..character_height)
		{
			foreach(int b; 0..2)
			{
				foreach_reverse(int p; 0..8)
				{
					if((fontbuffer[get_from] & (1 << p)) == 0)
					{
						DGUI_DrawPoint(renderer, x_offset, y_offset);
					}
					x_offset += 1;
				}
				get_from += 1;
			}
			x_offset -= character_width;
			y_offset += 1;
			get_from -= 4096/8+2;
		}

		y_offset -= character_height;
		x_offset += character_advance;
	}
}

static this()
{
	auto fontfile = File("unifont-16.0.01.bmp","rb");
	auto fontpixels = fontfile.rawRead(new byte[fontfile.size()]);
	fontfile.close();
	fontbuffer = fontpixels.ptr;
}
