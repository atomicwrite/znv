const EnvValue = @import("env-value.zig").EnvValue;
const EnvPair = @import("env-pair.zig").EnvPair;
const VariablePosition = @import("variable-position.zig").VariablePosition;
const std = @import("std");

pub fn free_interpolation_array(self: *EnvValue) void {
    std.debug.print("freeing interpolation array   \n", .{});
    self.allocator.free(self.interpolations);
    std.debug.print("freed interpolation array   \n", .{});
}
pub fn resizeInterpolationArray(self: *EnvValue) !void {
    std.debug.print("resizing ", .{});
    var tmp = try self.allocator.alloc(VariablePosition, self.interpolations.len + 1000);
    std.mem.copy(VariablePosition, tmp, self.interpolations);
    self.allocator.free(self.interpolations);
    self.interpolations = tmp;
}
fn check_if_pair_needs_interpolation( pairs: []EnvPair, pair: *const EnvPair) !void {
    if (!pair.value.hadInterpolation()) {
        return;
    }
    std.debug.print("Env pair had interpolation {s} \n", .{pair.key.key});
    if (pair.value.isAlreadyInterpolated) {
        return;
    }
    std.debug.print("Env pair is not yet processed {s} \n", .{pair.value.value});
    if (pair.value.isBeingInterpolated) {
        std.debug.print("Env pair is circular {s} \n", .{pair.key.key});
        return;
    }
    std.debug.print("Env pair is not circular {s} \n", .{pair.value.value});
    try interpolate_value(pair.value, pairs);
    std.debug.print("Env pair was interpolated {s} \n", .{pair.value.value});

    //todo: error mode allows to raise error or silently ignore that we had circular

}
fn get_size_for_interpolation(self: *EnvValue, pairs: []EnvPair) i32 {
    var tmp: u32 = self.interpolationIndex;

    std.debug.print("We have {} variables\n", .{tmp});
    var resizeNeeded: i32 = 0;
    while (tmp > 0) : (tmp = tmp - 1) {
        std.debug.print("Looking at variable {} \n", .{tmp - 1});
        const item = &self.interpolations[tmp - 1];
        const start = item.variableStart;
        const end = item.variableEnd;
        std.debug.print("interpolation starts at {} ends at {} with variable starts at {} and ends at {}  and we have {} variables now\n", .{ item.dollarSign, item.endBrace, item.variableStart, item.variableEnd, self.interpolationIndex });

        const length: i8 = @intCast(i8, item.endBrace) - @intCast(i8, item.dollarSign);
        const variableLength = end - start;
        std.debug.print("Pol {} start : {} end: {} length {} , variable name length {}  \n", .{ tmp, start, end, length, variableLength });
        const targetKey = self.value[start..end];
        std.debug.print("looking for {s}\n", .{targetKey});
        for (pairs) |pair| {
            std.debug.print("looking at {s}    \n", .{pair.key.key});
            if (!std.mem.eql(u8, pair.key.key, targetKey)) {
                continue;
            }
            check_if_pair_needs_interpolation(pairs, &pair) catch |x| {
                std.debug.print("err {}", .{x});
                continue;
            };
            //this is the one
            const pairValueLen = @intCast(i32, pair.value.value.len);
            std.debug.print("found {s}  at {} with length {} to replace old length {} \n", .{ targetKey, pair.value.value.len, pairValueLen, length });

            if (length > pairValueLen) {
                resizeNeeded += pairValueLen - length;
                std.debug.print("Value is less than variable name : {} \n", .{pairValueLen - length});
            } else if (length < pairValueLen) {
                std.debug.print("Value is greater than variable name : {} \n", .{pairValueLen + length});
                resizeNeeded -= pairValueLen + length;
            }
            std.debug.print("Current Diff in string size {}    \n", .{resizeNeeded});
        }
    }

    return resizeNeeded; //return it because for smaller you resize after
}
pub fn interpolate_value(self: *EnvValue, pairs: []EnvPair) !void {
    if (!self.hadInterpolation()) {
        return;
    }
    if (self.isAlreadyInterpolated) {
        return;
    }
    std.debug.print("----------------------  \n", .{});
    self.isBeingInterpolated = true;
    //get the difference in interpolation size and current size
    const resizeNeeded = get_size_for_interpolation(self, pairs);
    std.debug.print("Need to resize buffer {} for value size change    \n", .{resizeNeeded});
    //create a tmp amount for the exact size
    const new_size = @intCast(i8, self.valueIndex) + resizeNeeded;
    std.debug.print("Creating {} sized buffer  \n", .{new_size});
    var tmp = try self.allocator.alloc(u8, @intCast(usize, new_size));

    try copy_interpolation_values(self, tmp, pairs);
    self.value = tmp;
    self.isAlreadyInterpolated = true;
    self.isBeingInterpolated = false;
}
fn copy_interpolation_values(self: *EnvValue, new_buffer: []u8, pairs: []EnvPair) !void {
    var tmp: u8 = 0;
    var copy_index: u32 = 0;
    var buffer_index: u32 = 0;

    while (tmp < self.interpolationIndex) : (tmp = tmp + 1) {
        const item = &self.interpolations[tmp];
        std.debug.print("dollarSign: {} , endBrace: {}, buffer: {} \n", .{ item.dollarSign, item.endBrace, buffer_index });
        if (item.dollarSign > buffer_index) {
            const amount = item.dollarSign - buffer_index;
            copyJustText(self, new_buffer, copy_index, buffer_index, amount);
            buffer_index = buffer_index + amount; // now from the source array we are caught up to where the variable ended
            copy_index = copy_index + amount;
        }
        const valueSlice = self.value[item.variableStart..item.variableEnd];
        const envpair = find_pair(pairs, valueSlice) catch |x| switch (x) {
            error.PairNotFound => {
                std.debug.print("Could not find {s}", .{valueSlice});
                continue;
            }, //todo: catch up buffer_start (we'll fix this in a test csae)
            else => |e| return e,
        };

        std.debug.print("Copying in value {s}\n", .{envpair.value.value});
        const value_len = @intCast(u32, envpair.value.value.len);
        const copy_end: u32 = copy_index + value_len;
        std.debug.print("Copying after variable {}->{}\n", .{ copy_end, copy_index });
        std.mem.copy(u8, new_buffer[copy_index..copy_end], envpair.value.value);
        copy_index = copy_end;
        buffer_index = item.endBrace;
        std.debug.print("Copy End: {}, Copy Index: {}, Buffer Index: {} \n", .{ copy_end, copy_index, buffer_index });
        //zig, because for loops are while
        var amount: u32 = 0;
        //do we have another variable or is this the last?
        if (tmp < self.interpolationIndex - 1) {
            amount = self.interpolations[tmp + 1].dollarSign - buffer_index;
            std.debug.print("Copying {} to next variable \n", .{amount});
        } else {
            amount = @intCast(u32, self.value.len) - buffer_index;
            std.debug.print("Copying {} to end \n", .{amount});
        }
        if (amount > 0) {
            copyJustText(self, new_buffer, copy_index, buffer_index, amount);
            buffer_index = buffer_index + amount; // now from the source array we are caught up to where the variable ended
            copy_index = copy_index + amount;
        }
    }

    std.debug.print("new value: {s}\n", .{new_buffer});
}
pub fn copyJustText(self: *EnvValue, new_buffer: []u8, copy_index: u32, buffer_index: u32, amount: u32) void {
    const copy_end = copy_index + amount;
    const buffer_end = buffer_index + amount;
    var newBufferSlice = new_buffer[copy_index..copy_end];
    const oldBufferSlice = self.value[buffer_index..buffer_end];
    std.mem.copy(u8, newBufferSlice, oldBufferSlice);
}
pub fn incrementInterpolDepth(self: *EnvValue, count: u8) !void {
    if (self.interpolationIndex >= self.interpolations.len) {
        std.debug.print("resizing variable array \n", .{});
        try resizeInterpolationArray(self);
    }
    self.isParsingVariable = true;
    self.interpolations[self.interpolationIndex] = VariablePosition{
        .variableStart = self.valueIndex + 1,
        .startBrace = self.valueIndex,

        .dollarSign = self.valueIndex - count,
    };
    std.debug.print("interpolation starts at {}, dollar sign at {} :{}\n", .{ self.valueIndex + 1, self.valueIndex - count, self.interpolationIndex });
}
pub fn decrementInterpolDepth(self: *EnvValue) void {
    self.isParsingVariable = false;

    const interpolation = &self.interpolations[self.interpolationIndex];
    interpolation.endBrace = self.valueIndex + 1;
    interpolation.variableEnd = self.valueIndex;
    const leftVariableWhitespace = getWhiteSpaceOffsetLeft(self.value[interpolation.variableStart..interpolation.variableEnd]);
    if (leftVariableWhitespace > 0) {
        std.debug.print("Trimming left white space {}  \n", .{leftVariableWhitespace});
        interpolation.variableStart = interpolation.variableStart + leftVariableWhitespace;
    }
    const rightVariableWhitespace = getWhiteSpaceOffsetRight(self.value[interpolation.variableStart..interpolation.variableEnd]);
    if (rightVariableWhitespace > 0) {
        std.debug.print("Trimming right white space {}  \n", .{rightVariableWhitespace});
        interpolation.variableEnd = interpolation.variableStart - rightVariableWhitespace;
    }

    self.interpolationIndex = self.interpolationIndex + 1;
    std.debug.print("interpolation starts at {} ends at {} with variable starts at {} and ends at {} \"{s}\" and we have {} variables now\n", .{ interpolation.dollarSign, interpolation.endBrace, interpolation.variableStart, interpolation.variableEnd, self.value[interpolation.variableStart..interpolation.variableEnd], self.interpolationIndex });
}

pub fn getWhiteSpaceOffsetLeft(str: []u8) u8 {
    var tmp: u8 = 0;
    while (tmp <= str.len) : (tmp = tmp + 1) {
        if (str[tmp] != ' ') {
            break;
        }
    }
    return tmp;
}
pub fn getWhiteSpaceOffsetRight(str: []u8) u8 {
    var tmp = str.len;
    var count: u8 = 0;
    while (tmp <= 0) : (tmp = tmp - 1) {
        if (str[tmp] != ' ') {
            break;
        }
        count = count + 1;
    }
    return count;
}
pub fn find_pair(pairs: []EnvPair, inter_value: []u8) !EnvPair {
    for (pairs) |pair| {
        std.debug.print("Comparing {s} to {s}\n", .{ pair.key.key, inter_value });
        if (std.mem.eql(u8, pair.key.key, inter_value)) {
            return pair;
        }
    }
    return error.PairNotFound;
}
