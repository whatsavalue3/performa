module dguiw;
import std.algorithm;
import bindbc.sdl;
import std.stdio;

private struct Transform
{
	int x;
	int y;
}

private Transform[] transform_stack;

private int transpose_x = 0;
private int transpose_y = 0;

void DGUI_Transpose(int x, int y)
{
	//transform_stack ~= [Transform(x, y)];
	transpose_x += x;
	transpose_y += y;
}

void DGUI_PopTransform()
{
	transform_stack.length--;
}

enum ScaleMode
{
	Fit,
	Grow,
	Fixed
}

enum MouseButton
{
	Left,
	Middle,
	Right
}

class Panel
{
	int x = 0;
	int y = 0;
	int width = 0;
	int height = 0;
	int padding_top = 0;
	int padding_bottom = 0;
	int padding_left = 0;
	int padding_right = 0;
	int border = 5;
	int gap = 0;
	int needed_width = 0;
	int needed_height = 0;
	ScaleMode width_mode = ScaleMode.Fit;
	ScaleMode height_mode = ScaleMode.Fit;
	float align_x = 0.5f;
	float align_y = 0.5f;
	bool floating = false;
	bool draw_background = false;
	bool invert_border = false;
	bool vertical = false;
	Frame parent;
	
	this(Frame parent = null)
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
			border,
			border,
			width - border*2,
			height - border*2,
		);
	}

	void DrawContent(SDL_Renderer* renderer)
	{
		
	}

	void DrawDecorations(SDL_Renderer* renderer)
	{
		DGUI_DrawBeveledBoder(
			renderer,
			0,
			0,
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

	final void Draw(SDL_Renderer* renderer)
	{
		DGUI_Transpose(x, y);
		if(draw_background)
		{
			DrawBackground(renderer);
		}
		DrawContent(renderer);
		DrawDecorations(renderer);
		DGUI_Transpose(-x, -y);
	}

	bool InBounds(int x, int y)
	{
		int rx = x;
		int ry = y;

		return rx >= 0 && ry >= 0 && rx <= width && ry <= height;
	}

	bool WasInBounds(int x, int y, int dx, int dy)
	{
		return InBounds(x, y) || InBounds(x - dx, y - dy);
	}

	void MousePressed(int x, int y, MouseButton button)
	{
		
	}

	void MouseReleased(int x, int y, MouseButton button)
	{
		
	}

	void MouseMoved(int x, int y, int dx, int dy)
	{
		
	}

	void WheelMoved(int x, int y, int sx, int sy)
	{
		
	}

	void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
			
	}
}

class Frame : Panel
{
	Panel[] children;
	
	this(Frame parent = null)
	{
		super(parent);
	}
	
	void DrawChildren(SDL_Renderer* renderer)
	{
		foreach(Panel child; children)
		{
			child.Draw(renderer);
		}
	}
	
	void PropogateMouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		foreach(Panel child; children)
		{
			child.MouseEvent(x - child.x, y - child.y, lbutton, mbutton, rbutton, dx, dy);
		}
	}

	override void MousePressed(int x, int y, MouseButton button)
	{
		foreach(Panel child; children)
		{
			child.MousePressed(x - child.x, y - child.y, button);
		}
	}

	override void MouseReleased(int x, int y, MouseButton button)
	{
		foreach(Panel child; children)
		{
			child.MouseReleased(x - child.x, y - child.y, button);
		}
	}

	override void MouseMoved(int x, int y, int dx, int dy)
	{
		foreach(Panel child; children)
		{
			child.MouseMoved(x - child.x, y - child.y, dx, dy);
		}
	}

	override void WheelMoved(int x, int y, int sx, int sy)
	{
		foreach(Panel child; children)
		{
			child.WheelMoved(x, y, sx, sy);
		}
	}

	override void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		PropogateMouseEvent(x, y, lbutton, mbutton, rbutton, dx, dy);
	}
}

class Box : Frame
{
	this(Frame parent = null)
	{
		super(parent);
	}

	override void DrawContent(SDL_Renderer* renderer)
	{
		DrawChildren(renderer);	
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

	
}

class Button : Panel
{
	string text;
	bool state = false;
	void delegate() callback;
	
	this(Frame parent, string text, void delegate() origcallback = null)
	{
		super(parent);
		this.text = text;
		callback = origcallback;
	}

