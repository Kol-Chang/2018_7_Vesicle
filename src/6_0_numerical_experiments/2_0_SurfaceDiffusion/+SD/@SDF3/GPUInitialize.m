% initialize GPU functions
function GPUInitialize(obj)
	
	obj.ThreadBlockSize = [obj.GD3.mrows,ceil(512/obj.GD3.mrows),1];
	obj.GridSize = [ceil(obj.GD3.mrows/obj.ThreadBlockSize(1)), ...
					ceil(obj.GD3.ncols/obj.ThreadBlockSize(2)), ...
					ceil(obj.GD3.lshts/obj.ThreadBlockSize(3))];

	% functions used by reinitialization scheme and other schemes
	system('nvcc -ptx CUDA_Code/1_0_ENORK2_Reinitialization/boundary_correction.cu -o CUDA_Code/1_0_ENORK2_Reinitialization/boundary_correction.ptx');

	obj.ENORK2_boundary_correction = parallel.gpu.CUDAKernel('CUDA_Code/1_0_ENORK2_Reinitialization/boundary_correction.ptx', ...
															 'CUDA_Code/1_0_ENORK2_Reinitialization/boundary_correction.cu', ...
															 'boundary_correction');
	obj.ENORK2_boundary_correction.ThreadBlockSize = obj.ThreadBlockSize;
	obj.ENORK2_boundary_correction.GridSize = obj.GridSize;

	obj.ENORK2_reinitiliaztion_step = parallel.gpu.CUDAKernel('CUDA_Code/1_0_ENORK2_Reinitialization/boundary_correction.ptx', ...
															  'CUDA_Code/1_0_ENORK2_Reinitialization/boundary_correction.cu', ...
															  're_step');
	obj.ENORK2_reinitiliaztion_step.ThreadBlockSize = obj.ThreadBlockSize;
	obj.ENORK2_reinitiliaztion_step.GridSize = obj.GridSize;

	% function used by WENO reinitialization scheme
	system('nvcc -ptx CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.cu -o CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.ptx');

	obj.cubic_boundary_correction = parallel.gpu.CUDAKernel('CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.ptx', ...
															'CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.cu', ...
															'boundary_correction');
	obj.cubic_boundary_correction.ThreadBlockSize = obj.ThreadBlockSize;
	obj.cubic_boundary_correction.GridSize = obj.GridSize;

	obj.WENORK3_reinitialization_step = parallel.gpu.CUDAKernel('CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.ptx', ...
															    'CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.cu', ...
															    're_step');
	obj.WENORK3_reinitialization_step.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_reinitialization_step.GridSize = obj.GridSize;

	obj.WENORK3_re_step_kink = parallel.gpu.CUDAKernel('CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.ptx', ...
															    'CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.cu', ...
															    're_step_kink_stationary');
	obj.WENORK3_re_step_kink.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_re_step_kink.GridSize = obj.GridSize;

	obj.WENORK3_re_step_bo1 = parallel.gpu.CUDAKernel('CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.ptx', ...
															    'CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.cu', ...
															    're_step_bo1_stationary');
	obj.WENORK3_re_step_bo1.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_re_step_bo1.GridSize = obj.GridSize;

	obj.WENORK3_re_step_bo2 = parallel.gpu.CUDAKernel('CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.ptx', ...
															    'CUDA_Code/1_1_WENORK3_Reinitialization/weno_rk3_reinitialization.cu', ...
															    're_step_bo2_stationary');
	obj.WENORK3_re_step_bo2.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_re_step_bo2.GridSize = obj.GridSize;

	% functions used by the extend scheme and other schemes
	system('nvcc -ptx CUDA_Code/2_0_ENORK2_Extend/enork2_extend.cu -o CUDA_Code/2_0_ENORK2_Extend/enork2_extend.ptx');

	obj.ENORK2_upwind_normal = parallel.gpu.CUDAKernel('CUDA_Code/2_0_ENORK2_Extend/enork2_extend.ptx', ...
		   											   'CUDA_Code/2_0_ENORK2_Extend/enork2_extend.cu', ...
												   	   'upwind_normal');
	obj.ENORK2_upwind_normal.ThreadBlockSize = obj.ThreadBlockSize;
	obj.ENORK2_upwind_normal.GridSize = obj.GridSize;		

	obj.ENORK2_extend_step = parallel.gpu.CUDAKernel('CUDA_Code/2_0_ENORK2_Extend/enork2_extend.ptx', ...
		   											 'CUDA_Code/2_0_ENORK2_Extend/enork2_extend.cu', ...
												   	 'extend_step');
	obj.ENORK2_extend_step.ThreadBlockSize = obj.ThreadBlockSize;
	obj.ENORK2_extend_step.GridSize = obj.GridSize;		

	obj.ENORK2_boundary_interpolate = parallel.gpu.CUDAKernel('CUDA_Code/2_0_ENORK2_Extend/enork2_extend.ptx', ...
		   											 		  'CUDA_Code/2_0_ENORK2_Extend/enork2_extend.cu', ...
		          										   	  'boundary_interpolate');
	obj.ENORK2_boundary_interpolate.ThreadBlockSize = obj.ThreadBlockSize;
	obj.ENORK2_boundary_interpolate.GridSize = obj.GridSize;		

	% functions used by the WENO extend scheme and other schemes
	system('nvcc -ptx CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.cu -o CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.ptx');

	obj.WENORK3_upwind_normal = parallel.gpu.CUDAKernel('CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.ptx', ...
		   											    'CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.cu', ...
												   	    'upwind_normal');
	obj.WENORK3_upwind_normal.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_upwind_normal.GridSize = obj.GridSize;		

	obj.WENORK3_extend_step = parallel.gpu.CUDAKernel('CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.ptx', ...
		   											  'CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.cu', ...
												   	  'extend_step');
	obj.WENORK3_extend_step.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_extend_step.GridSize = obj.GridSize;		

	obj.WENORK3_boundary_interpolate = parallel.gpu.CUDAKernel('CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.ptx', ...
		   											 		   'CUDA_Code/2_1_WENORK3_Extend/wenork3_extend.cu', ...
		          										   	   'boundary_interpolate');
	obj.WENORK3_boundary_interpolate.ThreadBlockSize = obj.ThreadBlockSize;
	obj.WENORK3_boundary_interpolate.GridSize = obj.GridSize;		

	% functions used by GPUsetCalculusTooBox scheme
	system('nvcc -ptx CUDA_Code/4_0_Calculus_ToolBox/calculus_toolbox.cu -o CUDA_Code/4_0_Calculus_ToolBox/calculus_toolbox.ptx');

	obj.set_calculus_toolbox = parallel.gpu.CUDAKernel('CUDA_Code/4_0_Calculus_ToolBox/calculus_toolbox.ptx', ...
													   'CUDA_Code/4_0_Calculus_ToolBox/calculus_toolbox.cu', ...
													   'set_calculus_toolbox');
	obj.set_calculus_toolbox.ThreadBlockSize = obj.ThreadBlockSize;
	obj.set_calculus_toolbox.GridSize = obj.GridSize;

	obj.auxi_set_calculus_toolbox = parallel.gpu.CUDAKernel('CUDA_Code/4_0_Calculus_ToolBox/calculus_toolbox.ptx', ...
													   'CUDA_Code/4_0_Calculus_ToolBox/calculus_toolbox.cu', ...
													   'auxi_set_calculus_toolbox');
	obj.auxi_set_calculus_toolbox.ThreadBlockSize = obj.ThreadBlockSize;
	obj.auxi_set_calculus_toolbox.GridSize = obj.GridSize;

	% functions used for calculating weno derivatives
	system('nvcc -ptx CUDA_Code/5_0_Nonoscillating_Reconstruction/nonoscillating_interpolant.cu -o CUDA_Code/5_0_Nonoscillating_Reconstruction/nonoscillating_interpolant.ptx');

	obj.GD3.weno_derivative = parallel.gpu.CUDAKernel('CUDA_Code/5_0_Nonoscillating_Reconstruction/nonoscillating_interpolant.ptx', ...
												  'CUDA_Code/5_0_Nonoscillating_Reconstruction/nonoscillating_interpolant.cu', ...
												  'weno_derivative');
	obj.GD3.weno_derivative.ThreadBlockSize = obj.ThreadBlockSize;
	obj.GD3.weno_derivative.GridSize = obj.GridSize;
end








