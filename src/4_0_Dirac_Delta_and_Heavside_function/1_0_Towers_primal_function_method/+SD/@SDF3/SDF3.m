classdef SDF3 < handle
	
	%SDF3 : signed distance function in 3D

	properties (SetAccess = immutable)
		GD3 % SD.GD3 object
	end

	properties
		F % values of the signed distance function
	end

	methods

		function obj = SDF3(grid, Xm, Ym, Zm, Val)
			obj.GD3 = grid;
			obj.GPUInitialize;
			obj.F = Val;
		end

	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculus tool box : derivatives, curvature, Dirac_Delta function, Heaviside function
	properties
		Fx
		Fy
		Fz
		FGradMag % magnitude of (Fx,Fy,Fz)

		Fxx
		Fyy
		Fzz
		Fxy
		Fyz
		Fxz
		FLaplacian

		MeanCurvature
		GaussianCurvature

		Dirac_Delta
		Heaviside
	end


	methods
		% update the above properties
		setCalculusToolBox(obj)
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% GPU related properties and functions: 27 lines
	properties
		
		% parameter for GPU kernel
			ThreadBlockSize
			GridSize

		% kernel funcions object for ENORK2 reinitialization scheme
			% calculate grid step with modification near boundary
			ENORK2_boundary_correction 
			% calculate the numerical Hamiltonian for the Reinitalization equation
			ENORK2_reinitiliaztion_step 

		% kernel functions object for ENORK2 extend scheme
			ENORK2_upwind_normal % calculate upwind normals of the level set function
			ENORK2_boundary_interpolate % interpolate values at the boundary
			ENORK2_extend_step % calculate the extension step

		% kernel funcions object for ENORK2 surface redistance scheme
			% calculate the numerical Hamiltonian for the surface redistacne equation
			ENORK2_surface_redistance_step 

	end
	
	methods 
		GPUInitialize(obj)
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% utilities : reinitliazation, extend, surface_redistance
	methods
		ENORK2Reinitialization(obj,iteration)	
		NewC = ENORK2Extend(obj, C, iteration)
		NewAF = ENORK2CentralUpwindSurfaceRedistance(obj,AF,iteration)
	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% visualization methods : 86 lines
	methods 

		% plot a 3D field on the val contour of the distance function
		function plotField(obj,val,Field)
			% triangle mesh of the val isosurface. 
			% TriMesh is a structure with fields "vertices" and "faces"
			TriMesh = isosurface(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,obj.F,val);
			% interpolate the values of the Field onto the vertices of the triangle mesh
			SurfField = interp3(obj.GD3.X, obj.GD3.Y, obj.GD3.Z, Field, ...
				TriMesh.vertices(:,1), TriMesh.vertices(:,2), TriMesh.vertices(:,3), 'linear');
			% plot surface mesh 
			patch('Vertices',TriMesh.vertices,'Faces',TriMesh.faces, ...
				  'FaceVertexCData',SurfField,'FaceColor','interp','EdgeColor','none')
			axis equal
			patch('Vertices',TriMesh.vertices,'Faces',TriMesh.faces,'FaceVertexCData',SurfField,...
				'FaceColor','interp','EdgeColor','none')
			axis equal
			view(45,30)
			colorbar
		end

		% plot several half contours of the distance function
		function plot(obj)
			axis(obj.GD3.BOX)
			obj.plotIso(-12*obj.GD3.Dx,0.8,'Red')
			obj.plotIso(-6*obj.GD3.Dx,0.8,'Green')
			obj.plotIso(0,0.8,'Blue')
			obj.plotIso(6*obj.GD3.Dx,0.8,'Green')
			obj.plotIso(12*obj.GD3.Dx,0.8,'Red')
			daspect([1 1 1])
			view(3); 
			camlight; lighting gouraud
		end

		% plot half of the val contour of the distance function
		function plotIso(obj,val,trans,Color)
			F = obj.F;
			F(obj.GD3.Y<0) = inf;
			surf1 = isosurface(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,F,val);
			p1 = patch(surf1);
			isonormals(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,F,p1)
			set(p1,'FaceColor',Color,'EdgeColor','none','FaceAlpha',trans);
		end

		% plot the val contour of the distance function
		function plotSurface(obj,val,trans,Color, time)
			F = obj.F;
			surf1 = isosurface(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,F,val);
			p1 = patch(surf1);
			isonormals(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,F,p1)
			set(p1,'FaceColor',Color,'EdgeColor','none','FaceAlpha',trans);
			axis(obj.GD3.BOX)
			daspect([1 1 1])
			view(3); 
			camlight; lighting gouraud
		end

		% plot the val contour of the field (not the level set function)
		function plotSurfaceField(obj,F,val,trans,Color)
			surf1 = isosurface(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,F,val);
			p1 = patch(surf1);
			isonormals(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,F,p1)
			set(p1,'FaceColor',Color,'EdgeColor','none','FaceAlpha',trans);
			axis(obj.GD3.BOX)
			daspect([1 1 1])
			view(3); 
			camlight; lighting gouraud
		end

		% plot the val contour of the field within the surface (designed for the auxilary level
	 	% set function
		[x,y,z]=CrossingLine(obj,iso,field, faces, verts, colors) % defined elsewhere
		function plotIsoField(obj, iso, field)
			[faces,verts,colors] = isosurface(obj.GD3.X,obj.GD3.Y,obj.GD3.Z,obj.F,0,field);
			obj.plotSurface(0,1,'Green',1);
			[x,y,z] = obj.CrossingLine(0,field,faces,verts,colors);
			line(x(:),y(:),z(:),'Color','red','LineWidth',3);
			len = length(iso);
			for i=1:len
				[x,y,z] = obj.CrossingLine(iso(i),field,faces,verts,colors);
				line(x(:),y(:),z(:),'Color','black','LineWidth',2);
			end
		end

	end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
