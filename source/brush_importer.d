import game;
import math;
import std.file;
import std.stdio;
import std.algorithm;
import std.format;

struct OBJFace
{
	size_t[][] vertices;
}

Face[] LoadOBJFile(char[] data)
{
	float3[] vertices = [];
	OBJFace[] faces = [];

	writeln(data);

	bool line_start = true;
	foreach(i, b; data)
	{
		if(line_start)
		{
			line_start = false;
			
			if(startsWith(data[i..$], "v "))
			{
				float x, y, z;
				formattedRead(data[i..i+countUntil(data[i..$], "\n")], "v %f %f %f", x, y, z);
				vertices ~= [float3([x, y, z])];
			}
			else if(startsWith(data[i..$], "f "))
			{
				OBJFace face;
				formattedRead(data[i..i+countUntil(data[i..$], "\n")], "f %(%(%u/%) %)", face.vertices);
				faces ~= [face];
			}
		}
		if(b == '\n')
		{
			line_start = true;
		}
	}

	foreach(face; faces)
	{
		float3 tangent = ~(vertices[face.vertices[1][0]] - vertices[face.vertices[0][0]]);
		writeln(tangent);
	}

	return [];
}

static this()
{
	auto cylinder = LoadOBJFile(cast(char[])read("Cylinder.obj"));
}
