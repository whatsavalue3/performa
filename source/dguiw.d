module dguiw;
import std.algorithm;
import bindbc.sdl;
import std.stdio;
import std.array;
import input;

private SDL_Window* window;

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
	Panel parent;
	Panel[] children;
	
	this(Panel parent = null)
	{
		this.parent = parent;
		if(parent !is null)
		{
			parent.children ~= this;
		}
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

	void DrawBackground(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawColor(renderer, 32, 32, 32, 255);
		DGUI_DrawRect(
			renderer,
			0,
			0,
			width,
			height,
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
			5,
			false
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
		Layout();
		DGUI_Transpose(x, y);
		DrawBackground(renderer);
		DrawDecorations(renderer);
		DrawContent(renderer);
		foreach(Panel child; children)
		{
			child.Draw(renderer);
		}
		DGUI_Transpose(-x, -y);
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
			height = cury;
		}
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

	void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		foreach_reverse(Panel child; children)
		{
			child.MousePressed(x - child.x, y - child.y, button, covered);
			if(child.InBounds(x - child.x, y - child.y))
			{
				covered = true;
			}
		}
	}

	void MouseReleased(int x, int y, MouseButton button)
	{
		foreach_reverse(Panel child; children)
		{
			child.MouseReleased(x - child.x, y - child.y, button);
		}
	}

	void MouseMoved(int x, int y, int dx, int dy, bool covered)
	{
		foreach_reverse(Panel child; children)
		{
			child.MouseMoved(x - child.x, y - child.y, dx, dy, covered);
			
			if(child.InBounds(x - child.x, y - child.y))
			{
				covered = true;
			}
		}
	}
	
	void WheelMoved(int x, int y, int sx, int sy)
	{
		foreach_reverse(Panel child; children)
		{
			child.WheelMoved(x - child.x, y - child.y, sx, sy);
		}
	}

	void TextInput(char ch)
	{
		foreach(Panel child; children)
		{
			child.TextInput(ch);
		}
	}
	
	void KeyDown(int keysym)
	{
		foreach(Panel child; children)
		{
			child.KeyDown(keysym);
		}
	}

	void Update(int delta)
	{
		foreach(Panel child; children)
		{
			child.Update(delta);
		}
	}
}

class Button : Panel
{
	string text;
	bool state = false;
	void delegate() callback;
	
	this(Panel parent, string text, void delegate() origcallback = null)
	{
		super(parent);
		this.text = text;
		callback = origcallback;
		height = character_height;
		width = cast(int)(text.length) * character_advance;
	}

	override void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		if(InBounds(x, y) && !covered && button == MouseButton.Left)
		{
			state = true;
		}
	}

	override void MouseMoved(int x, int y, int dx, int dy, bool covered)
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

	override void DrawContent(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawColor(renderer,255,255,255,255);
		DGUI_DrawText(renderer, 0, 0, text);
	}
}

class MultiButton : Panel
{
	this(Panel parent, string[] names, void delegate() origcallback = null)
	{
		super(parent);
		foreach(name; names)
		{
			new Button(this, name, origcallback);
		}
	}
}

class WindowBar : Panel
{
	Button minimize_button;
	Button close_button;	
	bool dragged = false;

	this(Panel parent = null, bool add_close_button = true)
	{
		super(parent);

		close_button = new Button(this, "X");
		height = 24;
	}

	override void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		if(InBounds(x, y) && !covered && button == MouseButton.Left)
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

	override void MouseMoved(int x, int y, int dx, int dy, bool covered)
	{
		if(dragged)
		{
			parent.x += dx;
			parent.y += dy;
		}
	}
}

class ContentBox : Panel
{
	bool dragging_top = false;
	bool dragging_bottom = false;
	bool dragging_left = false;
	bool dragging_right = false;

	this(Panel parent = null)
	{
		super(parent);
		width = 200;
		height = 200;
	}

	override void MouseMoved(int x, int y, int dx, int dy, bool covered)
	{
		super.MouseMoved(x, y, dx, dy, covered);
		if(dragging_top)
		{
			parent.x += dx;
			width -= dx;
		}
		else if(dragging_bottom)
		{
			width += dx;
		}
		if(dragging_left)
		{
			parent.y += dy;
			height -= dy;
		}
		else if(dragging_right)
		{
			height += dy;
		}
	}

