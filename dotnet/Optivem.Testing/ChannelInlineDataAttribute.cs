namespace Optivem.Testing;

/// <summary>
/// Specifies inline test data for use with [ChannelData].
/// When combined with [ChannelData], creates a Cartesian product of channels � data rows.
/// Follows xUnit's [InlineData] naming convention.
/// </summary>
[AttributeUsage(AttributeTargets.Method, AllowMultiple = true)]
public class ChannelInlineDataAttribute : Attribute
{
    public object[] Data { get; }

    /// <summary>
    /// Additional channels this data row should also run on, beyond the base channels
    /// declared in [ChannelData]. When null (default), the row runs on base channels only.
    /// </summary>
    /// <example>
    /// [ChannelData(ChannelType.API)]
    /// [ChannelInlineData("20.00", "5", "100.00", Also = new[] { ChannelType.UI })]   // API + UI
    /// [ChannelInlineData("10.00", "3", "30.00")]                                      // API only
    /// </example>
    public string[]? Also { get; set; }

    /// <summary>
    /// Specifies test data parameters (excluding the channel parameter).
    /// </summary>
    /// <param name="data">Test data values</param>
    public ChannelInlineDataAttribute(params object[] data)
    {
        Data = data ?? throw new ArgumentNullException(nameof(data));
    }
}
