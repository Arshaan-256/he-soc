# he-soc
# 1.0 Setting up the project
1. Clone this repository. 

2. Update the `setup.sh` to point to your toolchain installation paths.

3. Run the following comamnds inside `he-soc`. 
	```
	 git clone https://github.com/AlSaqr-platform/cva6.git
	 git submodule update --init --recursive
	```
	To compile the code:
	```	 
	 source setup.sh
	 cd software/hello
	 make clean all
	```
	 
4. Before building the RTL using Bender, copy the contents of the vip folder (you can find this folder in the original he-soc repo in the VM) to the following path: `he-soc/hardware/tb/vip`.

5. Build the RTL  by running the following commands. Make sure, for simulation, to add the `localjtag=1` and `preload=1` flag to the `make scripts_vip` command.
	```
		make update
		make scripts_vip
	```
	
6. Compile the code.
	```
		cd ../software/hello/
		make clean all
	```

7. **Running simulation**
	1. Go into the CVA6 folder at `he-soc/cva6` and run the following commands:
		```
		git clone https://github.com/AlSaqr-platform/cva6.git
		```
	
	2. Install Verilator Simulation Flow (this is from [CVA6](https://github.com/AlSaqr-platform/cva6))
		1. Setup install directory RISCV environment variable i.e. export `RISCV=/YOUR/TOOLCHAIN/INSTALLATION/DIRECTORY`.
		2. Run `./ci/setup.sh` to install all required tools (i.e. verilator, device-tree-compiler, riscv64-unknown-elf-*, ..)
		
	You can install verilator from source using `./ci/install-verilator.sh` or by manually installing `verilator >= 4.002` Note: There is currently a known issue with version 4.106 and 4.108. 4.106 does not compile and 4.108 hangs after a couple of cycles simulation time.)
	```
		git clone https://github.com/AlSaqr-platform/cva6.git
	```
	3. Build model and simulation
		1. Build the Verilator model of CVA6 by using the Makefile:
			```
			make verilate
			make build
			```
		2. Copy the `work-dpi` folder that is created in the main folder of the CVA6 repo to `he-soc/hardware` 

	Now, you can run the simulation.

8. **Testing on the board**

	To generate the bitstream go to `he-soc/hardware/fpga` and follow the steps in the README.md there. But it is possible that you might get an error: `vivado-2018.2 not found. No such command.`
	
	In that case, go to the `Makefile` in `./alsaqr/tcl/ips/*` (there are multiple ips here: boot_rom, clk_mngr, etc. and you need to do this for all of them). Update the `vivado-2018.2 vivado -mode gui -source run.tcl &` with the command that works for your system. So, what I did was simply: `vivado -mode gui -source run.tcl &`.
