require 'cloud_controller/diego/lifecycles/buildpack_info'
require 'cloud_controller/diego/lifecycles/buildpack_lifecycle_data_validator'
require 'fetchers/buildpack_lifecycle_fetcher'

module VCAP::CloudController
  class AppBuildpackLifecycle
    def initialize(message)
      @message = message

      db_result      = BuildpackLifecycleFetcher.new.fetch(buildpack, stack)
      buildpack_info = BuildpackInfo.new(buildpack, db_result[:buildpack])
      @validator     = BuildpackLifecycleDataValidator.new({ buildpack_info: buildpack_info, stack: db_result[:stack] })
    end

    delegate :valid?, :errors, to: :validator

    def create_lifecycle_data_model(app)
      BuildpackLifecycleDataModel.create(
        buildpacks: Array(buildpack),
        stack:     stack,
        app:       app
      )
    end

    def update_lifecycle_data_model(app)
      should_save = false
      if message.buildpack_data.requested?(:buildpacks)
        should_save = true
        app.lifecycle_data.buildpacks = buildpacks
      end
      if message.buildpack_data.requested?(:stack)
        should_save = true
        app.lifecycle_data.stack = message.buildpack_data.stack
      end
      app.lifecycle_data.save if should_save
    end

    def type
      Lifecycles::BUILDPACK
    end

    private

    attr_reader :message, :validator

    def buildpack
      if message.buildpack_data.requested?(:buildpacks)
        message.buildpack_data.buildpacks.try(:first)
      end
    end

    def buildpacks
      message.buildpack_data.buildpacks if message.buildpack_data.requested?(:buildpacks)
    end

    def stack
      if message.buildpack_data.requested?(:stack) && !message.buildpack_data.stack.nil?
        message.buildpack_data.stack
      else
        Stack.default.name
      end
    end
  end
end
