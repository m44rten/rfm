module Rfm

	# Methods to help translate xml_mini document into Rfm/Filemaker objects.
	module Fmresultset
		def self.extended(obj)
		  obj.instance_variable_set :@root, obj
		  obj.extend Resultset
		end
	
	  module Resultset
	
	    def error
	    	self['FMPXMLRESULT']['ERRORCODE'].to_i
			end      
	       
	    def datasource
	      self['FMPXMLRESULT']['DATABASE']
	    end
	    
	    def meta
	    	self['FMPXMLRESULT']['METADATA']
	    end
	    
	    def resultset
	    	self['FMPXMLRESULT']['RESULTSET']
	    end
	      
	    def date_format
	    	Rfm.convert_date_time_format(datasource['DATEFORMAT'].to_s)
	  	end
	  	
	    def time_format
	    	Rfm.convert_date_time_format(datasource['TIMEFORMAT'].to_s)
	    end
	    
	    def timestamp_format
	    	#Rfm.convert_date_time_format(datasource['timestamp-format'].to_s)
	    	''
	    end
	
	    def foundset_count
	    	resultset['FOUND'].to_s.to_i
	    end
	    	
	    def total_count
	    	datasource['RECORDS'].to_s.to_i
	    end
	    	
	    def table
	    	#datasource['table'].to_s
	    	''
			end
	    
	    def records
	      resultset['ROW'].rfm_force_array.rfm_extend_members(Record, self)
	    end
	
	    
	    def fields
	    	meta['FIELD'].rfm_force_array.rfm_extend_members(Field, self)
	    end
	    
	    def portals
		    #meta['relatedset-definition'].rfm_force_array.rfm_extend_members(RelatedsetDefinition)
		    []
	    end
	
		end
		
		module Field
			def name
				self['NAME']
			end
			
			def result
	    	self['TYPE']
	    end
	    
	    def type
	    	#self['type']
	    	''
	    end
	    
	    def repeats
	    	self['MAXREPEAT']
	    end
	    
	    def global
	    	#self['global']
	    	''
	    end
		end
		
		module RelatedsetDefinition
			def table
				self['table']
			end
			
			def fields
				self['field-definition'].rfm_force_array.rfm_extend_members(Field)
			end
		end
		
		# May need to add @parent to each level of heirarchy in #rfm_extend_member,
		# so we can get the container and it's parent from records, columns, data, etc..
		module Record	
			def columns
				self['field'].rfm_force_array.rfm_extend_members(Column)
			end
			
			def record_id
				self['record-id']
			end
			
			def mod_id
				self['mod-id']
			end
			
			def portals
				self['relatedset'].rfm_force_array.rfm_extend_members(Relatedset)
			end
		end
			
		module Column
			def name #(fields)
				#self['name']
				
			end
			
			def data
				self['data'].values #['__content__']
			end
			
			private
			def position #(records)
				records.index(self)
			end
		end
		
		module Relatedset
			def table
				self['table']
			end
			
			def count
				self['count']
			end
			
			def records
				self['record'].rfm_force_array.rfm_extend_members(Record)
			end
		end
	
	end
    
	def convert_date_time_format(fm_format)
	  fm_format.gsub!('MM', '%m')
	  fm_format.gsub!('dd', '%d')
	  fm_format.gsub!('yyyy', '%Y')
	  fm_format.gsub!('HH', '%H')
	  fm_format.gsub!('mm', '%M')
	  fm_format.gsub!('ss', '%S')
	  fm_format
	end
    
end