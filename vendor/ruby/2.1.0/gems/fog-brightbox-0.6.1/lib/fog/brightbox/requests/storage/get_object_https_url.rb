module Fog
  module Storage
    class Brightbox

      class Real

        # Get an expiring object https url from Cloud Files
        #
        # ==== Parameters
        # * container<~String> - Name of container containing object
        # * object<~String> - Name of object to get expiring url for
        # * expires<~Time> - An expiry time for this url
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String> - url for object
        def get_object_https_url(container, object, expires, options = {})
          create_temp_url(container, object, expires, "GET", options.merge(:scheme => "https"))
        end

        # creates a temporary url
        #
        # ==== Parameters
        # * container<~String> - Name of container containing object
        # * object<~String> - Name of object to get expiring url for
        # * expires<~Time> - An expiry time for this url
        # * method<~String> - The method to use for accessing the object (GET, PUT, HEAD)
        # * scheme<~String> - The scheme to use (http, https)
        # * options<~Hash> - An optional options hash
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~String> - url for object
        #
        # ==== See Also
        # http://docs.rackspace.com/files/api/v1/cf-devguide/content/Create_TempURL-d1a444.html
        def create_temp_url(container, object, expires, method, options = {})
          raise ArgumentError, "Insufficient parameters specified." unless (container && object && expires && method)
          raise ArgumentError, "Storage must be instantiated with the :brightbox_temp_url_key option" if @brightbox_temp_url_key.nil?

          scheme = options[:scheme] || @scheme

          # POST not allowed
          allowed_methods = %w{GET PUT HEAD}
          unless allowed_methods.include?(method)
            raise ArgumentError.new("Invalid method '#{method}' specified. Valid methods are: #{allowed_methods.join(', ')}")
          end


          expires        = expires.to_i
          object_path_escaped   = "#{@path}/#{Fog::Storage::Brightbox.escape(container)}/#{Fog::Storage::Brightbox.escape(object,"/")}"
          object_path_unescaped = "#{@path}/#{Fog::Storage::Brightbox.escape(container)}/#{object}"
          string_to_sign = "#{method}\n#{expires}\n#{object_path_unescaped}"

          hmac = Fog::HMAC.new('sha1', @brightbox_temp_url_key)
          sig  = sig_to_hex(hmac.sign(string_to_sign))

          temp_url_options = {
            :scheme => scheme,
            :host => @host,
            :port => @port,
            :path => object_path_escaped,
            :query => URI.encode_www_form(
              :temp_url_sig => sig,
              :temp_url_expires => expires
            )
          }
          URI::Generic.build(temp_url_options).to_s
        end

        private

        def sig_to_hex(str)
          str.unpack("C*").map { |c|
            c.to_s(16)
          }.map { |h|
            h.size == 1 ? "0#{h}" : h
          }.join
        end

      end

    end
  end
end
