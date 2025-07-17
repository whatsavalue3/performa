import dguiw;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.file;
import std.string;
import game;
import math;
import std.algorithm;
import client;



uint SampleTexture(float2 uv, TextureData tex)
{
	ulong x = cast(ulong)(abs(uv[0]%1.0f)*tex.width);
	ulong y = cast(ulong)((1.0f-abs(uv[1]%1.0f))*tex.height);
	
	return tex.pixels[x+y*tex.width];
}




class ViewportPanel : Panel
{
	SDL_Texture* tex = null;
	ubyte[] pix;
	
	ulong time = 0;
	bool fisheye = false;
	
	this(Panel p)
	{
		super(p);
		width = 480;
		height = 360;
		pix = new ubyte[width*height*4];
		//LoadTexture("trippy_floor.bmp");
		//LoadTexture("tired_sky.bmp");
	}
	
	bool DrawCeilingFloor(ulong sectorindex, bool floor, float3 cdir, float3 castpos, out uint col)
	{
		Sector sector = g.sectors[sectorindex];
		if(sector.deleted)
		{
			return false;
		}
		float2 rdir = float2([cdir[0],cdir[1]]);
		float cdot;
		if(floor)
		{
			cdot = ((sector.low-castpos[2]))/cdir[2];
		}
		else
		{
			cdot = ((sector.high-castpos[2]))/cdir[2];
		}
		float2 chit = rdir*cdot;
		
		/*
		float2 castpos2 = float2([castpos[0],castpos[1]]);
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			float2 diff = g.verts[edge.end]-g.verts[edge.start];
			float2 n = ~float2([diff[1],-diff[0]]);
			float dist = n*(g.verts[edge.start]-castpos2);
			if(chit*n < dist)
			{
				return false;
			}
		}
		*/
		
		float2 uv = float2([chit[0]+castpos[0],chit[1]+castpos[1]])*0.25f;
		if(sector.ceilingtex < texturedict.length)
		{
			col = SampleTexture(uv,texturedict[sector.ceilingtex]);
			float R = cast(ubyte)(col>>16);
			float G = cast(ubyte)(col>>8);
			float B = cast(ubyte)(col);
			cdot *= 0.125f;
			R /= 1+cdot;
			G /= 1+cdot;
			B /= 1+cdot;
			R = clamp(R,0,255);
			G = clamp(G,0,255);
			B = clamp(B,0,255);
			col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
			/*
			float R = cast(ubyte)(col>>16);
			float G = cast(ubyte)(col>>8);
			float B = cast(ubyte)(col);
			float lR = 0.0f;
			float lG = 0.0f;
			float lB = 0.0f;
			float3 rayend = castpos + cdir*cdot;
			foreach(ei,entity; g.entities)
			{
				float3 endpos = entity.pos+float3([0.0,0.0,1.8f]);
				if(ei == viewent || Visible(sectorindex,rayend,endpos))
				{
					float projfactor = 60000000.0f/((rayend-endpos)*(rayend-endpos));
					lR += R*projfactor;
					lG += G*projfactor;
					lB += B*projfactor;
				}
			}
			R = clamp(sqrt(sqrt(lR)),0,255);
			G = clamp(sqrt(sqrt(lG)),0,255);
			B = clamp(sqrt(sqrt(lB)),0,255);
			col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
			*/
			
		}
		return true;
	}
	
