module input;
import dgui;
import bindbc.sdl;
import std.stdio;

enum ActionState
{
	RELEASED,
	JUST_PRESSED,
	_,
	PRESSED
}

bool IsPressed(ActionState action)
{
	return cast(int)action > 0;
}

bool IsJustPressed(ActionState action)
{
	return action == ActionState.JUST_PRESSED;
}

struct InputHandler
{
	ActionState forwards = ActionState.RELEASED;
	ActionState backwards = ActionState.RELEASED;
	ActionState left = ActionState.RELEASED;
	ActionState right = ActionState.RELEASED;
	ActionState jump = ActionState.RELEASED;
	bool dgui_passthrough = false;
	uint held = 0;
	
	void HandleKeyEvent(SDL_KeyboardEvent event)
	{
		auto isp = cast(int)(event.state == SDL_PRESSED);
		switch(event.keysym.scancode)
		{
			case SDL_SCANCODE_W:
				forwards = cast(ActionState)((isp | (cast(int)(forwards > 0) << 1)) & (isp<<1 | 1));
				break;
			case SDL_SCANCODE_S:
				backwards = cast(ActionState)((isp | (cast(int)(backwards > 0) << 1)) & (isp<<1 | 1));
				break;
			case SDL_SCANCODE_A:
				left = cast(ActionState)((isp | (cast(int)(left > 0) << 1)) & (isp<<1 | 1));
				break;
			case SDL_SCANCODE_D:
				right = cast(ActionState)((isp | (cast(int)(right > 0) << 1)) & (isp<<1 | 1));
				break;
			case SDL_SCANCODE_SPACE:
				jump = cast(ActionState)((isp | (cast(int)(jump > 0) << 1)) & (isp<<1 | 1));
				break;
			default:
				break;
		}
	}

	void HandleEvent(SDL_Event event)
	{
		switch(event.type)
		{
			case SDL_KEYDOWN:
			case SDL_KEYUP:
				HandleKeyEvent(event.key);
				break;
			default:
				break;
		}
	}
}
