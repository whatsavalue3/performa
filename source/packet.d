import math;
import game;

mixin template VerifySize(T, alias packet)
{
	T pack = *cast(T*)(packet.ptr);
}

struct Packet1CamVars
{
	uint type = 1;
	float camrot;
	float3 camvel;
	float color;
	float saturation;
	float value;
	bool pressed;
};

struct Packet2AddVert
{
	uint type = 2;
	float2 pos;
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
	ulong entity;
	ulong model;
}

struct Packet15CreateModel
{
	uint type = 15;
}

struct Packet16AddToModel
{
	uint type = 16;
	ulong model;
	ulong sector;
}

struct Packet17SetEntityBehavior
{
	uint type = 17;
	ulong entity;
	ushort behavior;
}

struct Packet18CreateAction
{
	uint type = 18;
}

struct Packet19SetActionArg1
{
	uint type = 19;
	ulong action;
	ulong val;
}

struct Packet20SetActionArg2
{
	uint type = 20;
	ulong action;
	ulong val;
}

struct Packet21SetActionType
{
	uint type = 21;
	ulong action;
	uint val;
}

struct Packet22CreateTrigger
{
	uint type = 22;
}

struct Packet23AddToTrigger
{
	uint type = 23;
	ulong trigger;
}

struct Packet24SetTriggerAction
{
	uint type = 24;
	ulong trigger;
	ulong actionindex;
	ulong action;
}

struct Packet25RemoveTriggerAction
{
	uint type = 25;
	ulong trigger;
	ulong actionindex;
}

struct Packet26SetEntityTrigger
{
	uint type = 26;
	ulong entity;
	ulong trigger;
}

struct Packet27SetEdge
{
	uint type = 27;
	ulong edgeindex;
	ulong start;
	ulong end;
};

struct Packet28AddTexture
{
	uint type = 28;
	char[64] texture;
};