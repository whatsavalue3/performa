import bindbc.loader;
import bindbc.sdl;
import std.stdio;

void main()
{
	loadSDL();
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_CreateWindowAndRenderer(1280, 720, 0, &window, &renderer);
	
	
	SDL_Event ev;
	bool run = true;
	while(run)
	{
		SDL_RenderPresent(renderer);
	
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
		
		SDL_GL_SwapWindow(window);
	}
	
	SDL_DestroyWindow(window);
	
	SDL_Quit();
}
