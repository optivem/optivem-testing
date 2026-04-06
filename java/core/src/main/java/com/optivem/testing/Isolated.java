package com.optivem.testing;

import org.junit.jupiter.api.Tag;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation to mark tests that require isolation from other tests.
 * 
 * <p>Use this annotation for tests that:
 * <ul>
 *   <li>Modify shared state (e.g., deleting all orders)</li>
 *   <li>Depend on specific time values (@TimeDependent tests)</li>
 *   <li>Have side effects that could affect other tests</li>
 *   <li>Need exclusive access to resources</li>
 * </ul>
 * 
 * <h2>Filtering Tests</h2>
 * 
 * <h3>Run ONLY isolated tests:</h3>
 * <pre>
 * gradlew :system-test:acceptance-test:test -DincludeTags=isolated
 * </pre>
 * 
 * <h3>Run all tests EXCEPT isolated tests:</h3>
 * <pre>
 * gradlew :system-test:acceptance-test:test -DexcludeTags=isolated
 * </pre>
 * 
 * <h3>IDE Support:</h3>
 * Most IDEs that support JUnit 5 will recognize this tag automatically:
 * <ul>
 *   <li>IntelliJ IDEA: Right-click → "Run tests with tag 'isolated'"</li>
 *   <li>Eclipse: Run Configurations → Test → Tags</li>
 *   <li>VS Code: Test Explorer should show tags</li>
 * </ul>
 */
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Tag("isolated")
public @interface Isolated {
    /**
     * Optional reason why this test needs isolation.
     * @return description of isolation requirement, empty string if not specified
     */
    String value() default "";
}
