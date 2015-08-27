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

require 'immutable_struct'


module Att
  module Codekit
    module Model

      class SuccessCreated < ImmutableStruct.new(:location)
        def self.from_response(response)
          headers = response.headers unless response.nil?

          new(headers[:location]) if headers
        end
      end

      class SuccessNoContent < ImmutableStruct.new(:last_modified)
        def self.from_response(response)
          headers = response.headers unless response.nil?

          new(headers[:last_modified]) if headers
        end
      end

      class SuccessDeleted < ImmutableStruct.new(:id)
        def self.from_response(response)
          id = response.headers[:x_systemTransactionId] unless response.nil?

          new(id)
        end
      end

    end
  end
end
