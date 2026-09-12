# 计算机组成原理课程设计 · 基于 Logisim-evolution 的 MIPS CPU

一个从时序电路一路搭到 32 位 MIPS 流水线 CPU 的课程设计存档。全部电路使用
[Logisim-evolution](https://github.com/logisim-evolution/logisim-evolution) 绘制，
共 8 个 `.circ` 工程，按课程任务点顺序整理。

> A MIPS CPU course project built from scratch in Logisim-evolution: counter,
> multiplier, register file, 64 KB memory, ALU, hardwired controller, and both a
> single-cycle and a fully bypassed 5-stage pipelined CPU.

## 内容清单

| 任务点 | 工程文件 | 主要子电路 | 说明 |
| --- | --- | --- | --- |
| 2.2 时序电路 · 计数器 | [`circuits/2.2-计数器.circ`](circuits/2.2-计数器.circ) | `count13`、`count_pro` | 13 进制同步计数器，附级联进位输出与显示电路 |
| 2.3 时序电路 · 乘法器 | [`circuits/2.3-乘法器.circ`](circuits/2.3-乘法器.circ) | `muti`、`control`、`shift`、`Add_7` | 8 位时序乘法器（移位-相加以状态机控制） |
| 3.1 寄存器堆 | [`circuits/3.1-寄存器堆.circ`](circuits/3.1-寄存器堆.circ) | `MIPS_32x32_reg`、`group_0`、`group_123` | 32×32 位 MIPS 寄存器堆：双读口、单写口、写地址译码 |
| 3.2 存储器实验 | [`circuits/3.2-存储器.circ`](circuits/3.2-存储器.circ) | `ROM_64KB_32bit`、`RAM_64KB_32bit`、`RAM_pro` | 64 KB×32 位 ROM / RAM，16 位字节地址，含读写自检电路 |
| 3.3 ALU 模块 | [`circuits/3.3-ALU模块.circ`](circuits/3.3-ALU模块.circ) | `ALU` | 32 位 ALU：加法、减法、逻辑或、比较置位、移位，3 位 `alu_control` 选通 |
| 3.4 控制器 | [`circuits/3.4-控制器.circ`](circuits/3.4-控制器.circ) | `cu`、`alu_control` | 硬布线主控制器 + ALU 控制器，输出全部数据通路控制信号 |
| 4.1 单周期 CPU | [`circuits/4.1-单周期CPU.circ`](circuits/4.1-单周期CPU.circ) | `main` + 上述全部模块 | 完整单周期 MIPS：取指-译码-执行-访存-写回，含 PC、存储器与显示 |
| 4.2 流水线 CPU | [`circuits/4.2-流水线CPU.circ`](circuits/4.2-流水线CPU.circ) | `IFID`、`IDEX`、`EXMEM`、`MEMWB`、`Forwarding_controlA/B`、`Hazard` | 五级流水 CPU：流水寄存器 + 数据前推 + load-use 冒险暂停 |

## 快速开始

### 1. 打开电路（图形界面）

仓库自带一键脚本，双击或在终端执行即可：

```bat
rem 打开空白工程
scripts\logisim.cmd

rem 直接打开某个电路，例如流水线 CPU
scripts\logisim.cmd circuits\4.2-流水线CPU.circ
```

### 2. 无界面自检（不需要打开窗口）

```powershell
pwsh -File scripts\verify-circuits.ps1
```

它用 Logisim-evolution 的 TTY 模式逐个加载 `circuits/` 下的工程并打印元件统计。
能加载成功，就说明文件完整、子电路没有缺失。当前结果：

```
  [ OK ]  2.2-计数器.circ              15 component rows
  [ OK ]  2.3-乘法器.circ              21 component rows
  [ OK ]  3.1-寄存器堆.circ             14 component rows
  [ OK ]  3.2-存储器.circ              17 component rows
  [ OK ]  3.3-ALU模块.circ            14 component rows
  [ OK ]  3.4-控制器.circ              11 component rows
  [ OK ]  4.1-单周期CPU.circ           28 component rows
  [ OK ]  4.2-流水线CPU.circ           37 component rows
```

### 3. 自己还原一份 Logisim-evolution（免安装）

`.circ` 文件由 **Logisim-evolution 3.9.0** 生成，用 Logisim-evolution 打开即可
（原始 Logisim 无法识别部分元件）。官方 Windows 版是 jpackage 打包的 MSI，
安装需要管理员权限；本仓库提供一个不需要管理员权限的做法：

1. 到 [Logisim-evolution Releases](https://github.com/logisim-evolution/logisim-evolution/releases)
   下载 `logisim-evolution-3.9.0-x86_64.zip`；
2. 放到 `_local/` 目录（该目录不会提交到仓库）；
3. 执行：

```powershell
pwsh -File tools\setup-logisim.ps1
```

脚本会把 MSI 里的程序、jar 和自带 JRE 解包到 `tools/logisim-evolution-3.9.0/`，
不改注册表、不写 Program Files，删掉文件夹即完全卸载。

如果需要用命令行方式（`-t stats`、`-w` 测试向量等）操作电路，系统里还要有一个
JDK/JRE 17 以上版本；自带 JRE 只包含图形启动所需的部分。

## 目录结构

```
.
├── circuits/                 8 个 Logisim 工程（按任务点编号）
├── docs/                     课程模板、指令集手册、Logisim 使用说明
├── scripts/
│   ├── logisim.cmd           启动免安装版 Logisim-evolution
│   └── verify-circuits.ps1   无界面加载全部电路做自检
├── tools/
│   ├── setup-logisim.ps1     从官方 MSI/ZIP 解包出免安装版（生成物不进仓库）
│   └── logisim-evolution-3.9.0/   ← 由脚本生成，已被 .gitignore 忽略
├── _local/                   本地私有资料（安装包 / 个人课表 / 教材），不进仓库
├── LICENSE
└── README.md
```

## 设计说明

### 支持的指令集

控制器按 opcode(6 bit) + func(6 bit) 译码，实现下列指令：

| 指令 | 格式 | 说明 |
| --- | --- | --- |
| `add` / `sub` / `slt` | R 型 | 由 `func` 经 `alu_control` 选通 |
| `ori` | I 型 | 立即数零扩展后与寄存器按位或 |
| `lui` | I 型 | 立即数装入高 16 位 |
| `lw` / `sw` | I 型 | 16 位字节地址立即数符号扩展后与基址寄存器相加 |
| `bne` | I 型 | 不等则跳转，偏移量左移 2 位后加到 PC+4 |
| `STP` (`0xFC000000`) | — | 停机指令，`stop` 信号拉高后 PC 停止更新 |

主控制器输出 `RegDst`、`ALUSrc`、`Branch`、`MemRead`、`Memwrite`、`Regwrite`、
`MemtoReg`、`EXtop`、`stop` 以及 3 位 `ALUop`；`alu_control` 再由 `ALUop` 与
`func` 生成 3 位 `ALUcontrol`。

### 数据通路

- **寄存器堆**：32 个 32 位寄存器，由 4 组 8 寄存器（`group_0`、`group_123` 等）
  拼成；两个读端口组合逻辑输出，写端口在时钟上升沿写入，`$0` 恒为 0。
- **指令存储器**：`14 位字地址 × 32 位`（即 16 K 字 / 64 KB）。
- **数据存储器**：`16 位字节地址 × 32 位`（64 KB），字访问时忽略低 2 位。
- **ALU**：加法器、减法器、OR 门、比较器、移位器经 8 选 1 多路选择器输出，
  同时给出 `zero` 标志供分支判断使用。
- **PC**：16 位计数器 `Count`，`Add4` 负责 PC+4，`shift_left_2` 负责分支偏移。

### 流水线

五级流水，`IF → ID → EX → MEM → WB`，每级之间由 `IFID`、`IDEX`、`EXMEM`、
`MEMWB` 四个流水寄存器隔离：

- `Forwarding_controlA` / `Forwarding_controlB` 比较 `EX/MEM`、`MEM/WB` 的目的
  寄存器与当前 ID/EX 的源寄存器，产生前推选择信号，避免不必要的暂停；
- `Hazard` 检测 load-use 冒险（`ID/EX` 是 `lw` 且其目的寄存器被 `IF/ID` 使用），
  拉高 `stall` 冻结 PC 与 IF/ID，并在 ID/EX 插入气泡；
- 分支在 ID 级由比较器判断 `IFID_Rs`/`IFID_Rt`，命中时把 NPC 送入 PC。

### 内置测试程序

两个 CPU 的指令 ROM 里都放了测试程序，可以直接打开电路、打上时钟观察。

**单周期 CPU**（4 条）：

```asm
lw   $1, 0($0)      # 8c010000
sw   $1, 4($0)      # ac010004
halt                # fc000000
sw   $1, 8($0)      # ac010008
```

**流水线 CPU**（17 条）：初始化寄存器后用循环把递推序列写入数据存储器，
再用 `slt` + `bne` 控制循环次数，最后停机——正好覆盖前推和 load-use 冒险。

```asm
ori  $1, $0, 1          # 34010001
ori  $2, $0, 1          # 34020001
ori  $7, $0, 4          # 34070004   步长 4
ori  $5, $0, 0x0100     # 34050100   循环上界 256
lui  $8, 0x0000         # 3c080000   基址 $8 = 0
add  $6, $8, $5         # 01053021   $6 = $8 + $5
add  $3, $1, $2         # 00221821   循环体：$3 = $1 + $2
ori  $1, $2, 0          # 34410000
ori  $2, $3, 0          # 34620000
sw   $2, 0($8)          # ad020000
lw   $4, 0($8)          # 8d040000   load-use 冒险
bne  $2, $4, +3         # 14440003
add  $8, $8, $7         # 01074021
slt  $9, $8, $6         # 0106482a
bne  $9, $0, -9         # 1520fff7
halt                    # fc000000
bne  $6, $0, -11        # 14c0fff5
```

### 已知限制

- 只实现上表列出的指令，没有 `j` / `jal` / `beq` / 立即数算术指令；
- ALU 的移位器只在实验范围内使用，R 型指令只做了 `add` / `sub` / `slt`；
- 2.3 的乘法器是 8 位版本，便于观察移位-相加过程；
- 数据通路用 Logisim 的 Hex Digit Display / LED 直接观察中间结果，没有做
  完整的自检测试向量。

## 参考资料

`docs/` 中收录了做实验时用到的资料，方便对照阅读：

| 文件 | 用途 |
| --- | --- |
| `2025ALU设计模板.pdf` | 3.3 ALU 实验要求与引脚定义 |
| `2025控制器设计模板.pdf` | 3.4 控制器实验要求与信号定义 |
| `MIPS指令集手册.pdf` | 指令编码参考 |
| `Logisim安装及使用说明 v1.0.docx` | 课程提供的软件使用说明 |

教材参考：《计算机组成与设计：硬件/软件接口》（第五版，中文版）——因体积与版权
原因未收录在本仓库中。

> 上述课程材料与教材的版权归原作者 / 课程组所有，这里仅作学习存档。若版权方
> 有异议，请提 issue，会立即移除。

## 许可

电路设计部分以 [MIT License](LICENSE) 开源，欢迎取用、修改、用于自己的实验课。
如果这份存档帮到了你，给个 star 就是最好的回礼。

> 请遵守所在学校的学术诚信要求：可以参考实现思路，但不要直接提交本仓库作为
> 你自己的课程作业。
