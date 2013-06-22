String.class_eval do
  def is_valid_url?
    uri = URI.parse self
    uri.kind_of? URI::HTTP
  rescue URI::InvalidURIError
    false
  end
end
