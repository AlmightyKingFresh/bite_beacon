defmodule BiteBeacon.Users.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias BiteBeacon.Repo

  alias BiteBeacon.Users.User

  @doc """
  Returns all users.
  """

  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  """

  def get_user(id), do: Repo.get(User, id)

  @doc """
  Fetches a user by email.
  """

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Fetches a user by name.
  """
  def get_user_by_name(name) when is_binary(name) do
    Repo.get_by(User, name: name)
  end

  ## User registration

  @doc """
  Registers a user.
  """

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user's username
  """

  def update_user_name(%User{} = user, attrs \\ %{}) do
    User.name_changeset(user, attrs)
    |> Repo.update()
  end

  ## Settings

  @doc """
  updates a user's email address

  """
  def update_user_email(%User{} = user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
    |> Repo.update()
  end

  @doc """
  update a user's password

  """

  def update_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
    |> Repo.update()
  end
end

#   def update_user_email(user, token) do
#     context = "change:#{user.email}"

#     with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
#          %UserToken{sent_to: email} <- Repo.one(query),
#          {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
#       :ok
#     else
#       _ -> :error
#     end
#   end

#   def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
#       when is_function(update_email_url_fun, 1) do
#     {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

#     Repo.insert!(user_token)
#     UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
#   end

#   @doc """
#   Returns an `%Ecto.Changeset{}` for changing the user password.

#   ## Examples

#       iex> change_user_password(user)
#       %Ecto.Changeset{data: %User{}}

#   """

#   ## Session

#   @doc """
#   Generates a session token.
#   """
#   def generate_user_session_token(user) do
#     {token, user_token} = UserToken.build_session_token(user)
#     Repo.insert!(user_token)
#     token
#   end

#   @doc """
#   Gets the user with the given signed token.
#   """
#   def get_user_by_session_token(token) do
#     {:ok, query} = UserToken.verify_session_token_query(token)
#     Repo.one(query)
#   end

#   @doc """
#   Deletes the signed token with the given context.
#   """
#   def delete_user_session_token(token) do
#     Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
#     :ok
#   end

#   ## Confirmation

#   @doc ~S"""
#   Delivers the confirmation email instructions to the given user.

#   ## Examples

#       iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
#       {:ok, %{to: ..., body: ...}}

#       iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
#       {:error, :already_confirmed}

#   """
#   def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
#       when is_function(confirmation_url_fun, 1) do
#     if user.confirmed_at do
#       {:error, :already_confirmed}
#     else
#       {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
#       Repo.insert!(user_token)
#       UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
#     end
#   end

#   @doc """
#   Confirms a user by the given token.

#   If the token matches, the user account is marked as confirmed
#   and the token is deleted.
#   """
#   def confirm_user(token) do
#     with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
#          %User{} = user <- Repo.one(query),
#          {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
#       {:ok, user}
#     else
#       _ -> :error
#     end
#   end

#   defp confirm_user_multi(user) do
#     Ecto.Multi.new()
#     |> Ecto.Multi.update(:user, User.confirm_changeset(user))
#     |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
#   end

#   ## Reset password

#   @doc ~S"""
#   Delivers the reset password email to the given user.

#   ## Examples

#       iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
#       {:ok, %{to: ..., body: ...}}

#   """
#   def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
#       when is_function(reset_password_url_fun, 1) do
#     {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
#     Repo.insert!(user_token)
#     UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
#   end

#   @doc """
#   Gets the user by reset password token.

#   ## Examples

#       iex> get_user_by_reset_password_token("validtoken")
#       %User{}

#       iex> get_user_by_reset_password_token("invalidtoken")
#       nil

#   """
#   def get_user_by_reset_password_token(token) do
#     with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
#          %User{} = user <- Repo.one(query) do
#       user
#     else
#       _ -> nil
#     end
#   end

#   @doc """
#   Resets the user password.

#   ## Examples

#       iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
#       {:ok, %User{}}

#       iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
#       {:error, %Ecto.Changeset{}}

#   """
#   def reset_user_password(user, attrs) do
#     Ecto.Multi.new()
#     |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
#     |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
#     |> Repo.transaction()
#     |> case do
#       {:ok, %{user: user}} -> {:ok, user}
#       {:error, :user, changeset, _} -> {:error, changeset}
#     end
#   end
# end
