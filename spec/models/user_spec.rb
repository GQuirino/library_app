require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    let(:user) { build(:user) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:birthdate) }
    it { should validate_presence_of(:address) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_presence_of(:email) }

    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'is invalid without a name' do
      user.name = nil
      expect(user).to_not be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a birthdate' do
      user.birthdate = nil
      expect(user).to_not be_valid
      expect(user.errors[:birthdate]).to include("can't be blank")
    end

    it 'is invalid without an address' do
      user.address = nil
      expect(user).to_not be_valid
      expect(user.errors[:address]).to include("can't be blank")
    end

    it 'is invalid without a phone number' do
      user.phone_number = nil
      expect(user).to_not be_valid
      expect(user.errors[:phone_number]).to include("can't be blank")
    end

    it 'is invalid with duplicate email' do
      create(:user, email: 'test@example.com')
      user.email = 'test@example.com'
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include('has already been taken')
    end

    it 'is invalid with improperly formatted email' do
      user.email = 'invalid_email'
      expect(user).to_not be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'is invalid with improperly formatted address' do
      user.address = 'invalid_address'
      expect(user).to_not be_valid
      expect(user.errors[:address]).to include('must be a hash')
    end

    it 'is invalid with missing address key' do
      user.address = { street: '123 Main St', city: 'Springfield' }
      expect(user).to_not be_valid
      expect(user.errors[:address]).to include("must contain the keys: zip, state")
    end
  end

  describe 'associations' do
    it { should have_many(:reservations).dependent(:destroy) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(librarian: 0, member: 1) }

    describe 'role enum' do
      let(:librarian) { create(:user, role: :librarian) }
      let(:member) { create(:user, role: :member) }

      it 'sets role correctly' do
        expect(librarian.role).to eq('librarian')
        expect(member.role).to eq('member')
      end

      it 'provides predicate methods' do
        expect(librarian.librarian?).to be_truthy
        expect(librarian.member?).to be_falsy
        expect(member.member?).to be_truthy
        expect(member.librarian?).to be_falsy
      end
    end
  end

  describe 'scopes' do
    let!(:librarian1) { create(:user, role: :librarian) }
    let!(:librarian2) { create(:user, role: :librarian) }
    let!(:member1) { create(:user, role: :member) }
    let!(:member2) { create(:user, role: :member) }

    describe '.librarians' do
      it 'returns only librarians' do
        librarians = User.librarians
        expect(librarians).to include(librarian1, librarian2)
        expect(librarians).to_not include(member1, member2)
        expect(librarians.count).to eq(2)
      end
    end

    describe '.members' do
      it 'returns only members' do
        members = User.members
        expect(members).to include(member1, member2)
        expect(members).to_not include(librarian1, librarian2)
        expect(members.count).to eq(2)
      end
    end

    describe '.with_open_reservations' do
      let!(:user_with_open_reservation) { create(:user) }
      let!(:user_with_returned_reservation) { create(:user) }
      let!(:user_without_reservations) { create(:user) }

      before do
        create(:reservation, user: user_with_open_reservation, returned_at: nil)
        create(:reservation, user: user_with_returned_reservation, returned_at: Time.current)
      end

      it 'returns only users with open reservations' do
        users_with_open = User.with_open_reservations
        expect(users_with_open).to include(user_with_open_reservation)
        expect(users_with_open).to_not include(user_with_returned_reservation, user_without_reservations)
      end
    end

    describe '.with_overdue_reservations' do
      let!(:user_with_overdue) { create(:user) }
      let!(:user_with_current) { create(:user) }
      let!(:user_with_returned_overdue) { create(:user) }

      before do
        # Overdue reservation (not returned)
        create(:reservation,
               user: user_with_overdue,
               return_date: 2.days.ago,
               returned_at: nil)

        # Current reservation (not overdue)
        create(:reservation,
               user: user_with_current,
               return_date: 2.days.from_now,
               returned_at: nil)

        # Overdue but already returned
        create(:reservation,
               user: user_with_returned_overdue,
               return_date: 2.days.ago,
               returned_at: 1.day.ago)
      end

      it 'returns only users with overdue unreturned reservations' do
        users_with_overdue = User.with_overdue_reservations
        expect(users_with_overdue).to include(user_with_overdue)
        expect(users_with_overdue).to_not include(user_with_current, user_with_returned_overdue)
      end
    end
  end
end
