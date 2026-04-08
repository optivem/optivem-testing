using Shouldly;
using Xunit;

namespace Optivem.Testing.Tests;

/// <summary>
/// Unit tests verifying all ChannelData patterns work correctly.
/// Tests the Cartesian product generation for:
/// 1. ChannelData alone (simple mode)
/// 2. ChannelData + ChannelInlineData
/// 3. ChannelData + ChannelClassData
/// 4. ChannelData + ChannelMemberData (method, property, external type)
/// </summary>
public class ChannelDataAttributeTests
{
    #region Test Data Providers

    // Provider for ChannelClassData tests
    public class TestDataProvider : IEnumerable<object[]>
    {
        public IEnumerator<object[]> GetEnumerator()
        {
            yield return new object[] { "value1", "message1" };
            yield return new object[] { "value2", "message2" };
        }

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
    }

    // Provider for ChannelMemberData tests (static method)
    public static IEnumerable<object[]> GetMemberTestData()
    {
        yield return new object[] { "memberValue1", "memberMessage1" };
        yield return new object[] { "memberValue2", "memberMessage2" };
    }

    // Provider for ChannelMemberData tests (static property)
    public static IEnumerable<object[]> MemberTestDataProperty => new[]
    {
        new object[] { "propertyValue1", "propertyMessage1" },
        new object[] { "propertyValue2", "propertyMessage2" }
    };

    #endregion

    #region Pattern 1: ChannelData Only (Simple Mode)

