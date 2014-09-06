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

[TensorMechanics]
  [./solid]
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
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
    type = MechanicalContactConstraint
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
    model = glued
  [../]
  [./contact_y]
    type = MechanicalContactConstraint
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
    model = glued
  [../]
  [./contact_z]
    type = MechanicalContactConstraint
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
    model = glued
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

[Materials]
  # Materials
  [./linear_elastic]
    type = LinearElasticMaterial
    block = '1 2'
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z

    all_21 = false
    # reading   C_11  C_12  C_13  C_22  C_23  C_33  C_44  C_55  C_66
    # Tetragonal
    #C_ijkl ='1.0e6 0.5e6 0.5e6 1.0e6 0.5e6 6.0e6 0.5e6 0.5e6 1.5e6'
    # Cubic
    C_ijkl ='1.0e6 0.5e6 0.5e6 1.0e6 0.5e6 1.0e6 0.5e6 0.5e6 0.5e6'
    # Isotropic
    # C_ijkl ='1.0e6 0.5e6 0.5e6 1.0e6 0.5e6 1.0e6 0.25e6 0.25e6 0.25e6'
    # Elk original example
    #C_ijkl ='1.0e6 0.0e6 0.0e6 1.0e6 0.0e6 1.0e6 0.5e6 0.5e6 0.5e6'
    # This is a test Cijkl entry to use with all_21 = true
    #C_ijkl ='11.0 12.0 13.0 14.0 15.0 16.0 22.0 23.0 24.0 25.0 26.0 33.0 34.0 35.0 36.0 44.0 45.0 46.0 55.0 56.0 66.0'

    euler_angle_1 = 0.0
    euler_angle_2 = 0.0
    euler_angle_3 = 0.0
  [../]
[]



[Executioner]
  type = Transient
  solve_type = PJFNK
  petsc_options = '-snes_view -snes_monitor -ksp_monitor'
  petsc_options_iname = '-ksp_rtol'
  petsc_options_value = '     1e-8'
  splitting = 'contact_interior'
  line_search = none
  nl_abs_tol = 1e-8
  l_max_its = 100
  nl_max_its = 20
  dt = 1.0
  num_steps = 1
[]
# Splits are inactive unless Executioner has splitting = 'contact_interior'
[Splits]
  [./contact_interior]
    splitting          = 'contact interior'
    splitting_type     = schur
    schur_type         = full
    schur_pre          = Sp
  [../]
  [./contact]
    type = ContactSplit
    contact_master   = '5'
    contact_slave    = '1'
    contact_displaced = 'true'
    petsc_options = '-dm_view -dm_moose_print_embedding'
    #petsc_options = '-ksp_monitor'
    petsc_options_iname = '-ksp_type -pc_type -sub_pc_type'
    petsc_options_value = '    gmres      asm           lu'
  [../]
  [./interior]
    type = ContactSplit
    uncontact_master   = '5'
    uncontact_slave    = '1'
    uncontact_displaced = 'true'
    petsc_options = '-dm_view -ksp_monitor'
    petsc_options_iname = '-pc_type -pc_asm_overlap -sub_pc_type'
    petsc_options_value = '     asm               5           lu'
  [../]
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


