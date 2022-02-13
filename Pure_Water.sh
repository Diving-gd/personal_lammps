###Overall Simulation Parameters###

clear			#Deletes all atoms, restores all settings to their default values, and frees all memory allocated by LAMMPS
echo both		#Output code to both log file and terminal screen
units	real		#Units are of metal style (distance=Angstrom, time=femtosecond, energy=Kcal/mole, temperature=K, pressure=atmospheres)
atom_style	full	#Atoms have charge as well a molecular attributes (i.e bonds, angles, dihedrals and impropers)
boundary p p p		#periodic boundary conditions in the y direction while fixed and nonperiodic in the x and z directions

dimension 3		#Create a 3-dimensional simulation


###Pair Style###
pair_style lj/cut/coul/long 10 10	#lj/cut/coul/long is used for the Oxygen to Oxygen, Hydrogen to Hydrogen and Oxygen to Hydrogen atom interactions 


###Long-range Columbic Solver###
kspace_style pppm 1.0e-6


#Bond Parameters
bond_style harmonic			#Harmonic bond style

#Angle Parameters
angle_style harmonic		#Harmonic angle style

###Placing water into simulation###

read_data LiqWatSPCE40500.SPCE 

#Water
pair_coeff  2 2 0.1553 3.166
pair_coeff  1 1 0.0000 0.0000
pair_coeff  1 2 0.0000 0.0000


###Putting atoms into groups###

group	Hydrogen 	type 1						#Create a group called Hydrogen and fill it with type 1 atoms
group	Oxygen   	type 2						#Create a group called Oxygen and fill it with type 2 atoms
group   Water 		union Hydrogen Oxygen		#Create a group called Water that is the union of the groups hydrogen and oxygen


neigh_modify every 1 delay 0 check yes one 5000 page 500000	#Build neighbor list every timestep 
					#do not delay by any timesteps and check if an atom has 
					#moved more than half the skin distance

###Simulation Initializations###

timestep 1			#Have a simulation time step of 1 femtosecond
neighbor 2.0 bin	#Have a skin distance of 2 Angstroms and sort the atoms by binning





###Post-Processing###
compute TWat Water temp
fix TempWater Water ave/time 100 10 1000 c_TWat file Average_Temperature_Water.sh

compute PWat all pressure TWat
fix PressWater all ave/time 100 10 1000 c_PWat file Average_Pressure_Water.sh

compute KEWat Water ke
fix KEWater Water ave/time 100 10 1000 c_KEWat file Average_KE_Water.sh

compute PEWat all pe
fix PEWater all ave/time 100 10 1000 c_PEWat file Average_PE_Water.sh

variable Tot_Volume equal vol
fix SystemVolume all ave/time 100 10 1000 v_Tot_Volume file Average_Volume_System.sh

variable Tot_Density equal density
fix SystemDensity all ave/time 100 10 1000 v_Tot_Density file Average_Density_System.sh

variable Tot_Enthalpy equal enthalpy
fix SystemEnthalpy all ave/time 100 10 1000 v_Tot_Enthalpy file Average_Enthalpy_System.sh

variable Tot_KineticE equal ke
fix KineticE all ave/time 100 10 1000 v_Tot_KineticE file Average_KE_from_thermo_output.sh

variable Tot_PotentialE equal pe
fix Potential all ave/time 100 10 1000 v_Tot_PotentialE file Average_PE_from_thermo_output.sh

#dump test all atom 1 System.lammpstrj	#Create a dump command called test that affects all groups 
					#and stores atom information in a file called System.lammpstrj



atom_modify sort 1 2	#Sort atoms spacially every timestep for a bin size of 2 Angstrom


thermo_style custom step temp ke pe etotal press enthalpy vol density	#Calculate timestep, temperature, kinetic energy, potential energy, 
                                                                        #total energy, pressure, enthalpy, volume and density
thermo_modify lost ignore lost/bond ignore flush yes #make thermodynamic output to file current								

thermo 1000		#Print thermodynamic information every 1000 timesteps

atom_modify sort 1 2	#Sort atoms spacially every timestep for a bin size of 2 Angstrom

restart 10000 Pure_W_SPCE_40500_373K.restart



velocity Water create 298.15 12345 loop local

fix constrain Water shake 1.0e-6 100 0 b 1 a 1
#fix_modify constrain virial yes
run 0
velocity Water scale 298.15


###System Temperature Equilibration###

unfix constrain
 #Create a fix called constrain that effects the atoms in the water group that, employs the SHAKE algorithm 						  
											   #has a solution tolerance of 1e-5, has a value of 100 as the maximum number of iterations to find a solution,
											   #Never Prints the SHAKE statistics every 1000 time steps, utilizes one bond type and one angle type
													
fix 1 Water nve #temp 298.15 373.15 100	#create a fix called 1 that effects the atoms in the Water group with a canonical ensemble thermostat
								#have the temperature start at 50K and end at 373.150K with a damping parameter of 1 picosecond 

fix 2 Water langevin 298.15 373.0 100 456 zero yes
fix constrain Water shake 1.0e-6 100 0 b 1 a 1
#fix_modify constrain virial yes
run 100000

unfix constrain
unfix 1
unfix 2

 #Create a fix called constrain that effects the atoms in the water group that, employs the SHAKE algorithm 						  
											   #has a solution tolerance of 1e-5, has a value of 100 as the maximum number of iterations to find a solution,
											   #Never Prints the SHAKE statistics every 1000 time steps, utilizes one bond type and one angle type

fix 1 Water nve
fix 2 Water langevin 373.0 373.0 100 456 zero yes
fix constrain Water shake 1.0e-6 100 0 b 1 a 1
#fix_modify constrain virial yes
run 100000

unfix constrain
unfix 1
unfix 2

fix constrain Water shake 1.0e-6 100 0 b 1 a 1
#fix_modify constrain virial yes
													
fix 1 Water npt temp 373.0 373.0 100 iso 1 1 1000	#create a fix called 1 that effects the atoms in the Water group with a canonical ensemble thermostat
#fix_modify 1 energy no										#have the temperature start at 373.25K and end at 373.150K with a damping parameter of 1 picosecond 

run 140000


