module camera;
import bindbc.sdl;
import math;

struct Camera {
	float2 position;
	float2 looking;
	float fov;
	float height;

	void Move(float2 amount = float2(1,0)) {
		position += amount.x * looking + amount.y * float2(-looking.y, looking.x);
	}
}


