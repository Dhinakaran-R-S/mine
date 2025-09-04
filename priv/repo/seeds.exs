# priv/repo/seeds.exs

alias Przma.Accounts
alias Przma.Accounts.User
alias Pbkdf2


# Create superadmin user if it doesn't exist
superadmin_email = "admin@przma.com"

case Accounts.get_user_by_email(superadmin_email) do
  nil ->
    # Hash a default password for the superadmin

    superadmin_attrs = %{
      "first_name" => "Super",
      "last_name" => "Admin",
      "email" => superadmin_email,
      "username" => "superadmin",
      "password" => "SuperAdmin123!",
      "password_hash" => Pbkdf2.hash_pwd_salt("SuperAdmin123!"),  # Add this line
      "role" => "superadmin",
      "is_verified" => true,
      "is_active" => true
    }

    case Accounts.create_superadmin(superadmin_attrs) do
      {:ok, user} ->
        IO.puts("Superadmin user created successfully!")
        IO.puts("   Email: #{user.email}")
        IO.puts("   Password: SuperAdmin123!")
        IO.puts("   Role: #{user.role}")
        IO.puts("   ⚠️  Please change the default password after first login!")

      {:error, changeset} ->
        IO.puts("Failed to create superadmin user:")
        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)
        |> Enum.each(fn {field, errors} ->
          IO.puts("   #{field}: #{Enum.join(errors, ", ")}")
        end)
    end

  %User{role: "superadmin"} = existing_user ->
    IO.puts("✅ Superadmin user already exists:")
    IO.puts("   Email: #{existing_user.email}")
    IO.puts("   Username: #{existing_user.username}")
    IO.puts("   Role: #{existing_user.role}")
    IO.puts("   Status: #{if existing_user.is_active, do: "Active", else: "Inactive"}")

  %User{} = existing_user ->
    IO.puts("⚠️  User exists but is not a superadmin:")
    IO.puts("   Email: #{existing_user.email}")
    IO.puts("   Current Role: #{existing_user.role}")
    IO.puts("   Consider using a different email or updating the user's role manually.")
end
