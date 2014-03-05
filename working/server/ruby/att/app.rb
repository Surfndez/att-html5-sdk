##
# This is an example Sinatra application demonstrating both server and client
# components of the AT&T HTML5 SDK library for interacting with AT&T's APIs.
#
# In order to run this example code, you will need an application set up. 
# You can sign up for an account at https://developer.att.com/
#
# Once you have logged in, set-up an application and make sure all of the APIs
# are provisioned. Be sure to set your OAuth callback URL to 
# http://127.0.0.1:4567/att/callback
#
# Update the server/ruby/conf/att-api.properties file with your Application ID
# and Secret Key, then start the server by executing:
#
#     ruby app.rb
#

require 'rubygems'
require 'sinatra'
require 'rack/mime'
require File.join(File.dirname(__FILE__), '../lib.old/base')
require File.join(File.dirname(__FILE__), '../lib/codekit')

include Att::Codekit

# Sinatra configuration
enable :sessions
set :bind, '0.0.0.0'
set :session_secret, 'random line noize634$#&g45gs%hrt#$%RTbw%Ryh46w5yh' # must be the same in app.rb and listener.rb

# This enables application's 'debug' mode. Set to 'false` to disable debugging.
# Remove this when the Sencha library is removed.
Sencha::DEBUG = :all

WEB_APP_ROOT = File.expand_path(File.dirname(__FILE__) + '/../../../webcontent')
CONFIG_DIR = File.expand_path(File.dirname(__FILE__) + '/../conf')
PROVIDER = "ServiceProvider"

#defines the media folder location used to find files for MMS, MOBO and SPEECH
MEDIA_DIR = File.expand_path(File.dirname(__FILE__) + '/../media')

# This points the public folder to the Sencha Touch application.
set :public_folder, WEB_APP_ROOT

# This ensures that sinatra doesn't set the X-Frame-Options header.
set :protection, :except => :frame_options

# This ensure the config data.
$config = YAML.load_file(File.join(CONFIG_DIR, 'att-api.properties'))

# This configures which port to listen on.
configure do
  set :port, ARGV[0] || 4567
end


host = $config['apiHost'].to_s
client_id = $config['apiKey'].to_s
client_secret = $config['secretKey'].to_s
client_model_scope = $config['clientModelScope'].to_s
  
if(/\/$/ =~ host)
  host.slice!(/\/$/)
end

#disable SSL verification is enableSSLCheck is set to false
enableSSLCheck = $config['enableSSLCheck']
if(!enableSSLCheck)
  I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end
    
# can be removed when completely migrated to codekit
#
# This sets up the ATT library with the client applicationID and secretID. These will have been
# given to you when you registered your application on the AT&T developer site.
@@att = Sencha::ServiceProvider::Base.init(
  :provider => :att,

  :client_id => client_id,
  :client_secret => client_secret,

  # This is the main endpoint through which all API requests are made.
  :host => host,
  
  # This is the address of the locally running server. This is used when a callback URL is
  # required when making a request to the AT&T APIs.
  :local_server => $config['localServer'].to_s,

  :client_model_methods => %w(getAd requestChargeAuth subscriptionDetails refundTransaction transactionStatus subscriptionStatus getNotification acknowledgeNotification),
  :client_model_scope => client_model_scope,
  :auth_model_scope_methods => {
    "deviceInfo" => "DC",
    "sendMobo" => "IMMN",
    "getMessageHeaders" => "MIM"  
  }
)

client_credential = Auth::ClientCred.new(host, client_id, client_secret)
$client_token = client_credential.createToken(client_model_scope)
@@att.client_model_token = $client_token.access_token # can be removed when codekit conversion is complete


# The root URL starts off the web application. On the desktop, any Webkit browser
# will work, such as Google Chrome or Apple Safari. It's best to use desktop browsers
# when developing and debugging your application due to the superior developer tools such
# as the Web Inspector.
get '/' do
  File.read(File.join(WEB_APP_ROOT, 'index.html'))
end

def return_json_file(file, error_response)
  begin
    file_contents = File.read file
  rescue Exception => e
    file_contents = error_response
  end
  JSON.parse(file_contents).to_json # clean up the json
end

def querystring_to_options(request, allowed_options, opts = {})
  allowed_options.each do |sym| 
    str = sym.to_s
    if request[str]
      opts[sym] = URI.decode request[str]
    end
  end
  return opts
end

# convert a map of file-extensions to mime-types into
# a map of mime-types to file-extensions
$extension_map = Rack::Mime::MIME_TYPES.invert

def mime_type_to_extension(mime_type)
  return '.wav' if mime_type == 'audio/wav' # some systems only have audio/x-wav in their MIME_TYPES
  return $extension_map[mime_type]
end

def save_attachment_as_file(file_data)
  rack_file = file_data[:tempfile]
  rack_filename = rack_file.path
  file_extension = mime_type_to_extension file_data[:type]
  filename = File.join(MEDIA_DIR, File.basename(rack_filename) + file_extension)
  FileUtils.copy(rack_filename, filename)
  filename
end

require File.join(File.dirname(__FILE__), 'check.rb')
require File.join(File.dirname(__FILE__), 'direct_router.rb')
require File.join(File.dirname(__FILE__), 'services/ads.rb')
require File.join(File.dirname(__FILE__), 'services/device.rb')
require File.join(File.dirname(__FILE__), 'services/iam.rb')
require File.join(File.dirname(__FILE__), 'services/mms.rb')
require File.join(File.dirname(__FILE__), 'services/oauth.rb')
require File.join(File.dirname(__FILE__), 'services/payment.rb')
require File.join(File.dirname(__FILE__), 'services/sms.rb')
require File.join(File.dirname(__FILE__), 'services/speech.rb')