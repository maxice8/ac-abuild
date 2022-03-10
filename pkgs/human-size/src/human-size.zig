const std = @import("std");

const ExitCode = enum(u8) {
    Success = 0,
    Syscall = 111,

    const Parse = enum(u8) {
        Overflow = 10, // value is over i64
        Syntax = 11, // value is not numeric
    };
    const Stdin = enum(u8) {
        MaxLen = 20, // more than 20 chars in stdin
        NotOpen = 21, // not open for reading
        Misc = 22, // any other error
    };
};

// Just enough to hold the longest string representation of
// an i64 value (-9223372036854775807)
const max_characters = 20;

fn read_stdin(allocator: std.mem.Allocator) ![]const u8 {
    // Read from stdin
    const stdin = std.io.getStdIn().reader();

    // Read stdin until '\n'
    const subinput = try stdin.readUntilDelimiterOrEofAlloc(allocator, '\n', max_characters);

    // I don't even know how this is possible to happen, even just pressing
    // enter (\n), will just return an empty string and not an optional value
    // having stdin closed will just trigger `error.NotOpenForReading` in the
    // command above
    return subinput orelse return "";
}

// get_input returns either an owned string ([]u8) or an error, it tries to
// read from the args of the system, if none are present (except for $0 which
// is the scriptname) it blocks and reads from stdin until `\n`.
fn get_input(allocator: std.mem.Allocator) ![]const u8 {
    // must be `var` as we process the args
    var args = std.process.args();

    // skip $0, no need to bother error checking since $0 is
    // always filled
    _ = args.skip();

    const input = try (args.next(allocator) orelse "-");

    // This is just a long way of saying `string1 == string2`
    if (std.mem.eql(u8, input, "-")) {
        return read_stdin(allocator);
    }

    return input;
}

fn count(allocator: std.mem.Allocator, input: f64) ![]u8 {
    // The units we use
    const SI: []const u8 = &[6]u8{ 'k', 'M', 'G', 'T', 'P', 'E' };

    // we divide by this to progress through every unit
    const unit = 1000;

    // if we are smaller than the unit then just return without any units
    // just the B.
    //
    // the @fabs returns the absolute value of the input, otherwise this will
    // fail with negative values
    if (@fabs(input) < unit) {
        return try std.fmt.allocPrint(allocator, "{d} B", .{input});
    }

    // gets added every time we cross a unit bound
    var exp: usize = 0;

    // take the input and divide by unit as we crossed
    // the first unit boundary
    var total: f64 = input / unit;

    while (@fabs(total) >= unit) {
        total /= unit;
        exp += 1;
    }

    return try std.fmt.allocPrint(allocator, "{d:.1} {c}B", .{ total, SI[exp] });
}

// we only return an u8 which is used as error
pub fn main() !u8 {
    // allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Get input, either from $1 or from stdin (if interactive we will block
    // for the user)
    const input = get_input(allocator) catch |err| switch (err) {
        error.OutOfMemory => return 111,
        error.StreamTooLong => {
            const stderr = std.io.getStdErr().writer();
            try stderr.writeAll("human-size: read: only up to 20 characters are accepted\n");
            return @enumToInt(ExitCode.Stdin.MaxLen);
        },
        error.NotOpenForReading => {
            const stderr = std.io.getStdErr().writer();
            try stderr.writeAll("human-size: read: stdin not open for reading\n");
            return @enumToInt(ExitCode.Stdin.NotOpen);
        },
        else => {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("human-size: read: {s}\n", .{err});
            return @enumToInt(ExitCode.Stdin.Misc);
        },
    };

    // parse the received input into an i64 value.
    const size = std.fmt.parseInt(i64, input, 10) catch |err| switch (err) {
        error.Overflow => {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("human-size: parse {s}: overflow\n", .{input});
            return @enumToInt(ExitCode.Parse.Overflow);
        },
        error.InvalidCharacter => {
            const stderr = std.io.getStdErr().writer();
            try stderr.print("human-size: parse {s}: invalid syntax\n", .{input});
            return @enumToInt(ExitCode.Parse.Syntax);
        },
    };

    // While there is only one error we want to deal with them explicitly so we
    // always know if errors are added or removed.
    const final = count(allocator, @intToFloat(f64, size)) catch |err| switch (err) {
        error.OutOfMemory => return @enumToInt(ExitCode.Syscall),
    };

    const stdio = std.io.getStdOut().writer();
    try stdio.print("{s}\n", .{final});

    return @enumToInt(ExitCode.Success);
}
