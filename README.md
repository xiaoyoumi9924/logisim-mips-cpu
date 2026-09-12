 # 基于 Logisim-evolution 设计的 MIPS CPU

![Logisim-evolution](https://img.shields.io/badge/Logisim--evolution-3.9.0-1f6feb)
![License](https://img.shields.io/badge/license-MIT-3fb950)
![Circuits](https://img.shields.io/badge/circuits-8-8957e5)

从触发器一路搭到五级流水线：8 个 Logisim-evolution 工程，覆盖计数器、乘法器、
寄存器堆、64 KB 存储器、ALU、硬布线控制器，以及最终的单周期与流水线 MIPS CPU。



## 快速开始

### 第一步：安装 Logisim-evolution 3.9.0

本项目所有电路都是用 **Logisim-evolution 3.9.0** 画的。

1. 到 **[Releases 页面](../../releases/latest)** 下载
   **`logisim-evolution-3.9.0-x86_64.msi`**
2. 双击安装，**弹出 UAC 管理员权限提示时点「是」**
3. 图文安装步骤见
   **[`docs/Logisim安装及使用说明 v1.0.docx`](docs/Logisim安装及使用说明%20v1.0.docx)**。
4. 装好后从开始菜单启动，或者直接双击任意 `.circ` 文件打开。

> macOS / Linux 用不了这个 MSI，请到[官方 Release](https://github.com/logisim-evolution/logisim-evolution/releases)



### 第二步：打开 `circuits/` 里的电路

所有电路都在 **`circuits/`** 目录下，点表格里的文件名就能打开。

| # | 电路文件 | 阶段 | 主要子电路 | 内容 |
| :-: | --- | --- | --- | --- |
| 1 | [`2.2-计数器.circ`](circuits/2.2-计数器.circ) | 时序基础 | `count13`、`count_pro` | 模 13 计数器，带进位输出与数码管显示 |
| 2 | [`2.3-乘法器.circ`](circuits/2.3-乘法器.circ) | 时序基础 | `muti`、`control`、`shift`、`Add_1`、`Add_7` | 8 位移位-相加乘法器，计数器控制迭代 |
| 3 | [`3.1-寄存器堆.circ`](circuits/3.1-寄存器堆.circ) | 四大部件 | `MIPS_32x32_reg`、`group_0`、`group_123` | 32×32 位寄存器堆：双读口、单写口、写地址译码 |
| 4 | [`3.2-存储器.circ`](circuits/3.2-存储器.circ) | 四大部件 | `ROM_64KB_32bit`、`RAM_64KB_32bit`、`RAM_pro` | 64 KB×32 位 ROM / RAM，含读写自检 |
| 5 | [`3.3-ALU模块.circ`](circuits/3.3-ALU模块.circ) | 四大部件 | `ALU` | 32 位 ALU：加、减、或、比较置位、移位 |
| 6 | [`3.4-控制器.circ`](circuits/3.4-控制器.circ) | 四大部件 | `cu`、`alu_control` | 硬布线主控 + ALU 控制，输出全部控制信号 |
| 7 | [`4.1-单周期CPU.circ`](circuits/4.1-单周期CPU.circ) | 整机 | 上述模块 + `Count`、`Add4`、`EX_control` | 单周期 MIPS：取指 / 译码 / 执行 / 访存 / 写回 |
| 8 | [`4.2-流水线CPU.circ`](circuits/4.2-流水线CPU.circ) | 整机 | `IFID`、`IDEX`、`EXMEM`、`MEMWB`、`Forwarding_controlA/B`、`Hazard` | 五级流水：数据前推 + load-use 冒险暂停 |


[详细说明](docs/详细设计说明.md)。


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
├── tools/
│   └── setup-logisim.ps1     从官方安装包解出免安装版
├── LICENSE                   MIT
└── README.md
```



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



## 详细文档

**📖 [详细设计说明](docs/详细设计说明.md)** —— 安装与调试、每个模块的引脚和设计思路、
指令编码与控制信号表、单周期与流水线数据通路、内置测试程序逐条讲解、
无界面自检、二次开发建议、常见问题。

## 许可

电路设计部分以 [MIT License](LICENSE) 开源，欢迎取用、修改、用在自己的实验课上。
