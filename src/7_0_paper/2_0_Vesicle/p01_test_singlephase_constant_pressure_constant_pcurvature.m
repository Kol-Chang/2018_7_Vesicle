% simulate single phase vesicle with constant pressure

% prolate --> tube
 TYPE="p"; ratio = 0.2; rd = 0.75;PresetP = -2000; GridSize = [64,64,96]; ConserveRAD = false; PresetTDA = 0; iteration = 300; SampleRate = 3;

% prolate --> pear --> pear pinching
%TYPE="p"; ratio = 0.35; rd = 0.75; PresetP = 700; GridSize = [64,64,64]; ConserveRAD = true;

%TYPE = "p"; ratio = 0.35; rd = 0.75; PresetP = 500; GridSize = [64,64,64];

% oblate --> sphere
%TYPE="o";ratio=0.25; rd = 0.75; PresetP = -100; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 50;

% oblate --> torus
%TYPE="o";ratio=0.25; rd = 0.75; PresetP = -1000; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 13; iteration = 300; SampleRate = 3;

% oblate --> prolate --> dumbell --> tube
% TYPE="o";ratio=0.25; rd = 0.75; PresetP = -200; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 10;
%TYPE="o";ratio=0.25; rd = 0.75; PresetP = -300; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 13;

% oblate --> four leg starfish
% TYPE="o";ratio=0.25; rd = 0.75; PresetP = -200; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 20; iteration = 400; SampleRate = 4;

% oblate --> three leg starfish
% TYPE="o";ratio=0.25; rd = 0.75; PresetP = -200; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 12; iteration = 700; SampleRate = 7;
%TYPE="o";ratio=0.25; rd = 0.75; PresetP = -200; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = 15;

%TYPE="o";ratio=0.25; rd = 0.99; PresetP = -300; GridSize = [64,64,64]; ConserveRAD = false; PresetTDA = -50;

iteration = 3000; SampleRate = 20;

[x,y,z,f] = SD.Shape.Ellipsoid(GridSize,rd,TYPE,ratio);
grid = SD.GD3(x,y,z);
map = SD.SDF3(grid,x,y,z,f);

map.setDistance
map.F = map.WENO5RK3Reinitialization(map.F,100);
map.GPUsetCalculusToolBox

InitialArea = map.calArea;
EquivalentRadius = sqrt(InitialArea/(4*pi));

InitialVolume = map.calVolume;
ReducedVolume = (3*InitialVolume/4/pi) * (4*pi/InitialArea)^(3/2);

MeanCurvature = map.WENORK3Extend(map.MeanCurvature,100);
InitialAreaDifference = map.surfaceIntegral(MeanCurvature);
InitialReducedAreaDifference = - InitialAreaDifference/(8*pi*EquivalentRadius);

fprintf('area: %4.5f, volume: %4.5f, rv: %4.5f, rad: %4.5f\n', InitialArea, InitialVolume, ReducedVolume, InitialReducedAreaDifference)

FIG = figure('Name','Single Vesicle','Position',[10 10 1600 800])

textX = gather(map.GD3.xmin);
textY = gather( (map.GD3.ymax + map.GD3.ymin)/2 );
textZ = gather(map.GD3.zmin);

KappaB = 1.0; % bending rigidity
CFLNumber = .2;
filterWidth = gather(map.GD3.Ds)*5.0;

