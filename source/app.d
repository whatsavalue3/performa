import bindbc.loader;
import bindbc.sdl;
import std.stdio;
import dgui;

void main()
{
	loadSDL();
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_CreateWindowAndRenderer(1280, 720, 0, &window, &renderer);

	SDL_SetWindowTitle(window, "Performa");
	
	SDL_Event ev;
	
	mainpanel = new Panel();
	
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
				default:
					break;
			}
		}
		
		DGUI_Draw(renderer);
		
		SDL_RenderPresent(renderer);
		SDL_GL_SwapWindow(window);
	}
	
	SDL_DestroyWindow(window);
	
	SDL_Quit();
}
