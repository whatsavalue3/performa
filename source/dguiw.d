module dguiw;
import std.algorithm;
import bindbc.sdl;
import std.stdio;

enum ScaleMode
{
	Fit,
	Grow,
	Fixed
}

class Panel
{
	int x = 0;
	int y = 0;
	int screen_x = 0;
	int screen_y = 0;
	int width = 100;
	int height = 100;
	int padding_top = 0;
	int padding_bottom = 0;
	int padding_left = 0;
	int padding_right = 0;
	int border = 5;
	int gap = 0;
	int needed_width = 0;
	int needed_height = 0;
	ScaleMode width_mode = ScaleMode.Fixed;
	ScaleMode height_mode = ScaleMode.Fixed;
	float align_x = 0.5f;
	float align_y = 0.5f;
	bool floating = false;
	bool draw_background = false;
	bool invert_border = false;
	bool vertical = false;
	Box parent;
	
	this(Box parent = null)
	{
		this.parent = parent;
		if(parent !is null)
		{
			parent.children ~= [this];
		}
	}

	void DrawBackground(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawColor(renderer, 32, 32, 32, 255);
		DGUI_DrawRect(
			renderer,
			screen_x + border,
			screen_y + border,
			width - border*2,
			height - border*2,
		);
	}

	void DrawDecorations(SDL_Renderer* renderer)
	{
		DGUI_DrawBeveledBoder(
			renderer,
			screen_x,
			screen_y,
			width,
			height,
			border,
			invert_border
		);
	}

	void FitSize()
	{

	}

	void PositionChildren()
	{

	}

	void GrowChildren()
	{

	}

	void Layout()
	{
		
	}

	void Draw(SDL_Renderer* renderer)
	{
		if(draw_background)
		{
			DrawBackground(renderer);
		}
		DrawDecorations(renderer);
	}

	bool InBounds(int x, int y)
	{
		int rx = x - screen_x;
		int ry = y - screen_y;

		return rx >= 0 && ry >= 0 && rx <= width && ry <= height;
	}

	bool WasInBounds(int x, int y, int dx, int dy)
	{
		return InBounds(x, y) || InBounds(x - dx, y - dy);
	}

	void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
			
	}
}

class Box : Panel
{
	Panel[] children;

	void DrawChildren(SDL_Renderer* renderer)
	{
		foreach(Panel child; children)
		{
			child.Draw(renderer);
		}
	}

	this(Box parent = null)
	{
		super(parent);
	}

	override void Draw(SDL_Renderer* renderer)
	{
		if(draw_background)
		{
			DrawBackground(renderer);
		}
		DrawChildren(renderer);
		DrawDecorations(renderer);
	}

	override void FitSize()
	{
		needed_width = 0;
		needed_height = 0;
		foreach(Panel child; children)
		{
			child.FitSize();
			if(!child.floating)
			{
				if(child.width_mode == ScaleMode.Grow)
				{
					child.width = 0;
				}
				if(child.height_mode == ScaleMode.Grow)
				{
					child.height = 0;
				}
				
				if(vertical)
				{
					needed_width = max(needed_width, child.width);
					needed_height += child.height;
				}
				else
				{
					needed_width += child.width;
					needed_height = max(needed_height, child.height);
				}
			}
		}

		if(vertical)
		{
			needed_height += gap * (children.length - 1);
		}
		else
		{
			needed_width += gap * (children.length - 1);
		}

		needed_width += border*2 + padding_left + padding_right;
		needed_height += border*2 + padding_top + padding_bottom;

		if(width_mode == ScaleMode.Fit)
		{
			width = needed_width;
		}

		if(height_mode == ScaleMode.Fit)
		{
			height = needed_height;
		}
	}
	
	override void PositionChildren()
	{
		int offset_x = padding_left + border;
		int offset_y = padding_top + border;
		if(vertical)
		{
			offset_y += cast(int)(align_y * (height - needed_height));
		}
		else
		{
			offset_x += cast(int)(align_x * (width - needed_width));
		}
		foreach(Panel child; children)
		{
			if(!child.floating)
			{
				child.x = offset_x;
				child.y = offset_y;
				if(vertical)
				{
					child.x += cast(int)(align_x * (width - child.width - padding_left - padding_right - border*2));
					offset_y += gap + child.height;
				}
				else
				{
					child.y += cast(int)(align_y * (height - child.height - padding_top - padding_bottom - border*2));
					offset_x += gap + child.width;
				}
			}
			child.screen_x = child.x + screen_x;
			child.screen_y = child.y + screen_y;
			child.PositionChildren();
		}
	}

	override void GrowChildren()
	{
		foreach(Panel child; children)
		{
			if(child.width_mode == ScaleMode.Grow)
			{
				if(vertical)
				{
					child.width = width - border*2 - padding_left - padding_right;
				}
				else
				{
					child.width = width - needed_width;
					needed_width = width;
				}
			}
			if(child.height_mode == ScaleMode.Grow)
			{
				if(vertical)
				{
					child.height = height - needed_height;
					needed_height = height;
				}
				else
				{
					child.height = height - border*2 - padding_top - padding_bottom;
				}
			}
			child.GrowChildren();
		}
	}

