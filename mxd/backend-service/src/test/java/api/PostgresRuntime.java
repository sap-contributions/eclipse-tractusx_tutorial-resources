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

import api.testixtures.PostgresqlEndToEndInstance;
import org.eclipse.edc.junit.extensions.EdcClassRuntimesExtension;
import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;
import org.jetbrains.annotations.NotNull;
import org.junit.jupiter.api.extension.RegisterExtension;

import java.util.HashMap;

import static api.InMemoryRuntime.inMemoryConfiguration;

public interface PostgresRuntime {

    EdcRuntimeExtension RUNTIME = new EdcRuntimeExtension(
            "backend-service",
            "backend-service",
            postgresqlConfiguration()
    );

    @RegisterExtension
    EdcClassRuntimesExtension RUNTIMES = new EdcClassRuntimesExtension(RUNTIME);

    @NotNull
    static HashMap<String, String> postgresqlConfiguration() {
        var config = new HashMap<String, String>() {
            {
                put("edc.datasource.default.url", PostgresqlEndToEndInstance.JDBC_URL_PREFIX + "runtime");
                put("edc.datasource.default.user", PostgresqlEndToEndInstance.USER);
                put("edc.datasource.default.password", PostgresqlEndToEndInstance.PASSWORD);
            }
        };

        config.putAll(inMemoryConfiguration());
        return config;
    }

}
