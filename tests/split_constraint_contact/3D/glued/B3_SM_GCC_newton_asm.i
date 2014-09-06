[Preconditioning]
 [./SMP]
 type = SMP
 full = true
 [../]
[]

[Mesh]
  type = FileMesh
  file = B3_tet.e
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]
  # Variables
  [./disp_x]
    order = FIRST
    family = LAGRANGE
  [../]
  [./disp_y]
    order = FIRST
    family = LAGRANGE
  [../]
  [./disp_z]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[AuxVariables]
  # AuxVariables
  [./penetration]
    order = FIRST
    family = LAGRANGE
  [../]
[]

[SolidMechanics]
  [./solid]
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
  [../]
[]

[Materials]
  # Materials
  [./elastic]
    type = Elastic
    block = '1 2'
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
    youngs_modulus = 6.67e5
    poissons_ratio = 0.3333
    formulation = linear
  [../]
[]


[AuxKernels]
  [./penetration]
    type = PenetrationAux
    variable = penetration
    boundary = 1
    paired_boundary = 5
  [../]
[]

[Constraints]
  [./contact_x]
    type = GluedContactConstraint
    variable = disp_x
    master_variable = disp_x
    component = 0
    boundary = 5
    slave = 1
    master = 5
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
    penalty = 1e6
    nodal_area = penetration
  [../]
  [./contact_y]
    type = GluedContactConstraint
    variable = disp_y
    master_variable = disp_y
    component = 0
    boundary = 5
    slave = 1
    master = 5
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
    penalty = 1e6
    nodal_area = penetration
  [../]
  [./contact_z]
    type = GluedContactConstraint
    variable = disp_z
    master_variable = disp_z
    component = 0
    boundary = 5
    slave = 1
    master = 5
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
    penalty = 1e6
    nodal_area = penetration
  [../]

[]

[BCs]
  # BCs
  [./left_anchor_x]
    type = DirichletBC
    variable = disp_x
    boundary = '2'
    value = 0.0
  [../]
  [./left_anchor_y]
    type = DirichletBC
    variable = disp_y
    boundary = '2'
    value = 0.0
  [../]
  [./left_anchor_z]
    type = DirichletBC
    variable = disp_z
    boundary = '2'
    value = 0.0
  [../]
  [./right_squeeze_x]
    type = DirichletBC
    variable = disp_x
    boundary = 6
    value = -0.0001
  [../]
  [./right_squeeze_y]
    type = DirichletBC
    variable = disp_y
    boundary = 6
    value = 0.0
  [../]
  [./right_squeeze_z]
    type = DirichletBC
    variable = disp_z
    boundary = 6
    value = 0.0
  [../]
  [./top_bottom_lamination_z]
    type = DirichletBC
    variable = disp_z
    boundary = '4 8'
    value = 0.0
  [../]
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options = '-snes_view -snes_monitor -ksp_monitor'
  petsc_options_iname = '-ksp_rtol -ksp_pc_side -pc_type -pc_asm_overlap -sub_pc_type -snes_linesearch_type'
  petsc_options_value = '    1e-8         right      asm               5           lu                 basic'
  line_search = none
  nl_abs_tol = 1e-8
  l_max_its = 100
  nl_max_its = 20
  dt = 1.0
  num_steps = 1
[]



[Postprocessors]
  [./_dt]
    # time step
    type = TimestepSize
  [../]
  [./nonlinear_its]
    # number of nonlinear iterations at each timestep
    type = NumNonlinearIterations
  [../]
  [./num_linear_its]
    type = NumLinearIterations
  [../]
[]

[Outputs]
  # Output
  interval = 1
  output_initial = true
  [./exodus]
    type = Exodus
    elemental_as_nodal = true
  [../]
  [./console]
    type = Console
    perf_log = true
    max_rows = 25
  [../]
  csv = true
[]

