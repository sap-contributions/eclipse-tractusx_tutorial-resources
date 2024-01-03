/*******************************************************************************
 *
 * Copyright (c) 2023 Contributors to the Eclipse Foundation
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

package org.eclipse.tractusx.mxd.util;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.security.SecureRandom;

public class RandomWordUtil {

    public static String generateRandom() {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            RandomData randomData = new RandomData();
            randomData.setUserId(generateRandomUserId());
            randomData.setTitle(generateRandomString());
            randomData.setText(generateRandomString());
            return objectMapper.writeValueAsString(randomData);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static int generateRandomUserId() {
        return Math.abs(new SecureRandom().nextInt());
    }

    private static String generateRandomString() {
        String characters = "abcdefghijklmnopqrstuvwxyz";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder();

        int length = random.nextInt(8) + 1;
        for (int i = 0; i < length; i++) {
            int index = random.nextInt(characters.length());
            sb.append(characters.charAt(index));
        }
        return sb.toString();
    }

    private static class RandomData {
        private int userId;
        private String title;
        private String text;

        public int getUserId() {
            return userId;
        }

        public void setUserId(int userId) {
            this.userId = userId;
        }

        public String getTitle() {
            return title;
        }

        public void setTitle(String title) {
            this.title = title;
        }

        public String getText() {
            return text;
        }

        public void setText(String text) {
            this.text = text;
        }
    }
}
