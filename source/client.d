import input;
import game;
import math;

InputHandler inputHandler;


void Tick()
{
	if(inputHandler.forwards > 0)
	{
		game.camvel = game.camvel + game.camdir*0.01f;
	}
	if(inputHandler.backwards > 0)
	{
		game.camvel = game.camvel - game.camdir*0.01f;
	}
	float2 left = float2([game.camdir[1],-game.camdir[0]]);
	if(inputHandler.left > 0)
	{
		game.camvel = game.camvel + left*0.01f;
	}
	if(inputHandler.right > 0)
	{
		game.camvel = game.camvel - left*0.01f;
	}
	
	if(inputHandler.jump > 0)
	{
		game.camvelz += 0.02f;
	}
	game.camvel = game.camvel * 0.99f;
}