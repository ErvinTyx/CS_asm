# CS_asm · Ice-Cream Shop

**A menu-driven ice-cream ordering and sales management program written in
8086 assembly for DOS.**

The program simulates a small ice-cream counter: customers log in, choose a
flavour, and receive an item subtotal, tax amount, and rounded bill. An
administrator can view the accumulated sales report and open or close ordering.

Built as assembly coursework, it demonstrates keyboard input, account
validation, role-based menus, integer arithmetic, and formatted console output.
The main application is [1.asm](1.asm). Earlier coursework and prototypes are
preserved separately in [legacy/](legacy/README.md).

[Features](#features) · [Example order](#example-order) ·
[Getting started](#getting-started) · [Testing](#testing) ·
[Code guide](docs/1-asm-maintenance.md)

## Features

### Customer accounts and ordering

- **Login and signup:** separate customer and administrator interfaces. Signup
  replaces the single customer account held in memory.
- **Credential input:** passwords appear as `*`; username and password entry
  support Backspace and Escape. Signup includes length and character checks.
- **Five flavours:** select by a single-letter code, in uppercase or lowercase.
- **Quantity validation:** enter exactly two digits, from `01` to `10`, for one
  flavour per order.
- **Bill calculation:** see the subtotal, 8% tax, and total rounded to the
  nearest 5 sen, then proceed to the counter for payment.
- **Repeat purchases:** choose `Y` to order again or `N` to return to login.

### Administrator controls

| Option | Action |
| :---: | --- |
| `1` | View the sales report |
| `2` | Open or close customer ordering |
| `3` | Terminate the program |
| `4` | Log out and return to login |

The sales report shows each flavour's unit price, quantity sold, and subtotal
revenue, followed by the combined quantity, total income, and total tax. It can
be generated repeatedly without changing recorded sales.

### Accurate sales tracking

| Capability | Behaviour |
| --- | --- |
| Quantity totals | Up to **999,999,999** items per flavour and overall |
| Money totals | Up to **RM999,999,999.99** per revenue or tax total |
| Money storage | Integer sen, displayed with two decimal places |
| Tax | Rounded to the nearest sen for each order, then accumulated |
| Payment rounding | Applied once to the complete bill, to the nearest 5 sen |
| Limit handling | Rejects the whole order if any affected total would exceed its limit |
| 8086 compatibility | Uses three 16-bit words per quantity or money value |

Rejected orders leave existing totals unchanged. Report income is the subtotal
revenue before tax; payment-rounding adjustments are separate from revenue and
tax totals. Quantity and money limits both apply, so the money limit can be
reached before the maximum quantity.

## Ice-cream menu

| Code | Flavour | Unit price |
| :---: | --- | ---: |
| `D` | Durian | RM5.80 |
| `A` | Apple | RM4.00 |
| `O` | Orange | RM4.50 |
| `G` | Grape | RM5.00 |
| `M` | Mango | RM4.50 |

## Example order

After logging in as a customer, enter `D` for durian and `10` for the quantity:

| Calculation | Amount |
| --- | ---: |
| 10 × RM5.80 | RM58.00 |
| Tax at 8% | RM4.64 |
| Total before payment rounding | RM62.64 |
| **Payable at the counter** | **RM62.65** |

An accepted order adds 10 items, RM58.00 revenue, and RM4.64 tax to the sales
totals. The program displays payment instructions; it does not process or
confirm an actual payment.

## Getting started

### Build and run

Use a MASM-compatible JWasm assembler to build the DOS executable:

```sh
mkdir -p /tmp/cs-asm-build
/path/to/jwasm -q -0 -WX -mz -Fo/tmp/cs-asm-build/shop.exe 1.asm
```

Run the resulting `shop.exe` in a DOS environment. The interface uses keyboard
input, BIOS screen operations, and ANSI colour sequences; colour rendering
depends on the DOS environment's ANSI support.

### Default demonstration accounts

| Role | Username | Password |
| --- | --- | --- |
| Administrator | `admin` | `admin123` |
| Customer | `USER1` | `USER1` |

Credentials are case-sensitive. These are the initial coursework accounts;
creating a customer account replaces `USER1` for the current session.

Choose `1` on the opening screen to log in, or `2` to sign up. New usernames
must contain 8–15 characters; password entry also allows up to 15 characters.
The program uses a reversible rotate/XOR credential transform as an assembly
exercise.

Accounts and sales totals live in memory. They are reset when the program is
restarted; there is no database, saved order history, or disk persistence.

## Testing

The automated suite compiles the actual assembly in 8086 mode with warnings
treated as errors, then executes the DOS machine code using Unicorn with
console and BIOS hooks.

```sh
python3 -m pip install -r tests/requirements.txt
JWASM_BIN=/path/to/jwasm python3 -m unittest discover -s tests -v
```

The 12 tests cover all 50 flavour/quantity combinations, rounding, zero sales,
decimal transitions, multiword carries, maximum values, whole-order rejection,
recovery after rejection, report alignment, and repeated report generation.

See [tests/README.md](tests/README.md) for setup, coverage, and execution limits.

## Explore the source

| File | Purpose |
| --- | --- |
| [1.asm](1.asm) | Main shop application, menus, arithmetic, and reporting |
| [Maintenance guide](docs/1-asm-maintenance.md) | Procedure map, data layout, order flow, and rounding rules |
| [Execution tests](tests/test_sales.py) | Tests that run the assembled instructions |
| [Testing guide](tests/README.md) | Test dependencies and commands |
| [Legacy sources](legacy/README.md) | Earlier coursework and prototypes kept for reference |

Source comments identify the major sections and document helper inputs,
outputs, register usage, and the carry-handling rules for multiword arithmetic.
