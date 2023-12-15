const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqualSlices = std.testing.expectEqualSlices;

const Mode = enum(u2) {
    no_disp = 0b00,
    byte = 0b01,
    word = 0b10,
    reg = 0b11,
};

const Dir = enum(u1) {
    source = 0,
    dest = 1,
};

const RegMem = union(enum) {
    // mod = 0b11
    Reg: Reg,

    // mod = 0b00
    RegPlusReg: struct {
        rega: Reg,
        regb: Reg,
    },
    RegAddress: struct {
        // should only be SI or DI
        reg: Reg,
    },

    DirectAddress: struct {
        addr: u16,
    },

    // mod = 0b01
    RegPlus8: struct {
        reg: Reg,
        val: u8,
    },
    RegPlusRegPlus8: struct {
        rega: Reg,
        regb: Reg,
        val: u8,
    },

    // mod = 0b10
    RegPlus16: struct {
        reg: Reg,
        val: u16,
    },
    RegPlusRegPlus16: struct {
        rega: Reg,
        regb: Reg,
        val: u16,
    },

    pub fn to_string(self: RegMem, alloc: Allocator) ![]u8 {
        return switch (self) {
            .Reg => |reg| std.fmt.allocPrint(alloc, "{s}", .{reg.to_string()}),
            else => @panic("unsupported regmem type"),
        };
    }
};

const Reg = enum(u4) {
    // 8bit
    al,
    cl,
    dl,
    bl,
    ah,
    ch,
    dh,
    bh,

    // 16bit
    ax,
    cx,
    dx,
    bx,
    sp,
    bp,
    si,
    di,

    pub fn to_string(self: Reg) *const [2]u8 {
        return switch (self) {
            .al => "al",
            .cl => "cl",
            .dl => "dl",
            .bl => "bl",
            .ah => "ah",
            .ch => "ch",
            .dh => "dh",
            .bh => "bh",
            .ax => "ax",
            .cx => "cx",
            .dx => "dx",
            .bx => "bx",
            .sp => "sp",
            .bp => "bp",
            .si => "si",
            .di => "di",
        };
    }
};

pub const Instr = struct {
    // byte 1
    // TODO: make an enum for opcodes
    opcode: u6,
    // direction:
    // if 0, source is REG
    // if 1, dest is REG
    dir: Dir,
    // does this instruction operate on words?
    word: bool,

    // byte 2
    mode: Mode,
    reg: Reg,
    regmem: RegMem,

    pub fn new(bytes: []const u8) Instr {
        const word: bool = (bytes[0] & 0x01) != 0;
        const dir: Dir = @enumFromInt(bytes[0] >> 1);
        const opcode: u6 = @truncate(bytes[0] >> 2);

        const mode: Mode = @enumFromInt(bytes[1] >> 6 & 0x07);
        const reg_val: u3 = @truncate(bytes[1] >> 3);
        const reg: Reg = if (word)
            @enumFromInt(@as(u8, reg_val) + 8)
        else
            @enumFromInt(reg_val);

        const reg_mem_val: u3 = @truncate(bytes[1]);
        const reg_mem_reg: Reg = if (word)
            @enumFromInt(@as(u8, reg_mem_val) + 8)
        else
            @enumFromInt(reg_mem_val);

        const regmem = RegMem{
            .Reg = reg_mem_reg,
        };

        return Instr{
            .word = word,
            .dir = dir,
            .opcode = opcode,
            .mode = mode,
            .reg = reg,
            .regmem = regmem,
        };
    }

    pub fn to_string(self: Instr, alloc: Allocator) ![]u8 {
        const src = self.reg.to_string();
        const dest = try self.regmem.to_string(alloc);
        defer alloc.free(dest);
        return std.fmt.allocPrint(alloc, "mov {s}, {s}\n", .{ dest, src });
    }
};

test "inst word" {
    const input = [_]u8{ 0x89, 0xd9 };
    const inst = Instr.new(&input);

    try expect(inst.opcode == 0b100010);
    // source in reg
    try expect(@intFromEnum(inst.dir) == 0);
    try expect(inst.dir == Dir.source);
    // 16 bits
    try expect(inst.word == true);

    // reg to reg
    try expect(@intFromEnum(inst.mode) == 0b11);
    try expect(inst.mode == Mode.reg);

    // bx is source
    try expect(inst.reg == Reg.bx);

    // cx is dest
    try expect(inst.regmem.Reg == Reg.cx);
}

test "inst high" {
    const input = [_]u8{ 0x88, 0xe5 };
    const inst = Instr.new(&input);

    try expect(inst.opcode == 0b100010);
    // source in reg
    try expect(inst.dir == Dir.source);
    // 16 bits
    try expect(inst.word == false);

    // reg to reg
    try expect(inst.mode == Mode.reg);

    // ah is source
    try expect(inst.reg == Reg.ah);

    // ch is dest
    try expect(inst.regmem.Reg == Reg.ch);

    const expected = "mov ch, ah";
    const actual = try inst.to_string(std.testing.allocator);
    defer std.testing.allocator.free(actual);
    try expectEqualSlices(u8, expected, actual);
}