time = 0;
array_ene = [];
array_t = [];
for i = 0:iteration
	map.GPUsetCalculusToolBox

	z_shift = - (map.Box(5) + map.Box(6));
	y_shift = - (map.Box(3) + map.Box(4));
	x_shift = - (map.Box(1) + map.Box(2));

	% calculate geometry constraints
	CurrentArea = map.calArea;
	DiffArea = 100 * (CurrentArea - InitialArea)/InitialArea;
	CurrentVolume = map.calVolume;
	DiffVolume = 100 * (CurrentVolume - InitialVolume) / InitialVolume;
	
	ReducedVolume = 100 * (3*CurrentVolume/4/pi) * (4*pi/CurrentArea)^(3/2);

	map.MeanCurvature = map.WENORK3Extend(map.MeanCurvature,100);
	map.GaussianCurvature = map.WENORK3Extend(map.GaussianCurvature,100);
	MeanCurvature = map.MeanCurvature;
	GaussianCurvature = map.GaussianCurvature;
	CurrentAreaDifference = map.surfaceIntegral(MeanCurvature);
	CurrentReducedAreaDifference = - CurrentAreaDifference / (8*pi*EquivalentRadius); 

	% calculate bending forces
	MeanCurvatureSurfaceLaplacian = map.GD3.Laplacian(map.MeanCurvature); 
	MeanCurvatureSurfaceLaplacian = map.ENORK2Extend(MeanCurvatureSurfaceLaplacian,100);
	NormalSpeedBend = KappaB * (MeanCurvatureSurfaceLaplacian + ...
			0.5 * MeanCurvature.^3 - 2.0 * MeanCurvature .* GaussianCurvature);

	mask = abs(map.F)<2*map.GD3.Ds;
	MaxSpeedBend = max(abs(NormalSpeedBend(mask)));

	Dt = CFLNumber * map.GD3.Ds / MaxSpeedBend;
	time = time + Dt;

	% now solve for Lagrange multipliers
	c11 = InitialArea;
	c12 = CurrentAreaDifference; c21 = c12;
	c13 = map.surfaceIntegral(GaussianCurvature); c31 = c13;
	c22 = map.surfaceIntegral(MeanCurvature.^2);
	c23 = map.surfaceIntegral(MeanCurvature.*GaussianCurvature); c32 = c23;
	c33 = map.surfaceIntegral(GaussianCurvature.^2);

	volumeChangeRate = (InitialVolume - CurrentVolume) / Dt;
	areaChangeRate = (InitialArea - CurrentArea) / Dt;
	areaDifferenceChangeRate = (InitialAreaDifference - CurrentAreaDifference) / (2*Dt);

	s1 = volumeChangeRate + map.surfaceIntegral(NormalSpeedBend);
	s2 = - areaChangeRate + map.surfaceIntegral(NormalSpeedBend.*MeanCurvature);
	s3 = - areaDifferenceChangeRate + map.surfaceIntegral(NormalSpeedBend.*GaussianCurvature);

	% conserve volume, area and area difference
	%PTA = [c11,c12,c13;c21,c22,c23;c31,c32,c33] \ [s1;s2;s3];
	%Pressure = PTA(1); Tension = PTA(2); TensionDA = PTA(3);


	if ConserveRAD
		% conserve area and area difference, set volume to be constant
		Pressure = PresetP;
		TA = [c22,c23;c32,c33] \ [s2-Pressure*c21; s3-Pressure*c31];
		Tension = TA(1); TensionDA = TA(2);
	else
		% conserve only area, set pressure to be constant
		Pressure = PresetP; TensionDA =  PresetTDA;
		Tension = (s2 - Pressure*c21 - TensionDA*c23) / c22; 
	end


	% now calculate normal speed
	normalSpeed = Tension .* MeanCurvature + Pressure + ...
				TensionDA .* GaussianCurvature - NormalSpeedBend;

	% time step the level set function
	%normalSpeedSmoothed = smoothGMRES(map, normalSpeed.*map.FGradMag, Dt, 0.5);
	normalSpeedSmoothed = map.GD3.smoothFFT(normalSpeed.*map.FGradMag, Dt, 0.5);
	normalSpeedSmoothed = map.ENORK2Extend(normalSpeedSmoothed, 100);
	map.F = map.F - Dt * normalSpeedSmoothed;
	map.setDistance
	
	ene = KappaB * c22 - Pressure * CurrentVolume;
	%ene = KappaB * c22;
	array_ene = [array_ene; ene];
	array_t = [array_t time];

	fprintf('iter: %5d, ene: %4.5f, ar: %+4.5f, vol: %+4.5f, rd: %4.5f, rad: %+4.5f\n', i, ene, DiffArea, DiffVolume, ReducedVolume, CurrentReducedAreaDifference)

	if mod(i,SampleRate)==0 || i==2
		clf(FIG)

		subplot(2,2,[1,3])
		titlestr1 = [ sprintf('rd:%.2f,rad:%.2f,gr:(%d,%d,%d) \n P:%.2f,T:%.2f,TA:%.2f', ReducedVolume, CurrentReducedAreaDifference,GridSize(1),GridSize(2),GridSize(3),Pressure,Tension,TensionDA ) ];
		title(titlestr1)
		map.plotSurface(0,1,'green','none');
		%map.plotField(0,normalSpeedSmoothed,0.5)
		%map.plotField(0,map.AHeaviside,0.01)
		%map.plotField(0,Tension,0.01)
		map.GD3.DrawBox

		xticks([map.GD3.BOX(1),0,map.GD3.BOX(2)])
		yticks([map.GD3.BOX(3),0,map.GD3.BOX(4)])
		zticks([map.GD3.BOX(5),0,map.GD3.BOX(6)])

		axis vis3d equal
		set(gca,'Color','k')

		zoom(1.0)

		subplot(2,2,2)
		xslice = ceil(map.GD3.ncols / 2);
		Fslice = reshape(map.F(:,xslice,:), [map.GD3.mrows,map.GD3.lshts]);
		Y = reshape(map.GD3.Y(:,xslice,:), [map.GD3.mrows,map.GD3.lshts]);
		Z = reshape(map.GD3.Z(:,xslice,:), [map.GD3.mrows,map.GD3.lshts]);
		contour(Y,Z,Fslice,[0,0],'blue','LineWidth',3)
		axis equal
		titlestr2 = [ sprintf('shift:(%.2f,%.2f,%.2f)',y_shift,x_shift,z_shift ) ];
		title(titlestr2)

		subplot(2,2,4)
		area( array_t, array_ene )
		titlestr3 = [ sprintf('iter: %5d,ene: %5.5f', i,ene ) ];
		title(titlestr3)

		drawnow
	end

	if mod(i,10)==0
		map.F = circshift(map.F, [sign(y_shift),sign(x_shift),sign(z_shift)]);
		map.setDistance
		map.F = map.WENO5RK3Reinitialization(map.F,200);
	end

end

