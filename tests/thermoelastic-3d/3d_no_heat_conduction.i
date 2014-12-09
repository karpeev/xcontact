[GlobalParams]
  density = 10431.0
  disp_x = disp_x
  disp_y = disp_y
  disp_z = disp_z
  order = SECOND
  family = LAGRANGE
[]

[Mesh]
  file = 1pellet_nogap.e
  displacements = 'disp_x disp_y disp_z'
  partitioner = centroid
  centroid_partitioner_direction = y
  patch_size = 40
[]

[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
[]

[AuxVariables]
  [./temp]
    initial_condition = 298
  [../]
  [./stress_xx]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_zz]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./vonmises]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hoop_stress]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./hydrostatic_stress]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./pid]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[Functions]
  [./fuel_temp]
    type = PiecewiseLinear
    x = '0 10000'
    y = '298 800'
  [../]
  [./clad_temp]
    type = PiecewiseLinear
    x = '0 10000'
    y = '298 550'
  [../]
[]

[SolidMechanics]
  [./solid]
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
    temp = temp
  [../]
[]

[AuxKernels]
  [./fuel_temperature]
    type = FunctionAux
    variable = temp
    block = 2
    function = fuel_temp
  [../]
  [./clad_temperature]
    type = FunctionAux
    variable = temp
    block = 1
    function = clad_temp
  [../]


  [./stress_xx]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_xx
    index = 0
    execute_on = timestep
  [../]
  [./stress_yy]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_yy
    index = 1
    execute_on = timestep
  [../]
  [./stress_zz]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_zz
    index = 2
    execute_on = timestep
  [../]
  [./vonmises]
    type = MaterialTensorAux
    tensor = stress
    variable = vonmises
    quantity = vonmises
    execute_on = timestep
  [../]
  [./hoop_stress]
    type = MaterialTensorAux
    tensor = stress
    variable = hoop_stress
    quantity = hoop
    execute_on = timestep
  [../]
  [./hydrostatic_stress]
    type = MaterialTensorAux
    tensor = stress
    variable = hydrostatic_stress
    quantity = hydrostatic
    execute_on = residual
  [../]
  [./pid]
    type = ProcessorIDAux
    variable = pid
  [../]
[]

[Contact]
  [./pellet_clad_mechanical]
    master = 5
    slave = 10
#    penalty = 1e6
    model = frictionless
    tangential_tolerance = 5e-4
    normal_smoothing_distance = 0.1
    penalty = 1e+14 #1e7
    normalize_penalty = true
    system = Constraint
#    master_slave_jacobian = true
#    connected_slave_nodes_jacobian = false
#    non_displacement_variables_jacobian = false
  [../]
[]

[BCs]

  [./no_x_all]
    type = DirichletBC
    variable = disp_x
    boundary = '1001 1003'
    value = 0.0
  [../]

# pin entire clad bottom in y
  [./no_y_clad_bottom]
    type = DirichletBC
    variable = disp_y
#    boundary = 1001
    boundary = 1
    value = 0.0
  [../]

# pin fuel bottom in y
  [./no_y_fuel_bottom]
    type = DirichletBC
    variable = disp_y
    boundary = 1020
    value = 0.0
  [../]

# pin fuel axis in x and z
  [./no_x_fuel]
    type = DirichletBC
    variable = disp_x
    boundary = 1005
    value = 0.0
  [../]

# wedge bcs
  [./no_z_wedge]
    type = DirichletBC
    variable = disp_z
    boundary = '13 14'
    value = 0.0
  [../]
[]

[Materials]
  [./fuel_thermal]
    type = HeatConductionMaterial
    block = 2
    temp = temp
    thermal_conductivity = 3.0
    specific_heat = 320.0
  [../]

  [./fuel_solid_mechanics_elastic]
    type = Elastic
    block = 2
    temp = temp
    youngs_modulus = 2.e11
    poissons_ratio = 0.345
    thermal_expansion = 10.0e-6
  [../]

  [./clad_thermal]
    type = HeatConductionMaterial
    block = 1
    thermal_conductivity = 16.0
    specific_heat = 330.0
  [../]

  [./clad_solid_mechanics]
    type = Elastic
    block = 1
    temp = temp
    youngs_modulus = 7.5e10
    poissons_ratio = 0.3
    thermal_expansion = 5.0e-6
  [../]


  [./clad_density]
    type = Density
    block = 1
    density = 6551.0
  [../]

  [./fuel_density]
    type = Density
    block = 2
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
#    off_diag_row    = 'disp_x disp_x disp_y disp_y disp_z disp_z'
#    off_diag_column = 'disp_y disp_z disp_x disp_z disp_x disp_y'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'
#solve_type = 'NEWTON'

#  petsc_options = '-snes_view -snes_check_jacobian -snes_check_jacobian_view'
  petsc_options = '-snes_ksp_ew'
#  petsc_options = '-snes_linesearch_monitor'
#  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter -pc_hypre_strong_threshold'
#  petsc_options_value = '201                hypre    boomeramg      2                            0.7'

  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu       superlu_dist'
#  petsc_options_iname = '-pc_type'
#  petsc_options_value = 'lu'

  line_search = 'none'

  l_max_its = 25
  nl_max_its = 40
  nl_rel_tol = 1e-4
  nl_abs_tol = 1e-8
#  l_tol = 1e-2


  dtmax = 1.0e3
  dtmin = 1.0e3
  end_time = 1e4

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e3
    optimal_iterations = 300
    iteration_window = 4
  [../]

#  [./Predictor]
#    type = SimplePredictor
#    scale = 1.0
#  [../]

  [./Quadrature]
     order = fifth
     side_order = seventh
  [../]
[]

[Postprocessors]

  [./dt]
    type = TimestepSize
  [../]

  [./residual]
    type = Residual
  [../]

  [./nl_its]
    type = NumNonlinearIterations
  [../]

  [./lin_its]
    type = NumLinearIterations
  [../]

  [./alive_time]
    type = RunTime
    time_type = alive
  [../]

[]

[Outputs]
  csv = true
  interval = 1
  output_initial = true
  exodus = true
#  color = false

  [./console]
    type = Console
    perf_log = true
    linear_residuals = true
    max_rows = 25
  [../]
#  [./dofs]
#    type = DOFMap
#  [../]
#  [./checkpoints]
#    type = Checkpoint
#    num_files = 2
#    interval = 1
#  [../]
[]