	override void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		super.MousePressed(x, y, button, covered);
		if(!InBounds(x, y) || covered)
		{
			return;
		}
		if(x <= 0)
		{
			dragging_left = true;
		}
		else if(x >= width)
		{
			dragging_right = true;
		}
		if(y <= 0)
		{
			dragging_top = true;
		}
		else if(y >= height)
		{
			dragging_bottom = true;
		}
	}

	override void MouseReleased(int x, int y, MouseButton button)
	{
		if(button == MouseButton.Left)
		{
			dragging_top = false;
			dragging_bottom = false;
			dragging_left = false;
			dragging_right = false;
		}
	}
}

class Window : Panel
{
	WindowBar window_bar;

	this(Panel parent = null, bool add_close_button = true)
	{
		super(parent);
		x = 10;
		y = 10;
		width = 320;
		height = 240;

		window_bar = new WindowBar(this, add_close_button);
	}
	
	override void Layout()
	{
		window_bar.width = width;
		LayoutVertically();
	}
}

private int captured_x;
private int captured_y;

private int mouse_x;
private int mouse_y;

void DGUI_Init(SDL_Window* the_window)
{
	window = the_window;
	SDL_GetMouseState(&mouse_x, &mouse_y);
}

void DGUI_HandleEvent(SDL_Event ev, InputHandler inputHandler)
{
	switch(ev.type)
	{
		case SDL_MOUSEBUTTONDOWN:
			rootpanel.MousePressed(
				ev.button.x,
				ev.button.y,
				cast(MouseButton)(ev.button.button-1),
				false
			);
			break;
		case SDL_MOUSEBUTTONUP:
			rootpanel.MouseReleased(ev.button.x, ev.button.y, cast(MouseButton)(ev.button.button-1));
			break;
		case SDL_MOUSEMOTION:
			int dx, dy;
			if(mouse_captured)
			{
				dx = ev.button.x - captured_x;
				dy = ev.button.y - captured_y;
			}
			else
			{
				dx = ev.button.x - mouse_x;
				dy = ev.button.y - mouse_y;
			}
			mouse_x = ev.button.x;
			mouse_y = ev.button.y;
			rootpanel.MouseMoved(ev.button.x, ev.button.y, dx, dy, false);
			break;
		case SDL_MOUSEWHEEL:
			rootpanel.WheelMoved(ev.wheel.mouseX, ev.wheel.mouseY, ev.wheel.x, ev.wheel.y);
			break;
		case SDL_TEXTINPUT:
			rootpanel.TextInput(ev.text.text[0]);
			break;
		case SDL_KEYDOWN:
			rootpanel.KeyDown(ev.key.keysym.sym);
			inputHandler.HandleEvent(ev);
			break;
		default:
			break;
	}
	if(mouse_captured)
	{
		SDL_WarpMouseInWindow(window, captured_x, captured_y);
	}
}

private bool mouse_captured = false;

void DGUI_CaptureMouse(bool capture = true)
{
	if(capture == mouse_captured)
	{
		return;
	}
	else if(capture)
	{
		mouse_captured = true;
		SDL_GetMouseState(&captured_x, &captured_y);
		SDL_SetRelativeMouseMode(true);
	}
	else
	{
		mouse_captured = false;
		SDL_SetRelativeMouseMode(false);
		SDL_WarpMouseInWindow(window, captured_x, captured_y);
	}
}

private bool left_button = false;
private bool right_button = false;
private bool middle_button = false;

bool DGUI_IsButtonPressed(MouseButton button)
{
	if(button == MouseButton.Left)
	{
		return left_button;
	}
	else if(button == MouseButton.Right)
	{
		return right_button;
	}
	else if(button == MouseButton.Middle)
	{
		return middle_button;
	}
	return false;
}

class RootPanel : Panel
{
	this(Panel parent = null)
	{
		super(parent);
	}

	override void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		if(button == MouseButton.Left)
		{
			left_button = true;
		}
		else if(button == MouseButton.Right)
		{
			right_button = true;
		}
		else if(button == MouseButton.Middle)
		{
			middle_button = true;
		}

		super.MousePressed(x, y, button, covered);
	}

	override void MouseReleased(int x, int y, MouseButton button)
	{
		if(button == MouseButton.Left)
		{
			left_button = false;
		}
		else if(button == MouseButton.Right)
		{
			right_button = false;
		}
		else if(button == MouseButton.Middle)
		{
			middle_button = false;
		}

		super.MouseReleased(x, y, button);
	}
}

int cursor_on_for = 500;
int cursor_off_for = 500;

