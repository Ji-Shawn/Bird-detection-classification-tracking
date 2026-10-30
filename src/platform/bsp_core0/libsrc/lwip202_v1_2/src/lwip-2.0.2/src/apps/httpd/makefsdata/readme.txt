Project directory note
======================
本文件位于 src/platform/ 下的第三方 lwIP BSP 库中，说明的是 HTTP
静态资源转换工具，不是鸟类识别项目的运行或构建入口。当前工程导览
请从仓库根目录 readme.md、src/readme.md 和 build/readme.md 阅读。
以下保留原工具说明，相关相对目录以本文件所在的 makefsdata/ 为基准。

This directory contains a script ('makefsdata') to create C code suitable for
httpd for given html pages (or other files) in a directory.

There is also a plain C console application doing the same and extended a bit.

Usage: htmlgen [targetdir] [-s] [-i]s
   targetdir: relative or absolute path to files to convert
   switch -s: toggle processing of subdirectories (default is on)
   switch -e: exclude HTTP header from file (header is created at runtime, default is on)
   switch -11: include HTTP 1.1 header (1.0 is default)

  if targetdir not specified, makefsdata will attempt to
  process files in subdirectory 'fs'.
