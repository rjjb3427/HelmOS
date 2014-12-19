class User < ActiveRecord::Base
  has_secure_password

  validates :email, presence: true, uniqueness: {case_sensitive: false}, format: { with: /\A[^@\s]+\@[^@\s]+\.[^@\.\s]+\z/ }
  validates :username, presence: true, uniqueness: {case_sensitive: false}
  validates :password, length: {minimum: 8}, if: :validate_password?

  before_validation :downcase_email
  before_create { generate_token(:tg_auth_token) }

  def reset_auth_token
    generate_token(:tg_auth_token)
    save!
  end

private
  def downcase_email
    self.email = self.email.downcase
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def validate_password?
    (password.present? || password == '')
  end
end
