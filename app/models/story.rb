# == Schema Information
# Schema version: 20090218144012
#
# Table name: news_items
#
#  id                          :integer(4)      not null, primary key
#  headline                    :string(255)
#  location                    :string(255)
#  state                       :string(255)
#  short_description           :text
#  delivery_description        :text
#  extended_description        :text
#  skills                      :text
#  keywords                    :string(255)
#  deliver_text                :boolean(1)      not null
#  deliver_audio               :boolean(1)      not null
#  deliver_video               :boolean(1)      not null
#  deliver_photo               :boolean(1)      not null
#  contract_agreement          :boolean(1)      not null
#  expiration_date             :datetime
#  created_at                  :datetime
#  updated_at                  :datetime
#  featured_image_file_name    :string(255)
#  featured_image_content_type :string(255)
#  featured_image_file_size    :integer(4)
#  featured_image_updated_at   :datetime
#  type                        :string(255)
#  video_embed                 :text
#  featured_image_caption      :string(255)
#  user_id                     :integer(4)
#  status                      :string(255)
#  feature                     :boolean(1)
#  fact_checker_id             :integer(4)
#  news_item_id                :integer(4)
#  deleted_at                  :datetime
#  widget_embed                :text
#  requested_amount            :decimal(15, 2)
#  current_funding             :decimal(15, 2)
#

class Story < NewsItem
  cleanse_columns(:extended_description) do |sanitizer|
    sanitizer.allowed_tags.add(%w(object param embed a img))
    sanitizer.allowed_attributes.add(%w(width height name src value allowFullScreen type href allowScriptAccess style wmode pluginspage classid codebase data quality))
  end

  aasm_initial_state  :draft
  aasm_state :draft
  aasm_state :fact_check
  aasm_state :ready
  aasm_state :published

  aasm_event :verify do
    transitions :from => :draft, :to => :fact_check, :on_transition => :notify_editor
  end

  aasm_event :reject do
    transitions :from => :fact_check, :to => :draft, :on_transition => :notify_reporter
  end

  aasm_event :accept do
    transitions :from => :fact_check, :to => :ready, :on_transition => :notify_admin
  end

  aasm_event :publish do
    transitions :from => :ready, :to => :published, :on_transition => :notify_donors
  end

  belongs_to :pitch, :foreign_key => 'news_item_id'
  
  has_many :organizational_donors, :through => :donations, :source => :user, :order => "donations.created_at", 
            :conditions => "users.type = 'organization'",
            :uniq => true
  validate_on_update :extended_description

  named_scope :published, :conditions => {:status => 'published'}
  named_scope :latest, :order => "updated_at desc", :limit => 6
  def supporting_organizations
    pitch.supporting_organizations
  end
  
  def donations
    pitch.donations
  end
  
  def donating_groups
    pitch.donating_groups
  end
  
  def supporters
    pitch.supporters
  end
  
  def total_amount_donated
    pitch.total_amount_donated
  end

  def editable_by?(user)
    return false if user.nil?
    #return false if self.fact_checker == user
    return true if self.user == user and self.status == "draft"
    return true if self.fact_checker == user and self.status == "fact_check"
    # if user.is_a?(Reporter)
    #   return (user == self.user) if self.draft?
    # end
    return false if user.is_a?(Citizen)
    return true if user.is_a?(Admin)
    false
  end

  def viewable_by?(user)
    return true if user.is_a?(Admin)
    return true if self.published?
    return true if self.fact_checker == user
    return true if self.user == user
    # if user.is_a?(Reporter)
    #   return reporter_view_permissions(user)
    # end
    false
  end

  def publishable_by?(user)
    return false if user.nil?
    self.ready? && user.is_a?(Admin)
  end

  def reporter_view_permissions(user)
    return true if (user == self.user || self.fact_checker == user)
  end

  def fact_checkable_by?(user)
    return true if user.is_a?(Admin)
    user == self.fact_checker
  end

  def notify_admin
    Mailer.deliver_story_ready_notification(self)
  end
  
  def notify_editor
    Mailer.deliver_story_to_editor_notification(self,fact_checker_recipients)
  end
  
  def notify_reporter
    Mailer.deliver_story_rejected_notification(self)
  end
  
  def notify_donors
    Mailer.deliver_story_published_notification(self,fact_checker_recipients)
  end
  
  def to_s
    headline
  end
  
  def to_param
    begin 
      "#{id}-#{to_s.parameterize}"
    rescue
      "#{id}"
    end
  end
  
  protected
  def fact_checker_recipients
      recipients = '"David Cohn" <david@spot.us>'
      if self.pitch && self.pitch.fact_checker_id
          fact_checker = User.find_by_id(self.pitch.fact_checker_id)
          if fact_checker && fact_checker.email
              recipients += (", " + fact_checker.email)
          end
      end
      recipients
  end
end

