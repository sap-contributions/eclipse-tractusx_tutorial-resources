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

package org.eclipse.tractusx.mxd.test;

import io.restassured.http.ContentType;
import jakarta.json.JsonObject;
import org.eclipse.edc.junit.annotations.PostgresqlIntegrationTest;
import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;
import org.eclipse.edc.spi.result.StoreResult;
import org.eclipse.tractusx.mxd.backendservice.entity.Transfer;
import org.eclipse.tractusx.mxd.backendservice.entity.TransferResponse;
import org.eclipse.tractusx.mxd.backendservice.store.TransferStoreService;
import org.eclipse.tractusx.mxd.testfixtures.PostgresRuntime;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static io.restassured.http.ContentType.JSON;
import static jakarta.json.Json.createObjectBuilder;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.is;

public class TransferApiEndToEndTest {

    @Nested
    @PostgresqlIntegrationTest
    class Postgres extends Tests implements PostgresRuntime {
        Postgres() {
            super(RUNTIME);
        }
    }

    abstract static class Tests extends BackendServiceApiEndToEndTestBase {

        private final static String ENDPOINT = "/v1/transfers/";

        Tests(EdcRuntimeExtension runtime) {
            super(runtime);
        }

        @Test
        void createTransfer_shouldBeStored() {
            String id = UUID.randomUUID().toString();
            JsonObject transferJson = getTransferJson(id);

            baseRequest()
                    .contentType(ContentType.JSON)
                    .body(transferJson)
                    .post(ENDPOINT)
                    .then()
                    .statusCode(200)
                    .body("id", is(id))
                    .body("authCode", is(transferJson.getString("authCode")))
                    .body("authKey", is(transferJson.getString("authKey")))
                    .body("endpoint", is(transferJson.getString("endpoint")));

            StoreResult<TransferResponse> response = getTransferIndex().findById(id);

            assertThat(response).isNotNull();
            assertThat(response.getContent().getTransferID()).isEqualTo(id);
        }

        @Test
        void getTransferWithId() {
            String id = UUID.randomUUID().toString();
            String userId = UUID.randomUUID().toString();

            Transfer transfer = getTransfer(id);
            JsonObject content = getContentJson(userId);
            getTransferIndex().save(transfer, content.toString());

            baseRequest()
                    .get(ENDPOINT + id)
                    .then()
                    .log().ifValidationFails()
                    .statusCode(200)
                    .contentType(JSON)
                    .body("id", is(id))
                    .body("authCode", is(transfer.getAuthCode()))
                    .body("authKey", is(transfer.getAuthKey()))
                    .body("endpoint", is(transfer.getEndpoint()));
        }

        @Test
        void getAssetContent() {
            String id = UUID.randomUUID().toString();
            TransferStoreService storeService = getTransferIndex();
            Transfer transfer = getTransfer(id);
            String userId = UUID.randomUUID().toString();
            JsonObject content = getContentJson(userId);
            storeService.save(
                    transfer,
                    content.toString()
            );

            baseRequest()
                    .get(ENDPOINT + id + "/contents")
                    .then()
                    .log().ifValidationFails()
                    .statusCode(200)
                    .contentType(JSON)
                    .body("userId", is(userId))
                    .body("id", is(content.getString("id")))
                    .body("title", is(content.getString("title")));

        }

        public JsonObject getTransferJson(String id) {
            return createObjectBuilder()
                    .add("id", id)
                    .add("endpoint", "https://jsonplaceholder.typicode.com/todos/1")
                    .add("authKey", "Authorization")
                    .add("authCode", "100000")
                    .build();
        }

        public JsonObject getContentJson(String id) {
            return createObjectBuilder()
                    .add("userId", id)
                    .add("id", "0")
                    .add("title", "test")
                    .build();

        }

        private Transfer getTransfer(String id) {
            return new Transfer(id,
                    "https://jsonplaceholder.typicode.com/todos/1",
                    "Authorization",
                    "100000",
                    Map.of());
        }

        private TransferStoreService getTransferIndex() {
            return runtime.getContext().getService(TransferStoreService.class);
        }
    }
}
