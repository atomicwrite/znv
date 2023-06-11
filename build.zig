const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("znv", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    const single_quote_tests = b.addTest("src/single-quote-tests.zig");
    single_quote_tests.setBuildMode(mode);
    const double_quote_tests = b.addTest("src/double-quote-tests.zig");
    double_quote_tests.setBuildMode(mode);
    const test_step = b.step("test", "Run library tests");

    test_step.dependOn(&main_tests.step);
    test_step.dependOn(&single_quote_tests.step);
      test_step.dependOn(&single_quote_tests.step);
}
