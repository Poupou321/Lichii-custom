// SPDX-License-Identifier: GPL-3.0-or-later

#include <array>
#include <chrono>
#include <cstddef>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include <catch2/catch_test_macros.hpp>

#include "video_core/renderer_vulkan/vk_pipeline_cache.h"
#include "video_core/shader_environment.h"
#include "video_core/shader_warm/shader_archives.h"
#include "video_core/shader_warm/warm_records.h"

namespace {
namespace Warm = VideoCommon::ShaderWarm;

static_assert(sizeof(Vulkan::GraphicsPipelineCacheKey) == Warm::GraphicsKeySize);
static_assert(sizeof(Vulkan::ComputePipelineCacheKey) == sizeof(Warm::ComputeKey));
static_assert(offsetof(Vulkan::GraphicsPipelineCacheKey, state) +
                  offsetof(Vulkan::FixedPipelineState, attribute_types) ==
              Warm::AttributeTypesOffset);

template <typename T>
void Put(std::vector<u8>& bytes, size_t offset, T value) {
    std::memcpy(bytes.data() + offset, &value, sizeof(value));
}

struct TemporaryRecord {
    std::filesystem::path path = std::filesystem::temp_directory_path() /
        ("lichii-warm-test-" + std::to_string(
             std::chrono::steady_clock::now().time_since_epoch().count()));

    ~TemporaryRecord() {
        std::error_code error;
        std::filesystem::remove(path, error);
    }

    void Write(std::span<const u8> bytes) const {
        std::ofstream out(path, std::ios::binary);
        out.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
        REQUIRE(out.good());
    }
};

// A single named SARC member containing deliberately unsupported data.
std::vector<u8> MakeSarc() {
    std::vector<u8> data(68);
    std::memcpy(data.data(), "SARC", 4);
    Put<u16>(data, 4, 20);
    Put<u16>(data, 6, 0xfeff);
    Put<u32>(data, 8, static_cast<u32>(data.size()));
    Put<u32>(data, 12, 64);
    std::memcpy(data.data() + 20, "SFAT", 4);
    Put<u16>(data, 24, 12);
    Put<u16>(data, 26, 1);
    Put<u32>(data, 36, 0x01000000);
    Put<u32>(data, 44, 4);
    std::memcpy(data.data() + 48, "SFNT", 4);
    Put<u16>(data, 52, 8);
    std::memcpy(data.data() + 56, "bad.bin", 7);
    return data;
}
} // namespace

TEST_CASE("Shader warm archives reject invalid extents and isolate member errors", "[video_core][shader_warm]") {
    size_t records{};
    std::vector<std::string> errors;
    const auto on_record = [&](const Warm::ShaderRecord&) { ++records; };
    const auto on_error = [&](const std::string& error) { errors.push_back(error); };
    auto archive = MakeSarc();
    REQUIRE_NOTHROW(Warm::WalkArchive(archive, "synthetic.sarc", nullptr, on_record, on_error));
    REQUIRE(records == 0);
    REQUIRE(errors.size() == 1);
    REQUIRE(errors.front().find("bad.bin") != std::string::npos);

    Put<u32>(archive, 44, 5); // Member extends past the archive.
    REQUIRE_THROWS_AS(Warm::WalkArchive(archive, "synthetic.sarc", nullptr, on_record, on_error),
                      Warm::ArchiveError);
    archive.resize(4);
    REQUIRE_THROWS_AS(Warm::WalkArchive(archive, "truncated.sarc", nullptr, on_record, on_error),
                      Warm::ArchiveError);

    const std::array<u8, 4> truncated_zstd{0x28, 0xb5, 0x2f, 0xfd};
    REQUIRE_THROWS_AS(Warm::WalkArchive(truncated_zstd, "synthetic.zs", nullptr, on_record, on_error),
                      Warm::ArchiveError);
}

TEST_CASE("Shader warm compute records deserialize with the application layout", "[video_core][shader_warm]") {
    std::vector<u8> control(108);
    Put<u32>(control, 88, 32);
    Put<u32>(control, 92, 2);
    Put<u32>(control, 96, 1);
    Put<u32>(control, 100, 257);
    Put<u32>(control, 104, 64);
    REQUIRE_FALSE(Warm::ReadComputeControl(std::span{control}.first(107)).has_value());
    const auto parsed = Warm::ReadComputeControl(control);
    REQUIRE(parsed.has_value());
    REQUIRE(parsed->shared_memory == 512);

    Warm::LoweredCode lowered;
    lowered.code.resize(96);
    constexpr u64 instruction = 0x123456789abcdef0ULL;
    Put<u64>(lowered.code, 80, instruction);
    Warm::ComputeKey key;
    const auto bytes = Warm::ComputeEntry(lowered, *parsed, key);
    TemporaryRecord record;
    record.Write(bytes);
    std::ifstream in(record.path, std::ios::binary);
    u32 count{};
    in.read(reinterpret_cast<char*>(&count), sizeof(count));
    REQUIRE(count == 1);
    VideoCommon::FileEnvironment environment;
    environment.Deserialize(in);
    REQUIRE(in.good());
    REQUIRE(environment.ShaderStage() == Shader::Stage::Compute);
    REQUIRE(environment.WorkgroupSize() == parsed->workgroup);
    REQUIRE(environment.SharedMemorySize() == 512);
    REQUIRE(environment.LocalMemorySize() == 64);
    REQUIRE(environment.ReadInstruction(80) == instruction);
    Vulkan::ComputePipelineCacheKey runtime_key{};
    in.read(reinterpret_cast<char*>(&runtime_key), sizeof(runtime_key));
    REQUIRE(in.good());
    REQUIRE(runtime_key.unique_hash == Warm::StageHash(lowered.code));
    REQUIRE(std::memcmp(key.data(), &runtime_key, key.size()) == 0);
}

TEST_CASE("Shader warm graphics guesses read D records without modifying their cache", "[video_core][shader_warm]") {
    std::vector<u8> program(144);
    Put<u32>(program, 0, 1U << 10); // Synthetic vertex header, no game code.
    Warm::LoweredCode lowered;
    lowered.code.resize(96);
    const auto env = Warm::GraphicsEnv(0, lowered, program);
    const u64 hash = Warm::StageHash(lowered.code);
    constexpr u64 attributes = 0x55;
    const auto key = Warm::GraphicsEntryKey(0, Warm::DefaultTemplate(true), hash, attributes);
    std::vector<u8> cache(16);
    std::memcpy(cache.data(), "yuzucach", 8);
    Put<u32>(cache, 8, 55); // D's schema is read only for state guesses.
    Put<u32>(cache, 12, 1);
    cache.insert(cache.end(), env.begin(), env.end());
    cache.insert(cache.end(), key.begin(), key.end());
    TemporaryRecord record;
    record.Write(cache);
    const auto stats = Warm::ReadRuntimeStats({record.path});
    REQUIRE(stats.occurrences == 1);
    REQUIRE(stats.templates[0].has_value());
    REQUIRE(stats.vertex_attributes.at(hash) == std::vector<u64>{attributes});
    std::ifstream in(record.path, std::ios::binary);
    const std::vector<u8> unchanged(std::istreambuf_iterator<char>{in},
                                    std::istreambuf_iterator<char>{});
    REQUIRE(unchanged == cache);
    REQUIRE_FALSE(Warm::IsReadableRuntimeCacheVersion(18));
    REQUIRE(Warm::WarmCacheVersion == VideoCommon::VulkanPipelineCacheVersion);
}
