class Thing < ActiveRecord::Base
  include Protectable
  validates :name, :presence=>true

  has_many :thing_images, inverse_of: :thing, dependent: :destroy
  has_many :thing_types, inverse_of: :thing, dependent: :destroy

  scope :not_linked, ->(image) { where.not(:id=>ThingImage.select(:thing_id)
                                                          .where(:image=>image)) }
  scope :not_typed, ->(type) { where.not(:id=>ThingType.select(:thing_id)
                                                    .where(:type=>type)) }

  scope :with_type, ->(type_id) { where(:id=>ThingType.select(:thing_id)
                                                     .where(:type_id=>type_id)) }
end