	override void MousePressed(int x, int y, MouseButton button)
	{
		if(InBounds(x, y) && button == MouseButton.Left)
		{
			state = true;
		}
	}

	override void MouseMoved(int x, int y, int dx, int dy)
	{
		state = false;
	}

	override void MouseReleased(int x, int y, MouseButton button)
	{
		if(state && button == MouseButton.Left)
		{
			state = false;
			if(callback !is null)
			{
				callback();
			}
		}
	}

	override void FitSize()
	{
		height = character_height + border*2 + padding_top + padding_bottom;
		width = cast(int)(text.length) * character_advance + border*2 + padding_left + padding_right;
	}

	override void DrawContent(SDL_Renderer* renderer)
	{
		invert_border = state;
		DGUI_DrawText(renderer, border+padding_left, border+padding_top, text);
	}
}

class WindowBar : Box
{
	Button minimize_button;
	Button close_button;	
	bool dragged = false;

	this(Frame parent = null, bool add_close_button = true)
	{
		super(parent);

		width_mode = ScaleMode.Grow;
		height_mode = ScaleMode.Fit;
		align_x = 1f;

		//minimize_button = new Button(this, "-");
		if(add_close_button)
		{
			close_button = new Button(this, "X");
		}
	}

	override void MousePressed(int x, int y, MouseButton button)
	{
		if(InBounds(x, y) && button == MouseButton.Left)
		{
			dragged = true;
		}
	}

	override void MouseReleased(int x, int y, MouseButton button)
	{
		if(button == MouseButton.Left)
		{
			dragged = false;
		}
	}

	override void MouseMoved(int x, int y, int dx, int dy)
	{
		if(dragged)
		{
			parent.x += dx;
			parent.y += dy;
		}
	}
}

class ContentBox : Box
{
	bool dragged = false;

	this(Frame parent = null)
	{
		super(parent);
		width = 200;
		height = 200;
	}

	override void MouseEvent(int x, int y, bool lbutton, bool mbutton, bool rbutton, int dx, int dy)
	{
		super.MouseEvent(x, y, lbutton, mbutton, rbutton, dx, dy);
		int rx = x;
		int ry = y;
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

	this(Frame parent = null, bool add_close_button = true)
	{
		super(parent);
		width_mode = ScaleMode.Fit;
		height_mode = ScaleMode.Fit;
		vertical = true;
		floating = true;
		border = 0;
		x = 10;
		y = 10;

		window_bar = new WindowBar(this, add_close_button);
	}
}

class RootPanel : Box
{
	this(Frame parent = null)
	{
		super(parent);
		draw_background = true;
		border = 0;

		width_mode = ScaleMode.Fixed;
		height_mode = ScaleMode.Fixed;
	}
}

class Textbox : Panel
{
	this(Frame parent)
	{
		super(parent);
		text = "";
		invert_border = true;
	}

	
	/*override void Click(int cx, int cy, int button, int action)
	{
		if(action == SDL_RELEASED)
		{
			DGUI_CaptureFocus(this);
		}
	}
	
	override void Type(uint chr)
	{
		if(chr == '\b')
		{
			if(text.length > 0)
			{
				text.length--;
			}
		}
		else
		{
			text ~= chr;
		}
	}*/

	override void FitSize()
	{
		height = border*2 + padding_top + padding_bottom + character_height;
		width = max(256, border*2 + padding_left + padding_right);
	}
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		DGUI_DrawText(renderer, border + padding_left, border + padding_top, text);
	}

	string text;
}

void DGUI_DrawRect(SDL_Renderer* renderer, int x, int y, int width, int height)
{
	auto r = SDL_Rect(x, y, width, height);
	SDL_RenderFillRect(renderer, &r);
}

void DGUI_DrawBeveledBoder(SDL_Renderer* renderer, int x, int y, int width, int height, int border, bool invert = false)
{
	border = min(border,min(width,height)/2);

	x += transpose_x;
	y += transpose_y;
	
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
	int x_offset = x + transpose_x;
	int y_offset = y + transpose_y;
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

RootPanel mainpanel;

void DGUI_ProcessFrame(SDL_Renderer* renderer)
{
	mainpanel.Layout();
	mainpanel.Draw(renderer);
}

static this()
{
	auto fontfile = File("unifont-16.0.01.bmp","rb");
	auto fontpixels = fontfile.rawRead(new byte[fontfile.size()]);
	fontfile.close();
	fontbuffer = fontpixels.ptr;
}
