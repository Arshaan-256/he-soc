-------------------------------------------------------------------------------
--  File name : testbench_s25fs256s_verilog.vhd
-------------------------------------------------------------------------------
--  Copyright (C) 2013 Spansion, LLC.
--
--  MODIFICATION HISTORY :
--
--  version:   |     author:     |   mod date:  |  changes made:
--    V1.0          S.Petrovic      13 Jan 28     Initial release
--    V1.1          S.Petrovic      13 Nov 28     Corrected time in Checker
--                                                process for Quad DDR read
--                                                with DLP
--    V1.2          S.Petrovic      13 Dec 23     DLP read enabled with 4
--                                                latency cycles
--    V1.3         S.Petrovic       26 Aug 14     Added SFDP JEDEC parameter
--    V1.4         M.Stojanovic     15 Apr 08     Corrected SFDP JEDEC parameter
--    V1.5         M.Stojanovic     15 Apr 09     Corrected SFDP JEDEC parameters
--                                                from 17h to 37h
--    V1.6         M.Stojanovic     13 May 15     Added DPD and RES_DPD commands
--    V1.7         B.Barac          17 Jun 20     Wrap read and few other discrepencies fixed
--
-------------------------------------------------------------------------------
--  PART DESCRIPTION:
--
--  Description:
--             Generic test enviroment for verification of flash memory
--             VITAL models.
--
-------------------------------------------------------------------------------
--  Comments :
--      * For correct simulation, simulator resolution should be set to 1ps.
--      * When testing with different timing models, value of CONSTANT
--        Timingmodel should be changed
--      * When testing with different hybrid sector architecture, value of
--        CONSTANT BootConfig should be changed. Possible values are
--        TRUE for BottomBoot and FALSE for TopBoot
-------------------------------------------------------------------------------
--  Known Bugs:
--
-------------------------------------------------------------------------------
--  Notes:
--  Choose value for variable 'Clock_polarity' to select SPI mode
--    Clock_polarity <= '0'; for SPI mode: CPO L= 0, CPHA = 0
--    Clock_polarity <= '1'; for SPI mode: CPO L= 1, CPHA = 1
--  Set test environment - device protection mode
--    MODE <= DEFAULT_PROTECTION;
--    MODE <= PERSISTENT_PROTECTION;
--    MODE <= PASSWORD_PROTECTION;
-------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.std_logic_1164.ALL;
    USE IEEE.VITAL_timing.ALL;
    USE IEEE.VITAL_primitives.ALL;
    USE STD.textio.ALL;

LIBRARY FMF;
    USE FMF.gen_utils.all;
    USE FMF.conversions.all;

LIBRARY work;
    USE work.spansion_tc_pkg.all;
-------------------------------------------------------------------------------
-- ENTITY DECLARATION
-------------------------------------------------------------------------------
ENTITY testbench_s25fs256s_verilog IS

