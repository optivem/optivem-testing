package com.optivem.testing.systemtest.smoketest.release;

import com.optivem.testing.Channel;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class SmokeTest {

    @Test
    public void shouldLoadLibrary() {
        var channelClass = Channel.class;
        assertNotNull(channelClass);
    }
}