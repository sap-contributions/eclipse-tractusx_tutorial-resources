/*
 *  Copyright (c) 2024 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
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

package api.testixtures;

import org.eclipse.edc.junit.testfixtures.TestUtils;
import org.eclipse.edc.spi.persistence.EdcPersistenceException;

import java.io.IOException;
import java.nio.file.Files;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public interface PostgresqlEndToEndInstance {

    String USER = "postgres";
    String PASSWORD = "postgres";
    String JDBC_URL_PREFIX = "jdbc:postgresql://localhost:5432/";

    static void createDatabase(String participantName) {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new EdcPersistenceException(e);
        }
        var postgres = new PostgresqlLocalInstance(USER, PASSWORD, JDBC_URL_PREFIX, participantName);
        postgres.createDatabase();
        try {
            var extensionsFolder = TestUtils.findBuildRoot().toPath().resolve("backend-service");
            var scripts = Files.walk(extensionsFolder)
                    .filter(path -> path.getFileName().toString().equals("schema.sql"))
                    .findFirst()
                    .orElse(null);
            try (var connection = postgres.getConnection(participantName)) {
                for (var script : scripts) {
                    var sql = Files.readString(script);

                    try (var statement = connection.createStatement()) {
                        statement.execute(sql);
                    } catch (Exception exception) {
                        throw new EdcPersistenceException(exception.getMessage(), exception);
                    }
                }
            } catch (SQLException | IOException e) {
                throw new EdcPersistenceException(e);
            }
        } catch (Exception e) {
            throw new EdcPersistenceException(e);
        }
    }

    static Map<String, String> defaultDatasourceConfiguration(String name) {
        return new HashMap<>() {
            {
                put("edc.datasource.default.url", JDBC_URL_PREFIX + name);
                put("edc.datasource.default.user", USER);
                put("edc.datasource.default.password", PASSWORD);
            }
        };
    }

}
