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

import io.restassured.specification.RequestSpecification;
import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;

import static io.restassured.RestAssured.given;
import static org.eclipse.edc.junit.testfixtures.TestUtils.getFreePort;

public abstract class BackendServiceApiEndToEndTestBase {

    public static final int PORT = getFreePort();
    public static final int PROTOCOL_PORT = getFreePort();

    protected final EdcRuntimeExtension runtime;

    public BackendServiceApiEndToEndTestBase(EdcRuntimeExtension runtime) {
        this.runtime = runtime;
    }

    protected RequestSpecification baseRequest() {
        return given()
                .port(PORT)
                .baseUri("http://localhost:%s/".formatted(PORT))
                .when();
    }

}
