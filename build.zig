const std = @import("std");
const ProcessAssetsStep = @import("ProcessAssetsStep.zig");
const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const wasm = b.addSharedLibrary(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = .{ .cpu_arch = .wasm32, .os_tag = .freestanding },
        .optimize = optimize,
    });
    wasm.rdynamic = true;
    b.installArtifact(wasm);

    const process_assets = ProcessAssetsStep.create(b);
    process_assets.addStage("maps/stages/needleman/needleman.world");

    // format generated files
    const fmt = b.addFmt(.{ .paths = &.{"src/stages/needleman.zig"} });
    fmt.step.dependOn(&process_assets.step);
    wasm.step.dependOn(&fmt.step);
}
