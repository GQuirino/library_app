class ReservationPolicy < ApplicationPolicy
  def index?
    user.librarian?
  end

  def show?
   true
  end

  def create?
    true
  end

  def update?
    user.librarian?
  end

  def destroy?
    user.librarian?
  end
end
