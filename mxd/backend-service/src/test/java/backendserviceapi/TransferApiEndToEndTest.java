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

package backendserviceapi;

import api.BackendServiceApiEndToEndTestBase;
import api.InMemoryRuntime;
import api.PostgresRuntime;
import api.testixtures.PostgresqlEndToEndInstance;
import io.restassured.http.ContentType;
import org.eclipse.edc.junit.annotations.EndToEndTest;
import org.eclipse.edc.junit.annotations.PostgresqlDbIntegrationTest;
import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;
import org.eclipse.tractusx.mxd.backendservice.entity.Content;
import org.eclipse.tractusx.mxd.backendservice.entity.Transfer;
import org.eclipse.tractusx.mxd.backendservice.entity.TransferRequest;
import org.eclipse.tractusx.mxd.backendservice.store.ContentStoreService;
import org.eclipse.tractusx.mxd.backendservice.store.TransferStoreService;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.util.Date;
import java.util.UUID;

import static jakarta.json.Json.createObjectBuilder;
import static org.assertj.core.api.Assertions.assertThat;
import static org.eclipse.edc.jsonld.spi.JsonLdKeywords.ID;
import static org.hamcrest.Matchers.is;

/**
 * Transfer V3 endpoints end-to-end tests
 */
public class TransferApiEndToEndTest {

    @Nested
    @EndToEndTest
    class InMemory extends Tests implements InMemoryRuntime {

        InMemory() {
            super(RUNTIME);
        }
    }

    @Nested
    @PostgresqlDbIntegrationTest
    class Postgres extends Tests implements PostgresRuntime {

        Postgres() {
            super(RUNTIME);
        }

        @BeforeAll
        static void beforeAll() {
            PostgresqlEndToEndInstance.createDatabase("runtime");
        }
    }

    abstract static class Tests extends BackendServiceApiEndToEndTestBase {

        Tests(EdcRuntimeExtension runtime) {
            super(runtime);
        }

        @Test
        void getAssetById() {
            var id = UUID.randomUUID().toString();
            var transfer = getTransfer(id,String.valueOf(getTransferRequest(id)));
            getTransferIndex().save(transfer,transfer.getContents());
            var body = baseRequest()
                    .get("/v1/transfers" + id)
                    .then()
                    .statusCode(200)
                    .extract().body().jsonPath();

            assertThat(body).isNotNull();
            assertThat(body.getString(ID)).isEqualTo(id);
        }

        private  TransferRequest getTransferRequest(String id) {
            return TransferRequest.builder().id(id).endpoint("https://jsonplaceholder.typicode.com/todos/1").build();
        }

        private  Transfer getTransfer(String id,String assets) {
            return Transfer.builder().transferID(id).asset(assets).contents("{\n" +
                    "  \"userId\": 1,\n" +
                    "  \"id\": 1,\n" +
                    "  \"title\": \"delectus aut autem\",\n" +
                    "  \"completed\": false\n" +
                    "}").createdDate(new Date()).updatedDate(new Date()).build();
        }

        @Test
        void createAsset_shouldBeStored() {
            var id = UUID.randomUUID().toString();
            var transferJson = createObjectBuilder()
                    .add("id", id)
                    .add("endpoint", "https://jsonplaceholder.typicode.com/todos/1")
                    .add("authKey", "")
                    .add("authCode", "")
                    .build();

            baseRequest()
                    .contentType(ContentType.JSON)
                    .body(transferJson)
                    .post("/v1/transfer")
                    .then()
                    .log().ifError()
                    .statusCode(200)
                    .body(ID, is(id));

            assertThat(getTransferIndex().findById(id)).isNotNull();
        }

        private TransferStoreService getTransferIndex() {
            return runtime.getContext().getService(TransferStoreService.class);
        }


    }

}