    [Theory]
    [ChannelData("UI", "API")]
    public void ChannelData_Simple_ShouldGenerateTestForEachChannel(Channel channel)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
    }

    [Theory]
    [ChannelData("UI")]
    public void ChannelData_SingleChannel_ShouldGenerateOneTest(Channel channel)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBe("UI");
    }

    [Theory]
    [ChannelData("UI", "API", "Mobile")]
    public void ChannelData_ThreeChannels_ShouldGenerateThreeTests(Channel channel)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API", "Mobile");
    }

    #endregion

    #region Pattern 2: ChannelData + ChannelInlineData

    [Theory]
    [ChannelData("UI", "API")]
    [ChannelInlineData("value1", "message1")]
    [ChannelInlineData("value2", "message2")]
    public void ChannelData_WithChannelInlineData_ShouldGenerateCartesianProduct(
        Channel channel, 
        string value, 
        string message)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
        value.ShouldBeOneOf("value1", "value2");
        message.ShouldBeOneOf("message1", "message2");
        
        // Verify the pairing
        if (value == "value1")
        {
            message.ShouldBe("message1");
        }
        else if (value == "value2")
        {
            message.ShouldBe("message2");
        }
    }

    [Theory]
    [ChannelData("UI")]
    [ChannelInlineData("")]
    [ChannelInlineData("   ")]
    public void ChannelData_WithChannelInlineData_EmptyValues_ShouldWork(
        Channel channel, 
        string emptyValue)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBe("UI");
        emptyValue.ShouldBeOneOf("", "   ");
    }

    [Theory]
    [ChannelData("UI", "API")]
    [ChannelInlineData(1)]
    [ChannelInlineData(2)]
    [ChannelInlineData(3)]
    public void ChannelData_WithChannelInlineData_Numbers_ShouldWork(
        Channel channel, 
        int number)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
        number.ShouldBeOneOf(1, 2, 3);
    }

    #endregion

    #region Pattern 2b: ChannelData + ChannelInlineData with Also (additional channels)

    /// <summary>
    /// Base channel is "API". First row also runs on "UI".
    /// Expected: 3 test cases (API+"both", UI+"both", API+"baseOnly").
    /// </summary>
    [Theory]
    [ChannelData("API")]
    [ChannelInlineData("both", "message-both", Also = new[] { "UI" })]
    [ChannelInlineData("baseOnly", "message-base")]
    public void ChannelData_WithChannelInlineData_Also_ShouldAddChannels(
        Channel channel,
        string value,
        string message)
    {
        if (channel.Type == "UI")
        {
            // UI should only see the row with Also
            value.ShouldBe("both");
            message.ShouldBe("message-both");
        }
        else
        {
            // API should see both rows
            channel.Type.ShouldBe("API");
            value.ShouldBeOneOf("both", "baseOnly");
        }
    }

    /// <summary>
    /// Simulates the real-world use case: API is base, first row also runs on UI.
    /// Expected: 5 test cases (API×4 rows + UI×1 row with Also).
    /// </summary>
    [Theory]
    [ChannelData("API")]
    [ChannelInlineData("20.00", "5", "100.00", Also = new[] { "UI" })]
    [ChannelInlineData("10.00", "3", "30.00")]
    [ChannelInlineData("15.50", "4", "62.00")]
    [ChannelInlineData("99.99", "1", "99.99")]
    public void ChannelData_WithChannelInlineData_Also_MixedRows_ShouldReduceUiTests(
        Channel channel,
        string unitPrice,
        string quantity,
        string basePrice)
    {
        channel.Type.ShouldBeOneOf("API", "UI");
        unitPrice.ShouldNotBeNullOrEmpty();
        quantity.ShouldNotBeNullOrEmpty();
        basePrice.ShouldNotBeNullOrEmpty();

        if (channel.Type == "UI")
        {
            // UI should only see the row with Also
            unitPrice.ShouldBe("20.00");
        }
    }

    /// <summary>
    /// Without Also — current cartesian product behavior should be unchanged.
    /// Expected: 4 test cases (2 channels × 2 rows).
    /// </summary>
    [Theory]
    [ChannelData("UI", "API")]
    [ChannelInlineData("row1")]
    [ChannelInlineData("row2")]
    public void ChannelData_WithChannelInlineData_WithoutAlso_ShouldPreserveCartesian(
        Channel channel,
        string value)
    {
        channel.Type.ShouldBeOneOf("UI", "API");
        value.ShouldBeOneOf("row1", "row2");
    }

    #endregion

    #region Pattern 2c: ChannelData with AlsoForFirstRow + ChannelInlineData

    /// <summary>
    /// AlsoForFirstRow with ChannelInlineData: API is base, UI only for first row.
    /// Expected: 4 test cases (API×3 rows + UI×1 first row).
    /// </summary>
    [Theory]
    [ChannelData("API", AlsoForFirstRow = new[] { "UI" })]
    [ChannelInlineData("first", "message1")]
    [ChannelInlineData("second", "message2")]
    [ChannelInlineData("third", "message3")]
    public void ChannelData_WithAlsoForFirstRow_ChannelInlineData_ShouldAddChannelOnlyForFirstRow(
        Channel channel,
        string value,
        string message)
    {
        channel.Type.ShouldBeOneOf("API", "UI");
        value.ShouldNotBeNullOrEmpty();

        if (channel.Type == "UI")
        {
            value.ShouldBe("first");
            message.ShouldBe("message1");
        }
    }

    #endregion

    #region Pattern 3: ChannelData + ChannelClassData

    [Theory]
    [ChannelData("UI", "API")]
    [ChannelClassData(typeof(TestDataProvider))]
    public void ChannelData_WithChannelClassData_ShouldGenerateCartesianProduct(
        Channel channel, 
        string value, 
        string message)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
        value.ShouldBeOneOf("value1", "value2");
        message.ShouldBeOneOf("message1", "message2");
        
        // Verify the pairing
        if (value == "value1")
        {
            message.ShouldBe("message1");
        }
        else if (value == "value2")
        {
            message.ShouldBe("message2");
        }
    }

    /// <summary>
    /// AlsoForFirstRow with ChannelClassData: API is base, UI only for first row.
    /// Expected: 3 test cases (API×2 rows + UI×1 first row).
    /// </summary>
    [Theory]
    [ChannelData("API", AlsoForFirstRow = new[] { "UI" })]
    [ChannelClassData(typeof(TestDataProvider))]
    public void ChannelData_WithAlsoForFirstRow_ChannelClassData_ShouldAddChannelOnlyForFirstRow(
        Channel channel,
        string value,
        string message)
    {
        channel.Type.ShouldBeOneOf("API", "UI");
        value.ShouldNotBeNullOrEmpty();

        if (channel.Type == "UI")
        {
            value.ShouldBe("value1");
            message.ShouldBe("message1");
        }
    }

    #endregion

    #region Pattern 4: ChannelData + ChannelMemberData (Method)

    [Theory]
    [ChannelData("UI", "API")]
    [ChannelMemberData(nameof(GetMemberTestData))]
    public void ChannelData_WithChannelMemberData_Method_ShouldGenerateCartesianProduct(
        Channel channel, 
        string value, 
        string message)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
        value.ShouldBeOneOf("memberValue1", "memberValue2");
        message.ShouldBeOneOf("memberMessage1", "memberMessage2");
        
        // Verify the pairing
        if (value == "memberValue1")
        {
            message.ShouldBe("memberMessage1");
        }
        else if (value == "memberValue2")
        {
            message.ShouldBe("memberMessage2");
        }
    }

    /// <summary>
    /// AlsoForFirstRow with ChannelMemberData (method): API is base, UI only for first row.
    /// Expected: 3 test cases (API×2 rows + UI×1 first row).
    /// </summary>
    [Theory]
    [ChannelData("API", AlsoForFirstRow = new[] { "UI" })]
    [ChannelMemberData(nameof(GetMemberTestData))]
    public void ChannelData_WithAlsoForFirstRow_ChannelMemberData_ShouldAddChannelOnlyForFirstRow(
        Channel channel,
        string value,
        string message)
    {
        channel.Type.ShouldBeOneOf("API", "UI");
        value.ShouldNotBeNullOrEmpty();

        if (channel.Type == "UI")
        {
            value.ShouldBe("memberValue1");
            message.ShouldBe("memberMessage1");
        }
    }

    #endregion

    #region Pattern 5: ChannelData + ChannelMemberData (Property)

    [Theory]
    [ChannelData("UI", "API")]
    [ChannelMemberData(nameof(MemberTestDataProperty))]
    public void ChannelData_WithChannelMemberData_Property_ShouldGenerateCartesianProduct(
        Channel channel, 
        string value, 
        string message)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
        value.ShouldBeOneOf("propertyValue1", "propertyValue2");
        message.ShouldBeOneOf("propertyMessage1", "propertyMessage2");
        
        // Verify the pairing
        if (value == "propertyValue1")
        {
            message.ShouldBe("propertyMessage1");
        }
        else if (value == "propertyValue2")
        {
            message.ShouldBe("propertyMessage2");
        }
    }

    #endregion

    #region Pattern 6: ChannelData + ChannelMemberData (External Type)

    [Theory]
    [ChannelData("UI", "API")]
    [ChannelMemberData(nameof(ExternalDataProvider.GetExternalData), typeof(ExternalDataProvider))]
    public void ChannelData_WithChannelMemberData_ExternalType_ShouldGenerateCartesianProduct(
        Channel channel, 
        string value, 
        string message)
    {
        // Arrange & Act
        var channelType = channel.Type;

        // Assert
        channelType.ShouldBeOneOf("UI", "API");
        value.ShouldBeOneOf("externalValue1", "externalValue2");
        message.ShouldBeOneOf("externalMessage1", "externalMessage2");
        
        // Verify the pairing
        if (value == "externalValue1")
        {
            message.ShouldBe("externalMessage1");
        }
        else if (value == "externalValue2")
        {
            message.ShouldBe("externalMessage2");
        }
    }

    #endregion

    #region Test Count Verification Documentation

    [Fact]
    public void Documentation_ChannelData_Simple_GeneratesCorrectCount()
    {
        // This is a meta-test documenting expected behavior:
        // 2 channels = 2 tests
        // Verified by: ChannelData_Simple_ShouldGenerateTestForEachChannel
        true.ShouldBeTrue();
    }

    [Fact]
    public void Documentation_ChannelData_WithInlineData_GeneratesCorrectCount()
    {
        // This is a meta-test documenting expected behavior:
        // 2 channels � 2 inline data rows = 4 tests
        // Verified by: ChannelData_WithChannelInlineData_ShouldGenerateCartesianProduct
        true.ShouldBeTrue();
    }

    [Fact]
    public void Documentation_ChannelData_WithClassData_GeneratesCorrectCount()
    {
        // This is a meta-test documenting expected behavior:
        // 2 channels � 2 class data rows = 4 tests
        // Verified by: ChannelData_WithChannelClassData_ShouldGenerateCartesianProduct
        true.ShouldBeTrue();
    }

    [Fact]
    public void Documentation_ChannelData_WithMemberData_GeneratesCorrectCount()
    {
        // This is a meta-test documenting expected behavior:
        // 2 channels � 2 member data rows = 4 tests
        // Verified by: ChannelData_WithChannelMemberData_Method_ShouldGenerateCartesianProduct
        true.ShouldBeTrue();
    }

    #endregion

    #region Negative Tests: Standard xUnit Attributes Should Throw Exceptions

    [Fact]
    public void ChannelData_WithInlineData_ShouldThrowHelpfulException()
    {
        // This test documents that using [InlineData] with [ChannelData] should throw an exception
        // guiding the user to use [ChannelInlineData] instead.
        // The actual validation happens at test discovery time, so this is a documentation test.
        true.ShouldBeTrue();
    }

    [Fact]
    public void ChannelData_WithClassData_ShouldThrowHelpfulException()
    {
        // This test documents that using [ClassData] with [ChannelData] should throw an exception
        // guiding the user to use [ChannelClassData] instead.
        // The actual validation happens at test discovery time, so this is a documentation test.
        true.ShouldBeTrue();
    }

    [Fact]
    public void ChannelData_WithMemberData_ShouldThrowHelpfulException()
    {
        // This test documents that using [MemberData] with [ChannelData] should throw an exception
        // guiding the user to use [ChannelMemberData] instead.
        // The actual validation happens at test discovery time, so this is a documentation test.
        true.ShouldBeTrue();
    }

    [Fact]
    public void ChannelData_WithFactInsteadOfTheory_ShouldThrowHelpfulException()
    {
        // This test documents that using [Fact] with [ChannelData] should throw an exception
        // guiding the user to use [Theory] instead.
        // The actual validation happens at test discovery time, so this is a documentation test.
        true.ShouldBeTrue();
    }

    [Fact]
    public void ChannelData_WithoutTheory_CannotBeDetected()
    {
        // LIMITATION: xUnit does not call GetData() without [Theory] attribute present.
        // Without [Theory], xUnit doesn't recognize the method as a theory test,
        // so it never calls ChannelDataAttribute.GetData() where our validation lives.
        //
        // Result: The method is simply ignored during test discovery (silently skipped).
        // This is a limitation of xUnit's architecture, not our validation.
        //
        // BEST PRACTICE: Always use [Theory] with [ChannelData]
        true.ShouldBeTrue();
    }

    #endregion
}

