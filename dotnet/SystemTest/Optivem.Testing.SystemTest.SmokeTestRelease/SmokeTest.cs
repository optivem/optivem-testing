using Shouldly;
using Xunit;

namespace Optivem.Testing.SystemTest.SmokeTestRelease;

/// <summary>
/// Smoke tests to verify the published release package from NuGet.org works correctly.
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
