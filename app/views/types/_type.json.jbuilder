json.extract! type, :id, :name, :created_at, :updated_at
json.notes type.notes unless type.notes.nil?
json.url type_url(type, format: :json)
json.user_roles type.user_roles unless type.user_roles.empty?
