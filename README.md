# znv

### Pre-Alpha

A .env (dotenv) parser for zig.

```zig

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var group: EnvGroup = EnvGroup{};
    group.init(&allocator);
    var buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    try preInitPairs(&group, 3,buffer);
    defer freePairs(&group);

    const file =
        try std.fs.cwd().openFile("test-files/sample-interpolated-2.env", .{});
    const reader = file.reader();
    defer file.close();
    var tmp : u8 = 0;
    while(tmp < 3) : (tmp = tmp + 1){
        try nextPair(reader,&group.pairs[tmp]);
    }
    var firstOne = group.values[2];
    try interpolate_value(&firstOne, group.pairs);
```

Try:
`zig test .\src\interpolation-tests-2.zig`

Check out:

* [interpolation-tests-2.zig](src%2Finterpolation-tests-2.zig)

* [interpolation-helper.zig](src%2Finterpolation-helper.zig)

* [env-value.zig](src%2Fenv-value.zig)