The sales tests compile the actual `1.asm` with JWasm in 8086 mode (`-0`),
with warnings treated as errors, and run the resulting DOS MZ machine code
using Unicorn. Only DOS console input/output and BIOS screen calls are hooked;
quantity calculation, tax, rounding, formatting, and ledger updates execute
as assembled instructions. This does not replace testing on a full DOS system.

Install the Python dependency in your Python environment:

```sh
python3 -m pip install -r tests/requirements.txt
```

With a built MASM-compatible [JWasm](https://github.com/JWasm/JWasm) executable:

```sh
JWASM_BIN=/path/to/jwasm python3 -m unittest discover -s tests -v
```

`JWASM_BIN` is optional if `jwasm` is on PATH. Do not use `JWASM` for this path:
JWasm interprets that environment variable as command-line options.

The tests cover zero sales, decimal transitions, low/middle-word carries,
maximum quantities and money, each limit rejecting an entire order, recovery
after rejection, all 50 legal flavour/quantity combinations, per-order tax
accumulation, nearest-5-sen payment rounding, report alignment and repeated
generation, and the existing flavour/quantity validation flow. Boundary tests
seed the ledger directly so they do not need millions of interactive orders.

Totals mean quantity sold, subtotal revenue excluding tax, and the sum of
the tax rounded to a sen on each accepted order. The nearest-5-sen adjustment
applies to the payable bill; it is not added to subtotal revenue or tax.
