BBSTRO for Vector-06C
=====================
![bbstro screenshot](https://github.com/svofski/bazis-bbstro/raw/master/bazis-bbstro.jpg "tvnoise screenshot")

It is of course best viewed on a real machine with a CRT display.

The source code is written in 8080 assembly and assembled using web-based [Pretty 8080 Assembler](https://svofski.github.io/pretty-8080-assembler/)

You can load the code directly into the assembler using [this link](https://svofski.github.io/pretty-8080-assembler/?https://raw.githubusercontent.com/svofski/bazis-bbstro/master/tvnoise.asm).
Use RUN button to execute it in the built-in emulator.

Making the packed 1K version step-by-step
-----------------------------------------
  1. Using the assembler link above, save ``tvnoise.rom`` to ``zx7mini/tvnoise.rom``
  2. Assemble ``zx7mini/dzx7mini-back.asm`` to ``zx7mini/dz7mini-fwd.4000``
  3. Run ``bat.bat`` in ``zx7mini`` directory. It will create a packed version and build a self-extracting rom.
  4. If you have [bin2wav](https://github.com/svofski/bin2wav) installed, same .bat file will also create a WAV file for loading into a real Vector-06C.
