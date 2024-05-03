/********************************************************************************
 *  Copyright (c) 2024 SAP SE
 *
 *  This program and the accompanying materials are made available under the
 *  terms of the Apache License, Version 2.0 which is available at
 *  https://www.apache.org/licenses/LICENSE-2.0
 *
 *  SPDX-License-Identifier: Apache-2.0
 *
 *  Contributors:
 *       SAP SE - initial implementation
 *
 ********************************************************************************/

package org.eclipse.tractusx.mxd.e2e;

import io.restassured.http.ContentType;
import jakarta.json.JsonObject;
import org.eclipse.edc.junit.annotations.PostgresqlIntegrationTest;
import org.eclipse.edc.junit.extensions.EdcRuntimeExtension;
import org.eclipse.tractusx.mxd.backendservice.entity.Content;
import org.eclipse.tractusx.mxd.backendservice.store.ContentStoreService;
import org.eclipse.tractusx.mxd.testfixtures.PostgresRuntime;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static io.restassured.http.ContentType.JSON;
import static jakarta.json.Json.createObjectBuilder;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.is;

public class ContentApiEndToEndTest {

    @Nested
    @PostgresqlIntegrationTest
    class Postgres extends Tests implements PostgresRuntime {
        Postgres() {
            super(RUNTIME);
        }
    }

    abstract static class Tests extends BackendServiceApiEndToEndTestBase {

        private final static String ENDPOINT = "/v1/contents/";

        Tests(EdcRuntimeExtension runtime) {
            super(runtime);
        }

        @Test
        void getContentById() {
            String id = UUID.randomUUID().toString();
            Content content = getContent(id);
            ContentStoreService storeService = getContentIndex();

            String storeResultId = storeService.save(content);

            baseRequest()
                    .when()
                    .get(ENDPOINT + storeResultId)
                    .then()
                    .log().ifValidationFails()
                    .statusCode(200)
                    .contentType(JSON)
                    .body("id", is(id))
                    .body("data", is(getContentData()));
        }

        @Test
        void getAllContents() {
            String id = UUID.randomUUID().toString();
            Content content = getContent(id);
            ContentStoreService storeService = getContentIndex();

            storeService.save(content);

            baseRequest()
                    .when()
                    .get(ENDPOINT)
                    .then()
                    .log().ifValidationFails()
                    .statusCode(200)
                    .contentType(JSON)
                    .body("size()", is(greaterThan(1)));
        }

        @Test
        void createAsset_shouldBeStored() {
            String id = UUID.randomUUID().toString();
            JsonObject contentJson = getContentJson(id);

            String contentId = baseRequest()
                    .contentType(ContentType.JSON)
                    .body(contentJson)
                    .post(ENDPOINT)
                    .then()
                    .log().ifError()
                    .statusCode(200)
                    .extract().jsonPath()
                    .getString("id");

            assertThat(getContentIndex().findById(contentId)).isNotNull();
        }

        @Test
        void getRandomContent() {
            var body = baseRequest()
                    .when()
                    .get(ENDPOINT + "random")
                    .then()
                    .log().ifValidationFails()
                    .statusCode(200)
                    .contentType(JSON)
                    .body("userId", is(greaterThan(-1)));

            assertThat(body).isNotNull();
        }

        private ContentStoreService getContentIndex() {
            return runtime.getContext().getService(ContentStoreService.class);
        }

        public JsonObject getContentJson(String id) {
            return createObjectBuilder()
                    .add("id", id)
                    .add("data", getContentData())
                    .add("createdAt", System.currentTimeMillis())
                    .build();

        }

        private Content getContent(String id) {
            return Content.Builder
                    .newInstance()
                    .id(id)
                    .data(getContentData())
                    .build();
        }

        private String getContentData() {
            return "\"userId\": 1, " +
                    "\"id\": 1, " +
                    "\"title\": \"delectus aut autem\", " +
                    "\"completed\": false";
        }
    }
}