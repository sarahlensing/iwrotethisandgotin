# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe User do
  before do
    @user = User.new(name: "Example User", email: "username@example.com", 
                     password: "foobar", password_confirmation: "foobar")
  end

  subject { @user }

  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:admin) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:essays) }

  it { should be_valid }
  it { should_not be_admin }

  describe "essay associations" do

	  before { @user.save }
	  let!(:older_essay) do
		  FactoryGirl.create(:essay, user: @user, created_at: 1.day.ago)
	  end
	  let!(:newer_essay) do
		  FactoryGirl.create(:essay, user: @user, created_at: 1.hour.ago)
	  end

	  describe "status" do
		  let(:unfollowed_post) do
			  FactoryGirl.create(:essay, user: FactoryGirl.create(:user))
		  end

		  its(:feed) { should include(newer_essay) }
		  its(:feed) { should include(older_essay) }
		  its(:feed) { should_not include(unfollowed_post) }
	  end

	  it "should have the right essays in the right order" do
		  @user.essays.should == [newer_essay, older_essay]
	  end

	  it "should destroy associated essays" do
		  essays = @user.essays
		  @user.destroy
		  essays.each do |essay|
			  Essay.find_by_id(essay.id).should be_nil
		  end
	  end
  end

  describe "with admin attribut set to 'true'" do
	  before { @user.toggle!(:admin) }

	  it { should be_admin }
  end

  describe "when name is not present" do
    before { @user.name = " " }
    it { should_not be_valid }
  end

  describe "when email is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end

  describe "when name is too long" do
    before { @user.name = "a" * 51 }
    it { should_not be_valid }
  end

  describe "when email format is invalid" do
    invalid_addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    invalid_addresses.each do |invalid_address|
      before { @user.email = invalid_address }
      it { should_not be_valid }
    end
  end

  describe "when email format is valid" do
    valid_addresses = %w[user@foo.com A_USER@f.b.org frst.lst@foo.jp a+b@baz.cn]
    valid_addresses.each do |valid_address|
      before { @user.email = valid_address }
      it { should be_valid }
    end
  end

  describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end

    it { should_not be_valid }
  end

  describe "when password is not present" do
    before { @user.password = @user.password_confirmation = " " }
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  describe "return value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by_email(@user.email) }

    describe "with valid password" do
      it { should == found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }
  
      it { should_not == user_for_invalid_password }
      specify { user_for_invalid_password.should be_false }
    end
  end

  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }
    it {should be_invalid }
  end

  describe "remember token" do
    before { @user.save }
    its(:remember_token) {should_not be_blank }
  end
end
