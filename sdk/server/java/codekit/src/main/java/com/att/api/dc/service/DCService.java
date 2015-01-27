/* vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 */

/*
 * Copyright 2014 AT&T
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.att.api.dc.service;

import com.att.api.dc.model.DCResponse;
import com.att.api.oauth.OAuthToken;
import com.att.api.rest.RESTClient;
import com.att.api.rest.RESTException;
import com.att.api.service.APIService;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Used to interact with version 2 of the Device Capabilities API.
 *
 * <p>
 * This class is thread safe.
 * </p>
 *
 * @author pk9069
 * @version 1.0
 * @since 1.0
 * @see <a href="https://developer.att.com/docs/apis/rest/2/Device%20Capabilities">DC Documentation</a>
 */
public class DCService extends APIService {

    /**
     * Creates a DCService object.
     *
     * @param fqdn fully qualified domain name to use for sending requests
     * @param token OAuth token to use for authorization
     */
    public DCService(final String fqdn, final OAuthToken token) {
        super(fqdn, token);
    }

    /**
     * Sends a request to the API for getting device capabilities.
     *
     * @return DCResponse API Response
     * @throws RESTException if API request was not successful
     */
    public DCResponse getDeviceCapabilities() throws RESTException {
        String endpoint = getFQDN() + "/rest/2/Devices/Info";

        try {
            JSONObject jsonResponse = new JSONObject(getDeviceCapabilitiesAndReturnRawJson());
            return DCResponse.valueOf(jsonResponse);
        } catch (JSONException pe) {
            throw new RESTException(pe);
        }
    }

    public String getDeviceCapabilitiesAndReturnRawJson() throws RESTException {
        String endpoint = getFQDN() + "/rest/2/Devices/Info";

        return new RESTClient(endpoint)
            .addAuthorizationHeader(getToken())
            .httpGet()
            .getResponseBody();
    }
}
