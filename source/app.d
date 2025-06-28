import bindbc.loader;
import bindbc.sdl;
import std.stdio;

void main()
{
	loadSDL();
	SDL_Init(SDL_INIT_VIDEO);
	
	SDL_CreateWindow("Performa", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 1280, 720, 0);
	
	
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
				default:
					break;
			}
		}
	}
	
	SDL_Quit();
}