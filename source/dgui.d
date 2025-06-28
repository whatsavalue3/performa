module dgui;
import std.stdio;
import std.algorithm;
import std.process;
import std.array;
import std.parallelism;
import std.string;
import glfw3.api;
import std.conv;
import std.ascii;

public import bindbc.opengl;

public GLFWwindow* window;

extern(C) nothrow @nogc
{
	alias pglBitmap = void function(GLsizei, GLsizei, GLfloat, GLfloat,GLfloat, GLfloat, GLubyte*);
}

public pglBitmap glBitmap;


void glBlendColor4ub(ubyte fr, ubyte fg, ubyte fb, ubyte fa)
{
	glColor4ub(fr,fg,fb,fa);
	glBlendColor(fr/255.0,fg/255.0,fb/255.0,fa/255.0);
}

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
	
	final void InternalDraw()
	{
		if(hidden)
		{
			return;
		}
		PerformLayout();
		glTranslatef(x,y,0);
		Draw();
		glTranslatef(offsetx,offsety,0);
		foreach(Panel child; children)
		{
			child.InternalDraw();
		}
		glTranslatef(-x,-y,0);
		glTranslatef(-offsetx,-offsety,0);
	}
	
	void DrawBackground()
	{
		glBlendColor4ub(32,32,32,255);
		DGUI_FillRect(0,0,width,height);
	}
	
	void Draw()
	{
		DrawBackground();
		
		glBlendColor4ub(255,255,255,255);
		glBegin(GL_LINES);
		glVertex2i(0,1);
		glVertex2i(width,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,0);
		glVertex2i(1,height);
		glEnd();
		glBlendColor4ub(0,0,0,255);
		glBegin(GL_LINES);
		glVertex2i(0,height);
		glVertex2i(width,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(width,0);
		glVertex2i(width,height);
		glEnd();
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

class VerticalLayoutPanel : Panel
{
	this(Panel parent)
	{
		super(parent);
	}
	
	override void PerformLayout()
	{
		LayoutVertically(0,true);
		Stretch();
	}
}

class Label : Panel
{
	this(Panel parent)
	{
		super(parent);
	}
	
	this(Panel parent, string text)
	{
		super(parent);
		this.text = text;
	}
	
	override void Draw()
	{
		glBlendColor4ub(255,255,255,255);
		if(text.length)
		{
			DGUI_DrawText(0,16,text,this.width);
		}
	}
	
	override void PerformLayout()
	{
		if(stretch)
		{
			width = parent.width;
		}
		else
		{
			width = max(8,cast(int)text.length*8);
		}
	}
	
	string text = "";
	bool stretch = false;
	int userdata = 0;
}

class Button : Label
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

	override void DrawBackground()
	{
		if(state)
		{
			glBlendColor4ub(48,96,255,255);
		}
		else
		{
			glBlendColor4ub(64,64,64,255);
		}
	}
	
	override void Draw()
	{
		DrawBackground();
		DGUI_FillRect(0,0,width,height);
		
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(0,1);
		glVertex2i(width,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,0);
		glVertex2i(1,height);
		glEnd();
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(0,height);
		glVertex2i(width,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(width,0);
		glVertex2i(width,height);
		glEnd();
		glBlendColor4ub(255,255,255,255);
		glRasterPos2i(0,16);
		super.Draw();
	}
	
	override void Click(int cx, int cy, int button, int action)
	{
		if(action == GLFW_RELEASE)
		{
			state = false;
			if(callback !is null)
			{
				callback();
			}
			if(callback2 !is null)
			{
				callback2(this);
			}
		}
		else
		{
			state = true;
			if(callback3 !is null)
			{
				callback3(this);
			}
		}
	}
	bool state = false;
	void delegate() callback;
	void delegate(Button) callback2;
	void delegate(Button) callback3;
}

class Checkbox : Label
{
	this(Panel parent)
	{
		super(parent);
		text = "0";
		width = 16;
	}

	override void DrawBackground()
	{
		glBlendColor4ub(64,64,64,255);
		DGUI_FillRect(0,0,width,height);
		if(state)
		{
			glBlendColor4ub(48,96,255,255);
			DGUI_FillRect(2,2,width-4,height-4);
		}
	}
	
	override void Draw()
	{
		DrawBackground();
		
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(0,1);
		glVertex2i(width,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,0);
		glVertex2i(1,height);
		glEnd();
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(0,height);
		glVertex2i(width,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(width,0);
		glVertex2i(width,height);
		glEnd();
	}
	
	override void Click(int cx, int cy, int button, int action)
	{
		if(action == GLFW_PRESS)
		{
			state = !state;
			if(state)
			{
				text = "1";
			}
			else
			{
				text = "0";
			}
		}
	}
	
	bool state = false;
}

class ClipboardButton : Button
{
	this(Panel parent, string origtext)
	{
		super(parent);
		text = origtext;
	}
	
	override void DrawBackground()
	{
		if(state)
		{
			glBlendColor4ub(48,96,255,255);
		}
		else
		{
			glBlendColor4ub(32,64,127,255);
		}
	}
	
	override void Click(int cx, int cy, int button, int action)
	{
		if(action == GLFW_RELEASE)
		{
			state = false;
			glfwSetClipboardString(cast(GLFWwindow*)null,toStringz(text));
		}
		else
		{
			state = true;
		}
	}
}

class Textbox : Label
{
	this(Panel parent)
	{
		super(parent);
	}
	
	override void Draw()
	{
		glBlendColor4ub(96,96,96,255);
		DGUI_FillRect(0,0,width,height);
		
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(0,1);
		glVertex2i(width,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,0);
		glVertex2i(1,height);
		glEnd();
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(0,height);
		glVertex2i(width,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(width,0);
		glVertex2i(width,height);
		glEnd();
		glBlendColor4ub(255,255,255,255);
		glRasterPos2i(0,16);
		super.Draw();
	}
	
	override void PerformLayout()
	{
		if(stretch)
		{
			width = max(48,cast(int)text.length*8+16);
		}
	}
	
	override void Type(uint chr)
	{
		int special = cast(int)chr;
		if(special < 0)
		{
			if(special == -259)
			{
				if(text.length > 0)
				{
					text.length = text.length-1;
				}
			}
		}
		else
		{
			text ~= chr;
		}
	}
	
	override void Click(int cx, int cy, int button, int action)
	{
		if(button == GLFW_MOUSE_BUTTON_MIDDLE && action == GLFW_RELEASE)
		{
			const char* pasted = glfwGetClipboardString(cast(GLFWwindow*)null);
			if(pasted)
			{
				text = to!string(pasted.fromStringz());
			}
		}
	}
}

class Numberbox : Textbox
{
	this(Panel parent)
	{
		super(parent);
	}

	override void Type(uint chr)
	{
		int special = cast(int)chr;
		
		if(special < 0)
		{
			if(special == -259)
			{
				if(text.length > 0)
				{
					text.length = text.length-1;
				}
			}
		}
		else if(isDigit(special))
		{
			text ~= chr;
		}
	}
}

class Charbox : Textbox
{
	this(Panel parent)
	{
		super(parent);
	}
	
	override void PerformLayout()
	{
		if(stretch)
		{
			width = 24;
		}
	}

	override void Type(uint chr)
	{
		int special = cast(int)chr;
		
		if(special > 0)
		{
			text = to!string(chr);
		}
	}
}

class Slider : Label
{
	this(Panel parent,float _min = 0.0,float _max = 1.0)
	{
		super(parent);
		min = _min;
		max = _max;
		value = 0.0;
		text = "0.0";
	}
	
	override void Draw()
	{
		int sliderwidth = width-64;
		if(held)
		{
			double dxpos, dypos;
			glfwGetCursorPos(window, &dxpos, &dypos);
			pos = clamp((dxpos - _screenx)/sliderwidth,0,1);
			value = pos*(max-min)+min;
			text = to!string(value);
			if(!HasHit(0,cast(int)(dypos-_screeny)))
			{
				held = false;
			}
		}
	
		int top = height/2-2;
		int bottom = top+4;
		glBlendColor4ub(255,255,255,127);
		DGUI_FillRect(0,top,sliderwidth,4);
		
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(0,top+1);
		glVertex2i(sliderwidth,top+1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,top);
		glVertex2i(1,bottom);
		glEnd();
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(0,bottom);
		glVertex2i(sliderwidth,bottom);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(sliderwidth,top);
		glVertex2i(sliderwidth,bottom);
		glEnd();
		
		glBlendColor4ub(96,96,96,255);
		int left = cast(int)(pos*(sliderwidth-6));
		int right = left+6;
		DGUI_FillRect(left,0,6,height);
		
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(left,1);
		glVertex2i(right,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(left,0);
		glVertex2i(left,height);
		glEnd();
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(left,height);
		glVertex2i(right,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(right,0);
		glVertex2i(right,height);
		glEnd();
		
		
		glBlendColor4ub(255,255,255,255);
		DGUI_DrawText(sliderwidth,16,text);
	}
	
	override void Click(int cx, int cy, int button, int action)
	{
		double dxpos, dypos;
		glfwGetCursorPos(window, &dxpos, &dypos);
		_screenx = cast(int)dxpos - cx;
		_screeny = cast(int)dypos - cy;
		held = action == GLFW_PRESS;
	}
	
	override void PerformLayout()
	{
	
	}
	
	int _screenx;
	int _screeny;
	
	bool held;
	float value;
	float pos;
	float min;
	float max;
}

class LabeledPanel : Panel
{
	this(Panel parent, string _label, bool _horizontal = false)
	{
		super(parent);
		label = _label;
		horizontal = _horizontal;
		if(!horizontal)
		{
			offsety = 20;
		}
	}
	
	override void PerformLayout()
	{
		if(horizontal)
		{
			offsetx = cast(int)label.length*8+4;
		}
		if(stretch)
		{
			Stretch();
		}
	}
	
	override void Draw()
	{
		super.Draw();
		glBlendColor4ub(255,255,255,255);
		DGUI_DrawText(0,16,label,width);
	}
	
	string label;
	bool horizontal;
	bool stretch;
}

class LabeledTextbox : Textbox
{
	this(Panel parent, int _offset, string _label)
	{
		super(parent);
		label = _label;
		offset = _offset;
	}
	
	override void Draw()
	{
		glBlendColor4ub(0,0,0,64);
		DGUI_FillRect(0,0,offset,height);
		glBlendColor4ub(255,255,255,255);
		DGUI_DrawText(0,16,label);
		glTranslatef(offset,0,0);
		glBlendColor4ub(96,96,96,255);
		DGUI_FillRect(0,0,width,height);
		
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(0,1);
		glVertex2i(width,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,0);
		glVertex2i(1,height);
		glEnd();
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(0,height);
		glVertex2i(width,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(width,0);
		glVertex2i(width,height);
		glEnd();
		glBlendColor4ub(255,255,255,255);
		glRasterPos2i(0,16);
		DGUI_DrawText(0,16,text);
		glTranslatef(-offset,0,0);
	}
	
	override bool HasHit(int hx, int hy)
	{
		return hx >= offset && hy >= 0 && hx < width+offset && hy < height;
	}
	
	string label;
	int offset;
}



class Optionbox : LabeledPanel
{
	this(Panel parent)
	{
		super(parent,"");
	}
	
	override void PerformLayout()
	{
		LayoutVertically(2,true);
		Stretch();
	}
	
	void Select(Button button)
	{
		label = button.text;
	}
	
	void AddOption(string option)
	{
		label = option;
		Button newoptionbutton = new Button(this);
		newoptionbutton.text = option;
		newoptionbutton.callback2 = &Select;
	}
}

class GenericPropertyBox(ValueType) : Panel
{
	class GenericPropertyPanel : Panel
	{
		this(GenericPropertyBox parent, string origkey)
		{
			super(parent);
			removebutton = new Button(this);
			removebutton.callback = &RemovePressed;
			removebutton.text = "-";
			key = new Textbox(this);
			key.width = 128;
			value = new ValueType(this);
			key.text = origkey;
			addbutton = new Button(this);
			addbutton.text = "+";
			addbutton.callback = &parent.AddPropertyEmpty;
		}
		
		void RemovePressed()
		{
			if(parent.children.length > 1)
			{
				this.destroy();
			}
		}
		
		override void PerformLayout()
		{
			key.x = removebutton.width;
			value.x = key.x+key.width + 8;
			addbutton.x = value.x+value.width;
			
			Stretch();
		}
		
		Textbox key;
		ValueType value;
		Button addbutton;
		Button removebutton;
	}
	
	this(Panel parent, bool addempty = true)
	{
		super(parent);
		if(addempty)
		{
			AddPropertyEmpty();
		}
	}
	
	void AddPropertyEmpty()
	{
		AddProperty();
	}
	
	void AddProperty(string key = "")
	{
		new GenericPropertyPanel(this,key);
	}
	
	override void PerformLayout()
	{
		LayoutVertically(2,true);
		Stretch();
	}
}

class Propertybox : Panel
{
	class PropertyPanel : Panel
	{
		this(Propertybox parent, string origkey, string origvalue)
		{
			super(parent);
			removebutton = new Button(this);
			removebutton.callback = &RemovePressed;
			removebutton.text = "-";
			key = new Textbox(this);
			key.width = 128;
			value = new Textbox(this);
			value.stretch = true;
			key.text = origkey;
			value.text = origvalue;
			addbutton = new Button(this);
			addbutton.text = "+";
			addbutton.callback = &parent.AddPropertyEmpty;
		}
		
		void RemovePressed()
		{
			if(parent.children.length > 1)
			{
				this.destroy();
			}
		}
		
		override void PerformLayout()
		{
			key.x = removebutton.width;
			value.x = key.x+key.width + 8;
			addbutton.x = value.x+value.width;
			
			Stretch();
		}
		
		Textbox key;
		Textbox value;
		Button addbutton;
		Button removebutton;
	}
	
	this(Panel parent, bool addempty = true)
	{
		super(parent);
		if(addempty)
		{
			AddPropertyEmpty();
		}
	}
	
	void AddPropertyEmpty()
	{
		AddProperty();
	}
	
	void AddProperty(string key = "", string value = "")
	{
		new PropertyPanel(this,key,value);
	}
	
	override void PerformLayout()
	{
		LayoutVertically(2,true);
		Stretch();
	}
}

void readOutput(ref File output, string* stext, bool[string] jobs, string jobid)
{
	char[] ye = new char[16];
    while (!output.eof)
	{
        *stext ~= output.rawRead(ye);
    }
	jobs.remove(jobid);
}

class Terminal : Panel
{
	this(Panel parent)
	{
		super(parent);
	}
	
	void DoCommand(string jobid, string cmd)
	{
		if((jobid in jobs) !is null)
		{
			return;
		}
		jobs[jobid] = true;
		task!readOutput(pipeProcess(cmd.split(" "), Redirect.stdout).stdout, &text, jobs, jobid).executeInNewThread();
	}
	
	void Write(T...)(T args)
	{
		foreach(string arg; args)
		{
			text ~= arg;
		}
		text ~= "\n";
	}
	
	override void Draw()
	{
		glBlendColor4ub(64,64,64,255);
		DGUI_FillRect(0,0,width,height);
		
		glBlendColor4ub(0,0,0,192);
		glBegin(GL_LINES);
		glVertex2i(0,1);
		glVertex2i(width,1);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(1,0);
		glVertex2i(1,height);
		glEnd();
		glBlendColor4ub(255,255,255,192);
		glBegin(GL_LINES);
		glVertex2i(0,height);
		glVertex2i(width,height);
		glEnd();
		glBegin(GL_LINES);
		glVertex2i(width,0);
		glVertex2i(width,height);
		glEnd();
		glBlendColor4ub(255,255,255,255);
		glRasterPos2i(0,16);
		int linecount = 0;
		int cutoff = 0;
		for(int i = cast(int)text.length; i-- > 0;)
		{
			if(text[i] == '\n')
			{
				linecount++;
				if(linecount > height/16)
				{
					cutoff = i+1;
					break;
				}
			}
		}
		DGUI_DrawText(0,16,text[cutoff..$],width);
	}
	string text;
	bool[string] jobs;
}

class Window : Panel
{
	class TitleBar : Button
	{
		this(Panel parent)
		{
			super(parent);
			//text = "hi!! i love you all thank you";
		}
		
		override void PerformLayout()
		{
			if(state)
			{
				double dxpos, dypos;
				glfwGetCursorPos(window, &dxpos, &dypos);
				int wxpos, wypos;
				glfwGetWindowPos(window, &wxpos,&wypos);
				glfwSetWindowPos(window, wxpos+cast(int)dxpos-deltaposx, wypos+cast(int)dypos-deltaposy);
			}
			LayoutHorizontally();
		}
		
		override void Click(int cx, int cy, int button, int action)
		{
			if(action == GLFW_RELEASE)
			{
				state = false;
			}
			else
			{
				
				state = true;
				deltaposx = max(0,cx+x);
				deltaposy = max(0,cy+y);
				
			}
		}
		
		int deltaposx = 0;
		int deltaposy = 0;
	}
	this()
	{
		close = new Button(this);
		close.callback = &CloseWindow;
		close.text = "X";
		titlebar = new TitleBar(this);
		inner = new Panel(this);
	}
	
	void CloseWindow()
	{
		glfwSetWindowShouldClose(window, GLFW_TRUE);
	}
	
	override void PerformLayout()
	{
		close.x = width-close.width-4;
		close.y = 4;
		titlebar.x = 4;
		titlebar.y = 4;
		titlebar.width = width-close.width-12;
		inner.x = 4;
		inner.y = 4+titlebar.height+4;
		inner.width = width-8;
		inner.height = height-8-titlebar.height-4;
	}
	Button close;
	TitleBar titlebar;
	Panel inner;
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

void DGUI_PutRect(int x, int y, int w, int h)
{
	glBegin(GL_LINE_LOOP);
	glVertex2i(x+1,y+1);
	glVertex2i(x+w,y+1);
	glVertex2i(x+w,y+h);
	glVertex2i(x+1,y+h);
	glEnd();
}

void DGUI_FillRect(int x, int y, int w, int h)
{
	glBegin(GL_TRIANGLE_STRIP);
	glVertex2i(x+w,y);
	glVertex2i(x,y);
	glVertex2i(x+w,y+h);
	glVertex2i(x,y+h);
	glEnd();
}


public Window mainpanel;
public Panel focusedpanel;
public byte* fontbuffer;

void DGUI_CaptureFocus(Panel panel)
{
	focusedpanel = panel;
}

void DGUI_Draw(int width, int height)
{
	glLoadIdentity();
    glOrtho(0, width, height, 0, 10.0f, -10.0f);
	mainpanel.width = width;
	mainpanel.height = height;
	
	mainpanel.InternalDraw();
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