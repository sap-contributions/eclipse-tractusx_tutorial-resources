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
import org.eclipse.tractusx.mxd.backendservice.store.ContentStoreService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.util.UUID;

import static jakarta.json.Json.createObjectBuilder;
import static org.assertj.core.api.Assertions.assertThat;
import static org.eclipse.edc.jsonld.spi.JsonLdKeywords.*;
import static org.hamcrest.Matchers.is;

/**
 * Asset V3 endpoints end-to-end tests
 */
public class ContentApiEndToEndTest {

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
        void shouldSimpleTest()
        {
            Assertions.assertEquals(1,1);
        }

        @Test
        void getAssetById() {
            var id = UUID.randomUUID().toString();
            var content = getContent(id);
            getContentIndex().save(content);
            var body = baseRequest()
                    .get("/v1/contents" + id)
                    .then()
                    .statusCode(200)
                    .extract().body().jsonPath();

            assertThat(body).isNotNull();
            assertThat(body.getString(ID)).isEqualTo(id);
        }

        private  Content getContent(String id) {
            return new Content(id,"{\"id\": \"123456\", \"data\": \"Sample data\", \"createdAt\": 1647624632}",
                    Clock.systemUTC(),
                    System.currentTimeMillis());
        }

        @Test
        void createAsset_shouldBeStored() {
            var id = UUID.randomUUID().toString();
            var contentJson = createObjectBuilder()
                    .add("id", id)
                    .add("data", "{\"id\": \"123456\", \"data\": \"Sample data\", \"createdAt\": 1647624632}")
                    .add("clock", String.valueOf(Clock.systemUTC()))
                    .add("createdAt", System.currentTimeMillis())
                    .build();

            baseRequest()
                    .contentType(ContentType.JSON)
                    .body(contentJson)
                    .post("/v1/contents")
                    .then()
                    .log().ifError()
                    .statusCode(200)
                    .body(ID, is(id));

            assertThat(getContentIndex().findById(id)).isNotNull();
        }

        private ContentStoreService getContentIndex() {
            return runtime.getContext().getService(ContentStoreService.class);
        }


    }

}
