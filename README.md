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
 	cd hardware
	make update
	make scripts_vip preload=1 localjtag=1
	```
	
6. Compile the code.
	```
	cd ../software/hello/
	make clean all
	```

## 7a. Running simulation

1. Go into the CVA6 folder at `he-soc/cva6` and run the following commands:
    ```
    git submodule update --init --recursive
    ```
	
2. Install Verilator Simulation Flow (this is from [r/cva6](https://github.com/AlSaqr-platform/cva6))
		
    1. Setup install directory RISCV environment variable i.e. export `RISCV=/YOUR/TOOLCHAIN/INSTALLATION/DIRECTORY`.
		
    2. Run `./ci/setup.sh` to install all required tools (i.e. verilator, device-tree-compiler, riscv64-unknown-elf-*, ..)
		
	You can install verilator from source using `./ci/install-verilator.sh` or by manually installing `verilator >= 4.002`. Note: There is currently a known issue with version 4.106 and 4.108. 4.106 does not compile and 4.108 hangs after a couple of cycles simulation time.)

3. Build model and simulation

	1. Build the Verilator model of CVA6 by using the Makefile:
		```
		make verilate
		make build
		```
	2. Copy the `work-dpi` folder that is created in the main folder of the CVA6 repo to `he-soc/hardware` 

	Now, you can run the simulation.

### **Debugging**
	
1. **Error** `Failed to open design unit file "./he-soc/hardware/tb/vip/hyperflash_model/s26ks512s.v" in read mode.`

Make sure you have imported the verification IPs (VIPs) to the correct location (Step 4). Sometimes this error persists despite this but in that case, the simulation should still run.
   	   
2. **Error** `pmc_op_e`-like defines not found for **Advanced Performance Monitoring Unit** (This is the RISC-V implementation of the APMU design specification.) 

    Yeah, this is a pretty annoying bug but it exists only for **SIMULATION**. The problem is that there are two copies of Ibex modules (except for `ibex_pmu_counter.sv` which does not exist in vanilla version):

    1. One is due to the APMU, as we are using a modified version of the Ibex core for the APMU: [r/ibex](https://github.com/Arshaan-256/ibex/tree/alsaqr-dev), the `alsaqr-dev` branch, maintained by the `u/Arshaan-256`. This module has been added as a dependency in the `Bender.yml` file of the APMU. The top core module in this branch of the repository is called `ibex_pmu_core`.
    
        Example: `ibex_pmu: { git: "git@github.com:Arshaan-256/ibex.git", version: 0.4.2 }`

    2. The second one is because of the base `he-soc` repo which also clones the standard Ibex GitHub repository using `bender`. This one is maintained by `u/lowRISC`. The top module here is `ibex_core`. 
    
        I am guessing that one of the modules that `he-soc` clones has this vanilla Ibex repository as a dependency.

    The top modules have different names but the internal Ibex modules still share the same names. This causes problems with QuestaSim as it ends up focusing on the Ibex files from `u/lowRISC`, which do not have the necessary defines and signals that the APMU is expecting. Causing errors like no define found for `pmc_op_e`, etc.

    My **current fix** is to first run the command that generates the Tcl script that QuestaSim needs: `make scripts_vip preload=1 localjtag=1`. This command creates a `compile.tcl` file in the `he-soc/hardware` folder. Then open that file and remove the entire `if` block where they add the base `ibex_core`. Only keep the `ibex_pmu_core` block. There might be a smarter way to configure `bender` but I haven't had the time to do so. 
   
**Note:** Do not confuse it with the Tcl file with the one created in the `he-soc/hardware/fpga/alsaqr/tcl/generated` folder when running the synthesis command: `make simple-padframe=1 scripts-bender-fpga-ddr exclude-cluster=1`. That file is used by Vivado for synthesis, and I have not faced any such errors during synthesis.

## 7b. Testing on the board

To generate the bitstream go to the `hardware` folder and run the following commands:

	
	bender update
	make simple-padframe=1 scripts-bender-fpga-ddr exclude-cluster=1


Then enter `fpga` folder and run `source setup.sh`.

The settings you need to use for `source setup.sh` are:
1. VCU 118,
2. Yes, instantiate the LLC,
3. DDR4,
4. Yes, validate the peripherals.

Once done, you need to run the following:
	
	make ips
	make clean run
	
	
### **Debugging**
1. **Error** It is possible that you get an error: `vivado-2018.2 not found. No such command.` 
	   
    
    1. **Fix:** Go to the `Makefile` in `./alsaqr/tcl/ips/*`. There are multiple ips here: boot_rom, clk_mngr, etc. and you need to do this for all of them.  
    2. Update the `vivado-2018.2 vivado` command in both rules `all` and `gui` with the command that works for your system. If you are using the VM, then should replace `vivado-2018.2 vivado -mode batch -source run.tcl` with `vivado -mode batch -source run.tcl` (and the same for the `gui` rule).

2. **Error** When you run `make clean all` and get an error for `IP not found` in the Vivado GUI.
    1. **Fix:** Go to `Reports` in the Menu Bar. 
    2. Select `Report IP status`.
    3. Vivado will open a window in the bottom menu, click on `Upgrade Selected` as shown below:
      ![image](https://github.com/Arshaan-256/he-soc/assets/30975751/4bce108c-687c-4f2e-bc60-0d56c9402f82)
     This should fix the issue. You can run `Generate Bitstream` again.

3. **Error** `Failed to spawn child process. Too many open files (os error 24)` when running `make init`.
   1. To check what the current session's file descriptor limit is, run `ulimit -n`.
   2. Increase it, by running `ulimit -n 4096`.

## 8.**`gdb` Commands**
1. Connect to a new target: `target remote:3333` OR `target extended-remote:3333`.
2. To mask the SIGINT signal: `handle signal SIGINT noprint`, it works only with `extended-remote`.


# 1.1 Errors?
Steps 7.a and 7.b have sections on debugging, focussing on errors that I observed during simulation and synthesis, respectively.
