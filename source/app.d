import bindbc.loader;
import bindbc.sdl;
import std.stdio;
import dgui;
import testing;
import menu;
import input;
import mapeditor;
import client;
import game;


void main()
{
	loadSDL();
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_CreateWindowAndRenderer(1280, 720, 0, &window, &renderer);

	SDL_SetWindowTitle(window, "Performa");
	
	SDL_Event ev;
	
	mainpanel = new MenuPanel();
	focusedpanel = mainpanel;
	SDL_GL_SetSwapInterval(1);
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
					DGUI_HandleMouse(ev.button.x,ev.button.y,ev.button.button,ev.button.state);
					break;
				case SDL_MOUSEBUTTONUP:
					DGUI_HandleMouse(ev.button.x,ev.button.y,ev.button.button,ev.button.state);
					break;
				case SDL_MOUSEMOTION:
					DGUI_MouseMove(ev.motion.x,ev.motion.y,ev.motion.xrel,ev.motion.yrel,ev.motion.state);
					break;
				default:
					inputHandler.HandleEvent(ev);
					break;
			}
		}

		client.Tick();
		game.Tick();
		
		DGUI_Draw(renderer);
		
		SDL_RenderPresent(renderer);
	}
	
	SDL_DestroyWindow(window);
	
	SDL_Quit();
}
