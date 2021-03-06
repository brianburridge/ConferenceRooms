require 'fog/core'

module Fog
  module Radosgw
    module MultipartUtils
      require 'net/http'

      class Headers
        include Net::HTTPHeader

        def initialize
          initialize_http_header({})
        end

        # Parse a single header line into its key and value
        # @param [String] chunk a single header line
        def self.parse(chunk)
          line = chunk.strip
          # thanks Net::HTTPResponse
          return [nil,nil] if chunk =~ /\AHTTP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/in
          m = /\A([^:]+):\s*/.match(line)
          [m[1], m.post_match] rescue [nil, nil]
        end

        # Parses a header line and adds it to the header collection
        # @param [String] chunk a single header line
        def parse(chunk)
          key, value = self.class.parse(chunk)
          add_field(key, value) if key && value
        end
      end

      def parse(data, boundary)
        contents = data.match(end_boundary_regex(boundary)).pre_match rescue ""
        contents.split(inner_boundary_regex(boundary)).reject(&:empty?).map do |part|
          parse_multipart_section(part)
        end.compact
      end

      def extract_boundary(header_string)
        $1 if header_string =~ /boundary=([A-Za-z0-9\'()+_,-.\/:=?]+)/
      end

      private
      def end_boundary_regex(boundary)
        /\r?\n--#{Regexp.escape(boundary)}--\r?\n?/
      end

      def inner_boundary_regex(boundary)
        /\r?\n--#{Regexp.escape(boundary)}\r?\n/
      end

      def parse_multipart_section(part)
        headers = Headers.new
        if md = part.match(/\r?\n\r?\n/)
          body = md.post_match
          md.pre_match.split(/\r?\n/).each do |line|
            headers.parse(line)
          end

          if headers["content-type"] =~ /multipart\/mixed/
            boundary = extract_boundary(headers.to_hash["content-type"].first)
            parse(body, boundary)
          else
            {:headers => headers.to_hash, :body => body}
          end
        end
      end
    end

    module UserUtils

      def update_radosgw_user(user_id, user)
        path         = "admin/user"
        user_id      = escape(user_id)
        params       = {
          :method => 'POST',
          :path => path,
        }
        query        = "?uid=#{user_id}&format=json&suspended=#{user[:suspended]}"
        begin
          response = Excon.post("#{@scheme}://#{@host}/#{path}#{query}",
                                :headers => signed_headers(params))
          if !response.body.empty?
            case response.headers['Content-Type']
            when 'application/json'
              response.body = Fog::JSON.decode(response.body)
            end
          end
          response
        rescue Excon::Errors::NotFound => e
          raise Fog::Radosgw::Provisioning::NoSuchUser.new
        rescue Excon::Errors::BadRequest => e
          raise Fog::Radosgw::Provisioning::ServiceUnavailable.new
        end
      end

      def update_mock_user(user_id, user)
        if data[user_id]
          if suspended = user[:suspended]
            data[user_id][:suspended] = suspended
          end

          Excon::Response.new.tap do |response|
            response.status = 200
            response.body   = data[user_id]
          end
        else
          Excon::Response.new.tap do |response|
            response.status = 403
          end
        end
      end
    end

    module Utils
      def configure_uri_options(options = {})
        @host       = options[:host]       || 'localhost'
        @persistent = options[:persistent] || true
        @port       = options[:port]       || 8080
        @scheme     = options[:scheme]     || 'http'
      end

      def radosgw_uri
        "#{@scheme}://#{@host}:#{@port}"
      end

      def escape(string)
        string.gsub(/([^a-zA-Z0-9_.\-~]+)/) {
          "%" + $1.unpack("H2" * $1.bytesize).join("%").upcase
        }
      end

      def signature(params, expires)
        headers = params[:headers] || {}

        string_to_sign =
<<-DATA
#{params[:method].to_s.upcase}
#{headers['Content-MD5']}
#{headers['Content-Type']}
#{expires}
DATA

        amz_headers, canonical_amz_headers = {}, ''
        for key, value in headers
          if key[0..5] == 'x-amz-'
            amz_headers[key] = value
          end
        end
        amz_headers = amz_headers.sort {|x, y| x[0] <=> y[0]}
        for key, value in amz_headers
          canonical_amz_headers << "#{key}:#{value}\n"
        end
        string_to_sign << canonical_amz_headers
 

        query_string = ''
        if params[:query]
          query_args = []
          for key in params[:query].keys.sort
            if VALID_QUERY_KEYS.include?(key)
              value = params[:query][key]
              if value
                query_args << "#{key}=#{value}"
              else
                query_args << key
              end
            end
          end
          if query_args.any?
            query_string = '?' + query_args.join('&')
          end
        end

        canonical_path = (params[:path] || object_to_path(params[:object_name])).to_s
        canonical_path = '/' + canonical_path if canonical_path[0..0] != '/'
        if params[:bucket_name]
          canonical_resource = "/#{params[:bucket_name]}#{canonical_path}"
        else
          canonical_resource = canonical_path
        end
        canonical_resource << query_string
        string_to_sign << canonical_resource

        hmac = Fog::HMAC.new('sha1', @radosgw_secret_access_key)
        signed_string = hmac.sign(string_to_sign)
        Base64.encode64(signed_string).chomp!
      end

      def signed_headers(params)
        expires = Fog::Time.now.to_date_header
        auth   =  signature(params,expires)
        awskey =  @radosgw_access_key_id
        headers = {
          'Date'          => expires,
          'Authorization' => "AWS #{awskey}:#{auth}"
        }
      end
    end

    extend Fog::Provider

    service(:provisioning, 'Provisioning')
    service(:usage,        'Usage')
  end
end
