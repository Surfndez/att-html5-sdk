# Copyright 2014 AT&T
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'cgi'

module Att
  module Codekit
    module Auth

      class AuthCode < OAuthService
        attr_reader :redirect
        # @!attribute [r] redirect
        #   @return [String] the url used for redirect post oauth

        # Constructor for OAuthService
        #
        # @param fqdn [String] the url to make the request to
        # @param client_id [String] the client id assigned for application
        # @param client_secret [String] the client secret assigned for the application
        # @param opts [Hash] optional data to set at creation time 
        # @option opts [#to_s] :redirect location to redirect after consent flow
        # @option opts [String, Array<String>] :scope the scope(s) in which to request a token
        # @option opts [String] :suburl the suburl of the fqdn for requesting tokens, 
        #   do not use unless you absolutely know what you are doing (default: '/oauth/v4/token')
        # @option opts [String] :auth_url the suburl of the fqdn for performing consent flow, 
        #   do not use unless you absolutely know what you are doing (default: '/oauth/v4/authorize')
        def initialize(fqdn, client_id, client_secret, opts={}) 
          super(fqdn, client_id, client_secret, opts)
          @auth_url = (opts[:auth_url] || '/oauth/v4/authorize')
          @redirect = opts[:redirect]
        end

        # Authenticate a token with authentication code
        #
        # @param code [String] The code to use for authentication
        # @return [OAuthToken] A new token that's been authenticated via code
        def createToken(code)
          makeToken(:authorization_code, :code => code.to_s)
        end
        alias_method :authenticate_token, :createToken

        # Generate a url to redirect to in order to perform authentication
        #   and obtain a code to receive a token, if required.
        #
        # @param opts [Hash] Options hash for specifying extra parameters
        # @option opts [String] :scope the scope to authenticate with
        # @option opts [String] :suburl the location relative to the fqdn
        # @option opts [String] :redirect the location to redirect after consent
        # @return [String] a url based on the OAuth object to perform authentication
        def generateConsentFlowUrl(opts={})
          scope = Array(opts[:scope] || @scope).join(",")
          suburl = (opts[:suburl] || @auth_url)
          redirect = (opts[:redirect] || @redirect)
          "#{@fqdn}#{suburl}?client_id=#{CGI.escape(@client_id)}&scope=#{CGI.escape(scope)}&redirect_uri=#{CGI.escape(redirect)}"
        end
        alias_method :consentFlow, :generateConsentFlowUrl

      end # AuthCode

    end
  end
end
