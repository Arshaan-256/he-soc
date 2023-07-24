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
  		git submodule update --init --recursive
		```
	
	2. Install Verilator Simulation Flow (this is from [CVA6](https://github.com/AlSaqr-platform/cva6))
		1. Setup install directory RISCV environment variable i.e. export `RISCV=/YOUR/TOOLCHAIN/INSTALLATION/DIRECTORY`.
		2. Run `./ci/setup.sh` to install all required tools (i.e. verilator, device-tree-compiler, riscv64-unknown-elf-*, ..)
		
	You can install verilator from source using `./ci/install-verilator.sh` or by manually installing `verilator >= 4.002` Note: There is currently a known issue with version 4.106 and 4.108. 4.106 does not compile and 4.108 hangs after a couple of cycles simulation time.)

	3. Build model and simulation
		1. Build the Verilator model of CVA6 by using the Makefile:
			```
			make verilate
			make build
			```
		2. Copy the `work-dpi` folder that is created in the main folder of the CVA6 repo to `he-soc/hardware` 

	Now, you can run the simulation.

8. **Testing on the board**

	To generate the bitstream go to the `hardware` folder and run the following commands:
	```
	bender update
	make simple-padframe=1 scripts-bender-fpga-ddr exclude-cluster=1
	```
	
	Then enter `fpga` folder and run `source setup.sh`.
	
	The settings you need to use for `source setup.sh` are:
	1. VCU 118,
	2. Yes, instantiate the LLC,
	3. DDR4,
	4. Yes, validate the peripherals.
	
	Once done, you need to run the following:
	```
	make ips
	make clean run
	```
	
	**Debugging**
	1. **Error**: It is possible that you get an error: `vivado-2018.2 not found. No such command.` 
	   
	   **Fix:** 
	   1. Go to the `Makefile` in `./alsaqr/tcl/ips/*`. There are multiple ips here: boot_rom, clk_mngr, etc. and you need to do this for all of them.  
	   2. Update the `vivado-2018.2 vivado` command in both rules `all` and `gui` with the command that works for your system. If you are using the VM, then should replace `vivado-2018.2 vivado -mode batch -source run.tcl` with `vivado -mode batch -source run.tcl` (and the same for the `gui` rule).
	
	2. **Error** When you run `make clean all` and get an error for `IP not found` in the Vivado GUI.
	   
	   **Fix:** 
	   1. Go to `Reports` in the Menu Bar. 
	   2. Select `Report IP status`.
	   3. Vivado will open a window in the bottom menu, click on `Upgrade Selected` as shown below:
	      ![image](https://github.com/Arshaan-256/he-soc/assets/30975751/4bce108c-687c-4f2e-bc60-0d56c9402f82)
	     This should fix the issue. You can run `Generate Bitstream` again.
