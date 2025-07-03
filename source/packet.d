import math;


struct Packet1CamVars
{
	uint type = 1;
	float camrot;
	float3 camvel;
	float color;
};

struct Packet2AddVert
{
	uint type = 2;
};

struct Packet3SetVert
{
	uint type = 3;
	ulong vertid;
	float2 pos;
};