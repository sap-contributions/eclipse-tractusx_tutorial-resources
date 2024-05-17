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
 *       SAP SE - initial API and implementation
 *
 ********************************************************************************/

package org.eclipse.tractusx.mxd.backendservice.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriBuilder;
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

    private final String host;
    private final String port;

    public ContentApiController(ContentService service, Monitor monitor, ObjectMapper objectMapper,
                                String host, String port) {
        this.service = service;
        this.monitor = monitor;
        this.objectMapper = objectMapper;
        this.host = host;
        this.port = port;
    }

    @POST
    public String createContent(Object contentJson) {
        var contentID = this.service.create(contentJson);
        return createJsonResponse(contentID);
    }

    @GET
    public String getAllContent() {
        return this.service.getAllContent();
    }

    @GET
    @Path("/{contentId}")
    public String getContentByID(@PathParam("contentId") String contentId) {
        return Optional.of(contentId)
                .map(id -> service.getContent(contentId))
                .map(content -> content.getContent() != null ? content.getContent().getData() : Converter.toJson(content.getFailure(), objectMapper))
                .orElse(Constants.DEFAULTERRORMESSAGE);
    }

    @GET
    @Path("/random")
    public Response getRandomContent(@QueryParam("size") @DefaultValue("1KB") String size) {
        if (!isValidSizeParam(size)) {
            return createResponse("Invalid size param. Use KB or MB.",
                    Response.Status.BAD_REQUEST);
        }
        String content = this.service.getRandomContent(size);
        return createResponse(content, Response.Status.OK);
    }

    @GET
    @Path("/create/random")
    public Response createRandomContent(@QueryParam("size") @DefaultValue("1KB") String size) {
        if (!isValidSizeParam(size)) {
            return createResponse("Invalid size param. Use KB or MB.",
                    Response.Status.BAD_REQUEST);
        }

        var contentID = this.service.createRandomContent(size);
        String content  = createJsonResponse(contentID);
        return createResponse(content, Response.Status.OK);
    }

    private boolean isValidSizeParam(String size) {
        if (size.endsWith("KB") || size.endsWith("MB")) {
            try {
                Integer.parseInt(size.substring(0, size.length() - 2).trim());
                return true;
            } catch (NumberFormatException e) {
                return false;
            }
        }
        return false;
    }

    private Response createResponse(String content, Response.Status status) {
        return Response
                .status(status)
                .entity(content)
                .build();
    }

    private String createJsonResponse(String id) {
        JsonNode jsonResponse = objectMapper.createObjectNode()
                .put("id", id)
                .put("url", UriBuilder.fromUri("http://" + host + ":" + port)
                        .path("api")
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
