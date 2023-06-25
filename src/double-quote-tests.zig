const std = @import("std");
const EnvValue = @import("env-value.zig").EnvValue;
const EnvKey = @import("env-key.zig").EnvKey;
const nextKey = @import("env-reader.zig").nextKey;
const nextValue = @import("env-reader.zig").nextValue;
const EnvGroup = @import("env-group.zig").EnvGroup;
const freePairs = @import("env-reader.zig").freePairs;
const preInitPairs = @import("env-reader.zig").preInitPairs;
const nextPair = @import("env-reader.zig").nextPair;
const testing = std.testing;

test "simple double quoted key value" {
    const file =
        try std.fs.cwd().openFile("test-files/sample-double-quote.env", .{});
    defer file.close();

      var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
      defer arena.deinit();
      var allocator = arena.allocator();
      var group: EnvGroup = EnvGroup{};
      group.init(&allocator);
      var buffer = try allocator.alloc(u8, 100);
      defer allocator.free(buffer);

      try preInitPairs(&group, 1, buffer);
      defer freePairs(&group);

      try nextPair(file.reader(), &group.pairs[0]);
      std.debug.print("Output:  {s}={s} \n", .{ group.pairs[0].key.key, group.pairs[0].value.value });
      try std.testing.expect(std.mem.eql(u8, group.pairs[0].value.value[0..4], "beta"));
}
