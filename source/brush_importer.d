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

Face[] LoadOBJFile(char[] data, ref ClipFace[] clipfaces)
{
	float3[] vertices = [float3([0,0,0])];
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
	
	Face[] returnfaces;

	foreach(face; faces)
	{
		Face ret;
		float3 tangent = ~(vertices[face.vertices[1][0]] - vertices[face.vertices[0][0]]);
		float3 othertangent = ~(vertices[face.vertices[2][0]] - vertices[face.vertices[1][0]]);
		float3 normal = ~(float3([
			tangent[1]*othertangent[2]-tangent[2]*othertangent[1],
			tangent[2]*othertangent[0]-tangent[0]*othertangent[2],
			tangent[0]*othertangent[1]-tangent[1]*othertangent[0]
		]));
		float3 bitangent = (float3([
			tangent[1]*normal[2]-tangent[2]*normal[1],
			tangent[2]*normal[0]-tangent[0]*normal[2],
			tangent[0]*normal[1]-tangent[1]*normal[0]
		]));
		ret.normal = normal;
		ret.tangent = tangent;
		ret.bitangent = bitangent;
		ret.distance = vertices[face.vertices[1][0]]*normal;
		foreach(i, verti; face.vertices)
		{
			float3 vert = vertices[verti[0]];
			ulong oi = (i+1)%face.vertices.length;
			float3 overt = vertices[face.vertices[oi][0]];
			float2 start = float2([tangent*vert,bitangent*vert]);
			float2 end = float2([tangent*overt,bitangent*overt]);
			float2 diff = end-start;
			float2 dnor = ~float2([diff[1],-diff[0]]);
			clipfaces ~= ClipFace(dnor,start*dnor);
			ret.clipfaces ~= clipfaces.length-1;
		}
		returnfaces ~= ret;
	}
	writeln(returnfaces);

	return returnfaces;
}

static this()
{

}
