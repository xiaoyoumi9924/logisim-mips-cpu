# 计算机组成原理课程设计 · 基于 Logisim-evolution 的 MIPS CPU

![Logisim-evolution](https://img.shields.io/badge/Logisim--evolution-3.9.0-1f6feb)
![License](https://img.shields.io/badge/license-MIT-3fb950)
![Circuits](https://img.shields.io/badge/circuits-8-8957e5)

从触发器一路搭到五级流水线：8 个 Logisim-evolution 工程，覆盖计数器、乘法器、
寄存器堆、64 KB 存储器、ALU、硬布线控制器，以及最终的单周期与流水线 MIPS CPU。

> A MIPS CPU built from scratch in Logisim-evolution - counter, multiplier, register
> file, 64 KB memory, ALU, hardwired controller, and both a single-cycle and a
> 5-stage pipelined CPU.

## 快速开始

### 第一步：下载并安装 Logisim-evolution 3.9.0

本项目所有电路都是用 **Logisim-evolution 3.9.0** 画的，请使用这个版本打开
（老版 Logisim 和某些新版本可能无法正确加载）。

1. 打开官方发布页：
   **[github.com/logisim-evolution/logisim-evolution/releases](https://github.com/logisim-evolution/logisim-evolution/releases)**
2. 找到 **v3.9.0** 那一版，按自己的系统下载安装包：

   | 系统 | 要下载的文件 |
   | --- | --- |
   | Windows 64 位 | `logisim-evolution-3.9.0-x86_64.msi`（如果下到的是 `.zip`，解压后里面就是同一个 MSI） |
   | macOS | `logisim-evolution-3.9.0-*.dmg` |
   | Linux | `logisim-evolution-3.9.0-*.deb` / `.rpm` / `.AppImage` |

3. 双击安装。**Windows 安装时会弹出 UAC 管理员权限提示，点「是」即可**：
   MSI 默认把程序装到 `C:\Program Files\logisim-evolution`，还会注册 `.circ`
   文件关联，所以需要管理员权限。一路「下一步」装完就行。
4. 装好后从开始菜单启动，或者直接双击任意 `.circ` 文件打开。

> 没有管理员权限、或者不想装进系统里？仓库里的 `tools/setup-logisim.ps1`
> 可以从同一个官方安装包解出一份免安装版，见[详细说明](docs/详细设计说明.md#14-免安装方式可选)。

### 第二步：打开 `circuits/` 里的电路

所有电路都在 **`circuits/`** 目录下，文件名按课程任务点编号，建议由易到难按顺序打开：

```
circuits/2.2-计数器.circ        →  2.3-乘法器.circ
circuits/3.1-寄存器堆.circ      →  3.2-存储器.circ
circuits/3.3-ALU模块.circ       →  3.4-控制器.circ
circuits/4.1-单周期CPU.circ     →  4.2-流水线CPU.circ   （重头戏）
```

打开后，用工具栏上的时钟按钮（或快捷键 `Ctrl+T`）一下一下打节拍，配合电路里的
数码管和 LED 观察寄存器、PC、ALU 结果的变化。每个电路具体怎么看，写在
[详细说明](docs/详细设计说明.md)里。

### 第三步（可选）：一键自检

不打开图形界面也能检查所有电路是否完好（需要系统里有 Java 17 以上）：

```powershell
pwsh -File scripts\verify-circuits.ps1
```

## 项目结构

```
.
├── circuits/                 8 个 Logisim 工程，按任务点编号
├── docs/
│   ├── 详细设计说明.md        安装、调试、每个模块的设计细节（推荐先看这份）
│   ├── 2025ALU设计模板.pdf    课程任务书：ALU 实验要求与引脚定义
│   ├── 2025控制器设计模板.pdf  课程任务书：控制器实验要求与信号定义
│   ├── MIPS指令集手册.pdf     指令编码参考
│   ├── Logisim安装及使用说明 v1.0.docx
│   └── images/               电路截图（欢迎补充）
├── scripts/
│   ├── logisim.cmd           启动免安装版 Logisim（用 tools 里的那份）
│   └── verify-circuits.ps1   无界面加载全部电路做自检
├── tools/setup-logisim.ps1   从官方安装包解出免安装版 Logisim
├── LICENSE                   MIT
└── README.md
```

## 电路清单

| 任务点 | 工程 | 主要子电路 | 做了什么 |
| --- | --- | --- | --- |
| 2.2 计数器 | [`circuits/2.2-计数器.circ`](circuits/2.2-计数器.circ) | `count13`、`count_pro` | 模 13 同步计数器，带进位输出与数码管显示 |
| 2.3 乘法器 | [`circuits/2.3-乘法器.circ`](circuits/2.3-乘法器.circ) | `muti`、`control`、`shift`、`Add_1`、`Add_7` | 8 位移位-相加乘法器，计数器控制迭代 |
| 3.1 寄存器堆 | [`circuits/3.1-寄存器堆.circ`](circuits/3.1-寄存器堆.circ) | `MIPS_32x32_reg`、`group_0`、`group_123` | 32×32 位寄存器堆：双读口、单写口、写地址译码 |
| 3.2 存储器 | [`circuits/3.2-存储器.circ`](circuits/3.2-存储器.circ) | `ROM_64KB_32bit`、`RAM_64KB_32bit`、`RAM_pro` | 64 KB×32 位 ROM/RAM，含读写自检电路 |
| 3.3 ALU | [`circuits/3.3-ALU模块.circ`](circuits/3.3-ALU模块.circ) | `ALU` | 32 位 ALU：加、减、或、比较置位、移位，3 位控制码选通 |
| 3.4 控制器 | [`circuits/3.4-控制器.circ`](circuits/3.4-控制器.circ) | `cu`、`alu_control` | 硬布线主控 + ALU 控制，输出全部控制信号 |
| 4.1 单周期 CPU | [`circuits/4.1-单周期CPU.circ`](circuits/4.1-单周期CPU.circ) | `main` + 上述模块 | 完整单周期 MIPS：取指 / 译码 / 执行 / 访存 / 写回 |
| 4.2 流水线 CPU | [`circuits/4.2-流水线CPU.circ`](circuits/4.2-流水线CPU.circ) | `IFID`、`IDEX`、`EXMEM`、`MEMWB`、`Forwarding_controlA/B`、`Hazard` | 五级流水：数据前推 + load-use 冒险暂停 |

## 支持的指令

| 指令 | 类型 | opcode | func | 含义 |
| --- | --- | --- | --- | --- |
| `addu` | R | `000000` | `100001` | 加法 |
| `sub` | R | `000000` | `100010` | 减法 |
| `slt` | R | `000000` | `101010` | 有符号比较，小于则置 1 |
| `lui` | I | `001111` | — | 立即数装入高 16 位 |
| `ori` | I | `001101` | — | 立即数零扩展后按位或 |
| `bne` | I | `000101` | — | 不等则跳转 |
| `lw` / `sw` | I | `100011` / `101011` | — | 取字 / 存字 |
| `stp` | — | `111111` | — | 停机，停止 PC 更新 |

两个 CPU 的指令 ROM 里都放了测试程序（其中一段循环会触发 load-use 冒险），
可以直接打时钟观察，逐条反汇编见[详细说明](docs/详细设计说明.md#9-内置测试程序)。

## 详细文档

**📖 [详细设计说明](docs/详细设计说明.md)** —— 安装与调试、每个模块的引脚和设计思路、
指令编码与控制信号表、单周期与流水线数据通路、内置测试程序逐条讲解、
无界面自检、二次开发建议、常见问题。

## 许可

电路设计部分以 [MIT License](LICENSE) 开源，欢迎取用、修改、用在自己的实验课上。

> 请遵守所在学校的学术诚信要求：可以参考实现思路，但不要直接把本仓库当作
> 自己的课程作业提交。
