const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("znv", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();


    const test_step = b.step("test", "Run library tests");

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    test_step.dependOn(&main_tests.step);
    const single_quote_tests = b.addTest("src/single-quote-tests.zig");
    single_quote_tests.setBuildMode(mode);
    test_step.dependOn(&single_quote_tests.step);

    const double_quote_tests = b.addTest("src/double-quote-tests.zig");
    double_quote_tests.setBuildMode(mode);
    test_step.dependOn(&single_quote_tests.step);

    const interpolation_tests = b.addTest("src/interpolation-tests.zig");
    interpolation_tests.setBuildMode(mode);
    test_step.dependOn(&interpolation_tests.step);

    const interpolation_tests2 = b.addTest("src/interpolation-tests-2.zig");
    interpolation_tests2.setBuildMode(mode);
    test_step.dependOn(&interpolation_tests2.step);

    const interpolation_tests3 = b.addTest("src/interpolation-tests-3.zig");
    interpolation_tests3.setBuildMode(mode);
    test_step.dependOn(&interpolation_tests3.step);


    const interpolation_tests4 = b.addTest("src/interpolation-tests-4.zig");
    interpolation_tests4.setBuildMode(mode);
    test_step.dependOn(&interpolation_tests4.step);

    const edge_cases = b.addTest("src/edge-cases-test.zig");
    edge_cases.setBuildMode(mode);
    test_step.dependOn(&edge_cases.step);


}