	bool Visible(ulong sectorindex, float3 castpos, float3 endpos)
	{
		Sector sector = g.sectors[sectorindex];
		bool ret = false;
		float cdist = *(endpos-castpos);
		float3 cdir = ~(endpos-castpos);
		
		
		if(sector.deleted)
		{
			return false;
		}
		float2 rdir = float2([cdir[0],cdir[1]]);
		float cdot;
		if(cdir[2] < 0)
		{
			cdot = ((sector.low-castpos[2]))/cdir[2];
		}
		else
		{
			cdot = ((sector.high-castpos[2]))/cdir[2];
		}
		float2 chit = rdir*cdot;
		
		bool fail = false;
		/*
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			float2 n = g.EdgeNormal(edge);
			float dist = n*(g.verts[edge.start]-float2([castpos[0],castpos[1]]));
			float score = chit*n - dist;
			if(score < 0)
			{
				fail = true;
				break;
			}
		}
		*/

		
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			
			
			float3 start = (float3([g.verts[edge.start][0],g.verts[edge.start][1],-edge.offset])-castpos);
			float3 end = (float3([g.verts[edge.end][0],g.verts[edge.end][1],-edge.offset])-castpos);
			float3 diff = end-start;
			float ndist = sqrt(diff[0]*diff[0]+diff[1]*diff[1]);
			float3 n = float3([diff[1]/ndist,-diff[0]/ndist, 0.0f]);
			
			float3 wallv = float3([diff[0]/ndist,diff[1]/ndist,0.0f]);
			
			float ndot = n*cdir;
			
			float walldot = (start*n)/ndot;
			
			float3 proj = (cdir*walldot-start);
			
			float along = proj*wallv;
			float alongy = proj[2];
			
			
			
			if(along < 0 || along > ndist)
			{
				continue;

			}
			

			
			if((alongy < 0) || (alongy > edge.height))
			{
				continue;
			}
			
			if(ndot > 0)
			{
				continue;
			}
			
			if(edge.hidden)
			{
				return Visible(edge.portal,castpos,endpos);
			}
			else
			{
				return *(cdir*walldot) >= cdist;
			}
		}
		return *(cdir*cdot) >= cdist;
	}
	ulong depth = 0;
	bool DrawWalls(ulong sectorindex, float3 cdir, float3 castpos, out uint col)
	{
		depth++;
		if(depth > 256)
		{
			return true;
		}
		Sector sector = g.sectors[sectorindex];
		float2 rdir = float2([cdir[0],cdir[1]]);
		float cdot;
		if(cdir[2] < 0)
		{
			cdot = ((sector.low-castpos[2]))/cdir[2];
		}
		else
		{
			cdot = ((sector.high-castpos[2]))/cdir[2];
		}
		float2 chit = rdir*cdot;
		
		float2 cuv = float2([chit[0]+castpos[0],chit[1]+castpos[1]])*0.25f;
		
		bool ret = false;
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			
			
			float3 start = (float3([g.verts[edge.start][0],g.verts[edge.start][1],-edge.offset])-castpos);
			float3 end = (float3([g.verts[edge.end][0],g.verts[edge.end][1],-edge.offset])-castpos);
			float3 diff = end-start;
			float ndist = sqrt(diff[0]*diff[0]+diff[1]*diff[1]+diff[2]*diff[2]);
			float3 n = float3([diff[1]/ndist,-diff[0]/ndist, diff[2]/ndist]);

			
			float ndot = n*cdir;
			
			if(ndot > 0)
			{
				continue;
			}
			
			float walldot = (start*n)/ndot;
			
			
			float3 proj = (cdir*walldot-start);
			float3 wallv = float3([diff[0]/ndist,diff[1]/ndist,0.0f]);
			
			float along = proj*wallv;
			
			
			
			if(along < 0 || along > ndist)
			{
				continue;
			}
			
			float alongy = proj[2];
			
			if((alongy < 0) || (alongy > edge.height))
			{
				if(((edge.offset >= -sector.low) && (alongy < 0)) || ((edge.height-edge.offset >= sector.high) && (alongy > edge.height)))
				{
					if(chit[0]*n[0]+chit[1]*n[1] > 0)
					{
						continue;
					}
					if(sector.ceilingtex >= texturedict.length)
					{
						col = 0xff00ff00;
						depth--;
						return true;
					}
					col = SampleTexture(cuv,texturedict[sector.ceilingtex]);
					float R = cast(ubyte)(col>>16);
					float G = cast(ubyte)(col>>8);
					float B = cast(ubyte)(col);
					cdot *= 0.0625f;
					R /= 1+cdot;
					G /= 1+cdot;
					B /= 1+cdot;
					R = clamp(R,0,255);
					G = clamp(G,0,255);
					B = clamp(B,0,255);
					col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
					ret = true;
					break;
				}
				else
				{
					continue;
				}
			}
			
			
			
			
			
			
			if(edge.hidden)
			{
				ret |= DrawWalls(edge.portal,cdir,castpos,col);
			}
			else
			{
				float2 uv = float2([along/ndist,1.0f-alongy/edge.height]);
				if(edge.texture >= g.textures.length)
				{
					col = 0xffff00ff;
				}
				else
				{
					if(edge.texture >= texturedict.length)
					{
						col = 0xff00ff00;
					}
					else
					{
						col = SampleTexture(uv,texturedict[edge.texture]);
						float R = cast(ubyte)(col>>16);
						float G = cast(ubyte)(col>>8);
						float B = cast(ubyte)(col);
						walldot *= 0.0625f;
						R /= 1+walldot;
						G /= 1+walldot;
						B /= 1+walldot;
						R = clamp(R,0,255);
						G = clamp(G,0,255);
						B = clamp(B,0,255);
						col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
						/*
						float R = cast(ubyte)(col>>16);
						float G = cast(ubyte)(col>>8);
						float B = cast(ubyte)(col);
						float lR = 0.0f;
						float lG = 0.0f;
						float lB = 0.0f;
						float3 rayend = castpos + cdir*walldot;
						foreach(ei, entity; g.entities)
						{
							float3 endpos = entity.pos+float3([0.0,0.0,1.8f]);
							if(ei == viewent || Visible(sectorindex,rayend,endpos))
							{
								float projfactor = 60000000.0f/((rayend-endpos)*(rayend-endpos));
								lR += R*projfactor;
								lG += G*projfactor;
								lB += B*projfactor;
							}
						}
						R = clamp(sqrt(sqrt(lR)),0,255);
						G = clamp(sqrt(sqrt(lG)),0,255);
						B = clamp(sqrt(sqrt(lB)),0,255);
						col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
						*/

					}
				}
				ret = true;
			}
			
			break;
		}
		
		foreach(ei,entity; g.entities)
		{
			//if(ei == viewent)
			//{
			//	continue;
			//}
			if(entity.cursector != sectorindex)
			{
				continue;
			}
			if(entity.model != -1)
			{
				uint origcol = col;
				foreach(modelsectorindex; g.models[entity.model].sectors)
				{
					if(!DrawWalls(modelsectorindex,cdir,castpos-entity.pos,col))
					{
						col = origcol;
					}
					else
					{
						ret = true;
						origcol = col;
					}
				}
				continue;
			}
			
			float3 entpos = entity.pos;
			
			entpos[2] += 1.3f;
			float3 up = entpos-castpos;
			
			float3 p = ~(up);
			float cu = (cdir*up);
			if(cu < 1.0f)
			{
				continue;
			}
			float closeness = up*up - cu*cu;
			/*
			if(closeness >= 1.0f)
			{
				continue;
			}
			float3 where = ~(entpos-(castpos + cdir*(cu-sqrt(1.0f-closeness)*0.5f)));
			float3 cubecoord = float3([abs(where[0])^^2,abs(where[1])^^2,abs(where[2])^^2]);
			cubecoord = cubecoord * (0.57735026919f/max(cubecoord[0],cubecoord[1],cubecoord[2]));
			cubecoord = float3([sgn(where[0])*(0.57735026919f-cubecoord[0]),sgn(where[1])*(0.57735026919f-cubecoord[1]),sgn(where[2])*(0.57735026919f-cubecoord[2])]);
			up = entpos-castpos+ where + cubecoord;
			p = ~(up);
			cu = (cdir*up);
			if(cu < 0.0f)
			{
				continue;
			}
			closeness = up*up - cu*cu;
			*/
			if(closeness < 1.0f)
			{
				float fresnel = sqrt(1.0f-closeness);
				float dist = cu-fresnel;
				float3 normal = ~(cdir-p*fresnel*2);
				DrawWalls(sectorindex,normal,castpos+cdir*dist,col);
				float light = normal[2];
				light *= 6.0f;
				if(light < 0.2f)
				{
					light = 0.0f;
				}
				else if(light < 0.3f)
				{
					
				}
				else
				{
					light += 0.2f;
				}
				light = clamp(light,0.0f,10.0f);
				float R = cast(ubyte)(col>>16)+20;
				float G = cast(ubyte)(col>>8)+20;
				float B = cast(ubyte)(col)+20;
				fresnel = closeness;
				fresnel = fresnel*fresnel*1.8f+0.3f;
				
				R = ((R*fresnel*(0.25f+entity.color[0])*0.75f)+light*(0.25f+entity.color[0])*0.75f*255);
				G = ((G*fresnel*(0.25f+entity.color[1])*0.75f)+light*(0.25f+entity.color[1])*0.75f*255);
				B = ((B*fresnel*(0.25f+entity.color[2])*0.75f)+light*(0.25f+entity.color[2])*0.75f*255);
				R = clamp(R,0,255);
				G = clamp(G,0,255);
				B = clamp(B,0,255);
				col = (cast(ubyte)(R) << 16) | (cast(ubyte)(G) << 8) | (cast(ubyte)(B));
				ret = true;
			}
		}
		depth--;
		return ret;
	}
	
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		
		this.time++;
		if(tex is null)
		{
			tex = SDL_CreateTexture(renderer,SDL_PIXELFORMAT_RGBA8888,SDL_TEXTUREACCESS_STREAMING,width/2,height/2);
		}
	
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		
		DGUI_FillRect(renderer, 0, 0, width, height);
		
		SDL_SetRenderDrawColor(renderer, 127, 127, 127, 255);
		
		if(g.entities.length <= viewent)
		{
			return;
		}
		
		
		
		float3 castpos = g.entities[viewent].pos;
		SDL_SetRenderDrawColor(renderer, cast(ubyte)(clamp(g.entities[viewent].color[0]*255,0,255)), cast(ubyte)(clamp(g.entities[viewent].color[1]*255,0,255)), cast(ubyte)(clamp(g.entities[viewent].color[2]*255,0,255)), 255);
		DGUI_FillRect(renderer,-1,-1,width+2,height+2);
		castpos[2] += g.camheight;
		pix[] = 0;
		foreach(x; 0..width/2)
		{
			
			float nx = (cast(float)(width)/height-cast(float)(x*2)/width*cast(float)(width)/height*2);
			float snx, cnx;
			if(fisheye)
			{
				snx = sin(nx);
				cnx = cos(nx);
			}
			
			
			
			if(g.sectors.length != 0)
			{
				foreach(y; 0..height/2)
				{
					float ny = (0.5f-cast(float)(y*2)/height)*2;
					float3 cdir;
					if(fisheye)
					{
						float sny = sin(ny);
						float cny = cos(ny);
						cdir = ~(g.camforward*cnx*cny - g.camright*snx + g.camup*sny);
					}
					else
					{
						cdir = ~(g.camforward - g.camright*nx + g.camup*ny);
					}
					ulong i = (x+y*width/2)*4;
					uint col = 0;
					if(DrawWalls(g.entities[viewent].cursector,cdir,castpos,col))
					{
						pix[i+1] = cast(ubyte)(col);
						pix[i+2] = cast(ubyte)(col>>8);
						pix[i+3] = cast(ubyte)(col>>16);
					}
				}
			}
			
			
		}
		auto rec = SDL_Rect(0, 0, width/2, height/2);
		SDL_UpdateTexture(tex,&rec,pix.ptr,width*4/2);
		DGUI_RenderCopy(renderer,tex,0,0,width,height);
	}

	override void MousePressed(int x, int y, MouseButton button, bool covered)
	{
		if(InBounds(x, y) && !covered)
		{
			captured = true;
			DGUI_CaptureMouse();
		}
	}

	override void KeyDown(int keysym)
	{
		if(keysym == SDLK_ESCAPE)
		{
			captured = false;
			DGUI_CaptureMouse(false);
		}
	}
	
	override void MouseMoved(int x, int y, int dx, int dy, bool covered)
	{
		if(captured)
		{
			g.camrot += cast(float)(dx)/720;
			g.campitch += cast(float)(dy)/720;
		}
	}

	bool captured = false;
}
