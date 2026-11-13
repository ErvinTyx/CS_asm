# Maintaining `1.asm`

`1.asm` is a DOS real-mode ice-cream shop program using MASM syntax and only
8086 instructions. It holds one admin account, one replaceable user account,
and sales totals in memory. Closing the process resets accounts and totals.
Earlier assembly sources are archived in [legacy/](../legacy/README.md) and
are not required by the current application.

## Finding the code

Search for the procedure names below; the source has matching section comments.

| Area | Entry points | Responsibility |
| --- | --- | --- |
| Startup/navigation | `MAIN` | Initialize DS, transform stored credentials once, dispatch login/signup and role menus |
| Credential input | `GET_E_U`, `GET_E_P` | Read up to 15 printable characters, support backspace/Escape, terminate buffers with `$` |
| Signup | `SIGNUP_VALIDATION`, `VALIDATION_P_SIGNUP`, `MOVE_UP_USER` | Check password requirements and replace the in-memory user |
| Credential comparison | `ENCRYPTION_P`, `LOCK_ENCRYPTION_U/A`, `VALIDATION_UIDP` | Apply matching legacy rotate/XOR transforms and identify admin/user |
| User orders | `USER_INTERFACE_P` | Normalize flavour, validate quantity, show subtotal, process an order |
| Order calculation | `CAL_QTY_UI`, `CAL_TAXNTOTAL` | Compute quantity, subtotal, tax and payable; request acceptance and handle Y/N |
| Sales acceptance | `RECORD_ORDER`, `ADD_CHECKED48`, `COPY_WORDS_DS` | Stage changes, check limits, copy accepted totals back |
| Reporting | `SALESREPORT`, `PRINT_UNSIGNED48` | Read totals and format complete unsigned values |
| Admin | `ADMIN_INTERFACE_P`, `AC_2_P` | Report, open/close orders, terminate, log out |

`DECRYPTION_P` is an inverse-transform helper retained in the source; no current
menu calls it. The credential-transform routines still share repeated code.
Consolidating those routines would benefit from dedicated login/signup tests;
the current automated suite focuses on ordering and sales.

## Numeric representation and layout

Every order quantity/subtotal/tax/payable and accumulated sales value uses three
16-bit words, least significant first:

```text
byte +0: low word    byte +2: middle word    byte +4: high word
value = low + middle * 65536 + high * 4294967296
```

Money is integer sen. For example, 580 means RM5.80. Quantities are limited to
999,999,999; each money total is limited to 99,999,999,999 sen (RM999,999,999.99).
The storage has more capacity than those business limits.
`VALUE_WORDS=3` describes the fixed representation; changing it alone does not
extend the arithmetic helpers, which explicitly access offsets 0, 2, and 4.

The live ledger is contiguous, beginning at `SALESQTY`:

| Field | Byte offset | Size | Meaning |
| --- | ---: | ---: | --- |
| `SALESQTY` | 0 | 30 | Five quantities, six bytes each |
| `SALESREVENUE` | 30 | 30 | Five subtotal revenues in sen |
| `TOTALSALESQTY` | 60 | 6 | Combined quantity |
| `TOTALINCOME` | 66 | 6 | Combined subtotal revenue, excluding tax |
| `TOTALTAX` | 72 | 6 | Sum of accepted orders' rounded tax |

`SALES_LEDGER_WORDS` and the staging offsets are derived from these labels.
Do not insert unrelated data between these fields. `PROPOSED_TOTALS` is a
separate scratch copy of the ledger; rejected scratch contents are discarded.

`FLAVOUR_IDS`, `ARRAYOFPRICE`, `REPORT_ROWS`, the report strings, and both ledger
arrays use the order D, A, O, G, M. Their counts must match `FLAVOUR_COUNT`.
The unit-price table and selected `PRICE` remain 16-bit values because menu
prices fit one word.

## Following an order

1. `USER_INTERFACE_P` accepts D/A/O/G/M, including lowercase input, then reads
   exactly two quantity characters. Only 01–10 reach calculation.
2. `CAL_QTY_UI` converts those ASCII digits in place and computes the subtotal.
   The full `MUL PRICE` result is preserved from DX:AX.
3. `CAL_TAXNTOTAL` calculates tax and the nearest-5-sen payable bill.
4. `RECORD_ORDER` copies the live ledger to scratch and checks five additions:
   flavour quantity, combined quantity, flavour revenue, combined revenue, tax.
5. Only after all checks pass is the scratch ledger copied back. Failure leaves
   every live total unchanged and displays a limit message instead of payment
   instructions. There is no second recording step when answering Y/N.
6. Y returns to the order menu; N returns to login. This choice applies after
   either acceptance or rejection.

The program records an accepted order before displaying payment instructions;
it does not implement payment confirmation or an order-history list.

## Rounding and reports

The current tax rate is 8%. With `subtotal` expressed in sen:

```text
tax     = (subtotal * 8 + 50) / 100       [integer quotient]
payable = ((subtotal + tax + 2) / 5) * 5 [integer quotient]
```

For one durian: subtotal 580 sen, tax 46 sen, payable 625 sen. For ten:
subtotal 5800 sen, tax 464 sen, payable 6265 sen.

Tax is rounded separately for each order. Two single-durian orders contribute
92 sen tax; recomputing 8% from their combined subtotal would give 93 sen.
Therefore reports read recorded tax instead of recalculating it. Payment
rounding changes neither subtotal income nor tax totals.

Per-order tax/division uses a 16-bit quotient because 10 items at the highest
price of 580 sen gives a maximum subtotal of 5800 sen. If quantities, prices,
or tax rates grow, revisit that bound in `CAL_TAXNTOTAL` before changing menus.

`PRINT_UNSIGNED48` divides a scratch copy high word first, carrying each
remainder into the next division. CH selects 0 or 2 decimal places; CL supplies
the minimum field width. `FORMAT_MONEY` sets CH=2. Report quantities use nine
columns, money uses twelve, and every table row is 54 characters wide. There
are no grouping commas or truncated leading digits. Global formatter scratch
means this routine must not be called recursively or from interrupt handlers.

## Assembly conventions and checks

DS addresses DGROUP throughout normal execution. Helpers use DS for both copy
operands, so they do not require ES to be initialized. BP is used as an offset
counter and added to SI; using `[BP]` directly would select SS by default.

`ADD_CHECKED48` returns CF=1 for overflow or a value above its inclusive limit.
It may modify a rejected candidate, so only pass scratch storage. Do not insert
flag-changing instructions between ADD/ADC steps or between a checked call and
its carry test. `COPY_WORDS_DS` requires a positive word count and disjoint
buffers. Routine comments list inputs, outputs, and register usage.

`RETURN_FLAG` controls order navigation: 0 pending, `RETURN_TO_MENU` (1),
`RETURN_TO_LOGIN` (2). `JUMP` controls return from admin to `MAIN`: 1 exits,
0 goes to login. `TYPE_LOG_IN` is 0 invalid, 1 admin, 2 user. These are separate
protocols despite sharing numeric values.

To verify changes, follow [the test instructions](../tests/README.md). The tests
compile the actual source in 8086 mode and execute its machine code. Boundary
fixtures seed the ledger directly; normal order fixtures exercise calculations,
acceptance, rejection, rounding, and repeated reports. Login/signup and full
DOS screen behaviour still require separate verification when changed.
