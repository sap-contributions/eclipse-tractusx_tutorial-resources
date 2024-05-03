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

package org.eclipse.tractusx.mxd.backendservice.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.UriBuilder;
import jakarta.ws.rs.core.UriInfo;
import org.eclipse.edc.spi.monitor.Monitor;
import org.eclipse.tractusx.mxd.backendservice.service.ContentService;
import org.eclipse.tractusx.mxd.util.Constants;
import org.eclipse.tractusx.mxd.util.Converter;

import java.io.IOException;
import java.util.Optional;

@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
@Path("/v1/contents")
public class ContentApiController {

    private final Monitor monitor;

    private final ContentService service;

    private final ObjectMapper objectMapper;

    public ContentApiController(ContentService service, Monitor monitor, ObjectMapper objectMapper) {
        this.service = service;
        this.monitor = monitor;
        this.objectMapper = objectMapper;
    }

    @POST
    public String createContent(Object contentJson, @Context UriInfo uriInfo) {
        var contentID = this.service.create(contentJson);
        monitor.info(uriInfo.getAbsolutePath() + "/" + contentID);
        return createJsonResponse(contentID, uriInfo);
    }

    @GET
    public String getAllContent() {
        return this.service.getAllContent();
    }

    @GET
    @Path("/{contentId}")
    public String getContentByID(@PathParam("contentId") String contentId) {
        // var test = service.getContent(contentId);
        return Optional.of(contentId)
                .map(id -> service.getContent(contentId))
                .map(content -> content.getContent() != null ? content.getContent().getData() : Converter.toJson(content.getFailure(), objectMapper))
                .orElse(Constants.DEFAULTERRORMESSAGE);
    }

    @GET
    @Path("/random")
    public String getRandomContent() {
        return this.service.getRandomContent();
    }

    private String createJsonResponse(String id, UriInfo uriInfo) {
        JsonNode jsonResponse = objectMapper.createObjectNode()
                .put("id", id)
                .put("url", UriBuilder.fromUri(uriInfo.getBaseUri())
                        .path("v1")
                        .path("contents")
                        .path(String.valueOf(id))
                        .build().toString());
        try {
            return objectMapper.writeValueAsString(jsonResponse);
        } catch (IOException e) {
            return "{\"error\": \"" + e.getMessage() + "\"}";
        }
    }

}