class Textbox : Panel
{
	bool focused = false;
	int cursor_timer = 0;
	int cursor_pos = 0;
	void delegate() on_enter;

	this(Panel parent, void delegate() on_enter = null)
	{
		super(parent);
		text = "";
		cursor_pos = cast(int)(text.length);
		this.on_enter = on_enter;
		width = 256;
		height = 16;
	}

	override void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		if(InBounds(x, y) && !covered)
		{
			if(button == MouseButton.Left)
			{
				focused = true;
				cursor_timer = 0;
				cursor_pos = x/character_advance;
			}
		}
		else
		{
			focused = false;
		}
		ClipCursor();
	}

	override void TextInput(char ch)
	{
		if(!focused)
		{
			return;
		}
		
		cursor_timer = 0;
		text.insertInPlace(cursor_pos, ch);
		cursor_pos++;
		ClipCursor();
	}

	override void KeyDown(int keysym)
	{
		if(!focused)
		{
			return;
		}
	
		switch(keysym)
		{
			case SDLK_BACKSPACE:
				if(text.length > 0 && cursor_pos > 0)
				{
					text = text[0 .. cursor_pos-1] ~ text[cursor_pos .. $];
					cursor_pos--;
					cursor_timer = 0;
				}
				break;
			case SDLK_LEFT:
				cursor_pos--;
				cursor_timer = 0;
				break;
			case SDLK_RIGHT:
				cursor_pos++;
				cursor_timer = 0;
				break;
			case SDLK_RETURN:
				if(on_enter !is null)
				{
					on_enter();
				}
				break;
			default:
				break;
		}
		ClipCursor();
	}

	override void FitSize()
	{
		height = character_height;
		width = 256;
	}
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawColor(renderer,255,255,255,255);
		DGUI_DrawText(renderer, 0, 0, text);
		if(focused && cursor_timer < cursor_on_for)
		{
			DGUI_DrawLine(
				renderer,
				cursor_pos*character_advance,
				0,
				cursor_pos*character_advance,
				height
			);
		}
	}
	
	override void DrawDecorations(SDL_Renderer* renderer)
	{
		DGUI_DrawBeveledBoder(
			renderer,
			0,
			0,
			width,
			height,
			5,
			true
		);
	}

	override void Update(int delta)
	{
		cursor_timer += delta;
		cursor_timer %= cursor_on_for + cursor_off_for;
	}

	void ClipCursor()
	{
		cursor_pos = max(min(text.length, cursor_pos),0);
	}

	string text;
}

void DGUI_DrawRect(SDL_Renderer* renderer, int x, int y, int width, int height)
{
	auto r = SDL_Rect(x+transpose_x, y+transpose_y, width, height);
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

void DGUI_FillRect(SDL_Renderer* renderer, int x, int y, int w, int h)
{
	auto r = SDL_Rect(x+transpose_x, y+transpose_y, w, h);
	SDL_RenderFillRect(renderer,&r);
}

void DGUI_RenderCopy(SDL_Renderer* renderer, SDL_Texture* tex, int x, int y, int w, int h)
{
	auto src = SDL_Rect(0, 0, w, h);
	auto dst = SDL_Rect(x+transpose_x, y+transpose_y, w, h);
	SDL_RenderCopy(renderer,tex,&src,&dst);
}


void DGUI_DrawLine(SDL_Renderer* renderer, int x1, int y1, int x2, int y2)
{
	SDL_RenderDrawLine(renderer, x1+transpose_x, y1+transpose_y, x2+transpose_x, y2+transpose_y);
}

void DGUI_DrawPoint(SDL_Renderer* renderer, int x, int y)
{
	SDL_RenderDrawPoint(renderer, x+transpose_x, y+transpose_y);
}

byte* fontbuffer;
int character_width = 16;
int character_height = 16;
int character_advance = 8;

void DGUI_DrawText(SDL_Renderer* renderer, int x, int y, string text)
{
	//SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
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

RootPanel rootpanel = null;

void DGUI_SetRoot(RootPanel root)
{
	rootpanel = root;
}

void DGUI_ProcessFrame(SDL_Renderer* renderer, int delta)
{
	rootpanel.Update(delta);
	rootpanel.Layout();
	rootpanel.Draw(renderer);
}

static this()
{
	auto fontfile = File("unifont-16.0.01.bmp","rb");
	auto fontpixels = fontfile.rawRead(new byte[fontfile.size()]);
	fontfile.close();
	fontbuffer = fontpixels.ptr;
}
