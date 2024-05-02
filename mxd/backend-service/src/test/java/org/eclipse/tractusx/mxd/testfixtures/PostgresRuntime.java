/*******************************************************************************
 *
 * Copyright (c) 2024 Contributors to the Eclipse Foundation
 *
 * See the NOTICE file(s) distributed with this work for additional
 * information regarding copyright ownership.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Apache License, Version 2.0 which is available at
 * https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 ******************************************************************************/

package org.eclipse.tractusx.mxd.testfixtures;

import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;
import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.RegisterExtension;

import java.util.Map;

public interface PostgresRuntime {

    @RegisterExtension
    static final BeforeAllCallback CREATE_DATABASE = context -> PostgresqlEndToEndInstance.createDatabase("runtime");

    @RegisterExtension
    public static final EdcRuntimeExtension RUNTIME = new EdcRuntimeExtension(
            "",
            "backend",
            Map.of(
                    "edc.datasource.default.url", PostgresqlEndToEndInstance.JDBC_URL_PREFIX + "runtime",
                    "edc.datasource.default.user", PostgresqlEndToEndInstance.USER,
                    "edc.datasource.default.password", PostgresqlEndToEndInstance.PASSWORD
            )
    );

}