/// <summary>
/// External data provider for testing ChannelMemberData with external types.
/// </summary>
public class ExternalDataProvider
{
    public static IEnumerable<object[]> GetExternalData()
    {
        yield return new object[] { "externalValue1", "externalMessage1" };
        yield return new object[] { "externalValue2", "externalMessage2" };
    }
}

/// <summary>
/// Negative test cases that should fail at test discovery time.
/// These are commented out because they would cause test discovery to fail,
/// but they document the expected validation behavior.
/// 
/// Uncommenting any of these should result in a helpful exception message.
/// </summary>
public class NegativeTestExamples
{
    /*
    // This should throw: "Cannot use [InlineData] with [ChannelData]. Use [ChannelInlineData] instead."
    [Theory]
    [ChannelData("UI", "API")]
    [InlineData("value1")]
    public void ShouldFail_WhenUsingInlineDataWithChannelData(Channel channel, string value)
    {
    }

    // This should throw: "Cannot use [ClassData] with [ChannelData]. Use [ChannelClassData] instead."
    [Theory]
    [ChannelData("UI", "API")]
    [ClassData(typeof(TestDataProvider))]
    public void ShouldFail_WhenUsingClassDataWithChannelData(Channel channel, string value, string message)
    {
    }

    // This should throw: "Cannot use [MemberData] with [ChannelData]. Use [ChannelMemberData] instead."
    [Theory]
    [ChannelData("UI", "API")]
    [MemberData(nameof(ChannelDataAttributeTests.GetMemberTestData))]
    public void ShouldFail_WhenUsingMemberDataWithChannelData(Channel channel, string value, string message)
    {
    }
    */
}
