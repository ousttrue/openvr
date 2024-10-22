const std = @import("std");
const zcc = @import("compile_commands");

pub fn build(b: *std.Build) void {
    var targets = std.ArrayList(*std.Build.Step.Compile).init(b.allocator);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dll = b.addSharedLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "simplehmd",
    });
    const install = b.addInstallArtifact(dll, .{
        .dest_sub_path = "simplehmd/bin/win64/driver_simplehmd.dll",
    });
    b.getInstallStep().dependOn(&install.step);

    const resource = b.addInstallDirectory(.{
        .source_dir = b.path("samples/drivers/drivers/simplehmd/simplehmd"),
        .install_dir = .bin,
        .install_subdir = "simplehmd",
    });
    install.step.dependOn(&resource.step);

    targets.append(dll) catch @panic("OOM");

    dll.linkLibCpp();
    dll.addCSourceFiles(.{
        .root = b.path("samples/drivers/drivers/simplehmd/src"),
        .files = &.{
            "device_provider.cpp",
            "hmd_driver_factory.cpp",
            "hmd_device_driver.cpp",
        },
        .flags = &.{
            "-std=c++14", // std::make_unique
            "-fPIC",
            "-fvisibility=hidden",
        },
    });
    dll.addIncludePath(b.path("headers"));
    dll.addIncludePath(b.path("samples/drivers/utils/driverlog"));
    dll.addCSourceFile(.{ .file = b.path("samples/drivers/utils/driverlog/driverlog.cpp") });
    dll.addIncludePath(b.path("samples/drivers/utils/vrmath"));
    dll.addIncludePath(b.path("samples/drivers/drivers/simplehmd/src"));

    zcc.createStep(b, "cdb", targets.toOwnedSlice() catch @panic("OOM"));
}
