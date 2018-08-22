require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'
require 'byebug'

class ControllerBase
  attr_reader :req, :res, :params, :session 

  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
    # @params = route_params.merge(req.params)
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "double render error" if already_built_response?
    @already_built_response = true
    @res.status = 302
    @res.location = url
    session.store_session(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    fail if @already_built_response
    @already_built_response = true
    @res['Content-Type'] = content_type
    @res.write(content)
    session.store_session(res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    # bin/lib/
    file_directory = File.dirname(__FILE__)

    # bin/lib/../views/cats_controller/new.html.erb
    file_path = File.join(file_directory, '..', 'views', "#{self.class.to_s.underscore}", "#{template_name}.html.erb")
    contents = File.read(file_path)

    # ERB.new parses the embedded ruby as well as captures controller's instance variables with binding
    parsed = ERB.new(contents).result(binding)
    render_content(parsed, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end
