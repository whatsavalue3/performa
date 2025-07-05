import bindbc.loader;
import bindbc.sdl;
import std.stdio;
import dguiw;
import testing;
import menu;
import input;
import mapeditor;
import client;
import game;
import server;



void main()
{
	loadSDL();
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_CreateWindowAndRenderer(1280, 720, SDL_WINDOW_RESIZABLE, &window, &renderer);

	SDL_SetWindowTitle(window, "Performa");	
	
	sv = new Server();
	ms = new MapServer();
	mc = new MapClient();
	cl = new Client();
	
	mainpanel = new MenuPanel();
	//focusedpanel = mainpanel;
	//SDL_GL_SetSwapInterval(1);

	int mouse_x;
	int mouse_y;
	SDL_GetMouseState(&mouse_x, &mouse_y);

	SDL_Event ev;

	bool run = true;
	while(run)
	{
	
		while(SDL_PollEvent(&ev))
		{
			switch(ev.type)
			{
				case SDL_QUIT:
					run = false;
					break;
				case SDL_MOUSEBUTTONDOWN:
					mainpanel.MousePressed(ev.button.x, ev.button.y, cast(MouseButton)(ev.button.button-1));
					break;
				case SDL_MOUSEBUTTONUP:
					mainpanel.MouseReleased(ev.button.x, ev.button.y, cast(MouseButton)(ev.button.button-1));
					break;
				case SDL_MOUSEMOTION:
					int dx = ev.button.x - mouse_x;
					int dy = ev.button.y - mouse_y;
					mouse_x = ev.button.x;
					mouse_y = ev.button.y;
					mainpanel.MouseMoved(ev.button.x, ev.button.y, dx, dy);
					break;
				case SDL_MOUSEWHEEL:
					mainpanel.WheelMoved(ev.wheel.mouseX, ev.wheel.mouseY, ev.wheel.x, ev.wheel.y);
					break;
				case SDL_TEXTINPUT:
					mainpanel.TextInput(ev.text.text[0]);
					break;
				case SDL_KEYDOWN:
					mainpanel.KeyDown(ev.key.keysym.sym);
					break;
				case SDL_WINDOWEVENT:
					SDL_GetWindowSize(window, &mainpanel.width, &mainpanel.height);
					break;
				default:
					inputHandler.HandleEvent(ev);
					break;
			}
		}
		
		if(ms.listener !is null)
		{
			ms.Tick();
		}
		
		if(mc.serversocket !is null)
		{
			mc.Tick();
		}
		
		
		if(sv.listener !is null)
		{
			sv.Tick();
		}
		
		if(cl.serversocket !is null)
		{
			client.Tick();
		}
		
		
		DGUI_ProcessFrame(renderer);
		
		SDL_RenderPresent(renderer);
	}
	
	SDL_DestroyWindow(window);
	
	SDL_Quit();
}
