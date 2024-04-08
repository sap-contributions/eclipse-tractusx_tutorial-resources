/*
 *  Copyright (c) 2023 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 *
 *  This program and the accompanying materials are made available under the
 *  terms of the Apache License, Version 2.0 which is available at
 *  https://www.apache.org/licenses/LICENSE-2.0
 *
 *  SPDX-License-Identifier: Apache-2.0
 *
 *  Contributors:
 *       Bayerische Motoren Werke Aktiengesellschaft (BMW AG) - initial API and implementation
 *
 */

package api;

import org.eclipse.edc.junit.extensions.EdcClassRuntimesExtension;
import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;
import org.jetbrains.annotations.NotNull;
import org.junit.jupiter.api.extension.RegisterExtension;

import java.util.HashMap;

import static org.eclipse.edc.junit.testfixtures.TestUtils.getFreePort;

public interface InMemoryRuntime {

    EdcRuntimeExtension RUNTIME = new EdcRuntimeExtension(
            "backend-service",
            "backend-service-logs",
            inMemoryConfiguration()
    );

    @RegisterExtension
    EdcClassRuntimesExtension RUNTIMES = new EdcClassRuntimesExtension(RUNTIME);

    @NotNull
    static HashMap<String, String> inMemoryConfiguration() {
        return new HashMap<>() {
            {
                put("web.http.path", "/api");
                put("web.http.port", String.valueOf(getFreePort()));
                put("edc.hostname", "localhost");
            }
        };
    }

}