END testbench_s25fs256s_verilog;
-------------------------------------------------------------------------------
-- ARCHITECTURE DECLARATION
-------------------------------------------------------------------------------
ARCHITECTURE vhdl_behavioral of testbench_s25fs256s_verilog IS
    COMPONENT s25fs256s IS
        GENERIC (

            UserPreload       : integer   := 1;
            -- memory file to be loaded
            mem_file_name     : STRING    := "s25fs256s.mem";
            otp_file_name     : STRING    := "s25fs256sOTP.mem";

            -- For FMF SDF technology file usage
            TimingModel       : STRING    := DefaultTimingModel
        );
        PORT (
            -- Data Inputs/Outputs
            SI              : INOUT std_ulogic := 'U';--serial data input/IO0
            SO              : INOUT std_ulogic := 'U';--serial data output/IO1
            -- Controls
            SCK             : IN    std_ulogic := 'U';--serial clock input
            CSNeg           : IN    std_ulogic := 'U';--chip select input
            WPNeg           : INOUT std_ulogic := 'U';--write protect input/IO2
            RESETNeg        : INOUT std_ulogic := 'U' --reset input/IO3
    );
    END COMPONENT;

    FOR ALL: s25fs256s USE ENTITY work.s25fs256s;
    ---------------------------------------------------------------------------
    --memory configuration
    ---------------------------------------------------------------------------
    CONSTANT MaxData       : NATURAL := 16#FF#;        --255;
    CONSTANT MemSize       : NATURAL := 16#1FFFFFF#;
    CONSTANT SecNumUni     : NATURAL := 511;
    CONSTANT SecNumHyb     : NATURAL := 519;
    CONSTANT BlockNumUni   : NATURAL := 127;
    CONSTANT BlockNumHyb   : NATURAL := 135;
    CONSTANT SecSize4      : NATURAL := 16#FFF#;
    CONSTANT SecSize64     : NATURAL := 16#FFFF#;
    CONSTANT SecSize256    : NATURAL := 16#3FFFF#;
    CONSTANT PageNum512    : NATURAL := 16#1FFFF#;
    CONSTANT PageNum256    : NATURAL := 16#3FFFF#;
    CONSTANT AddrRANGE     : NATURAL := 16#1FFFFFF#;
    CONSTANT HiAddrBit     : NATURAL := 31;
    CONSTANT OTPSize       : NATURAL := 1023;
    CONSTANT OTPLoAddr     : NATURAL := 16#000#;
    CONSTANT OTPHiAddr     : NATURAL := 16#3FF#;
    CONSTANT SFDPSize      : NATURAL := 16#113F#;
    CONSTANT SFDPLoAddr    : NATURAL := 16#0000#;
    CONSTANT SFDPHiAddr    : NATURAL := 16#113F#;

    ---------------------------------------------------------------------------
    --model configuration
    ---------------------------------------------------------------------------
    CONSTANT mem_file           :   string  := "s25fs256s.mem";
    CONSTANT otp_file           :   string  := "s25fs256sOTP.mem";
    CONSTANT half_period1_srl   :   time    := 3.76 ns;--1/(2*133MHz)
    CONSTANT half_period2_srl   :   time    := 10 ns;  --1/(2*50MHz)
    CONSTANT half_period_ddr    :   time    := 6.55 ns;--1/(2*80MHz)

    CONSTANT UserPreload        :   integer :=  1;
    CONSTANT LongTimming        :   boolean :=  TRUE;
    CONSTANT TimingModel        :   STRING  :=  "S25FS256SAGBHIY00_F_30pF";
    CONSTANT BootConfig         :   boolean :=  TRUE;
    ---------------------------------------------------------------------------
    --One Byte Instruction Code
    ---------------------------------------------------------------------------
    CONSTANT I_WRR          :std_logic_vector(7 downto 0) := "00000001";-- 01h
    CONSTANT I_PP           :std_logic_vector(7 downto 0) := "00000010";-- 02h
    CONSTANT I_READ         :std_logic_vector(7 downto 0) := "00000011";-- 03h
    CONSTANT I_WRDI         :std_logic_vector(7 downto 0) := "00000100";-- 04h
    CONSTANT I_RDSR1        :std_logic_vector(7 downto 0) := "00000101";-- 05h
    CONSTANT I_WREN         :std_logic_vector(7 downto 0) := "00000110";-- 06h
    CONSTANT I_RDSR2        :std_logic_vector(7 downto 0) := "00000111";-- 07h
    CONSTANT I_PP4          :std_logic_vector(7 downto 0) := "00010010";-- 12h
    CONSTANT I_READ4        :std_logic_vector(7 downto 0) := "00010011";-- 13h
    CONSTANT I_ECCRD4       :std_logic_vector(7 downto 0) := "00011000";-- 18h
    CONSTANT I_ECCRD        :std_logic_vector(7 downto 0) := "00011001";-- 19h
    CONSTANT I_P4E          :std_logic_vector(7 downto 0) := "00100000";-- 20h
    CONSTANT I_P4E4         :std_logic_vector(7 downto 0) := "00100001";-- 21h
    CONSTANT I_30h          :std_logic_vector(7 downto 0) := "00110000";-- 30h
    CONSTANT I_RDCR         :std_logic_vector(7 downto 0) := "00110101";-- 35h
    CONSTANT I_DLPRD        :std_logic_vector(7 downto 0) := "01000001";-- 41h
    CONSTANT I_OTPP         :std_logic_vector(7 downto 0) := "01000010";-- 42h
    CONSTANT I_PNVDLR       :std_logic_vector(7 downto 0) := "01000011";-- 43h
    CONSTANT I_BE_60        :std_logic_vector(7 downto 0) := "01100000";-- 60h
    CONSTANT I_RDAR         :std_logic_vector(7 downto 0) := "01100101";-- 65h
    CONSTANT I_RSTEN        :std_logic_vector(7 downto 0) := "01100110";-- 66h
    CONSTANT I_WRAR         :std_logic_vector(7 downto 0) := "01110001";-- 71h
    CONSTANT I_EPS_75       :std_logic_vector(7 downto 0) := "01110101";-- 75h
    CONSTANT I_CLSR         :std_logic_vector(7 downto 0) := "10000010";-- 82h
    CONSTANT I_EPS_85       :std_logic_vector(7 downto 0) := "10000101";-- 85h
    CONSTANT I_RST          :std_logic_vector(7 downto 0) := "10011001";-- 99h
    CONSTANT I_FAST_READ    :std_logic_vector(7 downto 0) := "00001011";-- 0Bh
    CONSTANT I_FAST_READ4   :std_logic_vector(7 downto 0) := "00001100";-- 0Ch
    CONSTANT I_ASPRD        :std_logic_vector(7 downto 0) := "00101011";-- 2Bh
    CONSTANT I_ASPP         :std_logic_vector(7 downto 0) := "00101111";-- 2Fh
    CONSTANT I_WVDLR        :std_logic_vector(7 downto 0) := "01001010";-- 4Ah
    CONSTANT I_OTPR         :std_logic_vector(7 downto 0) := "01001011";-- 4Bh
    CONSTANT I_RSFDP        :std_logic_vector(7 downto 0) := "01011010";-- 5Ah
    CONSTANT I_EPR_7A       :std_logic_vector(7 downto 0) := "01111010";-- 7Ah
    CONSTANT I_EPR_8A       :std_logic_vector(7 downto 0) := "10001010";-- 8Ah
    CONSTANT I_RDID         :std_logic_vector(7 downto 0) := "10011111";-- 9Fh
    CONSTANT I_PLBWR        :std_logic_vector(7 downto 0) := "10100110";-- A6h
    CONSTANT I_PLBRD        :std_logic_vector(7 downto 0) := "10100111";-- A7h
    CONSTANT I_RDQID        :std_logic_vector(7 downto 0) := "10101111";-- AFh
    CONSTANT I_EPS_B0       :std_logic_vector(7 downto 0) := "10110000";-- B0h
    CONSTANT I_BAM4         :std_logic_vector(7 downto 0) := "10110111";-- B7h
    CONSTANT I_DPD          :std_logic_vector(7 downto 0) := "10111001";-- B9h
    CONSTANT I_RES_DPD      :std_logic_vector(7 downto 0) := "10101011";-- ABh
    CONSTANT I_DIOR         :std_logic_vector(7 downto 0) := "10111011";-- BBh
    CONSTANT I_DIOR4        :std_logic_vector(7 downto 0) := "10111100";-- BCh
    CONSTANT I_SBL          :std_logic_vector(7 downto 0) := "11000000";-- C0h
    CONSTANT I_BE_C7        :std_logic_vector(7 downto 0) := "11000111";-- C7h
    CONSTANT I_EES          :std_logic_vector(7 downto 0) := "11010000";-- D0h
    CONSTANT I_SE           :std_logic_vector(7 downto 0) := "11011000";-- D8h
    CONSTANT I_SE4          :std_logic_vector(7 downto 0) := "11011100";-- DCh
    CONSTANT I_DYBRD4       :std_logic_vector(7 downto 0) := "11100000";-- E0h
    CONSTANT I_DYBWR4       :std_logic_vector(7 downto 0) := "11100001";-- E1h
    CONSTANT I_PPBRD4       :std_logic_vector(7 downto 0) := "11100010";-- E2h
    CONSTANT I_PPBP4        :std_logic_vector(7 downto 0) := "11100011";-- E3h
    CONSTANT I_PPBERS       :std_logic_vector(7 downto 0) := "11100100";-- E4h
    CONSTANT I_PASSRD       :std_logic_vector(7 downto 0) := "11100111";-- E7h
    CONSTANT I_PASSP        :std_logic_vector(7 downto 0) := "11101000";-- E8h
    CONSTANT I_PASSU        :std_logic_vector(7 downto 0) := "11101001";-- E9h
    CONSTANT I_RDQIOR       :std_logic_vector(7 downto 0) := "11101011";-- EBh
    CONSTANT I_RDQIOR4      :std_logic_vector(7 downto 0) := "11101100";-- ECh
    CONSTANT I_DDRQIOR      :std_logic_vector(7 downto 0) := "11101101";-- EDh
    CONSTANT I_DDRQIOR4     :std_logic_vector(7 downto 0) := "11101110";-- EEh
    CONSTANT I_RESET        :std_logic_vector(7 downto 0) := "11110000";-- F0h
    CONSTANT I_DYBRD        :std_logic_vector(7 downto 0) := "11111010";-- FAh
    CONSTANT I_DYBWR        :std_logic_vector(7 downto 0) := "11111011";-- FBh
    CONSTANT I_PPBRD        :std_logic_vector(7 downto 0) := "11111100";-- FCh
    CONSTANT I_PPBP         :std_logic_vector(7 downto 0) := "11111101";-- FDh
    CONSTANT I_MBR          :std_logic_vector(7 downto 0) := "11111111";-- FFh

    ---------------------------------------------------------------------------
    --testbench parameters
    ---------------------------------------------------------------------------
    --Flash Memory Array
    TYPE MemArr IS ARRAY (0 TO AddrRANGE)      OF integer RANGE -1 TO MaxData;
    --OTP Array
    TYPE OtpArr IS ARRAY (OTPLoAddr TO OTPHiAddr) OF integer
                                                            RANGE -1 TO MaxData;
    --CFI Array
    TYPE CFIArr IS ARRAY (16#00# TO 16#13F#) OF integer RANGE -1 TO MaxData;

    --SFDP Array
    TYPE SFDPArr IS ARRAY (SFDPLoAddr TO SFDPHiAddr) OF integer
                                                            RANGE -1 TO MaxData;

    ---------------------------------------------------------------------------
    --  memory declaration
    ---------------------------------------------------------------------------
    --             -- Mem(SecAddr)(Address)....
    SHARED  VARIABLE Mem             : MemArr := (OTHERS => MaxData);
    SHARED  VARIABLE Otp             : OtpArr := (OTHERS => MaxData);
    SHARED  VARIABLE CFI_array       : CFIArr;
    SHARED  VARIABLE SFDP_array      : SFDPArr;
    SHARED  VARIABLE half_period     : TIME     := half_period1_srl;--3.76 ns

    --command sequence
    SHARED VARIABLE cmd_seq         : cmd_seq_type;

    SIGNAL status          : status_type := none;
    SIGNAL cmd             : cmd_type := idle;
    SIGNAL read_num        : NATURAL := 0;

    -- device protection mode
    TYPE protection_type IS ( DEFAULT_PROTECTION,
                              PERSISTENT_PROTECTION,
                              PASSWORD_PROTECTION);

    SIGNAL MODE            : protection_type;

    SIGNAL Clock_polarity  : std_logic;
    SIGNAL PageSize        :   NATURAL :=  256 ;
    SIGNAL PageNum         :   NATURAL :=  0 ;

    SIGNAL check_err       :   std_logic := '0'; -- Active high on error
    SIGNAL ErrorInTest     :   std_logic := '0';

    ---------------------------------------------------------------------------
    --Personality module:
    --
    --  instanciates the DUT module and adapts generic test signals to it
    ---------------------------------------------------------------------------
    --DUT port
    SIGNAL T_SCK                : std_logic                     := 'U';
    SIGNAL T_SI                 : std_logic                     := 'U';
    SIGNAL T_SO                 : std_logic                     := 'U';

    SIGNAL T_CSNeg              : std_logic                     := 'U';
    SIGNAL T_RESETNeg           : std_logic                     := '1';
    SIGNAL T_WPNeg              : std_logic                     := '1';

    --Sector Protection Status
    SHARED VARIABLE Sec_Prot     : std_logic_vector (SecNumHyb downto 0) :=
                                                    (OTHERS => '0');
    SHARED VARIABLE Block_Prot     : std_logic_vector (BlockNumHyb downto 0) :=
                                                    (OTHERS => '0');
-----------------------------
-- Registers
-----------------------------
        --     ***  Status Register 1  ***
    SHARED VARIABLE SR1_NV      : std_logic_vector(7 downto 0) := "00000000";
    SHARED VARIABLE SR1_V       : std_logic_vector(7 downto 0) := "00000000";

    -- Non-Volatile Status Register Write Disable Bit
    ALIAS SRWD_NV   :std_logic IS SR1_NV(7);
    -- Non-Volatile Status Register Block Protection Bits
    ALIAS BP2_NV    :std_logic IS SR1_NV(4);
    ALIAS BP1_NV    :std_logic IS SR1_NV(3);
    ALIAS BP0_NV    :std_logic IS SR1_NV(2);

    -- Volatile Status Register Write Disable Bit
    ALIAS SRWD      :std_logic IS SR1_V(7);
    -- Volatile Status Register Programming Error Bit
    ALIAS P_ERR     :std_logic IS SR1_V(6);
    -- Volatile Status Register Erase Error Bit
    ALIAS E_ERR     :std_logic IS SR1_V(5);
    -- Volatile Status Register Block Protection Bits
    ALIAS BP2       :std_logic IS SR1_V(4);
    ALIAS BP1       :std_logic IS SR1_V(3);
    ALIAS BP0       :std_logic IS SR1_V(2);
    -- Volatile Status Register Write Enable Latch Bit
    ALIAS WEL       :std_logic IS SR1_V(1);
    -- Volatile Status Register Write In Progress Bit
    ALIAS WIP       :std_logic IS SR1_V(0);

        --     ***  Status Register 2  ***
    SHARED VARIABLE SR2_V       : std_logic_vector(7 downto 0) := "00000000";

    -- Volatile Status Register 2 Erase Status Bit
    ALIAS ESTAT     :std_logic IS SR2_V(2);
    -- Volatile Status Register 2 Write Enable Latch Bit
    ALIAS ES        :std_logic IS SR2_V(1);
    -- Volatile Status Register 2 Write In Progress Bit
    ALIAS PS        :std_logic IS SR2_V(0);

        --     ***  Configuration Register 1  ***
    SHARED VARIABLE CR1_NV      : std_logic_vector(7 downto 0) := "00000000";
    SHARED VARIABLE CR1_V       : std_logic_vector(7 downto 0) := "00000000";

    -- Non-Volatile Configuration Register 1 TBPROT bit
    ALIAS TBPROT_O  :std_logic IS CR1_NV(5);
    -- Non-Volatile Configuration Register 1 LOCK bit
    ALIAS LOCK_O    :std_logic IS CR1_NV(4);
    -- Non-Volatile Configuration Register 1 BPNV bit
    ALIAS BPNV_O    :std_logic IS CR1_NV(3);
    -- Non-Volatile Configuration Register 1 TBPARM bit
    ALIAS TBPARM_O  :std_logic IS CR1_NV(2);
    -- Non-Volatile Configuration Register 1 QUAD bit
    ALIAS QUAD_NV   :std_logic IS CR1_NV(1);

    -- Volatile Configuration Register 1 TBPROT bit
    ALIAS TBPROT    :std_logic IS CR1_V(5);
    -- Volatile Configuration Register 1 LOCK bit
    ALIAS LOCK      :std_logic IS CR1_V(4);
    -- Volatile Configuration Register 1 BPNV bit
    ALIAS BPNV      :std_logic IS CR1_V(3);
    -- Volatile Configuration Register 1 TBPARM bit
    ALIAS TBPARM    :std_logic IS CR1_V(2);
    -- Volatile Configuration Register 1 QUAD bit
    ALIAS QUAD      :std_logic IS CR1_V(1);
    -- Volatile Configuration Register 1 FREEZE bit
    ALIAS FREEZE    :std_logic IS CR1_V(0);

        --     ***  Configuration Register 2  ***
    SHARED VARIABLE CR2_NV      : std_logic_vector(7 downto 0) := "00001000";
    SHARED VARIABLE CR2_V       : std_logic_vector(7 downto 0) := "00001000";

    -- Non-Volatile Configuration Register 2 QA bit
    ALIAS QUAD_ALL_NV :std_logic IS CR2_NV(6);
    -- Volatile Configuration Register 2 QA bit
    ALIAS QUAD_ALL    :std_logic IS CR2_V(6);

        --     ***  Configuration Register 3  ***
    SHARED VARIABLE CR3_NV      : std_logic_vector(7 downto 0) := "00000000";
    SHARED VARIABLE CR3_V       : std_logic_vector(7 downto 0) := "00000000";

        --     ***  Configuration Register 4  ***
    SHARED VARIABLE CR4_NV      : std_logic_vector(7 downto 0) := "00010000";
    SHARED VARIABLE CR4_V       : std_logic_vector(7 downto 0) := "00010000";

        --      ***  ASP Register  ***
    SHARED VARIABLE ASP_reg        : std_logic_vector(15 downto 0) :=
                                                                (OTHERS => '1');
    --DYB Lock Boot Bit
    ALIAS DYBLBB    :std_logic IS ASP_reg(4);
    --PPB OTP Bit
    ALIAS PPBOTP    :std_logic IS ASP_reg(3);
    -- Password Protection Mode Lock Bit
    ALIAS PWDMLB    :std_logic IS ASP_reg(2);
    --Persistent Protection Mode Lock Bit
    ALIAS PSTMLB    :std_logic IS ASP_reg(1);
    --Permanent Protection Lock Bit
    ALIAS PERMLB    :std_logic IS ASP_reg(0);

        --      ***  Password Register  ***
    SHARED VARIABLE Password_reg   : std_logic_vector(63 downto 0)
                                            := (others => '1');

        --      ***  PPB Lock Register  ***
    SHARED VARIABLE PPBL           : std_logic_vector(7 downto 0) := "00000001";
    --Persistent Protection Mode Lock Bit
    ALIAS PPB_LOCK                  : std_logic IS PPBL(0);

        --      ***  PPB Access Register  ***
    SHARED VARIABLE PPBAR         : std_logic_vector(7 downto 0)
                                                             := (OTHERS => '1');
    -- PPB_bits(Sec)
    SHARED VARIABLE PPB_bits      : std_logic_vector(SecNumHyb downto 0)
                                                             := (OTHERS => '1');
        --      ***  DYB Access Register  ***
    SHARED VARIABLE DYBAR         : std_logic_vector(7 downto 0)
                                                             := (OTHERS => '1');
    -- DYB(Sec)
    SHARED VARIABLE DYB_bits      : std_logic_vector(SecNumHyb downto 0)
                                                             := (OTHERS => '1');

    SHARED VARIABLE NVDLR_reg     : std_logic_vector(7 downto 0) := "00000000";
    SHARED VARIABLE VDLR_reg      : std_logic_vector(7 downto 0) := "00000000";

    SHARED VARIABLE ECC_reg       : std_logic_vector(7 downto 0) := "00000000";

    -- The Lock Protection Registers for OTP Memory space
    SHARED VARIABLE LOCK_BYTE1 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE2 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE3 :std_logic_vector(7 downto 0);
    SHARED VARIABLE LOCK_BYTE4 :std_logic_vector(7 downto 0);

    SIGNAL Tseries     : NATURAL;
    SIGNAL Tcase       : NATURAL;

    SIGNAL count       : INTEGER RANGE -1 to 7 := -1;

    --Flag for initial configuration
    SIGNAL SECURE_OPN         : BOOLEAN;

    SIGNAL PARAMETER_ERASE    : BOOLEAN;

    SHARED VARIABLE ts_cnt  :   NATURAL RANGE 1 TO 33:=1; -- testseries counter
    SHARED VARIABLE tc_cnt  :   NATURAL RANGE 0 TO 10:=0; -- testcase counter

    FUNCTION ReturnAddr(ADDR : NATURAL; SADDR : NATURAL;
                        Arch: std_logic; Boot: std_logic) RETURN NATURAL IS
        VARIABLE result : NATURAL;
    BEGIN
        IF (Arch = '0' AND Boot = '0') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF (SADDR <= 8) THEN
                result := SADDR*(SecSize4+1) + ADDR;
            ELSE
                result := (SADDR-8)*(SecSize64+1) + ADDR;
            END IF;
        ELSIF (Arch = '0' AND Boot = '1') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF (SADDR <= 511) THEN
                result := SADDR*(SecSize64+1) + ADDR;
            ELSE
            result := AddrRANGE + 1 - 8*(SecSize4+1) +
                      (SADDR-512)*(SecSize4+1)+ ADDR;
            END IF;
        ELSE
        --Uniform Sector Architecture
            result := SADDR*(SecSize64+1) + ADDR;
        END IF;
        RETURN result;
    END ReturnAddr;

    FUNCTION ReturnBlockID(SADDR : NATURAL;
                        Arch: std_logic; Boot: std_logic) RETURN NATURAL IS
        VARIABLE result : NATURAL;
    BEGIN
        IF (Arch = '0' AND Boot = '0') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF SADDR < 8 THEN
                result := SADDR;
            ELSIF SADDR < 12 THEN
                result := 8;
            ELSE
                result := 8 + (SADDR - 8)/4;
            END IF;
        ELSIF (Arch = '0' AND Boot = '1') THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF SADDR <= 507 THEN
                result := SADDR/4;
            ELSIF SADDR <= 511 THEN
                result := 127;
            ELSE
                result := 127 + (SADDR - 511);
            END IF;
        ELSE
        --Uniform Sector Architecture
            result := SADDR/4;
        END IF;
        RETURN result;
    END ReturnBlockID;

    PROCEDURE Sesa(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   SectorID : NATURAL) IS
    BEGIN
        IF CR3_V(3) = '0' AND TBPARM = '0' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF SectorID <= 8 THEN
                IF SectorID < 8 AND PARAMETER_ERASE THEN
                    AddrLOW  := SectorID*(SecSize4+1);
                    AddrHIGH := SectorID*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 8*(SecSize4+1);
                    AddrHIGH := SecSize64;
                END IF;
            ELSE
                AddrLOW  := (SectorID-8)*(SecSize64+1);
                AddrHIGH := (SectorID-8)*(SecSize64+1) + SecSize64;
            END IF;
        ELSIF CR3_V(3) = '0' AND TBPARM_O = '1' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF SectorID < 511 THEN
                AddrLOW  := SectorID*(SecSize64+1);
                AddrHIGH := SectorID*(SecSize64+1) + SecSize64;
            ELSE
                IF SectorID > 511 AND PARAMETER_ERASE THEN
                    AddrLOW  := AddrRANGE + 1 - 8*(SecSize4+1) +
                            (SectorID-512)*(SecSize4+1);
                    AddrHIGH := AddrRANGE + 1 - 8*(SecSize4+1) +
                            (SectorID-512)*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 511*(SecSize64+1);
                    AddrHIGH := AddrRANGE - 8*(SecSize4+1);
                END IF;
            END IF;
        ELSE
            AddrLOW  := SectorID*(SecSize64+1);
            AddrHIGH := SectorID*(SecSize64+1) + SecSize64;
        END IF;
    END Sesa;

    PROCEDURE Seba(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   BlockID : NATURAL) IS
    BEGIN
        IF CR3_V(3) = '0' AND TBPARM = '0' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Bottom
            IF BlockID <= 8 THEN
                IF BlockID < 8 AND PARAMETER_ERASE THEN
                    AddrLOW  := BlockID*(SecSize4+1);
                    AddrHIGH := BlockID*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 8*(SecSize4+1);
                    AddrHIGH := SecSize256;
                END IF;
            ELSE
                AddrLOW  := (BlockID-8)*(SecSize256+1);
                AddrHIGH := (BlockID-8)*(SecSize256+1) + SecSize256;
            END IF;
        ELSIF CR3_V(3) = '0' AND TBPARM_O = '1' THEN
        --Hybrid Sector Architecture, 4KB Sectors at Top
            IF BlockID < 127 THEN
                AddrLOW  := BlockID*(SecSize256+1);
                AddrHIGH := BlockID*(SecSize256+1) + SecSize256;
            ELSE
                IF BlockID > 127 AND PARAMETER_ERASE THEN
                    AddrLOW  := AddrRANGE + 1 - 8*(SecSize4+1) +
                            (BlockID-128)*(SecSize4+1);
                    AddrHIGH := AddrRANGE + 1 - 8*(SecSize4+1) +
                            (BlockID-128)*(SecSize4+1) + SecSize4;
                ELSE
                    AddrLOW  := 127*(SecSize256+1);
                    AddrHIGH := AddrRANGE - 8*(SecSize4+1);
                END IF;
            END IF;
        ELSE
            AddrLOW  := BlockID*(SecSize256+1);
            AddrHIGH := BlockID*(SecSize256+1) + SecSize256;
        END IF;
    END Seba;

    PROCEDURE sepa(
        VARIABLE   AddrLOW  : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   AddrHIGH : INOUT NATURAL RANGE 0 to ADDRRange;
        VARIABLE   SectorID : NATURAL;
        VARIABLE   Addr     : NATURAL) IS
        VARIABLE   Page     : NATURAL;
        VARIABLE   Addr_tmp : NATURAL;
    BEGIN
        Addr_tmp := ReturnAddr(Addr,SectorID, CR3_V(3), TBPARM_O);
        Page     := Addr_tmp/PageSize;-- page number

        AddrLOW  := Page*PageSize;
        AddrHIGH := Page*PageSize + PageSize - 1;

    END sepa;

    PROCEDURE BlockProtect(
        VARIABLE   Sec_Prot   : INOUT std_logic_vector (SecNumHyb downto 0);
        VARIABLE   Block_Prot : INOUT std_logic_vector (BlockNumHyb downto 0);
        VARIABLE   BP_bits    : std_logic_vector (2 downto 0) ) IS
    BEGIN

        Sec_Prot := (OTHERS => '0');
        Block_Prot := (OTHERS => '0');

        CASE BP_bits IS
        WHEN "000" =>

        WHEN "001" =>
            IF CR3_V(3) = '1' THEN -- Uniform Architecture
                IF TBPROT_O = '0' THEN --BP starts at Top
                    Sec_Prot(SecNumUni downto(SecNumUni+1)*63/64)
										:= (OTHERS => '1');
                    Block_Prot(BlockNumUni downto
                     (BlockNumUni+1)*63/64) := (OTHERS => '1');
                ELSE
                    Sec_Prot((SecNumUni+1)/64-1 downto 0):= (OTHERS => '1');
                    Block_Prot((BlockNumUni+1)/64-1 downto 0):=(OTHERS => '1');
                END IF;
            ELSE
                IF TBPARM_O = '1' THEN
                    IF TBPROT_O = '0' THEN--BP starts at Top
                        Sec_Prot(SecNumHyb downto (SecNumHyb-7)*63/64) :=
                                                                (OTHERS => '1');
                        Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*63/64) :=
                                                                (OTHERS => '1');
                    ELSE
                        Sec_Prot((SecNumHyb-7)/64-1 downto 0):=(OTHERS => '1');
                        Block_Prot((BlockNumHyb-7)/64-1 downto 0):=(OTHERS => '1');
                    END IF;
                ELSE
                    IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)*63/64+8) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*63/64+8) :=
                                                                (OTHERS => '1');
                    ELSE
                         Sec_Prot((SecNumHyb-7)/64+7 downto 0) :=
																(OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/64+7 downto 0) :=
																(OTHERS => '1');
                    END IF;
                END IF;
            END IF;
        WHEN "010" =>
            IF CR3_V(3) = '1' THEN -- Uniform Architecture
                IF TBPROT_O = '0' THEN--BP starts at Top
                    Sec_Prot(SecNumUni downto (SecNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                    Block_Prot(BlockNumUni downto (BlockNumUni+1)*31/32)
                                                            := (OTHERS => '1');
                 ELSE
                    Sec_Prot((SecNumUni+1)/32-1 downto 0) := (OTHERS => '1');
                    Block_Prot((BlockNumUni+1)/32-1 downto 0) := (OTHERS => '1');
                 END IF;
            ELSE
                 IF TBPARM_O = '1' THEN
                     IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto  (SecNumHyb-7)*31/32) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto  (BlockNumHyb-7)*31/32) :=
                                                                (OTHERS => '1');
                     ELSE
                         Sec_Prot((SecNumHyb-7)/32-1 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/32-1 downto 0) := (OTHERS => '1');
                     END IF;
                 ELSE
                     IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)*31/32+8) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*31/32+8) :=
                                                                (OTHERS => '1');
                     ELSE
                         Sec_Prot((SecNumHyb-7)/32+7 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/32+7 downto 0) := (OTHERS => '1');
                     END IF;
                 END IF;
            END IF;

        WHEN "011" =>
            IF CR3_V(3) = '1' THEN -- Uniform Architecture
                 IF TBPROT_O = '0' THEN --BP starts at Top
                     Sec_Prot(SecNumUni downto (SecNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                     Block_Prot(BlockNumUni downto (BlockNumUni+1)*15/16)
                                                            := (OTHERS => '1');
                 ELSE
                     Sec_Prot((SecNumUni+1)/16-1 downto 0) := (OTHERS => '1');
                     Block_Prot((BlockNumUni+1)/16-1 downto 0) := (OTHERS => '1');
                 END IF;
            ELSE
                 IF TBPARM_O = '1' THEN
                     IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)*15/16) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*15/16) :=
                                                                (OTHERS => '1');
                     ELSE
                         Sec_Prot((SecNumHyb-7)/16-1 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/16-1 downto 0) := (OTHERS => '1');
                     END IF;
                 ELSE
                     IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)*15/16+8) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*15/16+8) :=
                                                                (OTHERS => '1');
                     ELSE
                         Sec_Prot((SecNumHyb-7)/16+7 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/16+7 downto 0) := (OTHERS => '1');
																					
                     END IF;
                 END IF;
            END IF;

        WHEN "100" =>
            IF CR3_V(3) = '1' THEN -- Uniform Architecture
                IF TBPROT_O = '0' THEN --BP starts at Top
                     Sec_Prot(SecNumUni downto (SecNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                     Block_Prot(BlockNumUni downto (BlockNumUni+1)*7/8)
                                                            := (OTHERS => '1');
                ELSE
                     Sec_Prot((SecNumUni+1)/8-1 downto 0):= (OTHERS => '1');
                     Block_Prot((BlockNumUni+1)/8-1 downto 0):= (OTHERS => '1');
                END IF;
            ELSE
                IF TBPARM_O = '1' THEN
                    IF TBPROT_O = '0' THEN--BP starts at Top
                        Sec_Prot(SecNumHyb downto (SecNumHyb-7)*7/8) :=
                                                                (OTHERS => '1');
                        Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*7/8) :=
                                                                (OTHERS => '1');
                    ELSE
                        Sec_Prot((SecNumHyb-7)/8-1 downto 0) := (OTHERS => '1');
                        Block_Prot((BlockNumHyb-7)/8-1 downto 0) := (OTHERS => '1');
                    END IF;
                ELSE
                    IF TBPROT_O = '0' THEN--BP starts at Top
                        Sec_Prot(SecNumHyb downto (SecNumHyb-7)*7/8+8) :=
                                                                (OTHERS => '1');
                        Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*7/8+8) :=
                                                                (OTHERS => '1');

                    ELSE
                        Sec_Prot((SecNumHyb-7)/8+7 downto 0) := (OTHERS => '1');
                        Block_Prot((BlockNumHyb-7)/8+7 downto 0) := (OTHERS => '1');
                    END IF;
                END IF;
            END IF;

        WHEN "101" =>
            IF CR3_V(3) = '1' THEN -- Uniform Architecture
                IF TBPROT_O = '0' THEN --BP starts at Top
                    Sec_Prot(SecNumUni downto (SecNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                    Block_Prot(BlockNumUni downto (BlockNumUni+1)*3/4)
                                                            := (OTHERS => '1');
                ELSE
                    Sec_Prot((SecNumUni+1)/4-1 downto 0) := (OTHERS => '1');
                    Block_Prot((BlockNumUni+1)/4-1 downto 0) := (OTHERS => '1');
                END IF;
            ELSE
                IF TBPARM_O = '1' THEN
                    IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)*3/4) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*3/4) :=
                                                                (OTHERS => '1');
                    ELSE
                         Sec_Prot((SecNumHyb-7)/4-1 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/4-1 downto 0) := (OTHERS => '1');
                    END IF;
                ELSE
                    IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)*3/4+8) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)*3/4+8) :=
                                                                (OTHERS => '1');

                    ELSE
                         Sec_Prot((SecNumHyb-7)/4+7 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/4+7 downto 0) := (OTHERS => '1');
                    END IF;
                END IF;
            END IF;

        WHEN "110" =>
            IF CR3_V(3) = '1' THEN -- Uniform Architecture
                IF TBPROT_O = '0' THEN  --BP starts at Top
                    Sec_Prot(SecNumUni downto (SecNumUni+1)/2)
 	                                                           := (OTHERS => '1');
                    Block_Prot(BlockNumUni downto (BlockNumUni+1)/2)
 	                                                           := (OTHERS => '1');
				
                ELSE
                    Sec_Prot((SecNumUni+1)/2-1 downto 0) := (OTHERS => '1');
                    Block_Prot((BlockNumUni+1)/2-1 downto 0) := (OTHERS => '1');
                END IF;
            ELSE
                IF TBPARM_O = '1' THEN
                    IF TBPROT_O = '0' THEN--BP starts at Top
                         Sec_Prot(SecNumHyb downto (SecNumHyb-7)/2) :=
                                                                (OTHERS => '1');
                         Block_Prot(BlockNumHyb downto (BlockNumHyb-7)/2) :=
                                                                (OTHERS => '1');
                    ELSE
                         Sec_Prot((SecNumHyb-7)/2-1 downto 0) := (OTHERS => '1');
                         Block_Prot((BlockNumHyb-7)/2-1 downto 0) := (OTHERS => '1');
                    END IF;
                ELSE
                    IF TBPROT_O = '0' THEN--BP starts at Top
                        Sec_Prot(SecNumHyb downto (SecNumHyb-7)/2+8) :=
                                                                (OTHERS => '1');
                        Block_Prot(BlockNumHyb downto (BlockNumHyb-7)/2+8) :=
                                                                (OTHERS => '1');
                    ELSE
                        Sec_Prot((SecNumHyb-7)/2+7 downto 0) := (OTHERS => '1');
                        Block_Prot((BlockNumHyb-7)/2+7 downto 0) := (OTHERS => '1');
                    END IF;
                END IF;
            END IF;

        WHEN OTHERS =>
            Sec_Prot := (OTHERS => '1');
            Block_Prot := (OTHERS => '1');
        END CASE;
   END BlockProtect;

    BEGIN
        DUT : s25fs256s
        GENERIC MAP (

            -- memory file to be loaded
            UserPreload       => UserPreload,
            mem_file_name     => "s25fs256s.mem",
            otp_file_name     => "s25fs256sOTP.mem",

            -- For FMF SDF technology file usage
            TimingModel       =>  "S25FS256SAGBHIY00_F_30pF"
        )
        PORT MAP(
            SCK        => T_SCK,
            SI         => T_SI,
            SO         => T_SO,
            CSNeg      => T_CSNeg,
            RESETNeg   => T_RESETNeg,
            WPNeg      => T_WPNeg
        );

   Clock_polarity <= '0';--SPI mode: CPO L= 0, CPHA = 0
