const std = @import("std");
const EnvValueCounter = @import("env-value-counter.zig").EnvValueCounter;
pub const MAX_ENV_VALUE_LENGTH = 32768;
const EnvPair = @import("env-pair.zig").EnvPair;
//test3

pub const EnvValue = struct {
    const Self = @This();
    value: []u8 = undefined, //reuse stack buffer for speed
    isParsingVariable: bool = false,
    interpolations: []u8 = undefined,
    interpolationIndex: u8 = 0,
    quoted: bool = false,
    envValueCounter: EnvValueCounter = EnvValueCounter{},
    tripleQuoted: bool = false,
    doubleQuoted: bool = false,
    tripleDoubleQuoted: bool = false,
    valueIndex: u8 = 0,
    allocator: std.mem.Allocator = undefined,

    didOverFlow: bool = false,
    pub fn free_interpolation_array(self: *Self) void {
      std.debug.print("freeing interpolation array   \n",.{ });
        self.allocator.free(self.interpolations);
              std.debug.print("freed interpolation array   \n",.{ });
    }
    pub fn free_value(self: *Self) void {
        self.allocator.free(self.value);
    }
    pub fn init(self: *Self, allocator: std.mem.Allocator, tmp_buffer: []u8) !void {
        std.debug.print("creating intOp array   \n",.{ });
        var tmp = try allocator.alloc(u8, 10);
        self.interpolations = tmp;
        self.value = tmp_buffer;
        self.allocator = allocator;
    }
    pub fn resizeInterpolationArray(self: *Self) !void {
        std.debug.print("resizing ", .{});
        var tmp = try self.allocator.alloc(u8, self.interpolations.len + 1000);
        std.mem.copy(u8, tmp, self.interpolations);
        self.allocator.free(self.interpolations);
        self.interpolations = tmp;
    }
    pub fn finalize_value(self: *Self) !void {
        if (self.valueIndex <= 0) {
            return error.ValueWouldBeEmpty;
        }
        std.debug.print("Finalizing Value of length {} \n", .{self.valueIndex});
        var tmp = try self.allocator.alloc(u8, self.valueIndex);
        const bufferSlice = self.value[0..self.valueIndex];
        std.mem.copy(u8, tmp, bufferSlice);
        self.value = tmp;
    }
    fn get_size_for_interpolation(self: *Self, pairs: []EnvPair) i8 {
        var tmp = self.interpolationIndex;
        if (tmp % 2 != 0) {
            //someone didn't close their last {}
            std.debug.print("Unclosed interpolation {}",.{tmp});
            tmp = tmp - 1;
        }
        std.debug.print("We have  {} variables in this string\n",.{tmp/2});
        var resizeNeeded: i8 = 0;
        while (tmp > 0) : (tmp = tmp - 2) {
            const start = self.interpolations[tmp - 2];
            const end = self.interpolations[tmp - 1];
            const length : i8= @intCast(i8,end - start);
            std.debug.print("Pol {} start : {} end: {} length {}   \n",.{tmp,start,end,length });
            const targetKey = self.value[start..end];
            std.debug.print("looking for {s}\n",.{targetKey});
            for (pairs) |pair| {
                std.debug.print("looking at {s}    \n",.{pair.key.key });
                if (std.mem.eql(u8, pair.key.key, targetKey)) {
                    //this is the one
                    const pairValueLen = @intCast(i8, pair.value.value.len);
                    std.debug.print("found {s}  at {} with length {} to replace old length {} \n",.{targetKey,pair.value.value.len,pairValueLen ,length});

                    if (pair.value.value.len > length) {
                        resizeNeeded += @intCast(i8,pairValueLen - length);
                    } else if (pair.value.value.len < length) {
                        resizeNeeded -=  @intCast(i8,pairValueLen - length);
                    }
                    std.debug.print("Current Diff in string size {}    \n",.{resizeNeeded });
                }
            }
        }

        return resizeNeeded; //return it because for smaller you resize after
    }
    pub fn interpolate_value(self: *Self, pairs: []EnvPair) !void {
        if (self.interpolationIndex < 2) {
            //it had none or one with a hanging chad
            return;
        }

        if (self.interpolationIndex % 2 != 0) {
            //fix hanging chad but it has other good ones
            self.interpolationIndex -= 1;
        }
        //get the difference in interpolation size and current size
        const resizeNeeded = self.get_size_for_interpolation(pairs);
        std.debug.print("Need to resize buffer {} for value size change    \n",.{resizeNeeded});
        if (resizeNeeded == 0) {
            //weird edge case for later, otherwise we'll optimize for the normal cases where the size is either smaller or larger
        }
        //create a tmp amount for the exact size
        var tmp = try self.allocator.alloc(u8,  @intCast(usize,@intCast(i8,self.valueIndex) + resizeNeeded));

        try self.copy_interpolation_values(tmp, pairs);
    }
    fn copy_interpolation_values(self: *Self, new_buffer: []u8, pairs: []EnvPair) !void {
        var tmp = self.interpolationIndex;
        var copy_index: u8 = 0;
        var buffer_index: u8 = 0;

        while (tmp > 0) : (tmp = tmp - 2) {
            const start = self.interpolations[tmp - 2];
            const end = self.interpolations[tmp - 1];
            //catch up the new buffer to where we are about to interpol
            // const length = end - start;
            if (start > buffer_index) {
                const amount = start - buffer_index;
                //copy the constant text between variables in
                const copy_end = copy_index + amount;
                const buffer_end = buffer_index + amount;
                var newBufferSlice = new_buffer[copy_index..copy_end];
                const oldBufferSlice = self.value[buffer_index..buffer_end];
                std.mem.copy(u8, newBufferSlice, oldBufferSlice);
                buffer_index = end; // now from the source array we are caught up to where the variable ended
                copy_index = copy_end;
            }
            //copy the variable value in
            const valueSlice = self.value[start..end];
            const envpair = find_pair(pairs, valueSlice) catch |x| switch (x) {
                error.PairNotFound => continue, //todo: catch up buffer_start (we'll fix this in a test csae)
                else => |e| return e,
            };

            const copy_end: u8 = copy_index + @intCast(u8, envpair.value.value.len);
            std.mem.copy(u8, new_buffer[copy_index..copy_end], envpair.value.value);
            copy_index = copy_end;
            //zig, because for loops are while

        }
    }

    fn placeValueCharacter(self: *Self, value: u8) !void {
        if (self.valueIndex >= MAX_ENV_VALUE_LENGTH) {
            //emit warning we are over allowed buffer length
            std.debug.print("Value {c} can not be stored. ENV has a max size. \n", .{value});
            self.didOverFlow = true;
            return;
            //todo: handle overflow -- probably will just ignore. ENV can't hold more than 32k on linux.
            //return;
        }
        std.debug.print("Adding character {c} \n", .{value});
        self.value[self.valueIndex] = value;
        self.valueIndex = self.valueIndex + 1;
        std.debug.print(" {s} \n", .{self.value[0..20]});
    }
    pub fn processValueNextValue(self: *Self, value: u8) !bool {

        if (self.didOverFlow) {
            //we've told the user they overflowed. Just return; Nothing else can be processed.
            return true;
        }
        if (self.quoted) { // process value if we have detected this is a single quoted value
            return self.processValueInsideQuoted(value);
        }
        if (value == '\'') { //single quote
            if (self.isAtStart()) { //at the start
                self.quoted = true;
                return false;
            }
        }
        // if (self.processDoubleQuote()) {
        //     return true;
        // }
        if (value == '\n') {
              std.debug.print("Newline hit on double/no quote\n", .{});
            // if (!self.tripleDoubleQuoted) {
            //     return true;
            // }
            // if (!self.tripleQuoted) {
            //     return true;
            // }

            return true;
        }
        if (value == '\r') {
            return false;
        }


        if (!self.isParsingVariable) {
            if (value == '{') { //ok we have either no double quote or are double quoted, process if we find ${}
                if (self.previousIsDollarSign()) {
                    try self.incrementInterpolDepth();
                }
            }
        }else {
            std.debug.print("scanning variable name: {c}\n", .{value});
            if (value == '}') {
                self.decrementInterpolDepth();
            }
        }

        try self.placeValueCharacter(value);
        return false;
    }

    pub fn incrementInterpolDepth(self: *Self) !void {
        if (self.interpolationIndex >= self.interpolations.len) {
            std.debug.print("resizing variable array \n", .{});
            try self.resizeInterpolationArray();
        }
        self.isParsingVariable = true;
        self.interpolations[self.interpolationIndex] = self.valueIndex + 1;
        std.debug.print("interpolation starts at {} :{}\n", .{ self.valueIndex + 1, self.interpolationIndex });
        self.interpolationIndex = self.interpolationIndex + 1;
    }
    pub fn decrementInterpolDepth(self: *Self) void {
        self.isParsingVariable = false;
        std.debug.print("interpolation ends at {} :{}\n", .{ self.valueIndex, self.interpolationIndex });
        self.interpolations[self.interpolationIndex] = self.valueIndex;

        self.interpolationIndex = self.interpolationIndex + 1;
    }
    fn processDoubleQuote(self: *Self) bool {
        const streak = self.previousDoubleQuoteCount();

        if (streak == 0) {
            if (self.isAtStart()) {
                self.doubleQuoted = true;
                return false;
            }
            if (!self.tripleDoubleQuoted) {
                return false;
            }
        }
        if (streak != 3) {
            return false;
        }
        if (self.tripleDoubleQuoted) {
            if (self.fourCharactersAgoNewline()) {
                return true;
            }
            return false;
        }
        if (self.fourCharactersAgoStart()) {
            self.tripleDoubleQuoted = true;
        }
        return false;
    }
    pub fn processValueInsideQuoted(self: *Self, value: u8) !bool {
        std.debug.print("Inside Single Quote {c} \n", .{value});
        if (value == '\'') {
            const streak = self.previousSingleQuoteCount();
            std.debug.print("Is a single quote with streak {} \n", .{streak});
            if (streak == 3) {
                if (self.fourCharactersAgoStart()) {
                    self.tripleQuoted = true;
                    return false;
                }
                if (self.fourCharactersAgoNewline()) {
                    return true;
                }
            }
            return true;
        }
        if (value == '\r') {
            return false;
        }
        if (value == '\n') {
            return true;
        }
        try self.placeValueCharacter(value);
        return false;
    }
    pub fn previousIsSingleQuote(self: *Self) !bool {
        if (self.valueIndex == 0) {
            return false;
        }
        return self.value[self.valueIndex - 1] == '\'';
    }
    pub fn fourCharactersAgoNewline(self: *Self) bool {
        if (self.valueIndex < 4) {
            return false;
        }
        return self.value[self.valueIndex - 4] == '\n';
    }
    pub fn previousSingleQuoteCount(self: *Self) u8 {
        var tmp = self.valueIndex;
        var count: u8 = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '\'') {
                count = count + 1;
            }
            if (count >= 3) {
                //avoid """"""""""""""""""""""""
                break;
            }
            tmp = tmp - 1;
        }
        return count;
    }
    pub fn previousDoubleQuoteCount(self: *Self) u8 {
        var tmp = self.valueIndex;
        var count: u8 = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '"') {
                count = count + 1;
            }
            if (count >= 3) {
                //avoid """"""""""""""""""""""""
                break;
            }
            tmp = tmp - 1;
        }
        return count;
    }
    pub fn isAtStart(self: *Self) bool {
        return self.valueIndex == 0;
    }
    pub fn fourCharactersAgoStart(self: *Self) bool {
        return self.valueIndex == 3;
    }
    pub fn previousIsDollarSign(self: *Self) bool {
        if (self.valueIndex == 0) {
            return false;
        }
        return self.value[self.valueIndex - 1] == '$';
    }
};

fn find_pair(pairs: []EnvPair, inter_value: []u8) !EnvPair {
    for (pairs) |pair| {
        if (std.mem.eql(u8, pair.value.value, inter_value)) {
            return pair;
        }
    }
    return error.PairNotFound;
}
