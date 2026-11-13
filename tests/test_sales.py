"""Execute the actual JWasm DOS binary with BIOS/DOS console hooks.

Run: JWASM_BIN=/path/to/jwasm python3 -m unittest discover -s tests -v
Requires the Python unicorn package. No translated arithmetic is executed.
"""
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import unittest

from unicorn import Uc, UC_ARCH_X86, UC_MODE_16, UC_HOOK_INTR
from unicorn.x86_const import *


class Machine:
    def __init__(self, exe, listing):
        self.symbols = {}
        for line in listing.splitlines():
            match = re.match(r"^\s*(\w+)\s+(?:\.\s*)*\s+(?:P Near|P Far|L Near|L Far|Word(?:\[\d+\])?|Byte(?:\[\d+\])?)\s+([0-9A-Fa-f]+)h?\s+(_DATA|_TEXT)", line)
            if match:
                self.symbols[match[1]] = int(match[2], 16)
        header = struct.unpack_from('<14H', exe)
        self.uc = Uc(UC_ARCH_X86, UC_MODE_16)
        self.uc.mem_map(0, 0x100000)
        self.base = 0x1000
        image = bytearray(exe[header[4] * 16:])
        for i in range(header[3]):
            offset, segment = struct.unpack_from('<HH', exe, header[12] + i * 4)
            at = segment * 16 + offset
            struct.pack_into('<H', image, at, (struct.unpack_from('<H', image, at)[0] + self.base) & 0xffff)
        self.uc.mem_write(self.base * 16, bytes(image))
        self.cs = self.base + header[11]
        # MAIN starts with MOV AX,@DATA; use its relocated immediate.
        self.ds = struct.unpack_from('<H', image, header[11] * 16 + header[10] + 1)[0]
        # MZ DGROUP may start before _DATA's word-aligned first byte.
        text_size = int(re.search(r'^_TEXT\s+(?:\.\s*)*\s+16 Bit\s+([0-9A-F]+)', listing, re.M)[1], 16)
        data_bias = (text_size + 1) // 2 * 2 - (self.ds - self.base) * 16
        for line in listing.splitlines():
            match = re.match(r'^\s*(\w+)\s+(?:\.\s*)*\s+(?:Word|Byte)(?:\[\d+\])?\s+[0-9A-Fa-f]+h?\s+_DATA', line)
            if match:
                self.symbols[match[1]] += data_bias
        self.ss = self.base + header[7]
        self.sp = header[8]
        self.uc.reg_write(UC_X86_REG_DS, self.ds)
        self.uc.reg_write(UC_X86_REG_SS, self.ss)
        self.output = ''
        self.keys = []
        self.uc.hook_add(UC_HOOK_INTR, self.interrupt)

    def interrupt(self, uc, number, _):
        if number == 0x10:
            return
        if number != 0x21:
            raise AssertionError(f'Unexpected interrupt {number:#x}')
        ah = uc.reg_read(UC_X86_REG_AH)
        if ah == 9:
            at = uc.reg_read(UC_X86_REG_DS) * 16 + uc.reg_read(UC_X86_REG_DX)
            data = bytes(uc.mem_read(at, 4096)).split(b'$', 1)[0]
            self.output += data.decode('ascii')
            uc.reg_write(UC_X86_REG_AL, 0x24)
        elif ah == 2:
            char = uc.reg_read(UC_X86_REG_DL)
            self.output += chr(char)
            uc.reg_write(UC_X86_REG_AL, char)
        elif ah == 1:
            assert self.keys, 'Program requested unexpected input'
            char = ord(self.keys.pop(0))
            uc.reg_write(UC_X86_REG_AL, char)
            self.output += chr(char)
        else:
            raise AssertionError(f'Unexpected DOS function {ah:#x}')

    def address(self, name, offset=0):
        return self.ds * 16 + self.symbols[name] + offset

    def put(self, name, value, size=6, offset=0):
        self.uc.mem_write(self.address(name, offset), value.to_bytes(size, 'little'))

    def get(self, name, size=6, offset=0):
        return int.from_bytes(self.uc.mem_read(self.address(name, offset), size), 'little')

    def call(self, proc, keys=''):
        self.output = ''
        self.keys = list(keys)
        self.uc.reg_write(UC_X86_REG_CS, self.cs)
        self.uc.reg_write(UC_X86_REG_SP, self.sp - 2)
        self.uc.mem_write(self.ss * 16 + self.sp - 2, b'\x00\xff')
        self.uc.emu_start(self.cs * 16 + self.symbols[proc], self.cs * 16 + 0xff00, count=500000)
        assert self.uc.reg_read(UC_X86_REG_IP) == 0xff00, 'Procedure did not return'
        assert self.uc.reg_read(UC_X86_REG_SP) == self.sp, 'Unbalanced stack'
        return self.output


class SalesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        path = Path(cls.temp.name)
        assembler = os.environ.get('JWASM_BIN') or shutil.which('jwasm')
        if not assembler:
            raise RuntimeError('Set JWASM_BIN to the JWasm executable')
        exe, listing = path / 'sales.exe', path / 'sales.lst'
        subprocess.run([assembler, '-q', '-0', '-WX', '-mz', f'-Fo{exe}', f'-Fl={listing}',
                        str(Path(__file__).resolve().parents[1] / '1.asm')], check=True)
        cls.exe, cls.listing = exe.read_bytes(), listing.read_text()

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def setUp(self):
        self.m = Machine(self.exe, self.listing)

    def state(self):
        return bytes(self.m.uc.mem_read(self.m.address('SALESQTY'), 78))

    def order(self, flavour='D', quantity=1):
        self.m.put('FLAVOURCODE', ord(flavour), 1)
        self.m.put('PRICE', {'D': 580, 'A': 400, 'O': 450, 'G': 500, 'M': 450}[flavour], 2)
        self.m.put('QTY1', ord(str(quantity).zfill(2)[0]), 1)
        self.m.put('QTY2', ord(str(quantity).zfill(2)[1]), 1)
        self.m.call('CAL_QTY_UI')
        return self.m.call('CAL_TAXNTOTAL', 'N')

    def test_report_five_to_six_digits_and_repeated_generation(self):
        for qty in (99999, 100000, 999999999):
            self.m.put('SALESQTY', qty)
            before = self.state()
            first = self.m.call('SALESREPORT')
            self.assertIn(str(qty), first)
            self.assertEqual(first, self.m.call('SALESREPORT'))
            self.assertEqual(before, self.state())

    def test_zero_sales(self):
        report = self.m.call('SALESREPORT')
        self.assertEqual(report.count('0.00'), 7)
        self.assertIn('TOTAL QUANTITY', report)
        self.assertEqual(self.state(), bytes(78))

    def test_report_columns_align_at_maximum_values(self):
        self.m.put('SALESQTY', 999999999)
        self.m.put('SALESREVENUE', 99999999999)
        self.m.put('TOTALINCOME', 99999999999)
        self.m.put('TOTALTAX', 99999999999)
        rows = self.m.call('SALESREPORT').splitlines()[2:]
        self.assertEqual({len(row) for row in rows}, {54})
        table_rows = [row for row in rows if row.count('|') == 5]
        self.assertEqual({tuple(i for i, char in enumerate(row) if char == '|')
                          for row in table_rows}, {(0, 10, 19, 31, 53)})

    def test_money_boundaries(self):
        for sen, want in [(1, '0.01'), (99, '0.99'), (100, '1.00'),
                          (9999999, '99999.99'), (10000000, '100000.00'),
                          (4294967296, '42949672.96'), (99999999999, '999999999.99')]:
            self.m.put('TOTALINCOME', sen)
            self.m.put('TOTALTAX', sen)
            self.m.put('SALESREVENUE', sen)
            report = self.m.call('SALESREPORT')
            self.assertEqual(report.count(want), 3)

    def test_orders_all_flavours_and_rounding(self):
        for flavour, qty, subtotal, tax, payable in [
            ('D', 1, 580, 46, '6.25'), ('A', 10, 4000, 320, '43.20'),
            ('O', 1, 450, 36, '4.85'), ('G', 1, 500, 40, '5.40'),
            ('M', 1, 450, 36, '4.85'), ('D', 9, 5220, 418, '56.40'),
            ('D', 10, 5800, 464, '62.65')]:
            output = self.order(flavour, qty)
            self.assertIn('TOTAL PRICE : RM' + payable, output)
            self.assertEqual(self.m.get('TOTALPRICE'), subtotal)
            self.assertEqual(self.m.get('TAXPRICE'), tax)
        self.assertEqual(self.m.get('TOTALINCOME'), 17000)
        self.assertEqual(self.m.get('TOTALTAX'), 1360)
        self.assertEqual(self.m.get('TOTALSALESQTY'), 33)
        for i, qty in enumerate([20, 10, 1, 1, 1]):
            self.assertEqual(self.m.get('SALESQTY', offset=i*6), qty)

    def test_tax_is_sum_of_order_tax(self):
        self.order('D', 1)
        self.order('D', 1)
        self.assertEqual(self.m.get('TOTALTAX'), 92)
        self.assertIn('0.92', self.m.call('SALESREPORT'))

    def test_all_fifty_legal_orders(self):
        prices = {'D': 580, 'A': 400, 'O': 450, 'G': 500, 'M': 450}
        income = taxes = 0
        for i, (flavour, price) in enumerate(prices.items()):
            for quantity in range(1, 11):
                subtotal = price * quantity
                tax = (subtotal * 8 + 50) // 100
                payable = ((subtotal + tax + 2) // 5) * 5
                output = self.order(flavour, quantity)
                self.assertIn(f'TOTAL PRICE : RM{payable // 100}.{payable % 100:02}', output)
                income += subtotal
                taxes += tax
                self.assertEqual(self.m.get('TOTALINCOME'), income)
                self.assertEqual(self.m.get('TOTALTAX'), taxes)
            self.assertEqual(self.m.get('SALESQTY', offset=i * 6), 55)
            self.assertEqual(self.m.get('SALESREVENUE', offset=i * 6), price * 55)
        self.assertEqual(self.m.get('TOTALSALESQTY'), 275)

    def test_rejected_order_can_be_followed_by_accepted_order(self):
        self.m.put('TOTALINCOME', 99999999599)
        before = self.state()
        self.assertIn('LIMIT', self.order('D'))
        self.assertEqual(self.state(), before)
        self.assertNotIn('LIMIT', self.order('A'))
        self.assertEqual(self.m.get('TOTALINCOME'), 99999999999)
        self.assertEqual(self.m.get('SALESQTY'), 0)
        self.assertEqual(self.m.get('SALESQTY', offset=6), 1)

    def test_quantity_and_tax_carry_into_next_word(self):
        for start in (65535,):
            self.m.put('SALESQTY', start)
            self.m.put('TOTALSALESQTY', start)
            self.m.put('TOTALTAX', start)
            self.order()
            self.assertEqual(self.m.get('SALESQTY'), 65536)
            self.assertEqual(self.m.get('TOTALSALESQTY'), 65536)
            self.assertEqual(self.m.get('TOTALTAX'), 65581)
        self.m.put('TOTALTAX', 99999999953)
        self.order()
        self.assertEqual(self.m.get('TOTALTAX'), 99999999999)

    def test_carries_and_exact_limits(self):
        for start in (65530, 4294967290, 99999999419):
            self.m.put('TOTALINCOME', start)
            self.order('D', 1)
            self.assertEqual(self.m.get('TOTALINCOME'), start + 580)
        self.m.put('TOTALINCOME', 0)
        self.m.put('SALESQTY', 999999998)
        self.m.put('TOTALSALESQTY', 999999998)
        self.order()
        self.assertEqual(self.m.get('SALESQTY'), 999999999)
        self.assertEqual(self.m.get('TOTALSALESQTY'), 999999999)

    def test_reject_each_limit_without_partial_update(self):
        for name, start in [('SALESQTY', 999999999), ('TOTALSALESQTY', 999999999),
                            ('SALESREVENUE', 99999999420), ('TOTALINCOME', 99999999420),
                            ('TOTALTAX', 99999999954), ('TOTALINCOME', (1 << 48) - 1)]:
            with self.subTest(name=name, start=start):
                self.m = Machine(self.exe, self.listing)
                self.m.put(name, start)
                before = self.state()
                output = self.order()
                self.assertIn('LIMIT', output)
                self.assertNotIn('Proceed payment', output)
                self.assertEqual(self.state(), before)

    def test_menu_error_only_after_invalid_flavour_and_quantity_validation(self):
        output = self.m.call('USER_INTERFACE_P', 'D01N')
        self.assertNotIn('INVALID CODE', output)
        self.m = Machine(self.exe, self.listing)
        output = self.m.call('USER_INTERFACE_P', 'xD001101N')
        self.assertEqual(output.count('INVALID CODE'), 1)
        self.assertEqual(output.count('INVALID QUANTITY'), 2)
        self.assertEqual(self.m.get('TOTALSALESQTY'), 1)


if __name__ == '__main__':
    unittest.main()
