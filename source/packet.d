import math;
import game;

struct Packet1CamVars
{
	uint type = 1;
	float camrot;
	float3 camvel;
	float color;
	float saturation;
	float value;
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

struct Packet4AddEdge
{
	uint type = 4;
	Edge edge;
};

struct Packet5AddSector
{
	uint type = 5;
};

struct Packet6SetEdgeSector
{
	uint type = 6;
	ulong edge;
	ulong sector;
};

struct Packet7SetEdgePortal
{
	uint type = 7;
	ulong edge;
	ulong sector;
};

struct Packet8ToggleVis
{
	uint type = 8;
	ulong edge;
	bool hidden;
};

struct Packet9SectorHeight
{
	uint type = 9;
	ulong sector;
	float low;
	float high;
};

struct Packet10EdgeHeight
{
	uint type = 10;
	ulong edge;
	float height;
	float offset;
};

struct Packet11EdgeTexture
{
	uint type = 11;
	ulong edge;
	char[64] texture;
};

struct Packet12LoadMap
{
	uint type = 12;
}

struct Packet13AddEntity
{
	uint type = 13;
}

struct Packet14SetEntityModel
{
	uint type = 14;
}