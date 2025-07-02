import std.stdio;
import std.math;


struct Vec(T, int size)
{
	T[size] a;
	
	alias this = a;
	

	Vec!(T,size) opBinary(string op : "*")(T b)
	{
		Vec!(T,size) ret;
		static foreach(i; 0 .. size)
		{
			ret[i] = a[i]*b;
		}
		return ret;
	}

	
	T opBinary(string op : "*")(Vec!(T,size) b)
	{
		T sum = 0;
		static foreach(i; 0 .. size)
		{
			sum += a[i]*b[i];
		}
		return sum;

	}
	
	Vec!(T,size) opBinary(string op : "+")(Vec!(T,size) b)
	{
		Vec!(T,size) ret;
		static foreach(i; 0 .. size)
		{
			ret[i] = a[i]+b[i];
		}
		return ret;
	}

	
	Vec!(T,size) opBinary(string op : "-")(Vec!(T,size) b)
	{
		Vec!(T,size) ret;
		static foreach(i; 0 .. size)
		{
			ret[i] = a[i]-b[i];
		}
		return ret;
	}

	
	Vec!(T,size) opUnary(string op : "~")()
	{
		Vec!(T,size) ret = a;
		T mag = 0.0;
		static foreach(i; 0 .. size)
		{
			mag += a[i]*a[i];
		}
		mag = 1.0/sqrt(mag);
		ret = ret*mag;
		return ret;
	}
	
	T opUnary(string op : "*")()
	{
		Vec!(T,size) ret = a;
		T mag = 0.0;
		static foreach(i; 0 .. size)
		{
			mag += a[i]*a[i];
		}
		return mag;
	}
	
	
	this(T[size] b)
	{
		a = b;
	}
}

struct Quat(T)
{
	Vec!(T, 4) a = [1,0,0,0];
	
	alias this = a;
	
	Quat!(T) opBinary(string op : "*")(Quat!(T) b)
	{
		Quat!(T) prod;
		prod[0] = a[0]*b[0]-a[1]*b[1]-a[2]*b[2]-a[3]*b[3];
		prod[1] = a[0]*b[1]+a[1]*b[0]+a[2]*b[3]-a[3]*b[2];
		prod[2] = a[0]*b[2]-a[1]*b[3]+a[2]*b[0]+a[3]*b[1];
		prod[3] = a[0]*b[3]+a[1]*b[2]-a[2]*b[1]+a[3]*b[0];
		return prod;
	}
	
	Vec!(T,3) opBinary(string op : "*")(Vec!(T,3) b)
	{
		Vec!(T,3) prod;
		Vec!(T,3) u = [a[1],a[2],a[3]];
		T dUV2 = 2*(u*b);
		T dUU = u*u;
		T cX = u[2]*b[1]-u[1]*b[2];
		T cY = u[0]*b[2]-u[2]*b[0];
		T cZ = u[1]*b[0]-u[0]*b[1];
		T s2 = 2*a[0];
		T ssmdUU = a[0]*a[0]-dUU;
		prod[0] = dUV2*u[0] + ssmdUU*b[0] + s2*cX;
		prod[1] = dUV2*u[1] + ssmdUU*b[1] + s2*cY;
		prod[2] = dUV2*u[2] + ssmdUU*b[2] + s2*cZ;
		return prod;
	}
	
	Quat!(T) opUnary(string s : "~")()
    {
        return [a[0],-a[1],-a[2],-a[3]];
    }
	
	ref T opIndex(ulong x)
	{
		return a[x];
	}
}

struct Mat(T, int width, int height)
{
	T[width*height] a = 0;
	
	alias this = a;
	Mat!(T, width, height) opBinary(string op : "*")(Mat!(T,width,height) b)
	{
		Mat!(T, width, height) c;
		ulong index = 0;
		static foreach(x; 0 .. width)
		{
			static foreach(y; 0 .. height)
			{
				index = y+x*height;
				c[index] = 0;
				static foreach(i; 0 .. height)
				{
					c[index] += a[y+i*height]*b[i+x*height];
				}
			}
		}
		return c;
	}
	
	Mat!(T, width, height) opBinary(string op : "+")(Mat!(T,width,height) b)
	{
		Mat!(T, width, height) c;
		ulong index = 0;
		static foreach(x; 0 .. width)
		{
			static foreach(y; 0 .. height)
			{
				index = y+x*width;
				c[index] = (a[index])+(b[index]);
			}
		}
		return c;
	}
	
	ref T opIndex(ulong x, ulong y)
	{
		return a[y+x*height];
	}
	
	ref T opIndex(ulong x)
	{
		return a[x];
	}
	
}

alias float2 = Vec!(float, 2);
alias float3 = Vec!(float, 3);
alias float4 = Vec!(float, 4);
alias floatq = Quat!(float);

alias float4x4 = Mat!(float,4,4);

alias double2 = Vec!(double, 2);
alias double3 = Vec!(double, 3);
alias double4 = Vec!(double, 4);
alias doubleq = Quat!(double);

alias int2 = Vec!(int, 2);
alias int3 = Vec!(int, 3);
alias int4 = Vec!(int, 4);

alias uint2 = Vec!(uint, 2);
alias uint3 = Vec!(uint, 3);
alias uint4 = Vec!(uint, 4);

struct Transform3D
{
	float3 position = [0,0,0];
	floatq rotation;
	float3 scale = [1,1,1];
	
	float4x4 opCast(T)()
	{
		float4x4 pret = cast(float4x4)[1,0,0,0,
		0,1,0,0,
		0,0,1,0,
		position[0],position[1],position[2],1];
		
		float4x4 ret = cast(float4x4)[1,0,0,0,
		0,1,0,0,
		0,0,1,0,
		0,0,0,1];
		
		ret[0,0] = 1-2*(rotation[2]*rotation[2]+rotation[3]*rotation[3]);
		ret[1,1] = 1-2*(rotation[1]*rotation[1]+rotation[3]*rotation[3]);
		ret[2,2] = 1-2*(rotation[1]*rotation[1]+rotation[2]*rotation[2]);
		
		ret[0,1] = 2*(rotation[1]*rotation[2]+rotation[0]*rotation[3]);
		ret[1,0] = 2*(rotation[1]*rotation[2]-rotation[0]*rotation[3]);
		
		ret[0,2] = 2*(rotation[1]*rotation[3]-rotation[0]*rotation[2]);
		ret[2,0] = 2*(rotation[1]*rotation[3]+rotation[0]*rotation[2]);
		
		ret[1,2] = 2*(rotation[2]*rotation[3]+rotation[0]*rotation[1]);
		ret[2,1] = 2*(rotation[2]*rotation[3]-rotation[0]*rotation[1]);
		
		
		return ret * pret;
	}
}

struct Transform2D
{
	float2 position;
	float rotation;
	float2 scale;
}

