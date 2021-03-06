# frozen_string_literal: true

require 'aws_backend'

class AwsRdsInstance < AwsResourceBase
  name 'aws_rds_instance'
  desc 'Verifies settings for an RDS instance'

  example "
    describe aws_rds_instance(db_instance_identifier: 'test-instance-id') do
      it { should exist }
    end
  "
  attr_reader :exists
  alias exists? exists

  def initialize(opts = {})
    # Call the parent class constructor
    opts = { db_instance_identifier: opts } if opts.is_a?(String) # this preserves the original scalar interface
    super(opts)
    validate_parameters([:db_instance_identifier])
    @display_name = opts[:db_instance_identifier]
    raise ArgumentError, 'aws_rds_instance Database Instance ID must be in the format: start with a letter followed by up to 62 letters/numbers/hyphens.' if opts[:db_instance_identifier] !~ /^[a-z]{1}[0-9a-z\-]{0,62}$/
    catch_aws_errors do
      @exists = false
      begin
        @resp = @aws.rds_client.describe_db_instances(db_instance_identifier: opts[:db_instance_identifier])
        return if @resp.db_instances.empty?
        @rds_instance = @resp.db_instances[0].to_h
        @exists = true
      rescue Aws::RDS::Errors::DBInstanceNotFound
        return
      end
      create_resource_methods(@rds_instance)
    end
  end

  def to_s
    "RDS Instance #{@display_name}"
  end
end
