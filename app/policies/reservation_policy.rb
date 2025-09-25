class ReservationPolicy < ApplicationPolicy
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
