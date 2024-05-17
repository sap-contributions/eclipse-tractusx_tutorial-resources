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

package org.eclipse.tractusx.mxd.backendservice.service;

import org.eclipse.edc.spi.result.StoreResult;
import org.eclipse.tractusx.mxd.backendservice.entity.ContentResponse;

public interface ContentService {

    String create(Object content);

    String getAllContent();

    StoreResult<ContentResponse> getContent(String contentId);

    String getRandomContent();

}