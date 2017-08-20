#json.extract! thing_type, :id, :created_at, :updated_at
#json.url thing_type_url(thing_type, format: :json)
json.extract! thing_type, :id, :thing_id, :type_id, :creator_id, :is_vip_pass_required, :created_at, :updated_at
json.thing_name thing_type.thing_name if thing_type.respond_to?(:thing_name)
json.type_name thing_type.type_name if thing_type.respond_to?(:type_name)
#json.url thing_thing_type_url(thing_type, format: :json)