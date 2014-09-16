[Mesh]
  file = contact.e
  displacements = 'disp_x disp_y'
[]

[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
[]

[Functions]
  [./source]
  type = PiecewiseLinear
  x = '0 1'
  y = '0 0'
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
  [../]
[]

[AuxKernels]
  [./penetration]
    type = PenetrationAux
    variable = penetration
    boundary = 1
    paired_boundary = 7
  [../]
[]

[Materials]
  [./constant]
    type = LinearIsotropicMaterial
    block = '1 2'
    youngs_modulus = 1e6
    poissons_ratio = .3
    thermal_expansion = 1e-4
    t_ref = 200
    disp_x = disp_x
    disp_y = disp_y
  [../]
[]

#[Contact]
#  [./mechanical]
#    master = 1
#    slave = 7
#    disp_x = disp_x
#    disp_y = disp_y
#    penalty = 1e7
#    tangential_tolerance = 0.1
#    model = glued
#  #  system = constraint
#  [../]
#[]

[Constraints]
  [./contact_x]
    type = SparsityBasedGluedContactConstraint
    variable = disp_x
    master_variable = disp_x
    component = 0
    boundary = 7
    slave = 1
    master = 7
    disp_x = disp_x
    disp_y = disp_y
    penalty = 1e6
    nodal_area = penetration
  [../]
  [./contact_y]
    type = SparsityBasedGluedContactConstraint
    variable = disp_y
    master_variable = disp_y
    component = 1
    boundary = 7
    slave = 1
    master = 7
    disp_x = disp_x
    disp_y = disp_y
    penalty = 1e6
    nodal_area = penetration
  [../]
[]

[BCs]
  [./leftright_disp_x]
    type = DirichletBC
    variable = disp_x
    boundary = '4 2'
    value = 0
  [../]
  [./bottom_disp_y]
    type = DirichletBC
    variable = disp_y
    boundary = 3
    value = 0
  [../]

  [./disp_y_upper]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = '5'
    function = source
  [../]
  [./disp_x_upper]
    type = DirichletBC
    variable = disp_x
    boundary = '5 6 8'
    value = 0
  [../]
[]


[Preconditioning]
  [./full]
   type = SMP
   full = true
  [../]
[]


[Executioner]
  type = Transient

  #Preconditioned JFNK (default)
  solve_type = 'NEWTON'



  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
  dt = 0.005
  dtmin = 0.001
  #num_steps = 20
  end_time = 0.64

  nl_rel_tol = 1e-12
  nl_abs_tol = 1e-9

  l_max_its = 50
  nl_max_its = 20
[]

[Outputs]
  output_initial = true
  exodus = true
  [./console]
    type = Console
    perf_log = true
    linear_residuals = true
  [../]
[]

[Postprocessors]
  [./1_top_disp_y]
    type = NodalVariableValue
    variable = disp_y
    nodeid = 1
    use_displaced_mesh = true
  [../]
  [./2_bot_disp_y]
    type = NodalVariableValue
    variable = disp_y
    nodeid = 3
    use_displaced_mesh = true
  [../]
  [./3_lower_block_disp_y]
    type = NodalVariableValue
    variable = disp_y
    nodeid = 5
    use_displaced_mesh = true
  [../]
  [./time_step]
    type = TimestepSize
  [../]
[]
