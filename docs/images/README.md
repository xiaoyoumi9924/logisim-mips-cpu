# 电路截图放这里

在 Logisim-evolution 里打开电路后，用 `文件 → 导出为图片`（或菜单
`File → Export As Image`）导出 PNG，放到本目录，然后在根目录 README 里引用，
例如：

```markdown
![流水线 CPU 数据通路](docs/images/pipeline.png)
```

建议每个主要电路各截一张图（计数器、乘法器、寄存器堆、存储器、ALU、
控制器、单周期 CPU、流水线 CPU），文件名与 `circuits/` 中的编号保持一致。
