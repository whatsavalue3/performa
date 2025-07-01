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

struct Sector
{
	ulong[] edges;
	float high;
	float low;
}

public float2[] verts;
public Edge[] edges;
public Sector[] sectors;

float2 EdgeNormal(Edge e)
{
	float2 diff = verts[e.end]-verts[e.start];
	return ~float2([diff[1],-diff[0]]);
}

float2 EdgeNormalVis(Edge e)
{
	float2 diff = verts[e.end]-verts[e.start];
	return float2([diff[1],-diff[0]]);
}
