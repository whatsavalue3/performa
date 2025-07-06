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
	
	DGUI_SetRoot(new MenuPanel());
	//SDL_GL_SetSwapInterval(1);

	int mouse_x;
	int mouse_y;
	SDL_GetMouseState(&mouse_x, &mouse_y);

	SDL_Event ev;

	bool run = true;
	ulong time = SDL_GetTicks64();
	while(run)
	{
		int delta = cast(int)(SDL_GetTicks64() - time);
		time = SDL_GetTicks64();
		while(SDL_PollEvent(&ev))
		{
			switch(ev.type)
			{
				case SDL_QUIT:
					run = false;
					break;
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
					int dx = ev.button.x - mouse_x;
					int dy = ev.button.y - mouse_y;
					mouse_x = ev.button.x;
					mouse_y = ev.button.y;
					rootpanel.MouseMoved(ev.button.x, ev.button.y, dx, dy);
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
				case SDL_WINDOWEVENT:
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

		SDL_GetWindowSize(window, &rootpanel.width, &rootpanel.height);
		
		DGUI_ProcessFrame(renderer, delta);
		
		SDL_RenderPresent(renderer);
	}
	
	SDL_DestroyWindow(window);
	
	SDL_Quit();
}
