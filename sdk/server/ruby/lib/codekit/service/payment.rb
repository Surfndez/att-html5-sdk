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

require 'json'
require_relative '../model/payment'
require_relative '../model/payment_notification'

module Att
  module Codekit
    module Service

        # valid categories
        module Categories
          IN_APP_GAMES = 1
          IN_APP_VIRTUAL_GOODS = 2
          IN_APP_OTHER = 3
          APPLICATION_GAMES = 4
          APPLICATION_OTHER = 5
        end

        # valid transaction types
        module TransactionType
          TransactionId = "TransactionId"
          TransactionAuthCode = "TransactionAuthCode"
          MerchantTransactionId = "MerchantTransactionId"
        end

        # valid subscription types
        module SubscriptionType
          SubscriptionId = "SubscriptionId"
          SubscriptionAuthCode = "SubscriptionAuthCode"
          MerchantTransactionId = "MerchantTransactionId"
        end

        # valid transaction states
        module TransactionState
          Refunded = "Refunded"
          SubscriptionCancelled = "SubscriptionCancelled"
        end

        # valid refund codes
        module RefundCodes
          CP_None = 1
          CP_Loss_of_Eligibility = 2
          CP_Product_Termination = 3
          CP_Abuse_of_Privileges = 4
          CP_Conversion_to_New_Product = 5
          CP_Nonrenewable_Product = 6
          CP_Duplicate_Subscription =7 
          CP_Other = 8
          Subscriber_None = 9
          Subscriber_Did_Not_Use = 10
          Subscriber_Too_Expensive = 11
          Subscriber_Did_Not_Like = 12
          Subscriber_Replaced_By_Same_Company = 13
          Subscriber_Replaced_By_Different_Company =14
          Subscriber_Duplicate_Subscription = 15
          Subscriber_Other = 16
        end

      #@author kh455g
      class PaymentService < CloudService
        module SERVICE_URL
          Transactions = "/rest/3/Commerce/Payment/Transactions"
          NotarySignature = "/Security/Notary/Rest/1/SignedPayload"
          Subscriptions = "/rest/3/Commerce/Payment/Subscriptions"
          Notifications = "/rest/3/Commerce/Payment/Notifications"
        end

        # Create a new transaction and return a url for authentication
        #
        # @param amount [#to_f] how much the item costs, rounds to 2 decimal 
        #   places
        # @param category [#to_i] see module Categories for possible values
        # @param desc [String] short description of purchase, must be less 
        #   than 128 chars
        # @param merch_trans_id [String] the transaction id in merchant's 
        #   system, must be unique for every purchase
        # @param merch_prod_id [String] specifies the product id of the item 
        #   purchased, must be less than 50 chars
        # @param redirect_uri [String] the location to redirect to after a new 
        #   transaction
        # @param channel [String] defines the merchant user interface, 
        #   currently only one option so ignore
        # @return [String] a url that can be redirected to for completing 
        #   authentication of a payment
        def newTransaction(amount, category, desc, merch_trans_id, 
                           merch_prod_id, redirect_uri, channel='MOBILE_WEB')
          channel = channel

          payload = {
            :Amount => amount,
            :Category => category.to_i,
            :Description => desc,
            :MerchantTransactionId => merch_trans_id,
            :MerchantProductId => merch_prod_id,
            :MerchantPaymentRedirectUrl => redirect_uri,
            :Channel => channel,
          }.to_json

          response = signPayload(payload)

          from_json = JSON.parse response

          parameters = "?Signature=#{from_json['Signature']}&SignedPaymentDetail=#{from_json['SignedDocument']}&clientid=#{@client.id}"

          "#{@fqdn}#{SERVICE_URL::Transactions}#{parameters}"
        end

        # Create a new subscription and return a url for authentication
        #
        # @param amount [#to_f] how much the item costs, rounds to 2 decimal 
        #   places
        # @param category [#to_i] see module Categories for possible values
        # @param desc [String] short description of purchase, must be less 
        #   than 128 chars
        # @param merch_trans_id [String] the transaction id in merchant's 
        #   system, must be unique for every purchase
        # @param merch_prod_id [String] specifies the product id of the item 
        #   purchased, must be less than 50 chars
        # @param redirect_uri[String] the location to redirect to after a new 
        #   subscription
        # @param [Hash] opts an option hash to define additional parameters
        # @option opts [String] :channel defines the merchant user interface, 
        #   currently only one option so ignore
        # @option opts [Integer] :sub_period_amount number of subscription 
        #   periods between renewals, currently only one option so ignore
        # @option opts [String] :sub_period The interval of periods, currently 
        #   only one option ('MONTHLY') so ignore
        # @option opts [Boolean] :iponas Current documentation is unclear, 
        #   currently only one option so ignore
        # @return [String] a url that can be redirected to for completing 
        #   authentication of a subscription
        def newSubscription(amount, category, desc, merch_trans_id,
                            merch_prod_id, merch_sub_id, sub_recurrances,
                            redirect_uri,  opts={})
          sub_period_amount = (opts[:sub_period_amount] || 1) 
          sub_period = (opts[:sub_period] || 'MONTHLY')
          is_purchase_on_no_active_sub = (opts[:iponas] || false)
          channel = (opts[:channel] || "MOBILE_WEB")

          payload = {
            :Amount => amount,
            :Category => category,
            :Description => desc,
            :MerchantTransactionId => merch_trans_id,
            :MerchantProductId => merch_prod_id,
            :MerchantSubscriptionIdList => merch_sub_id,
            :SubscriptionRecurrences => sub_recurrances,
            :MerchantPaymentRedirectUrl => redirect_uri,
            :SubscriptionPeriodAmount => sub_period_amount,
            :SubscriptionPeriod => sub_period,
            :IsPurchaseOnNoActiveSubscription => is_purchase_on_no_active_sub,
            :Channel => channel,
          }.to_json

          response = signPayload(payload)

          from_json = JSON.parse response

          parameters = "?Signature=#{from_json['Signature']}&SignedPaymentDetail=#{from_json['SignedDocument']}&clientid=#{@client.id}"

          "#{@fqdn}#{SERVICE_URL::Subscriptions}#{parameters}"
        end

        # Get the transaction status based on type and id
        #
        # @param transaction_type [String] the type of transaction being 
        #   performed (see #TransactionType)
        # @param transaction_id [String] the id relative to the type
        # @return [RestClient::Response] a parsed response object 
        # @raise [ServiceException] raised when issue with transaction type
        def getTransaction(transaction_type, transaction_id)
          raise ServiceException, "Unknown Transaction type: " + transaction_type unless TransactionType.const_defined? transaction_type
          url = "#{@fqdn}#{SERVICE_URL::Transactions}/#{transaction_type}/#{transaction_id}"

          headers = {
            :Accept => 'application/json',
          }

          response = self.get(url, headers)

          Model::TransactionStatus.createFromJson(response)
        end

        # Get the transaction status based on transaction id
        #
        # @param transaction_id [String] the id of the transaction
        # @return [RestClient::Response] a parsed response object 
        # @raise [ServiceException] raised when issue with transaction type
        def getTransactionByTransactionId(transaction_id)
          self.getTransaction(TransactionType::TransactionId,
                              transaction_id)
        end

        # Get the transaction status based on merchant transaction id
        #
        # @param mtransaction_id [String] the merchant transaction id
        # @return [RestClient::Response] a parsed response object 
        # @raise [ServiceException] raised when issue with transaction type
        def getTransactionByMerchantTransactionId(mtransaction_id)
          self.getTransaction(TransactionType::MerchantTransactionId, 
                              mtransaction_id)
        end

        # Get the transaction status based on transaction auth code
        #
        # @param auth_code [String] the auth code of the transaction
        # @return [RestClient::Response] a parsed response object 
        # @raise [ServiceException] raised when issue with transaction type
        def getTransactionByAuthCode(auth_code)
          self.getTransaction(TransactionType::TransactionAuthCode,
                              auth_code)
        end

        # Get the Subscription object specified
        #
        # @param subscription_type [String] method to obtain the Subscription 
        #   (see #SubscriptionType)
        # @param subscription_id [String] the id relative to the type
        # @return [RestClient::Response] a parsed response object
        def getSubscription(subscription_type, subscription_id)
          raise ServiceException, "Unknown Subscription type: " + subscription_type unless SubscriptionType.const_defined? subscription_type
          url = "#{@fqdn}#{SERVICE_URL::Subscriptions}/#{subscription_type}/#{subscription_id}"

          headers = {
            :Accept => 'application/json',
          }

          response = self.get(url, headers)
          Model::SubscriptionStatus.createFromJson(response)
        end

        def getSubscriptionByAuthCode(auth_code)
          self.getSubscription(SubscriptionType::SubscriptionAuthCode,
                               auth_code)
        end

        def getSubscriptionById(subscription_id)
          self.getSubscription(SubscriptionType::SubscriptionId,
                               subscription_id)
        end

        def getSubscriptionByMerchantTransactionId(trans_id)
          self.getSubscription(SubscriptionType::MerchantTransactionId,
                               trans_id)
        end

        # Get the Subscription Details from a transaction
        #
        # @param consumer_id [String] the user id generated representing the 
        #   subscriber
        # @param merchant_subscription_id [String] the subscription product id 
        #   of the merchant
        # @return [RestClient::Response] a parsed response object
        def getSubscriptionDetails(consumer_id, merchant_subscription_id)
          url = "#{@fqdn}#{SERVICE_URL::Subscriptions}/#{merchant_subscription_id}/Detail/#{consumer_id}"

          headers = {
            :Accept => 'application/json',
          }
          response = self.get(url, headers)
          Model::SubscriptionDetails.createFromJson(response)
        end

        # Refund a previous transaction
        #
        # @param transaction_id [String] the id of the transaction to refund
        # @param refund_reason [Integer] generalized code for refund 
        #   (see #RefundCodes)
        # @param refund_reason_text [String] specific reason for refund
        # @param transaction_state [String] the state of the transaction 
        #   (see #TransactionState)
        # @param action [String] action being performed
        # @return [RestClient::Response] a parsed response object
        def refundTransaction(transaction_id, 
                              refund_reason, 
                              refund_reason_text, 
                              transaction_state=TransactionState::Refunded, 
                              action="refund")
          raise ServiceException, "Unknown Transaction state: " + transaction_state unless TransactionState.const_defined? transaction_state

          url = "#{@fqdn}#{SERVICE_URL::Transactions}/#{transaction_id}?Action=#{action}"

          payload = {
            :TransactionOperationStatus => transaction_state,
            :RefundReasonCode => refund_reason,
            :RefundReasonText => refund_reason_text,
          }.to_json

          headers = {
            :Accept => 'application/json',
            :Content_Type => 'application/json',
          }

          response = self.put(url, payload, headers)
          Model::TransactionRefund.createFromJson(response)
        end
        alias_method :refundSubscription, :refundTransaction

        # Cancel a subscription
        #
        # @note This does not refund money, it will only cancel the ongoing
        #   subscription. To refund and cancel a subscription use
        #   refundSubscription
        #
        # @see refundTransaction
        def cancelSubscription(transaction_id, refund_reason, refund_reason_text)
          refundTransaction(transaction_id, refund_reason, refund_reason_text, TransactionState::SubscriptionCancelled)
        end

        # Sign a payload with the ATT notary service
        #
        # @param payload [JSON] a json object that defines the payload to sign.
        def signPayload(payload)
          url = "#{@fqdn}#{SERVICE_URL::NotarySignature}"

          headers = {
            :Accept => "application/json",
            :Content_Type => "application/json",
            'client_id' => @client.id,
            'client_secret' => @client.secret
          }

          self.post(url, payload, headers)
        end

        # Get the notification details for specified id                            
        #                                                                          
        # @param notification_id [String] the notification id to request
        # @deprecated
        def getNotification(notification_id)                                     
          url = "#{@fqdn}#{SERVICE_URL::Notifications}/#{notification_id}"           

          headers = {
            :Accept => "application/json",
          }

          self.get(url, headers)
        end                                                                        

        # Acknowledge/Delete a notification
        #
        # @note after this function is called the notification is no longer 
        #   accessible by #getNotification
        #
        # @param notification_id [String] the id of the notification to remove
        # @deprecated
        def ackNotification(notification_id)                                       
          url = "#{@fqdn}#{SERVICE_URL::Notifications}/#{notification_id}"

          headers = {
            :Accept => 'application/json',
          }

          self.put(url, "", headers) 
        end    
        alias_method :deleteNotification, :ackNotification

      end
    end
  end
end
