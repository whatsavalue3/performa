import bindbc.loader;
import bindbc.sdl;
import std.stdio;
import dguiw;
import testing;
import menu;
import input;
import mapeditor2;
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
	SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
	SDL_SetWindowTitle(window, "Performa");	
	
	sv = new Server();
	ms = new MapServer();
	mc = new MapClient();
	cl = new Client();

	DGUI_Init(window, renderer);
	
	DGUI_SetRoot(new MenuPanel());

	SDL_Event ev;

	bool run = true;
	ulong time = SDL_GetPerformanceCounter();
	double todiv = cast(double)SDL_GetPerformanceFrequency();
	while(run)
	{
		ulong delta = cast(ulong)(SDL_GetPerformanceCounter() - time);
		time = SDL_GetPerformanceCounter();
		while(SDL_PollEvent(&ev))
		{
			switch(ev.type)
			{
				case SDL_QUIT:
					run = false;
					break;
				default:
					DGUI_HandleEvent(ev, inputHandler);
					inputHandler.HandleEvent(ev);
					break;
			}
		}
		
		double deltad = delta/todiv;
		
		if(ms.listener !is null)
		{
			ms.Tick(deltad);
		}
		
		if(mc.serversocket !is null)
		{
			mc.Tick();
		}
		
		if(sv.listener !is null)
		{
			sv.Tick(deltad);
		}
		
		if(cl.serversocket !is null)
		{
			client.Tick();
		}

		SDL_GetWindowSize(window, &rootpanel.width, &rootpanel.height);
		
		DGUI_ProcessFrame(renderer, deltad);
		
		SDL_RenderPresent(renderer);
	}

	DGUI_Destroy();
	
	SDL_DestroyWindow(window);
	
	SDL_Quit();
}