	override void Layout()
	{
		FitSize();
		GrowChildren();
		PositionChildren();
	}

	void PropogateMouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		foreach(Panel child; children)
		{
			child.MouseEvent(x, y, lbutton, mbutton, rbutton, dx, dy);
		}
	}

	override void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		PropogateMouseEvent(x, y, lbutton, mbutton, rbutton, dx, dy);
	}
}

class Button : Panel
{
	string text;
	bool state = false;
	void delegate() callback;
	
	this(Box parent, string text, void delegate() origcallback = null)
	{
		super(parent);
		this.text = text;
		callback = origcallback;
	}

	override void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		if(!InBounds(x, y))
		{
			return;
		}
		if(state && !lbutton)
		{
			state = false;
			if(callback !is null)
			{
				callback();
			}
		}
		else if(lbutton)
		{
			state = true;
		}
		if(dx != 0 || dy != 0)
		{
			state = false;
		}
	}

	override void FitSize()
	{
		height = character_height + border*2 + padding_top + padding_bottom;
		width = cast(int)(text.length) * character_advance + border*2 + padding_left + padding_right;
	}

	override void Draw(SDL_Renderer* renderer)
	{
		invert_border = state;
		super.Draw(renderer);
		DGUI_DrawText(renderer, screen_x+border+padding_left, screen_y+border+padding_top, text);
	}
}

class WindowBar : Box
{
	Button minimize_button;
	Button close_button;	
	bool dragged = false;

	this(Box parent = null)
	{
		super(parent);

		width_mode = ScaleMode.Grow;
		height_mode = ScaleMode.Fit;
		align_x = 1f;

		//minimize_button = new Button(this, "-");
		close_button = new Button(this, "X");
	}

	override void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		super.MouseEvent(x, y, lbutton, mbutton, rbutton, dx, dy);
		if(!WasInBounds(x, y, dx, dy))
		{
			return;
		}
		if(!dragged && dx == 0 && dy == 0)
		{
			if(lbutton)
			{
				dragged = true;
			}
		}
		else if(dragged)
		{
			if(!lbutton)
			{
				dragged = false;
				return;
			}
			parent.x += dx;
			parent.y += dy;
		}
	}
}

class ContentBox : Box
{
	bool dragged = false;

	this(Box parent = null)
	{
		super(parent);
		width = 200;
		height = 200;
	}

	override void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		super.MouseEvent(x, y, lbutton, mbutton, rbutton, dx, dy);
		int rx = x - screen_x;
		int ry = y - screen_y;
		if(
			!WasInBounds(x, y, dx, dy) ||
			rx > border && ry > border && rx < width - border && ry < height - border &&
			rx - dx > border && ry - dy > border && rx - dx < width - border && ry - dy < height - border
		)
		{
			return;
		}
		if(!dragged && lbutton && dx == 0 && dy == 0)
		{
			dragged = true;
			return;
		}
		else if(!lbutton)
		{
			dragged = false;
			return;
		}
		else if(!dragged)
		{
			return;
		}
		if(rx <= border || rx - dx <= border)
		{
			parent.x += dx;
			width -= dx;
		}
		if(ry <= border || ry - dy <= border)
		{
			parent.y += dy;
			height -= dy;
		}
		if(rx >= width - border || rx - dx >= width - border)
		{
			width += dx;
		}
		if(ry >= height - border || ry - dy >= height - border)
		{
			height += dy;
		}
	}
}

class Window : Box
{
	WindowBar window_bar;
	ContentBox content_box;

	this(Box parent = null)
	{
		super(parent);
		width_mode = ScaleMode.Fit;
		height_mode = ScaleMode.Fit;
		vertical = true;
		floating = true;
		border = 0;
		x = 10;
		y = 10;

		window_bar = new WindowBar(this);
		
		content_box = new ContentBox(this);
	}
}

class RootPanel : Box
{
	this(Box parent = null)
	{
		super(parent);
		draw_background = true;
		border = 0;
		auto window = new Window(this);
		auto child1 = new Panel(this);
		auto child2 = new Box(this);
		child2.width_mode = ScaleMode.Fit;
		child2.height_mode = ScaleMode.Fit;
		auto child3 = new Panel(child2);
	}
}

void DGUI_DrawRect(SDL_Renderer* renderer, int x, int y, int width, int height)
{
	auto r = SDL_Rect(x, y, width, height);
	SDL_RenderFillRect(renderer, &r);
}

void DGUI_DrawBeveledBoder(SDL_Renderer* renderer, int x, int y, int width, int height, int border, bool invert = false)
{
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

byte* fontbuffer;
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
						SDL_RenderDrawPoint(renderer, x_offset, y_offset);
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
