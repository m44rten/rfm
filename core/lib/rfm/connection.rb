require 'net/https'
require 'cgi'
require 'rfm/compound_query'
#require 'rfm/config'
#require 'logger'

#SaxChange

module Rfm
  class Connection
    using Refinements
    prepend Config
    
    # TODO: Make this autoload.
    require 'rexml/document'

    def initialize(host=nil, **opts) 
      host && config(host: host)
    end
    
    def log
      Rfm.log
    end
    
    def parser
      config[:parser]
    end

    def get_scheme(**opts)
      opts&.dig(:ssl) ? "https" : "http"
    end

    def get_port(**opts)
      opts&.dig(:ssl) && opts&.dig(:port).nil? ? 443 : opts&.dig(:port)
    end
    
    # Field mapping is really a layout concern. Where should it go?
    # It is not a connection attribute, I don't think.
    # def field_mapping
    #   @field_mapping ||= load_field_mapping(state[:field_mapping])
    # end
    def field_mapping(**opts)
      load_field_mapping(config.merge(opts)[:field_mapping])
    end
    

    ###  COMMANDS  ###
    #
    #    :options parameter refers (usually) to request options other than query parameters, including but not limited to: result size limit, filemaker xml grammar, xml parser template (usually a name, spec, or object), query scope (I think? ... maybe not), etc.
    #
    #    Check 'gen_params' method before changing any param name or options name in these methods,
    #    with specific reference to '_database' and '_layout', but not limited to those params.
    #
    # Returns a ResultSet object containing _every record_ in the table associated with this layout.
    def findall(_layout=nil, **options)
      #return unless self.class.const_defined?(:ENABLE_FINDALL) && ENABLE_FINDALL || ENV['ENABLE_FINDALL']
      options[:database] ||= config[:database]
      options[:layout] = _layout || options[:layout] || config[:layout]
      (options[:record_proc] = proc) if block_given?
      get_records('-findall', {}, options)
    end

    # Returns a ResultSet containing a single random record from the table associated with this layout.
    def findany(_layout=nil, **options)
      options[:database] ||= config[:database]
      options[:layout] = _layout || options[:layout] || config[:layout]
      get_records('-findany', {}, options)
    end

    # Finds a record. Typically you will pass in a hash of field names and values. For example:
    def find(*args)
      layout = args.shift if args.first.is_a?(String)
      find_criteria = args.shift
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:database] ||= config[:database]
      options[:layout] = layout || options[:layout] || config[:layout]
      find_criteria = {'-recid'=>find_criteria} if (find_criteria.to_s.to_i > 0)
      (options[:record_proc] = proc) if block_given?
      # Original (and better!) code for making this 'find' command compound-capable:
      get_records(*Rfm::CompoundQuery.new(find_criteria, options))
      # But then inserted this to stub 'find' to get it working for rfm v4 dev changes.
      #get_records('-find', find_criteria, options)
    end

    # Access to raw -findquery command.
    def query(*args)
      layout = args.shift if args.first.is_a?(String)
      query_hash = args.shift
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:database] ||= config[:database]
      options[:layout] = layout || options[:layout] || config[:layout]
      (options[:record_proc] = proc) if block_given?
      get_records('-findquery', query_hash, options)
    end

    # Updates the contents of the record whose internal +recid+ is specified.
    def edit(layout=nil, recid, data, **options)
      layout = args.shift if args.first.is_a?(String)
      recid = args.shift
      data = args.shift
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:database] ||= config[:database]
      options[:layout] = layout || options[:layout] || config[:layout]
      get_records('-edit', {'-recid' => recid}.merge(data), options)
      #get_records('-edit', {'-recid' => recid}.merge(expand_repeats(values)), options) # attempt to set repeating fields.
    end

    # Creates a new record in the table associated with this layout.
    def create(_layout=nil, data, **options)
      layout = args.shift if args.first.is_a?(String)
      data = args.shift
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:database] ||= config[:database]
      options[:layout] = layout || options[:layout] || config[:layout]
      get_records('-new', data, options)
    end

    # Deletes the record with the specified internal recid.
    def delete(_layout=nil, recid, **options)
      layout = args.shift if args.first.is_a?(String)
      recid = args.shift
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:database] ||= config[:database]
      options[:layout] = layout || options[:layout] || config[:layout]
      get_records('-delete', {'-recid' => recid}, options)
      
      # Do we really want to return nil? FMP XML API returns the original record.
      #return nil
    end

    # Retrieves metadata only, with an empty resultset.
    def view(layout=nil, **options)
      options[:database] ||= config[:database]
      options[:layout] = layout || options[:layout] || config[:layout]
      get_records('-view', {}, options)
    end
    
    def databases(**options)
      # This from factory.
      #c = Connection.new('-dbnames', {}, {:grammar=>'FMPXMLRESULT'}, @server)
      #c.parse('fmpxml_minimal.yml', {})['data'].each{|k,v| (self[k] = Rfm::Database.new(v['text'], @server)) if k.to_s != '' && v['text']}
      # We only need a basic array of strings, so the simplest way...
      #connect('-dbnames', {}, {:grammar=>'FMPXMLRESULT'}.merge(options)).body
      # But we want controll over grammer & parsing, so use get_records...
      options[:grammar] ||= 'FMPXMLRESULT'
      (options[:record_proc] = proc) if block_given?
      # Don't set this here. Try to use rfm-model to set it, if even needed at all.
      #options[:template] ||= :databases
      get_records('-dbnames', {}, options)
    end

    def layouts(**options)
      # Experimental, uses Commands::Layouts class.
      # #connect('-layoutnames', {"-db" => database}, {:grammar=>'FMPXMLRESULT'}.merge(options)).body
      # options[:database] ||= database
      # options[:grammar] ||= 'FMPXMLRESULT'
      # get_records('-layoutnames', {}, options)
      options[:record_proc] = proc if block_given?
      
      require 'rfm/layouts_cmd'
      Rfm::Commands::Layouts.new(self, **options).call
    end
    
    def layout_meta(_layout=nil, **options)
      #get_records('-view', gen_params(binding, {}), options)
      #connect('-view', gen_params(binding, {}), {:grammar=>'FMPXMLLAYOUT'}.merge(options)).body
      options[:database] ||= config[:database]
      options[:layout] = _layout || options[:layout] || config[:layout]
      options[:grammar] ||= 'FMPXMLLAYOUT'
      get_records('-view', {}, options)
    end
    
    def scripts(**options)
      #connect('-scriptnames', {"-db" => database}, {:grammar=>'FMPXMLRESULT'}.merge(options)).body
      options[:database] ||= config[:database]
      options[:grammar] ||= 'FMPXMLRESULT'
      (options[:record_proc] = proc) if block_given?
      # Don't set this here. Try to use rfm-model to set it, if even needed at all.
      #options[:template] ||= :databases
      get_records('-scriptnames', {}, options)
    end
    
    
    # Get the foundset_count only given criteria & options.
    # TODO: This should probably be abstracted up to the Model layer of Rfm,
    # since it has no FMServer-specific command.
    def count(_layout=nil, find_criteria, **options)
      # foundset_count won't work until xml is parsed (still need to dev the xml parser interface to rfm v4).
      options[:database] ||= config[:database]
      options[:layout] = _layout || options[:layout] || config[:layout]
      options[:max_records] = 0
      find(find_criteria, **options).foundset_count   # from basic hash:  ['fmresultset']['resultset']['count'].to_i
    end
    
    # Retrieves metadata only, with an empty resultset.
    # TODO: This should not be in rfm-core, should be in rfm-model,
    # since it depends on parsing to specific objects.
    if Gem::Specification.find{|g| g.name == 'rfm-model'}
      require 'saxchange/object_merge_refinements'
      using ObjectMergeRefinements
      def meta(_layout=nil, **options)
        options[:database] ||= config[:database]
        options[:layout] = _layout || options[:layout] || config[:layout]
        t1 = Thread.new {get_records('-view', {}, options)}
        t2 = Thread.new {get_records('-view', {}, options.merge(grammar:'FMPXMLLAYOUT'))}
  
        t1v = t1.value
        t2v = t2.value
        t2v.merge! t1v.meta
        t2v.keys.each{|k| t2v._create_accessor(k)}
        t2v
      end
    end
    
    ###  END COMMANDS  ###

    # TODO: Meld this method with connect ??
    # Make call to FMS XML API, given action, query-params, options.
    # This method expects Rfm (human-friendly) args & options.
    def get_records(action, params = {}, runtime_options = {})
      #options[:template] ||= state[:template] # Dont decide template here!  #|| select_grammar('', options).to_s.downcase.to_sym
      
      runtime_options[:grammar] ||= 'fmresultset'  #select_grammar(post, request_options)      
      
      params, connection_options = prepare_params(params, runtime_options)
      
      # This has to be done after prepare_params, or database & layout options
      # get sent to 'connect' every time, which breaks 'databases', 'layouts', and 'scripts' commands.
      
      full_options = config.merge(runtime_options).merge({connection:self})
      # Nothing helps here to prevent password in resultset options-connection-config tree.
      full_options[:connection].config[:password] = nil
      
      # Note the capture_resultset_meta call from rfm v3.
      #capture_resultset_meta(rslt) unless resultset_meta_valid? #(@resultset_meta && @resultset_meta.error != '401')
      
      # Note a simple xml pretty-print formatter looks like this:
      # proc {|io| REXML::Document.new(io).write($stdout, 2) }
      
      # Get formatter, if exists.
      formatter = full_options[:formatter]
      
      # Add '-' to action, if not already there.
      action.gsub!(/^([^-]{1,1})/, '-\1')
      
      #puts "Connection#get_records calling 'connect' with action: #{action}, params: #{params}, options: #{connection_options}"

      # The block enables streaming and returns whatever is ultimately returned from the yield,
      # the finished object tree from the formatter & parser in the case of full rfm install.
      # If you call connection_thread.value, you will get the finished connection response object,
      # but it will wait until thread is done, so it defeats the purpose of streaming to the io object.
      # So don't call connection_thread.value, unless you absolutely need it. And in that case, consider
      # using the standard (not block) form of this method.
      #
      if block_given?
        # Yields streaming io & full set of options to block.
        connect(action, params, connection_options) do |io, http_thread|
          yield(io, full_options.merge({http_thread: http_thread, local_env: binding}))
        end
      elsif formatter
        # Yields streaming io & full set of options to formatter proc.
        connect(action, params, connection_options) do |io, http_thread|
          formatter.call(io, full_options.merge({http_thread: http_thread, local_env: binding}))
        end
      else
        # Non streaming, returns net-http response object with body.
        connect(action, params, connection_options)
      end
    end # get_records

    # TODO: Meld this method with get_records ??
    # Make call to FMS XML API, given action, query-params, options.
    # This method expects fms-xml-api formatted query params.
    def connect(action, params={}, request_options={})
      config_merge = config.merge(request_options)
      post = params.merge(expand_options(config_merge)).merge({action => ''})
      #grammar = select_grammar(post, request_options)
      grammar = select_grammar(post, config_merge)
      host = config_merge[:host]
      port = get_port(config_merge)
      
      # The block will be yielded with an io_reader and a connection object,
      # after the http connection has begun in its own thread.
      # See http_fetch method.
      if block_given?
        http_fetch(host, port, "/fmi/xml/#{grammar}.xml", post, **config_merge, &Proc.new)
      else
        http_fetch(host, port, "/fmi/xml/#{grammar}.xml", post, **config_merge)
      end
    end
    
    
    # DO NOT do any further config-option merging below here.
    # Either pass all needed options, or get options from config, but don't do both.
    private

    def http_fetch(host_name, port, path, post_data, redirect_limit=10, **options)
      
      raise Rfm::CommunicationError.new("While trying to reach the Web Publishing Engine, RFM was redirected too many times.") if redirect_limit == 0

      if options[:log_actions] == true
        #qs = post_data.collect{|key,val| "#{CGI::escape(key.to_s)}=#{CGI::escape(val.to_s)}"}.join("&")
        qs_unescaped = post_data.collect{|key,val| "#{key.to_s}=#{val.to_s}"}.join("&")
        #warn "#{@scheme}://#{@host_name}:#{@port}#{path}?#{qs}"
        log.info "#{get_scheme(options)}://#{host_name}:#{port}#{path}?#{qs_unescaped}"
      end

      pswd = options[:password].is_a?(Symbol) ? ENV[options[:password].to_s] : options[:password]
      
      request = Net::HTTP::Post.new(path)
      request.basic_auth(options[:account_name], pswd)
      request.set_form_data(post_data)
      
      # I tried to reuse this connection as @connection, but I don't think net-http connections
      # are thread safe. One request would appear to clobber the other.
      if options[:proxy]
        connection = Net::HTTP::Proxy(*options[:proxy]).new(host_name, port)
      else
        connection = Net::HTTP.new(host_name, port)
      end
      
      #ADDED LONG TIMEOUT TIMOTHY TING 05/12/2011
      connection.open_timeout = connection.read_timeout = options[:timeout]
      if options[:ssl]
        connection.use_ssl = true
        if options[:root_cert]
          connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
          connection.ca_file = File.join(options[:root_cert_path], options[:root_cert_name])
        else
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      # Stream to IO pipe, if block given.
      # See: https://www.jstorimer.com/blogs/workingwithcode/7766091-introduction-to-ipc-in-ruby
      if block_given?
        #puts "Connection#http_fetch (with block)"
        #pipe_reader, pipe_writer = IO.pipe
        IO.pipe do |pipe_reader, pipe_writer|
          #@io_object = [pipe_reader, pipe_writer]
          thread = Thread.new do
            #pipe_reader.close # close the unused reader if forking.
            #Thread.handle_interrupt(Exception => :immediate) do
              begin
                connection.request request do |response|
                  # Response object already has the header information at this point.
                  Thread.current[:http_response] = response
                  check_for_http_errors response
      
                  # This is NET::HTTP's way of streaming the response body.
                  response.read_body do |chunk|
                    if chunk.size > 0
                      bytes = pipe_writer.write(chunk) 
                      Rfm.log.info("#{self} wrote #{bytes} bytes to IO pipe.") if options[:log_responses]
                    end
                  end
                  
                end # connection.request
                # rescue Exception => exception
                #   # If you rescue, no exception will bubble up from this thread,
                #   # unless you re-raise. Note that you can ensure without rescuing.
                #   Thread.current[:exception] = exception
                #   #Thread.main.raise exception
              ensure
                Rfm.log.info("#{self} ensurring IO-writer is closed.") if options[:log_responses]
                pipe_writer.close
                #Thread.main.raise exception if defined?(:exception)
              end
            #end # Thread.handle_interrupt
          end # Thread
          #thread.abort_on_exception = true
          #pipe_writer.close # close unused writer if using Fork.
          
          # Hand over the reader IO and thread to the block.
          # Note that thread.value will give the return value of thread,
          # but only after the thread has closed. So beware how you use 'thread'.
          rslt = yield(pipe_reader, thread)
          thread.join
          rslt
        end # IO.pipe
      else
        # Give straight response object, if no block given.
        puts "Connection.http_fetch (without block)"
        response = connection.start { |http| http.request(request) }
        check_for_http_errors(response)
        response
      end
    end # http_fetch
    
    def check_for_http_errors(response, **options)
      if nil && options[:log_responses] == true
        response.to_hash.each { |key, value| log.info "#{key}: #{value}" }
        # TODO: Move this to http connection block.
        #log.info response.body
      end
    
      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        if options[:warn_on_redirect]
          log.warn "The web server redirected to " + response['location'] + 
            ". You should revise your connection hostname or adjust your server configuration if possible to improve performance."
        end
        newloc = URI.parse(response['location'])
        http_fetch(newloc.host, newloc.port, newloc.request_uri, account_name, password, post_data, limit - 1)
      when Net::HTTPUnauthorized
        msg = "The account name or password provided is not correct (or the account doesn't have the fmxml extended privilege)."
        raise Rfm::AuthenticationError.new(msg)
      when Net::HTTPNotFound
        msg = "Could not talk to FileMaker because the Web Publishing Engine is not responding (server returned 404)."
        raise Rfm::CommunicationError.new(msg)
      else
        msg = "Unexpected response from server: #{response.code} (#{response.class.to_s}). Unable to communicate with the Web Publishing Engine."
        raise Rfm::CommunicationError.new(msg)
      end
    end
    
    #def check_for_errors(code=@meta['error'].to_i, raise_401=state[:raise_401])
    def check_for_errors(code=nil, raise_401=config[:raise_401])
      Rfm.log.warn("#{self} No response code given in check_for_errors.") unless code
      code = (code || 0).to_i
      #puts ["\nRESULTSET#check_for_errors", code, raise_401]
      raise Rfm::Error.getError(code) if code != 0 && (code != 401 || raise_401)
    end

    def load_field_mapping(mapping={})
      mapping = (mapping || {}) #.to_cih
      def mapping.invert
        super #.to_cih
      end
      mapping
    end
    
    # Clean up passed params & options.
    # Should this be part of 'expand_options'
    def prepare_params(params={}, options={})
      params, options = params.dup, options.dup
      _database = options[:database]
      _layout   = options[:layout]
      if params.is_a?(String)
        params = Hash[URI.decode_www_form(params)]
      end
      params['-db'] = _database if _database
      params['-lay'] = _layout if _layout
      
      #options[:field_mapping] = field_mapping.invert if field_mapping && !options[:field_mapping]
      #mapping = options.extract(:field_mapping) || field_mapping
      mapping = options[:field_mapping] || field_mapping
      apply_field_mapping!(params, mapping.invert) if mapping.is_a?(Hash)
      
      [params, options]
    end
    
    def apply_field_mapping!(params, mapping)
      params.dup.each_key do |k|
        new_key = mapping[k.to_s] || k
        if params[new_key].is_a? Array
          params[new_key].each_with_index do |v, i|
            params["#{new_key}(#{i+1})"]=v
          end
          params.delete new_key
        else
          params[new_key]=params.delete(k) if new_key != k
        end
        #puts "PRMS: #{new_key} #{params[new_key].class} #{params[new_key]}"
      end
    end

    def select_grammar(post, options={})
      grammar = options[:grammar] || 'fmresultset'
      if grammar.to_s.downcase == 'auto'
        # TODO: build grammar-decider here.
        return "fmresultset"
        # post.keys.find(){|k| %w(-find -findall -dbnames -layoutnames -scriptnames).include? k.to_s} ? "FMPXMLRESULT" : "fmresultset"   
      else
        grammar
      end
    end

    # Convert user-facing keys to FMS-XML-API keys.
    # This takes a hash and transforms it to something fms-xml-api will understand.
    # keys not recognized by fms-xml-api or as rfm-allowable-options will be dropped,
    # or will raise exectpion if raise_invalid_option is true.
    def expand_options(options)
      result = {}
      #field_mapping = options.delete(:field_mapping) || {}
      _field_mapping = options.delete(:field_mapping) || {}
      options.each do |key,value|
        case key.to_sym
        when :max_portal_rows
          result['-relatedsets.max'] = value
          result['-relatedsets.filter'] = 'layout'
        when :ignore_portals
          result['-relatedsets.max'] = 0
          result['-relatedsets.filter'] = 'layout'
        when :max_records
          result['-max'] = value
        when :skip_records
          result['-skip'] = value
        when :sort_field
          if value.kind_of? Array
            raise Rfm::ParameterError.new(":sort_field can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
            value.each_index { |i| result["-sortfield.#{i+1}"] = _field_mapping[value[i]] || value[i] }
          else
            result["-sortfield.1"] = _field_mapping[value] || value
          end
        when :sort_order
          if value.kind_of? Array
            raise Rfm::ParameterError.new(":sort_order can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
            value.each_index { |i| result["-sortorder.#{i+1}"] = value[i] }
          else
            result["-sortorder.1"] = value
          end
        when :post_script
          if value.class == Array
            result['-script'] = value[0]
            result['-script.param'] = value[1]
          else
            result['-script'] = value
          end
        when :pre_find_script
          if value.class == Array
            result['-script.prefind'] = value[0]
            result['-script.prefind.param'] = value[1]
          else
            result['-script.presort'] = value
          end
        when :pre_sort_script
          if value.class == Array
            result['-script.presort'] = value[0]
            result['-script.presort.param'] = value[1]
          else
            result['-script.presort'] = value
          end
        when :response_layout
          result['-lay.response'] = value
        when :logical_operator
          result['-lop'] = value
        when :modification_id
          result['-modid'] = value
        else
          if config[:raise_invalid_option] && ! AllowableOptions.member?(key.to_s)
            raise Rfm::ParameterError.new("Invalid option: #{key}")
          end
        end
      end
      return result
    end
    
    # # Experimental open-uri, was in http_fetch method.
    # # This works well but writes entire http response body to temp file.
    # require 'open-uri'
    # output=[]
    # open("#{scheme}://#{host_name}:#{port}#{path}?#{qs_unescaped}",
    #   ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
    #   http_basic_authentication: [account_name, password]
    # ) do |io|
    #   output << io
    #   yield(io)
    # end
    # return output[0]
    
  end # Connection


end # Rfm