--     Clock_polarity <= '1';--SPI mode: CPO L= 1, CPHA = 1

   MODE <= DEFAULT_PROTECTION;
--    MODE <= PERSISTENT_PROTECTION;
--    MODE <= PASSWORD_PROTECTION;

    clk_count: PROCESS(T_SCK)
    BEGIN
        IF rising_edge(T_SCK) THEN
            count <= (count+1)mod 8;
        END IF;
    END PROCESS clk_count;

    clk_generation: PROCESS(T_SCK, T_CSNeg)
    BEGIN
        IF T_CSNeg = '1' THEN
            T_SCK <= Clock_polarity;
        ELSE
            T_SCK <= NOT T_SCK AFTER half_period;
        END IF;
    END PROCESS clk_generation;

--At the end of the simulation, if ErrorInTest='0' there were no errors
    err_ctrl : PROCESS ( check_err  )
    BEGIN
        IF check_err = '1' THEN
            ErrorInTest <= '1';
        END IF;
    END PROCESS err_ctrl;

tb  :PROCESS

    --------------------------------------------------------------------------
    --= PROCEDURE to select TC
    -- can be modified to read TC list from file, or to generate random list
    --------------------------------------------------------------------------
    PROCEDURE   Pick_TC
        (Model   :  IN  string  := "s25fs256s" )
    IS
    BEGIN
    CASE MODE IS
        WHEN DEFAULT_PROTECTION =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt < 32 THEN
                    TS_cnt := TS_cnt+1;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN PERSISTENT_PROTECTION =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 31;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;

        WHEN PASSWORD_PROTECTION   =>
            IF TC_cnt < tc(TS_cnt) THEN
                TC_cnt := TC_cnt+1;
            ELSE
                TC_cnt := 1;
                IF TS_cnt = 1 THEN
                    TS_cnt := 2;
                ELSIF TS_cnt = 2 THEN
                    TS_cnt := 32;
                ELSIF TS_cnt = 32 THEN
                    TS_cnt := 33;
                ELSE
                    IF ErrorInTest='0' THEN
                        REPORT "Test Ended without errors"
                        SEVERITY note;
                    ELSE
                        REPORT "There were errors in test"
                        SEVERITY note;
                    END IF;
                    WAIT;
                END IF;
            END IF;
        END CASE;
    END PROCEDURE Pick_TC;

   ----------------------------------------------------------------------------
    --bus commands, device specific implementation
    ---------------------------------------------------------------------------
    TYPE bus_type IS (bus_idle,
                      bus_select,     --CS# asseretd
                      bus_deselect,   --CS# deasserted after write
                      bus_desel_read, --CS# deasserted after read
                      bus_opcode,
                      bus_reset,
                      bus_address,
                      bus_dummy_byte,
                      bus_dummy_clock,
                      bus_mode_byte,
                      bus_data_read,
                      bus_data_write,
                      bus_inv_write); -- write is less then 8 bits

    --bus drive for specific command sequence cycle
    PROCEDURE bus_cycle(
        bus_cmd   :IN   bus_type := bus_idle;
        opcode    :IN   std_logic_vector(7 downto 0) := "00000000";
        data4     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data3     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data2     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        data1     :IN   NATURAL RANGE 0 TO 16#FFFF# := 0;
        address   :IN   NATURAL RANGE 0 TO AddrRANGE := 0;
        sector    :IN   INTEGER RANGE 0 TO SecNumHyb := 0;
        data_num  :IN   INTEGER RANGE 0 TO AddrRANGE := 0;
        protect   :IN   boolean                      := false;
        pulse     :IN   boolean                      := false;
        break     :IN   boolean                      := false;
        PowerUp   :IN   boolean                      := false;
        tm        :IN   TIME                         := 0 ns)
    IS
        VARIABLE tmpA         : std_logic_vector(31 downto 0);
        VARIABLE tmpD         : std_logic_vector(7 downto 0);
        VARIABLE tmpD1        : std_logic_vector(15 downto 0);
        VARIABLE tmpPASS      : std_logic_vector(63 downto 0);
        VARIABLE tmpData      : std_logic_vector(7 downto 0);
        VARIABLE Latency_code : NATURAL;
        VARIABLE data_tmp4    : NATURAL := 0;
        VARIABLE data_tmp3    : NATURAL := 0;
        VARIABLE data_tmp2    : NATURAL := 0;
        VARIABLE data_tmp1    : NATURAL := 0;
        VARIABLE AddrLo       : NATURAL;
        VARIABLE AddrHi       : NATURAL;
        VARIABLE SECT         : NATURAL;

    BEGIN

        SECT := sector;

        IF (TimingModel(15) = '0' OR TimingModel(15) = '2' OR
            TimingModel(15) = '3') THEN
            SECURE_OPN <= FALSE;
        ELSIF (TimingModel(15) = 'Y' OR TimingModel(15) = 'Z') THEN
            SECURE_OPN <= TRUE;
        END IF;

        tmpA := to_slv(ReturnAddr(address,SECT, CR3_V(3), TBPARM_O));
        data_tmp4 := data4;
        data_tmp3 := data3;
        data_tmp2 := data2;
        data_tmp1 := data1;
        tmpD := to_slv(data_tmp1, 8);
        tmpD1:= to_slv(data_tmp1, 16);
        tmpPASS(63 downto 0):= to_slv(data_tmp4, 16)& to_slv(data_tmp3, 16)&
                               to_slv(data_tmp2, 16)& to_slv(data_tmp1, 16);

        CASE bus_cmd IS

            WHEN bus_idle        =>
                    T_CSNeg    <= '1';
                    IF protect THEN
                        WAIT FOR 100 ns;
                        T_WPNeg <= not(T_WPNeg);
                    END IF;
                    WAIT FOR 20 ns;

            WHEN bus_select      =>
                T_CSNeg <= '0';
                WAIT FOR tm;

            WHEN bus_reset  =>
                T_RESETNeg <= '0', '1' AFTER tm;
                WAIT FOR 30 ns;

            WHEN bus_inv_write        =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                END IF;
                WAIT FOR 1.5 ns;
                FOR I IN 7 downto (data_num+1) LOOP
                    T_SI <= opcode(i);
                    WAIT FOR 2*half_period;
                END LOOP;
                T_SI <= opcode(data_num);

            WHEN bus_opcode        =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                END IF;
                IF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
                    WAIT FOR 1.5 ns;
                ELSE
                    WAIT FOR 0.5 ns;
                END IF;
                IF (QUAD_ALL = '0') THEN
                    FOR I IN 7 downto 1 LOOP
                        T_SI <= opcode(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= opcode(0);
                ELSE
                    T_RESETNeg <= opcode(7);
                    T_WPNeg    <= opcode(6);
                    T_SO       <= opcode(5);
                    T_SI       <= opcode(4);
                    WAIT FOR 2*half_period;
                    T_RESETNeg <= opcode(3);
                    T_WPNeg    <= opcode(2);
                    T_SO       <= opcode(1);
                    T_SI       <= opcode(0);
                END IF;
                -- if number of clock pulses isn't multiple of 8
                IF pulse THEN
                    WAIT FOR 2*half_period;
                END IF;

            WHEN bus_deselect    =>
                WAIT UNTIL rising_edge(T_SCK);
                IF Clock_polarity = '0' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                ELSE
                    WAIT FOR 3 ns;
                END IF;
                T_CSNeg <= '1';

                IF break THEN
                    WAIT FOR 15 ns;
                ELSE
                    WAIT FOR 30 ns;
                END IF;

            WHEN bus_desel_read    =>
                IF Clock_polarity = '1' THEN
                    WAIT UNTIL rising_edge(T_SCK);
                    IF half_period = half_period1_srl THEN
                        WAIT FOR 3.5 ns;
                    ELSE
                        WAIT FOR 5 ns;
                    END IF;
                ELSE
                    IF half_period = half_period1_srl THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 2 ns;
                    ELSIF half_period = half_period_ddr THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 3 ns;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 3 ns;
                    END IF;
                END IF;
                T_CSNeg <= '1';

                IF QUAD = '1' OR opcode = I_RESET THEN
                    WAIT FOR 2*half_period;
                    T_WPNeg    <= '1';
                    T_RESETNeg <= '1';
                END IF;

            WHEN bus_address     =>
                IF QUAD_ALL = '1' THEN
                --QUAD I/O DDR Read Mode (3 Bytes Address)
                    IF (opcode = I_DDRQIOR AND CR2_V(7) = '0') THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                            T_RESETNeg <= tmpA(23);
                            T_WPNeg    <= tmpA(22);
                            T_SO       <= tmpA(21);
                            T_SI       <= tmpA(20);
                            FOR I IN 4 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 3 ns;
                                T_RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        ELSE
                            WAIT UNTIL rising_edge(T_SCK);
                            FOR I IN 5 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 3 ns;
                                T_RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        END IF;
                    ELSIF (opcode = I_DDRQIOR4 OR
                          (opcode = I_DDRQIOR AND CR2_V(7) = '1')) THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                            T_RESETNeg <= tmpA(31);
                            T_WPNeg    <= tmpA(30);
                            T_SO       <= tmpA(29);
                            T_SI       <= tmpA(28);
                            FOR I IN 6 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 3 ns;
                                T_RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        ELSE
                            WAIT UNTIL rising_edge(T_SCK);
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 3 ns;
                                T_RESETNeg <= tmpA(4*i+3);
                                T_WPNeg    <= tmpA(4*i+2);
                                T_SO       <= tmpA(4*i+1);
                                T_SI       <= tmpA(4*i);
                            END LOOP;
                        END IF;
                    --QUAD I/O High Performance (3 Bytes Address)
                    ELSIF opcode = I_RDQIOR AND CR2_V(7) = '0' THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 4 LOOP
                            T_RESETNeg <= tmpA(23-4*i);
                            T_WPNeg    <= tmpA(22-4*i);
                            T_SO       <= tmpA(21-4*i);
                            T_SI       <= tmpA(20-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    --QUAD I/O High Performance (4 Bytes Address)
                    ELSIF (opcode = I_RDQIOR AND CR2_V(7) = '1') OR
                        opcode = I_RDQIOR4 THEN
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 6 LOOP
                            T_RESETNeg <= tmpA(31-4*i);
                            T_WPNeg    <= tmpA(30-4*i);
                            T_SO       <= tmpA(29-4*i);
                            T_SI       <= tmpA(28-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    ELSIF (opcode = I_RSFDP OR (CR2_V(7) = '0' AND
                      NOT(opcode = I_ECCRD4 OR opcode = I_READ4 OR
                          opcode = I_FAST_READ4 OR opcode = I_DIOR4 OR
                          opcode = I_RDQIOR OR
                          opcode = I_PP4 OR opcode = I_SE4 OR opcode = I_P4E4 OR
                          opcode = I_DYBRD4 OR opcode = I_DYBWR4 OR
                          opcode = I_PPBRD4 OR opcode = I_PPBP4))) THEN
                    --3 Bytes Address
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 4 LOOP
                            T_RESETNeg <= tmpA(23-4*i);
                            T_WPNeg    <= tmpA(22-4*i);
                            T_SO       <= tmpA(21-4*i);
                            T_SI       <= tmpA(20-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    ELSE
                    --4 Bytes Address
                        IF break THEN
                            IF Clock_polarity = '1' THEN
                                WAIT UNTIL falling_edge(T_SCK);
                            END IF;
                        ELSE
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        WAIT FOR 1 ns;
                        FOR I IN 0 TO 6 LOOP
                            T_RESETNeg <= tmpA(31-4*i);
                            T_WPNeg    <= tmpA(30-4*i);
                            T_SO       <= tmpA(29-4*i);
                            T_SI       <= tmpA(28-4*i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_RESETNeg <= tmpA(3);
                        T_WPNeg    <= tmpA(2);
                        T_SO       <= tmpA(1);
                        T_SI       <= tmpA(0);
                    END IF;
                --Dual I/O High Performance (3 Bytes Address)
                ELSIF opcode = I_DIOR AND CR2_V(7) = '0' THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 10 LOOP
                        T_SO <= tmpA(23-2*i);
                        T_SI <= tmpA(22-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpA(1);
                    T_SI <= tmpA(0);
                --Dual I/O High Performance (4 Bytes Address)
                ELSIF (opcode = I_DIOR AND CR2_V(7) = '1') OR
                       opcode = I_DIOR4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 14 LOOP
                        T_SO <= tmpA(31-2*i);
                        T_SI <= tmpA(30-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpA(1);
                    T_SI <= tmpA(0);
                --QUAD I/O High Performance (3 Bytes Address)
                ELSIF opcode = I_RDQIOR AND CR2_V(7) = '0' THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 4 LOOP
                        T_RESETNeg <= tmpA(23-4*i);
                        T_WPNeg    <= tmpA(22-4*i);
                        T_SO       <= tmpA(21-4*i);
                        T_SI       <= tmpA(20-4*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_RESETNeg <= tmpA(3);
                    T_WPNeg    <= tmpA(2);
                    T_SO       <= tmpA(1);
                    T_SI       <= tmpA(0);
                --QUAD I/O High Performance (4 Bytes Address)
                ELSIF (opcode = I_RDQIOR AND CR2_V(7) = '1') OR
                       opcode = I_RDQIOR4 THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                    END IF;
                    WAIT FOR 1 ns;
                    FOR I IN 0 TO 6 LOOP
                        T_RESETNeg <= tmpA(31-4*i);
                        T_WPNeg    <= tmpA(30-4*i);
                        T_SO       <= tmpA(29-4*i);
                        T_SI       <= tmpA(28-4*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_RESETNeg <= tmpA(3);
                    T_WPNeg    <= tmpA(2);
                    T_SO       <= tmpA(1);
                    T_SI       <= tmpA(0);
                --QUAD I/O DDR Read Mode (3 Bytes Address)
                ELSIF (opcode = I_DDRQIOR AND CR2_V(7) = '0') THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        T_RESETNeg <= tmpA(23);
                        T_WPNeg    <= tmpA(22);
                        T_SO       <= tmpA(21);
                        T_SI       <= tmpA(20);
                        FOR I IN 4 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 3 ns;
                            T_RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    ELSE
                        WAIT UNTIL rising_edge(T_SCK);
                        FOR I IN 5 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 3 ns;
                            T_RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    END IF;
                ELSIF (opcode = I_DDRQIOR4 OR
                      (opcode = I_DDRQIOR AND CR2_V(7) = '1')) THEN
                    IF break THEN
                        IF Clock_polarity = '1' THEN
                            WAIT UNTIL falling_edge(T_SCK);
                        END IF;
                        T_RESETNeg <= tmpA(31);
                        T_WPNeg    <= tmpA(30);
                        T_SO       <= tmpA(29);
                        T_SI       <= tmpA(28);
                        FOR I IN 6 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;
                            WAIT FOR 3 ns;
                            T_RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    ELSE
                        WAIT UNTIL rising_edge(T_SCK);
                        FOR I IN 7 downto 0 LOOP
                            WAIT UNTIL T_SCK'EVENT;

                            WAIT FOR 3 ns;
                            T_RESETNeg <= tmpA(4*i+3);
                            T_WPNeg    <= tmpA(4*i+2);
                            T_SO       <= tmpA(4*i+1);
                            T_SI       <= tmpA(4*i);
                        END LOOP;
                    END IF;
                --4 Bytes Address
                ELSIF opcode = I_READ4 OR opcode = I_FAST_READ4 OR
                      opcode = I_PP4 OR opcode =I_SE4 OR opcode = I_P4E4 OR
                      opcode = I_DYBRD4 OR opcode = I_DYBWR4 OR
                      opcode= I_PPBRD4 OR opcode= I_PPBP4 OR opcode=I_ECCRD4 OR
                      ((opcode=I_READ OR  opcode=I_FAST_READ OR opcode=I_OTPR OR
                      opcode = I_OTPP OR opcode = I_PP OR opcode = I_SE OR
                      opcode = I_P4E OR opcode = I_WRAR OR opcode = I_RDAR OR
                      opcode = I_DYBRD OR opcode = I_DYBWR OR opcode=I_ECCRD OR
                      opcode = I_PPBRD OR opcode = I_PPBP OR opcode = I_EES) AND
                      CR2_V(7) = '1') THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;
                    FOR I IN 31 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                ELSE  --3 Bytes Address
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1 ns;

                    FOR I IN 23 downto 1 LOOP
                        T_SI <= tmpA(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpA(0);
                END IF;

            WHEN bus_mode_byte  =>
                IF QUAD_ALL = '1' THEN
                    IF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 3 ns;
                        T_RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR half_period;
                        T_RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    ELSE
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                    END IF;
                ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1.5 ns;
                    FOR I IN 0 to 2 LOOP
                        T_SO <= tmpD(7-2*i);
                        T_SI <= tmpD(6-2*i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SO <= tmpD(1);
                    T_SI <= tmpD(0);
                ELSIF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 1.5 ns;
                    T_RESETNeg <= tmpD(7);
                    T_WPNeg    <= tmpD(6);
                    T_SO       <= tmpD(5);
                    T_SI       <= tmpD(4);
                    WAIT FOR 2*half_period;
                    T_RESETNeg <= tmpD(3);
                    T_WPNeg    <= tmpD(2);
                    T_SO       <= tmpD(1);
                    T_SI       <= tmpD(0);
                ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                    WAIT UNTIL T_SCK'EVENT;
                    WAIT FOR 3 ns;
                    T_RESETNeg <= tmpD(7);
                    T_WPNeg    <= tmpD(6);
                    T_SO       <= tmpD(5);
                    T_SI       <= tmpD(4);
                    WAIT FOR half_period;
                    T_RESETNeg <= tmpD(3);
                    T_WPNeg    <= tmpD(2);
                    T_SO       <= tmpD(1);
                    T_SI       <= tmpD(0);
                END IF;

            WHEN bus_dummy_byte  =>
                IF QUAD_ALL = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 7 downto 1 LOOP
                        T_RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_RESETNeg <= 'Z';
                    T_WPNeg    <= 'Z';
                    T_SI       <= 'Z';
                    T_SO       <= 'Z';
                ELSE
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 7 downto 1 LOOP
                        T_SI <= 'Z';
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= 'Z';
                END IF;

            WHEN bus_dummy_clock  =>
                Latency_code := to_nat(CR2_V(3 DOWNTO 0));

                IF QUAD_ALL = '1' THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1.5 ns;
                            T_RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_DIOR OR opcode = I_DIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1.5 ns;
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSIF (opcode = I_RDQIOR OR opcode = I_RDQIOR4 OR
                       opcode = I_DDRQIOR OR opcode = I_DDRQIOR4) THEN
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1.5 ns;
                            T_RESETNeg <= 'Z';
                            T_WPNeg    <= 'Z';
                            T_SI       <= 'Z';
                            T_SO       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_RESETNeg <= 'Z';
                        T_WPNeg    <= 'Z';
                        T_SI       <= 'Z';
                        T_SO       <= 'Z';
                    END IF;
                ELSE
                    IF Latency_code = 1 THEN
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 1.5 ns;
                        T_SI       <= 'Z';
                    ELSIF Latency_code > 1 THEN
                        FOR I IN (Latency_code-1) DOWNTO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            WAIT FOR 1.5 ns;
                            T_SI       <= 'Z';
                        END LOOP;
                        WAIT FOR 2*half_period;
                        T_SI       <= 'Z';
                    END IF;
                END IF;

            WHEN bus_data_read   =>

                IF QUAD_ALL = '1' OR opcode = I_RDQIOR OR opcode = I_RDQIOR4 OR
                   opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 OR
                   opcode = I_RDQID THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                    T_WPNeg    <= 'Z';
                    T_RESETNeg <= 'Z';
                ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                    T_SI       <= 'Z';
                ELSE
                    WAIT FOR 6.5 ns;
                    T_SO       <= 'Z';
                END IF;
                IF break THEN
                    FOR I IN data_num-1 downto 0 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 8 ns;
                    END LOOP;
                ELSE
                    IF opcode = I_RDQIOR OR opcode = I_RDQIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF opcode = I_DDRQIOR OR opcode = I_DDRQIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL T_SCK'EVENT;
                                WAIT FOR 4 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF QUAD_ALL = '1' THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 1 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF opcode = I_DIOR OR opcode = I_DIOR4 THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 3 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF opcode = I_ASPRD THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 15 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                    ELSIF opcode = I_PASSRD THEN
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 63 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                WAIT FOR 3 ns;
                            END LOOP;
                        END LOOP;
                    ELSE
                        FOR I IN data_num-1 DOWNTO 0 LOOP
                            FOR I IN 7 downto 0 LOOP
                                WAIT UNTIL falling_edge(T_SCK);
                                IF half_period = half_period1_srl THEN
                                    WAIT FOR 3 ns;
                                ELSE
                                    WAIT FOR 8 ns;
                                END IF;
                            END LOOP;
                        END LOOP;
                    END IF;
                END IF;
                --two more bit of data-out sequence
                IF pulse THEN
                    WAIT FOR 4*half_period;
                ELSIF QUAD = '1' THEN
                   WAIT FOR half_period;
                END IF;

            WHEN bus_data_write  =>
                IF QUAD_ALL = '1' THEN
                    WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                    FOR I IN data_num-1 DOWNTO 0 LOOP
                        T_RESETNeg <= tmpD(7);
                        T_WPNeg    <= tmpD(6);
                        T_SO       <= tmpD(5);
                        T_SI       <= tmpD(4);
                        WAIT FOR 2*half_period;
                        T_RESETNeg <= tmpD(3);
                        T_WPNeg    <= tmpD(2);
                        T_SO       <= tmpD(1);
                        T_SI       <= tmpD(0);
                        data_tmp1 := data_tmp1 + 1;
                        tmpD := to_slv(data_tmp1, 8);
                        IF I > 0 THEN
                            WAIT FOR 2*half_period;
                        END IF;
                    END LOOP;
                ELSIF cmd = w_scr OR cmd = w_asp THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 15 downto 1 LOOP
                        T_SI <= tmpD1(i);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpD1(0);
                    tmpD1 := to_slv(data_tmp1, 16);
                ELSIF cmd = w_password OR cmd = psw_unlock THEN
                    WAIT UNTIL falling_edge(T_SCK);
                    WAIT FOR 0.5 ns;
                    FOR I IN 1 to 7 LOOP
                        FOR J IN 1 to 8 LOOP
                            T_SI <= tmpPASS(I*8-J);
                            WAIT FOR 2*half_period;
                        END LOOP;
                    END LOOP;
                    FOR J IN 1 to 7 LOOP
                        T_SI <= tmpPASS(64-J);
                        WAIT FOR 2*half_period;
                    END LOOP;
                    T_SI <= tmpPASS(56);
                ELSE
                    FOR I IN data_num-1 DOWNTO 0 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 0.5 ns;
                        FOR I IN 7 downto 1 LOOP
                            T_SI <= tmpD(i);
                            WAIT FOR 2*half_period;
                        END LOOP;
                        T_SI <= tmpD(0);
                        data_tmp1 := data_tmp1 + 1;
                        tmpD := to_slv(data_tmp1, 8);
                    END LOOP;
                END IF;

        END CASE;

    END PROCEDURE;

   ----------------------------------------------------------------------------
    --procedure to decode commands into specific bus command sequence
    ---------------------------------------------------------------------------
    PROCEDURE cmd_dc
        (   command  :   IN  cmd_rec   )

    IS

        VARIABLE slv_1, slv_2 : std_logic_vector(7 downto 0);
        VARIABLE slv_3        : std_logic_vector(15 downto 0);
        VARIABLE opcode_tmp   : std_logic_vector(7 downto 0);
        VARIABLE Data_byte    : INTEGER RANGE 0 TO 16#FFFF#  := 0;
        VARIABLE Byte_number  : NATURAL RANGE 0 TO 600;
        VARIABLE cnt          : NATURAL RANGE 0 TO 512;
        VARIABLE pgm_page     : NATURAL;
        VARIABLE page_addr    : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE AddrLow      : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE ADDR         : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE addr_tmp     : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE AddrHigh     : NATURAL RANGE 0 TO AddrRANGE;
        VARIABLE SECTOR       : NATURAL RANGE 0 TO 519;
        VARIABLE BLOCK_E      : NATURAL RANGE 0 TO 135;
        VARIABLE BP_bits      : std_logic_vector(2 downto 0) := "000";
        VARIABLE tmp          : NATURAL;
        VARIABLE tmp_byte_num : NATURAL;
        VARIABLE pass_tmp     : std_logic_vector(63 downto 0);
        VARIABLE sec_tmp      : NATURAL RANGE 0 TO 541;
    BEGIN

        half_period := half_period1_srl;

        CASE command.cmd IS

            WHEN    idle        =>

                bus_cycle(bus_cmd => bus_idle,
                          PowerUp => command.aux=PowerUp,
                          protect => command.aux=violate);

            WHEN    w_enable    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WREN,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WEL := '1';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    w_disable    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRDI,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WEL := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    mbr    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_MBR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                WAIT FOR 9*half_period ;

            WHEN    reset_en    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RSTEN,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                WAIT FOR 9*half_period ;

            WHEN    rst    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RST,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN

                    SR1_V(7 DOWNTO 5) := SR1_NV(7 DOWNTO 5);
                    SR1_V(1 DOWNTO 0) := SR1_NV(1 DOWNTO 0);

                    CR1_V(7 DOWNTO 1) := CR1_NV(7 DOWNTO 1);

                    CR2_V := CR2_NV;
                    CR3_V := CR3_NV;
                    CR4_V := CR4_NV;

                    VDLR_reg  := NVDLR_reg;

                    IF CR3_V(4) = '1' THEN
                        PageSize <= 512;
                        PageNum <= PageNum512;
                    ELSE
                        PageSize <= 256;
                        PageNum <= PageNum256;
                    END IF;

                    IF FREEZE = '0' THEN

                        SR1_V(4 DOWNTO 2) := SR1_NV(4 DOWNTO 2);
                        BP_bits := SR2_V(4) & SR2_V(3) & SR2_V(2);

                        BlockProtect(Sec_Prot,Block_Prot,BP_bits);

                    END IF;
                END IF;
                WAIT for 50 ns;

            WHEN    reset_cmd    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RESET,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN

                    SR1_V(7 DOWNTO 5) := SR1_NV(7 DOWNTO 5);
                    SR1_V(1 DOWNTO 0) := SR1_NV(1 DOWNTO 0);

                    CR1_V(7 DOWNTO 1) := CR1_NV(7 DOWNTO 1);

                    CR2_V := CR2_NV;
                    CR3_V := CR3_NV;
                    CR4_V := CR4_NV;

                    VDLR_reg  := NVDLR_reg;

                    IF CR3_V(4) = '1' THEN
                        PageSize <= 512;
                        PageNum <= PageNum512;
                    ELSE
                        PageSize <= 256;
                        PageNum <= PageNum256;
                    END IF;

                    IF FREEZE = '0' THEN

                        SR1_V(4 DOWNTO 2) := SR1_NV(4 DOWNTO 2);
                        BP_bits := SR2_V(4) & SR2_V(3) & SR2_V(2);
                        BlockProtect(Sec_Prot,Block_Prot,BP_bits);
                    END IF;
                END IF;
                WAIT for 50 ns;

            WHEN    bam4   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BAM4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    CR2_V(7) := '1';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    ees   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EES,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_EES,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status = chk_sts_1 THEN
                    SR2_V(2) := '1';
                ELSIF status = chk_sts_0 THEN
                    SR2_V(2) := '0';
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    set_bl   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_SBL,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          opcode   => I_SBL,
                          data_num => command.byte_num,
                          data1    => command.data1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    Data_byte :=  command.data1;
                    slv_1 := to_slv(Data_byte,8);
                    CR4_V(4)          := slv_1(4);
                    CR4_V(1 DOWNTO 0) := slv_1(1 DOWNTO 0);
                END IF;

                WAIT FOR 9*half_period ;

            WHEN    h_reset         =>

                bus_cycle(bus_cmd => bus_reset,
                          data_num=> 1,
                          tm      => command.wtime);

                SR1_V(7 DOWNTO 5) := SR1_NV(7 DOWNTO 5);
                SR1_V(1 DOWNTO 0) := SR1_NV(1 DOWNTO 0);

                CR1_V := CR1_NV;
                CR2_V := CR2_NV;
                CR3_V := CR3_NV;
                CR4_V := CR4_NV;

                IF CR3_V(4) = '1' THEN
                    PageSize <= 512;
                    PageNum <= PageNum512;
                ELSE
                    PageSize <= 256;
                    PageNum <= PageNum256;
                END IF;

                VDLR_reg  := NVDLR_reg;

                IF PWDMLB = '0' THEN
                    PPB_LOCK := '0';
                ELSE
                    PPB_LOCK := '1';
                END IF;

                SR1_V(4 DOWNTO 2) := SR1_NV(4 DOWNTO 2);
                BP_bits := SR2_V(4) & SR2_V(3) & SR2_V(2);
                BlockProtect(Sec_Prot,Block_Prot,BP_bits);

                WAIT for 50 ns;

            WHEN    w_sr         =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_WRR,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_deselect);

                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);
                WIP := '1';

                IF status /= err AND WEL = '1' THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN

                        SRWD_NV   := slv_1 (7);
                        SRWD      := slv_1 (7);

                        IF (LOCK_O='0' AND SECURE_OPN) OR NOT(SECURE_OPN) THEN
                            IF FREEZE ='0' THEN
                                IF BPNV_O ='0' THEN
                                    BP2_NV := slv_1 (4);
                                    BP1_NV := slv_1 (3);
                                    BP0_NV := slv_1 (2);

                                    BP2    := slv_1 (4);
                                    BP1    := slv_1 (3);
                                    BP0    := slv_1 (2);
                                ELSE
                                    BP2    := slv_1 (4);
                                    BP1    := slv_1 (3);
                                    BP0    := slv_1 (2);
                                END IF;

                                BP_bits := BP2 & BP1 & BP0;
                            END IF;
                        END IF;

                        BlockProtect(Sec_Prot,Block_Prot,BP_bits);

                    END IF;
                    WEL := '0';
                    WIP := '0';
                END IF;

            WHEN    wrar         =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_WRAR,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_WRAR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_deselect);

                SECTOR := command.sect;
                ADDR   := command.addr;
                addr_tmp := ReturnAddr(ADDR,SECTOR, CR3_V(3), TBPARM_O);

                Data_byte :=  command.data1;
                slv_1     := to_slv(Data_byte,8);
                WIP       := '1';

                IF status /= err AND WEL = '1' THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN
                        IF addr_tmp = 16#00000000# THEN
                            SRWD_NV   := slv_1 (7);
                            SRWD      := slv_1 (7);

                            IF (LOCK_O = '0' AND SECURE_OPN) OR
                                NOT(SECURE_OPN) THEN
                                IF FREEZE ='0' THEN
                                    IF BPNV_O ='0' THEN
                                        BP2_NV := slv_1 (4);
                                        BP1_NV := slv_1 (3);
                                        BP0_NV := slv_1 (2);

                                        BP2    := slv_1 (4);
                                        BP1    := slv_1 (3);
                                        BP0    := slv_1 (2);
                                    END IF;

                                    BP_bits := BP2 & BP1 & BP0;
                                END IF;
                            END IF;

                            BlockProtect(Sec_Prot,Block_Prot,BP_bits);

                        ELSIF addr_tmp = 16#00000002# THEN
                            IF TBPROT_O = '0' THEN
                                TBPROT_O  := slv_1 (5);
                                TBPROT    := slv_1 (5);
                            END IF;

                            IF BPNV_O = '0' THEN
                                BPNV_O  := slv_1 (3);
                                BPNV    := slv_1 (3);
                            END IF;

                            IF (TBPARM_O = '0' AND CR3_V(3) = '0') THEN
                                TBPARM_O  := slv_1 (2);
                                TBPARM    := slv_1 (2);
                            END IF;

                            IF QUAD_ALL = '0' THEN
                                QUAD_NV := slv_1(1);
                                QUAD    := slv_1(1);
                            END IF;

                            IF SECURE_OPN AND LOCK_O = '0' THEN
                                LOCK_O  := slv_3(4);
                                LOCK    := slv_3(4);
                            END IF;
                        ELSIF addr_tmp = 16#00000003# THEN

                            IF CR2_NV(7) = '0' THEN
                                CR2_NV(7) := slv_1(7);
                                CR2_V(7)  := slv_1(7);
                            END IF;

                            IF CR2_NV(6) = '0'  AND slv_1(6) = '1' THEN
                                QUAD_ALL_NV := slv_1(6);
                                QUAD_ALL    := slv_1(6);

                                QUAD_NV := '1';
                                QUAD    := '1';
                            END IF;

                            IF CR2_NV(5) = '0' THEN
                                CR2_NV(5) := slv_1(5);
                                CR2_V(5)  := slv_1(5);
                            END IF;

                            IF CR2_NV(3 DOWNTO 0) = "1000" THEN
                                CR2_NV(3 DOWNTO 0) := slv_1(3 DOWNTO 0);
                                CR2_V(3 DOWNTO 0)  := slv_1(3 DOWNTO 0);
                            END IF;

                        ELSIF addr_tmp = 16#00000004# THEN

                            IF CR3_NV(5) = '0' THEN
                                CR3_NV(5) := slv_1(5);
                                CR3_V(5)  := slv_1(5);
                            END IF;

                            IF CR3_NV(4) = '0' THEN
                                CR3_NV(4) := slv_1(4);
                                CR3_V(4)  := slv_1(4);
                            END IF;

                            IF CR3_NV(3) = '0' THEN
                                CR3_NV(3) := slv_1(3);
                                CR3_V(3)  := slv_1(3);
                            END IF;

                            IF CR3_NV(2) = '0' THEN
                                CR3_NV(2) := slv_1(2);
                                CR3_V(2)  := slv_1(2);
                            END IF;

                            IF CR3_NV(1) = '0' THEN
                                CR3_NV(1) := slv_1(1);
                                CR3_V(1)  := slv_1(1);
                            END IF;

                            IF CR3_NV(0) = '0' THEN
                                CR3_NV(0) := slv_1(0);
                                CR3_V(0)  := slv_1(0);
                            END IF;

                            IF CR3_V(4) = '1' THEN
                                PageSize <= 512;
                                PageNum <= PageNum512;
                            ELSE
                                PageSize <= 256;
                                PageNum <= PageNum256;
                            END IF;

                        ELSIF addr_tmp = 16#00000005# THEN

                            IF CR4_NV(7 DOWNTO 5) = "000" THEN
                                CR4_NV(7 DOWNTO 5) := slv_1(7 DOWNTO 5);
                                CR4_V(7 DOWNTO 5)  := slv_1(7 DOWNTO 5);
                            END IF;

                            IF CR4_NV(4) = '0' THEN
                                CR4_NV(4) := slv_1(4);
                                CR4_V(4)  := slv_1(4);
                            END IF;

                            IF CR4_NV(1 DOWNTO 0) = "000" THEN
                                CR4_NV(1 DOWNTO 0) := slv_1(1 DOWNTO 0);
                                CR4_V(1 DOWNTO 0)  := slv_1(1 DOWNTO 0);
                            END IF;

                        ELSIF addr_tmp = 16#00000010# THEN
                            slv_1 := to_slv(Data_byte,8);
                            IF to_nat(NVDLR_reg) > -1 THEN
                                slv_2 := NVDLR_reg;
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            IF slv_2(7 DOWNTO 0) /= "XXXXXXXX" THEN
                                NVDLR_reg := slv_1;
                                VDLR_reg  := slv_1;
                            END IF;

                        ELSIF addr_tmp = 16#00000020# THEN
                            Password_reg(7 DOWNTO 0) := slv_1;
                        ELSIF addr_tmp = 16#00000021# THEN
                            Password_reg(15 DOWNTO 8) := slv_1;
                        ELSIF addr_tmp = 16#00000022# THEN
                            Password_reg(23 DOWNTO 16) := slv_1;
                        ELSIF addr_tmp = 16#00000023# THEN
                            Password_reg(31 DOWNTO 24) := slv_1;
                        ELSIF addr_tmp = 16#00000024# THEN
                            Password_reg(39 DOWNTO 32) := slv_1;
                        ELSIF addr_tmp = 16#00000025# THEN
                            Password_reg(47 DOWNTO 40) := slv_1;
                        ELSIF addr_tmp = 16#00000026# THEN
                            Password_reg(55 DOWNTO 48) := slv_1;
                        ELSIF addr_tmp = 16#00000027# THEN
                            Password_reg(63 DOWNTO 56) := slv_1;
                        ELSIF addr_tmp = 16#00000030# THEN

                            IF DYBLBB = '1' AND SECURE_OPN THEN
                                DYBLBB := slv_1(4);
                            END IF;

                            IF PPBOTP = '1' AND SECURE_OPN THEN
                                PPBOTP    := slv_1(3);
                            END IF;

                            IF PERMLB = '1' AND SECURE_OPN THEN
                                PERMLB    := slv_1(0);
                            END IF;

                            IF (slv_1(2) = '0' AND slv_1(1) = '0') THEN
                                P_ERR := '1';
                                WIP   := '1';
                            ELSE
                                PWDMLB    := slv_1(2);
                                PSTMLB    := slv_1(1);
                            END IF;

                        ELSIF addr_tmp = 16#00800000# THEN

                            SRWD      := slv_1 (7);

                            IF (LOCK_O = '0' AND SECURE_OPN) OR
                                NOT(SECURE_OPN) THEN
                                IF FREEZE ='0' THEN
                                    IF BPNV_O ='1' THEN
                                        BP2    := slv_1 (4);
                                        BP1    := slv_1 (3);
                                        BP0    := slv_1 (2);
                                    END IF;

                                    BP_bits := BP2 & BP1 & BP0;
                                END IF;
                            END IF;

                            BlockProtect(Sec_Prot,Block_Prot,BP_bits);

                        ELSIF addr_tmp = 16#00800002# THEN

                            IF QUAD_ALL = '0' THEN
                                QUAD    := slv_1(1);
                            END IF;

                            IF FREEZE = '0' THEN
                                FREEZE    := slv_1(0);
                            END IF;

                        ELSIF addr_tmp = 16#00800003# THEN

                            CR2_V(7)  := slv_1(7);
                            QUAD_ALL    := slv_1(6);
                            IF slv_1(6) = '1' THEN
                                QUAD    := '1';
                            END IF;
                            CR2_V(5)  := slv_1(5);
                            CR2_V(3 DOWNTO 0)  := slv_1(3 DOWNTO 0);

                        ELSIF addr_tmp = 16#00800004# THEN

                            CR3_V(5)  := slv_1(5);
                            CR3_V(4)  := slv_1(4);
                            CR3_V(3)  := slv_1(3);
                            CR3_V(2)  := slv_1(2);
                            CR3_V(1)  := slv_1(1);
                            CR3_V(0)  := slv_1(0);

                            IF CR3_V(4) = '1' THEN
                                PageSize <= 512;
                                PageNum <= PageNum512;
                            ELSE
                                PageSize <= 256;
                                PageNum <= PageNum256;
                            END IF;

                        ELSIF addr_tmp = 16#00800005# THEN

                            CR4_V(7 DOWNTO 5)  := slv_1(7 DOWNTO 5);
                            CR4_V(4)           := slv_1(4);
                            CR4_V(1 DOWNTO 0)  := slv_1(1 DOWNTO 0);

                        ELSIF addr_tmp = 16#00800010# THEN
                            slv_1 := to_slv(Data_byte,8);
                            VDLR_reg  := slv_1;
                        END IF;
                    END IF;
                    WEL := '0';
                    WIP := '0';
                END IF;

            WHEN    rdar_read       =>

                bus_cycle(bus_cmd  => bus_select);

                bus_cycle(bus_cmd  => bus_opcode,
                          opcode   => I_RDAR,
                          pulse    => false,
                          tm       => command.wtime);

                bus_cycle(bus_cmd  => bus_address,
                          opcode   => I_RDAR,
                          address  => command.addr,
                          sector   => command.sect,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDAR,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_read,
                          opcode   => I_RDAR,
                          data_num => command.byte_num,
                          pulse    => command.aux=clock_num,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    rd_sr1       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDSR1,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDSR1,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    rd_sr2       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDSR2,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDSR2,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    clr_sr       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_CLSR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err  THEN
                    E_ERR := '0';
                    P_ERR := '0';
                    WIP   := '0';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    w_scr        =>

                WIP := '1';
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_WRR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd  => bus_data_write,
                          opcode   => I_WRR,
                          data1    => command.data1,
                          data_num => 1,
                          tm       => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                Data_byte :=  command.data1;
                slv_3 := to_slv(Data_byte,16);

                WAIT FOR 22*half_period ;

                IF status /= err AND WEL = '1' THEN
                    IF NOT(SRWD = '1' AND T_WPNeg='0') THEN

                        SRWD_NV   := slv_3 (15);
                        SRWD      := slv_3 (15);

                        IF (LOCK_O='0' AND SECURE_OPN) OR NOT(SECURE_OPN) THEN
                            IF FREEZE ='0' THEN
                                IF BPNV_O ='0' THEN
                                    BP2_NV := slv_3 (12);
                                    BP1_NV := slv_3 (11);
                                    BP0_NV := slv_3 (10);

                                    BP2    := slv_3 (12);
                                    BP1    := slv_3 (11);
                                    BP0    := slv_3 (10);
                                ELSE
                                    BP2    := slv_3 (12);
                                    BP1    := slv_3 (11);
                                    BP0    := slv_3 (10);
                                END IF;

                                BP_bits := BP2 & BP1 & BP0;

                                IF TBPROT_O = '0' THEN
                                    TBPROT_O  := slv_3 (5);
                                    TBPROT    := slv_3 (5);
                                END IF;

                                IF BPNV_O = '0' THEN
                                    BPNV_O  := slv_3 (3);
                                    BPNV    := slv_3 (3);
                                END IF;

                                IF (TBPARM_O = '0' AND CR3_V(3) = '0') THEN
                                    TBPARM_O  := slv_3 (2);
                                    TBPARM    := slv_3 (2);
                                END IF;
                            END IF;
                        END IF;

                        IF QUAD_ALL = '0' THEN
                            QUAD_NV := slv_3(1);
                            QUAD    := slv_3(1);
                        END IF;

                        IF FREEZE = '0' THEN
                            FREEZE    := slv_3(0);
                        END IF;

                        IF SECURE_OPN AND LOCK_O = '0' THEN
                            LOCK_O  := slv_3(4);
                            LOCK    := slv_3(4);
                        END IF;

                        BlockProtect(Sec_Prot,Block_Prot,BP_bits);
                    END IF;
                    WEL := '0';
                    WIP := '0';
                END IF;

            WHEN    rd_scr       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDCR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDCR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    rd_dlp       =>

                half_period := half_period2_srl;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DLPRD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DLPRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    rd           =>

                half_period := half_period2_srl;

                IF command.aux = violate THEN
                    half_period := 10 ns;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_READ,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_READ,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_READ,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 5 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    rd_4           =>

                half_period := half_period2_srl;

                IF command.aux = violate THEN
                    half_period := 10 ns;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_READ4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_READ4,
                          data1   => command.data1,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_READ4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 5 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    fast_rd      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_FAST_READ,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_FAST_READ,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_FAST_READ,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_FAST_READ,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    fast_rd4       =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_FAST_READ4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_FAST_READ4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_FAST_READ4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_FAST_READ4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dual_high_rd      =>

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_dualIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_DIOR,
                            pulse   => false,
                            tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dual_high_rd_4      =>

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_dualIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_DIOR4,
                            pulse   => false,
                            tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_rd      =>

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_RDQIOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RDQIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_RDQIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDQIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_RDQIOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_rd_4      =>

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_quadIO4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_RDQIOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RDQIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_RDQIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_RDQIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_RDQIOR4);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_ddr_rd      =>
                --The maximum operating clock frequency for Quad I/O
                --DDR Read mode is 80 MHz
                half_period := half_period_ddr;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_qddr THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_DDRQIOR,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DDRQIOR,
                          address => command.addr,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DDRQIOR,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DDRQIOR,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DDRQIOR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;

                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_DDRQIOR);

                WAIT FOR 22*half_period ;

            WHEN    quad_high_ddr_rd_4      =>
                --The maximum operating clock frequency for Quad I/O
                --DDR Read mode is 80 MHz
                half_period := half_period_ddr;

                bus_cycle(bus_cmd => bus_select);

                IF command.status /= rd_cont_qddr4 THEN

                    bus_cycle(bus_cmd => bus_opcode,
                              opcode  => I_DDRQIOR4,
                              pulse   => false,
                              tm      => command.wtime);
                END IF;

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DDRQIOR4,
                          address => command.addr,
                          data1   => command.data1,
                          sector  => command.sect,
                          break   => command.aux=break,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_mode_byte,
                          opcode  => I_DDRQIOR4,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_DDRQIOR4,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    half_period := 4 ns;
                END IF;

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DDRQIOR4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                IF command.aux = violate THEN
                    WAIT FOR 7 ns;
                END IF;
                bus_cycle(bus_cmd => bus_desel_read,
                          opcode  => I_DDRQIOR4);

                WAIT FOR 22*half_period ;

            WHEN    read_JID       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    read_JQID       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RDQID,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RDQID,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 9*half_period ;

            WHEN    read_SFDP      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RSFDP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_RSFDP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_RSFDP,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_RSFDP,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    sector_erase  | p4_erase =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                BLOCK_E := ReturnBlockID(SECTOR, CR3_V(3), TBPARM_O);

                IF command.cmd = sector_erase THEN
                    opcode_tmp      := I_SE;
                    PARAMETER_ERASE <= FALSE;
                ELSIF command.cmd = p4_erase THEN
                    opcode_tmp      := I_P4E;
                    PARAMETER_ERASE <= TRUE;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
					IF CR3_V(1) = '0' THEN
						IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
							PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
							WIP := '1';
							sesa(AddrLow,AddrHigh,SECTOR);
							FOR i IN AddrLow TO AddrHigh LOOP
								mem(i) := 16#FF#;
							END LOOP;
							E_ERR := '0';
							WEL := '0';
							WIP := '0';
						ELSE
							E_ERR := '1';
							WIP   := '1';
						END IF;
					ELSE
						IF (Block_Prot(BLOCK_E) /= '1' AND WEL = '1' AND
							PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
							WIP := '1';
							seba(AddrLow,AddrHigh,BLOCK_E);
							FOR i IN AddrLow TO AddrHigh LOOP
								mem(i) := 16#FF#;
							END LOOP;
							E_ERR := '0';
							WEL := '0';
							WIP := '0';
						ELSE
							E_ERR := '1';
							WIP   := '1';
						END IF;
					END IF;
                ELSE
                    WEL := '0';
                END IF;

            WHEN    sector_erase_4  | p4_erase_4  =>

                SECTOR := command.sect;
                ADDR := command.addr;
                BLOCK_E := ReturnBlockID(SECTOR, CR3_V(3), TBPARM_O);

                IF command.cmd = sector_erase_4 THEN
                    opcode_tmp      := I_SE4;
                    PARAMETER_ERASE <= FALSE;
                ELSIF command.cmd = p4_erase_4 THEN
                    opcode_tmp      := I_P4E4;
                    PARAMETER_ERASE <= TRUE;
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => opcode_tmp,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => opcode_tmp,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
					IF CR3_V(1) = '0' THEN
						IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
							PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
							WIP := '1';
							sesa(AddrLow,AddrHigh,SECTOR);
							FOR i IN AddrLow TO AddrHigh LOOP
								mem(i) := 16#FF#;
							END LOOP;
							E_ERR := '0';
							WEL := '0';
							WIP := '0';
						ELSE
							E_ERR := '1';
							WIP   := '1';
						END IF;
					ELSE
						IF (Block_Prot(BLOCK_E) /= '1' AND WEL = '1' AND
							PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
							WIP := '1';
							seba(AddrLow,AddrHigh,BLOCK_E);
							FOR i IN AddrLow TO AddrHigh LOOP
								mem(i) := 16#FF#;
							END LOOP;
							E_ERR := '0';
							WEL := '0';
							WIP := '0';
						ELSE
							E_ERR := '1';
							WIP   := '1';
						END IF;
					END IF;
                ELSE
                    WEL := '0';
                END IF;

            WHEN    bulk_erase_60 =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BE_60,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    IF (BP0 = '0' AND BP1 = '0' AND BP2 = '0') THEN
                        WIP := '1';
                        FOR i IN 0 TO ADDRRange LOOP
                            -- Sector ID calculation
                            IF CR3_V(3) = '0' THEN
                                sec_tmp := i / (SecSize64+1);
                                IF TBPARM_O = '0' THEN
                                    IF sec_tmp = 0 THEN
                                        IF i <= (8*(SecSize4+1) - 1) THEN
                                            SECTOR := i/(SecSize4+1);
                                        ELSE
                                            SECTOR := 8;
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp + 8;
                                    END IF;
                                ELSE
                                    IF sec_tmp = 511 THEN
                                        IF i < (AddrRANGE + 1 -
                                                            8*(SecSize4+1)) THEN
                                            SECTOR := 511;
                                        ELSE
                                            SECTOR := 512 + (i -
                                             (AddrRANGE + 1 - 8*(SecSize4+1))) /
                                             (SecSize4+1);
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp;
                                    END IF;
                                END IF;
                            ELSE
                                SECTOR := i/(SecSize64+1);
                            END IF;

                            IF PPB_bits(SECTOR)='1' AND
                               DYB_bits(SECTOR)='1' THEN
                                mem(i) := 16#FF#;
                            END IF;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WIP   := '0';
                    ELSE
                        WEL := '0';
                        WIP := '0';
                    END IF;
                END IF;

            WHEN    bulk_erase_C7 =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_BE_C7,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    IF (BP0 = '0' AND BP1 = '0' AND BP2 = '0') THEN
                        WIP := '1';
                        FOR i IN 0 TO ADDRRange LOOP
                            -- Sector ID calculation
                            IF CR3_V(3) = '0' THEN
                                sec_tmp := i / (SecSize64+1);
                                IF TBPARM_O = '0' THEN
                                    IF sec_tmp = 0 THEN
                                        IF i <= (8*(SecSize4+1) - 1) THEN
                                            SECTOR := i/(SecSize4+1);
                                        ELSE
                                            SECTOR := 8;
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp + 8;
                                    END IF;
                                ELSE
                                    IF sec_tmp = 511 THEN
                                        IF i < (AddrRANGE + 1 -
                                                            8*(SecSize4+1)) THEN
                                            SECTOR := 511;
                                        ELSE
                                            SECTOR := 512 + (i -
                                             (AddrRANGE + 1 - 8*(SecSize4+1))) /
                                             (SecSize4+1);
                                        END IF;
                                    ELSE
                                        SECTOR := sec_tmp;
                                    END IF;
                                END IF;
                            ELSE
                                SECTOR := i/(SecSize64+1);
                            END IF;

                            IF PPB_bits(SECTOR)='1' AND
                               DYB_bits(SECTOR)='1' THEN
                                mem(i) := 16#FF#;
                            END IF;
                        END LOOP;
                        E_ERR := '0';
                        WEL   := '0';
                        WIP   := '0';
                    ELSE
                        WEL := '0';
                        WIP := '0';
                    END IF;
                END IF;

            WHEN     ers_susp_b0        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_B0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_susp_75        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_75,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_susp_85        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_85,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    ES  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     ers_resume_7a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_7A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    ES  := '0' ;
                END IF;

            WHEN     ers_resume_8a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_8A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    ES  := '0' ;
                END IF;

            WHEN    res_dpd   =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_RES_DPD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

            WHEN     dp_down    =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DPD,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

            WHEN    pg_prog      =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                sepa(AddrLow,AddrHigh,SECTOR,ADDR);
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PP,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        --if more than PageSize are sent to the device
                        IF Byte_number > PageSize THEN
                            Data_byte := Data_byte + (Byte_number-PageSize);
                            Byte_number := PageSize;
                        END IF;
                        page_addr := ReturnAddr(ADDR,SECTOR,CR3_V(3),TBPARM_O);
                        cnt := 0;

                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            --page program
                            slv_1 := to_slv(Data_byte,8);

                            IF mem(page_addr+i-cnt)>-1 THEN
                                slv_2 := to_slv(mem(page_addr+i-cnt),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            mem(page_addr + i - cnt) := to_nat(slv_1);

                            IF page_addr + i - cnt = AddrHigh THEN
                                cnt := i+1;
                                page_addr := AddrLow;
                            END IF;
                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                        P_ERR := '0';
                        IF ES = '0' THEN
                            WEL := '0';
                        END IF;
                        WIP := '0';
                    ELSE
                        P_ERR := '1';
                        WIP := '1';
                    END IF;
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    pg_prog4      =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                sepa(AddrLow,AddrHigh,SECTOR,ADDR);
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PP4,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PP4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PP4,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF (Sec_Prot(SECTOR) /= '1' AND WEL = '1' AND
                        PPB_bits(SECTOR)='1' AND DYB_bits(SECTOR)='1') THEN
                        WIP := '1';
                        --if more than PageSize are sent to the device
                        IF Byte_number > PageSize THEN
                            Data_byte := Data_byte + (Byte_number-PageSize);
                            Byte_number := PageSize;
                        END IF;
                        page_addr := ReturnAddr(ADDR,SECTOR,CR3_V(3),TBPARM_O);
                        cnt := 0;

                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            --page program
                            slv_1 := to_slv(Data_byte,8);

                            IF mem(page_addr+i-cnt)>-1 THEN
                                slv_2 := to_slv(mem(page_addr+i-cnt),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            mem(page_addr + i - cnt) := to_nat(slv_1);

                            IF page_addr + i - cnt = AddrHigh THEN
                                cnt := i+1;
                                page_addr := AddrLow;
                            END IF;
                            IF Data_byte = 511 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                        P_ERR := '0';
                        WEL   := '0';
                        WIP   := '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN     prg_susp_b0        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_B0,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_susp_75        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_75,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_susp_85        =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPS_85,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '0' ;
                    PS  := '1' ;
                END IF;
                WAIT FOR 22*half_period ;

            WHEN     prg_resume_7a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_7A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    PS  := '0' ;
                END IF;

            WHEN     prg_resume_8a      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_EPR_8A,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    WIP := '1' ;
                    PS  := '0' ;
                END IF;

            WHEN    otp_prog      =>

                ADDR        := command.addr;
                Data_byte   := command.data1;
                Byte_number := command.byte_num;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_OTPP,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_OTPP,
                          address => command.addr,
                          sector  => 0,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_OTPP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                LOCK_BYTE1 := to_slv(Otp(16#10#),8);
                LOCK_BYTE2 := to_slv(Otp(16#11#),8);
                LOCK_BYTE3 := to_slv(Otp(16#12#),8);
                LOCK_BYTE4 := to_slv(Otp(16#13#),8);

                IF status /= err AND WEL = '1' AND FREEZE = '0' THEN
                    WIP := '1';
                    IF ADDR + (Byte_number - 1) <= OTPHiAddr THEN
                        FOR i IN 0 TO  Byte_number - 1 LOOP
                            slv_1 := to_slv(Data_byte,8);

                            IF Otp(ADDR + i)>-1 THEN
                                slv_2 := to_slv(Otp(ADDR + i),8);
                            ELSE
                                slv_2 := (OTHERS=>'X');
                            END IF;

                            FOR j IN 0 to 7 LOOP
                                --changing bits from 1 to 0
                                IF slv_2(j)='0' THEN
                                    slv_1(j):='0';
                                END IF;
                            END LOOP;

                            Otp(ADDR + i) := to_nat(slv_1);

                            IF Data_byte = 255 THEN
                                Data_byte := 0;
                            ELSE
                                Data_byte := Data_byte + 1;
                            END IF;
                        END LOOP;
                    ELSE
                        ASSERT false
                            REPORT "Programming will reach over address "&
                            " limit of OTP array"
                            SEVERITY warning;
                    END IF;
                    P_ERR := '0';
                    WEL   := '0';
                    WIP   := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

            WHEN    otp_read      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_OTPR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_OTPR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_byte,
                          opcode  => I_OTPR,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_OTPR,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_nvldr      =>
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_PNVDLR,
                            pulse   => command.aux=clock_num,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                            opcode  => I_PNVDLR,
                            data_num=> command.byte_num,
                            data1   => command.data1,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    slv_1 := to_slv(Data_byte,8);
                    IF to_nat(NVDLR_reg) > -1 THEN
                        slv_2 := NVDLR_reg;
                    ELSE
                        slv_2 := (OTHERS=>'X');
                    END IF;

                    IF slv_2(7 DOWNTO 0) /= "XXXXXXXX" THEN
                        NVDLR_reg := slv_1;
                        VDLR_reg  := slv_1;
                    END IF;

                    WEL := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_wvdlr      =>
                Byte_number := command.byte_num;
                Data_byte   := command.data1;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                            opcode  => I_WVDLR,
                            pulse   => command.aux=clock_num,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                            opcode  => I_WVDLR,
                            data_num=> command.byte_num,
                            data1   => command.data1,
                            tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    slv_1 := to_slv(Data_byte,8);
                    VDLR_reg  := slv_1;
                    WEL := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    asp_reg_rd      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ASPRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_ASPRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_asp      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ASPP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_ASPP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' AND (PWDMLB = '1' AND
                   PSTMLB = '1') THEN

                    slv_3 := to_slv(command.data1, 16);

                    IF DYBLBB = '1' AND SECURE_OPN THEN
                        DYBLBB := slv_3(4);
                    END IF;

                    IF PPBOTP = '1' AND SECURE_OPN THEN
                        PPBOTP    := slv_3(3);
                    END IF;

                    IF PERMLB = '1' AND SECURE_OPN THEN
                        PERMLB    := slv_3(0);
                    END IF;

                    IF (slv_3(2) = '0' AND slv_3(1) = '0') THEN
                        P_ERR := '1';
                        WIP   := '1';
                    ELSE
                        PWDMLB    := slv_3(2);
                        PSTMLB    := slv_3(1);
                    END IF;

                    WIP := '0';
                    WEL := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    pass_reg_rd      =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PASSRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          break   => command.aux=violate,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_password      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSP,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PASSP,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          data3   => command.data3,
                          data4   => command.data4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' THEN
                    Password_reg := to_slv(command.data4, 16)&
                                    to_slv(command.data3, 16)&
                                    to_slv(command.data2, 16)&
                                    to_slv(command.data1, 16);
                    WIP := '0';
                    WEL := '0';
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    psw_unlock      =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PASSU,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_PASSU,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          data2   => command.data2,
                          data3   => command.data3,
                          data4   => command.data4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err THEN
                    Pass_tmp := to_slv(command.data4, 16)&
                                to_slv(command.data3, 16)&
                                to_slv(command.data2, 16)&
                                to_slv(command.data1, 16);
                    IF Pass_tmp = Password_reg  AND PWDMLB = '0' THEN
                        PPB_LOCK := '1';
                        WEL      := '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                ELSE
                    WIP   := '1';
                    P_ERR := '1';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    ppbl_reg_rd       =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PLBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PLBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_ppbl_reg       =>

                WIP := '1';

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PLBWR,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                IF status /= err AND WEL = '1' THEN
                    PPB_LOCK := '0';
                    WIP  := '0';
                    WEL  := '0';
                END IF;

                WAIT FOR 22*half_period ;

            WHEN    ppbacc_rd       =>

                SECTOR := command.sect;
                IF PPB_bits(SECTOR) = '1' THEN
                    PPBAR(7 downto 0) := "11111111";
                ELSE
                    PPBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PPBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    ppbacc_rd4       =>

                SECTOR := command.sect;
                IF PPB_bits(SECTOR) = '1' THEN
                    PPBAR(7 downto 0) := "11111111";
                ELSE
                    PPBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_PPBRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    w_ppb  =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBP,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBP,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits(SECTOR):= '0';
                    P_ERR := '0';
                    WEL := '0';
                    WIP := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    w_ppb4  =>

                SECTOR := command.sect;
                ADDR   := command.addr;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBP4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_PPBP4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits(SECTOR):= '0';
                    P_ERR := '0';
                    WEL := '0';
                    WIP := '0';
                ELSE
                    P_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    ppb_ers  =>

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_PPBERS,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    PPB_bits:= (OTHERS => '1');
                    WEL   := '0';
                ELSE
                    E_ERR := '1';
                    WIP   := '1';
                END IF;

            WHEN    dybacc_rd       =>

                SECTOR := command.sect;
                IF DYB_bits(SECTOR) = '1' THEN
                    DYBAR(7 downto 0) := "11111111";
                ELSE
                    DYBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DYBRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    dybacc_rd4       =>

                SECTOR := command.sect;
                IF DYB_bits(SECTOR) = '1' THEN
                    DYBAR(7 downto 0) := "11111111";
                ELSE
                    DYBAR(7 downto 0) := "00000000";
                END IF;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_DYBRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

                WAIT FOR 22*half_period ;

            WHEN    w_dyb  =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBWR,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBWR,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_DYBWR,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    DYBAR := slv_1;
                    IF DYBAR = "11111111" THEN
                        DYB_bits(SECTOR):= '1';
                    ELSIF DYBAR = "00000000" THEN
                        DYB_bits(SECTOR):= '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                    WIP  := '0';
                    WEL  := '0';
                END IF;

            WHEN    w_dyb4  =>

                SECTOR := command.sect;
                ADDR   := command.addr;
                Data_byte :=  command.data1;
                slv_1 := to_slv(Data_byte,8);

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_DYBWR4,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_DYBWR4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_write,
                          opcode  => I_DYBWR4,
                          data_num=> command.byte_num,
                          data1   => command.data1,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err AND WEL = '1' THEN
                    DYBAR := slv_1;
                    IF DYBAR = "11111111" THEN
                        DYB_bits(SECTOR):= '1';
                    ELSIF DYBAR = "00000000" THEN
                        DYB_bits(SECTOR):= '0';
                    ELSE
                        P_ERR := '1';
                        WIP   := '1';
                    END IF;
                    WIP  := '0';
                    WEL  := '0';
                END IF;

            WHEN    ecc_read       =>

                SECTOR := command.sect;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ECCRD,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_ECCRD,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_ECCRD,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_ECCRD,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    ecc_read4       =>

                SECTOR := command.sect;

                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_opcode,
                          opcode  => I_ECCRD4,
                          pulse   => false,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_address,
                          opcode  => I_ECCRD4,
                          address => command.addr,
                          sector  => command.sect,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_dummy_clock,
                          opcode  => I_ECCRD4,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_data_read,
                          opcode  => I_ECCRD4,
                          data_num=> command.byte_num,
                          pulse   => command.aux=clock_num,
                          tm      => command.wtime);

                bus_cycle(bus_cmd => bus_desel_read);

            WHEN    wt          =>
                WAIT FOR command.wtime;
                WAIT for 50 ns;

            WHEN    inv_write          =>
                bus_cycle(bus_cmd => bus_select);

                bus_cycle(bus_cmd => bus_inv_write,
                          data_num=> command.byte_num,
                          opcode  => to_slv(command.data1,8));

                bus_cycle(bus_cmd => bus_deselect);

                IF status /= err THEN
                    IF BP0 = '0' AND BP1 = '0' AND BP2 = '0' THEN
                        FOR i IN 0 TO ADDRRange LOOP
                            mem(i) := 16#FF#;
                        END LOOP;
                        E_ERR := '0';
                    ELSE
                        E_ERR := '0';
                    END IF;
                    WEL := '0';
                END IF;

            WHEN    OTHERS  =>  null;
        END CASE;

    END PROCEDURE;

    VARIABLE cmd_cnt    :   NATURAL;
    VARIABLE command    :   cmd_rec;

BEGIN
    TestInit(TimingModel, LongTimming);
    Pick_TC (Model   =>  "s25fs256s");

    Tseries <=  ts_cnt  ;
    Tcase   <=  tc_cnt  ;

    Generate_TC
        (Model       => TimingModel ,
         Series      => ts_cnt,
         TestCase    => tc_cnt,
         Sec_Arch    => BootConfig,
         command_seq => cmd_seq);

    cmd_cnt := 1;
    WHILE cmd_seq(cmd_cnt).cmd /= done LOOP
        command  := cmd_seq(cmd_cnt);
        status   <=  command.status;
        cmd      <=  command.cmd;
        read_num <= command.byte_num;
        cmd_dc(command);
        cmd_cnt :=cmd_cnt +1;
    END LOOP;

END PROCESS tb;

-------------------------------------------------------------------------------
-- Checker process,
-------------------------------------------------------------------------------
checker: PROCESS
    VARIABLE Addr_reg    : std_logic_vector(31 downto 0);
    VARIABLE RDAR_reg    : std_logic_vector(7 downto 0);
    VARIABLE Data_reg    : std_logic_vector(63 downto 0);
    VARIABLE DLP0_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP1_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP2_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP3_reg    : std_logic_vector(7 downto 0);
    VARIABLE DLP_ACT     : std_logic_vector(1 downto 0);
    VARIABLE DLP_EN      : std_logic;
    VARIABLE Pass_out    : std_logic_vector(63 downto 0);
    VARIABLE address     : NATURAL RANGE 0 TO AddrRANGE+1;
    VARIABLE byte        : NATURAL;
    VARIABLE CFIaddress  : NATURAL RANGE 16#00# TO 16#13F#;
    VARIABLE SFDPaddress : NATURAL RANGE 16#0000# TO 16#113F#;
    VARIABLE tmp         : NATURAL;
    VARIABLE Lat_cnt     : NATURAL;
    VARIABLE SecAddr     : NATURAL RANGE 0 TO AddrRANGE;

BEGIN

    IF (T_CSNeg='0') THEN
        DLP_EN := '0';
        DLP0_reg(7 downto 0) := (OTHERS => '0');
        DLP1_reg(7 downto 0) := (OTHERS => '0');
        DLP2_reg(7 downto 0) := (OTHERS => '0');
        DLP3_reg(7 downto 0) := (OTHERS => '0');

        --Opcode
        IF (status /= rd_cont_dualIO AND status /= rd_cont_dualIO4 AND
            status /= rd_cont_quadIO AND status /= rd_cont_quadIO4 AND
            status /= rd_cont_qddr   AND status /= rd_cont_qddr4   AND
            status /= none) THEN
            IF QUAD_ALL='1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL (rising_edge(T_SCK));
                END LOOP;
            ELSE
                FOR I IN 7 DOWNTO 0 LOOP
                    WAIT UNTIL (rising_edge(T_SCK));
                END LOOP;
            END IF;
        END IF;

        --Address
        --3 Bytes Address
        IF (QUAD_ALL='1') AND (((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR
             cmd = rdar_read OR cmd = ecc_read OR cmd = dybacc_rd OR
             cmd = ppbacc_rd OR cmd = dual_high_rd) AND CR2_V(7) = '0') OR
             cmd = read_SFDP) THEN
            FOR I IN 0 TO 5 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-4*i) := T_RESETNeg;
                Addr_reg(22-4*i) := T_WPNeg;
                Addr_reg(21-4*i) := T_SO;
                Addr_reg(20-4*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF ((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR cmd=rdar_read OR
             cmd = ecc_read OR cmd = dybacc_rd OR cmd = ppbacc_rd) AND
             CR2_V(7) = '0') OR cmd = read_SFDP THEN
            FOR I IN 23 DOWNTO 0 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = dual_high_rd AND CR2_V(7) = '0' THEN
            FOR I IN 0 TO 11 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(23-2*i) := T_SO;
                Addr_reg(22-2*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_high_rd AND CR2_V(7) = '0' THEN
            FOR I IN 0 TO 5 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(23-4*i) := T_RESETNeg;
                Addr_reg(22-4*i) := T_WPNeg;
                Addr_reg(21-4*i) := T_SO;
                Addr_reg(20-4*i) := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF cmd = quad_high_ddr_rd AND CR2_V(7)= '0' THEN
            WAIT UNTIL rising_edge(T_SCK);
            Addr_reg(23)   := T_RESETNeg;
            Addr_reg(22)   := T_WPNeg;
            Addr_reg(21)   := T_SO;
            Addr_reg(20)   := T_SI;
            FOR I IN 1 TO 5 LOOP
                WAIT UNTIL T_SCK'EVENT;
                Addr_reg(23-4*i)   := T_RESETNeg;
                Addr_reg(22-4*i)   := T_WPNeg;
                Addr_reg(21-4*i)   := T_SO;
                Addr_reg(20-4*i)   := T_SI;
            END LOOP;
            Addr_reg(31 downto 24):= "00000000";
            address := to_nat(Addr_reg(31 downto 0));
        END IF;

        --4 Bytes Address
        IF (QUAD_ALL='1') AND (((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR
             cmd = rdar_read OR cmd = ecc_read OR cmd = dybacc_rd OR
             cmd = ppbacc_rd OR cmd = dual_high_rd) AND CR2_V(7)='1') OR
             cmd = rd_4 OR cmd = fast_rd4 OR cmd = ecc_read4 OR
             cmd = dybacc_rd4 OR cmd = ppbacc_rd4) THEN
            FOR I IN 0 TO 7 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-4*i) := T_RESETNeg;
                Addr_reg(30-4*i) := T_WPNeg;
                Addr_reg(29-4*i) := T_SO;
                Addr_reg(28-4*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF ((cmd = rd OR cmd = fast_rd OR cmd = otp_read OR cmd=rdar_read OR
             cmd = ecc_read OR cmd = dybacc_rd OR cmd = ppbacc_rd) AND
             CR2_V(7)='1') OR cmd = rd_4 OR cmd = fast_rd4 OR cmd = ecc_read4 OR
             cmd = dybacc_rd4 OR cmd = ppbacc_rd4 THEN
            FOR I IN 31 DOWNTO 0 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = dual_high_rd AND CR2_V(7)='1') OR cmd = dual_high_rd_4 THEN
            FOR I IN 0 TO 15 LOOP
                WAIT UNTIL (rising_edge(T_SCK));
                Addr_reg(31-2*i) := T_SO;
                Addr_reg(30-2*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_high_rd AND CR2_V(7)='1') OR cmd = quad_high_rd_4 THEN
            FOR I IN 0 TO 7 LOOP
                WAIT UNTIL rising_edge(T_SCK);
                Addr_reg(31-4*i) := T_RESETNeg;
                Addr_reg(30-4*i) := T_WPNeg;
                Addr_reg(29-4*i) := T_SO;
                Addr_reg(28-4*i) := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        ELSIF (cmd = quad_high_ddr_rd AND CR2_V(7) = '1') OR
               cmd = quad_high_ddr_rd_4 THEN
            WAIT UNTIL rising_edge(T_SCK);
            Addr_reg(31)   := T_RESETNeg;
            Addr_reg(30)   := T_WPNeg;
            Addr_reg(29)   := T_SO;
            Addr_reg(28)   := T_SI;
            FOR I IN 1 TO 7 LOOP
                WAIT UNTIL T_SCK'EVENT;
                Addr_reg(31-4*i)   := T_RESETNeg;
                Addr_reg(30-4*i)   := T_WPNeg;
                Addr_reg(29-4*i)   := T_SO;
                Addr_reg(28-4*i)   := T_SI;
            END LOOP;
            address := to_nat(Addr_reg(31 downto 0));
        END IF;

        --Mode Byte
        IF cmd = dual_high_rd OR cmd = dual_high_rd_4 THEN
            IF QUAD_ALL = '1' THEN
                FOR I IN 1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSE
                FOR I IN 3 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF cmd = quad_high_rd OR cmd = quad_high_rd_4 THEN
            FOR I IN 1 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
            FOR I IN 1 DOWNTO 0 LOOP
                WAIT UNTIL T_SCK'EVENT;
            END LOOP;
        END IF;

        -- Dummy Bytes
        Lat_cnt := to_nat(CR2_V(3 DOWNTO 0));
        IF cmd = read_SFDP THEN
            FOR I IN 7 DOWNTO 0 LOOP
                WAIT UNTIL rising_edge(T_SCK);
            END LOOP;
        ELSIF (cmd = fast_rd OR cmd = fast_rd4 OR cmd = otp_read OR
             cmd = dual_high_rd OR cmd = dual_high_rd_4 OR cmd = quad_high_rd OR
             cmd = quad_high_rd_4 OR cmd = ecc_read OR cmd = ecc_read4 OR
             cmd = rdar_read) THEN
            IF Lat_cnt >= 1 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            END IF;
        ELSIF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
            IF Lat_cnt >= 1 AND Lat_cnt < 4 THEN
                FOR I IN Lat_cnt-1 DOWNTO 0 LOOP
                    WAIT UNTIL rising_edge(T_SCK);
                END LOOP;
            ELSIF Lat_cnt >= 4 THEN
                IF Lat_cnt = 4 THEN
                    WAIT FOR 6.51 ns;
                    IF (VDLR_reg /= "00000000") THEN
                        DLP0_reg(7) := T_SO;
                        DLP1_reg(7) := T_SI;
                        DLP2_reg(7) := T_WPNeg;
                        DLP3_reg(7) := T_RESETNeg;
                    END IF;
                    FOR I IN 6 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 6.51 ns;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_RESETNeg;
                        END IF;
                    END LOOP;
                ELSE
                    FOR I IN (Lat_cnt-5) DOWNTO 0 LOOP
                        WAIT UNTIL rising_edge(T_SCK);
                    END LOOP;
                    FOR I IN 7 DOWNTO 0 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 6.51 ns;
                        IF (VDLR_reg /= "00000000") THEN
                            DLP0_reg(I) := T_SO;
                            DLP1_reg(I) := T_SI;
                            DLP2_reg(I) := T_WPNeg;
                            DLP3_reg(I) := T_RESETNeg;
                        END IF;
                    END LOOP;
                END IF;
                WAIT UNTIL falling_edge(T_SCK);
                DLP_EN := '1';
            END IF;
        END IF;

        --Data Bytes
        CFIaddress  := 16#00#;
        SFDPaddress := 16#00#;
        byte        := 0;

        IF (status /= none AND status /= err) THEN
            FOR I IN read_num-1 DOWNTO 0 LOOP
                Data_reg(7 downto 0) := (OTHERS => '0');
                IF (cmd = dual_high_rd OR cmd = dual_high_rd_4) AND
                   QUAD_ALL = '0' THEN
                    FOR J IN 0 TO 3 LOOP
                        WAIT UNTIL (falling_edge(T_SCK));
                        WAIT FOR 6.5 ns;
                        Data_reg(7-2*J) := T_SO;
                        Data_reg(6-2*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_high_rd OR cmd = quad_high_rd_4  OR
                      cmd = read_JQID THEN
                    FOR J IN 0 TO 1 LOOP
                        WAIT UNTIL falling_edge(T_SCK);
                        WAIT FOR 6.5 ns;
                        Data_reg(7-4*J) := T_RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = quad_high_ddr_rd OR cmd = quad_high_ddr_rd_4 THEN
                    FOR J IN 0 TO 1 LOOP
                        WAIT UNTIL T_SCK'EVENT;
                        WAIT FOR 0.5 ns;
                        Data_reg(7-4*J) := T_RESETNeg;
                        Data_reg(6-4*J) := T_WPNeg;
                        Data_reg(5-4*J) := T_SO;
                        Data_reg(4-4*J) := T_SI;
                    END LOOP;
                ELSIF cmd = asp_reg_rd AND QUAD_ALL = '0' THEN
                    FOR J IN 15 DOWNTO 0 LOOP
                        WAIT UNTIL (falling_edge(T_SCK));
                        WAIT FOR 7 ns;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSIF cmd = pass_reg_rd  AND QUAD_ALL = '0' THEN
                    FOR J IN 63 DOWNTO 0 LOOP
                        WAIT UNTIL (falling_edge(T_SCK));
                        WAIT FOR 7 ns;
                        Data_reg(J) := T_SO;
                    END LOOP;
                ELSE
                    IF QUAD_ALL = '0' THEN
                        FOR J IN 7 DOWNTO 0 LOOP
                            WAIT UNTIL (falling_edge(T_SCK));
                            IF half_period = half_period1_srl THEN
                                WAIT FOR 6.5 ns;
                            ELSE
                                WAIT FOR 8 ns;
                            END IF;
                            Data_reg(J) := T_SO;
                        END LOOP;
                    ELSE
                        FOR J IN 0 TO 1 LOOP
                            WAIT UNTIL falling_edge(T_SCK);
                            IF half_period = half_period1_srl THEN
                                WAIT FOR 6.5 ns;
                            ELSE
                                WAIT FOR 8 ns;
                            END IF;
                            Data_reg(7-4*J) := T_RESETNeg;
                            Data_reg(6-4*J) := T_WPNeg;
                            Data_reg(5-4*J) := T_SO;
                            Data_reg(4-4*J) := T_SI;
                        END LOOP;
                    END IF;
                END IF;

                CASE status IS
                    WHEN read | read_4 | read_fast | read_fast_4 |
                         read_dual_hi | read_dual_hi4| read_quad_hi |
                         read_quad_hi4 | read_ddr_quad_hi |
                         read_ddr_quad_hi4 | rd_cont_dualIO |
                         rd_cont_dualIO4 | rd_cont_quadIO | rd_cont_quadIO4 |
                         rd_cont_qddr | rd_cont_qddr4 =>
                        DLP_ACT := "00";
                        IF (VDLR_reg /= "00000000") AND DLP_EN = '1' THEN
                            IF (status = read_ddr_quad_hi4
                            OR status = read_ddr_quad_hi) THEN
                                DLP_ACT := "11";
                            END IF;
                            DLP_EN := '0';
                        END IF;

                        --read memory array data and dlp if enabled
                        Check_read (
                            DQ        => Data_reg(7 downto 0),
                            DQ_reg0   => DLP0_reg(7 downto 0),
                            DQ_reg1   => DLP1_reg(7 downto 0),
                            DQ_reg2   => DLP2_reg(7 downto 0),
                            DQ_reg3   => DLP3_reg(7 downto 0),
                            D_mem     => mem(address),
                            DLP_reg   => to_nat(VDLR_reg),
                            D_dlp_act => DLP_ACT,
                            check_err => check_err);

                        IF CR4_V(4) = '1'  OR status = read OR
                           status = read_4 THEN   --Wrap Disabled
                            -- if the highest address is reached
                            IF address = AddrRange THEN
                                address := 0;
                            ELSE
                                address := address + 1;
                            END IF;
                        ELSE          --Wrap Enabled
                            address := address + 1;

                            IF CR4_V(1 DOWNTO 0)= "01" AND
                               address MOD 16 = 0 THEN
                                address:= address - 16;
                            ELSIF CR4_V(1 DOWNTO 0) = "10" AND
                               address MOD 32 = 0 THEN
                                address:= address - 32;
                            ELSIF CR4_V(1 DOWNTO 0) = "11" AND
                               address MOD 64 = 0 THEN
                                address:= address - 64;
                            ELSIF CR4_V(1 DOWNTO 0) = "00" AND
                               address MOD 8 = 0 THEN
                                address:= address - 8;
                            END IF;
                        END IF;

                    WHEN rd_HiZ =>
                        --read memory array data
                        Check_Z (
                            DQ        => Data_reg(0),
                            check_err => check_err);

                    WHEN rd_U =>
                        --read memory array data
                        Check_X (
                            DQ        => Data_reg(0),
                            check_err => check_err);

                    WHEN read_otp =>
                        --read otp array data
                        IF address >= OTPLoAddr AND address <= OTPHiAddr THEN
                            Check_otp_read (
                                DQ         => Data_reg(7 downto 0),
                                otp_mem    => Otp(address),
                                check_err  => check_err);

                            address := address +1;
                        END IF;

                    WHEN rd_JID | rd_JQID =>

                        IF (CFIaddress <= 16#13F#) THEN
                            -- read ID
                            Check_read_JID (
                                DQ          => Data_reg(7 downto 0),
                                VDATA       => SFDP_array(16#1000# + CFIaddress),
                                byte_no     => byte,
                                check_err   => check_err);

                            CFIaddress := CFIaddress + 1;
                         END IF;

                         byte := byte + 1;

                    WHEN rd_SFDP =>

                        IF (address < SFDPHiAddr+1) THEN
                            -- read ID
                            Check_read_SFDP (
                                DQ          => Data_reg(7 downto 0),
                                VDATA       => SFDP_array(address) ,
                                check_err   => check_err);
                         END IF;

                         address := address + 1;

                    WHEN read_sr1 =>
                        --read status register1
                        Check_read_sr1 (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(SR1_V),
                            check_err=> check_err);

                    WHEN read_sr2 =>
                        --read status register2
                        Check_read_sr2 (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(SR2_V),
                            check_err=> check_err);

                    WHEN read_rdar =>
                        --read all registers

                        IF address = 16#00000000# THEN
                            RDAR_reg := SR1_NV;
                        ELSIF address = 16#00000002# THEN
                            RDAR_reg := CR1_NV;
                        ELSIF address = 16#00000003# THEN
                            RDAR_reg := CR2_NV;
                        ELSIF address = 16#00000004# THEN
                            RDAR_reg := CR3_NV;
                        ELSIF address = 16#00000005# THEN
                            RDAR_reg := CR4_NV;
                        ELSIF address = 16#00000010# THEN
                            RDAR_reg := NVDLR_reg;
                        ELSIF address = 16#00000020# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(7 DOWNTO 0);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000021# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(15 DOWNTO 8);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000022# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(23 DOWNTO 16);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000023# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(31 DOWNTO 24);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000024# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(39 DOWNTO 32);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000025# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(47 DOWNTO 40);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000026# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(55 DOWNTO 48);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000027# THEN
                            IF PWDMLB = '1' THEN
                                RDAR_reg := Password_reg(63 DOWNTO 56);
                            ELSE
                                RDAR_reg := "XXXXXXXX";
                            END IF;
                        ELSIF address = 16#00000030# THEN
                            RDAR_reg := ASP_reg(7 DOWNTO 0);
                        ELSIF address = 16#00000031# THEN
                            RDAR_reg := ASP_reg(15 DOWNTO 8);
                        ELSIF address = 16#00800000# THEN
                            RDAR_reg := SR1_V;
                        ELSIF address = 16#00800001# THEN
                            RDAR_reg := SR2_V;
                        ELSIF address = 16#00800002# THEN
                            RDAR_reg := CR1_V;
                        ELSIF address = 16#00800003# THEN
                            RDAR_reg := CR2_V;
                        ELSIF address = 16#00800004# THEN
                            RDAR_reg := CR3_V;
                        ELSIF address = 16#00800005# THEN
                            RDAR_reg := CR4_V;
                        ELSIF address = 16#00800010# THEN
                            RDAR_reg := VDLR_reg;
                        ELSIF address = 16#00800040# THEN
                            RDAR_reg := PPBL;
                        ELSE
                            RDAR_reg := "XXXXXXXX";
                        END IF;

                        IF RDAR_reg /= "XXXXXXXX" THEN

                            Check_rdar (
                                DQ       => Data_reg(7 downto 0),
                                D_mem    => to_nat(RDAR_reg),
                                check_err=> check_err);
                        ELSE
                            Check_X (
                                DQ        => Data_reg(0),
                                check_err => check_err);
                        END IF;

                    WHEN read_config =>
                        --read configuration register
                        Check_read_config (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(CR1_V),
                            check_err=> check_err);

                    WHEN read_dlp =>
                        --read dlp register
                        Check_read_dlp (
                            DQ       => Data_reg(7 downto 0),
                            DLP_reg  => to_nat(VDLR_reg),
                            check_err=> check_err);

                    WHEN read_asp =>
                        --read asp register
                        Check_read_asp (
                            DQ       => Data_reg(15 downto 0),
                            D_mem    => to_nat(ASP_reg),
                            check_err=> check_err);

                    WHEN read_pass_reg =>
                        --read password register
                        Pass_out := Password_reg(7  downto 0) &
                                    Password_reg(15 downto 8) &
                                    Password_reg(23 downto 16) &
                                    Password_reg(31 downto 24) &
                                    Password_reg(39 downto 32) &
                                    Password_reg(47 downto 40) &
                                    Password_reg(55 downto 48) &
                                    Password_reg(63 downto 56);

                        Check_read_pass_reg (
                            DQ       => Data_reg(63 downto 0),
                            D_mem    => to_nat(Pass_out),
                            check_err=> check_err);

                    WHEN read_ppbl =>
                        --read ppb lock register
                        Check_read_ppbl (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(PPBL),
                            check_err=> check_err);

                    WHEN read_ppbar | read_ppbar_4 =>
                        --read ppb access register
                        Check_read_ppbar (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(PPBAR),
                            check_err=> check_err);

                    WHEN read_ecc | read_ecc_4 =>
                        --read ECC register
                        Check_read_ecc (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(ECC_reg),
                            check_err=> check_err);

                    WHEN read_dybar | read_dybar_4 =>
                        --read dyb access register
                        Check_read_dybar (
                            DQ       => Data_reg(7 downto 0),
                            D_mem    => to_nat(DYBAR),
                            check_err=> check_err);

                    WHEN rd_ppblock_0 | rd_ppblock_1 =>
                        Check_PPBLOCK_bit (
                            DQ       => PPBL(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_wip_0 | rd_wip_1 =>
                        Check_WIP_bit (
                            DQ       => Data_reg(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_wel_0 | rd_wel_1 =>
                        Check_WEL_bit (
                            DQ       => SR1_V(1),
                            sts      => status,
                            check_err=> check_err);

                    WHEN erase_succ | erase_nosucc =>
                        Check_eers_bit (
                            DQ       => Data_reg(5),
                            sts      => status,
                            check_err=> check_err);

                    WHEN pgm_succ | pgm_nosucc =>
                        Check_epgm_bit (
                            DQ       => Data_reg(6),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_ps_0 | rd_ps_1 =>
                        Check_PS_bit (
                            DQ       => Data_reg(0),
                            sts      => status,
                            check_err=> check_err);

                    WHEN rd_es_0 | rd_es_1 =>
                        Check_ES_bit (
                            DQ       => Data_reg(1),
                            sts      => status,
                            check_err=> check_err);

                    WHEN others =>
                        null;

                END CASE;
            END LOOP;
        END IF;
    END IF;

    WAIT ON T_CSNeg;

END PROCESS checker;

    ---------------------------------------------------------------------------
    ---- CFI Preload Process
    ---------------------------------------------------------------------------
    CFIPreload : PROCESS

    BEGIN
        -----------------------------------------------------------------------
        --CFI array data
        -----------------------------------------------------------------------
        -- Manufacturer and Device ID
        CFI_array(16#00#) := 16#01#;
        CFI_array(16#01#) := 16#02#;
        CFI_array(16#02#) := 16#19#;
        CFI_array(16#03#) := 16#4D#;
        CFI_array(16#04#) := 16#00#;--Uniform 256KB sectors
        CFI_array(16#05#) := 16#81#;
        IF TimingModel(15) = '0' THEN
            CFI_array(16#06#) := 16#30#;
        ELSIF TimingModel(15) = '1' THEN
            CFI_array(16#06#) := 16#31#;
        ELSIF TimingModel(15) = '2' THEN
            CFI_array(16#06#) := 16#32#;
        ELSIF TimingModel(15) = '3' THEN
            CFI_array(16#06#) := 16#33#;
        END IF;
        CFI_array(16#07#) := 16#31#;
        CFI_array(16#08#) := 16#84#;
        CFI_array(16#09#) := 16#00#;
        CFI_array(16#0A#) := 16#00#;
        CFI_array(16#0B#) := 16#00#;
        CFI_array(16#0C#) := 16#00#;
        CFI_array(16#0D#) := 16#00#;
        CFI_array(16#0E#) := 16#00#;
        CFI_array(16#0F#) := 16#00#;
        --CFI Query Identification String
        CFI_array(16#10#) := 16#51#;
        CFI_array(16#11#) := 16#52#;
        CFI_array(16#12#) := 16#59#;
        CFI_array(16#13#) := 16#02#;
        CFI_array(16#14#) := 16#00#;
        CFI_array(16#15#) := 16#40#;
        CFI_array(16#16#) := 16#00#;
        CFI_array(16#17#) := 16#53#;
        CFI_array(16#18#) := 16#46#;
        CFI_array(16#19#) := 16#51#;
        CFI_array(16#1A#) := 16#00#;
        --CFI system interface string
        CFI_array(16#1B#) := 16#17#;
        CFI_array(16#1C#) := 16#19#;
        CFI_array(16#1D#) := 16#00#;
        CFI_array(16#1E#) := 16#00#;
        CFI_array(16#1F#) := 16#09#;
        CFI_array(16#20#) := 16#09#;
        CFI_array(16#21#) := 16#0A#;-- 256KB
        CFI_array(16#22#) := 16#01#;
        CFI_array(16#23#) := 16#02#;
        CFI_array(16#24#) := 16#02#;
        CFI_array(16#25#) := 16#03#;
        CFI_array(16#26#) := 16#03#;
        -- Device Geometry Definition
        CFI_array(16#27#) := 16#19#;
        CFI_array(16#28#) := 16#02#;
        CFI_array(16#29#) := 16#01#;
        CFI_array(16#2A#) := 16#08#;
        CFI_array(16#2B#) := 16#00#;
        CFI_array(16#2C#) := 16#03#;
        CFI_array(16#2D#) := 16#07#;
        CFI_array(16#2E#) := 16#00#;
        CFI_array(16#2F#) := 16#10#;
        CFI_array(16#30#) := 16#00#;
        CFI_array(16#31#) := 16#00#;
        CFI_array(16#32#) := 16#00#;
        CFI_array(16#33#) := 16#80#;
        CFI_array(16#34#) := 16#00#;
        CFI_array(16#35#) := 16#FE#;
        CFI_array(16#36#) := 16#01#;
        CFI_array(16#37#) := 16#00#;
        CFI_array(16#38#) := 16#01#;
        CFI_array(16#39#) := 16#FF#;
        CFI_array(16#3A#) := 16#FF#;
        CFI_array(16#3B#) := 16#FF#;
        CFI_array(16#3C#) := 16#FF#;
        CFI_array(16#3D#) := 16#FF#;
        CFI_array(16#3E#) := 16#FF#;
        CFI_array(16#3F#) := 16#FF#;
        -- CFI Primary Vendor-Specific Extended Query
        CFI_array(16#40#) := 16#50#;
        CFI_array(16#41#) := 16#52#;
        CFI_array(16#42#) := 16#49#;
        CFI_array(16#43#) := 16#31#;
        CFI_array(16#44#) := 16#33#;
        CFI_array(16#45#) := 16#21#;
        CFI_array(16#46#) := 16#02#;
        CFI_array(16#47#) := 16#01#;
        CFI_array(16#48#) := 16#00#;
        CFI_array(16#49#) := 16#08#;

        CFI_array(16#4A#) := 16#00#;
        CFI_array(16#4B#) := 16#01#;
        CFI_array(16#4C#) := 16#03#;
        CFI_array(16#4D#) := 16#00#;
        CFI_array(16#4E#) := 16#00#;
        CFI_array(16#4F#) := 16#07#;
        CFI_array(16#50#) := 16#01#;

        WAIT;
    END PROCESS CFIPreload;

    ---------------------------------------------------------------------------
    ---- SFDP Preload Process
    ---------------------------------------------------------------------------
    SFDPPreload : PROCESS

    BEGIN
        -----------------------------------------------------------------------
        --SFDP Header
        -----------------------------------------------------------------------
        SFDP_array(16#0000#) := 16#53#;
        SFDP_array(16#0001#) := 16#46#;
        SFDP_array(16#0002#) := 16#44#;
        SFDP_array(16#0003#) := 16#50#;
        SFDP_array(16#0004#) := 16#06#;
        SFDP_array(16#0005#) := 16#01#;
        SFDP_array(16#0006#) := 16#05#;
        SFDP_array(16#0007#) := 16#FF#;
        SFDP_array(16#0008#) := 16#00#;
        SFDP_array(16#0009#) := 16#00#;
        SFDP_array(16#000A#) := 16#01#;
        SFDP_array(16#000B#) := 16#09#;
        SFDP_array(16#000C#) := 16#90#;
        SFDP_array(16#000D#) := 16#10#;
        SFDP_array(16#000E#) := 16#00#;
        SFDP_array(16#000F#) := 16#FF#;
        SFDP_array(16#0010#) := 16#00#;
        SFDP_array(16#0011#) := 16#05#;
        SFDP_array(16#0012#) := 16#01#;
        SFDP_array(16#0013#) := 16#10#;
        SFDP_array(16#0014#) := 16#90#;
        SFDP_array(16#0015#) := 16#10#;
        SFDP_array(16#0016#) := 16#00#;
        SFDP_array(16#0017#) := 16#FF#;
        SFDP_array(16#0018#) := 16#00#;
        SFDP_array(16#0019#) := 16#06#;
        SFDP_array(16#001A#) := 16#01#;
        SFDP_array(16#001B#) := 16#10#;
        SFDP_array(16#001C#) := 16#90#;
        SFDP_array(16#001D#) := 16#10#;
        SFDP_array(16#001E#) := 16#00#;
        SFDP_array(16#001F#) := 16#FF#;
        SFDP_array(16#0020#) := 16#81#;
        SFDP_array(16#0021#) := 16#00#;
        SFDP_array(16#0022#) := 16#01#;
        SFDP_array(16#0023#) := 16#1A#;
        SFDP_array(16#0024#) := 16#D8#;
        SFDP_array(16#0025#) := 16#10#;
        SFDP_array(16#0026#) := 16#00#;
        SFDP_array(16#0027#) := 16#FF#;
        SFDP_array(16#0028#) := 16#84#;
        SFDP_array(16#0029#) := 16#00#;
        SFDP_array(16#002A#) := 16#01#;
        SFDP_array(16#002B#) := 16#02#;
        SFDP_array(16#002C#) := 16#D0#;
        SFDP_array(16#002D#) := 16#10#;
        SFDP_array(16#002E#) := 16#00#;
        SFDP_array(16#002F#) := 16#FF#;
        SFDP_array(16#0030#) := 16#01#;
        SFDP_array(16#0031#) := 16#01#;
        SFDP_array(16#0032#) := 16#01#;
        SFDP_array(16#0033#) := 16#50#;
        SFDP_array(16#0034#) := 16#00#;
        SFDP_array(16#0035#) := 16#10#;
        SFDP_array(16#0036#) := 16#00#;
        SFDP_array(16#0037#) := 16#01#;
        --Unused
        FOR I IN 16#0038# TO 16#0FFF# LOOP
           SFDP_array(I) := 16#FF#;
        END LOOP;

        -----------------------------------------------------------------------
        --ID-CFI array data
        -----------------------------------------------------------------------
        -- Manufacturer and Device ID
        SFDP_array(16#1000#) := 16#01#;
        SFDP_array(16#1001#) := 16#02#;
        SFDP_array(16#1002#) := 16#19#;
        SFDP_array(16#1003#) := 16#4D#;
        --Uniform 256KB sectors
        SFDP_array(16#1004#) := 16#00#;
        SFDP_array(16#1005#) := 16#81#;
        IF TimingModel(15) = '0' THEN
            SFDP_array(16#1006#) := 16#30#;
        ELSIF TimingModel(15) = '1' THEN
            SFDP_array(16#1006#) := 16#31#;
        ELSIF TimingModel(15) = '2' THEN
            SFDP_array(16#1006#) := 16#32#;
        ELSIF TimingModel(15) = '3' THEN
            SFDP_array(16#1006#) := 16#33#;
        END IF;
        SFDP_array(16#1007#) := 16#30#;
        --CFI Query Identification String
        SFDP_array(16#1010#) := 16#51#;
        SFDP_array(16#1011#) := 16#52#;
        SFDP_array(16#1012#) := 16#59#;
        SFDP_array(16#1013#) := 16#02#;
        SFDP_array(16#1014#) := 16#00#;
        SFDP_array(16#1015#) := 16#40#;
        SFDP_array(16#1016#) := 16#00#;
        SFDP_array(16#1017#) := 16#53#;
        SFDP_array(16#1018#) := 16#46#;
        SFDP_array(16#1019#) := 16#51#;
        SFDP_array(16#101A#) := 16#00#;
        --CFI system interface string
        SFDP_array(16#101B#) := 16#17#;
        SFDP_array(16#101C#) := 16#19#;
        SFDP_array(16#101D#) := 16#00#;
        SFDP_array(16#101E#) := 16#00#;
        SFDP_array(16#101F#) := 16#09#;
        SFDP_array(16#1020#) := 16#09#;
        SFDP_array(16#1021#) := 16#0A#;-- 256KB
        SFDP_array(16#1022#) := 16#11#;
        SFDP_array(16#1023#) := 16#02#;
        SFDP_array(16#1024#) := 16#02#;
        SFDP_array(16#1025#) := 16#04#;
        SFDP_array(16#1026#) := 16#03#;
        -- Device Geometry Definition(Uniform Sector Devices)
        SFDP_array(16#1027#) := 16#19#;
        SFDP_array(16#1028#) := 16#02#;
        SFDP_array(16#1029#) := 16#01#;
        SFDP_array(16#102A#) := 16#08#;
        SFDP_array(16#102B#) := 16#00#;
        SFDP_array(16#102C#) := 16#03#;
        SFDP_array(16#102D#) := 16#07#;
        SFDP_array(16#102E#) := 16#00#;
        SFDP_array(16#102F#) := 16#10#;
        SFDP_array(16#1030#) := 16#00#;
        SFDP_array(16#1031#) := 16#00#;
        SFDP_array(16#1032#) := 16#00#;
        SFDP_array(16#1033#) := 16#80#;
        SFDP_array(16#1034#) := 16#00#;
        SFDP_array(16#1035#) := 16#FE#;
        SFDP_array(16#1036#) := 16#01#;
        SFDP_array(16#1037#) := 16#00#;
        SFDP_array(16#1038#) := 16#01#;
        SFDP_array(16#1039#) := 16#FF#;
        SFDP_array(16#103A#) := 16#FF#;
        SFDP_array(16#103B#) := 16#FF#;
        SFDP_array(16#103C#) := 16#FF#;
        SFDP_array(16#103D#) := 16#FF#;
        SFDP_array(16#103E#) := 16#FF#;
        SFDP_array(16#103F#) := 16#FF#;
        -- CFI Primary Vendor-Specific Extended Query
        SFDP_array(16#1040#) := 16#50#;
        SFDP_array(16#1041#) := 16#52#;
        SFDP_array(16#1042#) := 16#49#;
        SFDP_array(16#1043#) := 16#31#;
        SFDP_array(16#1044#) := 16#33#;
        SFDP_array(16#1045#) := 16#21#;
        SFDP_array(16#1046#) := 16#02#;
        SFDP_array(16#1047#) := 16#01#;
        SFDP_array(16#1048#) := 16#00#;
        SFDP_array(16#1049#) := 16#08#;

        SFDP_array(16#104A#) := 16#00#;
        SFDP_array(16#104B#) := 16#01#;
        SFDP_array(16#104C#) := 16#03#;
        SFDP_array(16#104D#) := 16#00#;
        SFDP_array(16#104E#) := 16#00#;
        SFDP_array(16#104F#) := 16#07#;
        SFDP_array(16#1050#) := 16#01#;

        -----------------------------------------------------------------------
        --CFI Alternate Vendor Specific Extended Query Parameters
        -----------------------------------------------------------------------
        -- CFI Alternate Vendor Specific Extended Query Header
        SFDP_array(16#1051#) := 16#41#;
        SFDP_array(16#1052#) := 16#4C#;
        SFDP_array(16#1053#) := 16#54#;
        SFDP_array(16#1054#) := 16#32#;
        SFDP_array(16#1055#) := 16#30#;

        -- CFI Alternate Vendor Specific Extended Query Parameter 0
        SFDP_array(16#1056#) := 16#00#;
        SFDP_array(16#1057#) := 16#10#;
        SFDP_array(16#1058#) := 16#53#;
        SFDP_array(16#1059#) := 16#32#;
        SFDP_array(16#105A#) := 16#35#;
        SFDP_array(16#105B#) := 16#46#;
        SFDP_array(16#105C#) := 16#53#;
        SFDP_array(16#105D#) := 16#32#;
        SFDP_array(16#105E#) := 16#35#;
        SFDP_array(16#105F#) := 16#36#;
        SFDP_array(16#1060#) := 16#53#;
        SFDP_array(16#1061#) := 16#FF#;
        SFDP_array(16#1062#) := 16#FF#;
        SFDP_array(16#1063#) := 16#FF#;
        SFDP_array(16#1064#) := 16#FF#;
        SFDP_array(16#1065#) := 16#FF#;
        IF TimingModel(15) = '0' THEN
            SFDP_array(16#1066#) := 16#30#;
        ELSIF TimingModel(15) = '1' THEN
            SFDP_array(16#1066#) := 16#31#;
        ELSIF TimingModel(15) = '2' THEN
            SFDP_array(16#1066#) := 16#32#;
        ELSIF TimingModel(15) = '3' THEN
            SFDP_array(16#1066#) := 16#33#;
        END IF;
        SFDP_array(16#1067#) := 16#30#;

        -- CFI Alternate Vendor-Specific Extended Query Parameter 80h
        SFDP_array(16#1068#) := 16#80#;
        SFDP_array(16#1069#) := 16#01#;
        SFDP_array(16#106A#) := 16#EB#;

        -- CFI Alternate Vendor-Specific Extended Query Parameter 84h
        SFDP_array(16#106B#) := 16#84#;
        SFDP_array(16#106C#) := 16#08#;
        SFDP_array(16#106D#) := 16#75#;
        SFDP_array(16#106E#) := 16#28#;
        SFDP_array(16#106F#) := 16#7A#;
        SFDP_array(16#1070#) := 16#64#;
        SFDP_array(16#1071#) := 16#75#;
        SFDP_array(16#1072#) := 16#28#;
        SFDP_array(16#1073#) := 16#7A#;
        SFDP_array(16#1074#) := 16#64#;
        SFDP_array(16#1075#) := 16#88#;
        SFDP_array(16#1076#) := 16#04#;
        SFDP_array(16#1077#) := 16#0A#;
        SFDP_array(16#1078#) := 16#01#;
        IF TimingModel(15) = '0' OR TimingModel(15) = '1' OR
           TimingModel(15) = '2' OR TimingModel(15) = '3' THEN
            SFDP_array(16#1079#) := 16#00#;
            SFDP_array(16#107A#) := 16#01#;
        END IF;

        -- CFI Alternate Vendor-Specific Extended Query Parameter 8Ch
        SFDP_array(16#107B#) := 16#8C#;
        SFDP_array(16#107C#) := 16#06#;
        SFDP_array(16#107D#) := 16#96#;
        SFDP_array(16#107E#) := 16#01#;
        SFDP_array(16#107F#) := 16#23#;
        SFDP_array(16#1080#) := 16#00#;
        SFDP_array(16#1081#) := 16#23#;
        SFDP_array(16#1082#) := 16#00#;

        --  CFI Alternate Vendor-Specific Extended Query Parameter F0h
        SFDP_array(16#1083#) := 16#F0#;
        SFDP_array(16#1084#) := 16#09#;
        SFDP_array(16#1085#) := 16#FF#;
        SFDP_array(16#1086#) := 16#FF#;
        SFDP_array(16#1087#) := 16#FF#;
        SFDP_array(16#1088#) := 16#FF#;
        SFDP_array(16#1089#) := 16#FF#;
        SFDP_array(16#108A#) := 16#FF#;
        SFDP_array(16#108B#) := 16#FF#;
        SFDP_array(16#108C#) := 16#FF#;
        SFDP_array(16#108D#) := 16#FF#;

        --  CFI Alternate Vendor-Specific Extended Query Parameter A5h
        SFDP_array(16#108E#) := 16#A5#;
        SFDP_array(16#108F#) := 16#B0#;
        SFDP_array(16#1090#) := 16#E7#;
        SFDP_array(16#1091#) := 16#FF#;
        SFDP_array(16#1092#) := 16#B2#;
        SFDP_array(16#1093#) := 16#FF#;
        SFDP_array(16#1094#) := 16#FF#;
        SFDP_array(16#1095#) := 16#FF#;
        SFDP_array(16#1096#) := 16#FF#;
        SFDP_array(16#1097#) := 16#0F#;
        SFDP_array(16#1098#) := 16#48#;
        SFDP_array(16#1099#) := 16#EB#;
        SFDP_array(16#109A#) := 16#FF#;
        SFDP_array(16#109B#) := 16#FF#;
        SFDP_array(16#109C#) := 16#FF#;
        SFDP_array(16#109D#) := 16#FF#;
        SFDP_array(16#109E#) := 16#88#;
        SFDP_array(16#109F#) := 16#BB#;
        SFDP_array(16#10A0#) := 16#FE#;
        SFDP_array(16#10A1#) := 16#FF#;
        SFDP_array(16#10A2#) := 16#FF#;
        SFDP_array(16#10A3#) := 16#FF#;
        SFDP_array(16#10A4#) := 16#FF#;
        SFDP_array(16#10A5#) := 16#FF#;
        SFDP_array(16#10A6#) := 16#FF#;
        SFDP_array(16#10A7#) := 16#FF#;
        SFDP_array(16#10A8#) := 16#FF#;
        SFDP_array(16#10A9#) := 16#FF#;
        SFDP_array(16#10AA#) := 16#48#;
        SFDP_array(16#10AB#) := 16#EB#;
        SFDP_array(16#10AC#) := 16#0C#;
        SFDP_array(16#10AD#) := 16#20#;
        SFDP_array(16#10AE#) := 16#10#;
        SFDP_array(16#10AF#) := 16#D8#;
        SFDP_array(16#10B0#) := 16#12#;
        SFDP_array(16#10B1#) := 16#D8#;
        SFDP_array(16#10B2#) := 16#00#;
        SFDP_array(16#10B3#) := 16#FF#;
        SFDP_array(16#10B4#) := 16#E2#;
        SFDP_array(16#10B5#) := 16#72#;
        SFDP_array(16#10B6#) := 16#1D#;
        SFDP_array(16#10B7#) := 16#FF#;
        SFDP_array(16#10B8#) := 16#91#;
        SFDP_array(16#10B9#) := 16#26#;
        SFDP_array(16#10BA#) := 16#07#;
        SFDP_array(16#10BB#) := 16#DD#;
        SFDP_array(16#10BC#) := 16#EC#;
        SFDP_array(16#10BD#) := 16#83#;
        SFDP_array(16#10BE#) := 16#18#;
        SFDP_array(16#10BF#) := 16#44#;
        SFDP_array(16#10C0#) := 16#8A#;
        SFDP_array(16#10C1#) := 16#85#;
        SFDP_array(16#10C2#) := 16#7A#;
        SFDP_array(16#10C3#) := 16#75#;
        SFDP_array(16#10C4#) := 16#F7#;
        SFDP_array(16#10C5#) := 16#BD#;
        SFDP_array(16#10C6#) := 16#D5#;
        SFDP_array(16#10C7#) := 16#5C#;
        SFDP_array(16#10C8#) := 16#8C#;
        SFDP_array(16#10C9#) := 16#F6#;
        SFDP_array(16#10CA#) := 16#5D#;
        SFDP_array(16#10CB#) := 16#FF#;
        SFDP_array(16#10CC#) := 16#F0#;
        SFDP_array(16#10CD#) := 16#30#;
        SFDP_array(16#10CE#) := 16#F8#;
        SFDP_array(16#10CF#) := 16#A1#;
        SFDP_array(16#10D0#) := 16#6B#;
        SFDP_array(16#10D1#) := 16#8E#;
        SFDP_array(16#10D2#) := 16#FF#;
        SFDP_array(16#10D3#) := 16#FF#;
        SFDP_array(16#10D4#) := 16#21#;
        SFDP_array(16#10D5#) := 16#DC#;
        SFDP_array(16#10D6#) := 16#DC#;
        SFDP_array(16#10D7#) := 16#FF#;
        SFDP_array(16#10D8#) := 16#FC#;
        SFDP_array(16#10D9#) := 16#65#;
        SFDP_array(16#10DA#) := 16#FF#;
        SFDP_array(16#10DB#) := 16#08#;
        SFDP_array(16#10DC#) := 16#04#;
        SFDP_array(16#10DD#) := 16#00#;
        SFDP_array(16#10DE#) := 16#00#;
        SFDP_array(16#10DF#) := 16#00#;
        SFDP_array(16#10E0#) := 16#FC#;
        SFDP_array(16#10E1#) := 16#65#;
        SFDP_array(16#10E2#) := 16#FF#;
        SFDP_array(16#10E3#) := 16#04#;
        SFDP_array(16#10E4#) := 16#02#;
        SFDP_array(16#10E5#) := 16#00#;
        SFDP_array(16#10E6#) := 16#00#;
        SFDP_array(16#10E7#) := 16#00#;
        SFDP_array(16#10E8#) := 16#FD#;
        SFDP_array(16#10E9#) := 16#65#;
        SFDP_array(16#10EA#) := 16#FF#;
        SFDP_array(16#10EB#) := 16#02#;
        SFDP_array(16#10EC#) := 16#04#;
        SFDP_array(16#10ED#) := 16#00#;
        SFDP_array(16#10EE#) := 16#00#;
        SFDP_array(16#10EF#) := 16#00#;
        SFDP_array(16#10F0#) := 16#FE#;
        SFDP_array(16#10F1#) := 16#00#;
        SFDP_array(16#10F2#) := 16#02#;
        SFDP_array(16#10F3#) := 16#FF#;
        SFDP_array(16#10F4#) := 16#F1#;
        SFDP_array(16#10F5#) := 16#7F#;
        SFDP_array(16#10F6#) := 16#00#;
        SFDP_array(16#10F7#) := 16#00#;
        SFDP_array(16#10F8#) := 16#F2#;
        SFDP_array(16#10F9#) := 16#7F#;
        SFDP_array(16#10FA#) := 16#00#;
        SFDP_array(16#10FB#) := 16#00#;
        SFDP_array(16#10FC#) := 16#F2#;
        SFDP_array(16#10FD#) := 16#FF#;
        SFDP_array(16#10FE#) := 16#FE#;
        SFDP_array(16#10FF#) := 16#01#;
        SFDP_array(16#1100#) := 16#FE#;
        SFDP_array(16#1101#) := 16#02#;
        SFDP_array(16#1102#) := 16#02#;
        SFDP_array(16#1103#) := 16#FF#;
        SFDP_array(16#1104#) := 16#F2#;
        SFDP_array(16#1105#) := 16#FF#;
        SFDP_array(16#1106#) := 16#FE#;
        SFDP_array(16#1107#) := 16#01#;
        SFDP_array(16#1108#) := 16#F2#;
        SFDP_array(16#1109#) := 16#7F#;
        SFDP_array(16#110A#) := 16#00#;
        SFDP_array(16#110B#) := 16#00#;
        SFDP_array(16#110C#) := 16#F1#;
        SFDP_array(16#110D#) := 16#7F#;
        SFDP_array(16#110E#) := 16#00#;
        SFDP_array(16#110F#) := 16#00#;
        SFDP_array(16#1110#) := 16#FE#;
        SFDP_array(16#1111#) := 16#01#;
        SFDP_array(16#1112#) := 16#02#;
        SFDP_array(16#1113#) := 16#FF#;
        SFDP_array(16#1114#) := 16#F1#;
        SFDP_array(16#1115#) := 16#7F#;
        SFDP_array(16#1116#) := 16#00#;
        SFDP_array(16#1117#) := 16#00#;
        SFDP_array(16#1118#) := 16#F4#;
        SFDP_array(16#1119#) := 16#7F#;
        SFDP_array(16#111A#) := 16#03#;
        SFDP_array(16#111B#) := 16#00#;
        SFDP_array(16#111C#) := 16#F4#;
        SFDP_array(16#111D#) := 16#FF#;
        SFDP_array(16#111E#) := 16#FB#;
        SFDP_array(16#111F#) := 16#01#;
        SFDP_array(16#1120#) := 16#FE#;
        SFDP_array(16#1121#) := 16#03#;
        SFDP_array(16#1122#) := 16#02#;
        SFDP_array(16#1123#) := 16#FF#;
        SFDP_array(16#1124#) := 16#F4#;
        SFDP_array(16#1125#) := 16#FF#;
        SFDP_array(16#1126#) := 16#FB#;
        SFDP_array(16#1127#) := 16#01#;
        SFDP_array(16#1128#) := 16#F4#;
        SFDP_array(16#1129#) := 16#7F#;
        SFDP_array(16#112A#) := 16#03#;
        SFDP_array(16#112B#) := 16#00#;
        SFDP_array(16#112C#) := 16#F1#;
        SFDP_array(16#112D#) := 16#7F#;
        SFDP_array(16#112E#) := 16#00#;
        SFDP_array(16#112F#) := 16#00#;
        SFDP_array(16#1130#) := 16#FE#;
        SFDP_array(16#1131#) := 16#04#;
        SFDP_array(16#1132#) := 16#00#;
        SFDP_array(16#1133#) := 16#FF#;
        SFDP_array(16#1134#) := 16#F2#;
        SFDP_array(16#1135#) := 16#FF#;
        SFDP_array(16#1136#) := 16#FF#;
        SFDP_array(16#1137#) := 16#01#;
        SFDP_array(16#1138#) := 16#FF#;
        SFDP_array(16#1139#) := 16#05#;
        SFDP_array(16#113A#) := 16#00#;
        SFDP_array(16#113B#) := 16#FF#;
        SFDP_array(16#113C#) := 16#F4#;
        SFDP_array(16#113D#) := 16#FF#;
        SFDP_array(16#113E#) := 16#FF#;
        SFDP_array(16#113F#) := 16#01#;

        WAIT;
    END PROCESS SFDPPreload;

    ---------------------------------------------------------------------------
    ---- File Read Section - Preload Control
    ---------------------------------------------------------------------------

    default:    PROCESS

    -- text file input variables
        FILE mem_f            : text  is  mem_file;
        FILE otp_f            : text  is  otp_file;
        VARIABLE ind          : NATURAL RANGE 0 TO AddrRANGE := 0;
        VARIABLE otp_ind      : NATURAL RANGE 16#000# TO 16#3FF# := 16#000#;
        VARIABLE buf          : line;

BEGIN
    --Preload Control
    ---------------------------------------------------------------------------
    -- File Read Section
    ---------------------------------------------------------------------------
         -- memory preload
        IF (mem_file(1 to 4) /= "none" AND UserPreload = 1) THEN
            ind := 0;
            Mem := (OTHERS => MaxData);
            WHILE (not ENDFILE (mem_f)) LOOP
                READLINE (mem_f, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF ind > AddrRANGE THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "memory address range"
                            SEVERITY warning;
                    ELSE
                        ind := h(buf(2 to 8)); --address
                    END IF;
                ELSE
                    Mem(ind) := h(buf(1 to 2));
                    IF ind < AddrRANGE THEN
                        ind := ind + 1;
                    END IF;
                END IF;
            END LOOP;
        END IF;

         -- memory preload
        IF (otp_file(1 to 4) /= "none" AND UserPreload = 1) THEN
            otp_ind := 16#000#;
            Otp := (OTHERS => MaxData);
            WHILE (not ENDFILE (otp_f)) LOOP
                READLINE (otp_f, buf);
                IF buf(1) = '/' THEN
                    NEXT;
                ELSIF buf(1) = '@' THEN
                    IF otp_ind > 16#3FF# OR otp_ind < 16#000# THEN
                        ASSERT false
                            REPORT "Given preload address is out of" &
                                   "OTP address range"
                            SEVERITY warning;
                    ELSE
                        otp_ind := h(buf(2 to 4)); --address
                    END IF;
                ELSE
                    Otp(otp_ind) := h(buf(1 to 2));
                    otp_ind := otp_ind + 1;
                END IF;
            END LOOP;
        END IF;

        LOCK_BYTE1 := to_slv(Otp(16#10#),8);
        LOCK_BYTE2 := to_slv(Otp(16#11#),8);
        LOCK_BYTE3 := to_slv(Otp(16#12#),8);
        LOCK_BYTE4 := to_slv(Otp(16#13#),8);

    WAIT;

END PROCESS default;

END vhdl_behavioral;

