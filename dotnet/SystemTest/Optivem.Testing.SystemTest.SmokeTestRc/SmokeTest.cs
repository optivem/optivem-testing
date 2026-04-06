using Shouldly;
using Xunit;

namespace Optivem.Testing.SystemTest.SmokeTestRc;

/// <summary>
/// Smoke tests to verify the published RC package from GitHub Packages works correctly.
/// These tests consume the Optivem.Testing package as a NuGet dependency (not a project reference).
/// </summary>
public class SmokeTest
{
    [Fact]
    public void ShouldLoadLibrary()
    {
        var channelClass = typeof(Channel);
        channelClass.ShouldNotBeNull();
    }
}
