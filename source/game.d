import bindbc.sdl;
import math;

class Entity
{
	float[3] pos;
}


struct Edge
{
	ulong start;
	ulong end;
	float height;
	float offset;
}

public float2[] verts;
public Edge[] edges;

